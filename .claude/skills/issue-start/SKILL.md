---
name: issue-start
description: >-
  Start a new issue: sync main, cut a feature branch, plan the change, then implement it.
  Use when the user invokes /issue-start, starts a new issue, or asks to begin work on a
  feature branch.
disable-model-invocation: true
---

# Issue Start

**Principle:** Sync a clean branch, produce a **simple** plan, then build. The best change is the smallest one that works.

**Kent Beck:** *Make the change easy, then make the easy change.*

## Before you start

1. Read `.claude/tool-registry.yml` — `project`, `issue_start`, `paths`.
2. Read `CLAUDE.md` and the plan in `.claude/local/in_progress/` — it records how the gem works and what is planned next.
3. Confirm you have a **branch name** and a **short description**. Ask if either is missing.
4. Naming: `feature/short-description`, `fix/short-description`, `chore/short-description`.

## Phase 1 — Preflight

```bash
git status
git branch -vv
git log --oneline -5
```

Base branch is **`main`**. Confirm the branch name does not already exist locally or on origin.

## Phase 2 — Create the branch

```bash
bin/start-branch BRANCH_NAME            # add --stash if the tree is dirty
```

It fetches, branches from the latest `origin/main`, and refuses `main` or an existing name. Never commit or push in this phase.

## Phase 3 — Understand the issue

1. Restate the goal in one sentence.
2. Decide **who the change is for**:

| Audience | Where it lives |
|---|---|
| A host app's developer (install, configure, opt a mailer in) | `lib/localmail/**`, README, and later generators |
| A person reading captured mail | The inbox: `app/controllers/localmail`, `app/views/localmail` |

3. Read the closest existing code as the pattern: `lib/localmail/configuration.rb` for a setting, `messages_controller.rb` for an inbox action.
4. Does it change the **public surface** — a setting, the macro, a route, a constant hosts might reference? That is API, and it needs a README entry, a CHANGELOG line and a version decision.
5. Note open questions where requirements are ambiguous.

## Phase 4 — Constraints

- **Two stores, one contract.** Captured mail lives in the host's database (`Stores::ActiveRecord`, the default) or Redis (`Stores::Redis`), chosen by `config.store`. Both implement `save`, `all`, `find`, `delete` and `clear`, both are bounded by `ttl` and `max_messages`, and both run the shared examples in `spec/support/shared_examples/a_localmail_store.rb`. A behaviour change to one is a change to both.
- **One table, shipped as an engine migration** (`db/migrate`, copied with `bin/rails localmail:install:migrations`). A change to it is a new migration; never edit a shipped one, because hosts have already run it. Nothing else may touch the host's database.
- **Assume nothing about the host.** No Devise, no Tailwind, no asset pipeline, no particular Redis, no brand. Anything host-specific is a `Localmail.configure` setting with a sensible default — and every new setting is forever, so prefer none.
- **The inbox is self-contained.** Styles are inline (`app/views/localmail/_styles.css.erb`), classes prefixed `lm-`, no JavaScript. It must render in a host with a strict CSP (the style tag carries the nonce).
- **Capture stays opt-in per action.** Nothing may divert mail the host has not named with `capture_in_localmail`.
- **No environment guard is deliberate.** Review apps run `RAILS_ENV=production`. Do not add one without the user agreeing.
- Use `bin/rails generate` (from the gem root, it targets the engine) rather than hand-writing what a generator would produce.

## Phase 5 — Plan

Keep it simple; prefer several small PRs over one large change. Flag any chunk over **30 files**.

```markdown
## Issue: [title]

### Goal
[One paragraph — the simplest version that delivers value]

### Who it is for
[Host developer / inbox reader. What they can do afterwards that they cannot now.]

### Simplicity
[Why this is minimal; what was deliberately left out]

### Branch
`branch-name`

### Public surface
[New or changed settings, macro arguments, routes, constants — or "none". Version bump: patch / minor / major.]

### Design
| Path | What it does |
|---|---|

### Testing plan
| Area | Type | Notes |
|---|---|---|

### PR chunks
| Chunk | Files (est.) | Delivers |
|---|---|---|

### Out of scope
### Open questions
```

End with: **"Approve this plan to implement, or tell me what to change."**

## Phase 6 — Implement (after approval)

Order: `lib/` → routes → controller → views → dummy app (a mailer, if the change needs one) → specs → README/CHANGELOG.

Follow the neighbouring code's structure and naming. Before finishing a chunk:

```bash
bin/pr-size
```

Over 30 files → stop, propose `/split-commits` or ask for approval.

## Phase 7 — Delivery pipeline

```
implement → /qa → /demo (inbox changed) → await user OK → /release
```

1. **`/qa`** — stay in the fix loop until green.
2. **`/draft-pr`** (optional) — when the user wants a PR URL early.
3. **`/demo`** — whenever the inbox changed. Skip for pure internals; say which.
4. **Await approval** — present what was built, the QA result, the demo and the PR size. End with **"Approve to release, or tell me what to change."**
5. **`/release`** — after approval only.

## Phase 8 — Done

Report: branch name, what was built, the public-surface decision, and the pipeline outcome.

## Safety rules

- Never update `git config`
- Never commit or push in this skill
- Never branch off a stale local `main` — always `origin/main`
- Never exceed 30 files in a PR without permission
