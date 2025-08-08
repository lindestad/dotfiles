####--------------------------------------------------
#### Basics
####--------------------------------------------------
# Shell options
set -o notify
set -o noclobber
set -o vi        # vi-style keybindings; use 'set -o emacs' if you prefer

# History
HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY INC_APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Editor
export EDITOR=hx
export VISUAL=hx

# Colors
autoload -U colors && colors

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

# Load all available completers (fast & simple)
if command -v carapace >/dev/null 2>&1; then
  source <(carapace _carapace)
fi

# Optional theming
# Use terminal file colors (if set LS_COLORS, e.g. via vivid)
export LS_COLORS="$(vivid generate dracula)"

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
  alias lza='eza --grid --long --icons --group-directories-first'
  alias lzt='eza --tree --long --icons --group-directories-first --git-ignore --git --level=3'
  alias lzta='eza --tree --long --icons --group-directories-first --git --level=3'
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

# ripgrep, fd common flags (optional)
alias rg='rg --hidden --glob "!.git"'
alias fd='fd --hidden --exclude .git'

# Git aliases (mirroring your Nushell ones)
alias gs='git status'
alias ga='git add'
alias "ga."='git add .'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch --all'
alias gbr='git branch --remote'
alias gf='git fetch'
alias gl='git log --oneline --graph'
alias pull='git pull'
alias push='git push'
alias gco='git checkout'
alias co='git checkout'
alias gm='git merge'
alias gcm='git commit -m'
alias gcam='git commit -am'

# gc <message...> (requires a non-empty message)
gc() {
  if (( $# == 0 )); then
    print -u2 "Commit message cannot be empty."
    print -u2 "Usage: gc Add login form"
    return 2
  fi
  git commit -m "$*"
}

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

# Path tweaks (optional)
# export PATH="$HOME/.local/bin:$PATH"

# Quiet login banners from some tools
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
