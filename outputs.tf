output "name_servers" {
  value = module.r53_zone.name_servers
}

output "cloudfront_id" {
  value = module.site_main.website_cdn_id
}
