#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "[*] Creating symlinks from $DOTFILES_DIR to $CONFIG_DIR and home..."

mkdir -p "$CONFIG_DIR"
mkdir -p "$HOME"

# Symlinks
ln -sf "$DOTFILES_DIR/config/helix"               "$CONFIG_DIR/helix"
ln -sf "$DOTFILES_DIR/config/yazi"                "$CONFIG_DIR/yazi"
ln -sf "$DOTFILES_DIR/config/starship/zsh/starship.toml" "$CONFIG_DIR/starship.toml"

mkdir -p "$CONFIG_DIR/nushell"
ln -sf "$DOTFILES_DIR/shells/config.nu"           "$CONFIG_DIR/nushell/config.nu"

ln -sf "$DOTFILES_DIR/shells/.zshrc"              "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/shells/.bashrc"             "$HOME/.bashrc"

echo "[✓] Symlinks created successfully."
