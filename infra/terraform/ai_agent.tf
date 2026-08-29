# =============================================================================
# AI Agent Lambda
# =============================================================================
# FastAPI + Lambda Web Adapter container exposed via Function URL
# with buffered responses.
# =============================================================================

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ai_agent" {
  name              = "/aws/lambda/${local.name_prefix}-ai-agent"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.name_prefix}-ai-agent-logs"
  }
}

# -----------------------------------------------------------------------------
# IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ai_agent" {
  name = "${local.name_prefix}-ai-agent-role"

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

  tags = {
    Name = "${local.name_prefix}-ai-agent-role"
  }
}

resource "aws_iam_role_policy_attachment" "ai_agent_basic" {
  role       = aws_iam_role.ai_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ai_agent_bedrock" {
  name = "bedrock-invoke"
  role = aws_iam_role.ai_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "InvokeFoundationModels"
        Effect   = "Allow"
        Action   = ["bedrock:*"]
        Resource = ["*"]
      },
      {
        Sid    = "MarketplaceSubscriptions"
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ai_agent_s3_sessions" {
  name = "s3-sessions"
  role = aws_iam_role.ai_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListSessionBucket"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ]
        Resource = [aws_s3_bucket.easyfinance.arn]
      },
      {
        Sid    = "ManageSessionObjects"
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = ["${aws_s3_bucket.easyfinance.arn}/*"]
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "ai_agent" {
  function_name = "${local.name_prefix}-ai-agent"
  description   = "EasyFinance AI agent — FastAPI + Lambda Web Adapter"
  role          = aws_iam_role.ai_agent.arn

  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.ai_agent.repository_url}:latest"
  architectures = ["x86_64"]

  timeout     = 900
  memory_size = 1024

  environment {
    variables = {
      ENVIRONMENT    = var.environment
      BUCKET_SESSION = aws_ssm_parameter.s3_session_bucket.value
      BUCKET_PREFIX  = aws_ssm_parameter.s3_session_prefix.value
      DB_HOST        = aws_ssm_parameter.db_host.value
      DB_PORT        = aws_ssm_parameter.db_port.value
      DB_NAME        = aws_ssm_parameter.db_name.value
      DB_USER        = aws_ssm_parameter.db_user.value
      DB_PASSWORD    = aws_ssm_parameter.db_password.value
      DB_SCHEMA      = aws_ssm_parameter.db_schema.value
      API_KEY        = aws_ssm_parameter.api_key.value
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.ai_agent,
    aws_iam_role_policy.ai_agent_bedrock,
    aws_iam_role_policy.ai_agent_s3_sessions,
  ]

  lifecycle {
    ignore_changes = [image_uri]
  }

  tags = {
    Name = "${local.name_prefix}-ai-agent"
  }
}

# -----------------------------------------------------------------------------
# Function URL
# -----------------------------------------------------------------------------
resource "aws_lambda_function_url" "ai_agent" {
  function_name      = aws_lambda_function.ai_agent.function_name
  authorization_type = "NONE"
  invoke_mode        = "BUFFERED"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["Content-Type", "X-Api-Key"]
    max_age           = 86400
  }
}

# -----------------------------------------------------------------------------
# Public access permission
# -----------------------------------------------------------------------------
resource "aws_lambda_permission" "public_url_invoke" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.ai_agent.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "public_invoke" {
  statement_id  = "FunctionURLInvokeAllowPublicAccess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_agent.function_name
  principal     = "*"
}
