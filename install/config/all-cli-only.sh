# CLI-only config stage for WSL installs
# Runs only config scripts that are meaningful in a headless WSL container.
# Skips: theme/branding/keyboard/xcompose/mimetypes/user-dirs/nautilus/walker/
# unmount-fuse/ssh-flakiness/sudoless-asdcontrol/input-group/pi/fast-shutdown/
# kernel-modules-hook/powerprofilesctl/wifi-powersave/plocate-ac-only, and
# everything under config/hardware/.

run_logged $OMARCHY_INSTALL/config/config-wsl.sh
run_logged $OMARCHY_INSTALL/config/theme-wsl.sh
run_logged $OMARCHY_INSTALL/config/git.sh
run_logged $OMARCHY_INSTALL/config/gpg.sh
run_logged $OMARCHY_INSTALL/config/timezones.sh
run_logged $OMARCHY_INSTALL/config/increase-sudo-tries.sh
run_logged $OMARCHY_INSTALL/config/increase-file-watchers.sh
run_logged $OMARCHY_INSTALL/config/increase-fd-limit.sh
run_logged $OMARCHY_INSTALL/config/docker-wsl.sh
run_logged $OMARCHY_INSTALL/config/mise-work.sh
run_logged $OMARCHY_INSTALL/config/omarchy-ai-skill.sh
run_logged $OMARCHY_INSTALL/config/omarchy-toggles.sh