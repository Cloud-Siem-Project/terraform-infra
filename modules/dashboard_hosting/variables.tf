variable "project_name" {
  description = "Project name, used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "api_origin_domain" {
  description = "Optional backend API origin domain (e.g. EC2 EIP DNS). When set, CloudFront forwards /api/* to this origin. Empty string = no API routing."
  type        = string
  default     = ""
}

variable "api_origin_port" {
  description = "Backend API HTTP port"
  type        = number
  default     = 9800
}

variable "events_api_origin_domain" {
  description = "Optional API Gateway origin domain for /api/events* (HTTPS only). Empty string = not wired."
  type        = string
  default     = ""
}

variable "custom_domain" {
  description = "Custom domain for CloudFront (e.g. cloudlogger.com). Empty string = no custom domain."
  type        = string
  default     = ""
}
