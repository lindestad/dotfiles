$env.config.show_banner = false

$env.config.buffer_editor = "hx"

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# ALIASES

# git
alias gs = git status
alias ga = git add
alias ga. = git add .
alias gf = git fetch
alias pull = git pull
alias push = git push
alias gm = git merge
alias gcm = git commit -m
def gc [...msg_parts: string] {
  let msg = $msg_parts | str join " " | str trim

  if ($msg == "") {
    error make {
      msg: "Commit message cannot be empty.",
      label: {
        text: "Provide a commit message, e.g. `gc Add login form`",
        span: (0, 0)
      }
    }
  }

  git commit -m $msg
}

# Other
alias tree = eza --tree --level=5
alias lz = eza --grid --long --icons --group-directories-first --git-ignore
alias lzt = eza --tree --long --icons --group-directories-first --git-ignore --git --level=3


