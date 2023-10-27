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