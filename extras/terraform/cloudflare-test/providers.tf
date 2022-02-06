terraform {

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.7.0"
    }
  }
}

provider "cloudflare" {
  email   = var.BOOTSTRAP_CLOUDFLARE_EMAIL
  api_key = var.BOOTSTRAP_CLOUDFLARE_APIKEY
}