resource "tfe_oauth_client" "github_oauth" {
  organization     = var.TERRAFORM_ORGANIZATION_NAME
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  oauth_token      = var.GITHUB_PERSONAL_ACCESS_TOKEN
  service_provider = "github"
}