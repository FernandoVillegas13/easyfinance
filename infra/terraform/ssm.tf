resource "aws_ssm_parameter" "s3_session_bucket" {
  name        = "${local.ssm_parameter_prefix}/s3-session-bucket"
  description = "S3 bucket used by the EasyFinance AI agent session manager."
  type        = "String"
  value       = aws_s3_bucket.easyfinance.bucket
  tier        = "Standard"

  tags = {
    Name = "${local.name_prefix}-s3-session-bucket"
  }
}

resource "aws_ssm_parameter" "s3_session_prefix" {
  name        = "${local.ssm_parameter_prefix}/s3-session-prefix"
  description = "S3 object prefix used by the EasyFinance AI agent session manager."
  type        = "String"
  value       = "${var.environment}/"
  tier        = "Standard"

  tags = {
    Name = "${local.name_prefix}-s3-session-prefix"
  }
}
