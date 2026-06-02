# GuardDuty detector. Findings are auto-published to the default EventBridge
# bus under source "aws.guardduty", which is how Phase 2 will consume them.
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency
}

# Optional features. EKS / Lambda / runtime monitoring stay off — they cost
# more than the rest of GuardDuty combined and the project doesn't run any.
resource "aws_guardduty_detector_feature" "s3_logs" {
  detector_id = aws_guardduty_detector.main.id
  name        = "S3_DATA_EVENTS"
  status      = var.enable_s3_protection ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "eks_audit_logs" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EKS_AUDIT_LOGS"
  status      = "DISABLED"
}

resource "aws_guardduty_detector_feature" "ebs_malware_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "DISABLED"
}

resource "aws_guardduty_detector_feature" "lambda_network_logs" {
  detector_id = aws_guardduty_detector.main.id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = "DISABLED"
}
