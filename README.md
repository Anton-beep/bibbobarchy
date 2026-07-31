# Bibbobarchy

Read more at [omarchy.org](https://omarchy.org).

## Installation on Arch Linux WSL
### Install

Open and run:

```bash
git clone --branch master https://github.com/Anton-beep/bibbobarchy.git ~/.local/share/omarchy
source ~/.local/share/omarchy/install-wsl.sh
```

### Alacritty on Windows (optional)

To use nice themes of omarchy install alacritty and use config below (or similar).

Create or edit the Windows config file at:

```
%APPDATA%\alacritty\alacritty.toml
```
with the following contents:

```toml
[general]
import = [
  "\\\\wsl.localhost\\archlinux\\home\\usr\\.config\\omarchy\\current\\theme\\alacritty.toml",
  "\\\\wsl.localhost\\archlinux\\home\\usr\\.config\\alacritty\\alacritty.toml"
]

[terminal.shell]
program = "wsl.exe"
args = ["-d", "archlinux"]

[font]
size = 16.0

[font.normal]
family = "JetBrainsMono Nerd Font"
style = "Regular"

[window]
dimensions = { columns = 120, lines = 30 }
decorations = "Full"
```
