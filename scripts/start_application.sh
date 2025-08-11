#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/final-python-app"
CONTAINER_NAME="final-python-app"
IMAGE_USER="${DOCKERHUB_USERNAME:-mosheshy}"   # override via env if needed
IMAGE="$IMAGE_USER/final-python-app:latest"

mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Pick docker or sudo docker depending on permissions
DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
    DOCKER="sudo docker"
  else
    echo "Docker is not accessible. Ensure it is installed and running." >&2
    exit 1
  fi
fi

# Stop/remove any existing container
$DOCKER stop "$CONTAINER_NAME" 2>/dev/null || true
$DOCKER rm "$CONTAINER_NAME" 2>/dev/null || true

# Pull and run the image
$DOCKER pull "$IMAGE"
$DOCKER run -d \
  --name "$CONTAINER_NAME" \
  -p 5000:5000 \
  --restart unless-stopped \
  "$IMAGE"

sleep 5

# Verify
if $DOCKER ps | grep -q "$CONTAINER_NAME"; then
  echo "Application started on port 5000"
  $DOCKER ps | grep "$CONTAINER_NAME"
else
  echo "Failed to start container" >&2
  $DOCKER logs "$CONTAINER_NAME" || true
  exit 1
fi