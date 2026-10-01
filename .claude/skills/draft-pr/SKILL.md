---
name: draft-pr
description: >-
  Quick commit and push with --no-verify so a GitHub PR is reviewable without waiting
  for the hooks. Use when the user invokes /draft-pr, wants an early PR for review, or
  asks to skip hooks for a fast push. After drafting, /qa then /release (hooks on) must
  run before merge.
disable-model-invocation: true
---

# Draft PR

> **The one documented exception to "never `--no-verify`".** This skill exists to bypass lefthook, on the user's explicit decision. If you are not in `/draft-pr` because the user invoked it by name, `--no-verify` is forbidden.

**Principle:** Get a PR URL in front of the reviewer fast. Hooks are deferred — not skipped forever.

**Not** `/review` — that is the post-release automation audit.

## When to run

- The user invokes `/draft-pr`
- They want to **see a PR quickly** while work is in progress

## When not to run

- Shipping or merging — use `/qa` then `/release` (hooks **on**)
- The user has not agreed to skip hooks for this push

## Phase 1 — Preflight

```bash
git status
git branch -vv
git log --oneline -5
git diff --stat origin/main...HEAD
git diff --stat
```

1. Abort if on `main`.
2. Base branch is `main`.
3. Confirm there is something to commit and/or push.
4. **Check the upstream** — `git rev-parse --abbrev-ref @{u}`. Never `git push` with no arguments.
5. Do **not** stage secrets or a built `.gem`.

## Phase 2 — Commit (hooks off)

```bash
git add <paths>
git commit --no-verify -m "$(cat <<'EOF'
Why-focused message for this chunk.
EOF
)"
```

No Claude attribution — no `Co-Authored-By` trailer, no "Generated with" line.

## Phase 3 — Push (hooks off)

```bash
git push --no-verify -u origin HEAD
```

Here `--no-verify` on the push matters: it skips the pre-push RSpec run.

## Phase 4 — Open or update the PR

```bash
bin/create-pr --draft
```

Or by hand, checking for an existing PR first:

```bash
gh pr list --head "$(git branch --show-current)" --json url,title
gh pr create --base main --draft --title "Why-focused title" --body "$(cat <<'EOF'
## Summary
- ... (work in progress)

## Status
Draft — hooks were bypassed, bin/ci not yet green.
EOF
)"
```

Return the **PR URL** prominently. If `gh` is missing, give `https://github.com/jaarnie/localmail/compare/main...<branch>`.

## Phase 5 — Hand off (mandatory)

Tell the user:

1. The PR URL
2. Hooks were **skipped** — RuboCop, the gem audit and RSpec have **not** run locally (GitHub Actions will run them on the PR)
3. Next steps before merge:

```
/qa → (fix if needed) → approve → /release
```

## Safety rules

- Never `--no-verify` in `/release` or when merging
- Never force-push `main`
- Never `git push` with no arguments
- Never update `git config`
- Never commit secrets
- After `/draft-pr`, never claim QA is green
