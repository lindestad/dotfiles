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
  fzf
  zoxide
  imagemagick
  yazi
  git
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

# AUR packages (installed with yay/paru if present)
AUR_PKGS=(
  # kanata is optional; installed based on prompt below
  carapace-bin
)

# Symlinks: "SRC|DST"
# (Create the source files/dirs in your repo matching these paths)
LINKS=(
  "$DOTFILES_DIR/shells/.zshrc|$HOME/.zshrc"
  "$DOTFILES_DIR/config/helix/config.toml|$HOME/.config/helix/config.toml"
  "$DOTFILES_DIR/config/helix/languages.toml|$HOME/.config/helix/languages.toml"
  "$DOTFILES_DIR/config/starship/zsh/starship.toml|$HOME/.config/starship.toml"
  "$DOTFILES_DIR/config/yazi|$HOME/.config/yazi"
  "$DOTFILES_DIR/config/ncspot/config.toml|$HOME/.config/ncspot/config.toml"
  # Kanata config is handled conditionally below; do not link entire dir here
  "$DOTFILES_DIR/config/niri|$HOME/.config/niri"
  "$DOTFILES_DIR/config/waybar|$HOME/.config/waybar"
  "$DOTFILES_DIR/config/fuzzel/fuzzel.ini|$HOME/.config/fuzzel/fuzzel.ini"
)

# --- Helpers ------------------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

aur_helper() {
  if have yay; then echo yay; return 0; fi
  if have paru; then echo paru; return 0; fi
  return 1
}

install_pacman() {
  sudo pacman -Sy --needed --noconfirm "$@"
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
  local ans
  while true; do
    read -r -p "$1 y/N " ans || ans=""
    case "${ans}" in
      [Yy]) echo "yes"; return 0;;
      ''|[Nn]) echo "no"; return 0;;
      *) echo "Please answer y or n.";;
    esac
  done
}

# --- Run ----------------------------------------------------------------------

echo "==> Installing pacman packages..."
install_pacman "${PACMAN_PKGS[@]}"

if ((${#AUR_PKGS[@]})); then
  echo "==> Installing AUR packages (if helper found)..."
  install_aur "${AUR_PKGS[@]}"
fi

# Kanata optional install + config selection
KANATA_INSTALL="$(prompt_yes_no "Install Kanata (Keyboard remapping)?")"
KANATA_CONFIG_SRC=""
if [[ "$KANATA_INSTALL" == "yes" ]]; then
  echo "==> Installing Kanata from AUR (if helper found)..."
  install_aur kanata || true

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

# Handle Kanata config link only if installing Kanata
if [[ "$KANATA_INSTALL" == "yes" ]]; then
  mkdir -p "$HOME/.config/kanata"
  if [[ -n "$KANATA_CONFIG_SRC" ]]; then
    backup_then_link "$KANATA_CONFIG_SRC" "$HOME/.config/kanata/config.kbd"
  fi
  echo "==> You can run: $DOTFILES_DIR/config/kanata/add_to_startup_arch.sh to enable autostart (systemd user)."
fi

echo "==> Done."
echo "Notes:"
echo " - Run 'sudo sensors-detect' once for temperature readings."
