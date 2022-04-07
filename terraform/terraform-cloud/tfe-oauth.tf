resource "tfe_oauth_client" "github_oauth" {
  name             = "my-github-oauth-client"
  organization     = "my-org-name"
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  oauth_token      = var.GITHUB_PERSONAL_ACCESS_TOKEN
  service_provider = "github"
}