resource "tfe_workspace" "cloudflare" {
  name              = "cloudflare"
  organization      = tfe_organization.k3s_gitops.id
  auto_apply        = true
  working_directory = "terraform/cloudflare/"
}

resource "tfe_workspace" "terraform_cloud" {
  name              = "terraform-cloud"
  organization      = tfe_organization.k3s_gitops.id
  auto_apply        = true
  working_directory = "terraform/terraform-cloud/"
}