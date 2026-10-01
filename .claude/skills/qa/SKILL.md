---
name: qa
description: >-
  Run the deterministic check suite (RuboCop, gem audit, RSpec) via bin/ci, then fix only
  what those tools report. Use after code changes, when the user invokes /qa, or from the
  /issue-start delivery pipeline.
disable-model-invocation: true
---

# QA

**Principle:** Deterministic tools run first and define the boundaries. Fix only what those tools report — never improvise style rules from memory.

> `bin/ci` is the whole suite here: RuboCop (omakase), bundler-audit and RSpec. The specs take seconds, so unlike a big app nothing is left out. There is no coverage gate.

## Phase 0 — Services

The default store is ActiveRecord, and the suite migrates the dummy's SQLite database itself, so nothing needs to be running for most of it. The `:redis` examples (the Redis store and the shared store examples run against it) need Redis:

```bash
redis-cli ping          # expect PONG
redis-server            # if not
```

With no Redis, those examples are **skipped** with a warning, not failed, so a green run without Redis has not tested the Redis store. Say so in the report. On CI (`CI` set) a missing Redis aborts the run instead.

## Phase 1 — Run the checks (no code changes yet)

1. **Read `.claude/tool-registry.yml`** — `hooks` mirrors `lefthook.yml`, `qa.all` is the command below.
2. **Run everything:**

```bash
bin/ci
```

It continues past a failure and prints a summary table, so one pass reports everything. Do not substitute individual commands for it — the point of the script is that its list cannot drift from `lefthook.yml` and `.github/workflows/ci.yml`. Run one check on its own only while iterating on a single failure.

3. **Collect every failure** before fixing anything. Summarise them all.

## Phase 2 — Fix loop (within tool boundaries)

For each failure:

1. **Identify the source** — RuboCop offence, RSpec example, audit CVE.
2. **Fix the code** to satisfy that output only.
3. **Re-run just that check:**

```bash
bundle exec rspec {path}          # or {path}:{line}
bin/rubocop {paths}
bundle exec bundler-audit check --update
```

4. **Repeat** until it passes.

Escalate instead of weakening a threshold: if a fix needs a cop disabled or a spec deleted → **stop and ask the user**.

### Failure modes specific to this gem

| Symptom | Likely cause |
|---|---|
| "skipping the :redis examples" warning | Redis is not reachable locally (Phase 0). The Redis store went untested |
| `ActiveRecord::StatementInvalid: no such table: localmail_messages` | The migration in `db/migrate` changed without the dummy's test database following. Delete `spec/dummy/db/test.sqlite3` and re-run |
| A Store spec sees messages it did not write | Something skipped `Localmail::Store.clear` / `Localmail.reset_config!` — both run around every example in `spec/rails_helper.rb` |
| A capture spec finds `ActionMailer::Base.deliveries` empty | `capture_in_test` or a stubbed `capturing?` leaked out of its example |
| `uninitialized constant` for a host class in the engine | The engine assumed something about its host. Make it configuration, not a reference |
| `SyntaxError` inside connection_pool | Running under the wrong Ruby. `.ruby-version` pins 3.4.7 |
| RuboCop wants `[ a ]` | That is omakase house style, not a mistake |

## Phase 3 — The boundary audit

Green checks say the code works. They say nothing about whether the gem has started assuming something about its host — Devise, a Redis setup, a brand, an env var — that should have been configuration. No cop catches that, so invoke:

```
/white-label
```

Report its verdict as part of the QA result. Skip it only for a change that touches no code — docs, `.claude/**`, a version bump — and say that you skipped it and why.

## Phase 4 — Confirm green

Re-run `bin/ci`. The task is complete only when it exits 0. **Say plainly what you ran.** Name any check you skipped.

## Fast mode (only when the user asks)

```bash
bin/rubocop --force-exclusion {changed paths}
bundle exec rspec {one spec file}
```

Then remind the user that full `/qa` is still required before commit.

## When to escalate

- `bundle install` needed, or a gem fails to build
- Redis is down and the change touches the Redis store (Phase 0)
- A failure needs a product decision — a change to the public configuration surface is one
- A fix would need a disabled cop or a deleted spec

## What not to do

- Do not apply style rules no cop enforces
- Do not claim a green run broader than the commands you executed
- Do not commit or push from this skill
- Do not bypass lefthook with `--no-verify`
- Do not skip the boundary audit because the deterministic checks are green

## After QA is green

- **From `/issue-start`:** continue to `/demo` when the inbox changed, then the approval gate. Do not invoke `/release` from here.
- **From a `/release` failure:** fix here, then tell the user to re-run `/release`.
- **Standalone:** report green and stop.
