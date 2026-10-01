module Localmail
  # Reads and writes captured mail in Redis: a list of ids newest-first plus one key per
  # message, both bounded by the configured TTL and message cap so captures cannot fill
  # an instance the app shares with something else.
  class Store
    class << self
      def save(mail)
        SecureRandom.uuid.tap { |id| write(id, mail.to_s, evicted_by_next_save) }
      end

      def all
        ids = redis.lrange(list_key, 0, -1)
        return [] if ids.empty?

        raws = redis.mget(message_keys(ids))
        ids.zip(raws).filter_map { |id, raw| Message.new(id, raw) if raw }
      end

      def find(id)
        raw = redis.get(message_key(id))
        return if raw.nil?

        Message.new(id, raw)
      end

      def delete(id)
        redis.multi do |transaction|
          transaction.del(message_key(id))
          transaction.lrem(list_key, 1, id)
        end
      end

      def clear
        ids = redis.lrange(list_key, 0, -1)
        redis.del(list_key, *message_keys(ids))
      end

      private

      def write(id, raw, evicted)
        redis.multi do |transaction|
          transaction.setex(message_key(id), ttl, raw)
          transaction.lpush(list_key, id)
          transaction.ltrim(list_key, 0, max_messages - 1)
          transaction.expire(list_key, ttl)
          transaction.del(*message_keys(evicted)) if evicted.any?
        end
      end

      # LTRIM drops ids off the tail but leaves their message keys behind, invisible to
      # the inbox until their own TTL runs out. These are the ids the next save pushes out.
      def evicted_by_next_save
        redis.lrange(list_key, max_messages - 1, -1)
      end

      def message_keys(ids)
        ids.map { |id| message_key(id) }
      end

      def message_key(id)
        "#{Localmail.config.namespace}:message:#{id}"
      end

      def list_key
        "#{Localmail.config.namespace}:messages"
      end

      def ttl
        Localmail.config.ttl.to_i
      end

      def max_messages
        Localmail.config.max_messages
      end

      def redis
        Localmail.redis
      end
    end
  end
end
