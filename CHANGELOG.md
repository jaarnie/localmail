# Changelog

## [Unreleased]

## [0.2.2]

- **The mobile preview reflows wide emails to fit**, as a phone mail app does: fixed widths
  give way and the text wraps at full size. A fixed-width email no longer scrolls sideways
  in the 390px preview. The desktop preview is unchanged.

## [0.2.1]

- Declare the MIT licence in the gemspec, so RubyGems lists it.

## [0.2.0]

- **Pluggable storage.** `config.store` takes `:active_record` (new default), `:redis`, or a
  store object. The ActiveRecord store needs one table:
  `bin/rails localmail:install:migrations && bin/rails db:migrate`.
- **Redis is now optional.** `redis` and `connection_pool` are no longer dependencies. Add them
  to your Gemfile and set `config.store = :redis` to keep the previous behaviour.
- A capture that fails to save is logged before the error is re-raised, so it is not lost
  silently when `raise_delivery_errors` is off.
- `Localmail.redis` is gone. Use `Localmail.store.redis` with the Redis store.

## [0.1.0]

- `capture_in_localmail` opt-in macro, included into every mailer.
- Redis store bounded by TTL and a message cap, namespaced per environment.
- Mountable inbox with HTML, plain-text and source views and a desktop/mobile preview toggle.
- `Localmail.configure` for enabling, Redis, limits, namespace, parent controller and an authenticate hook.
