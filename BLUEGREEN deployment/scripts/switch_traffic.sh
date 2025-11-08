#!/usr/bin/env bash
set -euo pipefail

: "${ACTIVE_COLOR:?Set ACTIVE_COLOR to blue or green}"
: "${REMOTE_HOST:?Set REMOTE_HOST (user@ip).}"
: "${REMOTE_PATH:?Set REMOTE_PATH where nginx template resides.}"
: "${NGINX_RELOAD_COMMAND:=sudo systemctl reload nginx}"

PORT=8081
if [[ "$ACTIVE_COLOR" == "green" ]]; then
  PORT=8082
elif [[ "$ACTIVE_COLOR" != "blue" ]]; then
  echo "ACTIVE_COLOR must be blue or green" >&2
  exit 1
fi

ssh "$REMOTE_HOST" "ACTIVE_PORT=$PORT TEMPLATE=$REMOTE_PATH/nginx/default.conf.template RELOAD=\"$NGINX_RELOAD_COMMAND\" bash -s" <<'REMOTE'
set -euo pipefail
rendered="/tmp/bluegreen-nginx.conf"
sed "s/\${ACTIVE_PORT}/$ACTIVE_PORT/g" "$TEMPLATE" > "$rendered"
sudo mv "$rendered" /etc/nginx/conf.d/bluegreen.conf
$RELOAD
REMOTE
