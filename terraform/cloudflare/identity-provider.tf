# Add GitHub OAuth identity provider
# https://developers.cloudflare.com/cloudflare-one/identity/idp-integration/github/
resource "cloudflare_access_identity_provider" "github_oauth" {
  zone_id    = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name       = "GitHub OAuth"
  type       = "github"
  config {
    client_id     = var.CLOUDFLARE_OAUTH_CLIENT_ID
    client_secret = var.CLOUDFLARE_OAUTH_CLIENT_SECRET
  }
}