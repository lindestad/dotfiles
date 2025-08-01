$env.config.show_banner = false

$env.config.buffer_editor = "hx"

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")


# ALIASES

# git
alias gs = git status
alias ga = git add
alias ga. = git add .
alias gaa = git add --all
alias gb = git branch
alias gba = git branch --all
alias gbr = git branch --remote
alias gf = git fetch
alias gl = git log --oneline --graph
alias pull = git pull
alias push = git push
alias gco = git checkout
alias co = git checkout
alias gm = git merge
alias gcm = git commit -m
alias gcam = git commit -am
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

# Eza
alias tree = eza --tree --level=5
alias lz = eza --grid --long --icons --group-directories-first --git-ignore
alias lza = eza --grid --long --icons --group-directories-first
alias lzt = eza --tree --long --icons --group-directories-first --git-ignore --git --level=3
alias lzta = eza --tree --long --icons --group-directories-first --git --level=3

# Bat
alias b = bat --style numbers,grid
alias cat = bat --plain


# AUTOCOMPLETIONS
# Check the path is correct
let autocompletions_path = "~/dev/dotfiles/config/nushell/custom-completions"
if not ($autocompletions_path | path exists) {
  print "\n\n    WARNING: Custom completions not loaded:"
  print "    Custom completions path does not exist, make sure dotfiles is installed at ~/dev/dotfiles\n\n"
  print "    Error below can be safely ignored, cause by early return workaround to exit script early.\n\n"
  return
}

# Load custom completions
source ~/dev/dotfiles/config/nushell/custom-completions/bat/bat-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/cargo/cargo-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/docker/docker-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/eza/eza-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/git/git-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/pytest/pytest-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/rg/rg-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/rustup/rustup-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/ssh/ssh-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/tar/tar-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/typst/typst-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/uv/uv-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/vscode/vscode-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/zellij/zellij-completions.nu
source ~/dev/dotfiles/config/nushell/custom-completions/zoxide/zoxide-completions.nu


# THEME
source ~/dev/dotfiles/config/nushell/nu-themes/humanoid-dark.nu

# Yazi binding allowing cd to working directory on exit

def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}

