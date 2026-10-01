module Localmail
  # ActionMailer delivery method that stores mail instead of sending it.
  class DeliveryMethod
    attr_accessor :settings

    def initialize(settings = {})
      @settings = settings
    end

    # Logged before re-raising because with raise_delivery_errors off, ActionMailer
    # swallows the error and the message is neither captured nor sent.
    def deliver!(mail)
      Store.save(mail)
    rescue StandardError => error
      Rails.logger.error("Localmail: failed to capture #{mail.subject.inspect}: #{error.class}: #{error.message}")
      raise
    end
  end
end
