resource "tfe_variable" "terraform_cloud_token" {
  key          = "TERRAFORM_CLOUD_TOKEN"
  value        = var.TERRAFORM_CLOUD_TOKEN
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.terraform_cloud.id
  description  = "a useful description"
}

resource "tfe_variable" "terraform_cloud_email" {
  key          = "TERRAFORM_CLOUD_EMAIL"
  value        = var.TERRAFORM_CLOUD_EMAIL
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.terraform_cloud.id
  description  = "a useful description"
}

resource "tfe_variable" "cloudflare_email" {
  key          = "CLOUDFLARE_EMAIL"
  value        = var.CLOUDFLARE_EMAIL
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
  description  = "a useful description"
}

resource "tfe_variable" "cloudflare_apikey" {
  key          = "CLOUDFLARE_APIKEY"
  value        = var.CLOUDFLARE_APIKEY
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
  description  = "a useful description"
}

resource "tfe_variable" "cloudflare_domain" {
  key          = "CLOUDFLARE_DOMAIN"
  value        = var.CLOUDFLARE_DOMAIN
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
  description  = "a useful description"
}

resource "tfe_variable" "cloudflare_team_name" {
  key          = "CLOUDFLARE_TEAM_NAME"
  value        = var.CLOUDFLARE_TEAM_NAME
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
  description  = "a useful description"
}

resource "tfe_variable" "public_ip_address" {
  key          = "PUBLIC_IP_ADDRESS"
  value        = var.PUBLIC_IP_ADDRESS
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
  description  = "a useful description"
}