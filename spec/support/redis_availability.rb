require "redis"

# Skips the :redis examples on a machine with no Redis, but never on CI, where a missing
# Redis means the service is misconfigured rather than absent.
module RedisAvailability
  def self.configure(config)
    return if available?
    abort("Redis is not reachable, and CI must run the :redis examples.") if ENV["CI"]

    warn "Redis is not reachable: skipping the :redis examples. Start redis-server to run them."
    config.filter_run_excluding :redis
  end

  def self.available?
    Redis.new.ping == "PONG"
  rescue Redis::BaseConnectionError
    false
  end
end
