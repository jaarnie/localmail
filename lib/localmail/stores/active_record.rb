module Localmail
  module Stores
    # Keeps captured mail in the host's database, which every web and worker process
    # already shares. Needs the localmail_messages table (bin/rails localmail:install:migrations).
    class ActiveRecord
      # One captured message's raw source.
      class Record < ::ActiveRecord::Base
        self.table_name = "localmail_messages"
      end

      def save(mail)
        SecureRandom.uuid.tap do |id|
          Record.transaction do
            Record.create!(key: id, raw: mail.to_s)
            prune
          end
        end
      end

      def all
        live.order(created_at: :desc, id: :desc).limit(max_messages).map { |record| to_message(record) }
      end

      def find(id)
        record = live.find_by(key: id)
        return if record.nil?

        to_message(record)
      end

      def delete(id)
        Record.where(key: id).delete_all
      end

      def clear
        Record.delete_all
      end

      private

      def prune
        Record.where(created_at: ...cutoff).delete_all
        overflow = Record.order(created_at: :desc, id: :desc).offset(max_messages).pluck(:id)
        Record.where(id: overflow).delete_all if overflow.any?
      end

      def live
        Record.where(created_at: cutoff..)
      end

      def to_message(record)
        Message.new(record.key, record.raw)
      end

      def cutoff
        Localmail.config.ttl.ago
      end

      def max_messages
        Localmail.config.max_messages
      end
    end
  end
end
