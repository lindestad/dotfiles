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

This repo manages:

- shell, terminal, editor, file manager, prompt, and Git configuration
- bundled fonts and platform-specific config linking
- optional Kanata keyboard remapping
- optional Niri desktop configuration on supported Linux installs
- package installs for the tools used by the dotfiles

See [apps.md](./apps.md) for the package inventory and platform-specific package names.

## Installation

### Linux and WSL

```bash
git clone https://github.com/lindestad/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

`install.sh` detects Arch-based, Debian/Ubuntu-based, Fedora, and WSL installs, then dispatches to the matching platform installer.

The installer prompts for optional components when no flags are provided. Use flags for repeatable installs:

```bash
./install.sh --niri --kanata
./install.sh --no-niri --no-kanata --yes
```

Optional components:

- `--niri` installs and links the Niri desktop stack: niri, waybar, fuzzel, swaylock/swayidle, and related Wayland utilities.
- `--kanata` installs or links Kanata keyboard remapping config where supported.

### Windows (PowerShell)

```powershell
git clone https://github.com/lindestad/dotfiles $HOME\dev\dotfiles
cd $HOME\dev\dotfiles
.\install.ps1
```

The platform-specific scripts are still available for direct use when needed: `install-arch.sh`, `install-ubuntu.sh`, `install-fedora.sh`, `install-wsl.sh`, and `install-windows.ps1`.

---

## Compatibility

This dotfiles setup is designed to support:

- Linux: Arch-based, Debian/Ubuntu-based, and Fedora
- WSL2
- Windows

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
