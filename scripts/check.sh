#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR"

have() {
  command -v "$1" >/dev/null 2>&1
}

step() {
  printf '\n==> %s\n' "$*"
}

skip() {
  printf '>> skipping %s: %s\n' "$1" "$2"
}

shell_files=()
while IFS= read -r -d '' file; do
  shell_files+=("$file")
done < <(
  {
    find . -type f -name '*.sh' -print0
    find bin -maxdepth 1 -type f -print0
  } | sort -zu
)

step "ShellCheck"
if have shellcheck; then
  shellcheck -x "${shell_files[@]}"
  shellcheck --shell=bash --exclude=SC1091 shells/.bashrc
else
  echo "!! shellcheck is required for shell linting."
  exit 1
fi

step "shell syntax"
for file in "${shell_files[@]}"; do
  bash -n "$file"
done
bash -n shells/.bashrc
if have zsh; then
  zsh -n shells/.zshrc
  zsh -n shells/.zprofile
else
  skip "zsh syntax" "zsh is not installed"
fi
if have fish; then
  fish --no-execute shells/config.fish
else
  skip "fish syntax" "fish is not installed"
fi

step "justfile"
if have just; then
  just --summary >/dev/null
else
  skip "justfile parse" "just is not installed"
fi

step "niri config"
if have niri; then
  niri validate -c config/niri/config.kdl
else
  skip "niri validate" "niri is not installed"
fi

step "TOML"
if have taplo; then
  toml_files=()
  while IFS= read -r -d '' file; do
    toml_files+=("$file")
  done < <(find . -type f -name '*.toml' -print0 | sort -z)
  taplo lint --no-auto-config "${toml_files[@]}"
else
  skip "taplo lint" "taplo is not installed"
fi

step "Lua syntax"
if have luac; then
  lua_files=()
  while IFS= read -r -d '' file; do
    lua_files+=("$file")
  done < <(find config/nvim config/yazi -type f -name '*.lua' -print0 | sort -z)
  for file in "${lua_files[@]}"; do
    luac -p "$file"
  done
else
  skip "luac -p" "luac is not installed"
fi

step "PowerShell"
if have pwsh; then
  # shellcheck disable=SC2016
  TERM=dumb pwsh -NoLogo -NoProfile -NonInteractive -Command '
    $module = Get-Module -ListAvailable -Name PSScriptAnalyzer | Select-Object -First 1
    if (-not $module) {
      Write-Host ">> skipping PSScriptAnalyzer: module is not installed"
      exit 0
    }
    $files = Get-ChildItem -Path . -Recurse -File -Filter *.ps1
    $results = @(
      foreach ($file in $files) {
        Invoke-ScriptAnalyzer -Path $file.FullName -Severity Warning,Error
      }
    )
    if ($results.Count -gt 0) {
      $results | Format-Table -AutoSize
      exit 1
    }
  '
else
  skip "PSScriptAnalyzer" "pwsh is not installed"
fi

printf '\n==> check passed\n'
