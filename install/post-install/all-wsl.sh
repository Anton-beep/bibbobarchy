# WSL post-install stage: configure pacman and show the finish message,
# but skip the reboot prompt (WSL is restarted from Windows, not via reboot).

run_logged $OMARCHY_INSTALL/post-install/pacman.sh
source $OMARCHY_INSTALL/post-install/finished-wsl.sh