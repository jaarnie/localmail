# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

Localmail is a mountable Rails engine that captures outgoing mail into Redis and serves it
from an inbox. It exists for deployed non-production environments (review apps, staging),
where the mail provider will not deliver and filesystem tools such as mailcatcher or
letter_opener_web cannot work because mail is sent from one process and read from another.

It was extracted from a Rails monolith where it was first built. Everything is namespaced
under `Localmail`. There is **no database**: Redis is the only service the gem or its suite needs.

The full design, with every decision and its reason, is in
`.claude/local/in_progress/localmail-gem.md`. Read it before changing behaviour.

## Commands

```sh
bin/ci                                        # RuboCop, gem audit, RSpec: every check
bundle exec rspec                             # suite (needs redis-server running)
bundle exec rspec spec/requests/inbox_spec.rb # one file
bin/rubocop                                   # lint (rubocop-rails-omakase)
bin/rubocop -A {paths}                        # ...and autocorrect
CAPTURE_EMAILS=true bin/rails server -p 3020  # dummy app, inbox at /mail
```

### The check list lives in four places

`lefthook.yml` (git hooks), `bin/ci`, `.github/workflows/ci.yml` and
`.claude/tool-registry.yml`. **Change one and change all four.** lefthook runs RuboCop
(autocorrecting and restaging) and the gem audit on commit, and RSpec on push. **Do not
bypass it with `--no-verify`**; `/draft-pr` is the one documented exception.

## Layout

| Path | What |
|---|---|
| `lib/localmail.rb` | `Localmail.configure`, `enabled?`, `capturing?`, `redis` |
| `lib/localmail/configuration.rb` | Every setting and its default |
| `lib/localmail/store.rb` | Redis reads and writes: an id list plus one key per message |
| `lib/localmail/message.rb` | One captured email, parts exposed as UTF-8 |
| `lib/localmail/delivery_method.rb` | ActionMailer delivery method, registered as `:localmail` |
| `lib/localmail/capture.rb` | The `capture_in_localmail` macro, included into every mailer |
| `lib/localmail/engine.rb` | Registers the delivery method and includes the macro via `on_load(:action_mailer)` |
| `app/controllers/localmail/` | The inbox |
| `app/views/localmail/` | Inbox views, plus `_styles.css.erb`, inlined into the layout |
| `spec/dummy` | Host app for the suite. Mounts the engine at `/mail` and has two mailers |

The core lives in `lib/`, not `app/`, because the delivery method and macro must exist when
ActionMailer loads, before Zeitwerk would autoload anything from `app/`.

## Rules

- **The gem must not assume anything about its host.** No Devise, no Tailwind or asset
  pipeline, no branding, no particular Redis. Anything a host would reasonably vary becomes a
  `Configuration` setting with a safe default, but keep that surface small: a setting
  is a promise.
- **The views are self-contained.** CSS lives in `app/views/localmail/_styles.css.erb` and is
  inlined, with a CSP nonce when the host has one. Do not add a stylesheet or JavaScript that
  needs a host pipeline.
- **Off means off.** Unless enabled, nothing is diverted and the inbox returns 404 even when
  mounted. Never add an environment guard such as `Rails.env.production?`. Review apps run as
  production, and the enable flag is the guard. See the README's Safety section.
- **Capture is opt-in per action.** Never add a way to capture every mailer globally without
  the user asking for it explicitly. Its blast radius in production is every email the
  host sends.
- **Bounded storage.** Every write sets a TTL and trims the list, and anything trimmed has its
  message key deleted in the same transaction.

## Ruby style

- Guard clauses over `if`/`else`.
- Record look-ups go in `set_*` methods from a `before_action` constrained with `only:`. An empty
  action (`def show; end`) is fine.
- Name anything non-obvious with a private method rather than explaining it in a comment.
- Before writing a helper, check Ruby, ActiveSupport and Rails don't already provide it.
- Name variables for what they hold.
- **Minimal comments.** One line on a class or module saying what it is; otherwise only a
  genuine trap a reader would fall into. No comments in specs: the example names are the
  documentation.

## Workflow

- **Plan first** for anything with three or more steps or an architectural choice.
- **Verify before declaring done**: run `bin/ci`. "It loaded" is not done.
- **Do not commit or push** unless the user confirms in the current message.
- **No Claude attribution** in commits, PRs, changelog entries or release notes: no
  `Co-Authored-By: Claude` trailer and no "Generated with Claude Code" line.
- Base branch is `main`. Branch from `origin/main`, PR back into it.

## Code review

Prove every finding before raising it. Cite the `file:line` that makes it true, and label each
**CONFIRMED** or **PLAUSIBLE**. Then re-read the findings as an adversary and keep only what
survives.
