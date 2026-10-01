module Localmail
  # Settings for capture, storage and the inbox. Set them with Localmail.configure.
  class Configuration
    attr_accessor :ttl, :max_messages, :capture_in_test, :parent_controller, :authenticate
    attr_writer :enabled, :redis, :namespace

    def initialize
      @enabled = nil
      @redis = nil
      @namespace = nil
      @ttl = 3.days
      @max_messages = 50
      @capture_in_test = false
      @parent_controller = "ActionController::Base"
      @authenticate = nil
    end

    def enabled?
      return ActiveModel::Type::Boolean.new.cast(ENV.fetch("CAPTURE_EMAILS", nil)) == true if @enabled.nil?

      @enabled.respond_to?(:call) ? @enabled.call == true : @enabled == true
    end

    # Scoped to the app and environment so neither another app on the same local Redis
    # nor a test run can read or wipe the inbox open in the browser.
    def namespace
      @namespace || "localmail:#{Rails.application.class.module_parent_name.underscore}:#{Rails.env}"
    end

    def build_redis
      case @redis
      when nil then ConnectionPool::Wrapper.new { Redis.new }
      when Proc then ConnectionPool::Wrapper.new { @redis.call }
      else @redis
      end
    end
  end
end
