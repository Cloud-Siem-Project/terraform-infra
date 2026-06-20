# Remote state for the SIEM (event-driven threat monitoring) layer.
# Separate state from the dashboard layer so apply blast radius is isolated.

terraform {
  backend "s3" {
    bucket       = "cloudguard-dns-terraform-state"
    key          = "siem/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
