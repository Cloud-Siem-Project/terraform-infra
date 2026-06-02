variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  description = "VPC where workers live"
  type        = string
}

variable "master_private_ip" {
  description = "Private IP of the master EC2 — workers POST register/heartbeat here"
  type        = string
}

variable "master_port" {
  description = "Port master.py listens on"
  type        = number
  default     = 9800
}

variable "worker_py_source" {
  description = "Local path to worker.py — content gets embedded into each instance's user-data"
  type        = string
}

variable "instance_type" {
  description = "EC2 type for all workers. Free-tier eligible only."
  type        = string
  default     = "t3.micro"
}

variable "heartbeat_interval" {
  description = "Seconds between worker heartbeats"
  type        = number
  default     = 20
}
