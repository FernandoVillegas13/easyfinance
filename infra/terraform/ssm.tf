resource "aws_ssm_parameter" "db_host" {
  name        = "${local.ssm_parameter_prefix}/db-host"
  description = "PostgreSQL host for the EasyFinance AI agent."
  type        = "SecureString"
  value       = var.db_host
  tier        = "Standard"

  tags = {
    Name = "${local.name_prefix}-db-host"
  }
}

resource "aws_ssm_parameter" "db_port" {
  name        = "${local.ssm_parameter_prefix}/db-port"
  description = "PostgreSQL port for the EasyFinance AI agent."
  type        = "String"
  value       = var.db_port
  tier        = "Standard"

  tags = {
    Name = "${local.name_prefix}-db-port"
  }
}

resource "aws_ssm_parameter" "db_name" {
  name        = "${local.ssm_parameter_prefix}/db-name"
  description = "PostgreSQL database name for the EasyFinance AI agent."
  type        = "SecureString"
  value       = var.db_name
  tier        = "Standard"

  tags = {
    Name = "${local.name_prefix}-db-name"
  }
}

resource "aws_ssm_parameter" "db_user" {
  name        = "${local.ssm_parameter_prefix}/db-user"
  description = "PostgreSQL user for the EasyFinance AI agent."
  type        = "SecureString"
  value       = var.db_user
  tier        = "Standard"

  tags = {
    Name = "${local.name_prefix}-db-user"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "${local.ssm_parameter_prefix}/db-password"
  description = "PostgreSQL password for the EasyFinance AI agent."
  type        = "SecureString"
  value       = var.db_password
  tier        = "Standard"

  tags = {
    Name = "${local.name_prefix}-db-password"
  }
}

resource "aws_ssm_parameter" "db_schema" {
  name        = "${local.ssm_parameter_prefix}/db-schema"
  description = "PostgreSQL schema used by the EasyFinance AI agent."
  type        = "String"
  value       = var.db_schema
  tier        = "Standard"

  tags = {
    Name = "${local.name_prefix}-db-schema"
  }
}

resource "aws_ssm_parameter" "api_key" {
  name        = "${local.ssm_parameter_prefix}/api-key"
  description = "API key for authenticating requests to the EasyFinance AI agent."
  type        = "SecureString"
  value       = var.api_key
  tier        = "Standard"

  tags = {
    Name = "${local.name_prefix}-api-key"
  }
}

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
