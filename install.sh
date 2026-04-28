#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-common.sh
source "$DOTFILES_DIR/install-common.sh"

parse_install_flags "$@"

if is_wsl; then
  resolve_install_flags no no
  mapfile -t dispatch_args < <(install_flag_args)
  exec "$DOTFILES_DIR/install-wsl.sh" "${dispatch_args[@]}"
fi

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
else
  echo "!! Cannot detect distro: /etc/os-release is missing."
  exit 1
fi

installer=""
case "${ID:-}" in
  arch|endeavouros|manjaro)
    installer="$DOTFILES_DIR/install-arch.sh"
    ;;
  ubuntu|debian|pop|linuxmint)
    installer="$DOTFILES_DIR/install-ubuntu.sh"
    ;;
  fedora)
    installer="$DOTFILES_DIR/install-fedora.sh"
    ;;
esac

if [[ -z "$installer" ]]; then
  case " ${ID_LIKE:-} " in
    *" arch "*)
      installer="$DOTFILES_DIR/install-arch.sh"
      ;;
    *" debian "*|*" ubuntu "*)
      installer="$DOTFILES_DIR/install-ubuntu.sh"
      ;;
    *" fedora "*)
      installer="$DOTFILES_DIR/install-fedora.sh"
      ;;
  esac
fi

if [[ -n "$installer" ]]; then
  resolve_install_flags yes yes
  mapfile -t dispatch_args < <(install_flag_args)
  exec "$installer" "${dispatch_args[@]}"
fi

echo "!! Unsupported distro: ${PRETTY_NAME:-${ID:-unknown}}"
echo "   Run one of: ./install-arch.sh, ./install-ubuntu.sh, ./install-fedora.sh, ./install-wsl.sh"
exit 1
