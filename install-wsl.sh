#!/usr/bin/env bash
set -euo pipefail

# --- Config -------------------------------------------------------------------

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-common.sh
source "$DOTFILES_DIR/install-common.sh"

APT_PKGS=(
  zsh
  curl
  ca-certificates
  build-essential
  pkg-config
  libssl-dev
  ripgrep
  fd-find
  ffmpeg
  p7zip-full
  jq
  bat
  htop
  fzf
  zoxide
  imagemagick
  git
)

APT_PKGS_OPTIONAL=(
  eza
  yazi
  git-delta
  ncspot
  vivid
)

LINKS=()
add_zsh_link
add_common_cli_links

ensure_rust_toolchain() {
  if have cargo; then
    return
  fi

  echo "==> Installing Rust toolchain (rustup)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

ensure_starship() {
  if have starship; then
    return
  fi

  if apt-cache show starship >/dev/null 2>&1; then
    echo "==> Installing starship from apt..."
    sudo apt-get install -y starship
  else
    echo "==> Installing starship with cargo..."
    cargo install --locked starship
  fi
}

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

echo "==> Installing apt packages..."
install_apt "${APT_PKGS[@]}" "${APT_PKGS_OPTIONAL[@]}"

echo "==> Installing Rust and cargo tools..."
ensure_rust_toolchain
# shellcheck disable=SC1091
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

ensure_shell_shims
ensure_starship
ensure_helix

echo "==> Creating WSL config symlinks..."
link_pairs "${LINKS[@]}"

copy_gitconfig

if [[ "$(prompt_yes_no "Set zsh as default shell?")" == "yes" ]]; then
  chsh -s "$(command -v zsh)" || echo ">> Could not change default shell automatically."
fi

echo "==> Done."
