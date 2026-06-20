variable "project_name" {
  description = "Project name, used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "master_py_source" {
  description = "Local filesystem path to backend/master.py — uploaded to S3 and pulled by the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. Account is restricted to free-tier-eligible types."
  type        = string
  default     = "t3.micro"
}

variable "api_port" {
  description = "Port master.py listens on"
  type        = number
  default     = 9800
}

variable "trusted_sg_ids" {
  description = "Additional security group IDs allowed to reach the master API port. Workers go here."
  type        = list(string)
  default     = []
}
