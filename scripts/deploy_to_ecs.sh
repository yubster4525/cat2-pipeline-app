#!/usr/bin/env bash
set -euo pipefail

: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID for image URI construction.}"
: "${AWS_REGION:?Set AWS_REGION for AWS CLI commands.}"
: "${ECR_REPOSITORY:?Set ECR_REPOSITORY to push/pull images.}"
: "${IMAGE_TAG:?Set IMAGE_TAG for the image version to deploy.}"
: "${CLUSTER_NAME:?Set CLUSTER_NAME to the target ECS cluster.}"
: "${SERVICE_NAME:?Set SERVICE_NAME to the target ECS service.}"
: "${EXECUTION_ROLE_ARN:?Set EXECUTION_ROLE_ARN used by the task.}"
: "${TASK_ROLE_ARN:?Set TASK_ROLE_ARN used by the application container.}"
: "${LOG_GROUP:?Set LOG_GROUP for CloudWatch logging.}"

TEMPLATE_PATH=${TASK_DEFINITION_TEMPLATE:-infra/task-definition-template.json}
GENERATED_TASK_DEF=$(mktemp)
IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}"

export IMAGE_URI EXECUTION_ROLE_ARN TASK_ROLE_ARN LOG_GROUP AWS_REGION

if ! command -v envsubst >/dev/null 2>&1; then
  echo "envsubst is required but was not found. Install gettext package." >&2
  exit 1
fi

envsubst < "${TEMPLATE_PATH}" > "${GENERATED_TASK_DEF}"

TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json "file://${GENERATED_TASK_DEF}" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text \
  --region "${AWS_REGION}")

echo "Registered new task definition: ${TASK_DEF_ARN}"

echo "Updating ECS service ${SERVICE_NAME} to use new task definition"
aws ecs update-service \
  --cluster "${CLUSTER_NAME}" \
  --service "${SERVICE_NAME}" \
  --task-definition "${TASK_DEF_ARN}" \
  --region "${AWS_REGION}" \
  >/dev/null

echo "Waiting for service deployment to stabilize"
aws ecs wait services-stable \
  --cluster "${CLUSTER_NAME}" \
  --services "${SERVICE_NAME}" \
  --region "${AWS_REGION}"

echo "Deployment completed"
rm -f "${GENERATED_TASK_DEF}"
