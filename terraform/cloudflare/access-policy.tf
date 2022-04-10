# Cloudflare Access Policy definition for each Access Application
resource "cloudflare_access_policy" "administrator_policy" {

  # One cloudflare_access_policy for each element of var.SERVICE_LIST
  for_each = toset( var.SERVICE_LIST )

  # each value here is a value from var.SERVICE_LIST
  name   = "${each.key}-policy"

  application_id =cloudflare_access_application.access_application[each.key].aud
  zone_id        = lookup(data.cloudflare_zones.domain.zones[0], "id")
  precedence     = "1"
  decision       = "allow"

  include {
    group = [cloudflare_access_group.administrators.id]
  }

  require {
    email_domain = ["var.BOOTSTRAP_CLOUDFLARE_DOMAIN"]
  }
}