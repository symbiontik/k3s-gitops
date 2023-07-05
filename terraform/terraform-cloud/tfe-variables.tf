# Cloudflare Workspace Variables

resource "tfe_variable" "cloudflare_email" {
  key          = "CLOUDFLARE_EMAIL"
  value        = var.CLOUDFLARE_EMAIL
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
}

resource "tfe_variable" "example" {
  key          = "example_key"
  value        = "EXAMPLE"
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
}

resource "tfe_variable" "cloudflare_apikey" {
  key          = "CLOUDFLARE_APIKEY"
  value        = var.CLOUDFLARE_APIKEY
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
}

resource "tfe_variable" "cloudflare_domain" {
  key          = "CLOUDFLARE_DOMAIN"
  value        = var.CLOUDFLARE_DOMAIN
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
}

resource "tfe_variable" "cloudflare_access_email" {
  key          = "CLOUDFLARE_ACCESS_EMAIL"
  value        = var.CLOUDFLARE_ACCESS_EMAIL
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
}

resource "tfe_variable" "public_ip_address" {
  key          = "PUBLIC_IP_ADDRESS"
  value        = var.PUBLIC_IP_ADDRESS
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
}

resource "tfe_variable" "cloudflare_oauth_client_id" {
  key          = "CLOUDFLARE_OAUTH_CLIENT_ID"
  value        = var.CLOUDFLARE_OAUTH_CLIENT_ID
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
}

resource "tfe_variable" "cloudflare_oauth_client_secret" {
  key          = "CLOUDFLARE_OAUTH_CLIENT_SECRET"
  value        = var.CLOUDFLARE_OAUTH_CLIENT_SECRET
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.cloudflare.id
}