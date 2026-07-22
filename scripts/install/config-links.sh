#!/usr/bin/env bash
# Config link and config-file helpers. Source from scripts/install/common.sh.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! scripts/install/config-links.sh is a helper; run ./install.sh instead."
  exit 1
fi

add_common_cli_links() {
  LINKS+=(
    "$DOTFILES_DIR/config/atuin/config.toml|$HOME/.config/atuin/config.toml"
    "$DOTFILES_DIR/config/atuin/themes|$HOME/.config/atuin/themes"
    "$DOTFILES_DIR/config/broot/conf.toml|$HOME/.config/broot/conf.toml"
    "$DOTFILES_DIR/config/broot/skins|$HOME/.config/broot/skins"
    "$DOTFILES_DIR/config/codex/AGENTS.md|$HOME/.codex/AGENTS.md"
    "$DOTFILES_DIR/config/codex/skills/gh-publish|$HOME/.codex/skills/gh-publish"
    "$DOTFILES_DIR/config/copilot/copilot-instructions.md|$HOME/.copilot/copilot-instructions.md"
    "$DOTFILES_DIR/config/fastfetch|$HOME/.config/fastfetch"
    "$DOTFILES_DIR/config/git/ignore|$HOME/.config/git/ignore"
    "$DOTFILES_DIR/config/helix/config.toml|$HOME/.config/helix/config.toml"
    "$DOTFILES_DIR/config/helix/languages.toml|$HOME/.config/helix/languages.toml"
    "$DOTFILES_DIR/config/nvim|$HOME/.config/nvim"
    "$DOTFILES_DIR/config/starship/fish/starship.toml|$HOME/.config/starship/fish.toml"
    "$DOTFILES_DIR/config/starship/zsh/starship.toml|$HOME/.config/starship.toml"
    "$DOTFILES_DIR/config/tealdeer/config.toml|$HOME/.config/tealdeer/config.toml"
    "$DOTFILES_DIR/config/yazi|$HOME/.config/yazi"
    "$DOTFILES_DIR/config/zellij|$HOME/.config/zellij"
    "$DOTFILES_DIR/config/zsh-patina/config.toml|$HOME/.config/zsh-patina/config.toml"
  )
}

add_zsh_link() {
  LINKS+=(
    "$DOTFILES_DIR/shells/.zshrc|$HOME/.zshrc"
    "$DOTFILES_DIR/shells/.zprofile|$HOME/.zprofile"
  )
}

add_fish_link() {
  LINKS+=("$DOTFILES_DIR/shells/config.fish|$HOME/.config/fish/config.fish")
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
  existing="$(awk -v key="$key" '
    /^[[:space:]]*\[/ { exit }
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*", "")
      print
      exit
    }
  ' "$dst")"
  if [[ -n "$existing" ]]; then
    if [[ "$existing" != "$value" ]]; then
      local tmp
      tmp="$(mktemp)"
      awk -v key="$key" -v value="$value" '
        !in_table && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
          print key " = " value
          next
        }
        /^[[:space:]]*\[/ { in_table = 1 }
        { print }
      ' "$dst" >"$tmp"
      cp "$tmp" "$dst"
      rm -f "$tmp"
      echo "-> Updated Codex config $key"
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

ensure_codex_table_config() {
  local dst="$1"
  local table="$2"
  local key="$3"
  local value="$4"

  local existing
  existing="$(awk -v table="$table" -v key="$key" '
    {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      sub(/[[:space:]]*$/, "", line)
    }
    line == "[" table "]" { in_table = 1; next }
    line ~ /^\[/ { in_table = 0 }
    in_table && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*", "")
      print
      exit
    }
  ' "$dst")"
  if [[ -n "$existing" ]]; then
    if [[ "$existing" != "$value" ]]; then
      local tmp
      tmp="$(mktemp)"
      awk -v table="$table" -v key="$key" -v value="$value" '
        {
          line = $0
          sub(/^[[:space:]]*/, "", line)
          sub(/[[:space:]]*$/, "", line)
        }
        line == "[" table "]" { in_table = 1; print; next }
        line ~ /^\[/ { in_table = 0 }
        in_table && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
          print key " = " value
          next
        }
        { print }
      ' "$dst" >"$tmp"
      cp "$tmp" "$dst"
      rm -f "$tmp"
      echo "-> Updated Codex [$table] config $key"
    fi
    return
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v table="$table" -v key="$key" -v value="$value" '
    BEGIN { inserted = 0 }
    {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      sub(/[[:space:]]*$/, "", line)
    }
    line == "[" table "]" {
      print
      print key " = " value
      inserted = 1
      next
    }
    { print }
    END {
      if (!inserted) {
        print ""
        print "[" table "]"
        print key " = " value
      }
    }
  ' "$dst" >"$tmp"
  cp "$tmp" "$dst"
  rm -f "$tmp"
  echo "-> Added Codex [$table] config $key"
}

ensure_codex_config() {
  local dst="$HOME/.codex/config.toml"

  mkdir -p "$(dirname "$dst")"
  touch "$dst"

  ensure_codex_root_config "$dst" "sandbox_mode" '"danger-full-access"'
  ensure_codex_root_config "$dst" "approval_policy" '"never"'
  ensure_codex_table_config "$dst" "tui" "vim_mode_default" "true"
  ensure_codex_table_config "$dst" "tui" "status_line" '["model-with-reasoning", "current-dir", "context-used", "five-hour-limit", "weekly-limit"]'
  ensure_codex_table_config "$dst" "tui" "status_line_use_colors" "true"
  ensure_codex_table_config "$dst" "tui" "theme" '"monokai-extended"'
  ensure_codex_table_config "$dst" "tui.keymap.pager" "half_page_down" '"d"'
  ensure_codex_table_config "$dst" "tui.keymap.pager" "half_page_up" '"u"'
}
