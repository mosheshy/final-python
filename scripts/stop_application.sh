#!/bin/bash
set -euo pipefail

CONTAINER_NAME="final-python-app"

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

echo "Stopping $CONTAINER_NAME container..."
$DOCKER stop "$CONTAINER_NAME" 2>/dev/null || true
$DOCKER rm "$CONTAINER_NAME" 2>/dev/null || true

echo "Application stopped successfully"