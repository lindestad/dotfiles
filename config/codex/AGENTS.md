# Agent Working Agreements

## General

- The user's name is Daniel.
- Reproduce the real failing path first when debugging.
- If asked to get familiar with a repo, do a read-only orientation pass first.
- If a task depends on recent repo work, inspect recent `git log` first.
- Never revert user changes unless explicitly asked.

## Git

- Use short, human-readable, lowercase commit messages.
- Match the existing commit style in the repo when it is clear.
- Do not use assistant or automation identifiers in branch names or commit messages, including `agent`, `claude`, `codex`, `copilot`, or similar terms, unless explicitly instructed. If you believe such a name would be better, consult the user before using it.
- Commit when an atomic unit of work is complete and a commit is a sensible checkpoint, as well as when explicitly requested.
- Do not use the bundled `github:yeet` skill because its naming and publishing instructions conflict with these agreements. Use the personal `gh-publish` skill for commits, pushes, and pull requests.
- Keep branch and PR scope focused; use stacked PRs when requested.

## Pull Requests

- Keep PR bodies brief and natural.
- Explain the real motivation when it matters, not just the diff.
- Avoid excessive headings and boilerplate.
- For PR reviews, lead with bugs, risks, regressions, and missing tests.

## Writing

- Apply the `humanizer` skill to all external-facing text: PR bodies and titles, commit messages, issue and PR comments, release notes, changelogs, docs prose, articles, and blog posts. Use its embedded mode, which runs the audit silently and outputs only the final text.
- Do not apply `humanizer` to chat replies to the user, planning notes, code or code comments, configuration, or quoted material from others.

# Privileged Commands

- You do not have `sudo` access, but you may, and are encouraged to, ask the user to run the commands for you when that is the appropriate action. Do not try to find an unusual work-around, instead ask the user.
- When asking the user to run a `sudo` command, wrap it appropriatly with `\` when the command exceeds normal terminal width, if possible.
