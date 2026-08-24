# EasyFinance Terraform

## Prerequisites

- Terraform 1.9.8 or newer (before 2.0)
- AWS CLI authenticated with an SSO profile that can create the declared resources
- Docker Buildx for the first AI agent image

## Local environment

```bash
cp infra/terraform/.env.example infra/terraform/.env
# Adjust AWS_PROFILE and AWS_REGION in infra/terraform/.env if needed.
aws sso login --profile easyfinance-dev
source infra/terraform/.env
```

The environment file derives the AWS account ID from the authenticated profile and sets the Terraform variables and backend values. It does not store AWS credentials or application secrets.

## First-time state backend bootstrap

Terraform cannot use a bucket as its backend before the bucket exists. Create it once with local state:

```bash
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform apply \
  -target=aws_s3_bucket.terraform_state \
  -target=aws_s3_bucket_public_access_block.terraform_state \
  -target=aws_s3_bucket_ownership_controls.terraform_state \
  -target=aws_s3_bucket_versioning.terraform_state \
  -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state
```

Then migrate that local state to the new S3 backend:

```bash
terraform -chdir=infra/terraform init -migrate-state \
  -backend-config="bucket=${TF_BACKEND_BUCKET}" \
  -backend-config="key=${TF_BACKEND_KEY}" \
  -backend-config="region=${TF_BACKEND_REGION}" \
  -backend-config="encrypt=true"
```

## Existing session bucket

The agent currently uses `easyfinance` as its session bucket. If it already exists outside Terraform, import it before the first full plan:

```bash
terraform -chdir=infra/terraform import \
  aws_s3_bucket.easyfinance "${TF_VAR_s3_session_bucket_name}"
```

Import the associated S3 configuration resources as needed if they were already configured outside Terraform.

## First AI agent image

The Lambda function references the ECR `:latest` image, so bootstrap ECR and publish an image before the full apply:

```bash
terraform -chdir=infra/terraform apply \
  -target=aws_ecr_repository.ai_agent \
  -target=aws_ecr_lifecycle_policy.ai_agent

repository="${TF_VAR_aws_account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com/${TF_VAR_environment}-${TF_VAR_infra_version}-ai-agent"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${TF_VAR_aws_account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com"
docker buildx build --platform linux/amd64 \
  --tag "${repository}:latest" \
  --push components/ai-agent
```

## Normal deployment

```bash
terraform -chdir=infra/terraform plan -out=tfplan
terraform -chdir=infra/terraform apply tfplan
```

The Lambda is configured for `x86_64`, so the image must be built for `linux/amd64`.
