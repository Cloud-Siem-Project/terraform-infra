variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  description = "VPC to enable flow logs on"
  type        = string
}

variable "retention_days" {
  description = "CloudWatch Logs retention for the flow log group"
  type        = number
  default     = 14
}

variable "traffic_type" {
  description = "ACCEPT, REJECT, or ALL"
  type        = string
  default     = "ALL"
}
