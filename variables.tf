variable "cloudfront_secret" {
  type        = "string"
  description = "Either put this value in a TF_VARS_cloudfront_secret env var or pass it on the command line."
}

variable "domain" {
  type        = "string"
  description = "The domain your site will be hosted at."
  default     = "genehack.blog"
}

variable "region" {
  type        = "string"
  description = "The AWS region where you want to deploy resources."
  default     = "us-west-1"
}
