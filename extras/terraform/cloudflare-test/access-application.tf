#Add an Access application for traefik
resource "cloudflare_access_application" "terraform_managed_resource_89e30e1b-8321-43d8-85a8-7162bff9a31f" {
  zone_id              = lookup(data.cloudflare_zones.domain.zones[0], "id")
  app_launcher_visible = true
  domain               = "traefik.${var.BOOTSTRAP_CLOUDFLARE_DOMAIN}"
  name                 = "traefik"
  session_duration     = "12h"
  type                 = "self_hosted"
}