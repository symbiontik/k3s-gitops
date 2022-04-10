resource "tfe_workspace" "cloudflare" {
  name              = "cloudflare"
  organization      = tfe_organization.k3s_gitops.id
  auto_apply        = true
  working_directory = "terraform/cloudflare/"
  vcs_repo {
    identifier  = "symbiontik/k3s-gitops"
    branch = "main"
    oauth_token_id = tfe_oauth_client.github_oauth.oauth_token_id
  }
}

resource "tfe_workspace" "terraform_cloud" {
  name              = "terraform-cloud"
  organization      = tfe_organization.k3s_gitops.id
  auto_apply        = true
  working_directory = "terraform/terraform-cloud/"
  vcs_repo {
    identifier  = "symbiontik/k3s-gitops"
    branch = "main"
    oauth_token_id = tfe_oauth_client.github_oauth.oauth_token_id
  }
}