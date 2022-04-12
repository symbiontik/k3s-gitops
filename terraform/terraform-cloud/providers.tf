terraform {

  required_providers {
    tfe = {
      source  = "cloudflare/cloudflare"
      version = "3.12.2"
    }
  }
}

provider "tfe" {
  token    = var.TERRAFORM_CLOUD_TOKEN
}