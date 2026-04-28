#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-common.sh
source "$DOTFILES_DIR/install-common.sh"

parse_install_flags "$@"
ensure_not_root

PACMAN_PKGS=(
  zsh
  curl
  unzip
  fontconfig
  helix
  eza
  ripgrep
  fd
  ffmpeg
  p7zip
  jq
  bat
  htop
  fzf
  zoxide
  imagemagick
  yazi
  git
  git-delta
  uutils-coreutils
  ncspot
  vivid
)

NIRI_PACMAN_PKGS=(
  lm_sensors
  brightnessctl
  cliphist
  bluez
  bluez-utils
  network-manager-applet
  pavucontrol
  niri
  waybar
  fuzzel
  swayidle
  swaylock
  wl-clipboard
)

AUR_PKGS=(
  carapace-bin
)

LINKS=()
add_common_cli_links
add_zsh_link

if is_wsl; then
  echo "!! WSL detected. Use ./install-wsl.sh for WSL installs."
  exit 1
fi

if ! have pacman; then
  echo "!! pacman is required for the Arch installer."
  exit 1
fi

resolve_install_flags yes yes
add_alacritty_link
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  add_wayland_desktop_links
fi

echo "==> Installing pacman packages..."
install_pacman "${PACMAN_PKGS[@]}"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  echo "==> Installing Niri desktop packages..."
  install_pacman "${NIRI_PACMAN_PKGS[@]}"
fi
ensure_rust_toolchain
ensure_starship
ensure_node_lts
install_fonts

if ((${#AUR_PKGS[@]})); then
  echo "==> Installing AUR packages (if helper found)..."
  install_aur "${AUR_PKGS[@]}"
fi

KANATA_CONFIG_SRC=""
if [[ "$INSTALL_KANATA" == "yes" ]]; then
  echo "==> Installing Kanata from AUR (if helper found)..."
  install_aur kanata || true
  choose_kanata_config
fi

echo "==> Creating config symlinks..."
link_pairs "${LINKS[@]}"
ensure_local_bin
copy_gitconfig
ensure_zsh_default_shell

if [[ "$INSTALL_KANATA" == "yes" ]]; then
  if [[ -n "$KANATA_CONFIG_SRC" ]]; then
    link_kanata_config "$KANATA_CONFIG_SRC"
  fi

  setup_kanata_startup
fi

if [[ "$INSTALL_NIRI" == "yes" ]]; then
  run_sensors_detect
fi

echo "==> Done."
