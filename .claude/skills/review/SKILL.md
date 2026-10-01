---
name: review
description: >-
  Post-release session review: audit the commands run this session, compare them against
  existing bin scripts and the registry, and propose moving repetitive work into scripts.
  Use after /release completes, or when the user invokes /review.
disable-model-invocation: true
---

# Review

**Principle:** *Make the change easy, then make the easy change.* Every release should leave the toolchain better — fewer improvised commands, more `bin/*` scripts and registry entries.

This skill **analyses and proposes**; it does not implement.

## When to run

**Mandatory** after `/release` succeeds. Also useful after any long session with many shell commands.

## Phase 1 — Gather evidence

1. **Tool calls** — reconstruct every `git`, `bin/*`, `bundle exec`, `redis-cli`, `gem`, browser-automation and `gh` invocation from this session.
2. **Branch diff:**

```bash
git log --oneline -10
git diff --stat origin/main...HEAD
```

3. **Registry inventory** — `.claude/tool-registry.yml`: `hooks`, `qa`, `release`, `issue_start`, `demo`.
4. **Script inventory** — `ls -1 bin/`.

## Phase 2 — Classify each command

| Category | Meaning | Action |
|----------|---------|--------|
| **Scripted** | Matches a `bin/*` or registry entry | None |
| **Hook** | Runs via lefthook or `/qa` | None |
| **LLM improvised** | Composed ad hoc from shell steps | **Automation candidate** |
| **One-off debug** | Exploratory (`grep`, a single `redis-cli keys`) | Ignore unless repeated |
| **Judgment call** | API design, naming, security reasoning | Stays with the agent |

### Red flags

Each of these already has a script. A session that hand-rolled one anyway is the finding — point the skill at the script rather than writing a second:

- `git fetch` / `switch -c` sequences → `bin/start-branch`
- Manual `git reset --soft` squash → `bin/squash`
- `git diff --stat | tail -1` file counting → `bin/pr-size`
- Hand-composed `gh pr create` → `bin/create-pr`
- Running checks one at a time → `bin/ci`
- Repeated `bin/rails runner` to send mail into the dummy → a registry `demo.*` entry, or a rake task
- Repeated `redis-cli` inspection of `localmail:*` keys → a spec, or a documented command

### Registry drift (check every time)

`lefthook.yml`, `bin/ci`, `.github/workflows/ci.yml` and the registry's `hooks`/`ci`/`qa` sections must all agree. If this session changed one, flag the others.

## Phase 3 — Automation plan

**Do not implement.**

```markdown
## Session review: [branch or session title]

### Commands observed
| Command / sequence | Times run | Category | Notes |
|---|---|---|---|

### Already well automated
- ...

### Automation opportunities
| Priority | Opportunity | Proposed change | Type | Effort |
|---|---|---|---|---|

**Types:** script · registry · skill · hook (lefthook.yml, bin/ci **and** the workflow) · docs (CLAUDE.md / README)

### Proposed scripts (detail)
#### `bin/proposed-name`
- **Replaces:** ...
- **Interface:** ...
- **Safety:** refuse `main`, refuse a dirty tree
- **Registry key:** ...

### Out of scope (correctly agent-driven)
### Recommended next step
```

End with: **"Approve items to implement, or skip review until next release."**

## Phase 4 — Pull request

Ensure the released branch has a PR open. `bin/create-pr` opens an existing PR rather than duplicating it, so it is safe to call. Over ~30 files → ask the user to split or approve.

## Phase 5 — Done

Report: commands audited, improvised sequences found, P1 opportunities, PR URL.

## Safety rules

- **Do not** implement proposed scripts or edit skills during the review (Phase 4 excepted)
- **Do not** commit or push
- **Do not** propose automation for judgment work
- Prefer extending an existing `bin/*` over adding a new one
- Every proposed script needs safety guards (refuse `main`, refuse a dirty tree)
