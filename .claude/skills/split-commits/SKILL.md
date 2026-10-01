---
name: split-commits
description: >-
  Split a large branch or PR diff into logical, reviewable commits instead of one squash.
  Use when the user invokes /split-commits, when the branch diff exceeds ~30 files, or
  before /release when they want commit-by-commit review on GitHub.
disable-model-invocation: true
---

# Split Commits

**Principle:** One concern per commit. Reviewers read history, not a monolithic diff.

> `bin/split-commits` (`plan` / `prepare` / `verify`) and `bin/pr-size` do the mechanics. `plan` groups changed files by area and suggests slices; `prepare` soft-resets to the merge base and leaves everything unstaged; both refuse `main`.

## When to use

| Situation | Action |
|-----------|--------|
| Branch diff exceeds ~30 files | Propose slices, run this skill, then `/release` keeping commits |
| The user asks for reviewable commits | Run this before `/release` |
| Mixed concerns on one branch | Split by layer (see the order below) |

## When NOT to use

When the slices would be individually broken — a configuration setting whose spec lands two commits later, or a view that references a route not yet added. If the branch cannot be sliced into working states, say so and recommend one commit.

## Before you start

1. Read `.claude/tool-registry.yml` — `release`.
2. Run `/qa` (or confirm green) **before** rewriting history.
3. **Get the user's approval on the commit plan** before touching history.

## Phase 1 — Plan

```bash
git fetch origin
bin/split-commits plan
```

Summarise total files, proposed commits (title + file list, ≤30 files each), in dependency order:

```
1. gem/infra      (localmail.gemspec, Gemfile, Gemfile.lock, lib/localmail.rb)
2. lib            (lib/localmail/** — configuration, store, message, capture, engine)
3. routes/config  (config/routes.rb)
4. controllers    (app/controllers/localmail)
5. views          (app/views — templates, layout, inline styles)
6. dummy-app      (spec/dummy)
7. specs          (spec/**)
8. tooling        (bin/, .github/, lefthook.yml, .rubocop.yml)
9. docs/skills    (README, CHANGELOG, CLAUDE.md, .claude/)
```

Ask the user to approve or adjust.

## Phase 2 — Prepare

Record a fallback first:

```bash
git rev-parse HEAD          # note this SHA — it is how you get back
bin/split-commits prepare
```

## Phase 3 — Commit slices

For each approved slice, in order:

```bash
git add path/to/file1 path/to/file2
git commit -m "Short why-focused message."
```

- **Never** `git add .` or `git add -A`
- Stage only the paths named in the approved plan
- No Claude attribution in any message
- A hook fails → fix it, then continue. Do **not** `--no-verify`

lefthook's RuboCop step runs on staged files only, so each slice is linted against just its own files.

After all slices:

```bash
git status                                      # must be clean
bin/split-commits verify
git diff origin/main...HEAD --stat | tail -1    # total unchanged from Phase 1
```

## Phase 4 — Release

Run `/qa` once more on the final tree, then `/release` and tell it to **keep the commits**.

## Safety

- Never `reset --hard`, `clean -fdx`, or force-push without explicit approval
- Save the fallback SHA before Phase 2
- Never run on `main`
- If the branch was already pushed, the stack will need `--force-with-lease`
