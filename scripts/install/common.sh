#!/usr/bin/env bash
# Shared helpers for Linux/WSL install scripts. Source this file; do not run it.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! scripts/install/common.sh is a helper; run ./install.sh instead."
  exit 1
fi

: "${DOTFILES_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

have() { command -v "$1" >/dev/null 2>&1; }

# shellcheck source=scripts/install/desktop-niri.sh
source "$DOTFILES_DIR/scripts/install/desktop-niri.sh"
# shellcheck source=scripts/install/config-links.sh
source "$DOTFILES_DIR/scripts/install/config-links.sh"
# shellcheck source=scripts/install/tools.sh
source "$DOTFILES_DIR/scripts/install/tools.sh"
# shellcheck source=scripts/install/kanata.sh
source "$DOTFILES_DIR/scripts/install/kanata.sh"
# shellcheck source=scripts/install/user-env.sh
source "$DOTFILES_DIR/scripts/install/user-env.sh"

INSTALL_NIRI=""
INSTALL_KANATA=""
ASSUME_YES="no"
DNF_MAKECACHE_DONE="no"

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

install_pacman() {
  sudo pacman -Syu --needed --noconfirm "$@"
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

  if [[ "${DNF_MAKECACHE_DONE:-no}" != "yes" ]]; then
    sudo dnf makecache -y || true
    DNF_MAKECACHE_DONE="yes"
  fi

  if dnf install --help 2>&1 | grep -q -- '--skip-unavailable'; then
    echo "==> Installing available dnf packages..."
    sudo dnf install -y --skip-unavailable "${pkgs[@]}"
    return
  fi

  echo "==> Checking dnf package availability..."
  for pkg in "${pkgs[@]}"; do
    echo "-> Checking $pkg"
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
