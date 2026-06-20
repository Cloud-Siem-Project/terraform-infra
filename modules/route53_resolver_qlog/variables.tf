variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  description = "VPC to associate resolver query logging with"
  type        = string
}

variable "retention_days" {
  description = "CWL retention for resolver query logs"
  type        = number
  default     = 14
}
