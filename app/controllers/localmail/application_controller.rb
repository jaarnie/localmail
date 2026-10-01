module Localmail
  # Base for the inbox. Inherits from the host's choice of controller so its own
  # authentication and helpers apply, then runs the configured authenticate hook.
  class ApplicationController < Localmail.config.parent_controller.constantize
    protect_from_forgery with: :exception

    before_action :require_enabled
    before_action :authenticate_localmail

    layout "localmail/application"

    private

    # Mounted but switched off is the same as not mounted.
    def require_enabled
      head :not_found unless Localmail.enabled?
    end

    def authenticate_localmail
      hook = Localmail.config.authenticate
      instance_exec(&hook) if hook
    end
  end
end
