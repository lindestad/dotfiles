#!/usr/bin/env bash
# Shared helpers for Linux/WSL install scripts. Source this file; do not run it.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! install-common.sh is a helper; run a distro installer instead."
  exit 1
fi

: "${DOTFILES_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

have() { command -v "$1" >/dev/null 2>&1; }

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

add_wayland_desktop_links() {
  LINKS+=(
    "$DOTFILES_DIR/config/niri|$HOME/.config/niri"
    "$DOTFILES_DIR/config/waybar|$HOME/.config/waybar"
    "$DOTFILES_DIR/config/fuzzel/fuzzel.ini|$HOME/.config/fuzzel/fuzzel.ini"
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

load_cargo_env() {
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi
  export PATH="$HOME/.cargo/bin:$PATH"
}

ensure_rust_toolchain() {
  if have cargo; then
    load_cargo_env
    return
  fi

  if ! have curl; then
    echo "!! curl is required to install rustup."
    return 1
  fi

  echo "==> Installing Rust toolchain (rustup)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  load_cargo_env
}

ensure_starship() {
  if have starship; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing starship with cargo..."
  cargo install --locked starship
}

ensure_bottom() {
  if have btm; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing bottom with cargo..."
  cargo install --locked bottom
}

ensure_typst_cli() {
  if have typst; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing Typst CLI with cargo..."
  cargo install --locked typst-cli
}

ensure_resvg_cargo() {
  if have resvg; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing resvg with cargo..."
  cargo install --locked resvg
}

ensure_dust_cargo() {
  if have dust; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing dust with cargo..."
  cargo install --locked du-dust
}

ensure_cargo_tool() {
  local command_name="$1" crate_name="$2" label="${3:-$1}"
  if have "$command_name"; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing $label with cargo..."
  cargo install --locked "$crate_name"
}

github_latest_asset_url() {
  local repo="$1" pattern="$2"
  curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
    | sed -nE 's/.*"browser_download_url": "([^"]+)".*/\1/p' \
    | grep -E "$pattern" \
    | head -n1
}

install_github_release_binary() {
  local label="$1" repo="$2" asset_pattern="$3" bin_name="$4"
  local asset_url tmp_file

  if ! have curl; then
    echo "!! curl is required to install $label."
    return 1
  fi

  asset_url="$(github_latest_asset_url "$repo" "$asset_pattern" || true)"
  if [[ -z "$asset_url" ]]; then
    echo "!! Could not resolve latest $label release asset matching: $asset_pattern"
    return 1
  fi

  ensure_local_bin
  tmp_file="$(mktemp)"
  echo "==> Installing $label from upstream release..."
  curl -fL "$asset_url" -o "$tmp_file"
  install -m 0755 "$tmp_file" "$HOME/.local/bin/$bin_name"
  rm -f "$tmp_file"
  export PATH="$HOME/.local/bin:$PATH"
}

install_github_release_archive_binary() {
  local label="$1" repo="$2" asset_pattern="$3" bin_name="$4"
  local asset_url tmp_dir archive

  if ! have curl || ! have tar; then
    echo "!! curl and tar are required to install $label."
    return 1
  fi

  asset_url="$(github_latest_asset_url "$repo" "$asset_pattern" || true)"
  if [[ -z "$asset_url" ]]; then
    echo "!! Could not resolve latest $label release asset matching: $asset_pattern"
    return 1
  fi

  ensure_local_bin
  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/archive.tar.gz"
  echo "==> Installing $label from upstream release..."
  curl -fL "$asset_url" -o "$archive"
  tar -C "$tmp_dir" -xzf "$archive"
  if [[ ! -x "$tmp_dir/$bin_name" ]]; then
    echo "!! $label release archive did not contain executable $bin_name."
    rm -rf "$tmp_dir"
    return 1
  fi
  install -m 0755 "$tmp_dir/$bin_name" "$HOME/.local/bin/$bin_name"
  rm -rf "$tmp_dir"
  export PATH="$HOME/.local/bin:$PATH"
}

ensure_shfmt_release() {
  if have shfmt; then
    return
  fi

  local machine asset_arch
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) asset_arch="amd64" ;;
    aarch64|arm64) asset_arch="arm64" ;;
    *)
      echo ">> Unsupported shfmt release architecture: $machine"
      return 1
      ;;
  esac

  install_github_release_binary "shfmt" "mvdan/sh" "shfmt_v[0-9.]+_linux_${asset_arch}$" "shfmt"
}

ensure_yq_mikefarah() {
  if have yq && yq --version 2>/dev/null | grep -qi 'github.com/mikefarah/yq'; then
    return
  fi

  local machine asset_arch
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) asset_arch="amd64" ;;
    aarch64|arm64) asset_arch="arm64" ;;
    *)
      echo ">> Unsupported yq release architecture: $machine"
      return 1
      ;;
  esac

  install_github_release_binary "Mike Farah yq" "mikefarah/yq" "yq_linux_${asset_arch}$" "yq"
}

ensure_lazygit_release() {
  if have lazygit; then
    return
  fi

  local machine asset_arch
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) asset_arch="x86_64" ;;
    aarch64|arm64) asset_arch="arm64" ;;
    *)
      echo ">> Unsupported lazygit release architecture: $machine"
      return 1
      ;;
  esac

  install_github_release_archive_binary "lazygit" "jesseduffield/lazygit" "lazygit_[0-9.]+_linux_${asset_arch}\\.tar\\.gz$" "lazygit"
}

ensure_modern_cli_cargo_tools() {
  ensure_cargo_tool just just
  ensure_cargo_tool hyperfine hyperfine
  ensure_cargo_tool watchexec watchexec-cli
  ensure_cargo_tool atuin atuin
  ensure_cargo_tool sd sd
  ensure_cargo_tool xh xh
  ensure_cargo_tool procs procs
  ensure_cargo_tool broot broot
  ensure_cargo_tool gitui gitui
}

ensure_neovim_release() {
  local machine nvim_arch
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) nvim_arch="x86_64" ;;
    aarch64|arm64) nvim_arch="arm64" ;;
    *)
      echo ">> Unsupported Neovim release architecture: $machine"
      return 1
      ;;
  esac

  if ! have curl || ! have tar; then
    echo ">> curl and tar are required to install upstream Neovim."
    return 1
  fi

  ensure_local_bin

  local url latest_version current_version tmp_dir archive extracted install_root install_dir bin_link ts
  url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz"
  install_root="$HOME/.local/opt"
  install_dir="$install_root/nvim-linux-${nvim_arch}"
  bin_link="$HOME/.local/bin/nvim"

  latest_version="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null \
    | sed -nE 's/^[[:space:]]*"tag_name":[[:space:]]*"v?([^"]+)".*/\1/p' \
    | head -n1 || true)"
  if have nvim && [[ -n "$latest_version" ]]; then
    current_version="$(nvim --version | sed -nE '1s/^NVIM v([^[:space:]]+).*/\1/p')"
    if [[ "$current_version" == "$latest_version" ]]; then
      echo "== Neovim is already latest stable ($current_version)."
      return
    fi
  fi

  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/nvim.tar.gz"
  extracted="$tmp_dir/nvim-linux-${nvim_arch}"

  echo "==> Installing latest stable Neovim from upstream release..."
  if ! curl -fL "$url" -o "$archive"; then
    echo ">> Failed to download Neovim release: $url"
    return 1
  fi
  if ! tar -C "$tmp_dir" -xzf "$archive"; then
    echo ">> Failed to extract Neovim release archive."
    return 1
  fi
  if [[ ! -x "$extracted/bin/nvim" ]]; then
    echo ">> Neovim release archive did not contain bin/nvim."
    return 1
  fi

  mkdir -p "$install_root"
  if [[ -e "$install_dir" || -L "$install_dir" ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    mv "$install_dir" "${install_dir}.bak.${ts}"
  fi
  mv "$extracted" "$install_dir"

  if [[ -L "$bin_link" ]]; then
    ln -sfn "$install_dir/bin/nvim" "$bin_link"
  elif [[ -e "$bin_link" ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    mv "$bin_link" "${bin_link}.bak.${ts}"
    ln -s "$install_dir/bin/nvim" "$bin_link"
  else
    ln -s "$install_dir/bin/nvim" "$bin_link"
  fi

  "$bin_link" --version | head -n 1
}

ensure_yazi_cargo() {
  if have yazi && have ya; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing Yazi with cargo..."
  cargo install --force yazi-build
}

ensure_vivid_cargo() {
  if have vivid; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing vivid with cargo..."
  cargo install --locked vivid
}

ensure_carapace_apt_repo() {
  # carapace-bin is not in the Debian/Ubuntu repos; add the upstream Gemfury
  # apt repo so it can be installed via apt-get like everything else.
  if have carapace; then
    return
  fi

  local list="/etc/apt/sources.list.d/fury-carapace.list"
  if [[ -f "$list" ]]; then
    return
  fi

  echo "==> Adding carapace-bin apt repo (apt.fury.io)..."
  echo 'deb [trusted=yes] https://apt.fury.io/rsteube/ /' | sudo tee "$list" >/dev/null
}

ensure_fnm() {
  if have fnm; then
    return
  fi

  if ! have curl || ! have unzip; then
    echo "!! curl and unzip are required to install fnm."
    return 1
  fi

  echo "==> Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell
  export PATH="$HOME/.local/share/fnm:$PATH"
}

ensure_node_lts() {
  ensure_fnm

  if fnm default >/dev/null 2>&1; then
    return
  fi

  echo "==> Installing default Node.js LTS with fnm..."
  fnm install --lts
  fnm default lts-latest
}

ensure_uv() {
  export PATH="$HOME/.local/bin:$PATH"

  if have uv; then
    return
  fi

  if ! have curl; then
    echo "!! curl is required to install uv."
    return 1
  fi

  echo "==> Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
  export PATH="$HOME/.local/bin:$PATH"
}

ensure_uv_tools() {
  local tool

  ensure_uv || return
  if ! have uv; then
    echo "!! uv is not available; skipping uv tools: $*"
    return 1
  fi

  for tool in "$@"; do
    echo "==> Installing/upgrading uv tool: $tool"
    uv tool install --upgrade "$tool"
  done

  export PATH="$HOME/.local/bin:$PATH"
}

ensure_kanata_cargo() {
  if have kanata; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing Kanata with cargo..."
  cargo install kanata
}

ensure_zellij_cargo() {
  if have zellij; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing Zellij with cargo..."
  cargo install --locked zellij
}

ensure_broot_launcher() {
  if ! have broot; then
    return
  fi

  local shell_name launcher_dir launcher_file
  for shell_name in bash zsh; do
    launcher_dir="$HOME/.config/broot/launcher/$shell_name"
    launcher_file="$launcher_dir/br"
    mkdir -p "$launcher_dir"
    if broot --print-shell-function "$shell_name" >"$launcher_file"; then
      chmod 0644 "$launcher_file"
    else
      rm -f "$launcher_file"
      echo ">> Could not generate broot launcher for $shell_name."
    fi
  done

  broot --set-install-state installed >/dev/null 2>&1 || true
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

choose_kanata_config() {
  # Read by the sourcing distro installer after this function returns.
  local prompt="Remap ISO to ANSI like? Warning, remaps Enter key."
  if [[ "$(prompt_yes_no "$prompt")" == "yes" ]]; then
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
  local helper="$DOTFILES_DIR/config/kanata/add_to_startup_arch.sh"
  local system_prompt user_prompt

  system_prompt="Enable Kanata system-wide (pre-login; copies config to /etc, rerun script after changes)?"
  if [[ "$(prompt_yes_no "$system_prompt")" == "yes" ]]; then
    KANATA_ENABLE_SYSTEM=yes KANATA_ENABLE_USER=no bash "$helper"
  else
    user_prompt="Enable Kanata for this user (starts after login)?"
    if [[ "$(prompt_yes_no "$user_prompt")" == "yes" ]]; then
      KANATA_ENABLE_SYSTEM=no KANATA_ENABLE_USER=yes bash "$helper"
    else
      KANATA_ENABLE_SYSTEM=no KANATA_ENABLE_USER=no bash "$helper"
    fi
  fi

  echo ">> Reboot after Kanata setup so group membership and uinput permissions take effect."
}

run_sensors_detect() {
  if have sensors-detect; then
    echo "==> Detecting hardware sensors..."
    sudo sensors-detect --auto >/dev/null 2>&1 || echo "   sensors-detect failed; run 'sudo sensors-detect' later if needed."
  fi
}
