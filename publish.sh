
# Variables
ECR_URL=064629264592.dkr.ecr.us-east-1.amazonaws.com
REPO_URL=${ECR_URL}/rul-aws-deployment
LOCAL_IMAGE=rul-aws-deployment
REMOTE_IMAGE_TAG="${REPO_URL}:v1"

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin ${ECR_URL}

# Build and push directly to ECR for single platform
docker buildx build \
  --platform linux/amd64 \
  --provenance=false \
  --sbom=false \
  --output type=image,push=true \
  -t ${REMOTE_IMAGE_TAG} \
  .


echo 'Done'









