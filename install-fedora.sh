#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-common.sh
source "$DOTFILES_DIR/install-common.sh"

parse_install_flags "$@"
ensure_not_root

DNF_PKGS=(
  zsh
  curl
  unzip
  fontconfig
  helix
  eza
  ripgrep
  fd-find
  ffmpeg-free
  p7zip
  p7zip-plugins
  jq
  bat
  htop
  btop
  fzf
  zoxide
  ImageMagick
  git
  git-delta
  uv
)

NIRI_DNF_PKGS=(
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
  swayidle
  swaylock
  wl-clipboard
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

if is_wsl; then
  echo "!! WSL detected. Use ./install-wsl.sh for WSL installs."
  exit 1
fi

if ! have dnf; then
  echo "!! dnf is required for the Fedora installer."
  exit 1
fi

resolve_install_flags yes yes
add_alacritty_link
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  add_wayland_desktop_links
fi

echo "==> Installing dnf packages..."
install_dnf "${DNF_PKGS[@]}" "${DNF_PKGS_OPTIONAL[@]}"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  echo "==> Installing Niri desktop packages..."
  install_dnf "${NIRI_DNF_PKGS[@]}"
fi
ensure_rust_toolchain
ensure_starship
ensure_bottom
ensure_node_lts
ensure_uv
install_fonts

echo "==> Creating config symlinks..."
link_pairs "${LINKS[@]}"
ensure_local_bin
copy_gitconfig
ensure_zsh_default_shell

KANATA_CONFIG_SRC=""
if [[ "$INSTALL_KANATA" == "yes" ]]; then
  ensure_kanata_cargo
  choose_kanata_config
fi

if [[ "$INSTALL_KANATA" == "yes" && -n "$KANATA_CONFIG_SRC" ]]; then
  link_kanata_config "$KANATA_CONFIG_SRC"
  setup_kanata_startup
fi

if [[ "$INSTALL_NIRI" == "yes" ]]; then
  run_sensors_detect
fi

echo "==> Done."
