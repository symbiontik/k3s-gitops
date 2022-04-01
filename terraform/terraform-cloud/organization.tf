resource "tfe_organization" "k3s-gitops" {
  name  = "k3s-gitops"
  email = var.TERRAFORM_CLOUD_EMAIL
}

resource "tfe_workspace" "cloudflare" {
  name              = "cloudflare"
  organization      = tfe_organization.k3s-gitops.id
  auto_apply        = true
  working_directory = "terraform/cloudflare"
}

resource "tfe_workspace" "terraform-cloud" {
  name              = "terraform-cloud"
  organization      = tfe_organization.k3s-gitops.id
  auto_apply        = true
  working_directory = "terraform/terraform-cloud"
}

resource "tfe_variable" "terraform_cloud_email" {
  key          = "TERRAFORM_CLOUD_EMAIL"
  value        = var.TERRAFORM_CLOUD_EMAIL
  sensitive    = true
  category     = "terraform"
  workspace_id = tfe_workspace.terraform-cloud.id
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