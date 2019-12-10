variable "cloudfront_secret" {
  type        = "string"
  description = "Either put this in a TF_VARS_cloudfront_secret env var or pass it on the command line."
}

variable "domain" {
  default = "genehack.blog"
}

variable "region" {
  default = "us-west-1"
}
