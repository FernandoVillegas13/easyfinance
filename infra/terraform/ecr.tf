# =============================================================================
# ECR Repositories
# =============================================================================

# -----------------------------------------------------------------------------
# AI Agent ECR Repository
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "ai_agent" {
  name                 = "${local.name_prefix}-ai-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${local.name_prefix}-ai-agent"
  }
}

resource "aws_ecr_lifecycle_policy" "ai_agent" {
  repository = aws_ecr_repository.ai_agent.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
