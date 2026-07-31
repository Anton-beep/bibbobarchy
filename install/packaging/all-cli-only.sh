# CLI-only packaging stage for WSL installs
# Installs the omarchy-cli-only package list, then sets up nvim and npx CLIs.
# Skips GUI packaging stages: fonts, icons, webapps, tuis, and all
# hardware-specific packaging scripts.

mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-cli-only.packages" | grep -v '^$')
omarchy-pkg-add "${packages[@]}"

run_logged $OMARCHY_INSTALL/packaging/nvim.sh
run_logged $OMARCHY_INSTALL/packaging/npx.sh