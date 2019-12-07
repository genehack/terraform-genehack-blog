provider "aws" {
  version = "~> 2.41"
  profile = "default"
  region = var.region
}

provider "template" {
  version = "~> 2.1"
}

module "site-main" {
  source = "./site-main"
  region = var.region
  domain = "genehack.blog"
  site_bucket_name = "genehack.blog-site"
  //  logs_bucket_name = "genehack.blog-logs"
  duplicate-content-penalty-secret = "FtgDeqHZgjbfGCH4zKgKEk4qxyYhE#"
  deployer = "genehack.blog-deployer"
  acm-certificate-arn = "fixme"
  not-found-response-path = "error.html"  
}
