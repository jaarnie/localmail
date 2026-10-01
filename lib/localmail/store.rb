module Localmail
  # Where captured mail lives. Delegates to the store chosen by config.store.
  module Store
    class << self
      delegate :save, :all, :find, :delete, :clear, to: :backend

      def backend
        Localmail.store
      end
    end
  end
end
