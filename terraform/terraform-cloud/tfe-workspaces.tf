resource "tfe_workspace" "cloudflare" {
  name              = "cloudflare"
  organization      = tfe_organization.tfe_organization.id
  auto_apply        = true
  working_directory = "terraform/cloudflare/"
  vcs_repo {
    identifier  = var.GITHUB_REPOSITORY_IDENTIFIER
    branch = "main"
    oauth_token_id = tfe_oauth_client.github_oauth.oauth_token_id
  }
  depends_on = [
    tfe_oauth_client.github_oauth
  ]
}