####--------------------------------------------------
#### Basics
####--------------------------------------------------
# Shell options
set -o notify
set -o noclobber
bindkey -e               # emacs line-editing (default); explicit so vi mode stays off

# Custom keybindings
bindkey '^H' backward-char          # Ctrl-H → move cursor left
bindkey '^L' forward-char           # Ctrl-L → move cursor right
                                    # (Ctrl-L no longer clears screen; use 'clear' if needed)
# Ctrl-Backspace → delete word behind cursor.
# WezTerm sends \x1b\x7f (Alt-Backspace), which emacs mode maps to backward-kill-word
# and passes through Zellij without KKP negotiation.
# Ghostty sends the KKP sequence \e[127;5u, so bind that too.
bindkey '\e[127;5u' backward-kill-word

# Zellij (0.44.x) leaks OSC 4 color-palette query responses into the first
# pane's stdin at startup (issue #5174, unfixed). Drain any pending bytes
# before the interactive prompt takes over.
if [[ -n "$ZELLIJ" ]]; then
  while read -t 0.1 -r -s _zellij_drain 2>/dev/null; do :; done
  unset _zellij_drain
fi

# History
HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY INC_APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Path and prompt config need to exist before tool initialization below.
export PATH="$HOME/go/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Keep desktop and SSH clients pointed at the same Zellij socket namespace.
if [ -z "${ZELLIJ_SOCKET_DIR:-}" ]; then
  _zellij_runtime_dir="/run/user/$(id -u 2>/dev/null)"
  if [ -d "$_zellij_runtime_dir" ]; then
    export ZELLIJ_SOCKET_DIR="$_zellij_runtime_dir/zellij"
  fi
  unset _zellij_runtime_dir
fi

# Editor
export EDITOR=hx
export VISUAL=hx

# Colors
autoload -U colors && colors
# Advertise 24-bit color so apps like Helix render true-color themes (WSL/Windows Terminal don't set this).
export COLORTERM=truecolor

# Work around openai/codex#9370-adjacent shifted text loss in
# Windows WezTerm -> WSL. Remove after a known-good Codex release.
# https://github.com/openai/codex/issues/9370
if [ -n "${WSL_INTEROP:-}" ] && [ "${TERM_PROGRAM:-}" = "WezTerm" ] && [ -z "${CODEX_TUI_DISABLE_KEYBOARD_ENHANCEMENT+x}" ]; then
  export CODEX_TUI_DISABLE_KEYBOARD_ENHANCEMENT=1
fi

####--------------------------------------------------
#### Prompt / tools init
####--------------------------------------------------
# Starship
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# zoxide (better cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# fzf keybindings + completion (installed via pacman)
if [ -f /usr/share/fzf/key-bindings.zsh ]; then
  source /usr/share/fzf/key-bindings.zsh
fi
if [ -f /usr/share/fzf/completion.zsh ]; then
  source /usr/share/fzf/completion.zsh
fi

# Show ~10 history entries inline rather than full-screen; prompt at top.
export FZF_CTRL_R_OPTS="--height=~40% --layout=reverse --preview-window=hidden"

####--------------------------------------------------
#### Completion (native Zsh)
####--------------------------------------------------
autoload -Uz compinit
# speed up compinit by caching
if [ -n "$ZDOTDIR" ]; then _zcachedir="$ZDOTDIR"; else _zcachedir="$HOME"; fi
if [ ! -d "$_zcachedir/.zcompcache" ]; then mkdir -p "$_zcachedir/.zcompcache"; fi
compinit -d "$_zcachedir/.zcompcache/zcompdump"

# Completion styles (sane defaults)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=** r:|=**'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{blue}%d%f'
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands

####--------------------------------------------------
#### Carapace (cross-shell completions)
####--------------------------------------------------
# let carapace reuse other shells' completion data when helpful
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'

# true  = lazy-load carapace on first Tab (faster shell startup)
# false = load carapace eagerly at shell startup
CARAPACE_LAZY=false

if command -v carapace >/dev/null 2>&1; then
  if [[ "$CARAPACE_LAZY" == true ]]; then
    # Lazy-load all available completers on first Tab to keep shell startup fast.
    # Remember the current Tab binding (e.g. fzf-completion) so we can chain to it
    # after carapace is loaded.
    _carapace_tab_fallback="${${(z)$(bindkey '^I')}[-1]}"
    case "$_carapace_tab_fallback" in
      ''|undefined-key|_carapace_lazy_widget) _carapace_tab_fallback=expand-or-complete ;;
    esac

    _carapace_lazy_widget() {
      bindkey '^I' "$_carapace_tab_fallback"
      source <(carapace _carapace)
      zle "$_carapace_tab_fallback"
    }
    zle -N _carapace_lazy_widget
    bindkey '^I' _carapace_lazy_widget
  else
    source <(carapace _carapace)
  fi
fi

# Optional theming
# Use terminal file colors (if set LS_COLORS, e.g. via vivid)
if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS="$(vivid generate dracula)"
fi

# Style specific elements in the completion UI (examples)
# carapace --style 'carapace.Value=bold,magenta'
# carapace --style 'carapace.Description='

####--------------------------------------------------
#### Aliases & functions
####--------------------------------------------------

# pacman
alias sps='sudo pacman -S'

# Safe ls → eza (fallback to ls if eza missing)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons'
  alias ll='eza -l --group-directories-first --icons'
  alias la='eza -la --group-directories-first --icons'
  alias tree='eza --tree --level=5'
  alias lz='eza --grid --long --icons --group-directories-first --git-ignore'
  alias lza='eza -a --grid --long --icons --group-directories-first'
  alias lzt='eza --tree --long --icons --group-directories-first --git-ignore --git --level=3'
  alias lzta='eza -a --tree --long --icons --group-directories-first --git --level=3'
fi

# bat as cat (fallback to cat)
if command -v bat >/dev/null 2>&1; then
  alias b='bat --style numbers,grid'
  alias cat='bat --plain'
fi

# helix installed as 'helix' not hx?
if command -v helix >/dev/null 2>&1; then
  alias hx='helix'
fi
alias h='hx'
alias n='nvim'

# ripgrep, fd common flags (optional)
alias rg='rg --hidden --glob "!.git"'
alias fd='fd --hidden --exclude .git'
alias svenv='source .venv/bin/activate'

# Zellij session shortcuts
zp() {
  local session_name="${1:-${ZELLIJ_PERSISTENT_SESSION:-work}}"
  zellij attach --create "$session_name"
}

zd() {
  local session_name="${1:-dev-$(date +%Y%m%d-%H%M%S)}"
  zellij --session "$session_name" --new-session-with-layout dev
}

zdclean() {
  local days="${1:-14}"
  case "$days" in
    ''|*[!0-9]*)
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

# Git aliases
alias gs='git status'
alias ga='git add'
alias "ga."='git add .'
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
alias gc='git commit'
alias gcm='git commit -m'
alias gcam='git commit -am'
alias gsh='git show HEAD'

####--------------------------------------------------
#### Yazi wrapper: cd to last dir on exit
####--------------------------------------------------
y() {
  local tmp
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return
  yazi --cwd-file="$tmp" "$@"
  if [ -s "$tmp" ]; then
    local newdir
    newdir="$(cat "$tmp")"
    if [ -n "$newdir" ] && [ -d "$newdir" ]; then
      cd "$newdir" || true
    fi
  fi
  rm -f "$tmp"
}

####--------------------------------------------------
#### Misc quality-of-life
####--------------------------------------------------
# Better grep colors
export GREP_OPTIONS=
export GREP_COLOR='1;32'

# Less with colors
export LESS='-R'
export LESSHISTFILE=-

# fnm (Fast Node Manager)
export PATH="$HOME/.local/share/fnm:$PATH"

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

####--------------------------------------------------
#### Host-local additions
####--------------------------------------------------
# Machine-specific exports belong here instead of in the shared dotfiles repo.
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
