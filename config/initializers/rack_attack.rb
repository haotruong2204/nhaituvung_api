# frozen_string_literal: true

class Rack::Attack
  # Use Redis for storing rate limit data
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
  )

  # Allow localhost and local networks
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1" || req.ip.start_with?("192.168.") || req.ip.start_with?("10.")
  end

  # Throttle all requests by IP
  # Allow 100 requests per minute per IP
  throttle("req/ip", limit: 100, period: 1.minute) do |req|
    req.ip
  end

  # Throttle API requests specifically
  # Allow 60 requests per minute for API endpoints
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Aggressive throttle for UI format endpoint (prevents mass scraping)
  # Allow 30 requests per minute per IP for ui_format endpoint
  throttle("ui_format/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path.include?("/ui_format")
  end

  # Block known scraper user agents
  blocklist("block-scrapers") do |req|
    # Block requests with scraper user agents
    user_agent = req.user_agent.to_s.downcase
    scrapers = %w[scrapy crawler spider bot wget curl]

    # Allow legitimate bots (Google, Bing, etc.)
    legitimate_bots = %w[googlebot bingbot slurp duckduckbot]

    is_scraper = scrapers.any? { |scraper| user_agent.include?(scraper) }
    is_legitimate = legitimate_bots.any? { |bot| user_agent.include?(bot) }

    is_scraper && !is_legitimate
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    retry_after = env["rack.attack.match_data"][:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ error: "Rate limit exceeded. Please try again later.", retry_after: retry_after }.to_json]
    ]
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |_env|
    [
      403,
      { "Content-Type" => "application/json" },
      [{ error: "Forbidden" }.to_json]
    ]
  end
end
