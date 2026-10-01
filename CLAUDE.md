# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

Localmail is a mountable Rails engine that captures outgoing mail into the host's database
(or Redis) and serves it from an inbox. It exists for deployed non-production environments (review apps, staging),
where the mail provider will not deliver and filesystem tools such as mailcatcher or
letter_opener_web cannot work because mail is sent from one process and read from another.

It was extracted from a Rails monolith where it was first built. Everything is namespaced
under `Localmail`. Storage is pluggable: `Stores::ActiveRecord` (the default, one table) or
`Stores::Redis`. The suite runs on the dummy app's SQLite and needs nothing running; the
`:redis` examples skip locally when Redis is not reachable.

The full design, with every decision and its reason, is in
`.claude/local/in_progress/localmail-gem.md`. Read it before changing behaviour.

## Commands

```sh
bin/ci                                        # RuboCop, gem audit, RSpec: every check
bundle exec rspec                             # suite (:redis examples skip without Redis)
bundle exec rspec spec/requests/inbox_spec.rb # one file
bin/rubocop                                   # lint (rubocop-rails-omakase)
bin/rubocop -A {paths}                        # ...and autocorrect
bin/rails db:migrate                          # the dummy's development database
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
| `lib/localmail.rb` | `Localmail.configure`, `enabled?`, `capturing?`, `store` (resolves `config.store`) |
| `lib/localmail/configuration.rb` | Every setting and its default |
| `lib/localmail/store.rb` | Facade: `Store.save/all/find/delete/clear` delegate to `Localmail.store` |
| `lib/localmail/stores/active_record.rb` | Default store: the `localmail_messages` table |
| `lib/localmail/stores/redis.rb` | Redis store: an id list plus one key per message. Requires the redis gems lazily |
| `db/migrate/` | The table's migration. Hosts copy it with `bin/rails localmail:install:migrations` |
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
- **Bounded storage, in both stores.** Every save prunes past the TTL and the cap, in the same
  transaction as the write.
- **The stores share one contract** and one set of shared examples
  (`spec/support/shared_examples/a_localmail_store.rb`). Change behaviour in both or neither.
- **Redis is optional.** `redis` and `connection_pool` are not gemspec dependencies; only
  `stores/redis.rb` requires them.
- **Never edit a shipped migration.** Hosts have run it. Add a new one.
- **A failed capture is logged, then re-raised.** With `raise_delivery_errors` off, ActionMailer
  swallows the error, and the log line is the only trace a message was lost.

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
