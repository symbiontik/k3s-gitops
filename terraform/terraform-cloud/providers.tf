terraform {

  required_providers {
    tfe = {
      source  = "cloudflare/cloudflare"
      version = "0.29.0"
    }
  }
}

provider "tfe" {
  token    = var.TERRAFORM_CLOUD_TOKEN
}