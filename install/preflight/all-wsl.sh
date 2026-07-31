# WSL preflight stage: guard, begin logging, then run environment-agnostic
# preflight scripts that are still useful in a WSL/CLI-only container.
# Skips: disable-mkinitcpio (no initramfs in WSL) and first-run-mode
# (sets up sudoers for ufw/gtk-icon-cache etc. that WSL doesn't need).

source $OMARCHY_INSTALL/preflight/guard-wsl.sh
source $OMARCHY_INSTALL/preflight/begin.sh
run_logged $OMARCHY_INSTALL/preflight/show-env.sh
run_logged $OMARCHY_INSTALL/preflight/pacman.sh
run_logged $OMARCHY_INSTALL/preflight/migrations.sh