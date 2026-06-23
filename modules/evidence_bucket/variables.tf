variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "expire_days" {
  description = "Days a captured artifact is kept before expiry"
  type        = number
  default     = 90
}
