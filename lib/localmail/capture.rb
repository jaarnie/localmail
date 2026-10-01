module Localmail
  # The opt-in macro, included into every mailer. A mailer names the actions it wants
  # captured:
  #
  #   capture_in_localmail :welcome   # just that action
  #   capture_in_localmail            # every action on the mailer
  #
  # Anything undeclared keeps the app's configured delivery method. The swap happens per
  # message, at delivery time, so a mailer delivered from a background job is decided
  # when it sends rather than when the class loaded.
  module Capture
    extend ActiveSupport::Concern

    included do
      class_attribute :localmail_captured_actions, instance_accessor: false, default: nil
    end

    class_methods do
      def capture_in_localmail(*actions)
        self.localmail_captured_actions = actions.map(&:to_sym)
        after_action :localmail_capture, only: actions.presence, if: -> { Localmail.capturing? }
      end
    end

    private

    def localmail_capture
      message.delivery_method(Localmail::DeliveryMethod)
    end
  end
end
