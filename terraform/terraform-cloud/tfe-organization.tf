resource "tfe_organization" "k3s_gitops" {
  name  = var.CLOUDFLARE_TEAM_NAME
  email = var.TERRAFORM_CLOUD_EMAIL
}