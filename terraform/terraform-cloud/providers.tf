terraform {

  required_providers {
    tfe = {
      source  = "cloudflare/cloudflare"
      version = "0.29.0"
    }
  }
}

provider "tfe" {
  hostname = var.TERRAFORM_CLOUD_HOSTNAME
  token    = var.TERRAFORM_CLOUD_TOKEN
}