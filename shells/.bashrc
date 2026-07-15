####--------------------------------------------------
#### Basics
####--------------------------------------------------

# History
HISTFILE="${HOME}/.bash_history"
HISTSIZE=100000
HISTFILESIZE=100000
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend

# Path and prompt config need to exist before tool initialization below.
case ":$PATH:" in
*":$HOME/.cargo/bin:"*) ;;
*) export PATH="$HOME/.cargo/bin:$PATH" ;;
esac
case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) export PATH="$HOME/.local/bin:$PATH" ;;
esac
case ":$PATH:" in
*":$LOCALAPPDATA/Microsoft/WinGet/Links:"*) ;;
*) [ -n "${LOCALAPPDATA:-}" ] && export PATH="$LOCALAPPDATA/Microsoft/WinGet/Links:$PATH" ;;
esac

export STARSHIP_CONFIG="$HOME/.config/starship.toml"
export EDITOR=nvim
export VISUAL=nvim
export LESS='-R'
export LESSHISTFILE=-

# Work around openai/codex#9370-adjacent shifted text loss in
# Windows WezTerm -> WSL. Remove after a known-good Codex release.
# https://github.com/openai/codex/issues/9370
if [ -n "${WSL_INTEROP:-}" ] && [ "${TERM_PROGRAM:-}" = "WezTerm" ] && [ -z "${CODEX_TUI_DISABLE_KEYBOARD_ENHANCEMENT+x}" ]; then
  export CODEX_TUI_DISABLE_KEYBOARD_ENHANCEMENT=1
fi

# Keep desktop and SSH clients pointed at the same Zellij socket namespace.
if [ -z "${ZELLIJ_SOCKET_DIR:-}" ]; then
  _zellij_runtime_dir="/run/user/$(id -u 2>/dev/null)"
  if [ -d "$_zellij_runtime_dir" ]; then
    export ZELLIJ_SOCKET_DIR="$_zellij_runtime_dir/zellij"
  fi
  unset _zellij_runtime_dir
fi

# Yazi requires file.exe on Windows. Git for Windows ships one.
if [ -x "/c/Program Files/Git/usr/bin/file.exe" ]; then
  export YAZI_FILE_ONE="C:/Program Files/Git/usr/bin/file.exe"
fi

####--------------------------------------------------
#### Prompt / tools init
####--------------------------------------------------

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell bash)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init bash)"
fi

####--------------------------------------------------
#### Completion
####--------------------------------------------------

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
export CARAPACE_MATCH=1

# true  = lazy-load carapace on first Tab (faster shell startup)
# false = load carapace eagerly at shell startup
CARAPACE_LAZY=false

if command -v carapace >/dev/null 2>&1; then
  if [ "$CARAPACE_LAZY" = true ]; then
    # Lazy-load carapace on first Tab to keep shell startup fast.
    # The default completion loader sources carapace once, removes itself, then
    # returns 124 so bash retries completion using carapace's registered completers.
    _carapace_lazy_load() {
      complete -r -D 2>/dev/null
      # shellcheck disable=SC1090
      source <(carapace _carapace)
      return 124
    }
    complete -D -F _carapace_lazy_load
  else
    # shellcheck disable=SC1090
    source <(carapace _carapace)
  fi
elif [ -f /etc/bash_completion ]; then
  # shellcheck disable=SC1091
  source /etc/bash_completion
fi

if [ -f /usr/share/git/completion/git-completion.bash ]; then
  # shellcheck disable=SC1091
  source /usr/share/git/completion/git-completion.bash
elif [ -f /etc/bash_completion.d/git ]; then
  # shellcheck disable=SC1091
  source /etc/bash_completion.d/git
fi

####--------------------------------------------------
#### Broot launcher
####--------------------------------------------------

if [ -f "$HOME/.config/broot/launcher/bash/br" ]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/broot/launcher/bash/br"
elif command -v broot >/dev/null 2>&1; then
  br() {
    local cmd_file code
    cmd_file="$(mktemp)" || return
    broot --outcmd "$cmd_file" "$@"
    code=$?
    if [ -s "$cmd_file" ]; then
      # shellcheck disable=SC1090
      source "$cmd_file"
    fi
    rm -f "$cmd_file"
    return "$code"
  }
fi

####--------------------------------------------------
#### Aliases & functions
####--------------------------------------------------

# ls -> eza
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons'
  alias lsa='eza --all --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
  alias lt='eza --tree --git-ignore --level=2 --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
  alias lta='eza --tree --level=2 --all --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
  alias ll='eza -l --group-directories-first --icons'
  alias la='eza -la --group-directories-first --icons'
  alias tree='eza --tree --level=5'
  alias lz='eza --grid --long --icons --group-directories-first --git-ignore'
  alias lza='eza -a --grid --long --icons --group-directories-first'
  alias lzt='eza --tree --long --icons --group-directories-first --git-ignore --git --level=3'
  alias lzta='eza -a --tree --long --icons --group-directories-first --git --level=3'
fi

if command -v bat >/dev/null 2>&1; then
  alias b='bat --style numbers,grid'
  alias cat='bat --plain'
fi

# Opencode, codex
alias oc='opencode'
# alias ocr='opencode resume' ->TODO Need to PR a fix, there is --continue but does not put you into the picker like codex
alias cx='codex'
alias cxr='codex resume'

# helix
if ! command -v hx >/dev/null 2>&1 && command -v helix >/dev/null 2>&1; then
  alias hx='helix'
fi
alias h='hx'
alias n='nvim'

alias rg='rg --hidden --glob "!.git"'
alias fd='fd --hidden --exclude .git'
alias svenv='source .venv/bin/activate'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Zellij session shortcuts
alias zj='zellij'

zp() {
  local session_name="${1:-${ZELLIJ_PERSISTENT_SESSION:-work}}"
  zellij attach --create "$session_name"
}

zd() {
  local session_name="${1:-dev-$(date +%Y%m%d-%H%M%S)}"
  zellij --session "$session_name" --new-session-with-layout dev
}

zleft() {
  local session_name="${1:-zleft-$(date +%Y%m%d-%H%M%S)}"
  zellij --session "$session_name" --new-session-with-layout zleft
}

zdclean() {
  local days="${1:-14}"
  case "$days" in
  '' | *[!0-9]*)
    echo "usage: zdclean [days]"
    return 2
    ;;
  esac

  local session_info_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zellij/contract_version_1/session_info"
  [ -d "$session_info_dir" ] || return 0

  find "$session_info_dir" -mindepth 2 -maxdepth 2 -type f \
    -path "*/dev-*/session-metadata.kdl" -mtime +"$days" \
    -exec sh -c '
      for metadata; do
        session_name=$(basename "$(dirname "$metadata")")
        zellij delete-session "$session_name"
      done
    ' sh {} +
}

# git aliases
alias gs='git status'
ga() {
  if [ "$#" -eq 0 ]; then
    git add --all
  else
    git add "$@"
  fi
}
alias ga.='git add .'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch --all'
alias gbr='git branch --remote'
alias gw='git worktree'
alias gwl='git worktree list'
alias gwa='git worktree add'
alias gwr='git worktree remove'
alias gwp='git worktree prune'
alias gd='git diff'
alias gdc='git diff --cached'
alias gds='git diff --staged'
alias gdh='git diff HEAD'
alias gf='git fetch'
alias gl='git log --oneline --graph'
alias gr='git rebase'
alias gri='git rebase -i'
alias pull='git pull'
alias push='git push'
alias gco='git checkout'
alias co='git checkout'
alias gm='git merge'
gc() {
  if [ "$#" -eq 0 ]; then
    git commit
  elif [ "$#" -eq 1 ] && [ "${1#-}" = "$1" ]; then
    git commit -m "$1"
  elif [ "${1#-}" = "$1" ]; then
    echo 'gc: quote multi-word commit messages, e.g. gc "my commit message"' >&2
    return 2
  else
    git commit "$@"
  fi
}
gac() {
  git add --all || return
  gc "$@"
}
alias gcm='git commit -m'
alias gcam='git commit -am'
alias gsh='git show HEAD'
gdd() {
  git -c diff.external=difft diff --ext-diff "$@"
}
gdds() {
  git -c diff.external=difft diff --ext-diff --staged "$@"
}
gddh() {
  git -c diff.external=difft diff --ext-diff HEAD "$@"
}
gshd() {
  local rev="${1:-HEAD}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  git -c diff.external=difft show --ext-diff --decorate --format=medium --stat --patch "$rev" -- "$@"
}
gsd() {
  if [ "$#" -eq 0 ]; then
    echo "usage: gsd <commit|range> [commit|range ...]" >&2
    return 2
  fi

  git -c diff.external=difft show --ext-diff --decorate --format=medium --stat --patch "$@"
}
gld() {
  git -c diff.external=difft log --ext-diff -p "$@"
}

y() {
  local tmp newdir
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return
  yazi "$@" --cwd-file="$tmp"
  if [ -s "$tmp" ]; then
    newdir="$(cat "$tmp")"
    if [ -n "$newdir" ] && [ -d "$newdir" ]; then
      cd "$newdir" || return
    fi
  fi
  rm -f "$tmp"
}
