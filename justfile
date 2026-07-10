default:
    @just --list

check:
    @./scripts/check.sh

doctor:
    @./bin/dotfiles-doctor

install *ARGS:
    @./install.sh {{ARGS}}

relink *ARGS:
    @./scripts/relink.sh {{ARGS}}

unlink *ARGS:
    @./scripts/unlink.sh {{ARGS}}
