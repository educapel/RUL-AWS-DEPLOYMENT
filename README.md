# RUL AWS Deployment

Deploying a machine learning model that predicts Remaining Useful Life (RUL) of machinery to AWS Lambda using Docker containers.

## The Challenge

AWS Lambda has strict size limits for deployment packages. When you have a machine learning model with heavy dependencies like scikit-learn, pandas, and numpy, you can't simply upload your code. The solution? Containerize everything with Docker and deploy the container to Lambda.

## How It Works

We package our ML model and all its dependencies inside a Docker container, push it to AWS ECR (Elastic Container Registry), and deploy it as a Lambda function. Then we expose the Lambda function through API Gateway, making it accessible via a simple REST API.

## Quick Start

### 1. Local Testing

First, build and test the container locally:

```bash
# Build the Docker image
docker build --platform linux/amd64 -t rul-aws-deployment .

# Run it locally
docker run -p 8080:8080 rul-aws-deployment

# Test it (in another terminal)
python tests/test.py
```

The local test uses: `http://localhost:8080/2015-03-31/functions/function/invocations`

### 2. Deploy to AWS

Once local testing works, deploy to AWS:

```bash
bash publish.sh
```

This script handles ECR authentication, builds the image for the correct architecture, and pushes it to your AWS container registry.

## The Docker Configuration Story

### Why This Dockerfile Works

AWS Lambda doesn't use virtual environments. When Lambda runs your container, it expects packages to be installed system-wide in `/var/lang/lib/python3.13/site-packages/`.

**The Problem We Solved:**

Initially, we tried using `uv sync`, which creates a virtual environment (`.venv`). Lambda couldn't find our packages because they were isolated in that virtual environment.

**The Solution:**

```dockerfile
RUN uv pip install --system --no-cache boto3 joblib numpy pandas scikit-learn
```

The `--system` flag installs packages globally, making them accessible to Lambda's Python runtime.

## The AWS Deployment Journey

### Step 1: Setting Up AWS Access

Create an IAM user with these permissions:
- `AmazonEC2ContainerRegistryPowerUser` - To push Docker images
- `AWSLambda_FullAccess` - To create and manage Lambda functions

Then authenticate:
```bash
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin 064629264592.dkr.ecr.us-east-1.amazonaws.com
```

### Step 2: Create Your Container Registry

Create a repository in ECR to store your Docker image:

```bash
aws ecr create-repository --repository-name rul-aws-deployment --region us-east-1
```

### Step 3: The Build & Push Script

The `publish.sh` script handles the tricky parts:

```bash
# Build and push directly to ECR for single platform (avoids multi-arch manifest)
docker buildx build \
  --platform linux/amd64 \
  --provenance=false \
  --sbom=false \
  --output type=image,push=true \
  -t ${REMOTE_IMAGE_TAG} \
  .
```

**Why These Flags Matter:**

- `--platform linux/amd64`: Lambda runs on x86_64 architecture
- `--provenance=false` & `--sbom=false`: Prevents Docker from creating multiple manifest images that Lambda doesn't support
- `--output type=image,push=true`: Pushes directly as a single-platform image, avoiding Docker Desktop's multi-architecture manifest lists

**The Problem This Solved:**

On Apple Silicon Macs, Docker Desktop would create 3 images (an Image Index + 2 platform images). Lambda couldn't read this format and threw "image manifest not supported" errors. Now we push a clean, single-platform image that Lambda can use.

### Step 4: Create the Lambda Function

1. Go to AWS Lambda Console
2. Click **Create function** → **Container image**
3. Function name: `RUL-Prediction`
4. Container image URI: `064629264592.dkr.ecr.us-east-1.amazonaws.com/rul-aws-deployment:v1`
5. **Important:** Select **x86_64** architecture (NOT arm64)

Test your Lambda function with this sample JSON:

```json
{
  "s_1": 0.0, "s_2": 0.421876, "s_3": 0.512349, "s_4": 0.0,
  "s_5": 1.0, "s_6": 0.492156, "s_7": 0.334521, "s_8": 0.68765,
  "s_9": 0.0, "s_10": 0.389234, "s_11": 0.578912, "s_12": 0.312456,
  "s_13": 0.167890, "s_14": 0.456123, "s_15": 0.0, "s_16": 0.423567,
  "s_17": 0.0, "s_18": 0.0, "s_19": 0.37823, "s_20": 0.534219, "s_21": 0.301234
}
```

### Step 5: Exposing Through API Gateway

Now we make the Lambda function accessible from anywhere:

1. Go to **API Gateway Console**
2. **Create API** → **REST API**
3. Create a resource: `/predict`
4. Create a method: **POST** → Link to your Lambda function
5. **Deploy API** → Choose a stage name (e.g., `prod`)

**Important URL Structure:**

API Gateway URLs follow this pattern:
```
https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/{resource}
```

For example: `https://aq8dv7o6dl.execute-api.us-east-1.amazonaws.com/prod/predict`

**A Common Mistake:**

The AWS Console shows the "Invoke URL" as just the stage: `https://xxx.com/predict`. But you need to append your resource path! If you named your stage "predict" and resource "predict", the full URL is: `https://xxx.com/predict/predict`

### Step 6: Test the Live API

Update `tests/test.py` with your API Gateway URL:

```python
url = 'https://aq8dv7o6dl.execute-api.us-east-1.amazonaws.com/prod/predict'
```

Run it:
```bash
python tests/test.py
```

Success looks like:
```json
{"statusCode": 200, "body": "{\"rul_prediction\": 123.45}"}
```

## Common Issues We Solved

### "No module named 'joblib'"
Lambda couldn't find our packages because they were in a virtual environment. Fixed by using `uv pip install --system`.

### "Image manifest not supported"
Docker created a multi-architecture manifest that Lambda couldn't read. Fixed by using `--provenance=false`, `--sbom=false`, and pushing directly to ECR.

### "Missing Authentication Token"
This confusing error actually means "404 - endpoint not found". We were missing the resource path after the stage name in our API Gateway URL.

## Technologies

- **Python 3.13** with Lambda runtime
- **uv** - Fast Python package manager
- **Docker** - Container platform
- **AWS Lambda** - Serverless compute
- **AWS ECR** - Container registry
- **AWS API Gateway** - REST API
- **scikit-learn, pandas, numpy** - ML stack