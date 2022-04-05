# Data lookup for your Cloudflare zones using your Cloudflare domain name
data "cloudflare_zones" "domain" {
  filter {
    name = var.BOOTSTRAP_CLOUDFLARE_DOMAIN
  }
}

# Add a DNS record for each item in var.SERVICE_LIST
resource "cloudflare_record" "dns" {

  # One cloudflare_record for each element of var.SERVICE_LIST
  for_each = var.SERVICE_LIST
  #for_each = toset( ["test1", "test2", "test3", "test4"] )

  # each.value here is a value from var.SERVICE_LIST
  #name = each.value
  name     = each.key

  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = var.PUBLIC_IP_ADDRESS
  proxied = true
  type    = "A"
  ttl     = 1
}