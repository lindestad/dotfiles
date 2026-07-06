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
# shellcheck source=scripts/install/tools.sh
source "$DOTFILES_DIR/scripts/install/tools.sh"
# shellcheck source=scripts/install/kanata.sh
source "$DOTFILES_DIR/scripts/install/kanata.sh"

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

add_common_cli_links() {
  LINKS+=(
    "$DOTFILES_DIR/config/atuin/config.toml|$HOME/.config/atuin/config.toml"
    "$DOTFILES_DIR/config/atuin/themes|$HOME/.config/atuin/themes"
    "$DOTFILES_DIR/config/broot/conf.toml|$HOME/.config/broot/conf.toml"
    "$DOTFILES_DIR/config/broot/skins|$HOME/.config/broot/skins"
    "$DOTFILES_DIR/config/codex/AGENTS.md|$HOME/.codex/AGENTS.md"
    "$DOTFILES_DIR/config/copilot/copilot-instructions.md|$HOME/.copilot/copilot-instructions.md"
    "$DOTFILES_DIR/config/git/ignore|$HOME/.config/git/ignore"
    "$DOTFILES_DIR/config/helix/config.toml|$HOME/.config/helix/config.toml"
    "$DOTFILES_DIR/config/helix/languages.toml|$HOME/.config/helix/languages.toml"
    "$DOTFILES_DIR/config/nvim|$HOME/.config/nvim"
    "$DOTFILES_DIR/config/starship/zsh/starship.toml|$HOME/.config/starship.toml"
    "$DOTFILES_DIR/config/yazi|$HOME/.config/yazi"
    "$DOTFILES_DIR/config/zellij|$HOME/.config/zellij"
  )
}

add_zsh_link() {
  LINKS+=("$DOTFILES_DIR/shells/.zshrc|$HOME/.zshrc")
}

add_bash_link() {
  LINKS+=("$DOTFILES_DIR/shells/.bashrc|$HOME/.bashrc")
}

add_alacritty_link() {
  LINKS+=("$DOTFILES_DIR/config/alacritty/alacritty.toml|$HOME/.config/alacritty/alacritty.toml")
}

add_wezterm_link() {
  LINKS+=("$DOTFILES_DIR/config/wezterm/wezterm.lua|$HOME/.config/wezterm/wezterm.lua")
}

add_ghostty_link() {
  LINKS+=(
    "$DOTFILES_DIR/config/ghostty/config.ghostty|$HOME/.config/ghostty/config.ghostty"
    "$DOTFILES_DIR/config/ghostty/shaders|$HOME/.config/ghostty/shaders"
  )
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
  for font in "$src_dir"/*.ttf "$src_dir"/*.otf; do
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

  if [[ ! -f "$src" ]]; then
    echo "!! Source gitconfig not found at $src"
    return
  fi

  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    echo "-> Copied gitconfig to ~/.gitconfig"
    return
  fi

  if ! have git; then
    echo "!! git not found; cannot merge gitconfig into ~/.gitconfig"
    return
  fi

  local entry key value existing
  while IFS= read -r entry; do
    [[ "$entry" == *=* ]] || continue
    key="${entry%%=*}"
    value="${entry#*=}"

    if existing="$(git config --global --get "$key" 2>/dev/null)"; then
      if [[ "$existing" != "$value" ]]; then
        echo "!! ~/.gitconfig already has $key=$existing; leaving desired value unapplied: $value"
      fi
    else
      git config --global "$key" "$value"
      echo "-> Added git config $key"
    fi
  done < <(git config --file "$src" --list)
}

ensure_codex_root_config() {
  local dst="$1"
  local key="$2"
  local value="$3"

  local existing
  existing="$(sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*(.*)$/\1/p" "$dst" | head -n 1)"
  if [[ -n "$existing" ]]; then
    if [[ "$existing" != "$value" ]]; then
      echo "!! ~/.codex/config.toml already has $key=$existing; leaving desired value unapplied: $value"
    fi
    return
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v line="$key = $value" '
    !inserted && /^[[:space:]]*\[/ {
      print line
      inserted = 1
    }
    { print }
    END {
      if (!inserted) {
        print line
      }
    }
  ' "$dst" >"$tmp"
  cp "$tmp" "$dst"
  rm -f "$tmp"
  echo "-> Added Codex config $key"
}

ensure_codex_tui_config() {
  local dst="$1"
  local key="$2"
  local value="$3"

  local existing
  existing="$(awk -v key="$key" '
    /^\[tui\][[:space:]]*$/ { in_tui = 1; next }
    /^\[/ { in_tui = 0 }
    in_tui && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*", "")
      print
      exit
    }
  ' "$dst")"
  if [[ -n "$existing" ]]; then
    if [[ "$existing" != "$value" ]]; then
      echo "!! ~/.codex/config.toml already has [tui].$key=$existing; leaving desired value unapplied: $value"
    fi
    return
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { inserted = 0 }
    /^\[tui\][[:space:]]*$/ {
      print
      print key " = " value
      inserted = 1
      next
    }
    { print }
    END {
      if (!inserted) {
        print ""
        print "[tui]"
        print key " = " value
      }
    }
  ' "$dst" >"$tmp"
  cp "$tmp" "$dst"
  rm -f "$tmp"
  echo "-> Added Codex TUI config $key"
}

ensure_codex_config() {
  local dst="$HOME/.codex/config.toml"

  mkdir -p "$(dirname "$dst")"
  touch "$dst"

  ensure_codex_root_config "$dst" "default_permissions" '":danger-full-access"'
  ensure_codex_root_config "$dst" "approval_policy" '"never"'
  ensure_codex_tui_config "$dst" "vim_mode_default" "true"
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

run_sensors_detect() {
  if have sensors-detect; then
    echo "==> Detecting hardware sensors..."
    sudo sensors-detect --auto >/dev/null 2>&1 || echo "   sensors-detect failed; run 'sudo sensors-detect' later if needed."
  fi
}
