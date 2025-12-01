source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.3"
# Use mysql as the database for Active Record
gem "mysql2", "~> 0.5"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use Redis for Rails.cache, Active Job, and Action Cable
gem "redis", "~> 5.0"
gem "hiredis-client", "~> 0.22"

# Use Sidekiq for background jobs
gem "sidekiq", "~> 7.0"
gem "sidekiq-status"
gem "sidekiq-scheduler"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

# Rate limiting and protection against abuse
gem "rack-attack"

# Api json serializer
gem "jsonapi-serializer"

# Paginate
gem "pagy"

# Search
gem "ransack"

# Strip attribute before commit
gem "strip_attributes"

# Config common variables
gem "config"

# Docs API
gem "rswag"

# Request third party api
gem "httparty"

# Authentication
gem "devise"
gem "devise-jwt"
gem "oauth"

group :development, :test do
  gem "pry-byebug"
  gem "pry-rails"

  # Convention
  gem "rubocop", require: false
  gem "rubocop-performance"
  gem "rubocop-rspec"
  gem "rubocop-rake"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Environment variables
  gem "dotenv-rails"

  # Unit Test
  gem "rspec"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "database_cleaner"
  gem "faker", git: "https://github.com/faker-ruby/faker.git", branch: "main"
end

group :development do
  # Schema in model
  gem "annotate"
end

group :test do
  # Use system testing
  gem "shoulda-matchers", "~> 3.1"
  gem "simplecov", require: false
end
