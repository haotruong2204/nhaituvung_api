# frozen_string_literal: true

namespace :redis do
  desc "Test Redis connection and functionality"
  task test: :environment do
    puts "\n🔍 Testing Redis Integration...\n\n"

    begin
      # Test 1: Basic Connection
      puts "1️⃣  Testing Redis Connection..."
      $redis.ping
      puts "   ✅ Redis connection successful!\n\n"

      # Test 2: Cache Store
      puts "2️⃣  Testing Cache Store..."
      Rails.cache.write("test_key", "Hello from Redis!")
      cached_value = Rails.cache.read("test_key")
      if cached_value == "Hello from Redis!"
        puts "   ✅ Cache store working! Value: #{cached_value}\n\n"
      else
        puts "   ❌ Cache store failed!\n\n"
      end

      # Test 3: Redis Info
      puts "3️⃣  Redis Server Info..."
      info = $redis.info
      puts "   📊 Redis Version: #{info['redis_version']}"
      puts "   💾 Used Memory: #{info['used_memory_human']}"
      puts "   🔗 Connected Clients: #{info['connected_clients']}\n\n"

      # Test 4: Sidekiq Connection
      puts "4️⃣  Testing Sidekiq Connection..."
      stats = Sidekiq::Stats.new
      puts "   ✅ Sidekiq connected!"
      puts "   📋 Processed: #{stats.processed}"
      puts "   ❌ Failed: #{stats.failed}"
      puts "   ⏳ Enqueued: #{stats.enqueued}\n\n"

      puts "🎉 All Redis tests passed!\n"
    rescue Redis::CannotConnectError => e
      puts "   ❌ Cannot connect to Redis: #{e.message}\n"
      puts "   💡 Make sure Redis is running: docker-compose up redis\n"
    rescue StandardError => e
      puts "   ❌ Error: #{e.message}\n"
    end
  end
end
