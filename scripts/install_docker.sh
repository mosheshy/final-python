#!/usr/bin/env bash
set -euo pipefail

# ---------------------------
# install_docker.sh + cleanup
# ---------------------------
# - Installs/starts Docker on Amazon Linux 2 / 2023
# - Adds ec2-user to docker group
# - (NEW) Cleans target deploy directory BEFORE files copy
#
# Run as: root (CodeDeploy hook: BeforeInstall, runas: root)
#
# Overridable env:
#   TARGET_DIR   (default: /home/ec2-user/final-python-app)
#   USER_NAME    (default: ec2-user)
# ---------------------------

USER_NAME="${USER_NAME:-ec2-user}"
TARGET_DIR="${TARGET_DIR:-/home/ec2-user/final-python-app}"

# Detect Amazon Linux 2023 vs 2
is_al2023=false
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "${NAME:-}" == "Amazon Linux" && "${VERSION_ID:-}" =~ ^2023 ]]; then
    is_al2023=true
  fi
fi

echo "[install_docker] Starting. AL2023=${is_al2023}"

# Update
if $is_al2023; then
  dnf -y update
else
  yum -y update
fi

# Install Docker if missing
if ! command -v docker >/dev/null 2>&1; then
  echo "[install_docker] Installing Docker..."
  if $is_al2023; then
    dnf -y install docker
  else
    amazon-linux-extras install -y docker || yum -y install docker
  fi
else
  echo "[install_docker] Docker already installed."
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

# Allow USER_NAME to use docker (future logins)
if id "${USER_NAME}" &>/dev/null; then
  if ! id -nG "${USER_NAME}" | grep -qw docker; then
    usermod -aG docker "${USER_NAME}"
    # Refresh CodeDeploy agent session so ApplicationStart (runas ec2-user) sees new group
    systemctl restart codedeploy-agent || true
  fi
fi

echo "[install_docker] Docker version: $(docker --version || echo 'unknown')"

# ---------------------------
# CLEANUP (BeforeInstall)
# ---------------------------
# Remove stale target dir to avoid 'file already exists' errors
echo "[cleanup] Removing target dir: ${TARGET_DIR}"
rm -rf "${TARGET_DIR}" || true
mkdir -p "${TARGET_DIR}"
chown -R "${USER_NAME}:${USER_NAME}" "${TARGET_DIR}"
echo "[cleanup] Done. ${TARGET_DIR} recreated and owned by ${USER_NAME}"
