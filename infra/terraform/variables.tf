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
  description = "Twelve-digit AWS account ID."
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
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 30
}

variable "db_host" {
  description = "PostgreSQL host for the EasyFinance database."
  type        = string
}

variable "db_port" {
  description = "PostgreSQL port."
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
}

variable "db_user" {
  description = "PostgreSQL user."
  type        = string
}

variable "db_password" {
  description = "PostgreSQL password."
  type        = string
  sensitive   = true
}

variable "db_schema" {
  description = "PostgreSQL schema used by the EasyFinance AI agent."
  type        = string
}

variable "api_key" {
  description = "API key for authenticating requests to the EasyFinance AI agent."
  type        = string
  sensitive   = true
}
