data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}-simulator"

  sim_py_content = file(var.simulator_py_source)
  sim_py_hash    = filemd5(var.simulator_py_source)
}

# AL2023 — has python3 + pip; we install boto3 in user-data.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

locals {
  subnet_id = sort(data.aws_subnets.default.ids)[0]
}

# ── IAM: SSM + write evidence to S3 + publish events to the bus ──
resource "aws_iam_role" "sim" {
  name = "${local.name_prefix}-instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.sim.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "sim" {
  name = "${local.name_prefix}-policy"
  role = aws_iam_role.sim.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EvidenceWrite"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.evidence_bucket_arn}/*"
      },
      {
        Sid      = "PutEventsToBus"
        Effect   = "Allow"
        Action   = ["events:PutEvents"]
        Resource = var.eb_bus_arn
      },
    ]
  })
}

resource "aws_iam_instance_profile" "sim" {
  name = "${local.name_prefix}-instance"
  role = aws_iam_role.sim.name
}

# Egress-only: needs DNS, outbound connects, AWS APIs, package mirrors.
resource "aws_security_group" "sim" {
  name        = "${local.name_prefix}-sg"
  description = "Centinel simulator - egress only"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "sim" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = local.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.sim.name
  vpc_security_group_ids = [aws_security_group.sim.id]

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    sim_py_content  = local.sim_py_content
    sim_py_hash     = local.sim_py_hash
    eb_bus_name     = var.eb_bus_name
    evidence_bucket = var.evidence_bucket_name
    region          = data.aws_region.current.name
    blacklist_ips   = var.blacklist_ips
    interval        = var.interval
  })

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = local.name_prefix
    Role = "simulator"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
