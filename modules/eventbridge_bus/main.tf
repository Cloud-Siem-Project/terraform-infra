locals {
  bus_name = "${var.project_name}-events"
}

# Custom event bus — keeps our rules isolated from the default bus so phase 3
# can wipe + redeploy without touching anything aws-native.
resource "aws_cloudwatch_event_bus" "main" {
  name = local.bus_name
}

# Archive everything that hits the bus. Built-in replay later if pipeline
# breaks. Storage is free, replays are billed per event.
resource "aws_cloudwatch_event_archive" "main" {
  name             = "${local.bus_name}-archive"
  event_source_arn = aws_cloudwatch_event_bus.main.arn
  retention_days   = var.archive_retention_days
}
