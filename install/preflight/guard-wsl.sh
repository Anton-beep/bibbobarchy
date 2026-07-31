abort() {
  echo -e "\e[31mOmarchy WSL install requires: $1\e[0m"
  echo
  gum confirm "Proceed anyway on your own accord and without assistance?" || exit 1
}

# Must be running under WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  abort "WSL (Microsoft kernel in /proc/version)"
fi

# Must not be running as root (unless the caller opted in via
# OMARCHY_WSL_ALLOW_ROOT=1; install-wsl.sh normally bootstraps a normal user
# before reaching this guard).
if (( EUID == 0 )) && [[ -z ${OMARCHY_WSL_ALLOW_ROOT:-} ]]; then
  abort "Running as root (not user) -- source install-wsl.sh as a normal user,
or set OMARCHY_WSL_ALLOW_ROOT=1 to allow a root install"
fi

# Must be x86_64 only
if [[ $(uname -m) != "x86_64" ]]; then
  abort "x86_64 CPU"
fi

# WSL skips: Arch distro check (WSL distros vary), limine, btrfs root,
# secure boot, and Gnome/KDE detection -- none apply to a WSL container.

# Cleared all guards
echo "WSL Guards: OK"