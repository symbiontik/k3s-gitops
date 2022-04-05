#Add an Access application for traefik
#resource "cloudflare_access_application" "traefik" {
#  zone_id              = lookup(data.cloudflare_zones.domain.zones[0], "id")
#  app_launcher_visible = true
#  domain               = "traefik.${var.BOOTSTRAP_CLOUDFLARE_DOMAIN}"
#  name                 = "traefik"
#  session_duration     = "12h"
#  type                 = "self_hosted"
#}

# Create a module that just ingests the name 
# The module would create those two resource types (access and dns resources)
#
# Check out the tutorial on foreach() with Terraform
# Example: for_each(var.service_name)
#{
#    $TFVARS_FILE
#}
# Check out auto.tfvars file - must be in the same working directory as where you're running terraform
# Once you have the modules and these files, 
# You could either modularize it, or you could have foreach() on each type - access and dns records 