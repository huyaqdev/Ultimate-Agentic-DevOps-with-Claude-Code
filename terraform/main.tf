##############################################################################
# S3 Bucket
##############################################################################

resource "aws_s3_bucket" "site" {
  bucket = "${var.project_name}-${var.environment}-site"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Keep all objects private — CloudFront accesses via OAC, never via public URL
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disable the S3 static-website hosting endpoint; CloudFront serves the site
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

##############################################################################
# CloudFront Origin Access Control (OAC)
##############################################################################

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for ${var.project_name} (${var.environment}) S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

##############################################################################
# S3 Bucket Policy — allow CloudFront OAC to read objects
##############################################################################

data "aws_iam_policy_document" "site_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontOACRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_bucket_policy.json

  # The distribution must exist before we can reference its ARN in the policy
  depends_on = [aws_cloudfront_distribution.site]
}

##############################################################################
# CloudFront Distribution
##############################################################################

# AWS-managed CachingOptimized policy (ID is constant across all accounts)
locals {
  caching_optimized_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  comment             = "${var.project_name} (${var.environment})"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = local.caching_optimized_policy_id
  }

  # Return index.html with HTTP 200 for any 404 — supports SPA-style routing
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
