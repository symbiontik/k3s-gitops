# Add a record for traefik to your domain
resource "cloudflare_record" "traefik2" {
  name    = "traefik2"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "CNAME"
  ttl     = 1
}