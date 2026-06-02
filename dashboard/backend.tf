# Remote state for the dashboard hosting layer.
# State key unchanged so the existing tfstate continues to be used.

terraform {
  backend "s3" {
    bucket       = "cloudguard-dns-terraform-state"
    key          = "dashboard/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
