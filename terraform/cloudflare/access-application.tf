#Add an Access application for each item in var.SERVICE_LIST
resource "cloudflare_access_application" "access_application" {

  # One cloudflare_access_application for each element of var.SERVICE_LIST
  for_each = toset( var.SERVICE_LIST )

  # each value here is a value from var.SERVICE_LIST
  name     = each.key 

  # each value here is a value from var.SERVICE_LIST
  domain   = "${each.key}.${var.BOOTSTRAP_CLOUDFLARE_DOMAIN}"

  zone_id              = lookup(data.cloudflare_zones.domain.zones[0], "id")
  app_launcher_visible = true
  session_duration     = "12h"
  type                 = "self_hosted"
}