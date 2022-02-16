# Allowing `admin1@example.com` and `admin2@example.com` to access but only when coming from a
# specific domain.
resource "cloudflare_access_group" "group_example" {
  zone_id        = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name           = "group_example"

  include {
    email = ["admin1@example.com","admin2@example.com"]
  }

  require {
    email_domain = ["example.com"]
  }
}