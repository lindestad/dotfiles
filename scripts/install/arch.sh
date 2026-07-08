#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/install/common.sh
source "$DOTFILES_DIR/scripts/install/common.sh"

parse_install_flags "$@"
ensure_not_root

PACMAN_PKGS=(
  zsh
  zsh-syntax-highlighting
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
  7zip
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
  grim
  slurp
  swayidle
  wl-clipboard
  power-profiles-daemon
  upower
  wlsunset
)

NIRI_AUR_PKGS=()

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
  if pacman -Si noctalia-shell >/dev/null 2>&1; then
    install_pacman noctalia-shell
  else
    NIRI_AUR_PKGS+=(noctalia-shell)
  fi
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

ensure_carapace_release
if [[ "$INSTALL_NIRI" == "yes" ]] && ((${#NIRI_AUR_PKGS[@]})); then
  echo "==> Installing Niri + Noctalia AUR packages (if helper found)..."
  install_aur "${NIRI_AUR_PKGS[@]}"
fi
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  ensure_nirimod
fi

KANATA_CONFIG_SRC=""
if [[ "$INSTALL_KANATA" == "yes" ]]; then
  if have kanata; then
    echo "== Kanata already installed: $(command -v kanata)"
  else
    if ! ensure_kanata_cargo; then
      echo ">> Could not install Kanata with cargo; falling back to AUR (if helper found)..."
      install_aur kanata || true
    fi
    if ! have kanata; then
      echo "!! Kanata is still not installed after Cargo/AUR attempts."
      exit 1
    fi
  fi
  choose_kanata_config
  if [[ -n "$KANATA_CONFIG_SRC" ]]; then
    link_kanata_config "$KANATA_CONFIG_SRC"
  fi
  setup_kanata_startup
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
install_dotfiles_helpers
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  install_niri_helpers
fi
copy_gitconfig
ensure_codex_config
ensure_zsh_default_shell

if [[ "$INSTALL_NIRI" == "yes" ]]; then
  run_sensors_detect
fi

ensure_uv_tools ty ruff

echo "==> Done."
