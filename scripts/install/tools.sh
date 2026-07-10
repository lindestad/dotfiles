#!/usr/bin/env bash
# Tool bootstrap helpers. Source from scripts/install/common.sh.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! scripts/install/tools.sh is a helper; run ./install.sh instead."
  exit 1
fi

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

ensure_zsh_patina() {
  if have zsh-patina; then
    return
  fi

  ensure_rust_toolchain
  echo "==> Installing zsh-patina with cargo (target-cpu=native)..."
  if [[ "${RUSTFLAGS:-}" == *"target-cpu="* ]]; then
    cargo install --locked zsh-patina
  else
    RUSTFLAGS="${RUSTFLAGS:+$RUSTFLAGS }-C target-cpu=native" cargo install --locked zsh-patina
  fi
}

have_cargo_tealdeer() {
  [[ "$(command -v tldr 2>/dev/null || true)" == "$HOME/.cargo/bin/tldr" ]] \
    && tldr --version 2>/dev/null | head -n1 | grep -qi '^tealdeer '
}

update_tealdeer_cache() {
  echo "==> Updating tealdeer cache..."
  if ! tldr --update; then
    echo ">> Could not update tealdeer cache; run 'tldr --update' later."
  fi
}

ensure_tealdeer() {
  ensure_rust_toolchain
  if have_cargo_tealdeer; then
    return
  fi

  echo "==> Installing tealdeer with cargo..."
  cargo install --locked tealdeer
  update_tealdeer_cache
}

github_latest_asset_url() {
  local repo="$1" pattern="$2"
  curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
    | sed -nE 's/.*"browser_download_url": "([^"]+)".*/\1/p' \
    | grep -E "$pattern" \
    | head -n1
}

github_latest_release_tag() {
  local repo="$1"
  curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
    | sed -nE 's/^[[:space:]]*"tag_name":[[:space:]]*"([^"]+)".*/\1/p' \
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

install_github_release_gzip_binary() {
  local label="$1" repo="$2" asset_pattern="$3" bin_name="$4"
  local asset_url tmp_dir archive

  if ! have curl || ! have gzip; then
    echo "!! curl and gzip are required to install $label."
    return 1
  fi

  asset_url="$(github_latest_asset_url "$repo" "$asset_pattern" || true)"
  if [[ -z "$asset_url" ]]; then
    echo "!! Could not resolve latest $label release asset matching: $asset_pattern"
    return 1
  fi

  ensure_local_bin
  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/$bin_name.gz"
  echo "==> Installing $label from upstream release..."
  curl -fL "$asset_url" -o "$archive"
  gzip -dc "$archive" >"$tmp_dir/$bin_name"
  install -m 0755 "$tmp_dir/$bin_name" "$HOME/.local/bin/$bin_name"
  rm -rf "$tmp_dir"
  export PATH="$HOME/.local/bin:$PATH"
}

ensure_taplo_release() {
  if have taplo; then
    return
  fi

  local machine asset_arch
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) asset_arch="x86_64" ;;
    aarch64|arm64) asset_arch="aarch64" ;;
    i386|i686) asset_arch="x86" ;;
    armv7l|armv7) asset_arch="armv7" ;;
    riscv64) asset_arch="riscv64" ;;
    *)
      echo ">> Unsupported Taplo release architecture: $machine"
      return 1
      ;;
  esac

  install_github_release_gzip_binary \
    "Taplo" "tamasfe/taplo" "taplo-linux-${asset_arch}\\.gz$" "taplo"
}

ensure_powershell_release() {
  if have pwsh; then
    return
  fi

  local machine asset_arch asset_url tmp_dir archive extracted install_root install_dir bin_link ts
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) asset_arch="x64" ;;
    aarch64|arm64) asset_arch="arm64" ;;
    *)
      echo ">> Unsupported PowerShell release architecture: $machine"
      return 1
      ;;
  esac

  if ! have curl || ! have tar; then
    echo "!! curl and tar are required to install PowerShell."
    return 1
  fi

  asset_url="$(github_latest_asset_url \
    "PowerShell/PowerShell" "powershell-[0-9.]+-linux-${asset_arch}\\.tar\\.gz$" || true)"
  if [[ -z "$asset_url" ]]; then
    echo "!! Could not resolve the latest PowerShell release for $asset_arch."
    return 1
  fi

  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/powershell.tar.gz"
  extracted="$tmp_dir/powershell"
  mkdir -p "$extracted"

  echo "==> Installing PowerShell from upstream release..."
  curl -fL "$asset_url" -o "$archive"
  tar -C "$extracted" -xzf "$archive"
  chmod 0755 "$extracted/pwsh"
  if ! TERM=dumb "$extracted/pwsh" -NoLogo -NoProfile -NonInteractive -Command 'exit 0'; then
    echo "!! PowerShell could not start; its native runtime dependencies may be missing."
    rm -rf "$tmp_dir"
    return 1
  fi

  ensure_local_bin
  install_root="$HOME/.local/opt"
  install_dir="$install_root/powershell"
  bin_link="$HOME/.local/bin/pwsh"
  mkdir -p "$install_root"
  if [[ -e "$install_dir" ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    mv "$install_dir" "${install_dir}.bak.${ts}"
  fi
  mv "$extracted" "$install_dir"
  if [[ -L "$bin_link" ]]; then
    ln -sfn "$install_dir/pwsh" "$bin_link"
  elif [[ -e "$bin_link" ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    mv "$bin_link" "${bin_link}.bak.${ts}"
    ln -s "$install_dir/pwsh" "$bin_link"
  else
    ln -s "$install_dir/pwsh" "$bin_link"
  fi
  rm -rf "$tmp_dir"
  export PATH="$HOME/.local/bin:$PATH"
}

ensure_psscriptanalyzer() {
  if ! have pwsh; then
    echo "!! PowerShell is required to install PSScriptAnalyzer."
    return 1
  fi

  if TERM=dumb pwsh -NoLogo -NoProfile -NonInteractive -Command \
    'if (Get-Module -ListAvailable -Name PSScriptAnalyzer) { exit 0 }; exit 1'; then
    return
  fi

  echo "==> Installing PSScriptAnalyzer for the current user..."
  TERM=dumb pwsh -NoLogo -NoProfile -NonInteractive -Command \
    'Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery -ErrorAction Stop'
}

ensure_powershell_linting() {
  ensure_powershell_release || return
  ensure_psscriptanalyzer
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

ensure_carapace_release() {
  if have carapace; then
    return
  fi

  local machine asset_arch
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) asset_arch="amd64" ;;
    aarch64|arm64) asset_arch="arm64" ;;
    i386|i686) asset_arch="386" ;;
    *)
      echo ">> Unsupported carapace-bin release architecture: $machine"
      return 1
      ;;
  esac

  install_github_release_archive_binary "carapace-bin" "carapace-sh/carapace-bin" "carapace-bin_[0-9.]+_linux_${asset_arch}\\.tar\\.gz$" "carapace"
}

ensure_modern_cli_cargo_tools() {
  ensure_cargo_tool just just
  ensure_cargo_tool hyperfine hyperfine
  ensure_cargo_tool watchexec watchexec-cli
  ensure_cargo_tool atuin atuin
  ensure_cargo_tool difft difftastic difftastic
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
