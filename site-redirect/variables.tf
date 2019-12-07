variable "region" {
  type    = string
  default = "us-east-1"
}

variable "domain" {
  type = string
}

variable "target" {
  type = string
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

variable "tags" {
  type        = map(string)
  description = "Optional Tags"
  default     = {}
}

variable "price_class" {
  type        = string
  description = "CloudFront price class"
  default     = "PriceClass_200"
}

variable "default_root_object" {
  type        = string
  description = "CloudFront default root object"
  default     = "index.html"
}
