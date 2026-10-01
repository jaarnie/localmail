# Changelog

## [Unreleased]

## [0.1.0]

- Extracted from the Rails application it was first built in.
- `capture_in_localmail` opt-in macro, included into every mailer.
- Redis store bounded by TTL and a message cap, namespaced per environment.
- Mountable inbox with HTML, plain-text and source views and a desktop/mobile preview toggle.
- `Localmail.configure` for enabling, Redis, limits, namespace, parent controller and an authenticate hook.
