output "terraform_state_bucket_name" {
  description = "S3 bucket that stores the Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "ai_agent_session_bucket_name" {
  description = "S3 bucket used by the AI agent session manager."
  value       = aws_s3_bucket.easyfinance.bucket
}

output "ai_agent_ecr_repository_url" {
  description = "ECR repository URI for the AI agent image."
  value       = aws_ecr_repository.ai_agent.repository_url
}

output "ai_agent_lambda_name" {
  description = "Name of the deployed AI agent Lambda function."
  value       = aws_lambda_function.ai_agent.function_name
}

output "ai_agent_function_url" {
  description = "Public Function URL for the AI agent."
  value       = aws_lambda_function_url.ai_agent.function_url
}
