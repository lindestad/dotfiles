default:
    @just --list

check:
    @./scripts/check.sh

doctor:
    @./bin/dotfiles-doctor

relink *ARGS:
    @./scripts/relink.sh {{ARGS}}

unlink *ARGS:
    @./scripts/unlink.sh {{ARGS}}
