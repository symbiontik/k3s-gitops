resource "tfe_organization" "tfe_organization" {
  name  = var.TERRAFORM_ORGANIZATION_NAME
  email = var.TERRAFORM_CLOUD_EMAIL
}