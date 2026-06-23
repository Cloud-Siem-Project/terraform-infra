data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.project_name}-${var.environment}-evidence-${data.aws_caller_identity.current.account_id}"
}

# Quarantine / evidence bucket — holds artifacts captured by the simulator and
# any content-fetching lambda, for the malware team to pull and analyze.
resource "aws_s3_bucket" "evidence" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket                  = aws_s3_bucket.evidence.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    id     = "expire"
    status = "Enabled"
    filter {}
    expiration {
      days = var.expire_days
    }
    noncurrent_version_expiration {
      noncurrent_days = 14
    }
  }
}
