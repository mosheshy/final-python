#!/usr/bin/env bash
set -euo pipefail

APP_NAME="final-python-app"
CONTAINER_NAME="$APP_NAME"

# If ec2-user session doesn't yet have docker group, fall back to sudo
DOCKER_BIN="docker"
if ! $DOCKER_BIN ps >/dev/null 2>&1; then
  DOCKER_BIN="sudo docker"
fi

# Stop & remove the container if it exists
if $DOCKER_BIN ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  $DOCKER_BIN rm -f "$CONTAINER_NAME" || true
fi

# Optional: clean up unused stuff to free space
$DOCKER_BIN system prune -f || true
