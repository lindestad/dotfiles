---
name: gh-publish
description: Safely prepare and publish GitHub changes with local git and the gh CLI. Use when Codex should commit completed work, push a branch, publish changes, create or open a pull request, update pull request metadata, or draft PR text. Do not use for reviewing PR feedback or fixing CI failures.
---

# GitHub Publish

Use local `git` for repository state and `gh` for GitHub operations. Prefer these predictable CLI paths over connector-based publishing.

## Respect action boundaries

- Treat commits as reversible local checkpoints. Commit when an atomic unit of requested work is complete and a commit is sensible, or when the user requests one.
- Do not push unless the user asks to push, publish to a remote, or create/open a PR. A request to create a PR authorizes the required branch push.
- Do not create or modify a PR unless the user explicitly requests that operation. Requests that only ask to write, suggest, revise, or review PR text authorize text only; applying that text to GitHub requires an explicit apply or update request.
- Create a ready-for-review PR by default. Use draft status only when the user explicitly asks for a draft.
- Do not add comments, labels, reviewers, milestones, or other repository state unless requested.
- If a bare request such as “publish this” has no clear endpoint in context, ask whether the desired endpoint is a remote branch or a PR.

## Inspect before changing state

1. Read applicable repository instructions and inspect recent `git log` when the task depends on recent work.
2. Run `git status --short --branch`. Inspect staged and unstaged diffs and identify untracked files.
3. Determine which changes belong to the task. Preserve unrelated user changes and never stage them silently.
4. Inspect remotes, the current branch, its upstream, and the remote default branch before choosing a branch or PR target.
5. Before remote operations, check `gh --version` and `gh auth status`.

If `gh auth status` fails because a sandbox cannot access credentials, the keyring, the filesystem, or the network, retry that non-mutating check with privileged execution when available. If execution already has full access, or authentication is genuinely missing or expired, ask the user to run `gh auth login`. Never display tokens, inspect them with `gh auth token`, or invent a credential workaround.

## Make atomic commits

- Run the relevant checks before committing when practical. Report unavailable tools or dependencies instead of silently changing the environment or bypassing checks. Recheck status afterward and do not stage test caches or generated artifacts unless they are intentional outputs.
- Stage explicit paths. Use `git add -A` only when the entire working tree is confirmed to belong to the same atomic change.
- Review `git diff --cached` before committing.
- Match the repository's established commit style. Keep messages concise, human-readable, and focused on one coherent change.
- Do not include assistant or automation identifiers, generated-by footers, or automated co-author attribution.
- Do not amend, squash, rebase, or otherwise rewrite existing commits unless requested. Prefer a follow-up atomic commit.
- Do not bypass hooks with `--no-verify`. If a hook fails, diagnose it, fix in-scope problems, and rerun it.
- Confirm the resulting commit and working-tree state.

## Choose and push branches safely

- Preserve an appropriate existing branch. Before committing on the default branch, inspect the repository workflow: create a topic branch first when the work is intended for review or the default branch normally tracks its remote unchanged; commit directly when that is the repository's established workflow. When a topic branch is needed, derive a human name from the work, such as `fix/...`, `feat/...`, `docs/...`, `test/...`, or `chore/...`.
- Never include assistant or automation identities in branch names. Consult the user only when the correct human name is materially ambiguous.
- Push to the intended fork or repository, normally `origin`, and target the appropriate upstream repository when opening a PR from a fork.
- Do not push directly to the default branch unless the user explicitly requests it.
- For a new remote branch, normally use `git push -u origin "$(git branch --show-current)"`.
- Never force-push unless explicitly requested. When rewriting is authorized, prefer `--force-with-lease`, verify the remote and branch again, and explain the risk before pushing.
- Do not push tags or additional branches unless requested.

## Write and open pull requests

1. Identify the target repository and base branch. Use `gh repo view --json nameWithOwner,defaultBranchRef` when authenticated, while accounting for fork and upstream remotes.
2. Inspect the complete diff and commit list against the chosen base, not only the latest commit.
3. Check whether the head branch already has a PR with `gh pr view` or `gh pr list --head ...`. Do not create a duplicate; report the existing PR and update it only when requested.
4. Write a concise, natural title with no assistant prefix. Base the body on the actual diff.
5. Explain what changed and why. Include the root cause for fixes when useful, user impact when meaningful, and the validation actually performed. Avoid boilerplate and excessive headings.
6. Write the body to a temporary file and pass it with `--body-file` so Markdown contains real newlines. Use `gh pr create` without `--draft` unless draft status was explicitly requested.
7. For cross-repository PRs, explicitly set the target with `--repo`, the base with `--base`, and the fork head with `--head owner:branch` as needed.
8. Verify the result with `gh pr view --json url,title,body,isDraft,baseRefName,headRefName,state` and report the URL and state.

Do not use `gh pr create --dry-run` as a harmless test: it may still push changes. Test command availability with help and read-only queries instead.

## Report the outcome

Summarize only the state that changed: commit hashes, branch and remote, PR URL and draft status, and checks run. Clearly identify anything that remains local or unverified.
