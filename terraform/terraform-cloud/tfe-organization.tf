resource "tfe_organization" "k3s_gitops" {
  name  = "k3s_gitops"
  email = var.TERRAFORM_CLOUD_EMAIL
}