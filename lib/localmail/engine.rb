module Localmail
  # Mounts the inbox and wires capture into ActionMailer.
  class Engine < ::Rails::Engine
    isolate_namespace Localmail

    initializer "localmail.action_mailer" do
      ActiveSupport.on_load(:action_mailer) do
        add_delivery_method :localmail, Localmail::DeliveryMethod
        include Localmail::Capture
      end
    end
  end
end
