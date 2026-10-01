---
name: spec-style
description: >-
  House rules for this gem's RSpec suite: request specs against the dummy app, assertions
  on what a person sees or the one class that is the coupling, a clean Redis namespace and
  config around every example, one expectation per example, no comments. Use whenever
  writing or reviewing a spec, and when the user invokes /spec-style.
---

# Spec style

**Principle:** the suite is the gem's only proof that it works in a host. Keep it fast, isolated and readable as documentation.

## Layout

| Spec | Lives in | Tests |
|---|---|---|
| Library | `spec/lib/` | `Localmail` itself, `Store`, `Message`, configuration — plain Ruby against Redis |
| Mailers | `spec/mailers/` | The `capture_in_localmail` macro, through the dummy's real mailers |
| Requests | `spec/requests/` | The inbox, through the dummy app's mount at `/mail` |

The dummy app (`spec/dummy`) is the host. When a spec needs a mailer shape that does not exist — a new declaration style, say — add a mailer under `spec/dummy/app/mailers` rather than building one inline.

## Isolation is already done for you

`spec/rails_helper.rb` runs `Localmail.reset_config!` and `Localmail::Store.clear` around every example. So:

- Configure inside the example or its `before`, with `Localmail.configure { |config| ... }`. Never set config at file level; it would leak if the reset ever moved.
- Do not add your own `Store.clear`. If a spec needs one, the global hook is broken — fix that.
- Prefer real configuration over stubs. Stub `Localmail.capturing?` only where the test environment itself is the obstacle (the capture spec).
- Tests use the `localmail:dummy:test` namespace, so they never touch a development inbox on the same Redis.

## Assert on what a person sees

In request specs, assert on visible text (`include("Nothing held yet")`) or the response status. Reach for a selector only when the markup is the contract — and then use the one class or attribute that **is** the coupling:

```ruby
expect(response.parsed_body.at_css("div.lm-panels iframe.lm-frame")).to be_present
```

That class is what the viewport toggle resizes; dropping it breaks the feature silently. A styling-only class is not a contract and must not be asserted on.

## One expectation per example

Each `it` states one fact, and its name says which. Two facts are two examples, sharing setup through `let` and `before`.

## No comments

The `describe` / `context` / `it` names are the documentation. If an example needs a comment to be understood, rename it.

## Names

- `describe` the method (`.find`) or the route (`GET /mail/:id`)
- `context` the condition (`when enabled`, `with an authenticate hook`)
- `it` the behaviour, in plain words (`"redirects to the inbox when the message has expired"`)

## Running them

```bash
bundle exec rspec                       # whole suite, needs redis-server
bundle exec rspec spec/requests         # one area
bundle exec rspec spec/lib/localmail/store_spec.rb:42
```
