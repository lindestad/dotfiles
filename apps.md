# Apps and Tools

This tracks the packages and post-install tools managed by the platform installers. Keep this file in sync when adding, removing, or renaming entries in `install-*.sh` or `install-windows.ps1`.

## Cross-platform

These tools are installed on at least one Linux installer and on Windows.

| Tool | Arch | Ubuntu | Fedora | WSL | Windows |
| --- | --- | --- | --- | --- | --- |
| 7zip/p7zip | `p7zip` | `p7zip-full` | `p7zip`, `p7zip-plugins` | `p7zip-full` | `7zip.7zip` |
| bat | `bat` | `bat` | `bat` | `bat` | `sharkdp.bat` |
| carapace | `carapace-bin` (AUR) | `carapace` (optional) | `carapace` (optional) | not installed | `rsteube.Carapace` |
| eza | `eza` | `eza` (optional) | `eza` | `eza` (optional) | `eza-community.eza` |
| fd | `fd` | `fd-find` | `fd-find` | `fd-find` | `sharkdp.fd` |
| ffmpeg | `ffmpeg` | `ffmpeg` | `ffmpeg-free` | `ffmpeg` | `Gyan.FFmpeg` |
| fnm | install script | install script | install script | install script | `Schniz.fnm` |
| fzf | `fzf` | `fzf` | `fzf` | `fzf` | `junegunn.fzf` |
| git | `git` | `git` | `git` | `git` | `Git.Git` |
| git-delta | `git-delta` | `git-delta` (optional) | `git-delta` | `git-delta` (optional) | `dandavison.delta` |
| GitHub CLI | `github-cli` | `gh` | `gh` | `gh` | `GitHub.cli` |
| helix | `helix` | `helix` (optional) | `helix` | release `.deb` fallback | `Helix.Helix` |
| imagemagick | `imagemagick` | `imagemagick` | `ImageMagick` | `imagemagick` | `ImageMagick.ImageMagick` |
| jq | `jq` | `jq` | `jq` | `jq` | `jqlang.jq` |
| ncspot | `ncspot` | `ncspot` (optional) | `ncspot` (optional) | `ncspot` (optional) | `hrkfdn.ncspot` |
| Node.js LTS | via fnm | via fnm | via fnm | via fnm | via fnm |
| ripgrep | `ripgrep` | `ripgrep` | `ripgrep` | `ripgrep` | `BurntSushi.ripgrep.MSVC` |
| ShellCheck | `shellcheck` | `shellcheck` | `ShellCheck` | `shellcheck` | `koalaman.shellcheck` |
| starship | cargo fallback | cargo fallback | cargo fallback | cargo fallback | `Starship.Starship` |
| uutils coreutils | `uutils-coreutils` | `uutils-coreutils` (optional) | `uutils-coreutils` (optional) | not installed | `uutils.coreutils` |
| uv | `uv` | standalone installer | `uv` with standalone fallback | standalone installer | `astral-sh.uv` |
| yazi | `yazi` | `yazi` (optional) | `yazi` (optional) | `yazi` (optional) | `sxyazi.yazi` |
| zoxide | `zoxide` | `zoxide` | `zoxide` | `zoxide` | `ajeetdsouza.zoxide` |

## Linux-only

These are installed only by the Linux/WSL shell installers.

| Tool | Arch | Ubuntu | Fedora | WSL |
| --- | --- | --- | --- | --- |
| bottom/btm | `bottom` | `btm` | cargo fallback | `btm` |
| btop | `btop` | `btop` | `btop` | `btop` |
| ca-certificates | not installed | `ca-certificates` | not installed | `ca-certificates` |
| curl | `curl` | `curl` | `curl` | `curl` |
| fontconfig | `fontconfig` | `fontconfig` | `fontconfig` | `fontconfig` |
| htop | `htop` | `htop` | `htop` | `htop` |
| rustup/cargo | install script | install script | install script | install script |
| unzip | `unzip` | `unzip` | `unzip` | `unzip` |
| user fonts | bundled fonts copied to `~/.local/share/fonts` | same | same | same |
| vivid | `vivid` | `vivid` (optional) | `vivid` (optional) | `vivid` (optional) |
| zsh | `zsh` | `zsh` | `zsh` | `zsh` |

## Distro-specific

These are the main package naming differences to check when adding support for another Linux distro.

| Tool | Arch | Ubuntu/WSL | Fedora |
| --- | --- | --- | --- |
| fd | `fd` | `fd-find` | `fd-find` |
| ffmpeg | `ffmpeg` | `ffmpeg` | `ffmpeg-free` |
| ImageMagick | `imagemagick` | `imagemagick` | `ImageMagick` |
| lm sensors | `lm_sensors` | `lm-sensors` | `lm_sensors` |
| network applet | `network-manager-applet` | `network-manager-gnome` | `NetworkManager-applet` |
| p7zip | `p7zip` | `p7zip-full` | `p7zip`, `p7zip-plugins` |

## WSL-only

These packages are only in `install-wsl.sh`.

| Tool | Package |
| --- | --- |
| build tools | `build-essential` |
| OpenSSL headers | `libssl-dev` |
| pkg-config | `pkg-config` |

## Optional Linux Desktop

These are installed when the Linux installer runs with `--niri`.

| Tool | Arch | Ubuntu | Fedora |
| --- | --- | --- | --- |
| BlueZ | `bluez`, `bluez-utils` | `bluez` | `bluez`, `bluez-tools` |
| brightnessctl | `brightnessctl` | `brightnessctl` | `brightnessctl` |
| cliphist | `cliphist` | `cliphist` | `cliphist` |
| fuzzel | `fuzzel` | `fuzzel` | `fuzzel` |
| network applet | `network-manager-applet` | `network-manager-gnome` | `NetworkManager-applet` |
| niri | `niri` | `niri` | `niri` |
| pavucontrol | `pavucontrol` | `pavucontrol` | `pavucontrol` |
| sensors | `lm_sensors` | `lm-sensors` | `lm_sensors` |
| swayidle | `swayidle` | `swayidle` | `swayidle` |
| swaylock | `swaylock` | `swaylock` | `swaylock` |
| waybar | `waybar` | `waybar` | `waybar` |
| wl-clipboard | `wl-clipboard` | `wl-clipboard` | `wl-clipboard` |

## Optional Keyboard Remapping

Kanata is optional and controlled by `--kanata` on Linux installers or an interactive prompt on Windows.

| Platform | Install behavior |
| --- | --- |
| Arch | Installs `kanata` from AUR when an AUR helper is available, then can configure system or user startup. |
| Ubuntu | Links the selected config, but package install and service setup are manual. |
| Fedora | Installs `kanata` with Cargo when missing, links the selected config, and configures udev/systemd startup. |
| WSL | Not supported. |
| Windows | Installs `jtroo.kanata_gui` through winget when selected, links/copies config, and runs Windows startup setup. |

## Windows-only

These winget packages are only in `install-windows.ps1`.

| Tool | Winget ID |
| --- | --- |
| less | `jftuga.less` |
| Nushell | `Nushell.Nushell` |
| Poppler | `oschwartz10612.Poppler` |
| PowerShell | `Microsoft.PowerShell` |

## Installer-managed Config

These are not package installs, but the installers manage them alongside the tools above.

| Config | Linux/WSL | Windows |
| --- | --- | --- |
| Alacritty | non-WSL Linux only | not linked |
| Bash profile | Ubuntu only | linked/copied |
| Git config | copied if missing | copied if missing |
| Helix | symlinked | linked/copied |
| Kanata | optional | optional |
| ncspot | symlinked | linked/copied |
| Nushell | Ubuntu only | linked/copied |
| Starship | symlinked | linked/copied |
| Windows Terminal | not managed | Git Bash profile/default configured when settings exist |
| Yazi | symlinked | linked/copied |
| Zsh | symlinked | not linked |
