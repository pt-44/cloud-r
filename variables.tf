variable "cloudflare_email" {
  description = "CloudFlare Account Email"
  type        = string
}

variable "cloudflare_api_key" {
  description = "CloudFlare Global API Key"
  type        = string
  sensitive   = true  # This ensures Terraform does not print this value in logs or outputs.
}

variable "cloudflare_zone_id" {
  description = "CloudFlare Zone ID"
  type        = string
}