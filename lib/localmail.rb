require "connection_pool"
require "redis"
require "mail"
require "active_support"
require "active_support/core_ext/integer/time"

require "localmail/version"
require "localmail/configuration"
require "localmail/message"
require "localmail/store"
require "localmail/delivery_method"
require "localmail/capture"
require "localmail/engine"

# Captures outgoing mail into Redis and serves it from a mountable inbox.
module Localmail
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def reset_config!
      @config = nil
      @redis = nil
    end

    # Whether capture is switched on at all. Also decides whether the host draws the
    # inbox route, which happens once at boot.
    def enabled?
      config.enabled?
    end

    # Whether a message being delivered right now should be captured.
    def capturing?
      enabled? && (config.capture_in_test || !Rails.env.test?)
    end

    def redis
      @redis ||= config.build_redis
    end
  end
end
