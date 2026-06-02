locals {
  name_prefix = "${var.project_name}-${var.environment}-backend"

  # Hash of master.py — embedded in user-data below so updating the script
  # forces an instance replacement (user_data_replace_on_change = true).
  master_py_hash = filemd5(var.master_py_source)
}

# ──────────────────────────────────────────────
# Default VPC / subnet for the EC2 instance
# ──────────────────────────────────────────────

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Pick the first default-subnet deterministically — order is region-stable enough
# for a quick deploy. Replace with a specific AZ if you ever need stickiness.
locals {
  subnet_id = sort(data.aws_subnets.default.ids)[0]
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# CloudFront's managed prefix list — limits backend ingress to CloudFront edge
# locations only. Backend has no auth, so locking the SG down matters.
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ──────────────────────────────────────────────
# Code staging bucket — master.py is uploaded here, instance pulls on boot
# ──────────────────────────────────────────────

resource "aws_s3_bucket" "code" {
  bucket        = "${local.name_prefix}-code"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "code" {
  bucket = aws_s3_bucket.code.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "master_py" {
  bucket = aws_s3_bucket.code.id
  key    = "master.py"
  source = var.master_py_source
  etag   = local.master_py_hash
}

# ──────────────────────────────────────────────
# IAM — instance role with S3 read + SSM
# ──────────────────────────────────────────────

resource "aws_iam_role" "instance" {
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
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "code_read" {
  name = "${local.name_prefix}-code-read"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.code.arn,
        "${aws_s3_bucket.code.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "instance" {
  name = "${local.name_prefix}-instance"
  role = aws_iam_role.instance.name
}

# ──────────────────────────────────────────────
# Security group — ingress only from CloudFront edge locations
# ──────────────────────────────────────────────

resource "aws_security_group" "backend" {
  name        = "${local.name_prefix}-sg"
  description = "Backend HTTP API - ingress from CloudFront only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP API from CloudFront edge"
    from_port       = var.api_port
    to_port         = var.api_port
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  # Per-trusted-SG ingress (workers register/heartbeat via private network).
  dynamic "ingress" {
    for_each = var.trusted_sg_ids
    content {
      description     = "API from trusted SG (worker fleet)"
      from_port       = var.api_port
      to_port         = var.api_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    description = "All outbound (apt, S3, SSM)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ──────────────────────────────────────────────
# EC2 instance + Elastic IP
# ──────────────────────────────────────────────

resource "aws_eip" "backend" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip"
  }
}

resource "aws_instance" "backend" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  subnet_id            = local.subnet_id
  iam_instance_profile = aws_iam_instance_profile.instance.name

  vpc_security_group_ids = [aws_security_group.backend.id]

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    code_bucket    = aws_s3_bucket.code.id
    api_port       = var.api_port
    master_py_hash = local.master_py_hash
  })

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-instance"
  }

  # Don't force-replace the instance every time AWS publishes a new AL2023 AMI.
  # If we want to upgrade, we can manually taint or change the data source.
  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [
    aws_s3_object.master_py,
    aws_iam_role_policy.code_read,
    aws_iam_role_policy_attachment.ssm,
  ]
}

resource "aws_eip_association" "backend" {
  instance_id   = aws_instance.backend.id
  allocation_id = aws_eip.backend.id
}
