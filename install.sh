#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-common.sh
source "$DOTFILES_DIR/install-common.sh"

if is_wsl; then
  exec "$DOTFILES_DIR/install-wsl.sh"
fi

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
else
  echo "!! Cannot detect distro: /etc/os-release is missing."
  exit 1
fi

case "${ID:-}" in
  arch|endeavouros|manjaro)
    exec "$DOTFILES_DIR/install-arch.sh"
    ;;
  ubuntu|debian|pop|linuxmint)
    exec "$DOTFILES_DIR/install-ubuntu.sh"
    ;;
  fedora)
    exec "$DOTFILES_DIR/install-fedora.sh"
    ;;
esac

case " ${ID_LIKE:-} " in
  *" arch "*)
    exec "$DOTFILES_DIR/install-arch.sh"
    ;;
  *" debian "*|*" ubuntu "*)
    exec "$DOTFILES_DIR/install-ubuntu.sh"
    ;;
  *" fedora "*)
    exec "$DOTFILES_DIR/install-fedora.sh"
    ;;
esac

echo "!! Unsupported distro: ${PRETTY_NAME:-${ID:-unknown}}"
echo "   Run one of: ./install-arch.sh, ./install-ubuntu.sh, ./install-fedora.sh, ./install-wsl.sh"
exit 1
