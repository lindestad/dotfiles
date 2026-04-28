<h1 align="center">
  <img align="left" width="140" height="140" src="https://www.svgrepo.com/show/361365/terminal-bash.svg">
  <a name="top">~/.dotfiles</a><br/><br/>
  <sup>Cross-platform, cross-shell configuration</sup><br/><sub><br/></sub>
</h1>
<div align="center">
  <a href="https://github.com/lindestad/dotfiles/blob/main/LICENSE">
    <img alt="License: MIT" src="https://img.shields.io/github/license/lindestad/dotfiles?style=flat-square">
  </a>
  <a href="https://github.com/lindestad/dotfiles/stargazers">
    <img alt="Stars" src="https://img.shields.io/github/stars/lindestad/dotfiles?style=flat-square">
  </a>
  <a href="https://github.com/lindestad/dotfiles/actions">
    <img alt="Build Status" src="https://img.shields.io/github/actions/workflow/status/lindestad/dotfiles/lint.yml?branch=main&style=flat-square">
  </a>
</div>

---

This repository provides a unified development environment across **Linux**, **Windows**, and **WSL**, with version-controlled configuration for editors, terminals, shells, and CLI tools.

<img width="1785" height="230" alt="image" src="https://github.com/user-attachments/assets/09046c6d-0bb9-4652-bbe6-93a2a78cd9bd" />

## Contents

- Configuration for:
  - **All Operating Systems**: Linux, Windows, WSL
    - **[Helix](https://github.com/helix-editor/helix)** – Modal code editor
    - **[Starship](https://github.com/starship/starship)** – Cross-shell prompt
    - **[Yazi](https://github.com/sxyazi/yazi)** – TUI file manager
    - **[Ncspot](https://github.com/hrkfdn/ncspot)** – Terminal-based Spotify client
    - **[Kanata](https://github.com/jtroo/kanata)** – Key remapping – see [Key remapping section](#kanata-key-remappings) below
    - **[Alacritty](https://github.com/alacritty/alacritty)** – GPU-accelerated terminal emulator
  - **Arch/Fedora**:
    - **[Zsh](https://www.zsh.org/)** – Solid POSIX shell
    - **[niri](https://github.com/YaLTeR/niri)** – Wayland tiling window manager  
    - **[Waybar](https://github.com/Alexays/Waybar)** – Highly customizable status bar for Wayland  
    - **[Neofetch](https://github.com/dylanaraps/neofetch)** – Command-line system information tool  
    - **[Fuzzel](https://codeberg.org/dnkl/fuzzel)** – Wayland-native application launcher
    - **[Zellij](https://github.com/zellij-org/zellij)** – Terminal multiplexer
  - **Windows**:
    - **[Nushell](https://github.com/nushell/nushell)** – Structured shell (with Bash/Zsh/Pwsh fallbacks)
    - **[Windows Terminal](https://github.com/microsoft/terminal)** – Modern terminal application for Windows

## Installation

### Arch

```bash
git clone https://github.com/lindestad/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install-arch.sh
```

### Ubuntu

```bash
git clone https://github.com/lindestad/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install-ubuntu.sh
```

### Fedora

```bash
git clone https://github.com/lindestad/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install-fedora.sh
```

The distro installers prompt for optional components when no flags are provided.
Use flags for repeatable installs:

```bash
./install.sh --niri --kanata
./install-fedora.sh --no-niri --no-kanata --yes
```

Optional components:

- `--niri` installs and links the Niri desktop stack: niri, waybar, fuzzel, swaylock/swayidle, and related Wayland utilities.
- `--kanata` installs or links Kanata keyboard remapping config where supported.

### WSL (Ubuntu)

```bash
git clone https://github.com/lindestad/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install-wsl.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/lindestad/dotfiles $HOME\dev\dotfiles
cd $HOME\dev\dotfiles
.\install-windows.ps1
```

The installation scripts install required packages, install bundled fonts, and symlink configuration files. `./install.sh` and `.\install.ps1` remain as compatibility dispatchers.

---

## Compatibility

This dotfiles setup is designed to support:

- 🐧 Linux (Arch-based, Ubuntu, Fedora)
- 🪟 Windows
- 🧊 WSL2

---

## Kanata Key Remappings

Kanata is an optional install. Use `--kanata`, or answer the installer prompt when running interactively.

**Standard binds:**

- `Caps Lock` → `LeftCtrl`
- `LeftCtrl` → `Escape`
- `RightCtrl` → `Caps Lock`
- `RightAlt` + `;`/`'`/`[` → `ø`/`æ`/`å`

**Optional binds:**

These binds are only enabled if selected during install.
*Warning:* Enter is rebound

- ISO to ANSI-like feel:
- `<` key (Between `LeftShift` and `Z`) → `LeftShift` -- Emulates long left shift key
- `Enter` → `\` -- Remap `Enter` to the key that resides above `Enter` on ANSI.
- `\` key (between `'` and `Enter`) → `Enter` -- Emulates long enter key, shorter stroke

**Force exit Kanata:**
`LeftCtrl` + `Space` + `Esc` (Ignores rebinds).

---

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for details.

---

<p align="center">
  <a href="#top">Back to top ↑</a>
</p>
