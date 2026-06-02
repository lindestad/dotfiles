# Copilot Working Agreements

## General

- Reproduce the real failing path first when debugging.
- If asked to get familiar with a repo, do a read-only orientation pass first.
- If a task depends on recent repo work, inspect recent `git log` first.
- Never revert user changes unless explicitly asked.

## Git

- Use short, human-readable, lowercase commit messages.
- Match the existing commit style in the repo when it is clear.
- Never attribute the model or agent as a commit co-author. Do not add
  `Co-authored-by: Copilot ...` (or any model/agent) trailers unless I
  explicitly ask for it in that request.
- Avoid `copilot` in branch names unless explicitly requested.
- Treat explicit commit requests as part of the task.
- Keep branch and PR scope focused; use stacked PRs when requested.

## Pull Requests

- Keep PR bodies brief and natural.
- Explain the real motivation when it matters, not just the diff.
- Avoid excessive headings and boilerplate.
- For PR reviews, lead with bugs, risks, regressions, and missing tests.

# Privileged Commands

- You do not have `sudo` access, but you may, and are encouraged to, ask the user to run the commands for you when that is the appropriate action. Do not try to find an unusual work-around, instead ask the user.
- When asking the user to run a `sudo` command, wrap it appropriatly with `\` when the command exceeds normal terminal width, if possible.
