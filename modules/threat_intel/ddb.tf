# Threat-intel blacklist. PK = ip. On-demand billing — the loader does a burst
# of writes every 12h, the flow_detector scans it into memory. TTL on `ttl` so
# stale feed entries age out if the loader stops running.
resource "aws_dynamodb_table" "threat_intel" {
  name         = local.ti_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ip"

  attribute {
    name = "ip"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = false
  }
}
