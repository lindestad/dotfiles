#!/usr/bin/env bash
set -euo pipefail

# --- Config -------------------------------------------------------------------

# Path to your dotfiles repo (default = where this script lives)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Packages in official repos (installed with pacman)
PACMAN_PKGS=(
  helix            # Helix editor
  starship         # Prompt
  eza              # ls replacement
  ripgrep          # rg
  fd               # fd
  ffmpeg
  p7zip            # 7zip
  jq
  bat
  htop
  fzf
  zoxide
  imagemagick
  yazi
  git
  git-delta
  uutils-coreutils # coreutils (Rust)
  ncspot
  lm_sensors       # for temperature scripts/modules
  brightnessctl    # for backlight in Waybar
  cliphist         # clipboard history used in bar config
  bluez bluez-utils
  network-manager-applet
  pavucontrol
  vivid
)

# Packages for Ubuntu/Debian (installed with apt)
APT_PKGS_COMMON=(
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

APT_PKGS_DESKTOP=(
  lm-sensors
  brightnessctl
  bluez
  network-manager-gnome
  pavucontrol
)

# Nice-to-have packages that may not exist in all Ubuntu repos.
APT_PKGS_OPTIONAL=(
  helix
  starship
  eza
  yazi
  git-delta
  uutils-coreutils
  ncspot
  vivid
  cliphist
  carapace
)

# AUR packages (installed with yay/paru if present)
AUR_PKGS=(
  # kanata is optional; installed based on prompt below
  carapace-bin
)

# Symlinks: "SRC|DST"
# Built dynamically for Linux distro + WSL environment.
LINKS=(
  "$DOTFILES_DIR/config/helix/config.toml|$HOME/.config/helix/config.toml"
  "$DOTFILES_DIR/config/helix/languages.toml|$HOME/.config/helix/languages.toml"
  "$DOTFILES_DIR/config/starship/zsh/starship.toml|$HOME/.config/starship.toml"
  "$DOTFILES_DIR/config/yazi|$HOME/.config/yazi"
  "$DOTFILES_DIR/config/ncspot/config.toml|$HOME/.config/ncspot/config.toml"
)

# --- Helpers ------------------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null
}

is_ubuntu() {
  [[ -f /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "ubuntu" || "${ID_LIKE:-}" == *ubuntu* ]]
}

aur_helper() {
  if have yay; then echo yay; return 0; fi
  if have paru; then echo paru; return 0; fi
  return 1
}

install_pacman() {
  sudo pacman -Sy --needed --noconfirm "$@"
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

install_aur() {
  local helper
  if helper="$(aur_helper)"; then
    "$helper" -S --needed --noconfirm "$@"
  else
    echo ">> No AUR helper (yay/paru) found. Skipping AUR packages: $*"
    echo "   You can install one with: sudo pacman -S --needed base-devel git && (yay|paru)"
  fi
}

ensure_dirs() {
  for pair in "${LINKS[@]}"; do
    IFS='|' read -r SRC DST <<<"$pair"
    mkdir -p "$(dirname "$DST")"
  done
}

backup_then_link() {
  local SRC="$1" DST="$2"
  if [[ ! -e "$SRC" ]]; then
    echo "!! Missing source: $SRC (skipping)"
    return
  fi
  if [[ -L "$DST" ]]; then
    local target
    target="$(readlink -f "$DST")" || true
    if [[ "$target" == "$(readlink -f "$SRC")" ]]; then
      echo "== Already linked: $DST -> $SRC"
      return
    else
      rm -f "$DST"
    fi
  elif [[ -e "$DST" ]]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    mv -v "$DST" "${DST}.bak.${ts}"
  fi
  ln -s "$SRC" "$DST"
  echo "-> Linked $SRC  ->  $DST"
}

prompt_yes_no() {
  # $1 = prompt text, default No
  local answer
  while true; do
    read -r -p "$1 y/N " answer || answer=""
    case "${answer}" in
      [Yy]) echo "yes"; return 0;;
      ''|[Nn]) echo "no"; return 0;;
      *) echo "Please answer y or n.";;
    esac
  done
}

# --- Run ----------------------------------------------------------------------

if is_wsl; then
  echo "!! WSL detected. Use ./install-wsl.sh for WSL installs."
  exit 1
fi

# Add shell + desktop paths based on environment.
if is_ubuntu; then
  LINKS+=(
    "$DOTFILES_DIR/shells/.bashrc|$HOME/.bashrc"
    "$DOTFILES_DIR/shells/config.nu|$HOME/.config/nushell/config.nu"
  )
fi

# Zsh + desktop Wayland config are skipped in WSL.
if ! is_wsl; then
  LINKS+=(
    "$DOTFILES_DIR/shells/.zshrc|$HOME/.zshrc"
    # Kanata config is handled conditionally below; do not link entire dir here
    "$DOTFILES_DIR/config/niri|$HOME/.config/niri"
    "$DOTFILES_DIR/config/waybar|$HOME/.config/waybar"
    "$DOTFILES_DIR/config/fuzzel/fuzzel.ini|$HOME/.config/fuzzel/fuzzel.ini"
  )
fi

if have pacman; then
  echo "==> Installing pacman packages..."
  install_pacman "${PACMAN_PKGS[@]}"

  if ((${#AUR_PKGS[@]})); then
    echo "==> Installing AUR packages (if helper found)..."
    install_aur "${AUR_PKGS[@]}"
  fi
elif have apt-get; then
  echo "==> Installing apt packages..."
  APT_PKGS=("${APT_PKGS_COMMON[@]}" "${APT_PKGS_OPTIONAL[@]}")
  if ! is_wsl; then
    APT_PKGS+=("${APT_PKGS_DESKTOP[@]}")
  fi
  install_apt "${APT_PKGS[@]}"
else
  echo "!! No supported package manager found (expected pacman or apt-get)."
  exit 1
fi

# Kanata optional install + config selection
KANATA_INSTALL="$(prompt_yes_no "Install Kanata (Keyboard remapping)?")"
KANATA_CONFIG_SRC=""
if [[ "$KANATA_INSTALL" == "yes" ]]; then
  if have pacman; then
    echo "==> Installing Kanata from AUR (if helper found)..."
    install_aur kanata || true
  else
    echo ">> Kanata auto-install is currently only configured for Arch/AUR."
    echo "   On Ubuntu/WSL, install Kanata manually if desired."
  fi

  # Choose config variant
  ISO_PROMPT="Remap ISO to ANSI like? Warning, remaps Enter key."
  if [[ "$(prompt_yes_no "$ISO_PROMPT")" == "yes" ]]; then
    KANATA_CONFIG_SRC="$DOTFILES_DIR/config/kanata/config_iso_to_ansi.kbd"
  else
    KANATA_CONFIG_SRC="$DOTFILES_DIR/config/kanata/config.kbd"
  fi
fi

echo "==> Creating config symlinks..."
ensure_dirs
for pair in "${LINKS[@]}"; do
  IFS='|' read -r SRC DST <<<"$pair"
  backup_then_link "$SRC" "$DST"
done

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Ensure ~/.gitconfig exists (copy, don't symlink)
if [[ ! -f "$HOME/.gitconfig" ]]; then
  if [[ -f "$DOTFILES_DIR/config/git/gitconfig" ]]; then
    cp "$DOTFILES_DIR/config/git/gitconfig" "$HOME/.gitconfig"
    echo "-> Copied gitconfig to ~/.gitconfig"
  else
    echo "!! Source gitconfig not found at $DOTFILES_DIR/config/git/gitconfig"
  fi
else
  echo "== ~/.gitconfig exists; leaving as-is."
fi

# Handle Kanata config link only if installing Kanata
if [[ "$KANATA_INSTALL" == "yes" ]]; then
  mkdir -p "$HOME/.config/kanata"
  if [[ -n "$KANATA_CONFIG_SRC" ]]; then
    backup_then_link "$KANATA_CONFIG_SRC" "$HOME/.config/kanata/config.kbd"
  fi

  if have pacman; then
    # Ask how to enable Kanata: system-wide (pre-login) or user-only (post-login)
    SYS_PROMPT="Enable Kanata system-wide (pre-login; copies config to /etc, rerun script after changes)?"
    if [[ "$(prompt_yes_no "$SYS_PROMPT")" == "yes" ]]; then
      KANATA_ENABLE_SYSTEM=yes KANATA_ENABLE_USER=no \
        bash "$DOTFILES_DIR/config/kanata/add_to_startup_arch.sh"
    else
      USER_PROMPT="Enable Kanata for this user (starts after login)?"
      if [[ "$(prompt_yes_no "$USER_PROMPT")" == "yes" ]]; then
        KANATA_ENABLE_SYSTEM=no KANATA_ENABLE_USER=yes \
          bash "$DOTFILES_DIR/config/kanata/add_to_startup_arch.sh"
      else
        # Still run to ensure uinput rules/groups are configured; skip enabling units
        KANATA_ENABLE_SYSTEM=no KANATA_ENABLE_USER=no \
          bash "$DOTFILES_DIR/config/kanata/add_to_startup_arch.sh"
      fi
    fi
  else
    echo ">> Skipping Arch-specific Kanata startup setup on non-Arch system."
  fi
fi

# Run sensors-detect non-interactively to enable temperature readings
if have sensors-detect; then
  echo "==> Detecting hardware sensors..."
  sudo sensors-detect --auto >/dev/null 2>&1 || echo "   sensors-detect failed; run 'sudo sensors-detect' later if needed."
fi

echo "==> Done."
