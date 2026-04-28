#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-common.sh
source "$DOTFILES_DIR/install-common.sh"

DNF_PKGS=(
  zsh
  helix
  starship
  eza
  ripgrep
  fd-find
  ffmpeg-free
  p7zip
  p7zip-plugins
  jq
  bat
  htop
  fzf
  zoxide
  ImageMagick
  git
  git-delta
  lm_sensors
  brightnessctl
  cliphist
  bluez
  bluez-tools
  NetworkManager-applet
  pavucontrol
  niri
  waybar
  fuzzel
)

DNF_PKGS_OPTIONAL=(
  yazi
  uutils-coreutils
  ncspot
  vivid
  carapace
)

LINKS=()
add_common_cli_links
add_zsh_link
add_wayland_desktop_links

if is_wsl; then
  echo "!! WSL detected. Use ./install-wsl.sh for WSL installs."
  exit 1
fi

if ! have dnf; then
  echo "!! dnf is required for the Fedora installer."
  exit 1
fi

echo "==> Installing dnf packages..."
install_dnf "${DNF_PKGS[@]}" "${DNF_PKGS_OPTIONAL[@]}"

KANATA_INSTALL="$(prompt_yes_no "Install Kanata (Keyboard remapping)?")"
KANATA_CONFIG_SRC=""
if [[ "$KANATA_INSTALL" == "yes" ]]; then
  echo ">> Kanata auto-install is not configured for Fedora. Install Kanata manually if needed."
  choose_kanata_config
fi

echo "==> Creating config symlinks..."
link_pairs "${LINKS[@]}"
ensure_local_bin
copy_gitconfig

if [[ "$KANATA_INSTALL" == "yes" && -n "$KANATA_CONFIG_SRC" ]]; then
  link_kanata_config "$KANATA_CONFIG_SRC"
  echo ">> Skipping Kanata service setup on Fedora."
fi

run_sensors_detect

echo "==> Done."
