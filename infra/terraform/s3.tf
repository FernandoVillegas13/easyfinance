resource "aws_s3_bucket" "easyfinance" {
  bucket        = local.session_bucket_name
  force_destroy = false

  tags = {
    Name      = local.session_bucket_name
    Component = "ai-agent"
  }
}

resource "aws_s3_bucket_public_access_block" "easyfinance" {
  bucket = aws_s3_bucket.easyfinance.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "easyfinance" {
  bucket = aws_s3_bucket.easyfinance.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "easyfinance" {
  bucket = aws_s3_bucket.easyfinance.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
