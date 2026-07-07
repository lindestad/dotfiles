#!/usr/bin/env bash
set -euo pipefail

# --- Config -------------------------------------------------------------------

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/install/common.sh
source "$DOTFILES_DIR/scripts/install/common.sh"

parse_install_flags "$@"
ensure_not_root

APT_PKGS=(
  zsh
  curl
  unzip
  ca-certificates
  fontconfig
  build-essential
  cmake
  pkg-config
  libssl-dev
  ripgrep
  fd-find
  du-dust
  file
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

APT_PKGS_OPTIONAL=(
  eza
  carapace
  yazi
  git-delta
  vivid
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
add_zsh_link
add_common_cli_links

ensure_helix() {
  if have hx; then
    return
  fi

  local machine deb_arch
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) deb_arch="amd64" ;;
    aarch64|arm64) deb_arch="arm64" ;;
    *) deb_arch="" ;;
  esac

  if [[ -n "$deb_arch" ]] && have curl && have jq; then
    local api_url release_json asset_url deb_file
    api_url="https://api.github.com/repos/helix-editor/helix/releases/latest"

    echo "==> Resolving latest Helix release artifact for $deb_arch..."
    release_json="$(curl -fsSL "$api_url")"
    asset_url="$(printf '%s\n' "$release_json" | jq -r --arg arch "$deb_arch" \
      '.assets[] | select(.name | test("^helix_.*_" + $arch + "\\.deb$")) | .browser_download_url' | head -n1)"

    if [[ -n "$asset_url" && "$asset_url" != "null" ]]; then
      deb_file="$(mktemp /tmp/helix.XXXXXX.deb)"
      echo "==> Installing Helix from release: $asset_url"
      curl -fL "$asset_url" -o "$deb_file"
      sudo apt-get install -y "$deb_file"
      rm -f "$deb_file"
      return
    fi
  fi

  echo ">> Could not resolve Helix release .deb automatically."
  if apt-cache show helix >/dev/null 2>&1; then
    echo "==> Falling back to apt helix package..."
    sudo apt-get install -y helix
    return
  fi

  echo "!! Helix install failed. Install manually from https://github.com/helix-editor/helix/releases and rerun."
  exit 1
}

# --- Run ----------------------------------------------------------------------

if ! is_wsl; then
  echo "!! This installer is for WSL only. Use ./install.sh for non-WSL Linux."
  exit 1
fi

if ! have apt-get; then
  echo "!! apt-get is required for WSL installer."
  exit 1
fi

resolve_install_flags no no

echo "==> Installing apt packages..."
install_apt "${APT_PKGS[@]}" "${APT_PKGS_OPTIONAL[@]}"

echo "==> Installing Rust and cargo tools..."
ensure_rust_toolchain

ensure_local_bin
ensure_shell_shims
ensure_neovim_release || install_apt neovim
ensure_starship
ensure_bottom
ensure_yazi_cargo
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
ensure_zellij_cargo
ensure_helix
ensure_vivid_cargo
install_fonts

echo "==> Creating WSL config symlinks..."
link_pairs "${LINKS[@]}"
ensure_broot_launcher

copy_gitconfig
ensure_codex_config

ensure_zsh_default_shell

ensure_uv_tools ty ruff

echo "==> Done."
