module Localmail
  # ActionMailer delivery method that stores mail in Redis instead of sending it.
  class DeliveryMethod
    attr_accessor :settings

    def initialize(settings = {})
      @settings = settings
    end

    def deliver!(mail)
      Store.save(mail)
    end
  end
end
