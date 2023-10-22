variable "managed_connection" {
  default = true
}

variable "needs_cert" {
  default     = false
  description = "Allow HTTPS access to the instance for certificate initialization"
  type        = bool
}

variable "region" {
  default = "europe-west2"
}

variable "zone" {
  default = "europe-west2-b"
}
