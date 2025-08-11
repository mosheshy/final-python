#!/usr/bin/env bash
set -euo pipefail

# ---------------- CONFIG ----------------
IMAGE="mosheshay/final-python-app:latest"   # <-- make sure this EXACTLY matches your Docker Hub repo/tag
CONTAINER_NAME="final-python-app"
CONTAINER_PORT="5000"
HOST_PORT="80"             
# ----------------------------------------

# If ec2-user session doesn't yet have docker group, fall back to sudo
DOCKER_BIN="docker"
if ! $DOCKER_BIN ps >/dev/null 2>&1; then
  DOCKER_BIN="sudo docker"
fi

# --- If your Docker Hub repo is PRIVATE, login first ---
# Option A: expect env vars on the instance (or injected securely)
#   export DOCKERHUB_USERNAME="your_user"
#   export DOCKERHUB_PASSWORD="your_token"
if [ -n "${DOCKERHUB_USERNAME:-}" ] && [ -n "${DOCKERHUB_PASSWORD:-}" ]; then
  echo "$DOCKERHUB_PASSWORD" | $DOCKER_BIN login -u "$DOCKERHUB_USERNAME" --password-stdin
fi

# Option B (commented): fetch creds from SSM Parameter Store (instance role needs ssm:GetParameter)
# DOCKERHUB_USERNAME=$(aws ssm get-parameter --name "/dockerhub/username" --with-decryption --query "Parameter.Value" --output text)
# DOCKERHUB_PASSWORD=$(aws ssm get-parameter --name "/dockerhub/token"    --with-decryption --query "Parameter.Value" --output text)
# echo "$DOCKERHUB_PASSWORD" | $DOCKER_BIN login -u "$DOCKERHUB_USERNAME" --password-stdin

# Pull the image
$DOCKER_BIN pull "$IMAGE"

# Stop existing container if any (idempotent)
if $DOCKER_BIN ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  $DOCKER_BIN rm -f "$CONTAINER_NAME" || true
fi

# Ensure host port is free (best effort)
if command -v ss >/dev/null 2>&1 && ss -ltn "( sport = :$HOST_PORT )" | grep -q ":$HOST_PORT"; then
  echo "Port $HOST_PORT is in use; attempting to free it by removing $CONTAINER_NAME if running."
  $DOCKER_BIN rm -f "$CONTAINER_NAME" || true
fi

# Run container
$DOCKER_BIN run -d \
  --name "$CONTAINER_NAME" \
  -p "${HOST_PORT}:${CONTAINER_PORT}" \
  --restart unless-stopped \
  "$IMAGE"

# Simple health check (best effort)
sleep 3
$DOCKER_BIN ps --filter "name=$CONTAINER_NAME"

echo "[start_application] Launched $CONTAINER_NAME on port ${HOST_PORT}->${CONTAINER_PORT}"
