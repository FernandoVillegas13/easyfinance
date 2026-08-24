variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}

variable "aws_region" {
  description = "AWS region where the infrastructure is deployed."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

variable "aws_account_id" {
  description = "Twelve-digit AWS account ID used for the Terraform state bucket name."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a twelve-digit AWS account ID."
  }
}

variable "infra_version" {
  description = "Version segment shared by ECR and Lambda resource names."
  type        = string
  default     = "v1"

  validation {
    condition     = length(trimspace(var.infra_version)) > 0
    error_message = "infra_version must not be empty."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention period for the AI agent Lambda."
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545,
      731, 1096, 1827, 2192, 2557, 2922, 3288, 3653,
    ], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "s3_session_bucket_name" {
  description = "Globally unique S3 bucket name used by the AI agent session manager."
  type        = string
  default     = "easyfinance"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.s3_session_bucket_name))
    error_message = "s3_session_bucket_name must be a valid S3 bucket name."
  }
}
