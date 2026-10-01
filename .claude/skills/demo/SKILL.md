---
name: demo
description: >-
  Demo a change by driving the dummy app's inbox in a browser and showing screenshots of
  what a person would see. Use when the user asks to demo, preview, or show changes,
  invokes /demo, or from the /issue-start pipeline when the inbox changed.
disable-model-invocation: true
---

# Demo

**Principle:** A demo is what a person would actually see — the inbox driven in a browser, with screenshots. Not curl, and not a description of what the template should render.

## Before you start

Read `.claude/tool-registry.yml` — `demo`.

## Phase 1 — Bring it up

The dummy captures into its SQLite database by default, so migrate it once. Then, from the gem root (`bin/rails` runs `spec/dummy`):

```bash
bin/rails db:migrate
CAPTURE_EMAILS=true bin/rails server -p 3020
```

To demo the Redis store instead, start Redis (`redis-cli ping`) and set `config.store = :redis` in a dummy initializer for the session; remove it afterwards.

Run it in a background shell (or the `localmail-dummy` config in `.claude/launch.json`) and wait for `http://localhost:3020/mail/` to answer.

Put mail in the inbox through the real path — the macro and the delivery method — rather than writing to the Store directly:

```bash
CAPTURE_EMAILS=true bin/rails runner 'NotificationMailer.sign_in_link.deliver_now'   # declared action
CAPTURE_EMAILS=true bin/rails runner 'DigestMailer.weekly.deliver_now'               # bare declaration
```

`capturing?` is true in development once enabled, so these land in the inbox. `NotificationMailer.receipt` is undeclared and is **not** captured — use it to show that.

**The dummy's inbox is its own.** The ActiveRecord store uses the dummy's own database, and the Redis store's default namespace includes the app name (`localmail:dummy:development`), so neither can see another app's captured mail. If a message you did not send appears anyway, stop: do not screenshot it, because it may be a real sign-in link.

| Symptom | Cause |
|---|---|
| `no such table: localmail_messages` | `bin/rails db:migrate` not run |
| `Redis::CannotConnectError` | Using the Redis store and `redis-server` is not running |
| `/mail` is 404 | Started without `CAPTURE_EMAILS=true` — the controller refuses when not enabled |
| Mail sent but not in the inbox | The runner was started without `CAPTURE_EMAILS=true`, or the action is not declared |
| Port already in use | A previous server survived. `lsof -nP -iTCP:3020 -sTCP:LISTEN`, kill by pid |

## Phase 2 — Walk the change in the browser

Use the browser tools. Navigate, act, screenshot at each step that shows something new:

1. `http://localhost:3020/mail/` — the inbox list
2. A message you sent — the HTML view, then plain text and source tabs
3. The desktop/mobile toggle, when the message has an HTML part
4. Delete, and Clear all only if the inbox holds nothing but your own mail

Also check, and say which you checked:

- **A narrow viewport** (≈390px wide) — the list drops the time column and must not scroll sideways
- **The empty state**, if the change touched it — use a throwaway namespace rather than clearing someone else's mail
- **Authentication: none.** The dummy mounts the engine with no `authenticate` hook, so there is no signed-out case to show. Say so; the `authenticate` hook is covered by `spec/requests/inbox_spec.rb`.

## Phase 3 — Show and explain

For each step: the URL, the screenshot, and one sentence on what a person can now do that they could not before.

## Phase 4 — Report and stop the server

- Base URL, and whether the server was yours or the user's
- Pages visited, with a screenshot each
- Viewport and other checks made
- Anything blocked

Stop a server you started: `kill $(lsof -nP -iTCP:3020 -sTCP:LISTEN -t)`.

**From `/issue-start`:** continue to the approval gate. Never release from `/demo`.

## What not to do

- Do not demo by reading the code aloud — drive the app
- Do not screenshot or delete mail you did not send
- Do not seed the inbox by calling `Localmail::Store.save` — that skips the macro, which is half of what is being shown
