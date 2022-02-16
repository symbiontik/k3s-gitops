# Allowing access to group_example access group only
resource "cloudflare_access_policy" "policy_example" {
  application_id = cloudflare_access_application.application_example.aud
  zone_id        = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name           = "policy_example"
  precedence     = "1"
  decision       = "allow"

  include {
    group = [cloudflare_access_group.group_example.id]
  }

  require {
    email_domain = ["example.com"]
  }
}