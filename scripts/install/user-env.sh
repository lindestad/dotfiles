#!/usr/bin/env bash
# User environment helpers. Source from scripts/install/common.sh.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! scripts/install/user-env.sh is a helper; run ./install.sh instead."
  exit 1
fi

install_fonts() {
  local src_dir="$DOTFILES_DIR/fonts"
  local dst_dir="$HOME/.local/share/fonts"
  local changed="no"
  local font dst

  if [[ ! -d "$src_dir" ]]; then
    echo ">> Font directory not found: $src_dir"
    return
  fi

  echo "==> Installing user fonts..."
  mkdir -p "$dst_dir"
  for font in "$src_dir"/*.ttf "$src_dir"/*.otf; do
    [[ -e "$font" ]] || continue
    dst="$dst_dir/$(basename "$font")"
    if [[ -f "$dst" ]] && cmp -s "$font" "$dst"; then
      echo "== Font already current: $(basename "$font")"
      continue
    fi

    cp -f "$font" "$dst"
    changed="yes"
    echo "-> Installed $(basename "$font")"
  done

  if [[ "$changed" != "yes" ]]; then
    echo "== User fonts already current."
    return
  fi

  if have fc-cache; then
    fc-cache -f "$dst_dir"
  else
    echo ">> fc-cache not found; restart apps after installing fontconfig."
  fi
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

install_dotfiles_helpers() {
  ensure_local_bin

  local helper
  local helpers=(
    dotfiles-doctor
  )

  for helper in "${helpers[@]}"; do
    if [[ ! -f "$DOTFILES_DIR/bin/$helper" ]]; then
      echo "!! Missing dotfiles helper: $DOTFILES_DIR/bin/$helper"
      continue
    fi

    install -m 0755 "$DOTFILES_DIR/bin/$helper" "$HOME/.local/bin/$helper"
    echo "-> Installed dotfiles helper: ~/.local/bin/$helper"
  done
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
