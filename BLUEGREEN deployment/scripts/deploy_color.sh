#!/usr/bin/env bash
set -euo pipefail

: "${COLOR:?Set COLOR to blue or green}"
: "${DOCKER_IMAGE:?Set DOCKER_IMAGE to the full Docker image name.}"
: "${REMOTE_HOST:?Set REMOTE_HOST (user@ip) for SSH deployments.}"
: "${REMOTE_PATH:?Set REMOTE_PATH where docker-compose files live on the host.}"

if [[ "$COLOR" != "blue" && "$COLOR" != "green" ]]; then
  echo "COLOR must be blue or green" >&2
  exit 1
fi

ssh "$REMOTE_HOST" "COLOR=$COLOR DOCKER_IMAGE=$DOCKER_IMAGE REMOTE_PATH=$REMOTE_PATH bash -s" <<'REMOTE'
set -euo pipefail
compose_file="$REMOTE_PATH/docker-compose.${COLOR}.yml"
export DOCKER_IMAGE
export APP_VERSION

if [[ ! -f "$compose_file" ]]; then
  echo "$compose_file missing on remote host" >&2
  exit 1
fi
DOCKER_IMAGE="$DOCKER_IMAGE" docker compose -f "$compose_file" pull
DOCKER_IMAGE="$DOCKER_IMAGE" docker compose -f "$compose_file" up -d
REMOTE
