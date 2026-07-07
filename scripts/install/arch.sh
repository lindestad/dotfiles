#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/install/common.sh
source "$DOTFILES_DIR/scripts/install/common.sh"

parse_install_flags "$@"
ensure_not_root

PACMAN_PKGS=(
  zsh
  curl
  unzip
  fontconfig
  wezterm
  ghostty
  helix
  eza
  dust
  ripgrep
  fd
  ffmpeg
  p7zip
  jq
  bat
  neovim
  htop
  btop
  bottom
  fzf
  zoxide
  imagemagick
  yazi
  git
  github-cli
  git-delta
  shellcheck
  shfmt
  uutils-coreutils
  vivid
  zellij
  direnv
  just
  yq
  hyperfine
  watchexec
  atuin
  sd
  xh
  procs
  broot
  lazygit
  gitui
  python
  python-pipx
  typst
  uv
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
  fuzzel
  swayidle
  wl-clipboard
  power-profiles-daemon
  upower
  wlsunset
)

AUR_PKGS=(
  carapace-bin
)

NIRI_AUR_PKGS=(
  noctalia-shell
)

LINKS=()
add_common_cli_links
add_zsh_link

if is_wsl; then
  echo "!! WSL detected. Use ./install.sh for WSL installs."
  exit 1
fi

if ! have pacman; then
  echo "!! pacman is required for the Arch installer."
  exit 1
fi

resolve_install_flags yes yes
add_alacritty_link
add_wezterm_link
add_ghostty_link
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  add_wayland_desktop_links
fi

echo "==> Installing pacman packages..."
install_pacman "${PACMAN_PKGS[@]}"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  echo "==> Installing Niri + Noctalia desktop packages..."
  install_pacman "${NIRI_PACMAN_PKGS[@]}"
fi
ensure_rust_toolchain
ensure_starship
ensure_shfmt_release
ensure_yq_mikefarah
ensure_lazygit_release
ensure_modern_cli_cargo_tools
ensure_tealdeer
ensure_resvg_cargo
ensure_dust_cargo
ensure_node_lts
install_fonts

if ((${#AUR_PKGS[@]})); then
  echo "==> Installing AUR packages (if helper found)..."
  install_aur "${AUR_PKGS[@]}"
fi
if [[ "$INSTALL_NIRI" == "yes" ]] && ((${#NIRI_AUR_PKGS[@]})); then
  echo "==> Installing Niri + Noctalia AUR packages (if helper found)..."
  install_aur "${NIRI_AUR_PKGS[@]}"
fi
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  ensure_nirimod
fi

KANATA_CONFIG_SRC=""
if [[ "$INSTALL_KANATA" == "yes" ]]; then
  echo "==> Installing Kanata from AUR (if helper found)..."
  install_aur kanata || true
  choose_kanata_config
fi

echo "==> Creating config symlinks..."
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  prepare_niri_config_dir
fi
link_pairs "${LINKS[@]}"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  validate_migrated_niri_local_config
  activate_niri_usno_layout
fi
ensure_broot_launcher
ensure_local_bin
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  install_niri_helpers
fi
copy_gitconfig
ensure_codex_config
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

ensure_uv_tools ty ruff

echo "==> Done."
