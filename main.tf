// define providers
provider "aws" {
  version = "~> 2.41"
  profile = "default"
  region  = var.region
}

provider "template" {
  version = "~> 2.1"
}

// FIXME need r53 zone

// FIXME need IAM user for deployment

module "site-main" {
  source           = "./site-main"
  region           = var.region
  domain           = var.domain
  site_bucket_name = "genehack.blog-site"
  // FIXME set up logging bucket
  //  logs_bucket_name = "genehack.blog-logs"
  duplicate_content_penalty_secret = "FtgDeqHZgjbfGCH4zKgKEk4qxyYhE#"
  deployer                         = "genehack.blog-deployer"
  acm_certificate_arn              = "FIXME"
  not_found_response_path          = "error.html"
}

module "r53-alias" {
  source             = "./r53-alias"
  domain             = var.domain
  target             = "${module.site-main.website_cdn_hostname}"
  cdn_hosted_zone_id = "${module.site-main.website_cdn_zone_id}"
  route53_zone_id    = "<r53-zone-id>"
}
