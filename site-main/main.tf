################################################################################################################
## Creates a setup to serve a static website from an AWS S3 bucket, with a Cloudfront CDN and
## certificates from AWS Certificate Manager.
##
## Bucket name restrictions:
##    http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
##
## Duplicate Content Penalty protection:
##    Description: https://support.google.com/webmasters/answer/66359?hl=en
##    Solution: http://tuts.emrealadag.com/post/cloudfront-cdn-for-s3-static-web-hosting/
##        Section: Restricting S3 access to Cloudfront
##
## Deploy remark:
##    Do not push files to the S3 bucket with an ACL giving public READ access, e.g s3-sync --acl-public
##
## 2016-05-16
##    AWS Certificate Manager supports multiple regions. To use CloudFront with ACM certificates, the
##    certificates must be requested in region us-east-1
################################################################################################################

locals {
  tags = merge(
    var.tags,
    {
      "domain" = var.domain
    },
    )
}

################################################################################################################
## Configure the bucket and static website hosting
################################################################################################################
data "template_file" "bucket_policy" {
  template = file("${path.module}/website_bucket_policy.json")

  vars = {
    bucket = var.site_bucket_name
    secret = var.duplicate_content_penalty_secret
  }
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = var.logs_bucket_name
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = var.site_bucket_name
  policy = data.template_file.bucket_policy.rendered

  website {
    index_document = "index.html"
    error_document = "error.html"
    routing_rules  = var.routing_rules
  }

  logging {
    target_bucket = "${aws_s3_bucket.logs_bucket.id}"
    target_prefix = "${var.domain}/"
  }

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = "${aws_s3_bucket.website_bucket.id}"

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
  name = var.deployer
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

resource "aws_iam_policy_attachment" "site-deployer-attach-user-policy" {
  name       = "${var.site_bucket_name}-deployer-policy-attachment"
  users      = [var.deployer]
  policy_arn = aws_iam_policy.site_deployer_policy.arn
}

################################################################################################################
## Create a Cloudfront distribution for the static website
################################################################################################################
resource "aws_cloudfront_distribution" "website_cdn" {
  enabled      = true
  price_class  = var.price_class
  http_version = "http2"

  origin {
    origin_id   = "origin-bucket-${aws_s3_bucket.website_bucket.id}"
    domain_name = aws_s3_bucket.website_bucket.website_endpoint

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1"]
    }

    custom_header {
      name  = "User-Agent"
      value = var.duplicate_content_penalty_secret
    }
  }

  default_root_object = var.default_root_object

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = "360"
    response_code         = "200"
    response_page_path    = "/${var.not_found_response_path}"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "DELETE", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = var.forward_query_string

      cookies {
        forward = "none"
      }
    }

    trusted_signers = var.trusted_signers

    min_ttl          = "0"
    default_ttl      = "300"  //3600
    max_ttl          = "1200" //86400
    target_origin_id = "origin-bucket-${aws_s3_bucket.website_bucket.id}"

    // This redirects any HTTP request to HTTPS. Security first!
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  aliases = [var.domain]
  tags    = local.tags
}
