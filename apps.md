# Apps and Tools

This tracks the packages and post-install tools managed by the platform installers. Keep this file in sync when adding, removing, or renaming entries in `install.sh`, `install.ps1`, or `scripts/install/`.

## Cross-platform

These are the main package and tool installs managed by the platform installers.

| Tool | Arch | Ubuntu | Fedora | WSL | Windows |
| --- | --- | --- | --- | --- | --- |
| 7zip/p7zip | `p7zip` | `p7zip-full` | `7zip` | `p7zip-full` | `7zip.7zip` |
| Alacritty | not installed | not installed | `alacritty` | not installed | not installed |
| Atuin | `atuin` | `atuin` or cargo fallback | `atuin` | `atuin` or cargo fallback | `Atuinsh.Atuin` |
| bat | `bat` | `bat` | `bat` | `bat` | `sharkdp.bat` |
| bottom/btm | `bottom` | `btm` | cargo fallback | `btm` | `Clement.bottom` |
| Broot | `broot` | `broot` or cargo fallback | cargo fallback | `broot` or cargo fallback | `Dystroy.broot` |
| carapace | `carapace-bin` (AUR) | `carapace` or release fallback | release fallback | `carapace` or release fallback | `rsteube.Carapace` |
| direnv | `direnv` | `direnv` | `direnv` | `direnv` | `direnv.direnv` |
| dust | `dust` with cargo fallback | `du-dust` with cargo fallback | `du-dust` with cargo fallback | `du-dust` with cargo fallback | `bootandy.dust` |
| eza | `eza` | `eza` (optional) | `eza` | `eza` (optional) | `eza-community.eza` |
| fd | `fd` | `fd-find` | `fd-find` | `fd-find` | `sharkdp.fd` |
| ffmpeg | `ffmpeg` | `ffmpeg` | `ffmpeg-free` | `ffmpeg` | `Gyan.FFmpeg` |
| fnm | install script | install script | install script | install script | `Schniz.fnm` |
| fzf | `fzf` | `fzf` | `fzf` | `fzf` | `junegunn.fzf` |
| git | `git` | `git` | `git` | `git` | `Git.Git` |
| git-delta | `git-delta` | `git-delta` (optional) | `git-delta` | `git-delta` (optional) | `dandavison.delta` |
| GitHub CLI | `github-cli` | `gh` | `gh` | `gh` | `GitHub.cli` |
| GitUI | `gitui` | `gitui` or cargo fallback | `gitui` with cargo fallback | `gitui` or cargo fallback | `StephanDilly.gitui` |
| Ghostty | `ghostty` | prompted community `.deb` installer | prompted COPR | not installed | not available |
| helix | `helix` | `helix` (optional) | `helix` | release `.deb` fallback | `Helix.Helix` |
| imagemagick | `imagemagick` | `imagemagick` | `ImageMagick` | `imagemagick` | `ImageMagick.ImageMagick` |
| jq | `jq` | `jq` | `jq` | `jq` | `jqlang.jq` |
| just | `just` | `just` or cargo fallback | `just` | `just` or cargo fallback | `Casey.Just` |
| lazygit | `lazygit` | `lazygit` or release fallback | `lazygit` or release fallback | `lazygit` or release fallback | `JesseDuffield.lazygit` |
| Neovim | `neovim` | upstream release with `neovim` fallback | `neovim` | upstream release with `neovim` fallback | `Neovim.Neovim` |
| Node.js LTS | via fnm | via fnm | via fnm | via fnm | via fnm |
| pipx | `python-pipx` | `pipx` | `pipx` | `pipx` | installed with `py -3.12 -m pip install --user pipx` |
| procs | `procs` | `procs` or cargo fallback | `procs` | `procs` or cargo fallback | `dalance.procs` |
| Python | `python` | `python3`, `python3.12`, `python3.12-venv` | `python3.12` | `python3`, `python3.12`, `python3.12-venv` | `Python.Python.3.12` |
| ripgrep | `ripgrep` | `ripgrep` | `ripgrep` | `ripgrep` | `BurntSushi.ripgrep.MSVC` |
| sd | `sd` | `sd` or cargo fallback | cargo fallback | `sd` or cargo fallback | `chmln.sd` |
| ShellCheck | `shellcheck` | `shellcheck` | `ShellCheck` | `shellcheck` | `koalaman.shellcheck` |
| shfmt | `shfmt` | `shfmt` or release fallback | `shfmt` | `shfmt` or release fallback | `mvdan.shfmt` |
| starship | cargo fallback | cargo fallback | cargo fallback | cargo fallback | `Starship.Starship` |
| Typst CLI | `typst` | cargo fallback | cargo fallback | cargo fallback | `Typst.Typst` |
| uutils coreutils | `uutils-coreutils` | `uutils-coreutils` (optional) | `uutils-coreutils` (optional) | not installed | `uutils.coreutils` |
| uv | `uv` | standalone installer | `uv` with standalone fallback | standalone installer | `astral-sh.uv` |
| uv tools | `ty`, `ruff` | `ty`, `ruff` | `ty`, `ruff` | `ty`, `ruff` | `ty`, `ruff` |
| watchexec | `watchexec` | `watchexec` or cargo fallback | cargo fallback | `watchexec` or cargo fallback | upstream release fallback |
| WezTerm | `wezterm` | prompted official APT repo | `wezterm` or prompted official COPR | not installed | `wez.wezterm` |
| xh | `xh` | `xh` or cargo fallback | cargo fallback | `xh` or cargo fallback | `ducaale.xh` |
| yazi | `yazi` | `yazi` (optional) | cargo fallback | `yazi` (optional) | `sxyazi.yazi` |
| yq | `yq` | Mike Farah release fallback | `yq` | Mike Farah release fallback | `MikeFarah.yq` |
| Zellij | `zellij` | cargo fallback | COPR with cargo fallback | cargo fallback | not installed |
| zoxide | `zoxide` | `zoxide` | `zoxide` | `zoxide` | `ajeetdsouza.zoxide` |

## Linux-only

These are installed only by the Linux/WSL shell installers.

| Tool | Arch | Ubuntu | Fedora | WSL |
| --- | --- | --- | --- | --- |
| browser automation | not installed | not installed | `chromium`, `chromium-headless`, `chromedriver`, `xorg-x11-server-Xvfb` | not installed |
| btop | `btop` | `btop` | `btop` | `btop` |
| build tools | not installed | `build-essential`, `cmake` | `gcc`, `gcc-c++`, `make`, `cmake` | `build-essential`, `cmake` |
| ca-certificates | not installed | `ca-certificates` | not installed | `ca-certificates` |
| containers | not installed | not installed | `podman`, `podman-compose`, `buildah` | not installed |
| curl | `curl` | `curl` | `curl` | `curl` |
| database clients/headers | not installed | not installed | `sqlite`, `sqlite-devel`, `postgresql`, `postgresql-devel` | not installed |
| desktop capture/input | not installed | not installed | `grim`, `slurp`, `wl-clipboard`, `xclip`, `xdotool`, `wtype` | not installed |
| diagnostics/networking | not installed | not installed | `bind-utils`, `gdb`, `httpie`, `lsof`, `nmap-ncat`, `procps-ng`, `psmisc`, `strace`, `wget` | not installed |
| file | not installed | `file` | `file` | `file` |
| fontconfig | `fontconfig` | `fontconfig` | `fontconfig` | `fontconfig` |
| htop | `htop` | `htop` | `htop` | `htop` |
| OpenSSL headers | not installed | `libssl-dev` | `openssl-devel` | `libssl-dev` |
| pkg-config | not installed | `pkg-config` | `pkgconf-pkg-config` | `pkg-config` |
| resvg | cargo fallback | cargo fallback | cargo fallback | cargo fallback |
| rustup/cargo | install script | install script | install script | install script |
| tealdeer/tldr | cargo install | cargo install | cargo install | cargo install |
| unzip | `unzip` | `unzip` | `unzip` | `unzip` |
| user fonts | bundled fonts copied to `~/.local/share/fonts` | same | same | same |
| vivid | `vivid` | `vivid` (optional) | cargo fallback | `vivid` (optional) |
| Fedora workflow extras | not installed | not installed | `entr`, `git-lfs`, `tokei`, `tree` | not installed |
| zsh | `zsh` | `zsh` | `zsh` | `zsh` |

## Distro-specific

These are the main package naming differences to check when adding support for another Linux distro.

| Tool | Arch | Ubuntu/WSL | Fedora |
| --- | --- | --- | --- |
| fd | `fd` | `fd-find` | `fd-find` |
| ffmpeg | `ffmpeg` | `ffmpeg` | `ffmpeg-free` |
| ImageMagick | `imagemagick` | `imagemagick` | `ImageMagick` |
| lm sensors | `lm_sensors` | `lm-sensors` | `lm_sensors` |
| network applet | `network-manager-applet` | `network-manager-gnome` | `network-manager-applet` |
| OpenSSL headers | not installed | `libssl-dev` | `openssl-devel` |
| p7zip | `p7zip` | `p7zip-full` | `7zip` |
| pkg-config | not installed | `pkg-config` | `pkgconf-pkg-config` |
| pipx | `python-pipx` | `pipx` | `pipx` |
| Python | `python` | `python3`, `python3.12`, `python3.12-venv` | `python3.12` |

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
| Noctalia Shell | AUR: `noctalia-shell` | Noctalia APT repo: `noctalia-shell` where supported | `noctalia-shell` |
| pavucontrol | `pavucontrol` | `pavucontrol` | `pavucontrol` |
| polkit auth agent | not installed | not installed | `xfce-polkit` |
| power profiles | `power-profiles-daemon` | `power-profiles-daemon` | `power-profiles-daemon` unless `tuned-ppd` is installed |
| sensors | `lm_sensors` | `lm-sensors` | `lm_sensors` |
| swayidle | `swayidle` | `swayidle` | `swayidle` |
| upower | `upower` | `upower` | `upower` |
| wlsunset | `wlsunset` | `wlsunset` | `wlsunset` |
| wl-clipboard | `wl-clipboard` | `wl-clipboard` | `wl-clipboard` |
| xdg desktop portal | not installed | `xdg-desktop-portal` | not installed |

## Optional Keyboard Remapping

Kanata is optional and controlled by `--kanata` on Linux installers or an interactive prompt on Windows.
The Windows installer can also install and enable the tracked US+NO keyboard layout from `keyboard_layouts/us+no`.

| Platform | Install behavior |
| --- | --- |
| Arch | Installs `kanata` from AUR when an AUR helper is available, then can configure system or user startup. |
| Ubuntu | Links the selected config, but package install and service setup are manual. |
| Fedora | Installs `kanata` with Cargo when missing, links the selected config, and configures udev/systemd startup. |
| WSL | Not supported. |
| Windows | Installs `jtroo.kanata_gui` through winget when selected, links/copies config, and runs Windows startup setup. |

## Windows-only

These winget packages are only in `scripts/install/windows.ps1`.

| Tool | Winget ID |
| --- | --- |
| less | `jftuga.less` |
| Poppler | `oschwartz10612.Poppler` |
| PowerShell | `Microsoft.PowerShell` |

## Installer-managed Config

These are not package installs, but the installers manage them alongside the tools above.

| Config | Linux/WSL | Windows |
| --- | --- | --- |
| Alacritty | non-WSL Linux only | linked/copied |
| Atuin config + themes | symlinked | linked/copied |
| Bash profile | Ubuntu only | `.bashrc` linked/copied; `.bash_profile` created if no login profile exists |
| Broot config + skins | symlinked; launchers generated when `broot` is installed | linked/copied to the Broot AppData config directory; Git Bash launcher generated when `broot` is installed |
| Codex instructions | symlinked | linked/copied |
| Git config | copied if missing; missing keys merged | copied if missing; missing keys merged |
| Git global ignore | symlinked | linked/copied |
| Ghostty config + shaders | non-WSL Linux only | not linked |
| Helix | symlinked | linked/copied |
| Neovim | symlinked | linked/copied |
| Noctalia color scheme | optional with `--niri` | not managed |
| Kanata | optional | optional |
| Starship | symlinked | linked/copied |
| Tealdeer | config symlinked with 30-day automatic cache updates | not managed |
| WezTerm | non-WSL Linux only | linked/copied to `.wezterm.lua` and `.config/wezterm/wezterm.lua` |
| Windows Terminal | not managed | Git Bash profile/default configured when settings exist |
| Yazi | symlinked | linked/copied |
| Zsh | symlinked | not linked |
