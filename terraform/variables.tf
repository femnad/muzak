variable "allow_https_access" {
  default     = true
  description = "Allow HTTPS access to the instance for certificate initialization"
  type        = bool
}

variable "managed_connection" {
  default = true
}

variable "region" {
  default = "us-west4"
}

variable "zone" {
  default = "us-west4-b"
}
