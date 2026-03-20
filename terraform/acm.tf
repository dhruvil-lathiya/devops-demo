################################################################################
# ACM Certificate
################################################################################

resource "aws_acm_certificate" "main" {
  domain_name       = "${var.subdomain}.${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Name = "${var.project_name}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# ACM DNS Validation (waits for Cloudflare records to propagate)
################################################################################

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in cloudflare_record.cert_validation : record.hostname]
}
