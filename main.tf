terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 2.0" # You can specify a version constraint if needed.
    }
  }
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

provider "aws" {
  region = "us-west-1" # Adjust the region as per your requirements.
}

resource "aws_s3_bucket" "cloudresume_pt2" {
  bucket = "cloudresume-pt2"

  tags = {
    Name = "cloudresume-pt2"
    Purpose = "Public Resume Storage"
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudresume_pt2" {
  bucket = aws_s3_bucket.cloudresume_pt2.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudresume_pt2" {
  bucket = aws_s3_bucket.cloudresume_pt2.bucket

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "cloudresume_pt2_acl" {
  bucket = aws_s3_bucket.cloudresume_pt2.bucket
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "cloudresume_pt2_policy" {
  bucket = aws_s3_bucket.cloudresume_pt2.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "arn:aws:s3:::cloudresume-pt2/*"
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "cloudresume_pt2_versioning" {
  bucket = aws_s3_bucket.cloudresume_pt2.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "cloudresume_pt2_cors" {
  bucket = aws_s3_bucket.cloudresume_pt2.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_website_configuration" "cloudresume_pt2_website" {
  bucket = aws_s3_bucket.cloudresume_pt2.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Outputs the website endpoint for the S3 bucket.
output "website_url" {
  value = "http://${aws_s3_bucket.cloudresume_pt2.bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}

data "aws_region" "current" {}

# AWS CloudFront Distribution
resource "aws_cloudfront_distribution" "cloudresume_distribution" {
  origin {
    domain_name = "cloudresume-pt2.s3.amazonaws.com"
    origin_id   = "cloudresumeS3Origin"
  }

  price_class = "PriceClass_100" # North America and Europe
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront Distribution for cloudresume-pt2"
  default_root_object = "index.html"

  aliases = ["resume.3lack.co"] # Alternate domain names

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "cloudresumeS3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:796608557876:certificate/7f0b76df-bbd0-4fa7-ae9e-b773fd702f54"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name    = "cloudresume-pt2-distribution"
    Purpose = "CloudFront Distribution for Public Resume Storage"
  }
}

# Output the CloudFront distribution's domain name (URL)
output "cloudfront_distribution_url" {
  value = aws_cloudfront_distribution.cloudresume_distribution.domain_name
}

resource "cloudflare_record" "resume_domain" {
  lifecycle {
    create_before_destroy = true
  }
  zone_id = var.cloudflare_zone_id
  name    = "resume.3lack.co"
  value   = aws_cloudfront_distribution.cloudresume_distribution.domain_name
  type    = "CNAME"
  ttl     = 1
  proxied = true
}