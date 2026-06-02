# Pull the backend EC2 EIP DNS from the backend_service stack so CloudFront
# can route /api/* to it. Backend stack must be applied first.
data "terraform_remote_state" "backend_service" {
  backend = "s3"
  config = {
    bucket = "cloudguard-dns-terraform-state"
    key    = "backend_service/terraform.tfstate"
    region = "eu-central-1"
  }
}

# Pull the API Gateway domain from the siem stack for /api/events* routing.
# Siem stack must be applied first; outputs may be null if dashboard_api disabled.
data "terraform_remote_state" "siem" {
  backend = "s3"
  config = {
    bucket = "cloudguard-dns-terraform-state"
    key    = "siem/terraform.tfstate"
    region = "eu-central-1"
  }
}

module "dashboard_hosting" {
  source = "../modules/dashboard_hosting"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project_name             = var.project_name
  environment              = var.environment
  api_origin_domain        = data.terraform_remote_state.backend_service.outputs.api_origin_domain
  api_origin_port          = data.terraform_remote_state.backend_service.outputs.api_port
  events_api_origin_domain = try(data.terraform_remote_state.siem.outputs.events_api_domain, "")
  custom_domain            = var.custom_domain
}

module "github_oidc" {
  source = "../modules/github_oidc"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  github_repos = [
    "Cloud-Siem-Project/frontend",
    "Cloud-Siem-Project/backend",
    "Cloud-Siem-Project/enrichmentpipeline",
  ]

  s3_bucket_arns = [
    module.dashboard_hosting.bucket_arn,
    "arn:aws:s3:::${var.project_name}-${var.environment}-backend-code",
  ]

  cloudfront_arns = [
    "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.dashboard_hosting.distribution_id}",
  ]

  lambda_arns = [
    "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*",
  ]
}

data "aws_caller_identity" "current" {}

# State migrations: the resources used to live at the root of terraform-infra.
# After the Phase 0 refactor they are inside the dashboard_hosting module.
# These `moved` blocks tell Terraform to update state addresses in place,
# without destroying or recreating any resource.

moved {
  from = aws_s3_bucket.dashboard
  to   = module.dashboard_hosting.aws_s3_bucket.dashboard
}

moved {
  from = aws_s3_bucket_public_access_block.dashboard
  to   = module.dashboard_hosting.aws_s3_bucket_public_access_block.dashboard
}

moved {
  from = aws_cloudfront_origin_access_control.dashboard
  to   = module.dashboard_hosting.aws_cloudfront_origin_access_control.dashboard
}

moved {
  from = aws_cloudfront_distribution.dashboard
  to   = module.dashboard_hosting.aws_cloudfront_distribution.dashboard
}

moved {
  from = aws_s3_bucket_policy.dashboard
  to   = module.dashboard_hosting.aws_s3_bucket_policy.dashboard
}
