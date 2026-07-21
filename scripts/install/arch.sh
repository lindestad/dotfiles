#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/install/common.sh
source "$DOTFILES_DIR/scripts/install/common.sh"

parse_install_flags "$@"
ensure_not_root
start_install_log

PACMAN_PKGS=(
  fish
  zsh
  bc
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
  tokei
  python
  python-pipx
  typst
  uv
)

NIRI_PACMAN_PKGS=(
  lm_sensors
  brightnessctl
  flatpak
  cliphist
  bluez
  bluez-utils
  network-manager-applet
  pavucontrol
  qalculate-qt
  loupe
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
add_fish_link

if is_wsl; then
  echo "!! WSL detected. Use ./install.sh for WSL installs."
  exit 1
fi

if ! have pacman; then
  echo "!! pacman is required for the Arch installer."
  exit 1
fi

show_install_intro
collect_install_choices yes yes
add_alacritty_link
add_wezterm_link
add_ghostty_link
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  add_wayland_desktop_links
fi

show_install_plan
request_sudo_access
install_progress 1 5 "System packages"
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

install_progress 2 5 "Command-line tools"
ensure_rust_toolchain
ensure_zsh_patina
ensure_starship
ensure_shfmt_release
ensure_taplo_release
ensure_powershell_linting
ensure_yq_mikefarah
ensure_lazygit_release
ensure_modern_cli_cargo_tools
ensure_tealdeer
ensure_resvg_cargo
ensure_dust_cargo
ensure_node_lts
install_fonts

install_progress 3 5 "Optional components"
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

install_progress 4 5 "Managed configuration"
echo "==> Creating config symlinks..."
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  prepare_niri_config_dir
fi
link_pairs "${LINKS[@]}"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  validate_migrated_niri_local_config
  activate_niri_usno_layout
  ensure_niri_zvim
fi
ensure_broot_launcher
ensure_local_bin
install_dotfiles_helpers
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  install_niri_helpers
  ensure_zen_browser
  install_zen_browser_url_handler
  apply_zen_browser_preferences
fi

install_progress 5 5 "Finishing setup"
copy_gitconfig
ensure_codex_config
ensure_fish_default_shell

if [[ "$INSTALL_NIRI" == "yes" ]]; then
  run_sensors_detect
fi

ensure_uv_tools ty ruff

echo "==> Installation complete"
