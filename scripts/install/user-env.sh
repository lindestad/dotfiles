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

  if [[ -n "${SET_ZSH_DEFAULT:-}" ]]; then
    [[ "$SET_ZSH_DEFAULT" == "yes" ]] || return
  elif [[ "$(prompt_yes_no "Set zsh as default shell?")" != "yes" ]]; then
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
    zen-preferences
    zen-url-handler
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

zen_browser_available() {
  if have flatpak && flatpak info app.zen_browser.zen >/dev/null 2>&1; then
    return 0
  fi
  have zen-browser || have zen
}

ensure_zen_browser() {
  if zen_browser_available; then
    echo "== Zen Browser is already installed."
    return
  fi

  if ! have flatpak; then
    echo ">> Flatpak is not installed; skipping Zen Browser installation."
    return
  fi

  echo "==> Enabling Flathub for the current user..."
  if ! flatpak remote-add --user --if-not-exists \
    flathub https://flathub.org/repo/flathub.flatpakrepo; then
    echo ">> Could not enable Flathub; skipping Zen Browser installation."
    return
  fi

  echo "==> Installing Zen Browser from Flathub..."
  if ! flatpak install --user --noninteractive flathub app.zen_browser.zen; then
    echo ">> Could not install Zen Browser from Flathub."
    return
  fi

  echo "-> Installed Zen Browser from Flathub."
}

install_zen_browser_url_handler() {
  ensure_local_bin

  local helper_src="$DOTFILES_DIR/bin/zen-url-handler"
  local helper_dst="$HOME/.local/bin/zen-url-handler"
  local applications_dir="$HOME/.local/share/applications"
  local desktop_file="$applications_dir/zen-url-handler.desktop"

  if [[ ! -f "$helper_src" ]]; then
    echo "!! Missing Zen Browser launcher helper: $helper_src"
    return
  fi

  install -m 0755 "$helper_src" "$helper_dst"
  mkdir -p "$applications_dir"
  cat >"$desktop_file" <<EOF
[Desktop Entry]
Name=Zen Browser
Comment=Open links in Zen Browser
Exec=$helper_dst %u
Icon=app.zen_browser.zen
Type=Application
MimeType=text/html;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
NoDisplay=true
Terminal=false
Categories=Network;WebBrowser;
EOF
  echo "-> Installed Zen Browser desktop integration: ~/.local/share/applications/zen-url-handler.desktop"

  if have desktop-file-validate; then
    desktop-file-validate "$desktop_file" || return
  fi

  if have update-desktop-database; then
    update-desktop-database "$applications_dir" || true
  fi

  if ! zen_browser_available; then
    echo ">> Zen Browser not detected; leaving browser defaults unchanged."
    return
  fi

  if ! have xdg-mime; then
    echo ">> xdg-mime not found; cannot set Zen Browser defaults."
    return
  fi

  xdg-mime default zen-url-handler.desktop x-scheme-handler/http
  xdg-mime default zen-url-handler.desktop x-scheme-handler/https
  xdg-mime default zen-url-handler.desktop text/html
  xdg-mime default zen-url-handler.desktop application/xhtml+xml

  if have xdg-settings; then
    xdg-settings set default-web-browser zen-url-handler.desktop || true
  fi

  if have update-desktop-database; then
    update-desktop-database "$applications_dir" || true
  fi

  echo "-> Set Zen Browser as the default browser for links."
}

apply_zen_browser_preferences() {
  ensure_local_bin

  local helper_src="$DOTFILES_DIR/bin/zen-preferences"
  local helper_dst="$HOME/.local/bin/zen-preferences"

  if [[ ! -f "$helper_src" ]]; then
    echo "!! Missing Zen preferences helper: $helper_src"
    return
  fi

  install -m 0755 "$helper_src" "$helper_dst"

  if ! zen_browser_available; then
    echo ">> Zen Browser not detected; leaving browser preferences unchanged."
    return
  fi

  "$helper_dst"
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
