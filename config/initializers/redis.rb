# frozen_string_literal: true

# Initialize Redis client
$redis = Redis.new(
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  timeout: 5
)

# Configure Sidekiq
Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    network_timeout: 5,
    pool_timeout: 5
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    network_timeout: 5,
    pool_timeout: 5
  }
end

Rails.logger.info "Redis initialized at #{ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')}"
