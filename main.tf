provider "aws" {
  version = "~> 2.41"
  profile = "default"
  region  = var.region
}

provider "template" {
  version = "~> 2.1"
}

module "site-main" {
  source           = "./site-main"
  region           = var.region
  domain           = var.domain
  site_bucket_name = "genehack.blog-site"
  //  logs_bucket_name = "genehack.blog-logs"
  duplicate_content_penalty_secret = "FtgDeqHZgjbfGCH4zKgKEk4qxyYhE#"
  deployer                         = "genehack.blog-deployer"
  acm_certificate_arn              = "FIXME"
  not_found_response_path          = "error.html"
}
