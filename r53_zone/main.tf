// Create Route53 zone

// define a special provider for us-east-1 to force cert and cert verifier into that region
provider "aws" {
  version = "~> 2.41"
  profile = "default"
  region  = "us-east-1"
  alias   = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.us-east-1
  domain_name       = var.domain
  validation_method = "DNS"
}

resource "aws_route53_zone" "main" {
  name    = var.domain
  comment = var.comment
}

resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  zone_id = aws_route53_zone.main.id
  records = [aws_acm_certificate.cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}
