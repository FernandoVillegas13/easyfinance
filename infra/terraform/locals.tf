locals {
  project_name                = "easyfinance"
  name_prefix                 = "${var.environment}-${var.infra_version}"
  terraform_state_bucket_name = "terraform-state-${var.aws_account_id}"
  session_bucket_name         = "easyfinance-${var.aws_account_id}"
  ssm_parameter_prefix        = "/${local.project_name}/${var.environment}"

  common_tags = {
    Project               = local.project_name
    Environment           = var.environment
    InfrastructureVersion = var.infra_version
    ManagedBy             = "Terraform"
  }
}
