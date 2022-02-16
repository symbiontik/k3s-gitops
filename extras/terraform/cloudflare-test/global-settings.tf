# Add resources for Cloudflare global settings
resource "cloudflare_zone_settings_override" "cloudflare_settings" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  settings {
    # /ssl-tls
    ssl = "strict"
    # /ssl-tls/edge-certificates
    always_use_https         = "on"
    min_tls_version          = "1.0"
    opportunistic_encryption = "on"
    #my setting for tls 1_3: on
    tls_1_3                  = "zrt"
    automatic_https_rewrites = "on"
    universal_ssl            = "on"
    # /firewall/settings
    browser_check  = "on"
    challenge_ttl  = 1800
    privacy_pass   = "on"
    security_level = "medium"
    # /speed/optimization
    brotli = "on"
    # my setings for all these: off
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    #my setting for rocket_loader: off
    rocket_loader = "on"
    # /caching/configuration
    #my setting for always_online: on
    always_online    = "off"
    development_mode = "off"
    #browser_cache_ttl           = 14400
    #browser_check               = "on"
    #cache_level                 = "aggressive"
    # /network
    #my setting for http3: off
    http3               = "on"
    #my setting for zero_rtt: off
    zero_rtt            = "on"
    ipv6                = "on"
    websockets          = "on"
    opportunistic_onion = "on"
    pseudo_ipv4         = "off"
    ip_geolocation      = "on"
    # /content-protection
    email_obfuscation   = "on"
    server_side_exclude = "on"
    hotlink_protection  = "off"
    # /workers
    security_header {
      enabled = false
    }
    # other settings I have
    #cname_flattening            = "flatten_at_root"
    #early_hints                 = "off"
    #filter_logs_to_cloudflare   = "off"
    #http2                       = "on"
    #log_to_cloudflare           = "on"
    #max_upload                  = 100
    #mirage                      = "off"
    #orange_to_orange            = "off"
    #origin_error_page_pass_thru = "off"
    #polish                      = "off"
    #prefetch_preload            = "off"
    #proxy_read_timeout          = "100"
    #response_buffering          = "off"
    #sort_query_string_for_cache = "off"
    #tls_1_2_only                = "off"
    #tls_client_auth             = "on"
    #true_client_ip_header       = "off"
    #visitor_ip                  = "on"
    #waf                         = "off"
    #webp                        = "off"
  }
}