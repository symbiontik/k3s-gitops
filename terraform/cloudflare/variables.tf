variable "CLOUDFLARE_EMAIL" {
 type        = string
 description = "Email for your Cloudflare account"
 default     = null
}

variable "CLOUDFLARE_APIKEY" {
 type        = string
 description = "API Key for your Cloudflare account"
 default     = null
}

variable "CLOUDFLARE_DOMAIN" {
 type        = string
 description = "Your Cloudflare domain name"
 default     = null
}

variable "PUBLIC_IP_ADDRESS" {
 type        = string
 description = "Your public IP address"
 default     = null
}

variable "SERVICE_LIST" {
 type        = list
 description = "Your list of services"
 default     = null
}