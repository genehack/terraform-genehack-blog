// define providers
provider "aws" {
  version = "~> 2.41"
  profile = "default"
  region  = var.region
}
provider "template" { version = "~> 2.1" }

// set up route53 zone and certificate
module "r53-zone" {
  source  = "./r53-zone"
  domain  = "${var.domain}"
  comment = "Zone for ${var.domain} // Managed by Terraform"
}

// set up S3 buckets, IAM user, policies, and cloudfront
module "site-main" {
  source                  = "./site-main"
  region                  = "${var.region}"
  domain                  = "${var.domain}"
  site_bucket_name        = "${var.domain}-site"
  logs_bucket_name        = "${var.domain}-logs"
  cloudfront_secret       = "${var.cloudfront_secret}"
  deployer                = "${var.domain}-deployer"
  acm_certificate_arn     = "${module.r53-zone.certificate_arn}"
  not_found_response_path = "error.html"
}

// set up ALIAS entry to map to cloudfront distribution
module "r53-alias" {
  source             = "./r53-alias"
  domain             = "${var.domain}"
  target             = "${module.site-main.website_cdn_hostname}"
  cdn_hosted_zone_id = "${module.site-main.website_cdn_zone_id}"
  route53_zone_id    = "${module.r53-zone.zone_id}"
}
