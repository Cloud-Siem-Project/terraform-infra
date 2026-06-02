variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "archive_retention_days" {
  description = "EB archive retention. Use 0 for indefinite."
  type        = number
  default     = 30
}
