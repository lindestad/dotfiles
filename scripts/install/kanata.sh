#!/usr/bin/env bash
# Kanata install helpers. Source from scripts/install/common.sh.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! scripts/install/kanata.sh is a helper; run ./install.sh instead."
  exit 1
fi

ensure_kanata_cargo() {
  if have kanata; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing Kanata with cargo..."
  cargo install kanata
}

choose_kanata_config() {
  # Read by the sourcing distro installer after this function returns.
  local prompt="Remap ISO to ANSI like? Warning, remaps Enter key."
  if [[ "${KANATA_LAYOUT:-}" == "iso-ansi" ]] || \
    [[ -z "${KANATA_LAYOUT:-}" && "$(prompt_yes_no "$prompt")" == "yes" ]]; then
    # shellcheck disable=SC2034
    KANATA_CONFIG_SRC="$DOTFILES_DIR/config/kanata/config_iso_to_ansi.kbd"
  else
    # shellcheck disable=SC2034
    KANATA_CONFIG_SRC="$DOTFILES_DIR/config/kanata/config.kbd"
  fi
}

link_kanata_config() {
  local config_src="$1"
  mkdir -p "$HOME/.config/kanata"
  backup_then_link "$config_src" "$HOME/.config/kanata/config.kbd"
}

setup_kanata_startup() {
  local helper="$DOTFILES_DIR/scripts/install/kanata-linux-startup.sh"
  local system_prompt user_prompt

  system_prompt="Enable Kanata system-wide (pre-login; copies config to /etc, rerun script after changes)?"
  if [[ "${KANATA_STARTUP:-}" == "system" ]] || \
    [[ -z "${KANATA_STARTUP:-}" && "$(prompt_yes_no "$system_prompt")" == "yes" ]]; then
    KANATA_ENABLE_SYSTEM=yes KANATA_ENABLE_USER=no bash "$helper"
  else
    user_prompt="Enable Kanata for this user (starts after login)?"
    if [[ "${KANATA_STARTUP:-}" == "user" ]] || \
      [[ -z "${KANATA_STARTUP:-}" && "$(prompt_yes_no "$user_prompt")" == "yes" ]]; then
      KANATA_ENABLE_SYSTEM=no KANATA_ENABLE_USER=yes bash "$helper"
    else
      KANATA_ENABLE_SYSTEM=no KANATA_ENABLE_USER=no bash "$helper"
    fi
  fi

  echo ">> Reboot after Kanata setup so group membership and uinput permissions take effect."
}
