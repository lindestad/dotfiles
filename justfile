default:
    @just --list

check:
    @./scripts/check.sh

doctor:
    @./bin/dotfiles-doctor
