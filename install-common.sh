#!/usr/bin/env bash
# Shared helpers for Linux/WSL install scripts. Source this file; do not run it.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! install-common.sh is a helper; run a distro installer instead."
  exit 1
fi

: "${DOTFILES_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

have() { command -v "$1" >/dev/null 2>&1; }

INSTALL_NIRI=""
INSTALL_KANATA=""
ASSUME_YES="no"

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

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --niri        Install the Niri desktop stack (niri, waybar, fuzzel, swaylock)
  --no-niri     Skip the Niri desktop stack
  --kanata      Install/link Kanata keyboard remapping config
  --no-kanata   Skip Kanata
  -y, --yes     Use non-interactive defaults for unspecified options
  -h, --help    Show this help
EOF
}

parse_install_flags() {
  while (($#)); do
    case "$1" in
      --niri) INSTALL_NIRI="yes" ;;
      --no-niri) INSTALL_NIRI="no" ;;
      --kanata) INSTALL_KANATA="yes" ;;
      --no-kanata) INSTALL_KANATA="no" ;;
      -y|--yes) ASSUME_YES="yes" ;;
      -h|--help) usage; exit 0 ;;
      *)
        echo "!! Unknown option: $1"
        usage
        exit 2
        ;;
    esac
    shift
  done
}

resolve_install_flags() {
  local support_niri="${1:-yes}"
  local support_kanata="${2:-yes}"

  if [[ "$support_niri" == "no" ]]; then
    if [[ "$INSTALL_NIRI" == "yes" ]]; then
      echo ">> Niri desktop stack is not supported by this installer; skipping."
    fi
    INSTALL_NIRI="no"
  elif [[ -z "$INSTALL_NIRI" ]]; then
    if [[ "$ASSUME_YES" == "yes" ]]; then
      INSTALL_NIRI="no"
    elif [[ "$(prompt_yes_no "Install Niri desktop stack (niri/waybar/fuzzel/swaylock)?")" == "yes" ]]; then
      INSTALL_NIRI="yes"
    else
      INSTALL_NIRI="no"
    fi
  fi

  if [[ "$support_kanata" == "no" ]]; then
    if [[ "$INSTALL_KANATA" == "yes" ]]; then
      echo ">> Kanata is not supported by this installer; skipping."
    fi
    INSTALL_KANATA="no"
  elif [[ -z "$INSTALL_KANATA" ]]; then
    if [[ "$ASSUME_YES" == "yes" ]]; then
      INSTALL_KANATA="no"
    elif [[ "$(prompt_yes_no "Install Kanata (keyboard remapping)?")" == "yes" ]]; then
      INSTALL_KANATA="yes"
    else
      INSTALL_KANATA="no"
    fi
  fi

  echo "==> Optional components: niri=$INSTALL_NIRI, kanata=$INSTALL_KANATA"
  if [[ "$support_niri" != "no" && "$INSTALL_NIRI" == "no" ]]; then
    echo ">> Skipping Niri desktop stack. Re-run with --niri to install niri/waybar/fuzzel/swaylock."
  fi
  if [[ "$support_kanata" != "no" && "$INSTALL_KANATA" == "no" ]]; then
    echo ">> Skipping Kanata. Re-run with --kanata to install/link keyboard remapping config."
  fi
}

install_flag_args() {
  [[ "$INSTALL_NIRI" == "yes" ]] && printf '%s\n' "--niri" || printf '%s\n' "--no-niri"
  [[ "$INSTALL_KANATA" == "yes" ]] && printf '%s\n' "--kanata" || printf '%s\n' "--no-kanata"
  [[ "$ASSUME_YES" == "yes" ]] && printf '%s\n' "--yes"
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

add_alacritty_link() {
  LINKS+=("$DOTFILES_DIR/config/alacritty/alacritty.toml|$HOME/.config/alacritty/alacritty.toml")
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

install_fonts() {
  local src_dir="$DOTFILES_DIR/fonts"
  local dst_dir="$HOME/.local/share/fonts"
  local font

  if [[ ! -d "$src_dir" ]]; then
    echo ">> Font directory not found: $src_dir"
    return
  fi

  echo "==> Installing user fonts..."
  mkdir -p "$dst_dir"
  for font in "$src_dir"/*.ttf; do
    [[ -e "$font" ]] || continue
    cp -f "$font" "$dst_dir/"
    echo "-> Installed $(basename "$font")"
  done

  if have fc-cache; then
    fc-cache -f "$dst_dir"
  else
    echo ">> fc-cache not found; restart apps after installing fontconfig."
  fi
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
