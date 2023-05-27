terraform {

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.6.0"
    }
  }
}

provider "cloudflare" {
  email   = var.CLOUDFLARE_EMAIL
  api_key = var.CLOUDFLARE_APIKEY
}