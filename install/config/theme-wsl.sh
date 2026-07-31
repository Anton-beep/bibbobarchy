# WSL-safe theme setup: sets the initial theme so the neovim theme symlink
# (created by omarchy-nvim-setup -> ~/.config/omarchy/current/theme/neovim.lua)
# has a valid target. Skips all GUI-specific parts of config/theme.sh
# (nautilus icons, chromium policy, mako link, singleton lock, swaybg).
#
# omarchy-theme-set already self-detects WSL and skips GUI restarts/setters,
# so we only need to suppress the background swapper (swaybg/notify-send).

# Setup user theme folder
mkdir -p ~/.config/omarchy/themes

# Set initial theme, skipping background (no wallpaper daemon in WSL)
OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy-theme-set "Tokyo Night"

# Wire up btop to the current theme (CLI-relevant)
mkdir -p ~/.config/btop/themes
ln -snf ~/.config/omarchy/current/theme/btop.theme ~/.config/btop/themes/current.theme