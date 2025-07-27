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
  - **Helix** – Modal code editor
  - **Starship** – Cross-shell prompt
  - **Yazi** – TUI file manager
  - **Ncspot** – Terminal-based Spotify client
  - **Zellij** – Terminal multiplexer
  - **Nushell** – Structured shell (with Bash/Zsh/Pwsh fallbacks)
  - **Patched Nerd Fonts** – (MesloLGS NF)

## Installation

### Linux / WSL

```bash
git clone https://github.com/lindestad/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh
````

### Windows (PowerShell)

```powershell
git clone https://github.com/lindestad/dotfiles $HOME\.dotfiles
cd $HOME\.dotfiles
.\install.ps1
```

The installation scripts install required packages and symlink configuration files. You may also run `symlink.ps1` or `symlink.sh` directly to skip system configuration.

---

## Compatibility

This dotfiles setup is designed to support:

* 🐧 Linux (Ubuntu, Arch-based)
* 🪟 Windows
* 🧊 WSL2

Shells tested:

* [x] Nushell
* [x] PowerShell
* [x] Zsh
* [x] Bash

---

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for details.

---

<p align="center">
  <a href="#top">Back to top ↑</a>
</p>

