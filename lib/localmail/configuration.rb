module Localmail
  # Settings for capture, storage and the inbox. Set them with Localmail.configure.
  class Configuration
    attr_accessor :ttl, :max_messages, :capture_in_test, :parent_controller, :authenticate
    attr_accessor :store, :redis
    attr_writer :enabled, :namespace

    def initialize
      @enabled = nil
      @store = :active_record
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

    # The :redis store's key prefix. Scoped to the app and environment so neither another
    # app on the same local Redis nor a test run can read or wipe the inbox.
    def namespace
      @namespace || "localmail:#{Rails.application.class.module_parent_name.underscore}:#{Rails.env}"
    end
  end
end
