# WSL Installation Plan for Bibbobarchy

## Overview
Install bibbobarchy on WSL Arch Linux with CLI tools only, no graphical applications. Docker engine runs on Windows, not in WSL.

## Files to Create

### 1. `install-wsl.sh`
WSL-specific entry point that runs only relevant stages:
- helpers → preflight (WSL guard) → packaging (CLI only) → config (shell/docker/nvim only) → post-install (no reboot)

> Implementation: `install-wsl.sh` sources `install/preflight/all-wsl.sh`,
> `install/packaging/all-cli-only.sh`, `install/config/all-cli-only.sh`, and
> `install/post-install/all-wsl.sh`. It exports `OMARCHY_WSL_INSTALL=1` and
> `OMARCHY_ONLINE_INSTALL=1` (so preflight `pacman.sh` configures the Omarchy
> custom pacman repos, since WSL installs are online rather than ISO/chroot).

**Root bootstrap:** a fresh Arch WSL instance ships with only the root user,
which `guard-wsl.sh` rejects. When `install-wsl.sh` is sourced as root it:
1. installs `gum sudo base-devel` (needed for the installer UI and the wheel group),
2. interactively prompts for a username, password, and optional git identity,
3. creates the user with `useradd -m -G wheel`, sets the password, and writes
   `%wheel ALL=(ALL:ALL) ALL` to `/etc/sudoers.d/10-omarchy-wheel`,
4. moves the cloned repo from root's home into the new user's home
   (`~/.local/share/omarchy`) and `chown`s it,
5. writes the git name/email and OMARCHY flags to a temp env file, then
   `exec su -l <user> -c "bash -c 'source /tmp/...env; source ~/.local/share/omarchy/install-wsl.sh; rm ...'"`.
The re-sourced `install-wsl.sh` runs as the new user and `guard-wsl.sh` passes.
Set `OMARCHY_WSL_ALLOW_ROOT=1` to skip the bootstrap and permit a true root
install (discouraged).

### 2. `install/preflight/guard-wsl.sh`
WSL-specific guards:
- Detect WSL (`grep -qi microsoft /proc/version`)
- Must not be root
- Must be x86_64
- Skip: limine, btrfs, secure boot, gnome/kde checks

### 3. `install/omarchy-cli-only.packages`
CLI-only package list (~40 packages):

**Shell**: bash-completion, starship, zoxide, tmux, fzf, gum
**Files**: eza, bat, fd, ripgrep, dust, btop, less, plocate, unzip, man-db
**Dev**: neovim, omarchy-nvim, git, github-cli, lazygit, mise, jq, socat, clang, llvm, rust, ruby, tree-sitter-cli
**Docker**: docker, docker-buildx, docker-compose, lazydocker
**System**: base, base-devel, yay, inetutils, inxi, whois, expac, libyaml, libsecret

### 4. `install/packaging/all-cli-only.sh`
CLI packaging stage:
```bash
mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-cli-only.packages" | grep -v '^$')
omarchy-pkg-add "${packages[@]}"
run_logged $OMARCHY_INSTALL/packaging/nvim.sh
run_logged $OMARCHY_INSTALL/packaging/npx.sh
```

### 5. `install/config/all-cli-only.sh`
CLI config stage - only runs:
- config-wsl.sh (whitelist config copy, replaces config.sh)
- git.sh, gpg.sh, timezones.sh
- increase-sudo-tries.sh, increase-file-watchers.sh, increase-fd-limit.sh
- docker-wsl.sh (modified for WSL)
- mise-work.sh, omarchy-ai-skill.sh, omarchy-toggles.sh

> Rationale: the existing `install/config/config.sh` performs an unconditional
> `cp -R config/* ~/.config/`, which drags in GUI/display clutter unsuitable
> for a CLI-only WSL install (hypr/, waybar/, walker/, swayosd/, uwsm/,
> chromium/, obsidian/, xournalpp/, Typora/, imv/, fcitx5/, fontconfig/,
> autostart/, omarchy.ttf, xdg-terminals.list). `config-wsl.sh` copy-lists
> only the CLI-relevant entries instead.

### 5.1 `install/config/config-wsl.sh`
Whitelist config copy (replaces config.sh for WSL):
```bash
mkdir -p ~/.config
for entry in alacritty btop fastfetch git ghostty kitty lazygit omarchy \
             opencode starship.toml tmux wiremix systemd environment.d; do
  cp -R ~/.local/share/omarchy/config/"$entry" ~/.config/
done
cp ~/.local/share/omarchy/default/bashrc ~/.bashrc
```

Note: verify no CLI tooling reads `~/.config/hypr/` (referenced by
`omarchy-theme-set`) before deciding to drop it; add `hypr` back to the
whitelist if theme generation needs it.

### 6. `install/config/docker-wsl.sh`
WSL Docker configuration:
- Install docker CLI only (no daemon)
- Configure to connect to Windows Docker Desktop socket
- Add user to docker group
- Skip: daemon.json, systemd-resolved, docker.socket enable

### 7. `install/post-install/finished-wsl.sh`
WSL finish script:
- No reboot prompt
- Print message about Docker Desktop WSL integration
- Print message about enabling systemd in `/etc/wsl.conf`

> Implementation: `install/post-install/all-wsl.sh` runs `pacman.sh` then
> sources `finished-wsl.sh`. Reboot/`allow-reboot.sh` are skipped because WSL
> is restarted from Windows (`wsl --shutdown`), not via `reboot`.

## Theme Support

### Approach
Modify `omarchy-theme-set` to detect WSL and skip GUI-specific parts:
```bash
if grep -qi microsoft /proc/version; then
  # Skip: waybar, swayosd, mako, hyprctl, gnome, browser, vscode, obsidian, keyboard
  # Keep: btop, helix, nvim, terminals, gum
fi
```

### What Works
- Core theme system: colors.toml → template generation
- CLI tools: btop, helix, neovim, gum
- Terminal configs: alacritty, foot, ghostty, kitty

### What Gets Skipped
- GUI daemons: waybar, swayosd, mako, hyprctl
- GUI apps: gnome, browser, vscode, obsidian, keyboard RGB

## What Gets Skipped Entirely

### Stages
- `install/login/` - Plymouth, SDDM, hibernation, limine, snapper
- `install/first-run/` - Notifications, WiFi, GNOME theme, firewall

### Config Scripts
- theme.sh (partially), branding.sh
- detect-keyboard-layout, xcompose, nautilus, walker
- All `config/hardware/*` (NVIDIA, Intel, Bluetooth, printers, etc.)
- mimetypes, user-dirs, kernel-modules-hook
- powerprofilesctl, wifi-powersave, plocate-ac-only
- sudoless-asdcontrol, input-group, pi.sh, fast-shutdown
- unmount-fuse, ssh-flakiness, increase-lockout-limit

### Packages
- GUI: hyprland, waybar, sddm, plymouth, chromium, nautilus, obs-studio, mpv
- Display: grim, slurp, wl-clipboard, qt5-wayland, fcitx5
- System: cups, iwd, wireplumber, ufw, all fonts
- Hardware-specific packages

## Shell Configuration
Preserved as-is:
- `default/bash/` setup (aliases, functions, starship, zoxide, fzf, tmux, inputrc)
- `cd` replacement via zoxide (`zd` function)
- All CLI aliases and functions

## Docker Configuration
- Docker CLI installed in WSL
- Connects to Docker Desktop on Windows via socket
- User added to docker group
- No Docker daemon in WSL

## Installation Command
```bash
# Clone and run WSL installer
git clone --branch master https://github.com/Anton-beep/bibbobarchy.git ~/.local/share/omarchy
source ~/.local/share/omarchy/install-wsl.sh
```

## Post-Installation
1. Enable systemd in `/etc/wsl.conf`:
```ini
[boot]
systemd=true
```

2. Enable Docker Desktop WSL integration in Windows settings

3. Restart WSL: `wsl --shutdown`
