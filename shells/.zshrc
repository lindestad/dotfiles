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
# Ghostty is configured to send the same sequence for Ctrl-Backspace.
bindkey '\e\x7f' backward-kill-word
# Some terminals can send the KKP sequence for Ctrl-Backspace, so bind that too.
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
export EDITOR=nvim
export VISUAL=nvim

# Colors
autoload -U colors && colors
# Advertise 24-bit color so apps like Helix render true-color themes (WSL/Windows Terminal don't set this).
export COLORTERM=truecolor

####--------------------------------------------------
#### Prompt / tools init
####--------------------------------------------------
# Starship
if command -v starship >/dev/null 2>&1; then
  typeset -g +x DOTFILES_STARSHIP_RIGHT_START='__DOTFILES_STARSHIP_RIGHT_START__'
  typeset -g +x DOTFILES_STARSHIP_DURATION_START='__DOTFILES_STARSHIP_DURATION_START__'
  typeset -g +x DOTFILES_STARSHIP_MEMORY_START='__DOTFILES_STARSHIP_MEMORY_START__'
  typeset -g +x DOTFILES_STARSHIP_TIME_START='__DOTFILES_STARSHIP_TIME_START__'
  typeset -g +x DOTFILES_STARSHIP_RIGHT_END='__DOTFILES_STARSHIP_RIGHT_END__'

  eval "$(starship init zsh)"

  # Ask Zsh how many terminal columns a rendered prompt fragment occupies.
  # This handles prompt escapes and wide glyphs more accurately than ${#value}.
  _dotfiles_prompt_length() {
    emulate -L zsh
    local -i COLUMNS=$(( ${#1} * 2 + 2 ))
    local -i x=0 y=${#1} midpoint

    if (( y )); then
      while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
        x=$y
        (( y *= 2 ))
      done

      while (( y > x + 1 )); do
        (( midpoint = x + (y - x) / 2 ))
        (( ${${(%):-$1%$midpoint(l.x.y)}[-1]} = midpoint ))
      done
    fi

    REPLY=$x
  }

  # Keep the left side intact. When the first prompt line is too wide, remove
  # RAM first, then the clock, and finally the command duration if necessary.
  _dotfiles_starship_prompt() {
    emulate -L zsh
    local rendered remainder left duration memory timestamp suffix
    local right padding=''
    local -i left_width right_width gap columns=${COLUMNS:-80}

    rendered="$(
      export DOTFILES_STARSHIP_RIGHT_START DOTFILES_STARSHIP_DURATION_START
      export DOTFILES_STARSHIP_MEMORY_START DOTFILES_STARSHIP_TIME_START
      export DOTFILES_STARSHIP_RIGHT_END
      command starship prompt "$@"
    )" || {
      print -rn -- "$rendered"
      return
    }

    if [[ $rendered != *$DOTFILES_STARSHIP_RIGHT_START* ||
          $rendered != *$DOTFILES_STARSHIP_RIGHT_END* ]]; then
      print -rn -- "$rendered"
      return
    fi

    left=${rendered%%${DOTFILES_STARSHIP_RIGHT_START}*}
    remainder=${rendered#*${DOTFILES_STARSHIP_RIGHT_START}}
    remainder=${remainder#*${DOTFILES_STARSHIP_DURATION_START}}
    duration=${remainder%%${DOTFILES_STARSHIP_MEMORY_START}*}
    remainder=${remainder#*${DOTFILES_STARSHIP_MEMORY_START}}
    memory=${remainder%%${DOTFILES_STARSHIP_TIME_START}*}
    remainder=${remainder#*${DOTFILES_STARSHIP_TIME_START}}
    timestamp=${remainder%%${DOTFILES_STARSHIP_RIGHT_END}*}
    suffix=${remainder#*${DOTFILES_STARSHIP_RIGHT_END}}

    _dotfiles_prompt_length "$left"
    left_width=$REPLY

    for right in "$duration$memory$timestamp" "$duration$timestamp" "${duration% }" ''; do
      _dotfiles_prompt_length "$right"
      right_width=$REPLY
      (( left_width + right_width <= columns )) && break
    done

    (( gap = columns - left_width - right_width ))
    if (( gap > 0 )); then
      printf -v padding '%*s' $gap ''
    fi

    print -rn -- "$left$padding$right$suffix"
  }

  PROMPT='$(_dotfiles_starship_prompt --terminal-width="$COLUMNS" --keymap="${KEYMAP:-}" --status="${STARSHIP_CMD_STATUS:-}" --pipestatus="${STARSHIP_PIPE_STATUS[*]:-}" --cmd-duration="${STARSHIP_DURATION:-}" --jobs="$STARSHIP_JOBS_COUNT")'
fi

# zoxide (better cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
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

# Atuin history
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
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

####--------------------------------------------------
#### Zellij completions
####--------------------------------------------------
_zellij_session_names() {
  local -a sessions
  sessions=("${(@f)$(zellij list-sessions --short --no-formatting 2>/dev/null)}")
  (( ${#sessions} )) && compadd "$@" -a sessions
}

_zellij_session_command() {
  _arguments \
    '(-h --help)'{-h,--help}'[Print help information]' \
    '1:session:_zellij_session_names'
}

_zellij_attach() {
  _arguments \
    '(-c --create)'{-c,--create}'[Create session if it does not exist]' \
    '(-b --create-background)'{-b,--create-background}'[Create detached session in the background if it does not exist]' \
    '(-f --force-run-commands)'{-f,--force-run-commands}'[Run resurrected session commands immediately]' \
    '(-r --remember)'{-r,--remember}'[Save session for automatic re-authentication]' \
    '--forget[Delete saved session before connecting]' \
    '--insecure[Skip TLS certificate validation]' \
    '--index=[Attach by session index]:index:' \
    '(-t --token)'{-t+,--token=}'[Authentication token for remote sessions]:token:' \
    '--ca-cert=[Path to a custom CA certificate]:file:_files' \
    '1:session:_zellij_session_names'
}

_zellij() {
  local -a commands
  commands=(
    'attach:Attach to a session'
    'a:Attach to a session'
    'list-sessions:List sessions'
    'ls:List sessions'
    'watch:Watch a session'
    'w:Watch a session'
    'kill-session:Kill a session'
    'k:Kill a session'
    'delete-session:Delete a session'
    'd:Delete a session'
  )

  case "$words[2]" in
    attach|a)
      words=("${(@)words[2,-1]}")
      (( CURRENT-- ))
      _zellij_attach
      ;;
    watch|w|kill-session|k|delete-session|d)
      words=("${(@)words[2,-1]}")
      (( CURRENT-- ))
      _zellij_session_command
      ;;
    *)
      if (( CURRENT == 2 )); then
        _describe -t commands 'zellij command' commands
      fi
      ;;
  esac
}

compdef _zellij zellij zj
compdef _zellij_session_names zp

# Optional theming
# Use terminal file colors (if set LS_COLORS, e.g. via vivid)
if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS="$(vivid generate dracula)"
fi

# Style specific elements in the completion UI (examples)
# carapace --style 'carapace.Value=bold,magenta'
# carapace --style 'carapace.Description='

####--------------------------------------------------
#### Broot launcher
####--------------------------------------------------
if [ -f "$HOME/.config/broot/launcher/zsh/br" ]; then
  source "$HOME/.config/broot/launcher/zsh/br"
elif command -v broot >/dev/null 2>&1; then
  br() {
    local cmd_file code
    cmd_file="$(mktemp)" || return
    broot --outcmd "$cmd_file" "$@"
    code=$?
    if [ -s "$cmd_file" ]; then
      source "$cmd_file"
    fi
    rm -f "$cmd_file"
    return "$code"
  }
fi

####--------------------------------------------------
#### Aliases & functions
####--------------------------------------------------

# pacman
alias sps='sudo pacman -S'

# Safe ls → eza (fallback to ls if eza missing)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
  alias lsa='eza --all --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto' 
  alias lt='eza --tree --git-ignore --level=2 --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
  alias lta='eza --tree --level=2 --all --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
  alias ll='eza -l --group-directories-first --icons'
  alias la='eza --all --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
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
ga() {
  if [ "$#" -eq 0 ]; then
    git add --all
  else
    git add "$@"
  fi
}
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

####--------------------------------------------------
#### Syntax highlighting
####--------------------------------------------------
# zsh-patina needs to activate last so it sees the final ZLE setup.
command -v zsh-patina >/dev/null 2>&1 && eval "$(zsh-patina activate)"
