# Localmail

An inbox for email captured from deployed Rails environments.

On a review app or staging server, mail often cannot go anywhere useful: the provider is in
sandbox mode, or you do not want real customers receiving test sends. The usual tools
(mailcatcher, letter_opener_web) write to the local filesystem or a local SMTP port, so they
break as soon as mail is sent from a worker dyno or container and read from a web one.

Localmail keeps captured mail somewhere every process already shares (your database, or Redis
if you prefer) and serves it from a mountable inbox.

- **Opt-in per mailer action.** Only the actions you name are captured, and everything else
  keeps your normal delivery method.
- **Bounded.** Messages expire after a TTL and the inbox keeps only the newest N, so capture
  cannot fill a database or a Redis instance shared with Sidekiq.
- **Off by default.** Without `CAPTURE_EMAILS` (or `config.enabled`) nothing is diverted and the
  inbox returns 404.

## Installation

```ruby
# Gemfile
gem "localmail"
```

Captured mail is stored in your database by default, in one table:

```sh
bin/rails localmail:install:migrations
bin/rails db:migrate
```

Mount the inbox, behind your own authentication:

```ruby
# config/routes.rb
authenticate :admin do                      # Devise; or use config.authenticate below
  mount Localmail::Engine, at: "/mail"
end
```

Turn it on in the environments that should capture:

```sh
CAPTURE_EMAILS=true
```

## Choosing what to capture

Every mailer gets the `capture_in_localmail` macro:

```ruby
class AccountMailer < ApplicationMailer
  capture_in_localmail :sign_in_link       # just this action
end

class DigestMailer < ApplicationMailer
  capture_in_localmail                     # every action on this mailer
end
```

Declare once per mailer. The delivery method is swapped per message at delivery time, so a
mailer delivered from a background job is decided when it sends.

## Storage

| Store | When | Needs |
|---|---|---|
| `:active_record` (default) | Any app. Works with the Solid Queue/Cache stack and with no Redis at all | The `localmail_messages` table (above) |
| `:redis` | You already run Redis and would rather keep captured mail out of your database | `gem "redis"` and `gem "connection_pool"` in your Gemfile |

```ruby
Localmail.configure do |config|
  config.store = :redis
  config.redis = -> { Redis.new(url: ENV["REDIS_URL"]) }   # default: Redis.new, pooled
end
```

On Heroku Redis, whose certificates do not verify:

```ruby
config.redis = -> { Redis.new(ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }) }
```

`config.store` also takes any object that responds to `save(mail)` (returning an id),
`all`, `find(id)`, `delete(id)` and `clear`, returning `Localmail::Message` objects.

If saving fails (the database or Redis is unreachable), Localmail logs
`Localmail: failed to capture "<subject>"` and re-raises. With `raise_delivery_errors` off,
ActionMailer then swallows the error, so the log line is your only sign that a message was
neither captured nor sent.

## Configuration

```ruby
# config/initializers/localmail.rb
Localmail.configure do |config|
  config.enabled = ENV["CAPTURE_EMAILS"] == "true"    # default: CAPTURE_EMAILS, cast to boolean
  config.store = :active_record                       # default
  config.ttl = 3.days                                 # default
  config.max_messages = 50                            # default
  config.capture_in_test = false                      # default
  config.parent_controller = "ActionController::Base" # default
  config.authenticate = -> { authenticate_admin! }    # default: nil
  config.redis = nil                                  # :redis store only
  config.namespace = "localmail:my_app:#{Rails.env}"  # :redis store only. Default: app name + environment
end
```

| Setting | What it does |
|---|---|
| `enabled` | Boolean or callable. Unset, it reads `CAPTURE_EMAILS`. |
| `store` | `:active_record`, `:redis`, or a store object. |
| `ttl` | How long each message is kept. |
| `max_messages` | How many messages the inbox holds. The oldest roll off. |
| `capture_in_test` | Capture in `Rails.env.test?` too. Off, so mailer specs still see `ActionMailer::Base.deliveries`. |
| `parent_controller` | What the inbox controller inherits from. Set it to your own controller to pick up its authentication. Read once, when the controller loads. |
| `authenticate` | A block run in the inbox controller before every action, e.g. `-> { authenticate_admin! }`. |
| `redis` | `:redis` store only. A callable that builds a client (wrapped in a connection pool), or a ready-made client. |
| `namespace` | `:redis` store only. Key prefix, defaulting to the app's name and environment, so neither another app on the same Redis nor a test run can see or wipe your inbox. |

## Safety

**There is no environment guard.** Review apps usually run with `RAILS_ENV=production`, so a
`Rails.env.production?` check would block the case this exists for. The enable flag is the only
thing between production and a silent mail outage: a captured message looks exactly like a
delivered one in the logs. Keep `CAPTURE_EMAILS` unset in production, and weigh that every time
you add a mailer action to the capture list.

The inbox shows whole messages, including sign-in links and tokens. Always mount it behind
authentication.

## Development

```sh
bundle install
bin/ci                # RuboCop, gem audit, RSpec
```

The suite runs on the dummy app's SQLite and needs nothing running. Start `redis-server` to
include the Redis store's examples; without it they are skipped with a warning (on CI, a
missing Redis fails the run instead).

## License

MIT
