#!/usr/bin/env bash
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR" || exit

have() {
  command -v "$1" >/dev/null 2>&1
}

red=""
green=""
yellow=""
reset=""
if [[ -t 1 && ${TERM:-dumb} != dumb && -z ${NO_COLOR+x} ]]; then
  red=$'\e[31m'
  green=$'\e[32m'
  yellow=$'\e[33m'
  reset=$'\e[0m'
fi

passed=0
failed=0
skipped=0
check_index=0
check_tmp_dir="$(mktemp -d -t dotfiles-check.XXXXXX)"
trap 'rm -rf -- "$check_tmp_dir"' EXIT

status_line() {
  local color=$1
  local status=$2
  local label=$3
  printf '%s%s %s%s\n' "$color" "$status" "$label" "$reset"
}

run_check() {
  local label=$1
  shift

  local output="$check_tmp_dir/$check_index.log"
  ((check_index += 1))

  local exit_status
  "$@" >"$output" 2>&1
  exit_status=$?

  if ((exit_status == 0)); then
    ((passed += 1))
    status_line "$green" PASS "$label"
    return
  fi

  ((failed += 1))
  status_line "$red" FAIL "$label"
  if [[ -s $output ]]; then
    sed 's/^/  /' "$output"
  fi
  printf '  exit status: %d\n' "$exit_status"
}

skip_check() {
  local label=$1
  local reason=$2
  ((skipped += 1))
  status_line "$yellow" SKIP "$label — $reason"
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

check_shellcheck() {
  if ! have shellcheck; then
    echo "shellcheck is required for shell linting"
    return 127
  fi

  shellcheck -x "${shell_files[@]}" || return
  shellcheck --shell=bash --exclude=SC1091 shells/.bashrc
}

check_bash_syntax() {
  local file
  for file in "${shell_files[@]}"; do
    bash -n "$file" || return
  done
  bash -n shells/.bashrc
}

check_zsh_syntax() {
  zsh -n shells/.zshrc || return
  zsh -n shells/.zprofile
}

check_fish_syntax() {
  fish --no-execute shells/config.fish
}

check_justfile() {
  just --summary
}

check_niri_config() {
  niri validate -c config/niri/config.kdl
}

check_niri_zvim_config() {
  if have niri-zvim; then
    NIRI_ZVIM_CONFIG="$DOTFILES_DIR/config/niri-zvim/config.json" \
      niri-zvim config check
  else
    jq --exit-status 'type == "object"' config/niri-zvim/config.json >/dev/null
  fi
}

check_toml() {
  local toml_files=()
  while IFS= read -r -d '' file; do
    toml_files+=("$file")
  done < <(find . -type f -name '*.toml' -print0 | sort -z)
  taplo lint --no-auto-config "${toml_files[@]}"
}

check_lua_lint() {
  (cd config/nvim && selene .) || return
  (cd config/yazi && selene .)
}

check_lua_format() {
  (cd config/nvim && stylua --check .) || return
  (cd config/yazi && stylua --check .)
}

have_powershell_analyzer() {
  TERM=dumb pwsh -NoLogo -NoProfile -NonInteractive -Command '
    if (Get-Module -ListAvailable -Name PSScriptAnalyzer | Select-Object -First 1) {
      exit 0
    }
    exit 1
  ' >/dev/null 2>&1
}

check_powershell() {
  # shellcheck disable=SC2016
  TERM=dumb pwsh -NoLogo -NoProfile -NonInteractive -Command '
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
}

run_check "ShellCheck" check_shellcheck
run_check "Bash syntax" check_bash_syntax

if have zsh; then
  run_check "Zsh syntax" check_zsh_syntax
else
  skip_check "Zsh syntax" "zsh is not installed"
fi

if have fish; then
  run_check "Fish syntax" check_fish_syntax
else
  skip_check "Fish syntax" "fish is not installed"
fi

if have just; then
  run_check "Justfile" check_justfile
else
  skip_check "Justfile" "just is not installed"
fi

if have niri; then
  run_check "Niri config" check_niri_config
else
  skip_check "Niri config" "niri is not installed"
fi

if have niri-zvim || have jq; then
  run_check "niri-zvim config" check_niri_zvim_config
else
  skip_check "niri-zvim config" "niri-zvim and jq are not installed"
fi

if have taplo; then
  run_check "TOML" check_toml
else
  skip_check "TOML" "taplo is not installed"
fi

if have selene; then
  run_check "Lua lint" check_lua_lint
else
  skip_check "Lua lint" "selene is not installed"
fi

if have stylua; then
  run_check "Lua format" check_lua_format
else
  skip_check "Lua format" "stylua is not installed"
fi

if ! have pwsh; then
  skip_check "PowerShell" "pwsh is not installed"
elif ! have_powershell_analyzer; then
  skip_check "PowerShell" "PSScriptAnalyzer is not installed"
else
  run_check "PowerShell" check_powershell
fi

printf '\n'
if ((failed > 0)); then
  status_line "$red" FAIL "$passed passed, $failed failed, $skipped skipped"
  exit 1
fi

status_line "$green" PASS "$passed checks, $skipped skipped"
