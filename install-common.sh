#!/usr/bin/env bash
# Shared helpers for Linux/WSL install scripts. Source this file; do not run it.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! install-common.sh is a helper; run a distro installer instead."
  exit 1
fi

: "${DOTFILES_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

have() { command -v "$1" >/dev/null 2>&1; }

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null
}

ensure_not_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "!! Do not run this installer with sudo."
    echo "   Run it as your normal user; the script will ask for sudo when needed."
    exit 1
  fi
}

prompt_yes_no() {
  local answer
  while true; do
    read -r -p "$1 y/N " answer || answer=""
    case "${answer}" in
      [Yy]) echo "yes"; return 0 ;;
      ''|[Nn]) echo "no"; return 0 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

add_common_cli_links() {
  LINKS+=(
    "$DOTFILES_DIR/config/helix/config.toml|$HOME/.config/helix/config.toml"
    "$DOTFILES_DIR/config/helix/languages.toml|$HOME/.config/helix/languages.toml"
    "$DOTFILES_DIR/config/starship/zsh/starship.toml|$HOME/.config/starship.toml"
    "$DOTFILES_DIR/config/yazi|$HOME/.config/yazi"
    "$DOTFILES_DIR/config/ncspot/config.toml|$HOME/.config/ncspot/config.toml"
  )
}

add_zsh_link() {
  LINKS+=("$DOTFILES_DIR/shells/.zshrc|$HOME/.zshrc")
}

add_bash_link() {
  LINKS+=("$DOTFILES_DIR/shells/.bashrc|$HOME/.bashrc")
}

add_nushell_link() {
  LINKS+=("$DOTFILES_DIR/shells/config.nu|$HOME/.config/nushell/config.nu")
}

add_wayland_desktop_links() {
  LINKS+=(
    "$DOTFILES_DIR/config/niri|$HOME/.config/niri"
    "$DOTFILES_DIR/config/waybar|$HOME/.config/waybar"
    "$DOTFILES_DIR/config/fuzzel/fuzzel.ini|$HOME/.config/fuzzel/fuzzel.ini"
  )
}

install_pacman() {
  sudo pacman -Sy --needed --noconfirm "$@"
}

aur_helper() {
  if have yay; then echo yay; return 0; fi
  if have paru; then echo paru; return 0; fi
  return 1
}

install_aur() {
  local helper
  if helper="$(aur_helper)"; then
    "$helper" -S --needed --noconfirm "$@"
  else
    echo ">> No AUR helper (yay/paru) found. Skipping AUR packages: $*"
    echo "   You can install one with: sudo pacman -S --needed base-devel git && (yay|paru)"
  fi
}

install_apt() {
  local pkgs=("$@")
  local available=() missing=()

  sudo apt-get update -y
  for pkg in "${pkgs[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if ((${#available[@]})); then
    sudo apt-get install -y "${available[@]}"
  fi
  if ((${#missing[@]})); then
    echo ">> Skipping unavailable apt packages: ${missing[*]}"
  fi
}

install_dnf() {
  local pkgs=("$@")
  local available=() missing=()

  sudo dnf makecache -y || true
  for pkg in "${pkgs[@]}"; do
    if dnf -q list --installed "$pkg" >/dev/null 2>&1 || dnf -q list --available "$pkg" >/dev/null 2>&1; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if ((${#available[@]})); then
    sudo dnf install -y "${available[@]}"
  fi
  if ((${#missing[@]})); then
    echo ">> Skipping unavailable dnf packages: ${missing[*]}"
  fi
}

load_cargo_env() {
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi
  export PATH="$HOME/.cargo/bin:$PATH"
}

ensure_rust_toolchain() {
  if have cargo; then
    load_cargo_env
    return
  fi

  if ! have curl; then
    echo "!! curl is required to install rustup."
    return 1
  fi

  echo "==> Installing Rust toolchain (rustup)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  load_cargo_env
}

ensure_starship() {
  if have starship; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing starship with cargo..."
  cargo install --locked starship
}

ensure_dirs() {
  local pair _src dst
  for pair in "$@"; do
    IFS='|' read -r _src dst <<<"$pair"
    mkdir -p "$(dirname "$dst")"
  done
}

backup_then_link() {
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then
    echo "!! Missing source: $src (skipping)"
    return
  fi
  if [[ -L "$dst" ]]; then
    local target
    target="$(readlink -f "$dst")" || true
    if [[ "$target" == "$(readlink -f "$src")" ]]; then
      echo "== Already linked: $dst -> $src"
      return
    fi
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    mv -v "$dst" "${dst}.bak.${ts}"
  fi
  ln -s "$src" "$dst"
  echo "-> Linked $src  ->  $dst"
}

link_pairs() {
  local pair src dst
  ensure_dirs "$@"
  for pair in "$@"; do
    IFS='|' read -r src dst <<<"$pair"
    backup_then_link "$src" "$dst"
  done
}

copy_gitconfig() {
  local src="$DOTFILES_DIR/config/git/gitconfig"
  local dst="$HOME/.gitconfig"

  if [[ ! -f "$dst" ]]; then
    if [[ -f "$src" ]]; then
      cp "$src" "$dst"
      echo "-> Copied gitconfig to ~/.gitconfig"
    else
      echo "!! Source gitconfig not found at $src"
    fi
  else
    echo "== ~/.gitconfig exists; leaving as-is."
  fi
}

ensure_zsh_default_shell() {
  if ! have zsh; then
    echo ">> zsh is not installed; leaving default shell unchanged."
    return
  fi

  local zsh_path current_shell
  zsh_path="$(command -v zsh)"
  current_shell="$(getent passwd "$USER" | cut -d: -f7)"

  if [[ "$current_shell" == "$zsh_path" ]]; then
    echo "== zsh is already the default shell."
    return
  fi

  if [[ "$(prompt_yes_no "Set zsh as default shell?")" != "yes" ]]; then
    return
  fi

  if ! grep -qxF "$zsh_path" /etc/shells; then
    echo "==> Adding $zsh_path to /etc/shells..."
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  chsh -s "$zsh_path" "$USER" || sudo chsh -s "$zsh_path" "$USER" || {
    echo ">> Could not change default shell automatically."
    echo "   Run manually: chsh -s $zsh_path"
  }
}

ensure_local_bin() {
  mkdir -p "$HOME/.local/bin"
}

ensure_shell_shims() {
  ensure_local_bin

  # Ubuntu/Debian packages name these binaries differently.
  if ! have fd && have fdfind; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  if ! have bat && have batcat; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  fi
}

choose_kanata_config() {
  local prompt="Remap ISO to ANSI like? Warning, remaps Enter key."
  if [[ "$(prompt_yes_no "$prompt")" == "yes" ]]; then
    KANATA_CONFIG_SRC="$DOTFILES_DIR/config/kanata/config_iso_to_ansi.kbd"
  else
    KANATA_CONFIG_SRC="$DOTFILES_DIR/config/kanata/config.kbd"
  fi
}

link_kanata_config() {
  local config_src="$1"
  mkdir -p "$HOME/.config/kanata"
  backup_then_link "$config_src" "$HOME/.config/kanata/config.kbd"
}

run_sensors_detect() {
  if have sensors-detect; then
    echo "==> Detecting hardware sensors..."
    sudo sensors-detect --auto >/dev/null 2>&1 || echo "   sensors-detect failed; run 'sudo sensors-detect' later if needed."
  fi
}
