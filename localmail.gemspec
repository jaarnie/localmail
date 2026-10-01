require_relative "lib/localmail/version"

Gem::Specification.new do |spec|
  spec.name        = "localmail"
  spec.version     = Localmail::VERSION
  spec.authors     = [ "John Arnold" ]
  spec.email       = [ "41114838+jaarnie@users.noreply.github.com" ]
  spec.homepage    = "https://github.com/jaarnie/localmail"
  spec.summary     = "A Redis-backed inbox for email captured from deployed Rails environments."
  spec.description = "Localmail swaps ActionMailer's delivery for the mailer actions you name, stores " \
                     "the message in Redis, and serves it from a mountable inbox. It works where " \
                     "mailcatcher and letter_opener_web cannot: across dynos and containers that " \
                     "share no disk."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "redis", ">= 4.8"
  spec.add_dependency "connection_pool", ">= 2.4"
end
