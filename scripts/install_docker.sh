#!/usr/bin/env bash
set -euo pipefail

# Detect Amazon Linux 2 vs 2023
is_al2023=false
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "${NAME:-}" == "Amazon Linux" && "${VERSION_ID:-}" =~ ^2023 ]]; then
    is_al2023=true
  fi
fi

# Update
if $is_al2023; then
  dnf -y update
else
  yum -y update
fi

# Install Docker
if ! command -v docker >/dev/null 2>&1; then
  if $is_al2023; then
    dnf -y install docker
  else
    amazon-linux-extras install -y docker || yum -y install docker
  fi
fi

# Enable & start Docker
systemctl enable docker
systemctl start docker

# Optional: docker compose v2 plugin (best-effort)
if $is_al2023; then
  dnf -y install docker-compose-plugin || true
else
  yum -y install docker-compose-plugin || true
fi

# Let ec2-user use docker (future sessions)
if id ec2-user &>/dev/null; then
  if ! id -nG ec2-user | grep -qw docker; then
    usermod -aG docker ec2-user
    # Refresh CodeDeploy agent session so ApplicationStart (runas ec2-user) gets the new group
    systemctl restart codedeploy-agent || true
  fi
fi

echo "[install_docker] Docker version: $(docker --version || echo 'unknown')"
