#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-common.sh
source "$DOTFILES_DIR/install-common.sh"

PACMAN_PKGS=(
  zsh
  helix
  starship
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
  lm_sensors
  brightnessctl
  cliphist
  bluez
  bluez-utils
  network-manager-applet
  pavucontrol
  vivid
)

AUR_PKGS=(
  carapace-bin
)

LINKS=()
add_common_cli_links
add_zsh_link
add_wayland_desktop_links

if is_wsl; then
  echo "!! WSL detected. Use ./install-wsl.sh for WSL installs."
  exit 1
fi

if ! have pacman; then
  echo "!! pacman is required for the Arch installer."
  exit 1
fi

echo "==> Installing pacman packages..."
install_pacman "${PACMAN_PKGS[@]}"

if ((${#AUR_PKGS[@]})); then
  echo "==> Installing AUR packages (if helper found)..."
  install_aur "${AUR_PKGS[@]}"
fi

KANATA_INSTALL="$(prompt_yes_no "Install Kanata (Keyboard remapping)?")"
KANATA_CONFIG_SRC=""
if [[ "$KANATA_INSTALL" == "yes" ]]; then
  echo "==> Installing Kanata from AUR (if helper found)..."
  install_aur kanata || true
  choose_kanata_config
fi

echo "==> Creating config symlinks..."
link_pairs "${LINKS[@]}"
ensure_local_bin
copy_gitconfig

if [[ "$KANATA_INSTALL" == "yes" ]]; then
  if [[ -n "$KANATA_CONFIG_SRC" ]]; then
    link_kanata_config "$KANATA_CONFIG_SRC"
  fi

  system_prompt="Enable Kanata system-wide (pre-login; copies config to /etc, rerun script after changes)?"
  if [[ "$(prompt_yes_no "$system_prompt")" == "yes" ]]; then
    KANATA_ENABLE_SYSTEM=yes KANATA_ENABLE_USER=no \
      bash "$DOTFILES_DIR/config/kanata/add_to_startup_arch.sh"
  else
    user_prompt="Enable Kanata for this user (starts after login)?"
    if [[ "$(prompt_yes_no "$user_prompt")" == "yes" ]]; then
      KANATA_ENABLE_SYSTEM=no KANATA_ENABLE_USER=yes \
        bash "$DOTFILES_DIR/config/kanata/add_to_startup_arch.sh"
    else
      KANATA_ENABLE_SYSTEM=no KANATA_ENABLE_USER=no \
        bash "$DOTFILES_DIR/config/kanata/add_to_startup_arch.sh"
    fi
  fi
fi

run_sensors_detect

echo "==> Done."
