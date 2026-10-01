---
name: release
description: >-
  Commit branch work, push, and optionally open or update a GitHub PR targeting main;
  for a version release, also bump the version, changelog and tag. Pre-commit hooks run on
  commit; on any failure, stop and hand off to /qa. Use when the user invokes /release,
  approves release after the /issue-start pipeline, or asks to ship a branch.
disable-model-invocation: true
---

# Release

**Principle:** This skill does git release mechanics only. It does **not** fix failing checks — hand off to `/qa`.

> `bin/squash`, `bin/create-pr` and `bin/pr-size` are what the phases below use. lefthook runs RuboCop and the gem audit on commit and RSpec on push, so a red suite will stop a push — provided Redis is running.

## Before you start

1. Read `.claude/tool-registry.yml` — `release` and `hooks`.
2. Confirm the user wants to **commit and push** (this skill does both), and whether to open a PR (Phase 5) or cut a version (Phase 6).
3. **From `/issue-start`:** only after explicit user approval. QA should already be green.
4. **Standalone:** recommend `/qa` first.

Base branch is **`main`**. Remote is `git@github.com:jaarnie/localmail.git`.

## Phase 1 — Preflight

Run together:

```bash
git status
git diff
git diff --staged
git log --oneline -15
git branch -vv
```

Then:

1. **Abort** if on `main` — release only from a feature branch unless the user explicitly overrides.
2. **Fetch** — `git fetch origin`.
3. **Check the upstream.** `git rev-parse --abbrev-ref @{u}`. A branch cut from `origin/main` can track it, in which case a bare `git push` would push to main. Push explicitly (Phase 4) — never `git push` with no arguments.

**Never stage secrets** — `.env`, credentials, a RubyGems API key (`~/.gem/credentials`), or a built `.gem`.

## Phase 2 — Commit

1. Stage the intended paths with `git add <paths>` — never `git add .` unless the user has confirmed the whole tree is theirs and intended.
2. If everything is already committed, skip to Phase 3.
3. Draft the message from the **full branch diff** against `origin/main`: what changed and **why**, matching recent commit style.

```bash
git commit -m "$(cat <<'EOF'
Why this change exists.
EOF
)"
```

**No Claude attribution** — no `Co-Authored-By` trailer, no "Generated with" line, in commits or PR bodies.

**Pre-commit hooks run automatically.** If any fail:

- **STOP.** Do not fix code, re-stage, or retry.
- Summarise the hook output.
- Tell the user: **run `/qa` to fix, then re-run `/release`.**

Do **not** use `--no-verify` (`/draft-pr` is the one documented exception).

## Phase 3 — One commit or several

- **Already one commit since the base** → nothing to do. `bin/squash` detects this and exits cleanly.
- **Several WIP commits the user wants collapsed** → `bin/squash -m "message"` (or `--keep-message`). It refuses `main` and a dirty tree; `--dry-run` shows the count and message first. Note the pre-squash SHA (`git rev-parse HEAD`) as a fallback.
- **A large branch the user wants reviewable commit-by-commit** → `/split-commits` instead, and skip this phase.

WIP commits must not appear on `main`.

## Phase 4 — Push

```bash
git push -u origin HEAD
```

If rejected because a soft reset rewrote pushed history:

```bash
git push --force-with-lease origin HEAD
```

**Never** force-push `main`. The pre-push hook runs RSpec; if it fails, stop and hand off to `/qa` exactly as for a commit failure.

## Phase 5 — Pull request (when asked)

`bin/create-pr` runs `bin/pr-size` first, opens an existing PR rather than duplicating it, and refuses `main` or an unpushed branch:

```bash
bin/create-pr --title "Why-focused title" --body-file /tmp/pr-body.md
```

Or drive `gh` directly:

```bash
gh pr create --base main --title "Why-focused title" --body "$(cat <<'EOF'
## Summary
- ...

## Test plan
- [ ] bin/ci green

## Accepted boundary findings
- ... (from `/white-label`; omit the section when the audit came back clean)
EOF
)"
```

Draft from the **full branch diff**. Flag anything over ~30 files (`release.max_pr_files`). Any `/white-label` finding the user accepted rather than fixed goes in the body with its reason.

If `gh` is missing, give the compare URL: `https://github.com/jaarnie/localmail/compare/main...<branch>`.

## Phase 6 — Version release (only when asked)

A version is cut from `main` after the PR merges:

1. On a release branch, bump `lib/localmail/version.rb` (semver: a new config setting or behaviour is a minor bump; a fix is a patch; anything a host must change is a major).
2. Move `CHANGELOG.md`'s `Unreleased` entries under the new version.
3. Check the gem builds: `gem build localmail.gemspec`, then delete the `.gem`.
4. PR, merge, then tag `main`:

```bash
git fetch origin
git tag -a vX.Y.Z origin/main -m "vX.Y.Z"
git push origin vX.Y.Z
```

Confirm the tag push with the user first — a pushed tag is public. Hosts pin with `gem "localmail", github: "jaarnie/localmail", tag: "vX.Y.Z"`.

**Nothing is published to RubyGems** (`gem push`) unless the user asks for that explicitly. It is irreversible in practice — a yanked version number can never be reused.

## Phase 7 — Done

Report:

- Branch name
- Final commit SHA and message
- Push result (new branch vs updated remote)
- PR URL, or a note that the user can ask for one
- Tag, if one was cut
- **Whether the suite was actually verified**, and by what

Then **invoke `/review`** to audit the session for automation opportunities.

## Handoff to QA (on any hook failure)

```
Release stopped — checks failed.

Failed: [hook / command]
Output:
[relevant output]

Next step: /qa to fix, then /release again.
```

## Safety rules

- Never update `git config`
- Never force-push `main`
- Never `git push` with no arguments
- Never commit unless the user invoked `/release` or asked to release
- Never `gem push` without an explicit request
- Ask before including unrelated untracked files
- If the merge base is ambiguous (branch not fetched), stop and ask
