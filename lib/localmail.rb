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

# Captures outgoing mail and serves it from a mountable inbox.
module Localmail
  STORES = {
    active_record: [ "localmail/stores/active_record", "Localmail::Stores::ActiveRecord" ],
    redis: [ "localmail/stores/redis", "Localmail::Stores::Redis" ]
  }.freeze

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
      @store = nil
    end

    def reset_config!
      @config = nil
      @store = nil
    end

    # Whether capture is switched on at all. Also decides whether the inbox serves.
    def enabled?
      config.enabled?
    end

    # Whether a message being delivered right now should be captured.
    def capturing?
      enabled? && (config.capture_in_test || !Rails.env.test?)
    end

    def store
      @store ||= build_store
    end

    private

    def build_store
      choice = config.store
      return choice unless choice.is_a?(Symbol)

      path, class_name = STORES.fetch(choice) do
        raise ArgumentError, "Unknown Localmail store #{choice.inspect}. Use one of #{STORES.keys.inspect} or a store object."
      end
      require path
      class_name.constantize.new
    end
  end
end
