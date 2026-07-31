stop_install_log

echo_in_style() {
  if command -v tte >/dev/null 2>&1; then
    echo "$1" | tte --canvas-width 0 --anchor-text c --frame-rate 640 print
  else
    echo "$1"
  fi
}

clear
echo
if command -v tte >/dev/null 2>&1 && [[ -f ~/.local/share/omarchy/logo.txt ]]; then
  tte -i ~/.local/share/omarchy/logo.txt --canvas-width 0 --anchor-text c --frame-rate 920 laseretch
elif [[ -f ~/.local/share/omarchy/logo.txt ]]; then
  cat ~/.local/share/omarchy/logo.txt
fi
echo

# Display installation time if available
if [[ -f $OMARCHY_INSTALL_LOG_FILE ]] && grep -q "Total:" "$OMARCHY_INSTALL_LOG_FILE" 2>/dev/null; then
  echo
  TOTAL_TIME=$(tail -n 20 "$OMARCHY_INSTALL_LOG_FILE" | grep "^Total:" | sed 's/^Total:[[:space:]]*//')
  if [[ -n $TOTAL_TIME ]]; then
    echo_in_style "Installed in $TOTAL_TIME"
  fi
else
  echo_in_style "Finished installing"
fi

# Clean up the passwordless-reboot sudoers rule if present; there is no reboot
# step in WSL so this is just hygiene.
if sudo test -f /etc/sudoers.d/99-omarchy-installer-reboot; then
  sudo rm -f /etc/sudoers.d/99-omarchy-installer-reboot &>/dev/null
fi

# Remove the temporary passwordless-sudo rule granted to this user by the
# WSL root bootstrap (install-wsl.sh). Normal sudo via the wheel group
# (password required) remains in /etc/sudoers.d/10-omarchy-wheel.
if sudo test -f /etc/sudoers.d/11-omarchy-wsl-install-nopasswd; then
  sudo rm -f /etc/sudoers.d/11-omarchy-wsl-install-nopasswd &>/dev/null
fi

echo
gum style --foreground 3 --padding "1 0" "WSL post-install steps:"
echo
echo "  1. Enable systemd in /etc/wsl.conf (edit on the Windows side or with sudo):"
echo
echo "     [boot]"
echo "     systemd=true"
echo
echo "  2. Enable Docker Desktop WSL integration in Windows settings"
echo "     (Docker Desktop -> Settings -> Resources -> WSL Integration)."
echo
echo "  3. Restart WSL from Windows PowerShell:  wsl --shutdown"
echo
echo "  4. Open a new WSL session for docker group membership and DOCKER_HOST"
echo "     to take effect."
echo