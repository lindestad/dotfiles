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
  wget
  unzip
  gcc
  gcc-c++
  make
  cmake
  perl-FindBin
  perl-IPC-Cmd
  perl-Time-Piece
  pkgconf-pkg-config
  openssl-devel
  fontconfig
  alacritty
  chromium
  chromium-headless
  chromedriver
  xorg-x11-server-Xvfb
  helix
  eza
  du-dust
  file
  ripgrep
  fd-find
  ffmpeg-free
  7zip
  jq
  yq
  bat
  neovim
  htop
  btop
  fzf
  zoxide
  ImageMagick
  grim
  slurp
  wl-clipboard
  xclip
  xdotool
  wtype
  git
  git-lfs
  gh
  git-delta
  ShellCheck
  shfmt
  tree
  entr
  direnv
  just
  hyperfine
  atuin
  procs
  lazygit
  gitui
  tokei
  httpie
  lsof
  strace
  gdb
  procps-ng
  psmisc
  nmap-ncat
  bind-utils
  sqlite
  sqlite-devel
  postgresql
  postgresql-devel
  podman
  podman-compose
  buildah
  python3.12
  python3-virtualenv
  python3-pytest
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

ensure_ghostty_fedora() {
  if have ghostty; then
    return
  fi

  echo "==> Installing Ghostty from configured Fedora repositories if available..."
  install_dnf ghostty
  if have ghostty; then
    return
  fi

  echo ">> Ghostty is not available from the configured Fedora repositories."
  if [[ "$ASSUME_YES" == "yes" ]]; then
    echo ">> Skipping Ghostty COPR setup in non-interactive mode."
    return
  fi
  if [[ "$(prompt_yes_no "Install Ghostty from the scottames/ghostty COPR?")" != "yes" ]]; then
    return
  fi

  if ! dnf copr --help >/dev/null 2>&1; then
    echo "==> Installing dnf COPR plugin..."
    sudo dnf install -y dnf-plugins-core
  fi

  echo "==> Enabling scottames/ghostty COPR..."
  sudo dnf copr enable -y scottames/ghostty
  echo "==> Installing Ghostty..."
  sudo dnf install -y ghostty
}

ensure_wezterm_fedora() {
  if have wezterm; then
    return
  fi

  echo "==> Installing WezTerm from configured Fedora repositories if available..."
  install_dnf wezterm
  if have wezterm; then
    return
  fi

  echo ">> WezTerm is not available from the configured Fedora repositories."
  if [[ "$ASSUME_YES" == "yes" ]]; then
    echo ">> Skipping WezTerm COPR setup in non-interactive mode."
    return
  fi
  if [[ "$(prompt_yes_no "Install WezTerm from the official wezfurlong/wezterm-nightly COPR?")" != "yes" ]]; then
    return
  fi

  if ! dnf copr --help >/dev/null 2>&1; then
    echo "==> Installing dnf COPR plugin..."
    sudo dnf install -y dnf-plugins-core
  fi

  echo "==> Enabling wezfurlong/wezterm-nightly COPR..."
  sudo dnf copr enable -y wezfurlong/wezterm-nightly
  echo "==> Installing WezTerm..."
  sudo dnf install -y wezterm
}

ensure_zellij_fedora() {
  if have zellij; then
    zellij --version
    return
  fi

  if ! dnf copr --help >/dev/null 2>&1; then
    echo "==> Installing dnf COPR plugin..."
    if ! sudo dnf install -y dnf-plugins-core; then
      echo ">> Could not install dnf COPR plugin; falling back to cargo."
      ensure_zellij_cargo
      zellij --version
      return
    fi
  fi

  echo "==> Enabling varlad/zellij COPR..."
  if sudo dnf copr enable -y varlad/zellij; then
    echo "==> Installing Zellij..."
    if sudo dnf install -y zellij && have zellij; then
      zellij --version
      return
    fi
  fi

  echo ">> Could not install Zellij with dnf; falling back to cargo."
  ensure_zellij_cargo
  zellij --version
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
add_wezterm_link
add_ghostty_link
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  add_wayland_desktop_links
fi

echo "==> Installing dnf packages..."
install_dnf "${DNF_PKGS[@]}" "${DNF_PKGS_OPTIONAL[@]}"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  echo "==> Installing Niri desktop packages..."
  install_dnf "${NIRI_DNF_PKGS[@]}"
fi
ensure_wezterm_fedora
ensure_ghostty_fedora
ensure_rust_toolchain
ensure_starship
ensure_bottom
ensure_typst_cli
ensure_shfmt_release
ensure_yq_mikefarah
ensure_lazygit_release
ensure_carapace_release
ensure_modern_cli_cargo_tools
ensure_resvg_cargo
ensure_dust_cargo
ensure_yazi_cargo
ensure_vivid_cargo
ensure_zellij_fedora
ensure_node_lts
install_fonts

echo "==> Creating config symlinks..."
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  prepare_niri_config_dir
fi
link_pairs "${LINKS[@]}"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  validate_migrated_niri_local_config
fi
ensure_broot_launcher
ensure_local_bin
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  install_niri_helpers
fi
copy_gitconfig
ensure_codex_config
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

ensure_uv_tools ty ruff

echo "==> Done."
