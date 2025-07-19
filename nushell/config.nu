$env.config.show_banner = false
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

alias gs = git status
alias ga = git add .
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
