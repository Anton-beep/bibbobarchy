# Omarchy

Omarchy is a beautiful, modern & opinionated Linux distribution by DHH.

Read more at [omarchy.org](https://omarchy.org).

## Installation on Arch Linux WSL

Bibbobarchy ships a WSL-specific installer that runs in CLI-only mode (no GUI),
with Docker CLI connecting to Docker Desktop on Windows. The bootstrap creates
a normal user with sudo privileges when run as root (the default state of a
fresh Arch WSL instance), then re-execs the installer as that user.

### Prerequisites

- Windows 10/11 with WSL 2 enabled
- An Arch Linux WSL distro imported or installed (e.g. via `archlinux`
  from the Microsoft Store, or `wsl --import` from the official rootfs at
  https://gitlab.archlinux.org/archlinux/arch-boxes/)

### Install

Open the Arch WSL distro as root (the only user that exists on a fresh
install) and run:

```bash
git clone --branch master https://github.com/Anton-beep/bibbobarchy.git ~/.local/share/omarchy
source ~/.local/share/omarchy/install-wsl.sh
```

The installer will:
1. Install `gum`, `sudo`, and `base-devel` (needed for the installer UI and
   the wheel group)
2. Prompt for a username, password, and optional git identity
3. Create the user with `useradd -m -G wheel`, grant temporary passwordless
   sudo, and set `/etc/wsl.conf` so future `wsl` launches log in as that user
4. Move the cloned repo into the new user's home and `chown` the whole
   `~/.local` tree
5. Re-exec the installer as the new user and run the CLI-only install stages
   (preflight, packaging, config, post-install)
6. Drop you into an interactive login shell as the new user when finished

### Post-install steps

1. Enable systemd in `/etc/wsl.conf` (edit as root):

   ```ini
   [boot]
   systemd=true
   ```

   The installer already adds this; verify with `cat /etc/wsl.conf`.

2. Enable Docker Desktop WSL integration in Windows settings
   (Docker Desktop -> Settings -> Resources -> WSL Integration).

3. Restart WSL from PowerShell:

   ```powershell
   wsl --shutdown
   wsl -d archlinux
   ```

4. Open a new WSL session for docker group membership and `DOCKER_HOST` to
   take effect.

### Alacritty on Windows (optional)

Alacritty on Windows reads its config from a Windows path, not from WSL's
`~/.config/`. To merge Omarchy's themed WSL config with Windows-specific
settings (font, window size, decorations), use the `general.import` directive
to pull in the WSL theme and config files.

Create or edit the Windows config file at:

```
%APPDATA%\alacritty\alacritty.toml
```

(equivalently `C:\Users\<YourUser>\AppData\Roaming\alacritty\alacritty.toml`)
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

How the merge works:
- The first import pulls in Omarchy's generated theme colors
  (`[colors.*]` sections)
- The second import pulls in the WSL `alacritty.toml` (env, keyboard
  bindings, etc.) — note its own `~/.config/omarchy/...` import is ignored on
  Windows because `~` resolves to the Windows home, not WSL's, which is why
  we import the theme file directly above
- The keys at the end (`[font]`, `[window]`) override anything from the
  imported files, so `decorations = "Full"` restores the Windows title bar
  that the WSL config sets to `"None"`

Change themes later from WSL:

```bash
omarchy-theme-set "Catppuccin"
# restart Alacritty (it does not watch imported files for changes)
```

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).
