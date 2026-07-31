# Whitelist config copy for WSL/CLI-only installs.
# Replaces install/config/config.sh, which does an unconditional `cp -R
# config/*` and would drag in GUI/display clutter (hypr/, waybar/, walker/,
# swayosd/, uwsm/, chromium/, obsidian/, xournalpp/, Typora/, imv/, fcitx5/,
# fontconfig/, autostart/, omarchy.ttf, xdg-terminals.list).
#
# Only CLI-relevant entries are copy-listed here. Terminals (alacritty/foot/
# ghostty/kitty) are kept so theme generation has targets even if no GUI runs.

mkdir -p ~/.config

for entry in alacritty btop fastfetch git ghostty kitty lazygit omarchy \
             opencode starship.toml tmux wiremix systemd environment.d; do
  [[ -e $OMARCHY_PATH/config/$entry ]] && \
    cp -R "$OMARCHY_PATH/config/$entry" ~/.config/
done

# Use default bashrc from Omarchy
cp "$OMARCHY_PATH/default/bashrc" ~/.bashrc