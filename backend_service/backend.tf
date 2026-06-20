terraform {
  backend "s3" {
    bucket       = "cloudguard-dns-terraform-state"
    key          = "backend_service/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
