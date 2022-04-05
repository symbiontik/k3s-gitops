# # Add one time pin Identity Provider
# https://developers.cloudflare.com/cloudflare-one/identity/one-time-pin/
resource "cloudflare_access_identity_provider" "pin_login" {
  zone_id    = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name       = "PIN login"
  type       = "onetimepin"
}

# Add GitHub OAuth identity provider
# https://developers.cloudflare.com/cloudflare-one/identity/idp-integration/github/
#resource "cloudflare_access_identity_provider" "github_oauth" {
#  zone_id    = lookup(data.cloudflare_zones.domain.zones[0], "id")
#  name       = "GitHub OAuth"
#  type       = "github"
#  config {
#    client_id     = "example"
#    client_secret = "secret_key"
#  }
#}