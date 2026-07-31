# Docker configuration for WSL.
# Docker engine runs on Windows (Docker Desktop); only the CLI is installed
# in WSL and pointed at the Docker Desktop socket.
#
# Skipped from config/docker.sh: daemon.json, systemd-resolved config,
# docker.socket enable, no-block-boot drop-in -- none apply when the
# daemon runs on the Windows host.

# Add this user to the docker group so docker CLI works without sudo.
# (Group membership only takes full effect after a new login / WSL restart.)
sudo usermod -aG docker "$USER" 2>/dev/null || true

# Point docker CLI at Docker Desktop's guest socket if Docker Desktop is the
# backend and the socket isn't already exposed at the default location.
# Docker Desktop exposes the socket via the WSL integration at:
#   /mnt/wsl/docker-desktop/shared-sockets/guest-services/docker.sock
# and also symlinks /var/run/docker.sock to it once integration is enabled.
if [[ ! -e /var/run/docker.sock ]] && \
   [[ -e /mnt/wsl/docker-desktop/shared-sockets/guest-services/docker.sock ]]; then
  sudo mkdir -p /var/run
  sudo ln -sf \
    /mnt/wsl/docker-desktop/shared-sockets/guest-services/docker.sock \
    /var/run/docker.sock
fi

# Minimal DOCKER_HOST hint in case the link above isn't present.
# Sourced by bashrc via the omarchy environment.d dir if needed.
DOCKER_HOST_SOCK="/mnt/wsl/docker-desktop/shared-sockets/guest-services/docker.sock"
if [[ -S $DOCKER_HOST_SOCK ]]; then
  mkdir -p ~/.config/environment.d
  echo "DOCKER_HOST=unix://$DOCKER_HOST_SOCK" >~/.config/environment.d/30-docker-wsl.conf
fi