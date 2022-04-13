terraform {
  
  required_providers {
    tfe = {
      version = "~> 0.30.2"
    }
  }
}

provider "tfe" {
  token   = var.TERRAFORM_CLOUD_TOKEN
}