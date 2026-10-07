# CLI-only packaging stage for WSL installs
# Installs the omarchy-cli-only package list (neovim via packages, node CLIs via mise).
# Skips GUI packaging stages: fonts, icons, webapps, tuis, and all
# hardware-specific packaging scripts.

mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-cli-only.packages" | grep -v '^$')
omarchy-pkg-add "${packages[@]}"

# NOTE (quattro merge): packaging/nvim.sh + npx.sh are gone upstream;
# neovim/omarchy-nvim come from omarchy-cli-only.packages, node CLIs via mise.