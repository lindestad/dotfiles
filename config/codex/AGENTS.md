# Codex Working Agreements

## General

- Read the relevant repo context before making changes; prefer existing project patterns over new abstractions.
- Reproduce the real failing path first when debugging.
- Keep edits narrowly scoped to the user's request and avoid unrelated refactors.
- If asked to get familiar with a repo, do a read-only orientation pass first.
- If a task depends on recent repo work, inspect recent `git log` first.
- Never revert user changes unless explicitly asked.

## Git

- Use short, human-readable, lowercase commit messages.
- Match the existing commit style in the repo when it is clear.
- Avoid `codex` in branch names unless explicitly requested.
- Treat explicit commit requests as part of the task.
- Keep branch and PR scope focused; use stacked PRs when requested.

## Pull Requests

- Keep PR bodies brief and natural.
- Explain the real motivation when it matters, not just the diff.
- Avoid excessive headings and boilerplate.
- For PR reviews, lead with bugs, risks, regressions, and missing tests.

## Dotfiles

- In this repo, keep `apps.md` aligned with installer-managed packages and config links.
- Keep README high level and route package details to `apps.md`.
- Keep optional desktop stack pieces behind explicit flags like `--niri` and `--kanata`.
- Mirror behavior across shell and PowerShell installers when both platforms are affected.
