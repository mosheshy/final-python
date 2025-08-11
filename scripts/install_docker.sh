#!/bin/bash
set -euo pipefail

# Idempotent Docker setup for EC2 (Amazon Linux 2 / Ubuntu)

if command -v docker >/dev/null 2>&1; then
  echo "Docker already installed: $(docker --version)"
else
  if command -v yum >/dev/null 2>&1; then
    echo "Installing Docker via yum..."
    yum update -y
    yum install -y docker
  elif command -v apt-get >/dev/null 2>&1; then
    echo "Installing Docker via apt..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y docker.io
  else
    echo "Unsupported OS: neither yum nor apt-get found" >&2
    exit 1
  fi
fi

# Ensure Docker service is enabled and running
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable docker || true
  systemctl start docker || true
fi

# Add common users to docker group so hooks can run without sudo when not root
for u in ec2-user ubuntu; do
  if id "$u" >/dev/null 2>&1; then
    usermod -aG docker "$u" || true
  fi
done

# Optional: Login to DockerHub if credentials provided via environment variables
if [[ -n "${DOCKERHUB_USERNAME:-}" && -n "${DOCKERHUB_TOKEN:-}" ]]; then
  echo "Logging into DockerHub for $DOCKERHUB_USERNAME ..."
  echo "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin || true
fi

# Verify
docker --version

echo "Docker is ready."