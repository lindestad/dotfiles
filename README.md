<h1 align="center">
  <img align="left" width="140" height="140" src="./docs/assets/terminal-bash.svg">
  <a name="top">~/.dotfiles</a><br/><br/>
  <sup>Cross-platform, cross-shell configuration</sup><br/><sub><br/></sub>
</h1>
<div align="center">
  <a href="https://github.com/lindestad/dotfiles/blob/main/LICENSE">
    <img alt="License: MIT" src="https://img.shields.io/github/license/lindestad/dotfiles?style=for-the-badge&labelColor=101418&color=b9c8da">
  </a>
  <a href="https://github.com/lindestad/dotfiles/stargazers">
    <img alt="Stars" src="https://img.shields.io/github/stars/lindestad/dotfiles?style=for-the-badge&labelColor=101418&color=ffd700">
  </a>
  <a href="https://github.com/lindestad/dotfiles/actions">
    <img alt="Build Status" src="https://img.shields.io/github/actions/workflow/status/lindestad/dotfiles/lint.yml?branch=main&style=for-the-badge&labelColor=101418">
  </a>
</div>

---

This repository provides a unified development environment across **Linux**, **Windows**, and **WSL**, with version-controlled configuration for editors, terminals, shells, and CLI tools.

<img width="1785" height="230" alt="image" src="https://github.com/user-attachments/assets/09046c6d-0bb9-4652-bbe6-93a2a78cd9bd" />

## Contents

This repo manages:

- shell, terminal, editor, file manager, prompt, and Git configuration
- bundled fonts and platform-specific config linking
- optional keyboard layout and Kanata laptop remapping
- optional Niri + Noctalia desktop configuration on supported Linux installs
- package installs for the tools used by the dotfiles

See [apps.md](./apps.md) for the package inventory and platform-specific package names.

## Installation

### Linux and WSL

```bash
git clone https://github.com/lindestad/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

`install.sh` detects Arch-based, Debian/Ubuntu-based, Fedora, and WSL installs, then dispatches to the matching implementation under `scripts/install/`.

The installer prompts for optional components when no flags are provided. Use flags for repeatable installs:

```bash
./install.sh --niri --kanata
./install.sh --no-niri --no-kanata --yes
```

Optional components:

- `--niri` installs and links the Niri + Noctalia desktop stack: niri, noctalia-shell, NiriMod, fuzzel, swayidle, and related Wayland utilities.
- `--kanata` installs or links Kanata keyboard remapping config where supported.

The CachyOS/Limine Plymouth LUKS prompt theme is documented in [docs/plymouth-luks-theme.md](./docs/plymouth-luks-theme.md).

### Windows (PowerShell)

```powershell
git clone https://github.com/lindestad/dotfiles $HOME\dev\dotfiles
cd $HOME\dev\dotfiles
.\install.ps1
```

`install.sh` and `install.ps1` are the supported entrypoints. Platform-specific installer code lives under `scripts/install/`.

On Windows, the installer can optionally install and enable the tracked US+NO keyboard layout for `RightAlt` Norwegian characters.

## Zellij Sessions

The shell configs keep plain `zellij` unchanged and add a few shortcuts:

- `zp` attaches to a shared editable persistent session named `work`, creating it if needed. Set `ZELLIJ_PERSISTENT_SESSION` or pass a name, e.g. `zp laptop`.
- `zd` starts a fresh dev session with the `dev` layout: two side-by-side panes plus the usual tab/status bars. Pass a name if you want one, e.g. `zd api`.
- `zleft` starts a fresh session with four panes: `btm`, `expensive`, `nvtop`, and an empty shell. Pass a name if you want one, e.g. `zleft monitors`.
- `zdclean` deletes `dev-*` sessions whose saved metadata is older than 14 days. Pass another cutoff in days if needed, e.g. `zdclean 30`.

On Linux, the shell configs set `ZELLIJ_SOCKET_DIR` to `/run/user/$UID/zellij` when that runtime directory exists, so desktop and SSH shells attach to the same live session namespace.

---

## Compatibility

This dotfiles setup is designed to support:

- Linux: Arch-based, Debian/Ubuntu-based, and Fedora
- WSL2
- Windows

---

## Keyboard Layout

The Niri config uses the custom XKB layout in `config/xkb/symbols/usno`. It keeps a US base layout and maps Norwegian characters on AltGr:

- `RightAlt` + `;`/`'`/`[` -> `ø`/`æ`/`å`
- `RightAlt` + `Shift` + `;`/`'`/`[` -> `Ø`/`Æ`/`Å`

The Windows layout source and built installer are tracked under `keyboard_layouts/`.

## Kanata Key Remappings

Kanata is an optional install. Use `--kanata`, or answer the installer prompt when running interactively.

**Standard binds:**

- `Caps Lock` → `LeftCtrl`
- `LeftCtrl` → `Escape`
- `RightCtrl` → `Caps Lock`
- `LeftAlt` ↔ `LeftSuper`
- `RightAlt` passes through for XKB AltGr

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
