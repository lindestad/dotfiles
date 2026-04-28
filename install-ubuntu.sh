#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-common.sh
source "$DOTFILES_DIR/install-common.sh"

parse_install_flags "$@"
ensure_not_root

APT_PKGS_COMMON=(
  zsh
  curl
  unzip
  ca-certificates
  fontconfig
  ripgrep
  fd-find
  ffmpeg
  p7zip-full
  jq
  bat
  htop
  btop
  btm
  fzf
  zoxide
  imagemagick
  git
)

NIRI_APT_PKGS=(
  niri
  waybar
  fuzzel
  swaylock
  swayidle
  wl-clipboard
  cliphist
  lm-sensors
  brightnessctl
  bluez
  network-manager-gnome
  pavucontrol
)

APT_PKGS_OPTIONAL=(
  helix
  eza
  yazi
  git-delta
  uutils-coreutils
  ncspot
  vivid
  cliphist
  carapace
)

LINKS=()
add_common_cli_links
add_bash_link
add_nushell_link
add_zsh_link

if is_wsl; then
  echo "!! WSL detected. Use ./install-wsl.sh for WSL installs."
  exit 1
fi

if ! have apt-get; then
  echo "!! apt-get is required for the Ubuntu installer."
  exit 1
fi

resolve_install_flags yes yes
add_alacritty_link
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  add_wayland_desktop_links
fi

echo "==> Installing apt packages..."
install_apt "${APT_PKGS_COMMON[@]}" "${APT_PKGS_OPTIONAL[@]}"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  echo "==> Installing Niri desktop packages..."
  install_apt "${NIRI_APT_PKGS[@]}"
fi
ensure_shell_shims
ensure_rust_toolchain
ensure_starship
ensure_node_lts
ensure_uv
install_fonts

KANATA_CONFIG_SRC=""
if [[ "$INSTALL_KANATA" == "yes" ]]; then
  echo ">> Kanata auto-install is not configured for Ubuntu. Install Kanata manually if needed."
  choose_kanata_config
fi

echo "==> Creating config symlinks..."
link_pairs "${LINKS[@]}"
ensure_local_bin
copy_gitconfig
ensure_zsh_default_shell

if [[ "$INSTALL_KANATA" == "yes" && -n "$KANATA_CONFIG_SRC" ]]; then
  link_kanata_config "$KANATA_CONFIG_SRC"
  echo ">> Skipping Kanata service setup on Ubuntu."
fi

if [[ "$INSTALL_NIRI" == "yes" ]]; then
  run_sensors_detect
fi

echo "==> Done."
