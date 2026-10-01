---
name: white-label
description: >-
  Audit changed code for assumptions about the host app hard-coded into the gem —
  Devise, a Redis setup, a CSS framework, a brand, an env var — and for the safety
  properties no cop enforces. Use from /qa once the deterministic checks are green, when
  the user invokes /white-label, or whenever a change adds a name, a default or a setting.
---

# White label

**Principle:** a gem is installed into apps you have not seen. Deterministic checks prove the code works in the dummy app; they say nothing about whether it still works in a host with no Devise, a different Redis, a strict CSP, or another company's name on the door. Localmail began inside one app, so this is the drift to watch for.

**The one-line test:** *would this line still be right in a host app I have never seen?*

## Phase 1 — Scope

Audit what this branch changed, not the whole repo:

```bash
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
```

Read the diff, not a summary of it.

## Phase 2 — What to look for

### A. Host assumptions

| Smell | Why it matters | The move instead |
|---|---|---|
| A reference to a host class, helper or method — `authenticate_admin!`, `current_user`, `ApplicationController` | Raises `NameError` in any host without it | The `authenticate` hook or `parent_controller` setting |
| A specific Redis — URL, SSL params, db number | Wrong for every other host | `config.redis`, with `Redis.new` (reads `REDIS_URL`) as the default |
| Tailwind or framework classes, `stylesheet_link_tag`, a JS dependency | The inbox renders unstyled or raises where that bundle does not exist | Inline `lm-` CSS in `_styles.css.erb` |
| A brand, company or product name in copy | The inbox belongs to whoever installs it | Neutral copy |
| A new env var read directly | Every name is a decision imposed on the host | A setting; `CAPTURE_EMAILS` stays the only env default |
| An inline `<style>` or `<script>` without the CSP nonce | Blocked by a strict policy | Carry `content_security_policy_nonce` |

### B. Safety properties no cop enforces

| Smell | Why it matters |
|---|---|
| Anything that captures mail the host did not name | Capture is opt-in per action. Diverting more is a silent outage for real recipients |
| A default that turns capture **on** | Off must stay the default. A host that installs and forgets must keep sending |
| An environment guard (`Rails.env.production?`) added | Review apps run as production. A guard silently breaks the case this exists for — it needs the user's agreement |
| An inbox action that skips `require_enabled` or the `authenticate` hook | Captured mail holds sign-in links and tokens |
| Unbounded Redis writes — no TTL, no cap | The host's Redis is usually shared with Sidekiq or a cache |
| Captured HTML rendered outside the sandboxed iframe | It is untrusted markup |

### C. Configuration surface

| Smell | Why it matters |
|---|---|
| A new setting with no README row | Hosts cannot discover it |
| A setting that duplicates one that exists | Two ways to say the same thing; they drift |
| A setting added "in case" | Every setting is public API kept forever. Add one when a real host needs it |

## Phase 3 — The forward-looking question

For anything new, one sentence each:

1. **What does a host have to have for this to work?** "Nothing beyond Rails and Redis" is the target.
2. **If a second host with different auth, Redis and branding installed this tomorrow, what would break?**
3. **Who owns this decision — the gem or the host?** Name it.

Do not refactor to satisfy this audit. The finding is to *notice*, and to record it.

## Phase 4 — Report

```markdown
## White-label audit
**Scope:** N files changed on this branch

### Findings
| File:line | Observation | Move proposed | Blocks release? |
|---|---|---|---|

### New settings or defaults introduced
| Setting / default | Default value | Documented in README? |
|---|---|---|

### Verdict
Clean — or: N findings, of which N block the release.
```

Every finding ends **fixed in this chunk** or **explicitly accepted by the user**, with the reason in the PR body.

## What is NOT a finding

- **The dummy app** (`spec/dummy`) being specific. It is a host; its mailers and routes are meant to be concrete.
- **`CAPTURE_EMAILS`** as the default enable flag. It is the one documented env var, and `config.enabled` overrides it.
- **`ActionController::Base`** as the default parent controller.
- **Opinionated inbox design.** Neutral is not the same as unstyled.

## When to escalate

- The finding changes the public API or a default → the user decides, and it needs a version decision
- The correct version is materially more work than the issue asked for → present both
- The finding is in code the branch did not touch → note it, do not fix it here

## What not to do

- Do not refactor, extract, or add a setting without the user agreeing
- Do not report a finding without proposing the move
- Do not audit the whole repo; audit the branch

## After the audit

- **From `/qa`:** report the verdict as part of the QA result.
- **Standalone:** report and stop.
