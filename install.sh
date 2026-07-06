#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/common.sh
source "$DOTFILES_DIR/scripts/install/common.sh"

parse_install_flags "$@"

if is_wsl; then
  exec "$DOTFILES_DIR/scripts/install/wsl.sh" "$@"
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
    installer="$DOTFILES_DIR/scripts/install/arch.sh"
    ;;
  ubuntu|debian|pop|linuxmint)
    installer="$DOTFILES_DIR/scripts/install/ubuntu.sh"
    ;;
  fedora)
    installer="$DOTFILES_DIR/scripts/install/fedora.sh"
    ;;
esac

if [[ -z "$installer" ]]; then
  case " ${ID_LIKE:-} " in
    *" arch "*)
      installer="$DOTFILES_DIR/scripts/install/arch.sh"
      ;;
    *" debian "*|*" ubuntu "*)
      installer="$DOTFILES_DIR/scripts/install/ubuntu.sh"
      ;;
    *" fedora "*)
      installer="$DOTFILES_DIR/scripts/install/fedora.sh"
      ;;
  esac
fi

if [[ -n "$installer" ]]; then
  exec "$installer" "$@"
fi

echo "!! Unsupported distro: ${PRETTY_NAME:-${ID:-unknown}}"
echo "   Use ./install.sh on a supported Arch, Debian/Ubuntu, Fedora, or WSL install."
exit 1
