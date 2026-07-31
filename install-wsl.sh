#!/bin/bash

# WSL-specific entry point for installing Omarchy in CLI-only mode.
# Docker engine runs on Windows (Docker Desktop), not in WSL.

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Locate the cloned repo from this script's path (it's sourced, so use
# BASH_SOURCE). This stays valid after we move the clone into the new user's
# home directory because the rest of the bootstrap uses absolute paths.
OMARCHY_REPO_SOURCE="${BASH_SOURCE[0]}"
OMARCHY_REPO_DIR="$(cd -- "$(dirname -- "$OMARCHY_REPO_SOURCE")" && pwd)"

# ---------------------------------------------------------------------------
# Root bootstrap: a fresh Arch WSL instance ships with only the root user.
# When run as root, create a normal user with sudo privileges first, then
# re-exec the installer as that user. Set OMARCHY_WSL_ALLOW_ROOT=1 to skip.
# ---------------------------------------------------------------------------
if (( EUID == 0 )) && [[ -z ${OMARCHY_WSL_ALLOW_ROOT:-} ]]; then
  # Ensure pacman db is fresh and the minimum bootstrap tools are installed.
  # gum is needed by the rest of the installer (presentation.sh, error menu);
  # base-devel provides sudo and the AUR build toolchain needed later.
  pacman -Sy --noconfirm --needed gum sudo base-devel

  # Make sure the wheel group exists for sudo delegation.
  if ! getent group wheel >/dev/null; then
    groupadd -r wheel
  fi

  # Generate the en_US.UTF-8 locale so bash/startup doesn't warn
  # "setlocale: cannot change locale (en_US.UTF-8): No such file or directory"
  # on every login. Fresh Arch WSL ships with all locales commented out.
  if ! locale -a 2>/dev/null | grep -qx 'en_US.UTF-8'; then
    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
  fi

  echo
  gum style --foreground 3 --padding "1 1" "Fresh WSL Arch detected."
  echo "Omarchy installs as a normal (non-root) user with sudo privileges."
  echo "Let's create that user now."
  echo

  # Prompt for username and validate it.
  while true; do
    OMARCHY_NEW_USER=$(gum input --placeholder "Username" --prompt "> ")
    if [[ -z $OMARCHY_NEW_USER ]]; then
      echo "Username cannot be empty."
      continue
    fi
    if [[ ! $OMARCHY_NEW_USER =~ ^[a-z_][a-z0-9_-]*$ ]]; then
      echo "Invalid username. Use lowercase letters, digits, '-' or '_'."
      continue
    fi
    if id "$OMARCHY_NEW_USER" >/dev/null 2>&1; then
      echo "User '$OMARCHY_NEW_USER' already exists."
      # Reuse existing user instead of failing out.
      gum confirm "Re-use existing user '$OMARCHY_NEW_USER' and continue?" || { echo "Aborting."; exit 1; }
    fi
    break
  done

  # Prompt for password (with confirmation) only when creating a new user.
  if ! id "$OMARCHY_NEW_USER" >/dev/null 2>&1; then
    while true; do
      OMARCHY_NEW_PASS=$(gum input --password --placeholder "Password" --prompt "> ")
      if [[ -z $OMARCHY_NEW_PASS ]]; then
        echo "Password cannot be empty."
        continue
      fi
      OMARCHY_NEW_PASS2=$(gum input --password --placeholder "Confirm password" --prompt "> ")
      if [[ $OMARCHY_NEW_PASS != "$OMARCHY_NEW_PASS2" ]]; then
        echo "Passwords do not match. Try again."
        continue
      fi
      break
    done

    useradd -m -G wheel -s /bin/bash "$OMARCHY_NEW_USER"
    echo "$OMARCHY_NEW_USER:$OMARCHY_NEW_PASS" | chpasswd
  fi

  # Allow the wheel group to use sudo with a password (permanent rule).
  echo "%wheel ALL=(ALL:ALL) ALL" >/etc/sudoers.d/10-omarchy-wheel
  chmod 440 /etc/sudoers.d/10-omarchy-wheel

  # Temporary passwordless sudo for the new user, only for the duration of
  # the install. The install runs non-interactively via `su -l -c`, so it
  # cannot prompt for a sudo password; without this, the first `sudo` call
  # (e.g. preflight/pacman.sh) fails under `set -e` and the session dies.
  # finished-wsl.sh removes this file so normal use still requires a password.
  echo "$OMARCHY_NEW_USER ALL=(ALL:ALL) NOPASSWD: ALL" >/etc/sudoers.d/11-omarchy-wsl-install-nopasswd
  chmod 440 /etc/sudoers.d/11-omarchy-wsl-install-nopasswd

  # Optional git identity (config/git.sh reads these env vars later).
  echo
  echo "Optional: provide a git identity for ~/.gitconfig."
  OMARCHY_GIT_NAME=$(gum input --placeholder "Git user.name (leave empty to skip)" --prompt "> ")
  OMARCHY_GIT_EMAIL=$(gum input --placeholder "Git user.email (leave empty to skip)" --prompt "> ")

  # Move the cloned repo into the new user's home so they own it.
  NEW_HOME=$(getent passwd "$OMARCHY_NEW_USER" | cut -d: -f6)
  mkdir -p "$NEW_HOME/.local/share" "$NEW_HOME/.local/state" "$NEW_HOME/.local/bin"
  if [[ $OMARCHY_REPO_DIR != "$NEW_HOME/.local/share/omarchy" ]]; then
    rm -rf "$NEW_HOME/.local/share/omarchy"
    mv "$OMARCHY_REPO_DIR" "$NEW_HOME/.local/share/omarchy"
  fi
  # chown the entire ~/.local tree (not just the omarchy subdir). The mkdir
  # above runs as root and would otherwise leave ~/.local, ~/.local/share,
  # ~/.local/state, ~/.local/bin owned by root, causing "Permission denied"
  # in migrations.sh / nvim.sh / npx.sh / mise-work.sh / omarchy-toggles.sh.
  chown -R "$OMARCHY_NEW_USER:$OMARCHY_NEW_USER" "$NEW_HOME/.local"

  # Set the WSL default user so future `wsl` launches log in as the new user
  # (where the repo now lives). Without this, WSL reopens as root, where the
  # repo appears "deleted" because it was moved to /home/<user>.
  mkdir -p /etc
  if [[ -f /etc/wsl.conf ]]; then
    crudini --set /etc/wsl.conf user default "$OMARCHY_NEW_USER" 2>/dev/null || true
  fi
  if ! grep -q "^\[user\]" /etc/wsl.conf 2>/dev/null; then
    printf '\n[user]\ndefault=%s\n' "$OMARCHY_NEW_USER" >>/etc/wsl.conf
  else
    sed -i "s/^default=.*/default=$OMARCHY_NEW_USER/" /etc/wsl.conf
  fi

  # Make `wsl` relaunch pull in the new default user on the Windows side.
  printf '\n[boot]\nsystemd=true\n' >>/etc/wsl.conf 2>/dev/null || true

  # Persist the captured env vars across the su re-exec via a temp file.
  # Escape single quotes in values using the standard '\'' pattern.
  GIT_NAME_ESC="${OMARCHY_GIT_NAME//\'/\'\\\'\'}"
  GIT_EMAIL_ESC="${OMARCHY_GIT_EMAIL//\'/\'\\\'\'}"
cat >/tmp/omarchy-wsl-bootstrap.env <<EOF
export OMARCHY_USER_NAME='$GIT_NAME_ESC'
export OMARCHY_USER_EMAIL='$GIT_EMAIL_ESC'
export OMARCHY_WSL_INSTALL=1
export OMARCHY_ONLINE_INSTALL=1
EOF
  # Make the env file removable by the new user (it'll be deleted after the
  # install runs). chmod 666 since the file is created by root but read+deleted
  # by the non-root user we su into.
  chmod 666 /tmp/omarchy-wsl-bootstrap.env

  # Write a runner script instead of inlining a long `bash -c '...'` string
  # inside `su -c`. This avoids quote-escaping issues and gives the new user's
  # login shell a proper script to source, so the final `exec bash -li` gets
  # job control / a working TTY instead of the "no job control in this shell"
  # warning that `su -c "bash -c '...'"` produces.
  cat >/tmp/omarchy-wsl-run.sh <<'RUNNER'
#!/bin/bash
source /tmp/omarchy-wsl-bootstrap.env 2>/dev/null
( source "$HOME/.local/share/omarchy/install-wsl.sh" ) || echo "Omarchy install exited ($?)"
rm -f /tmp/omarchy-wsl-bootstrap.env 2>/dev/null || true
rm -f /tmp/omarchy-wsl-run.sh 2>/dev/null || true
RUNNER
  chmod 755 /tmp/omarchy-wsl-run.sh
  chown "$OMARCHY_NEW_USER:$OMARCHY_NEW_USER" /tmp/omarchy-wsl-run.sh

  echo
  gum style --foreground 2 "Switching to user '$OMARCHY_NEW_USER' and continuing install..."
  echo

  # Run the install as the new user (no `exec` so the root shell stays alive
  # and we can drop into a real interactive login shell afterward). The runner
  # sources install-wsl.sh wrapped in `( ... ) || ...` so a failing stage
  # (which sets `set -eEo pipefail` and installs an ERR trap) can't prevent
  # cleanup from running. Disable errexit around this call so a failed install
  # still lets us hand the user an interactive shell instead of exiting WSL.
  set +e
  su -l "$OMARCHY_NEW_USER" -c "/tmp/omarchy-wsl-run.sh"
  set -e

  # Drop into a real interactive login shell as the new user. Unlike
  # `su -l -c "bash -li"` (which has no controlling TTY and prints "no job
  # control in this shell"), bare `su -l <user>` allocates a TTY and gives
  # proper job control. `exec` replaces the root shell so WSL stays attached
  # to this process and doesn't fall back to PowerShell when root exits.
  exec su -l "$OMARCHY_NEW_USER"
fi

# ---------------------------------------------------------------------------
# From here we are running as a normal user (or OMARCHY_WSL_ALLOW_ROOT=1).
# ---------------------------------------------------------------------------

# Define Omarchy locations
export OMARCHY_PATH="$HOME/.local/share/omarchy"
export OMARCHY_INSTALL="$OMARCHY_PATH/install"
export OMARCHY_INSTALL_LOG_FILE="/var/log/omarchy-install.log"
export PATH="$OMARCHY_PATH/bin:$PATH"

# Mark this as a WSL/CLI-only install so individual scripts can detect it
export OMARCHY_WSL_INSTALL=1

# WSL installs are online (not ISO/chroot): tell preflight/pacman.sh to
# configure the Omarchy custom pacman repos before installing packages.
export OMARCHY_ONLINE_INSTALL=1

# Install only the stages relevant to WSL CLI environments
source "$OMARCHY_INSTALL/helpers/all.sh"
source "$OMARCHY_INSTALL/preflight/all-wsl.sh"
source "$OMARCHY_INSTALL/packaging/all-cli-only.sh"
source "$OMARCHY_INSTALL/config/all-cli-only.sh"
source "$OMARCHY_INSTALL/post-install/all-wsl.sh"
