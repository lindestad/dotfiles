#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/install/common.sh
source "$DOTFILES_DIR/scripts/install/common.sh"

from_root="$DOTFILES_DIR"
dry_run="no"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Remove managed symlinks that point at a dotfiles checkout.
Real files and symlinks to other targets are left untouched.

Options:
  --from-root PATH  Only remove symlinks pointing inside PATH
  -n, --dry-run     Print what would be removed
  -h, --help        Show this help
EOF
}

while (($#)); do
  case "$1" in
    --from-root)
      if [[ $# -lt 2 ]]; then
        echo "!! --from-root needs a path"
        exit 2
      fi
      from_root="$2"
      shift
      ;;
    -n|--dry-run) dry_run="yes" ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "!! Unknown option: $1"
      usage
      exit 2
      ;;
  esac
  shift
done

abs_path() {
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$1"
  else
    readlink -m "$1"
  fi
}

symlink_target_abs() {
  local link_path="$1"
  local raw target

  raw="$(readlink "$link_path")"
  case "$raw" in
    /*) target="$raw" ;;
    *) target="$(dirname "$link_path")/$raw" ;;
  esac

  abs_path "$target"
}

unlink_managed_link() {
  local dst="$1"
  local from_abs="$2"
  local target_abs

  if [[ ! -L "$dst" ]]; then
    if [[ -e "$dst" ]]; then
      echo "== Keeping non-symlink: $dst"
    fi
    return
  fi

  target_abs="$(symlink_target_abs "$dst")"
  if [[ "$target_abs" != "$from_abs" && "$target_abs" != "$from_abs/"* ]]; then
    echo "== Keeping unmanaged symlink: $dst -> $(readlink "$dst")"
    return
  fi

  if [[ "$dry_run" == "yes" ]]; then
    echo "DRY unlink $dst -> $(readlink "$dst")"
  else
    rm -f "$dst"
    echo "-> Unlinked $dst"
  fi
}

LINKS=()
add_common_cli_links
add_zsh_link
add_bash_link
add_alacritty_link
add_wezterm_link
add_ghostty_link
add_wayland_desktop_links

from_root_abs="$(abs_path "$from_root")"
echo "==> Removing managed symlinks pointing inside $from_root_abs"

for pair in "${LINKS[@]}"; do
  IFS='|' read -r _src dst <<<"$pair"
  unlink_managed_link "$dst" "$from_root_abs"
done

echo "==> Unlink complete"
