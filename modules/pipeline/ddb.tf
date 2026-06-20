# DynamoDB events table. PK = event_id, no SK. TTL on `ttl` attribute set by
# the persist lambda. On-demand billing — pay per request, no capacity tuning.
resource "aws_dynamodb_table" "events" {
  name         = local.ddb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
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
