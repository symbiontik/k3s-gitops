variable "BOOTSTRAP_CLOUDFLARE_EMAIL" {
 type        = string
 description = "Email for your Cloudflare account"
 default     = null
}

variable "BOOTSTRAP_CLOUDFLARE_APIKEY" {
 type        = string
 description = "API Key for your Cloudflare account"
 default     = null
}

variable "BOOTSTRAP_CLOUDFLARE_ZONE_ID" {
 type        = string
 description = "Zone ID for your Cloudflare domain"
 default     = null
}