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
  gcc
  make
  pkgconf-pkg-config
  openssl-devel
  fontconfig
  alacritty
  helix
  eza
  ripgrep
  fd-find
  ffmpeg-free
  7zip
  jq
  bat
  htop
  btop
  fzf
  zoxide
  ImageMagick
  git
  gh
  git-delta
  ShellCheck
  python3.12
  pipx
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
  uutils-coreutils
)

ensure_carapace_fedora() {
  if have carapace; then
    ensure_carapace_nushell_init
    return
  fi

  echo ">> carapace is not available from Fedora's default repos."
  if [[ "$ASSUME_YES" == "yes" ]]; then
    echo ">> Skipping carapace-bin RPM repo setup in non-interactive mode."
    return
  fi
  if [[ "$(prompt_yes_no "Install carapace-bin from the upstream Gemfury RPM repo?")" != "yes" ]]; then
    return
  fi

  echo "==> Adding carapace-bin Gemfury RPM repo..."
  sudo tee /etc/yum.repos.d/carapace-fury.repo >/dev/null <<'EOF'
[carapace-fury]
name=carapace-bin Gemfury RPM repository
baseurl=https://yum.fury.io/rsteube/
enabled=1
gpgcheck=0
EOF

  echo "==> Installing carapace-bin..."
  sudo dnf makecache -y || true
  sudo dnf install -y carapace-bin
  ensure_carapace_nushell_init
}

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
ensure_typst_cli
ensure_yazi_cargo
ensure_vivid_cargo
ensure_carapace_fedora
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
