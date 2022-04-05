# Cloudflare Access Policy definition for administrators
#resource "cloudflare_access_policy" "administrator_policy" {
#  application_id = cloudflare_access_application.application_example.aud
#  zone_id        = lookup(data.cloudflare_zones.domain.zones[0], "id")
#  name           = "administrator_policy"
#  precedence     = "1"
#  decision       = "allow"
#
#  include {
#    group = [cloudflare_access_group.administrators.id]
#  }
#
#  require {
#    email_domain = ["var.CLOUDFLARE_DOMAIN"]
#  }
#}