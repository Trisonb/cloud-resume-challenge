# Updated CI/CD test comment - May 28, 2025

data "aws_caller_identity" "current" {}

# Provider for Production Account
provider "aws" {
  profile = "prod-account"
  region  = "us-east-1"
  alias   = "prod"
}

terraform {
  backend "s3" {
    bucket  = "trison-terraform-state-1747864476"
    key     = "terraform.tfstate"
    region  = "us-east-1"
  }
}

# Random string for bucket name uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket for Production Static Website
resource "aws_s3_bucket" "website_bucket" {
  provider = aws.prod
  bucket   = "trison-cloud-resume-prod-${random_string.bucket_suffix.result}"
}

# S3 Bucket Public Access Block for Production
resource "aws_s3_bucket_public_access_block" "website_public_access" {
  provider                = aws.prod
  bucket                  = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for Production
resource "aws_s3_bucket_policy" "website_policy" {
  provider = aws.prod
  bucket   = aws_s3_bucket.website_bucket.id
  policy   = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/E1Z7J2MV57SJA1"
          }
        }
      }
    ]
  })
}

# CloudFront Distribution for Production
resource "aws_cloudfront_distribution" "website_cdn_prod" {
  provider = aws.prod
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "trison-cloud-resume-prod-${random_string.bucket_suffix.result}.s3.us-east-1.amazonaws.com"
    origin_access_control_id = "E3F28HFE59CNN4"
  }
  default_cache_behavior {
    target_origin_id       = "trison-cloud-resume-prod-${random_string.bucket_suffix.result}.s3.us-east-1.amazonaws.com"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false
    default_ttl            = 3600
    max_ttl                = 86400
    min_ttl                = 0
    smooth_streaming       = false
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  default_root_object = "cloudresume.html"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  aliases             = ["trisoncloudresume.com"]
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:442426863782:certificate/767456a5-a4b8-4f6c-8d59-baa6e2c891d2"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# IAM Role for API Gateway
resource "aws_iam_role" "api_gateway_role" {
  provider = aws.prod
  name     = "api-gateway-visitor-count-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role for Production Lambda
resource "aws_iam_role" "lambda_role" {
  provider = aws.prod
  name     = "lambda-visitor-count-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
