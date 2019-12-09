// Create Route53 zone

resource "aws_route53_zone" "main" {
  name = var.domain
  comment = var.comment
}
