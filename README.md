# Terraform setup for S3 static site with CloudFront, Certificate Manager and Route53

This Git repository contains the required
[Terraform](https://www.terraform.io/) scripts to setup a static
website, hosted out of an S3 bucket. The site is fronted by a
CloudFront distribution, uses AWS Certificate Manager for HTTPS, and
handles creating a DNS zone and configures the required DNS entries in
Route53. The files in this repo only support hosting a site on a
"naked" or "apex" domain (e.g., on `example.com`). The repo doesn't
configure the extra bits required to also have the site respond on a
sub-domain (e.g., on `www.example.com`). If you need that, you might
want to look at
[the repo](https://github.com/skyscrapers/terraform-website-s3-cloudfront-route53)
this repo was forked from.

The scripts also take care of:

* Preventing the origin bucket being indexed by search bots.
* Access logging
* Redirecting HTTP to HTTPS

## Introduction

This repository is split into 3 parts, each of which can be used as a
separate module in your own root script. You can see a working example
of such a script in the `main.tf` file in this repo.

* `r53_zone`: configuration of a Route53 zone and ACM cert with
  DNS-based validations
* `site_main`: setup of the site and logging S3 buckets with a
  CloudFront distribution in front of the site bucket
* `r53_alias`: configuration of a Route53 ALIAS record pointing to a
  CloudFront distribution

## Top-level variables

You'll want to set up a few top level variables (or modify the default
values of the ones in `variables.tf`): `domain` and `region`.

## Setting up the Route53 zone and ACM certs

Creating a Route53 zone corresponding to your domain, as well as
requesting a certificate in ACM and setting up the appropriate DNS
records to validate that cert, can be done as follows:

    module "r53_zone" {
      source  = "./r53_zone"
      domain  = "${var.domain}"
      comment = "Zone for ${var.domain} // Managed by Terraform"
    }

Note: this step requires you to have your DNS properly configured, or
the certificate validation _*will*_ time out. When bootstraping, you
can go into the AWS console, extract the provisioned DNS servers, and
configure your DNS server entries. If you don't get this done in time
and the certification validation fails, you can just re-run `terraform
apply`.

### Inputs

* `domain`: The domain you're going to be hosting the site at.
* `comment` (Optional): Comment to associate with the zone

### Outputs

* `zone_id`: Zone ID of the Route53 zone that was created
* `certificate_arn`: ARN of the created certificate from ACM
* `name_servers`: List of name servers for the created Route53 zone

## Setting up the main site

Creating all the resources for an S3-based static website, including
an IAM deployer user, with a CloudFront distribution, using the
appropriate SSL certificates is as easy as using the `site_main`
module and passing the appropriate variables:

    module "site_main" {
     source                  = "./site_main"
     region                  = "${var.region}"
     domain                  = "${var.domain}"
     site_bucket_name        = "${var.domain}-site"
     logs_bucket_name        = "${var.domain}-logs"
     deployer                = "${var.domain}-deployer"
     acm_certificate_arn     = "${module.r53_zone.certificate_arn}"
     not_found_response_path = "error.html"
    }

### Inputs

* `region`: the AWS region where the S3 bucket will be created. The
  source bucket can be created in any of the available regions. The
  default value is `us-east-1`.
* `domain`: the domain name by which you want to make the website
  available on the Internet. While we are not at the point of setting
  up the DNS part, the CloudFront distribution needs to know which
  domain it needs to accept requests for.
* `site_bucket_name`: the name of the bucket to create for the S3 based
  static website. Note that this needs to be globally unique across
  all AWS S3 buckets!
* `logs_bucket_name`: the name of the bucket to create for access
  logging. Also needs to be globally unique.
* `deployer`: the name of an IAM user that will be created to be used
  to push contents to the S3 bucket. This user will get a role policy
  attached to it, configured to have read/write access to the bucket
  that will be created.
* `acm_certificate_arn`: the id of an certificate in AWS Certificate
  Manager. As this certificate will be used on a CloudFront
  distribution, Amazon's documentation states the certificate must be
  generated in the `us-east-1` region.
* `default_root_object`: (Optional) default root object to be served
  by CloudFront. Defaults to `index.html`, but can be e.x.
  `v1.0.0/index.html` for versioned applications.
* `not_found_response_path`: response path for the file that should be
  served on 404. Default to `/404.html`, but can be e.x. `/index.html`
  for single page applications.
* `forward_query_string`: (Optional) Forward the query string to the
  origin. Default value = `false`
* `price_class`: (Optional) The price class that corresponds with the
  maximum price that you want to pay for CloudFront service. Read
  [pricing page](https://aws.amazon.com/cloudfront/pricing/) for more
  details. Options: `PriceClass_100` | `PriceClass_200` |
  `PriceClass_All`. Default value = `PriceClass_200`

### Outputs

* `website_cdn_hostname`: the Amazon generated Cloudfront domain name.
  You can already test accessing your website content by this
  hostname. This hostname is needed later on to create a `CNAME`
  record in Route53.
* `website_cdn_zone_id`: the Hosted Zone ID of the Cloudfront
  distribution. This zone ID is needed later on to create a Route53
  `ALIAS` record.
* `site_bucket_id`: The website bucket id
* `site_bucket_arn`: The website bucket arn
* `website_cdn_id`: The CDN ID of the Cloudfront distribution.
* `website_cdn_arn`: The ARN of the CDN

## Setting up the Route 53 ALIAS

Whether it is a main site or a redirect site, an ALIAS DNS record is
needed for your site to be accessed on a root domain.

    module "r53_alias" {
      source             = "./r53_alias"
      domain             = "${var.domain}"
      target             = "${module.site_main.website_cdn_hostname}"
      cdn_hosted_zone_id = "${module.site_main.website_cdn_zone_id}"
      route53_zone_id    = "${module.r53_zone.zone_id}"
    }

### Inputs

* `domain`: the domain name you want to use to access your static
  website. This should match the domain name used in setting up either
  a main or a redirect site.
* `target`: the domain name of the CloudFront distribution to which
  the domain name should point. You usually pass the
  `website_cdn_hostname` output variable from the main or redirect
  site here.
* `cdn_hosted_zone_id`: the Hosted Zone ID of the CloudFront
  distribution. You usually pass the `website_cdn_zone_id` output
  variable from the main or redirect site here.
* `route53_zone_id`: the Route53 Zone ID where the CNAME entry must be
  created.

## Credits

This repository is forked from
[https://github.com/skyscrapers/terraform-website-s3-cloudfront-route53](https://github.com/skyscrapers/terraform-website-s3-cloudfront-route53)
but has undergone significant revision.

**Enjoy!**
