# Security & Performance Configuration

## 🔐 Security Features

### 1. Rate Limiting (Rack::Attack)

**Configuration:** `config/initializers/rack_attack.rb`

#### Rate Limits

| Rule | Limit | Period | Scope |
|------|-------|--------|-------|
| General requests | 100 | 1 minute | Per IP |
| API endpoints | 60 | 1 minute | Per IP |
| UI format endpoint | 30 | 1 minute | Per IP |

#### Safelist (Allowed IPs)

```ruby
# Localhost and local networks
- 127.0.0.1
- ::1
- 192.168.*
- 10.*
```

#### Blocklist (Blocked User Agents)

**Blocked:**
```
scrapy, crawler, spider, bot, wget, curl
```

**Exceptions (Legitimate Bots):**
```
googlebot, bingbot, slurp, duckduckbot
```

### 2. Redis Configuration

**Store:** Rate limit data
**URL:** `redis://redis:6379/1` (Docker internal)
**Namespace:** Separated from cache data

### 3. CORS Configuration

**File:** `config/initializers/cors.rb`

```ruby
# Allow specific origins only
origins 'http://localhost:3000', 'https://your-domain.com'

# Allow specific HTTP methods
methods :get, :post, :put, :patch, :delete, :options, :head
```

---

## ⚡ Performance Optimizations

### 1. Caching Strategy

#### Redis Cache Configuration

**Environment:** Development
```ruby
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  namespace: "nhaituvung_dev_cache",
  expires_in: 90.minutes
}
```

**Environment:** Production
```ruby
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL"),
  namespace: "nhaituvung_prod_cache",
  expires_in: 24.hours,
  pool_size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i,
  pool_timeout: 5
}
```

#### Cache Keys

```
Format: kanji_ui_format:{character}
Example: kanji_ui_format:一
TTL: 1 hour
```

#### Cache Headers

```http
Cache-Control: max-age=3600, public
```

- Browser can cache for 1 hour
- CDN can cache for 1 hour
- Shared cache allowed (public)

### 2. Database Optimization

#### Connection Pooling

```yaml
# config/database.yml
pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

#### Indexes

**Already created:**
```sql
-- Kanjis table
INDEX idx_kanjis_jlpt_level ON kanjis(jlpt_level)
INDEX idx_kanjis_grade ON kanjis(grade)
INDEX idx_kanjis_stroke_count ON kanjis(stroke_count)
INDEX idx_kanjis_newspaper_rank ON kanjis(newspaper_frequency_rank)

-- Kanji Examples
INDEX idx_kanji_examples_kanji_id ON kanji_examples(kanji_id)
INDEX idx_kanji_examples_type ON kanji_examples(example_type)

-- Compositions
UNIQUE INDEX idx_unique_composition ON kanji_compositions(
  kanji_id, relation_type, related_kanji
)
```

#### Query Optimization

**Use scopes:**
```ruby
# app/models/kanji.rb
scope :by_jlpt, ->(level) { where(jlpt_level: level) }
scope :by_grade, ->(grade) { where(grade: grade) }
scope :ordered_by_frequency, -> { order(newspaper_frequency_rank: :asc) }
```

### 3. Serialization

**Fast JSON serialization:**
```ruby
# Using jsonapi-serializer (fast-jsonapi)
gem "jsonapi-serializer"
```

**Optimized serializer:**
```ruby
class KanjiUiSerializer
  include JSONAPI::Serializer

  # Cache serialized output
  cache_options enabled: true, cache_length: 1.hour

  set_type :kanji
  set_id :character

  attributes :character, :meaning, :jlpt_level, :stroke_count
  # ... other attributes
end
```

---

## 📊 Monitoring

### 1. Performance Metrics

#### API Response Times

**Targets:**
```
Cached request: < 100ms
Uncached request: < 2s
```

#### Check current performance:
```bash
# In Rails console
docker-compose exec web rails c

# Benchmark API call
require 'benchmark'
Benchmark.measure {
  KanjiUiSerializer.new(Kanji.find("一")).as_json
}
```

### 2. Cache Monitoring

#### Cache Hit Rate

```bash
# Connect to Redis
docker-compose exec redis redis-cli

# Check stats
INFO stats

# Look for:
# keyspace_hits: <number>
# keyspace_misses: <number>

# Calculate hit rate:
# hit_rate = hits / (hits + misses) * 100
```

**Target:** > 95% hit rate

#### View Cached Keys

```bash
# List all cache keys
docker-compose exec redis redis-cli KEYS "kanji_ui_format:*"

# Count cached kanjis
docker-compose exec redis redis-cli KEYS "kanji_ui_format:*" | wc -l

# View specific cache entry
docker-compose exec redis redis-cli GET "kanji_ui_format:一"
```

#### Clear Cache

```bash
# Clear all cache
docker-compose exec redis redis-cli FLUSHDB

# Clear specific key
docker-compose exec redis redis-cli DEL "kanji_ui_format:一"

# Clear by pattern
docker-compose exec redis redis-cli --scan --pattern "kanji_ui_format:*" | \
  xargs docker-compose exec -T redis redis-cli DEL
```

### 3. Rate Limit Monitoring

#### Check Rate Limit Status

```bash
# Connect to Redis
docker-compose exec redis redis-cli

# View rate limit keys
KEYS "rack::attack:*"

# Check specific IP's current count
GET "rack::attack:{timestamp}:ui_format/ip:{ip_address}"
```

#### View Blocked Requests

```bash
# In Rails logs
docker-compose logs web | grep "429"
docker-compose logs web | grep "403"
```

---

## 🛡️ Security Best Practices

### 1. Environment Variables

**Never commit:**
```bash
# .env (gitignored)
DATABASE_URL=mysql2://user:pass@host/db
REDIS_URL=redis://host:6379/0
SECRET_KEY_BASE=your_secret_key
```

**Use Rails credentials:**
```bash
# Edit encrypted credentials
EDITOR=nano rails credentials:edit

# Access in code
Rails.application.credentials.secret_key_base
```

### 2. API Authentication (Future)

**Add JWT authentication:**
```ruby
# Gemfile
gem "devise"
gem "devise-jwt"

# Generate token
token = JWT.encode(payload, Rails.application.credentials.secret_key_base)

# Verify token
JWT.decode(token, Rails.application.credentials.secret_key_base)
```

**Protect endpoints:**
```ruby
class Api::V1::KanjisController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
end
```

### 3. HTTPS in Production

**Force SSL:**
```ruby
# config/environments/production.rb
config.force_ssl = true
```

**SSL Certificate (Let's Encrypt):**
```bash
# Using Certbot
certbot certonly --standalone -d api.your-domain.com
```

---

## 🔧 Configuration Files

### Rate Limiting

**File:** `config/initializers/rack_attack.rb`

**Key configurations:**
```ruby
# Cache store
Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
)

# Throttle rules
throttle("ui_format/ip", limit: 30, period: 1.minute)

# Custom responses
self.throttled_responder = lambda do |env|
  [429, { "Content-Type" => "application/json" }, [...]]
end
```

### Caching

**File:** `config/environments/development.rb`

**Key configurations:**
```ruby
# Enable caching
config.action_controller.perform_caching = true

# Redis cache store
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL"),
  namespace: "nhaituvung_dev_cache",
  expires_in: 90.minutes
}
```

### CORS

**File:** `config/initializers/cors.rb`

**Configuration:**
```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_URL", "http://localhost:3000")
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
```

---

## 📈 Scaling Recommendations

### 1. Horizontal Scaling

**Load Balancer:**
```
User → Load Balancer → [App Server 1, App Server 2, App Server 3]
                              ↓
                        Shared Redis & MySQL
```

**Docker Compose scaling:**
```bash
docker-compose up -d --scale web=3
```

### 2. Redis Scaling

**Redis Cluster:**
```yaml
# docker-compose.yml
redis-master:
  image: redis:7-alpine

redis-replica-1:
  image: redis:7-alpine
  command: redis-server --slaveof redis-master 6379
```

### 3. Database Scaling

**Read Replicas:**
```ruby
# config/database.yml
production:
  primary:
    url: <%= ENV["PRIMARY_DATABASE_URL"] %>

  replica:
    url: <%= ENV["REPLICA_DATABASE_URL"] %>
    replica: true
```

**Use replicas:**
```ruby
# Read from replica
ActiveRecord::Base.connected_to(role: :reading) do
  Kanji.find("一")
end
```

---

## 🚨 Alerts & Monitoring

### 1. Application Performance Monitoring (APM)

**Recommended tools:**
- New Relic
- Datadog
- Scout APM

### 2. Log Aggregation

**Recommended tools:**
- Papertrail
- Loggly
- ELK Stack

### 3. Uptime Monitoring

**Recommended tools:**
- Pingdom
- UptimeRobot
- StatusCake

### 4. Custom Alerts

**Monitor these metrics:**
```ruby
# config/initializers/monitoring.rb

# Alert if response time > 2s
ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  if event.duration > 2000
    # Send alert
  end
end

# Alert if cache hit rate < 90%
if cache_hit_rate < 0.9
  # Send alert
end

# Alert if rate limit triggers > 100/hour
if rate_limit_triggers_per_hour > 100
  # Send alert
end
```

---

## 🔄 Maintenance Tasks

### Daily Tasks

```bash
# Check Redis memory
docker-compose exec redis redis-cli INFO memory

# Check disk space
docker-compose exec web df -h

# Check logs for errors
docker-compose logs web --tail=100 | grep ERROR
```

### Weekly Tasks

```bash
# Analyze slow queries
docker-compose exec db mysql -uroot -ppassword -D nhaituvung_api_development \
  -e "SELECT * FROM mysql.slow_log LIMIT 10;"

# Check database size
docker-compose exec db mysql -uroot -ppassword -D nhaituvung_api_development \
  -e "SELECT table_name, ROUND((data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' \
      FROM information_schema.tables WHERE table_schema = 'nhaituvung_api_development';"

# Backup database
docker-compose exec db mysqldump -uroot -ppassword nhaituvung_api_development > backup.sql
```

### Monthly Tasks

```bash
# Update dependencies
docker-compose exec web bundle update

# Security audit
docker-compose exec web bundle audit

# Database optimization
docker-compose exec db mysql -uroot -ppassword -D nhaituvung_api_development \
  -e "OPTIMIZE TABLE kanjis, kanji_examples, kanji_compositions, textbook_references;"
```

---

## 📝 Troubleshooting Guide

### Issue: High Response Times

**Diagnosis:**
```bash
# Check database queries
docker-compose logs web | grep "SELECT"

# Check cache hit rate
docker-compose exec redis redis-cli INFO stats

# Check server load
docker stats
```

**Solutions:**
1. Add missing indexes
2. Increase cache TTL
3. Optimize N+1 queries
4. Add more Redis memory

### Issue: Cache Not Working

**Diagnosis:**
```bash
# Check Redis connection
docker-compose exec web rails runner "puts Rails.cache.redis.ping"

# Check cache keys
docker-compose exec redis redis-cli KEYS "*"

# Test manual cache
docker-compose exec web rails runner "Rails.cache.write('test', 'value'); puts Rails.cache.read('test')"
```

**Solutions:**
1. Verify Redis is running
2. Check REDIS_URL env var
3. Restart Rails server
4. Clear corrupted cache: `docker-compose exec redis redis-cli FLUSHDB`

### Issue: Rate Limiting Too Aggressive

**Diagnosis:**
```bash
# Check current rate limits
grep "limit:" config/initializers/rack_attack.rb

# Check blocked IPs
docker-compose logs web | grep "429"
```

**Solutions:**
1. Increase limits in `rack_attack.rb`
2. Whitelist specific IPs
3. Adjust time periods
4. Add exponential backoff

---

**Last Updated:** 2025-12-01
**Version:** 1.0
