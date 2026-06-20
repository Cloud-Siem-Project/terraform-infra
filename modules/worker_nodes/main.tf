locals {
  name_prefix = "${var.project_name}-${var.environment}-worker"

  worker_py_content = file(var.worker_py_source)
  worker_py_hash    = filemd5(var.worker_py_source)

  # Three free-tier-eligible instances, one per distro. All x86_64 so the
  # worker.py (stdlib only) behavior is identical across them.
  workers = {
    al2023 = {
      ami_id  = data.aws_ami.al2023.id
      node_id = "worker-al2023"
    }
    ubuntu24 = {
      ami_id  = data.aws_ami.ubuntu.id
      node_id = "worker-ubuntu24"
    }
    debian12 = {
      ami_id  = data.aws_ami.debian.id
      node_id = "worker-debian12"
    }
  }
}

# ──────────────────────────────────────────────
# AMIs — one data source per distro
# ──────────────────────────────────────────────

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"] # Debian

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ──────────────────────────────────────────────
# Default subnet — workers land in the same VPC as the master
# ──────────────────────────────────────────────

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

locals {
  subnet_id = sort(data.aws_subnets.default.ids)[0]
}

# ──────────────────────────────────────────────
# IAM — SSM only. worker.py is embedded in user-data so no S3 read needed.
# ──────────────────────────────────────────────

resource "aws_iam_role" "worker" {
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
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "worker" {
  name = "${local.name_prefix}-instance"
  role = aws_iam_role.worker.name
}

# ──────────────────────────────────────────────
# Security group — no ingress, all egress.
# Workers only need to talk OUT (to master, to package mirrors, to SSM).
# ──────────────────────────────────────────────

resource "aws_security_group" "worker" {
  name        = "${local.name_prefix}-sg"
  description = "Worker nodes - egress only"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (master, package mirrors, SSM)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ──────────────────────────────────────────────
# Instances — one per distro
# ──────────────────────────────────────────────

resource "aws_instance" "worker" {
  for_each = local.workers

  ami                  = each.value.ami_id
  instance_type        = var.instance_type
  subnet_id            = local.subnet_id
  iam_instance_profile = aws_iam_instance_profile.worker.name

  vpc_security_group_ids = [aws_security_group.worker.id]

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    worker_py_content  = local.worker_py_content
    worker_py_hash     = local.worker_py_hash
    node_id            = each.value.node_id
    master_private_ip  = var.master_private_ip
    master_port        = var.master_port
    heartbeat_interval = var.heartbeat_interval
  })

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-${each.key}"
    Role = "worker"
  }

  # Don't replace when AWS publishes a new AMI of the distro.
  lifecycle {
    ignore_changes = [ami]
  }
}
