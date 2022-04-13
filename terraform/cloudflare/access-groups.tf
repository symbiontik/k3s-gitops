# Cloudflare Access Group defintion for administrators
resource "cloudflare_access_group" "administrators" {
  zone_id        = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name           = "administrators"

  include {
    email = [var.CLOUDFLARE_EMAIL]
  }

  require {
    email_domain = [var.CLOUDFLARE_DOMAIN]
  }
}