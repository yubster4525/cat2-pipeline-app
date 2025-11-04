#!/usr/bin/env bash
set -euo pipefail

# Required environment variables
: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID to your account ID (12-digit).}"
: "${AWS_REGION:?Set AWS_REGION to the target AWS region.}"
: "${ECR_REPOSITORY:?Set ECR_REPOSITORY to the target ECR repository name.}"

IMAGE_NAME=${IMAGE_NAME:-cat2-pipeline-app}
IMAGE_TAG=${IMAGE_TAG:-latest}
REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

aws ecr describe-repositories \
  --repository-names "${ECR_REPOSITORY}" \
  --region "${AWS_REGION}" >/dev/null 2>&1 || {
  echo "ECR repository ${ECR_REPOSITORY} not found; creating it";
  aws ecr create-repository --repository-name "${ECR_REPOSITORY}" --region "${AWS_REGION}" >/dev/null;
}

echo "Logging Docker client into ECR ${REPO_URI}";
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REPO_URI}:${IMAGE_TAG}"
docker push "${REPO_URI}:${IMAGE_TAG}"

# Optionally update 'latest' tag alongside explicit version
if [[ "${IMAGE_TAG}" != "latest" ]]; then
  docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REPO_URI}:latest"
  docker push "${REPO_URI}:latest"
fi

echo "Image pushed: ${REPO_URI}:${IMAGE_TAG}"
