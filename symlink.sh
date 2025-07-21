#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
ln -sf "$DOTFILES_DIR/config/helix" "$HOME/.config/helix"
ln -sf "$DOTFILES_DIR/config/yazi" "$HOME/.config/yazi"

ln -sf "$DOTFILES_DIR/shells/config.nu" "$HOME/.config/nushell/config.nu"
ln -sf "$DOTFILES_DIR/shells/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/shells/.bashrc" "$HOME/.bashrc"