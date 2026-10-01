# Localmail

A Redis-backed inbox for email captured from deployed Rails environments.

On a review app or staging server, mail often cannot go anywhere useful: the provider is in
sandbox mode, or you do not want real customers receiving test sends. The usual tools
(mailcatcher, letter_opener_web) write to the local filesystem or a local SMTP port, so they
break as soon as mail is sent from a worker dyno or container and read from a web one.

Localmail keeps captured mail in Redis, which every process already shares, and serves it from
a mountable inbox.

- **Opt-in per mailer action.** Only the actions you name are captured, and everything else
  keeps your normal delivery method.
- **Bounded.** Messages expire after a TTL and the inbox keeps only the newest N, so capture
  cannot fill a Redis instance shared with Sidekiq or a cache.
- **Off by default.** Without `CAPTURE_EMAILS` (or `config.enabled`) nothing is diverted and the
  inbox returns 404.

## Installation

```ruby
# Gemfile
gem "localmail", github: "jaarnie/localmail"
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

## Configuration

```ruby
# config/initializers/localmail.rb
Localmail.configure do |config|
  config.enabled = ENV["CAPTURE_EMAILS"] == "true"    # default: CAPTURE_EMAILS, cast to boolean
  config.redis = -> { Redis.new(url: ENV["REDIS_URL"]) } # default: Redis.new, pooled
  config.ttl = 3.days                                 # default
  config.max_messages = 50                            # default
  config.namespace = "localmail:my_app:#{Rails.env}"  # default: app name + environment
  config.capture_in_test = false                      # default
  config.parent_controller = "ActionController::Base" # default
  config.authenticate = -> { authenticate_admin! }    # default: nil
end
```

| Setting | What it does |
|---|---|
| `enabled` | Boolean or callable. Unset, it reads `CAPTURE_EMAILS`. |
| `redis` | A callable that builds a client (wrapped in a connection pool), or a ready-made client. |
| `ttl` | How long each message is kept. |
| `max_messages` | How many messages the inbox holds. The oldest roll off. |
| `namespace` | Redis key prefix. Defaults to the app's name and environment, so neither another app on the same Redis nor a test run can see or wipe your inbox. |
| `capture_in_test` | Capture in `Rails.env.test?` too. Off, so mailer specs still see `ActionMailer::Base.deliveries`. |
| `parent_controller` | What the inbox controller inherits from. Set it to your own controller to pick up its authentication. Read once, when the controller loads. |
| `authenticate` | A block run in the inbox controller before every action, e.g. `-> { authenticate_admin! }`. |

On Heroku Redis, whose certificates do not verify:

```ruby
config.redis = -> { Redis.new(ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }) }
```

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
redis-server          # the suite needs a running Redis
bin/ci                # RuboCop, gem audit, RSpec
```

## License

MIT
