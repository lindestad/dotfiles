#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/install/common.sh
source "$DOTFILES_DIR/scripts/install/common.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Relink managed dotfiles from this checkout without installing packages.

Options:
  --niri        Link Niri + Noctalia desktop config
  --no-niri     Skip Niri + Noctalia desktop config
  --kanata      Link Kanata keyboard remapping config
  --no-kanata   Skip Kanata
  -y, --yes     Use non-interactive defaults for unspecified options
  -h, --help    Show this help
EOF
}

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

is_debian_like_relink() {
  local id="" id_like=""

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}"
    id_like="${ID_LIKE:-}"
  fi

  case " $id $id_like " in
    *" ubuntu "*|*" debian "*|*" pop "*|*" linuxmint "*) return 0 ;;
    *) return 1 ;;
  esac
}

existing_kanata_config_src() {
  local current="$HOME/.config/kanata/config.kbd"
  local raw basename candidate

  [[ -L "$current" ]] || return 1

  raw="$(readlink "$current")"
  basename="$(basename "$raw")"
  candidate="$DOTFILES_DIR/config/kanata/$basename"

  [[ -f "$candidate" ]] || return 1
  printf '%s\n' "$candidate"
}

LINKS=()
add_common_cli_links
add_zsh_link

if is_wsl; then
  resolve_install_flags no no
else
  resolve_install_flags yes yes
  if is_debian_like_relink; then
    add_bash_link
  fi
  add_alacritty_link
  add_wezterm_link
  add_ghostty_link
  if [[ "$INSTALL_NIRI" == "yes" ]]; then
    add_wayland_desktop_links
  fi
fi

echo "==> Relinking managed config from $DOTFILES_DIR"
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  prepare_niri_config_dir
fi
link_pairs "${LINKS[@]}"

ensure_local_bin
install_dotfiles_helpers
if [[ "$INSTALL_NIRI" == "yes" ]]; then
  validate_migrated_niri_local_config
  install_niri_helpers
  install_zen_browser_url_handler
fi

KANATA_CONFIG_SRC=""
if [[ "$INSTALL_KANATA" == "yes" ]]; then
  if KANATA_CONFIG_SRC="$(existing_kanata_config_src)"; then
    echo "== Preserving Kanata profile: $(basename "$KANATA_CONFIG_SRC")"
  else
    choose_kanata_config
  fi
  link_kanata_config "$KANATA_CONFIG_SRC"
fi

echo "==> Relink complete"
