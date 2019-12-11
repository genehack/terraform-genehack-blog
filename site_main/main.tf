// Configure S3 buckets, IAM user, CloudFront

// Make a random string to use as the cloudfront secret

// If you make an S3 bucket available as the source for a CloudFront
// distribution, you have the risk of search bots to index both this
// source bucket and the distribution. Google _punishes_ you for this
// as you can read in
// https://support.google.com/webmasters/answer/66359?hl=en.

// We need to protect access to the source bucket. There are 2 options
// to do this: using an Origin Access User between the CloudFront
// distribution and the source S3 bucket, or using custom headers
// between the distribution and the bucket. The use of an Origin
// Access User prevents accessing the source bucket in REST mode,
// which results in bucket redirects not being followed. Consequently,
// this module uses the custom header option.

resource "random_password" "cloudfront_secret" {
  length  = 24
  special = false // don't use special characters just to avoid any hassles
}

// Configure the buckets and static website hosting
data "template_file" "bucket_policy" {
  template = file("${path.module}/site_bucket_policy.json")

  vars = {
    bucket = var.site_bucket_name
    secret = random_password.cloudfront_secret.result
  }
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = var.logs_bucket_name
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket" "site_bucket" {
  bucket = var.site_bucket_name
  policy = data.template_file.bucket_policy.rendered

  website {
    index_document = "index.html"
    error_document = "error.html"
    routing_rules  = var.routing_rules
  }

  logging {
    target_bucket = aws_s3_bucket.logs_bucket.id
    target_prefix = "${var.domain}/"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.site_bucket.id

  // Block public access to buckets and objects granted through new
  // access control lists (ACLs)
  block_public_acls = true

  // Block public access to buckets and objects granted through any
  // access control lists (ACLs)
  block_public_policy = true

  // Block public access to buckets and objects granted through new
  // public bucket or access point policies
  ignore_public_acls = true

  // Block public and cross-account access to buckets and objects
  // through any public bucket or access point policies
  restrict_public_buckets = false
}

// Create a deployment user and configure access
resource "aws_iam_user" "deployer_user" {
  name          = var.deployer
  force_destroy = true
}

data "template_file" "deployer_role_policy_file" {
  template = file("${path.module}/deployer_role_policy.json")

  vars = {
    bucket = var.site_bucket_name
  }
}

resource "aws_iam_policy" "site_deployer_policy" {
  name        = "${var.site_bucket_name}.deployer"
  path        = "/"
  description = "Policy allowing to publish a new version of the website to the S3 bucket"
  policy      = data.template_file.deployer_role_policy_file.rendered
}

resource "aws_iam_policy_attachment" "site_deployer_attach_user_policy" {
  name       = "${var.site_bucket_name}-deployer-policy-attachment"
  users      = [var.deployer]
  policy_arn = aws_iam_policy.site_deployer_policy.arn
}

// Create a Cloudfront distribution for the static website
resource "aws_cloudfront_distribution" "website_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.price_class
  http_version        = "http2"
  default_root_object = var.default_root_object
  aliases             = [var.domain]

  origin {
    origin_id   = "origin-bucket-${aws_s3_bucket.site_bucket.id}"
    domain_name = aws_s3_bucket.site_bucket.website_endpoint

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "User-Agent"
      value = random_password.cloudfront_secret.result
    }
  }

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = "360"
    response_code         = "404"
    response_page_path    = "/${var.not_found_response_path}"
  }

  default_cache_behavior {
    min_ttl                = "0"
    default_ttl            = "3600"
    max_ttl                = "3600"
    target_origin_id       = "origin-bucket-${aws_s3_bucket.site_bucket.id}"
    viewer_protocol_policy = "redirect-to-https" // This redirects any HTTP request to HTTPS. Security first!
    compress               = true

    allowed_methods = ["GET", "HEAD", "DELETE", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = var.forward_query_string

      cookies { forward = "none" }
    }
    trusted_signers = var.trusted_signers

  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}
