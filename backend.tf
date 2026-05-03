# Remote state — so all 3 team members share the same infrastructure state.
#
# SETUP: This bucket must exist before "terraform init".
# One person runs this command once, everyone else just runs "terraform init".
#
#   aws s3api create-bucket \
#     --bucket cloudguard-dns-terraform-state \
#     --region eu-central-1 \
#     --create-bucket-configuration LocationConstraint=eu-central-1

terraform {
  backend "s3" {
    bucket       = "cloudguard-dns-terraform-state"
    key          = "dashboard/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
