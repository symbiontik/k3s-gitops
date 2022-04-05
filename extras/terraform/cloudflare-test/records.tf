# Add a record for traefik to your domain
resource "cloudflare_record" "traefik" {
  name    = "traefik"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}

# Add a record for home-assistant to your domain
resource "cloudflare_record" "hass" {
  name    = "hass"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}

# Add a record for vscode to your domain
resource "cloudflare_record" "vscode" {
  name    = "vscode"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}

# Add a record for influxdb to your domain
resource "cloudflare_record" "influxdb" {
  name    = "influxdb"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}

# Add a record for grafana to your domain
resource "cloudflare_record" "grafana" {
  name    = "grafana"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}

# Add a record for grafana to your domain
resource "cloudflare_record" "prometheus" {
  name    = "prometheus"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}

# Add a record for grafana to your domain
resource "cloudflare_record" "jaeger" {
  name    = "jaeger"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}

# Add a record for grafana to your domain
resource "cloudflare_record" "code-server" {
  name    = "code-server"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}