variable "TERRAFORM_CLOUD_EMAIL" {
 type        = string
 description = "Email for your Terraform Cloud account"
 default     = null
}

variable "TERRAFORM_CLOUD_TOKEN" {
 type        = string
 description = "API Token for your Terraform Cloud account"
 default     = null
}

variable "TERRAFORM_ORGANIZATION_NAME" {
 type        = string
 description = "Your Terraform organization name"
 default     = null
}

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

variable "CLOUDFLARE_TEAM_NAME" {
 type        = string
 description = "Your Cloudflare team name"
 default     = null
}

variable "PUBLIC_IP_ADDRESS" {
 type        = string
 description = "Your public IP address"
 default     = null
}

variable "GITHUB_PERSONAL_ACCESS_TOKEN" {
 type        = string
 description = "Your GitHub Personal Access Token"
 default     = null
}