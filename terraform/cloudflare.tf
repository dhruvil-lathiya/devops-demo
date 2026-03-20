################################################################################
# Cloudflare - Look up existing zone
################################################################################

data "cloudflare_zone" "main" {
  name = var.domain_name
}

################################################################################
# ACM Certificate Validation Records (in Cloudflare)
################################################################################

resource "cloudflare_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      value = dvo.resource_record_value
      type  = dvo.resource_record_type
    }
  }

  zone_id = data.cloudflare_zone.main.id
  name    = each.value.name
  content = each.value.value
  type    = each.value.type
  ttl     = 60
  proxied = false
}

################################################################################
# Application DNS Record (CNAME to ALB)
################################################################################

resource "cloudflare_record" "app" {
  zone_id = data.cloudflare_zone.main.id
  name    = var.subdomain
  content = aws_lb.main.dns_name
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

# NOTE: Set Cloudflare SSL/TLS mode to "Full (Strict)" in the Cloudflare
# dashboard for end-to-end encryption. Requires Zone Settings permission
# on the API token to manage via Terraform.
