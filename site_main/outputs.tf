output "website_cdn_hostname" {
  value = aws_cloudfront_distribution.website_cdn.domain_name
}

output "website_cdn_id" {
  value = aws_cloudfront_distribution.website_cdn.id
}

output "website_cdn_arn" {
  value = aws_cloudfront_distribution.website_cdn.arn
}

output "website_cdn_zone_id" {
  value = aws_cloudfront_distribution.website_cdn.hosted_zone_id
}

output "site_bucket_id" {
  value = aws_s3_bucket.site_bucket.id
}

output "site_bucket_arn" {
  value = aws_s3_bucket.site_bucket.arn
}
