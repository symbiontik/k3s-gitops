resource "tfe_organization" "k3s_gitops" {
  name  = "k3s-gitops"
  email = var.TERRAFORM_CLOUD_EMAIL
}