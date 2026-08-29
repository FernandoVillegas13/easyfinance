# EasyFinance

EasyFinance is a voice-first personal finance app for Apple Watch. The watch app uses Apple's native dictation UI, sends expense messages to an AI agent running on AWS Lambda, and displays the user's PostgreSQL spending history.

## Architecture

- `swift/`: SwiftUI watchOS app.
- `components/ai-agent/`: FastAPI + Strands agent using Amazon Bedrock.
- `infra/terraform/`: Lambda Function URL, ECR, S3 sessions, IAM, SSM, and logging.

The app uses three authenticated endpoints:

| Endpoint | Body | Purpose |
| --- | --- | --- |
| `POST /api/v1/log` | `{ "user_id": "…", "query": "…" }` | Extract and save one or more expenses. |
| `POST /api/v1/chat` | `{ "user_id": "…", "query": "…" }` | Ask conversational questions about spending. |
| `POST /api/v1/spendings` | `{ "user_id": "…", "limit": 100 }` | Return structured, user-scoped expenses for the UI. |

All API requests require the `X-Api-Key` header. `/health` is public.

## Configure the Apple Watch app

The non-secret Lambda URL is defined in `swift/Configuration/AppConfig.xcconfig`:

```text
https://licm3mgb2sak63hkui7jldwkeu0laxjz.lambda-url.us-east-1.on.aws/
```

Create the ignored local secrets file:

```bash
cp swift/Configuration/Secrets.xcconfig.example \
   swift/Configuration/Secrets.xcconfig
```

Set these values in the copy:

```xcconfig
EASYFINANCE_API_KEY = your-agent-api-key
EASYFINANCE_USER_ID = your-stable-logical-user-id
```

`EASYFINANCE_USER_ID` determines which database rows and S3 conversation belong to the watch. Keep it stable across builds if the same history should remain visible. The current local workspace is already configured with an ignored secrets file; its value is not committed.

Open `swift/easyfinance.xcodeproj`, select the `easyfinance Watch App` scheme, choose an Apple Watch simulator or paired device, and run. The target includes a microphone usage description. Dictation is presented by WatchKit's native text input controller, so Apple handles transcription and returns only the resulting text to the app.

## Agent deployment required for spending history

The checked-in backend now includes `/api/v1/spendings`. The supplied Lambda URL must run a new container image before dashboard/history loading will work. Logging and chat continue to use the existing endpoints.

Build and push a uniquely tagged image rather than reusing an already-resolved Lambda image:

```bash
source infra/terraform/.env
repository="$(terraform -chdir=infra/terraform output -raw ai_agent_ecr_repository_url)"
tag="$(date -u +%Y%m%d%H%M%S)"

aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin \
      "${TF_VAR_aws_account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com"

docker buildx build --platform linux/amd64 \
  --tag "${repository}:${tag}" \
  --push components/ai-agent

function_name="$(terraform -chdir=infra/terraform output -raw ai_agent_lambda_name)"
aws lambda update-function-code \
  --region "${AWS_REGION}" \
  --function-name "${function_name}" \
  --image-uri "${repository}:${tag}"
aws lambda wait function-updated \
  --region "${AWS_REGION}" \
  --function-name "${function_name}"
```

Apply the Terraform CORS update separately if browser clients will call the API:

```bash
terraform -chdir=infra/terraform plan -out=tfplan
terraform -chdir=infra/terraform apply tfplan
```

A native watchOS client is not restricted by browser CORS.

## Security notes

- `Secrets.xcconfig` and environment files are ignored by Git.
- A static key compiled into a client app can be extracted from the binary. It is suitable only as the existing service gate, not as per-user authentication. For a public production app, put the Lambda behind API Gateway and use short-lived user tokens (for example Cognito), then derive `user_id` server-side.
- The list endpoint uses a fixed parameterized SQL query. Agent tools are bound to one request user, and analytical SQL remains user-scoped.
- Do not commit Terraform plans, local state, API keys, database credentials, or generated app archives.
