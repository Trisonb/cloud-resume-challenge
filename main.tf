# Updated CI/CD test comment - May 28, 2025

data "aws_caller_identity" "current" {}

# Provider for Production Account
provider "aws" {
  region  = "us-east-1"
}

# Provider for Test Account
provider "aws" {
  alias   = "test"
  region  = "us-east-1"
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
  bucket = "trison-cloud-resume-prod-${random_string.bucket_suffix.result}"
}

# S3 Bucket Public Access Block for Production
resource "aws_s3_bucket_public_access_block" "website_public_access" {
  bucket                  = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for Production
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
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

# S3 Bucket for Test Static Website
resource "aws_s3_bucket" "website_bucket_test" {
  provider = aws.test
  bucket   = "trison-cloud-resume-test-gnkn928i"
}

# S3 Bucket Public Access Block for Test
resource "aws_s3_bucket_public_access_block" "website_public_access_test" {
  provider                = aws.test
  bucket                  = aws_s3_bucket.website_bucket_test.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for Test
resource "aws_s3_bucket_policy" "website_policy_test" {
  provider = aws.test
  bucket   = aws_s3_bucket.website_bucket_test.id
  policy = jsonencode({
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
        Resource  = "${aws_s3_bucket.website_bucket_test.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/NEW_DISTRIBUTION_ID"  # Replace with new ID
          }
        }
      }
    ]
  })
}

# CloudFront Distribution for Production
resource "aws_cloudfront_distribution" "website_cdn_prod" {
  origin {
    domain_name           = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id             = "trison-cloud-resume-prod-${random_string.bucket_suffix.result}.s3.us-east-1.amazonaws.com"
    origin_access_control_id = "E3F28HFE59CNN4"
  }
  default_cache_behavior {
    target_origin_id = "trison-cloud-resume-prod-${random_string.bucket_suffix.result}.s3.us-east-1.amazonaws.com"
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

# CloudFront Distribution for Test
resource "aws_cloudfront_distribution" "website_cdn_test" {
  origin {
    domain_name           = "trison-cloud-resume-test-gnkn928i.s3.us-east-1.amazonaws.com"
    origin_id             = "S3-trison-cloud-resume-test-gnkn928i"
    origin_access_control_id = "E1PLEV6BOWGMG5"
  }
  default_cache_behavior {
    target_origin_id = "S3-trison-cloud-resume-test-gnkn928i"
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
  aliases             = ["test.trisoncloudresume.com"]
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

# DynamoDB Table for Production Website (in Test Account)
resource "aws_dynamodb_table" "visitor_count_table" {
  provider       = aws.test
  name           = "visitor-count-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user"

  attribute {
    name = "user"
    type = "S"
  }

  tags = {
    Name        = "VisitorCountTable"
    Environment = "Production"
  }
}

# DynamoDB Table for Test Website (in Test Account)
resource "aws_dynamodb_table" "visitor_count_table_test" {
  provider       = aws.test
  name           = "visitor-count-table-test"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "VisitorCountTableTest"
    Environment = "Test"
  }
}

# IAM Role for API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "api-gateway-visitor-count-role"

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

# IAM Policy for API Gateway
resource "aws_iam_policy" "api_gateway_policy" {
  name        = "api-gateway-invoke-lambda-policy"
  description = "Policy for API Gateway to invoke Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = aws_lambda_function.visitor_count_function.arn
      }
    ]
  })
}

# Attach Policy to API Gateway Role
resource "aws_iam_role_policy_attachment" "api_gateway_policy_attachment" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.api_gateway_policy.arn
}

# IAM Role for Production Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-visitor-count-role"

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

# IAM Policy for Production Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-visitor-count-policy"
  description = "Policy for Lambda to access DynamoDB and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.visitor_count_table.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to Production Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# IAM Role for Test Lambda
resource "aws_iam_role" "lambda_role_test" {
  provider = aws.test
  name     = "lambda-visitor-count-role-test"

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

# IAM Policy for Test Lambda
resource "aws_iam_policy" "lambda_policy_test" {
  provider = aws.test
  name     = "lambda-visitor-count-policy-test"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.visitor_count_table_test.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to Test Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_test" {
  provider   = aws.test
  role       = aws_iam_role.lambda_role_test.name
  policy_arn = aws_iam_policy.lambda_policy_test.arn
}

# Lambda Function for Production
resource "aws_lambda_function" "visitor_count_function" {
  provider       = aws.test  # Moved to test account
  function_name = "visitor-count-function"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role_test.arn
  filename      = "function.zip"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count_table.name
    }
  }

  timeout = 10
}

resource "aws_lambda_function" "visitor_count_function_test" {
  provider       = aws.test
  function_name  = "visitor-count-function-test"
  handler        = "lambda_function.lambda_handler"
  runtime        = "python3.9"
  role           = aws_iam_role.lambda_role_test.arn
  filename       = "function.zip"
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count_table_test.name
    }
  }
  timeout = 10
}

# API Gateway REST API for Production
resource "aws_api_gateway_rest_api" "visitor_count_api" {
  provider = aws.test  # Moved to test account
  name        = "VisitorCountAPI"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Environment = "Production"
    Redeploy    = "v1"
  }
}

# API Gateway Resource for Production
resource "aws_api_gateway_resource" "visitor_resource" {
  provider    = aws.test
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  parent_id   = aws_api_gateway_rest_api.visitor_count_api.root_resource_id
  path_part   = "visitor"
}

# POST Method for Production
resource "aws_api_gateway_method" "post_method" {
  provider      = aws.test
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# POST Integration for Production
resource "aws_api_gateway_integration" "lambda_integration" {
  provider               = aws.test
  rest_api_id            = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id            = aws_api_gateway_resource.visitor_resource.id
  http_method            = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.visitor_count_function.invoke_arn
  credentials            = "arn:aws:iam::940482418939:role/api-gateway-visitor-count-role"
}

# OPTIONS Method for Production
resource "aws_api_gateway_method" "options_method" {
  provider      = aws.test
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# OPTIONS Integration for Production
resource "aws_api_gateway_integration" "options_integration" {
  provider               = aws.test
  rest_api_id            = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id            = aws_api_gateway_resource.visitor_resource.id
  http_method            = aws_api_gateway_method.options_method.http_method
  type                   = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# OPTIONS Method Response for Production
resource "aws_api_gateway_method_response" "options_response" {
  provider    = aws.test
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

# OPTIONS Integration Response for Production
resource "aws_api_gateway_integration_response" "options_integration_response" {
  provider    = aws.test
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Cache-Control,Custom-No-Cache'"
  }

  depends_on = [aws_api_gateway_integration.options_integration]
}

# Permission for API Gateway to Invoke Production Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  provider      = aws.test
  statement_id = "AllowAPIGatewayInvokeNew2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_count_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_count_api.execution_arn}/*/POST/visitor"
}

# API Gateway Deployment for Production
resource "aws_api_gateway_deployment" "api_deployment" {
  provider    = aws.test
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  triggers = {
    redeploy = timestamp()
  }
  depends_on = [
    aws_lambda_permission.api_gateway_permission,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_integration_response.options_integration_response
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage for Production
resource "aws_api_gateway_stage" "dev_stage" {
  provider      = aws.test
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  stage_name    = "Dev"
}

# API Gateway REST API for Test
resource "aws_api_gateway_rest_api" "visitor_count_api_test" {
  provider = aws.test
  name     = "visitor_count_api_test"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Environment = "Test"
    Redeploy    = "v1"
  }
}

# API Gateway Resource for Test
resource "aws_api_gateway_resource" "visitor_resource_test" {
  provider    = aws.test
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api_test.id
  parent_id   = aws_api_gateway_rest_api.visitor_count_api_test.root_resource_id
  path_part   = "visitor"
}

# POST Method for Test
resource "aws_api_gateway_method" "post_method_test" {
  provider      = aws.test
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api_test.id
  resource_id   = aws_api_gateway_resource.visitor_resource_test.id
  http_method   = "POST"
  authorization = "NONE"
}

# POST Integration for Test
resource "aws_api_gateway_integration" "lambda_integration_test" {
  provider               = aws.test
  rest_api_id            = aws_api_gateway_rest_api.visitor_count_api_test.id
  resource_id            = aws_api_gateway_resource.visitor_resource_test.id
  http_method            = aws_api_gateway_method.post_method_test.http_method
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.visitor_count_function_test.invoke_arn
}

# OPTIONS Method for Test
resource "aws_api_gateway_method" "options_method_test" {
  provider      = aws.test
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api_test.id
  resource_id   = aws_api_gateway_resource.visitor_resource_test.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# OPTIONS Integration for Test
resource "aws_api_gateway_integration" "options_integration_test" {
  provider               = aws.test
  rest_api_id            = aws_api_gateway_rest_api.visitor_count_api_test.id
  resource_id            = aws_api_gateway_resource.visitor_resource_test.id
  http_method            = aws_api_gateway_method.options_method_test.http_method
  type                   = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# OPTIONS Method Response for Test
resource "aws_api_gateway_method_response" "options_response_test" {
  provider    = aws.test
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api_test.id
  resource_id = aws_api_gateway_resource.visitor_resource_test.id
  http_method = aws_api_gateway_method.options_method_test.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

# OPTIONS Integration Response for Test
resource "aws_api_gateway_integration_response" "options_integration_response_test" {
  provider    = aws.test
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api_test.id
  resource_id = aws_api_gateway_resource.visitor_resource_test.id
  http_method = aws_api_gateway_method.options_method_test.http_method
  status_code = aws_api_gateway_method_response.options_response_test.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Cache-Control,Custom-No-Cache'"
  }

  depends_on = [aws_api_gateway_integration.options_integration_test]
}

# Permission for API Gateway to Invoke Test Lambda
resource "aws_lambda_permission" "api_gateway_permission_test" {
  provider      = aws.test
  statement_id  = "AllowAPIGatewayInvokeTest"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_count_function_test.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_count_api_test.execution_arn}/*/POST/visitor"
}

# API Gateway Deployment for Test
resource "aws_api_gateway_deployment" "api_deployment_test" {
  provider    = aws.test
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api_test.id
  triggers = {
    redeploy = timestamp()
  }
  depends_on = [
    aws_lambda_permission.api_gateway_permission_test,
    aws_api_gateway_integration.lambda_integration_test,
    aws_api_gateway_integration.options_integration_test,
    aws_api_gateway_integration_response.options_integration_response_test
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage for Test
resource "aws_api_gateway_stage" "dev_stage_test" {
  provider      = aws.test
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api_test.id
  deployment_id = aws_api_gateway_deployment.api_deployment_test.id
  stage_name    = "Dev"
}# Re-trigger workflow
# Re-trigger workflow
# Re-trigger workflow with updated secrets
