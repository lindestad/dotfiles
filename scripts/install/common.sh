#!/usr/bin/env bash
# Shared helpers for Linux/WSL install scripts. Source this file; do not run it.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! scripts/install/common.sh is a helper; run ./install.sh instead."
  exit 1
fi

: "${DOTFILES_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

have() { command -v "$1" >/dev/null 2>&1; }

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

render_install_output() {
  local line current total label width filled_count empty_count percent filled empty
  local reset=$'\033[0m' bold=$'\033[1m' muted=$'\033[2m'
  local cyan=$'\033[38;5;81m' green=$'\033[38;5;114m'
  local yellow=$'\033[38;5;214m' red=$'\033[38;5;203m'

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^==\>\ \[([0-9]+)/([0-9]+)\]\ (.*)$ ]]; then
      current="${BASH_REMATCH[1]}"
      total="${BASH_REMATCH[2]}"
      label="${BASH_REMATCH[3]}"
      width=28
      percent=$((current * 100 / total))
      filled_count=$((current * width / total))
      empty_count=$((width - filled_count))
      printf -v filled '%*s' "$filled_count" ''
      printf -v empty '%*s' "$empty_count" ''
      filled="${filled// /■}"
      empty="${empty// /･}"
      printf '\n%b%s%s %3d%%%b  %b%s%b\n' \
        "$yellow" "$filled" "$empty" "$percent" "$reset" "$bold" "$label" "$reset"
      continue
    fi

    case "$line" in
      '==> '*) printf '\n%b◆%b %b%s%b\n' "$cyan" "$reset" "$bold" "${line#==> }" "$reset" ;;
      '== '*) printf '%b✓%b %s\n' "$green" "$reset" "${line#== }" ;;
      '-> '*) printf '%b✓%b %s\n' "$green" "$reset" "${line#-> }" ;;
      '>> '*) printf '%b⚠%b %s\n' "$yellow" "$reset" "${line#>> }" ;;
      '!! '*) printf '%b✗%b %s\n' "$red" "$reset" "${line#!! }" ;;
      '   '*) printf '%b%s%b\n' "$muted" "$line" "$reset" ;;
      *) printf '%s\n' "$line" ;;
    esac
  done
}

start_install_log() {
  if [[ "${DOTFILES_INSTALL_LOGGING:-}" == "active" ]]; then
    return
  fi

  local log_dir ts pipe_dir pipe_path
  log_dir="${DOTFILES_INSTALL_LOG_DIR:-$DOTFILES_DIR/logs}"
  mkdir -p "$log_dir"
  ts="$(date +%Y%m%d-%H%M%S)"
  export DOTFILES_INSTALL_LOG_FILE="${DOTFILES_INSTALL_LOG_FILE:-$log_dir/install-$ts.log}"
  export DOTFILES_INSTALL_LOGGING="active"

  pipe_dir="$(mktemp -d)"
  pipe_path="$pipe_dir/output"
  mkfifo "$pipe_path"

  if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
    exec 3>&1
    export DOTFILES_INSTALL_INTERACTIVE="yes"
    tee -a "$DOTFILES_INSTALL_LOG_FILE" <"$pipe_path" | render_install_output >&3 &
  else
    export DOTFILES_INSTALL_INTERACTIVE="no"
    tee -a "$DOTFILES_INSTALL_LOG_FILE" <"$pipe_path" &
  fi
  DOTFILES_INSTALL_LOG_PID=$!
  exec >"$pipe_path" 2>&1
  rm -f "$pipe_path"
  rmdir "$pipe_dir"
  trap finish_install_log EXIT
}

finish_install_log() {
  trap - EXIT
  exec 1>&- 2>&-
  wait "${DOTFILES_INSTALL_LOG_PID:?}" || true
}

show_install_intro() {
  if [[ "${DOTFILES_INSTALL_INTRO_SHOWN:-}" == "yes" ]]; then
    return
  fi
  export DOTFILES_INSTALL_INTRO_SHOWN="yes"

  local logo details
  logo="$(cat <<'EOF'
   ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
   ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
   ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
   ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██╗██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
╚═╝╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
EOF
)"
  details="Personal workstation bootstrap
Installs tools, links managed config, and preserves replaced files as timestamped backups.
Choices are collected before installation; package managers may still request sudo credentials.
Log: ${DOTFILES_INSTALL_LOG_FILE:-disabled}"

  if [[ "${DOTFILES_INSTALL_INTERACTIVE:-no}" == "yes" ]]; then
    printf '\033[38;5;81m%s\033[0m\n\n\033[1m%s\033[0m\n\033[2m%s\n%s\n%s\033[0m\n' \
      "$logo" \
      "${details%%$'\n'*}" \
      "$(printf '%s\n' "$details" | sed -n '2p')" \
      "$(printf '%s\n' "$details" | sed -n '3p')" \
      "$(printf '%s\n' "$details" | sed -n '4p')" >&3
    {
      printf '%s\n\n%s\n' "$logo" "$details"
    } >>"$DOTFILES_INSTALL_LOG_FILE"
  else
    printf '%s\n\n%s\n' "$logo" "$details"
  fi
}

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
SET_ZSH_DEFAULT=""
KANATA_LAYOUT=""
KANATA_STARTUP=""
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
    if [[ "${DOTFILES_INSTALL_INTERACTIVE:-no}" == "yes" ]]; then
      printf '\033[38;5;214m?\033[0m %s \033[2m[y/N]\033[0m ' "$1" >&3
      read -r answer || answer=""
    else
      read -r -p "$1 [y/N] " answer || answer=""
    fi
    case "${answer}" in
      [Yy]) echo "yes"; return 0 ;;
      ''|[Nn]) echo "no"; return 0 ;;
      *)
        if [[ "${DOTFILES_INSTALL_INTERACTIVE:-no}" == "yes" ]]; then
          printf '\033[38;5;214m⚠\033[0m Please answer y or n.\n' >&3
        else
          echo "Please answer y or n." >&2
        fi
        ;;
    esac
  done
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --niri        Install the Niri + Noctalia desktop stack
  --no-niri     Skip the Niri + Noctalia desktop stack
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
      echo ">> Niri + Noctalia desktop stack is not supported by this installer; skipping."
    fi
    INSTALL_NIRI="no"
  elif [[ -z "$INSTALL_NIRI" ]]; then
    if [[ "$ASSUME_YES" == "yes" ]]; then
      INSTALL_NIRI="no"
    elif [[ "$(prompt_yes_no "Install Niri + Noctalia desktop stack?")" == "yes" ]]; then
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

}

collect_install_choices() {
  local support_niri="${1:-yes}"
  local support_kanata="${2:-yes}"
  local current_shell=""

  resolve_install_flags "$support_niri" "$support_kanata"

  if [[ "$INSTALL_KANATA" == "yes" ]]; then
    if [[ "$ASSUME_YES" == "yes" ]]; then
      KANATA_LAYOUT="default"
      KANATA_STARTUP="none"
    else
      if [[ "$(prompt_yes_no "Use the ISO-to-ANSI Kanata layout (remaps Enter)?")" == "yes" ]]; then
        KANATA_LAYOUT="iso-ansi"
      else
        KANATA_LAYOUT="default"
      fi

      if [[ "$(prompt_yes_no "Enable Kanata system-wide, including the login screen?")" == "yes" ]]; then
        KANATA_STARTUP="system"
      elif [[ "$(prompt_yes_no "Enable Kanata for this user after login?")" == "yes" ]]; then
        KANATA_STARTUP="user"
      else
        KANATA_STARTUP="none"
      fi
    fi
  fi

  current_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || true)"
  if [[ "${current_shell##*/}" != "zsh" ]]; then
    if [[ "$ASSUME_YES" == "yes" ]]; then
      SET_ZSH_DEFAULT="no"
    else
      SET_ZSH_DEFAULT="$(prompt_yes_no "Set zsh as the default shell?")"
    fi
  fi

}

show_install_plan() {
  echo "==> Installation plan"
  echo "-> Desktop stack: $INSTALL_NIRI"
  echo "-> Kanata: $INSTALL_KANATA${KANATA_LAYOUT:+ ($KANATA_LAYOUT, $KANATA_STARTUP startup)}"
  if [[ -n "$SET_ZSH_DEFAULT" ]]; then
    echo "-> Set zsh as default: $SET_ZSH_DEFAULT"
  fi
}

install_progress() {
  printf '==> [%d/%d] %s\n' "$1" "$2" "$3"
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
  if have shelly; then echo shelly; return 0; fi
  return 1
}

install_aur() {
  local helper
  if helper="$(aur_helper)"; then
    case "$helper" in
      yay|paru) "$helper" -S --needed --noconfirm "$@" ;;
      shelly) shelly aur install --no-confirm "$@" ;;
      *)
        echo "!! Unsupported AUR helper: $helper"
        return 1
        ;;
    esac
  else
    echo ">> No AUR helper (yay/paru/shelly) found. Skipping AUR packages: $*"
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
