# Add a record to the domain
resource "cloudflare_record" "ipv4" {
  name    = "ipv4"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}

# Add a record to the domain
resource "cloudflare_record" "root" {
  name    = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ipv4.${var.PUBLIC_IP_ADDRESS}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

# Add a record to the domain
resource "cloudflare_record" "traefik2" {
  name    = "traefik2"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ipv4.${var.PUBLIC_IP_ADDRESS}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}