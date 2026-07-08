#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/install/common.sh
source "$DOTFILES_DIR/scripts/install/common.sh"

parse_install_flags "$@"
ensure_not_root

APT_PKGS_COMMON=(
  zsh
  curl
  unzip
  ca-certificates
  build-essential
  cmake
  pkg-config
  libssl-dev
  fontconfig
  gpg
  ripgrep
  fd-find
  du-dust
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
  gh
  shellcheck
  shfmt
  direnv
  hyperfine
  python3
  python3.12
  python3.12-venv
  pipx
)

NIRI_APT_PKGS=(
  niri
  fuzzel
  grim
  slurp
  swayidle
  wl-clipboard
  cliphist
  lm-sensors
  brightnessctl
  bluez
  network-manager-gnome
  pavucontrol
  power-profiles-daemon
  upower
  wlsunset
  xdg-desktop-portal
)

APT_PKGS_OPTIONAL=(
  helix
  eza
  yazi
  git-delta
  uutils-coreutils
  vivid
  cliphist
  carapace
  just
  watchexec
  atuin
  sd
  xh
  procs
  broot
  lazygit
  gitui
)

LINKS=()
add_common_cli_links
add_bash_link
add_zsh_link

if is_wsl; then
  echo "!! WSL detected. Use ./install.sh for WSL installs."
  exit 1
fi

if ! have apt-get; then
  echo "!! apt-get is required for the Ubuntu installer."
  exit 1
fi

resolve_install_flags yes yes
add_alacritty_link
add_wezterm_link
add_ghostty_link
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  add_wayland_desktop_links
fi

ensure_wezterm_ubuntu() {
  if have wezterm; then
    return
  fi

  if apt-cache show wezterm >/dev/null 2>&1; then
    install_apt wezterm
    return
  fi

  echo ">> WezTerm is not available from the configured Ubuntu apt repositories."
  if [[ "$ASSUME_YES" == "yes" ]]; then
    echo ">> Skipping WezTerm APT repo setup in non-interactive mode."
    return
  fi
  if [[ "$(prompt_yes_no "Install WezTerm from the official apt.fury.io APT repo?")" != "yes" ]]; then
    return
  fi
  if ! have curl; then
    echo "!! curl is required to install WezTerm from the official APT repo."
    return 1
  fi
  if ! have gpg; then
    echo "==> Installing gpg for WezTerm APT repo setup..."
    install_apt gpg
  fi

  echo "==> Adding WezTerm APT repo..."
  local key_file
  key_file="$(mktemp)"
  curl -fsSL https://apt.fury.io/wez/gpg.key -o "$key_file"
  sudo install -d -m 0755 /etc/apt/keyrings
  sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg "$key_file"
  rm -f "$key_file"
  echo "deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *" \
    | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null

  echo "==> Installing WezTerm..."
  install_apt wezterm
}

ensure_ghostty_ubuntu() {
  if have ghostty; then
    return
  fi

  if apt-cache show ghostty >/dev/null 2>&1; then
    install_apt ghostty
    return
  fi

  echo ">> Ghostty is not available from the configured Ubuntu apt repositories."
  if [[ "$ASSUME_YES" == "yes" ]]; then
    echo ">> Skipping community ghostty-ubuntu installer in non-interactive mode."
    return
  fi
  if [[ "$(prompt_yes_no "Install Ghostty from the community ghostty-ubuntu .deb installer?")" != "yes" ]]; then
    return
  fi
  if ! have curl; then
    echo "!! curl is required to install Ghostty from ghostty-ubuntu."
    return 1
  fi

  echo "==> Installing Ghostty from ghostty-ubuntu..."
  local installer release_tag installer_url
  release_tag="$(github_latest_release_tag "mkasberg/ghostty-ubuntu" || true)"
  if [[ -z "$release_tag" ]]; then
    echo "!! Could not resolve latest ghostty-ubuntu release tag."
    return 1
  fi
  case "$release_tag" in
    *[!A-Za-z0-9._-]*)
      echo "!! Refusing unexpected ghostty-ubuntu release tag: $release_tag"
      return 1
      ;;
  esac

  installer_url="https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/${release_tag}/install.sh"
  installer="$(mktemp)"
  curl -fsSL "$installer_url" -o "$installer"
  bash "$installer"
  rm -f "$installer"
}

echo "==> Installing apt packages..."
install_apt "${APT_PKGS_COMMON[@]}" "${APT_PKGS_OPTIONAL[@]}"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  echo "==> Installing Niri + Noctalia desktop packages..."
  install_apt "${NIRI_APT_PKGS[@]}"
  ensure_noctalia_ubuntu
  ensure_nirimod
fi
ensure_wezterm_ubuntu
ensure_ghostty_ubuntu
ensure_shell_shims
ensure_neovim_release || install_apt neovim
ensure_rust_toolchain
ensure_starship
ensure_zellij_cargo
ensure_typst_cli
ensure_shfmt_release
ensure_yq_mikefarah
ensure_lazygit_release
ensure_carapace_release
ensure_modern_cli_cargo_tools
ensure_tealdeer
ensure_resvg_cargo
ensure_dust_cargo
ensure_node_lts
install_fonts

KANATA_CONFIG_SRC=""
if [[ "$INSTALL_KANATA" == "yes" ]]; then
  echo ">> Kanata auto-install is not configured for Ubuntu. Install Kanata manually if needed."
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
install_dotfiles_helpers
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  install_niri_helpers
fi
copy_gitconfig
ensure_codex_config
ensure_zsh_default_shell

if [[ "$INSTALL_KANATA" == "yes" && -n "$KANATA_CONFIG_SRC" ]]; then
  link_kanata_config "$KANATA_CONFIG_SRC"
  echo ">> Skipping Kanata service setup on Ubuntu."
fi

if [[ "$INSTALL_NIRI" == "yes" ]]; then
  run_sensors_detect
fi

ensure_uv_tools ty ruff

echo "==> Done."
