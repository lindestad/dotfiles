# Dotfiles

This repository contains my personal configuration files for tools I use regularly across Linux and Windows systems. The goal is to maintain a consistent development environment with minimal manual setup.

## Overview

The repository includes configurations for:

* **Helix** (text editor)
* **Starship** (shell prompt)
* **Yazi** (file manager, with custom themes)
* **Ncspot** (Spotify TUI)
* **Zellij** (terminal multiplexer)
* **Nushell** and other shell environments
* Patched **Nerd Fonts** (MesloLGS NF)

## Setup

### Linux / WSL

```bash
git clone https://github.com/lindestad/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/lindestad/dotfiles $HOME\.dotfiles
cd $HOME\.dotfiles
.\install.ps1
```

These scripts install utilities and symlink config files into place. Use `symlink.sh` or `symlink.ps1` directly if you want to skip other setup steps.
