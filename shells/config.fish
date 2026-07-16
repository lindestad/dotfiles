####--------------------------------------------------
#### Environment
####--------------------------------------------------

# config.fish is read by every Fish process, unlike .zshrc. Keep exported
# environment available to non-interactive commands and guard UI setup below.
# Modify PATH directly instead of creating persistent universal variables.
fish_add_path --path --prepend --move \
    "$HOME/.local/share/fnm" \
    "$HOME/go/bin" \
    "$HOME/.cargo/bin"

# Match .zprofile: user-installed executables should be available to login
# sessions without shadowing system commands.
fish_add_path --path --append --move "$HOME/.local/bin"

set -gx STARSHIP_CONFIG "$HOME/.config/starship/fish.toml"
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx COLORTERM truecolor

# Keep desktop and SSH clients pointed at the same Zellij socket namespace.
if not set -q ZELLIJ_SOCKET_DIR; or test -z "$ZELLIJ_SOCKET_DIR"
    set -l _zellij_runtime_dir "/run/user/"(id -u 2>/dev/null)
    if test -d "$_zellij_runtime_dir"
        set -gx ZELLIJ_SOCKET_DIR "$_zellij_runtime_dir/zellij"
    end
end

# Better grep colors.
set -gx GREP_OPTIONS ''
set -gx GREP_COLOR '1;32'

# Less with colors and no history file.
set -gx LESS -R
set -gx LESSHISTFILE -

if not status is-interactive
    return
end

####--------------------------------------------------
#### Interactive basics
####--------------------------------------------------

# Fish already provides job notifications, duplicate-free history, leading-space
# history suppression, autosuggestions, syntax highlighting, and an interactive
# completion pager. It manages its own history size, so the Zsh history limits
# have no direct Fish equivalent.
set -g fish_greeting
set -g fish_key_bindings fish_default_key_bindings

# Match zsh-patina's Tokyo Night palette using Fish's native highlighting.
set -g fish_color_normal --reset
set -g fish_color_command 7dcfff
set -g fish_color_keyword 7aa2f7
set -g fish_color_quote 9ece6a
set -g fish_color_redirection 7aa2f7
set -g fish_color_end 7aa2f7
set -g fish_color_error f7768e
set -g fish_color_param --reset
set -g fish_color_option bb9af7
set -g fish_color_comment 9ca3b3
set -g fish_color_operator 7aa2f7
set -g fish_color_escape e6c384
set -g fish_color_autosuggestion 686868
set -g fish_color_valid_path --underline

# Fish has no global `noclobber` mode. Use `>?file` when a redirection must fail
# rather than overwrite an existing file.

# Match Zsh's shared history visibility. Atuin remains the primary search UI.
function __dotfiles_merge_history --on-event fish_prompt
    history merge
end

# Zellij (0.44.x) leaks OSC 4 color-palette query responses into the first
# pane's stdin at startup (issue #5174, unfixed). Drain any pending bytes before
# the interactive prompt takes over.
if set -q ZELLIJ
    while read --silent --nchars=1 --timeout=0.1 _zellij_drain 2>/dev/null
    end
end

####--------------------------------------------------
#### Prompt / tools init
####--------------------------------------------------

if command -q starship
    starship init fish | source

    # Keep the first prompt line intact. As space gets tight, remove RAM first,
    # then the clock, and finally command duration. Fish measures ANSI escapes
    # and wide glyphs natively, so padding matches the terminal's actual width.
    function __dotfiles_starship_prompt
        set -lx DOTFILES_STARSHIP_RIGHT_START __DOTFILES_STARSHIP_RIGHT_START__
        set -lx DOTFILES_STARSHIP_DURATION_START __DOTFILES_STARSHIP_DURATION_START__
        set -lx DOTFILES_STARSHIP_MEMORY_START __DOTFILES_STARSHIP_MEMORY_START__
        set -lx DOTFILES_STARSHIP_TIME_START __DOTFILES_STARSHIP_TIME_START__
        set -lx DOTFILES_STARSHIP_RIGHT_END __DOTFILES_STARSHIP_RIGHT_END__

        set -l rendered (command starship prompt $argv | string collect)
        if test $status -ne 0
            printf '%s' "$rendered"
            return
        end

        for marker in \
            "$DOTFILES_STARSHIP_RIGHT_START" \
            "$DOTFILES_STARSHIP_DURATION_START" \
            "$DOTFILES_STARSHIP_MEMORY_START" \
            "$DOTFILES_STARSHIP_TIME_START" \
            "$DOTFILES_STARSHIP_RIGHT_END"
            if not string match --quiet -- "*$marker*" "$rendered"
                printf '%s' "$rendered"
                return
            end
        end

        set -l parts (string split --max 1 "$DOTFILES_STARSHIP_RIGHT_START" "$rendered")
        set -l left "$parts[1]"
        set -l remainder "$parts[2]"

        set parts (string split --max 1 "$DOTFILES_STARSHIP_DURATION_START" "$remainder")
        set remainder "$parts[2]"
        set parts (string split --max 1 "$DOTFILES_STARSHIP_MEMORY_START" "$remainder")
        set -l duration "$parts[1]"
        set remainder "$parts[2]"
        set parts (string split --max 1 "$DOTFILES_STARSHIP_TIME_START" "$remainder")
        set -l memory "$parts[1]"
        set remainder "$parts[2]"
        set parts (string split --max 1 "$DOTFILES_STARSHIP_RIGHT_END" "$remainder")
        set -l timestamp "$parts[1]"
        set -l suffix "$parts[2]"

        set -l left_width (string length --visible "$left")
        set -l right
        set -l right_width 0
        set -l duration_only (string trim --right "$duration")
        for candidate in \
            "$duration$memory$timestamp" \
            "$duration$timestamp" \
            "$duration_only" \
            ''
            set right "$candidate"
            set right_width (string length --visible "$right")
            if test (math "$left_width + $right_width") -le "$COLUMNS"
                break
            end
        end

        set -l gap (math "$COLUMNS - $left_width - $right_width")
        set -l padding
        if test "$gap" -gt 0
            set padding (string repeat --count "$gap" ' ')
        end

        printf '%s' "$left$padding$right$suffix"
    end

    # Starship's generated function captures command state before rendering.
    # Mirror that entry point and substitute only the normal prompt renderer.
    function fish_prompt
        set STARSHIP_CMD_PIPESTATUS $pipestatus
        set STARSHIP_CMD_STATUS $status
        set STARSHIP_DURATION "$CMD_DURATION$cmd_duration"

        switch "$fish_key_bindings"
            case fish_hybrid_key_bindings fish_vi_key_bindings fish_helix_key_bindings
                set STARSHIP_KEYMAP "$fish_bind_mode"
            case '*'
                set STARSHIP_KEYMAP insert
        end

        __starship_set_job_count

        if contains -- --final-rendering $argv; or test "$TRANSIENT" = 1
            if test "$TRANSIENT" = 1
                set -g TRANSIENT 0
                printf '\e[0J'
            end
            if type -q starship_transient_prompt_func
                starship_transient_prompt_func \
                    --terminal-width="$COLUMNS" \
                    --status="$STARSHIP_CMD_STATUS" \
                    --pipestatus="$STARSHIP_CMD_PIPESTATUS" \
                    --keymap="$STARSHIP_KEYMAP" \
                    --cmd-duration="$STARSHIP_DURATION" \
                    --jobs="$STARSHIP_JOBS"
            else
                printf '\e[1;32m❯\e[0m '
            end
        else
            __dotfiles_starship_prompt \
                --terminal-width="$COLUMNS" \
                --status="$STARSHIP_CMD_STATUS" \
                --pipestatus="$STARSHIP_CMD_PIPESTATUS" \
                --keymap="$STARSHIP_KEYMAP" \
                --cmd-duration="$STARSHIP_DURATION" \
                --jobs="$STARSHIP_JOBS"
        end
    end

    # right_format is intentionally empty; alignment lives on the first line.
    function fish_right_prompt
    end
end

if command -q zoxide
    zoxide init fish | source
end

if command -q direnv
    direnv hook fish | source
end

if command -q atuin
    atuin init fish | source
end

if command -q fnm
    fnm env --use-on-cd --shell fish | source
end

####--------------------------------------------------
#### Keybindings
####--------------------------------------------------

# Keep Emacs-style bindings and preserve the custom Zsh shortcuts. Fish 4's
# named-key syntax covers both the terminal's Alt-Backspace fallback and KKP's
# distinct Ctrl-Backspace sequence.
bind ctrl-h backward-char
bind ctrl-l forward-char
bind alt-backspace backward-kill-word
bind ctrl-backspace backward-kill-word

# Cycle native command history without opening Atuin's search interface.
bind ctrl-k up-or-search
bind ctrl-j down-or-search

####--------------------------------------------------
#### Completion (native Fish)
####--------------------------------------------------

# Fish completion is already case-insensitive, fuzzy, described, searchable,
# and syntax-aware. This replaces compinit, matcher-list, Carapace, and the Zsh
# completion menu configuration.

function __dotfiles_zellij_sessions
    command zellij list-sessions --short --no-formatting 2>/dev/null
end

# Retain the focused subcommand and dynamic session-name completion added by the
# custom Zsh completer without loading Carapace's broader completion database.
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments attach --description 'Attach to a session'
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments a --description 'Attach to a session'
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments list-sessions --description 'List sessions'
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments ls --description 'List sessions'
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments watch --description 'Watch a session'
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments w --description 'Watch a session'
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments kill-session --description 'Kill a session'
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments k --description 'Kill a session'
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments delete-session --description 'Delete a session'
complete --command zellij --condition __fish_use_subcommand --no-files \
    --arguments d --description 'Delete a session'

set -l _zellij_attach_condition '__fish_seen_subcommand_from attach a'
complete --command zellij --condition "$_zellij_attach_condition" \
    --short-option c --long-option create --description 'Create the session if needed'
complete --command zellij --condition "$_zellij_attach_condition" \
    --short-option b --long-option create-background --description 'Create a detached session if needed'
complete --command zellij --condition "$_zellij_attach_condition" \
    --short-option f --long-option force-run-commands --description 'Run resurrected commands immediately'
complete --command zellij --condition "$_zellij_attach_condition" \
    --short-option r --long-option remember --description 'Save the session for re-authentication'
complete --command zellij --condition "$_zellij_attach_condition" \
    --long-option forget --description 'Delete saved authentication first'
complete --command zellij --condition "$_zellij_attach_condition" \
    --long-option insecure --description 'Skip TLS certificate validation'
complete --command zellij --condition "$_zellij_attach_condition" --no-files \
    --long-option index --require-parameter --description 'Attach by session index'
complete --command zellij --condition "$_zellij_attach_condition" --no-files \
    --short-option t --long-option token --require-parameter --description 'Authentication token'
complete --command zellij --condition "$_zellij_attach_condition" --force-files \
    --long-option ca-cert --require-parameter --description 'Custom CA certificate'
set -e _zellij_attach_condition

for _zellij_subcommand in attach a watch w kill-session k delete-session d
    complete --command zellij \
        --condition "__fish_seen_subcommand_from $_zellij_subcommand" \
        --no-files \
        --arguments '(__dotfiles_zellij_sessions)' \
        --description Session
end
set -e _zellij_subcommand

complete --command zp \
    --no-files \
    --arguments '(__dotfiles_zellij_sessions)' \
    --description Session

# Keep terminal file colors for eza and other tools. Fish's native completion
# pager uses its own theme-aware color variables instead of the Zsh list style.
if command -q vivid
    set -gx LS_COLORS (vivid generate dracula)
end

####--------------------------------------------------
#### Broot launcher
####--------------------------------------------------

set -l _broot_launcher "$HOME/.config/broot/launcher/fish/br"
if test -f "$_broot_launcher"
    source "$_broot_launcher"
else if command -q broot
    function br --wraps=broot --description 'Launch broot and apply its resulting command'
        set -l cmd_file (mktemp); or return
        command broot --outcmd "$cmd_file" $argv
        set -l code $status
        if test -s "$cmd_file"
            source "$cmd_file"
        end
        command rm -f "$cmd_file"
        return $code
    end
end

####--------------------------------------------------
#### Commands, abbreviations, and functions
####--------------------------------------------------

# Fish abbreviations are preferable for interactive shortcuts: they expand to
# the real command before execution, so native completion and history stay clear.

# Safe ls -> eza (fallback to ls if eza is missing).
if command -q eza
    alias ls 'eza --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
    alias lsa 'eza --all --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
    alias lt 'eza --tree --git-ignore --level=2 --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
    alias lta 'eza --tree --level=2 --all --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
    alias ll 'eza -l --group-directories-first --icons'
    alias la 'eza --all --oneline --group-directories-first --long --git --no-user --no-time --no-permissions --icons --color=auto'
    alias tree 'eza --tree --level=5'
    alias lz 'eza --grid --long --icons --group-directories-first --git-ignore'
    alias lza 'eza -a --grid --long --icons --group-directories-first'
    alias lzt 'eza --tree --long --icons --group-directories-first --git-ignore --git --level=3'
    alias lzta 'eza -a --tree --long --icons --group-directories-first --git --level=3'
end

# bat as cat (fallback to cat).
if command -q bat
    alias b 'bat --style numbers,grid'
    alias cat 'bat --plain'
end

abbr --add oc opencode
abbr --add cx codex
abbr --add cxr 'codex resume'
abbr --add ff fastfetch

if command -q helix
    abbr --add hx helix
end
abbr --add h helix
abbr --add n nvim
abbr --add nn 'nvim --cmd "let g:skip_startup_explorer = 1"'

abbr --add rg 'rg --hidden --glob "!.git"'
abbr --add fd 'fd --hidden --exclude .git'

function svenv --description 'Activate the current Python virtual environment'
    source .venv/bin/activate.fish
end

abbr --add .. 'cd ..'
abbr --add ... 'cd ../..'
abbr --add .... 'cd ../../..'

# Zellij session shortcuts.
abbr --add zj zellij

function zp --wraps='zellij attach' --description 'Attach to a persistent Zellij session'
    set -l session_name work
    if set -q ZELLIJ_PERSISTENT_SESSION; and test -n "$ZELLIJ_PERSISTENT_SESSION"
        set session_name "$ZELLIJ_PERSISTENT_SESSION"
    end
    if test (count $argv) -gt 0; and test -n "$argv[1]"
        set session_name "$argv[1]"
    end
    command zellij attach --create "$session_name"
end

function zd --wraps=zellij --description 'Start a fresh Zellij development session'
    set -l session_name "dev-"(date +%Y%m%d-%H%M%S)
    if test (count $argv) -gt 0; and test -n "$argv[1]"
        set session_name "$argv[1]"
    end
    command zellij --session "$session_name" --new-session-with-layout dev
end

function zleft --wraps=zellij --description 'Start a fresh Zellij monitoring session'
    set -l session_name "zleft-"(date +%Y%m%d-%H%M%S)
    if test (count $argv) -gt 0; and test -n "$argv[1]"
        set session_name "$argv[1]"
    end
    command zellij --session "$session_name" --new-session-with-layout zleft
end

function zdclean --description 'Delete old generated Zellij development sessions'
    set -l days 14
    if test (count $argv) -gt 0
        set days "$argv[1]"
    end

    if not string match --quiet --regex '^[0-9]+$' -- "$days"
        echo 'usage: zdclean [days]'
        return 2
    end

    set -l cache_home "$HOME/.cache"
    if set -q XDG_CACHE_HOME; and test -n "$XDG_CACHE_HOME"
        set cache_home "$XDG_CACHE_HOME"
    end
    set -l session_info_dir "$cache_home/zellij/contract_version_1/session_info"
    test -d "$session_info_dir"; or return 0

    command find "$session_info_dir" -mindepth 2 -maxdepth 2 -type f \
        -path '*/dev-*/session-metadata.kdl' -mtime +"$days" \
        -exec sh -c '
            for metadata; do
                session_name=$(basename "$(dirname "$metadata")")
                zellij delete-session "$session_name"
            done
        ' sh '{}' +
end

# Git shortcuts. Simple aliases become abbreviations so they retain Git's exact
# native completion context; argument-sensitive shortcuts remain functions.
abbr --add gs 'git status'
abbr --add ga. 'git add .'
abbr --add gaa 'git add --all'
abbr --add gb 'git branch'
abbr --add gba 'git branch --all'
abbr --add gbr 'git branch --remote'
abbr --add gw 'git worktree'
abbr --add gwl 'git worktree list'
abbr --add gwa 'git worktree add'
abbr --add gwr 'git worktree remove'
abbr --add gwp 'git worktree prune'
abbr --add gd 'git diff'
abbr --add gdc 'git diff --cached'
abbr --add gds 'git diff --staged'
abbr --add gdh 'git diff HEAD'
abbr --add gf 'git fetch'
abbr --add gl 'git log --oneline --graph'
abbr --add gr 'git rebase'
abbr --add gri 'git rebase -i'
abbr --add pull 'git pull'
abbr --add push 'git push'
abbr --add gco 'git checkout'
abbr --add co 'git checkout'
abbr --add gm 'git merge'
abbr --add gcm 'git commit -m'
abbr --add gcam 'git commit -am'
abbr --add gsh 'git show HEAD'

function ga --wraps='git add' --description 'Stage paths, or everything when called without arguments'
    if test (count $argv) -eq 0
        command git add --all
    else
        command git add $argv
    end
end

function gc --wraps='git commit' --description 'Commit with a convenient one-message argument form'
    if test (count $argv) -eq 0
        command git commit
        return
    end

    if not string match --quiet -- '-*' "$argv[1]"
        if test (count $argv) -eq 1
            command git commit -m "$argv[1]"
            return
        end

        echo 'gc: quote multi-word commit messages, e.g. gc "my commit message"' >&2
        return 2
    end

    command git commit $argv
end

function gac --wraps='git commit' --description 'Stage everything and commit'
    command git add --all; or return
    gc $argv
end

function gdd --wraps='git diff' --description 'Show a difftastic working-tree diff'
    command git -c diff.external=difft diff --ext-diff $argv
end

function gdds --wraps='git diff' --description 'Show a difftastic staged diff'
    command git -c diff.external=difft diff --ext-diff --staged $argv
end

function gddh --wraps='git diff' --description 'Show a difftastic diff against HEAD'
    command git -c diff.external=difft diff --ext-diff HEAD $argv
end

function gshd --wraps='git show' --description 'Show a commit through difftastic'
    set -l rev HEAD
    if test (count $argv) -gt 0
        set rev "$argv[1]"
        set -e argv[1]
    end

    command git -c diff.external=difft show --ext-diff --decorate \
        --format=medium --stat --patch "$rev" -- $argv
end

function gsd --wraps='git show' --description 'Show one or more revisions through difftastic'
    if test (count $argv) -eq 0
        echo 'usage: gsd <commit|range> [commit|range ...]' >&2
        return 2
    end

    command git -c diff.external=difft show --ext-diff --decorate \
        --format=medium --stat --patch $argv
end

function gld --wraps='git log' --description 'Show patch history through difftastic'
    command git -c diff.external=difft log --ext-diff -p $argv
end

####--------------------------------------------------
#### Yazi wrapper: cd to last directory on exit
####--------------------------------------------------

function y --wraps=yazi --description 'Launch Yazi and change to its final directory'
    set -l tmp (mktemp -t 'yazi-cwd.XXXXXX'); or return
    command yazi --cwd-file="$tmp" $argv
    set -l code $status

    if test -s "$tmp"
        set -l newdir (command cat "$tmp")
        if test -n "$newdir"; and test -d "$newdir"
            cd "$newdir"
        end
    end

    command rm -f "$tmp"
    return $code
end

####--------------------------------------------------
#### Host-local additions
####--------------------------------------------------

# Fish uses a Fish-syntax local file rather than trying to parse .zshrc.local.
set -l _fish_local_config "$HOME/.config/fish/.config.local.fish"
if test -f "$_fish_local_config"
    source "$_fish_local_config"
end

# No zsh-patina equivalent is initialized: Fish's asynchronous native syntax
# highlighting and autosuggestions are active by default.
