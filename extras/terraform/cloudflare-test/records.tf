# Add a record to the domain
resource "cloudflare_record" "private_ip_example" {
  zone_id = var.BOOTSTRAP_CLOUDFLARE_ZONE_ID
  name    = "private_ip_example"
  value   = "192.168.0.11"
  type    = "A"
  ttl     = 1
}

# Add a record to the domain
resource "cloudflare_record" "public_ip_example" {
  zone_id = var.BOOTSTRAP_CLOUDFLARE_ZONE_ID
  name    = "public_ip_example"
  proxied = true
  value   = "8.8.8.8"
  type    = "A"
  ttl     = 1
}