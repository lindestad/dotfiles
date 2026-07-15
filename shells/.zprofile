# Login-session commands should find user-installed executables without letting
# them shadow system commands.
typeset -U path PATH
path+=("$HOME/.local/bin")
export PATH
