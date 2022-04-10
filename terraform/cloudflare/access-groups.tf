# Cloudflare Access Group defintion for administrators
resource "cloudflare_access_group" "administrators" {
  zone_id        = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name           = "administrators"

  include {
    email = ["var.BOOTSTRAP_CLOUDFLARE_EMAIL"]
  }

  require {
    email_domain = ["var.BOOTSTRAP_CLOUDFLARE_DOMAIN"]
  }
}