variable "project_name" { type = string }
variable "environment" { type = string }

variable "vpc_id" {
  description = "VPC the simulator lives in — must be the one with R53 resolver qlog + flow logs"
  type        = string
}

variable "simulator_py_source" {
  description = "Local path to simulator.py — embedded into user-data"
  type        = string
}

variable "eb_bus_name" { type = string }
variable "eb_bus_arn" { type = string }

variable "evidence_bucket_name" { type = string }
variable "evidence_bucket_arn" { type = string }

variable "blacklist_ips" {
  description = "Comma-separated TEST-NET IPs the simulator connects to (must be in the threat-intel table)"
  type        = string
  default     = "192.0.2.66,192.0.2.123"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "interval" {
  description = "Seconds between simulator activity cycles"
  type        = number
  default     = 30
}
