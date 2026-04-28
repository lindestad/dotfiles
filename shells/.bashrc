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
export EDITOR=hx
export VISUAL=hx
export LESS='-R'
export LESSHISTFILE=-

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

####--------------------------------------------------
#### Completion
####--------------------------------------------------

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'

if command -v carapace >/dev/null 2>&1; then
  # shellcheck disable=SC1090
  source <(carapace _carapace)
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
#### Aliases & functions
####--------------------------------------------------

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

if command -v bat >/dev/null 2>&1; then
  alias b='bat --style numbers,grid'
  alias cat='bat --plain'
fi

if ! command -v hx >/dev/null 2>&1 && command -v helix >/dev/null 2>&1; then
  alias hx='helix'
fi

alias rg='rg --hidden --glob "!.git"'
alias fd='fd --hidden --exclude .git'

alias gs='git status'
alias ga='git add'
alias ga.='git add .'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch --all'
alias gbr='git branch --remote'
alias gd='git diff'
alias gdc='git diff --cached'
alias gf='git fetch'
alias gl='git log --oneline --graph'
alias gr='git rebase'
alias gri='git rebase -i'
alias pull='git pull'
alias push='git push'
alias gco='git checkout'
alias co='git checkout'
alias gm='git merge'
alias gcm='git commit -m'
alias gcam='git commit -am'

gc() {
  if [ "$#" -eq 0 ]; then
    git commit
  else
    git commit -m "$*"
  fi
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
