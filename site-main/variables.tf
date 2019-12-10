variable "region" {
  default = "us-east-1"
}

variable "domain" {
  type = string
}

variable "site_bucket_name" {
  type        = string
  description = "The name of the S3 bucket to create to hold the site."
}

variable "logs_bucket_name" {
  type        = string
  description = "The name of the S3 bucket to create to hold access logs"
}

variable "duplicate_content_penalty_secret" {
  type = string
}

variable "deployer" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "routing_rules" {
  type    = string
  default = ""
}

variable "default_root_object" {
  type    = string
  default = "index.html"
}

variable "not_found_response_path" {
  type    = string
  default = "/404.html"
}

variable "tags" {
  type        = map(string)
  description = "Optional Tags"
  default     = {}
}

variable "trusted_signers" {
  type    = list(string)
  default = []
}

variable "forward_query_string" {
  type        = bool
  description = "Forward the query string to the origin"
  default     = false
}

variable "price_class" {
  type        = string
  description = "CloudFront price class"
  default     = "PriceClass_200"
}
