# 📁 Cấu trúc Dự án nhaituvung_api

> **Tổng quan về cấu trúc thư mục và file quan trọng**

---

## 📂 Root Directory

```
nhaituvung_api/
├── 📁 app/                    # Application code
├── 📁 bin/                    # Executables
├── 📁 config/                 # Configuration
├── 📁 db/                     # Database
├── 📁 docs/                   # 📚 Documentation
├── 📁 lib/                    # Libraries
├── 📁 log/                    # Logs
├── 📁 public/                 # Public assets
├── 📁 scripts/                # 🛠️ Deployment scripts
├── 📁 spec/                   # Tests
├── 📁 storage/                # Active Storage
├── 📁 terraform/              # 🏗️ Infrastructure as Code
├── 📁 tmp/                    # Temporary files
├── 📁 vendor/                 # Vendor gems
├── 📄 .gitignore              # Git ignore rules
├── 📄 Dockerfile              # 🐳 Docker image config
├── 📄 Gemfile                 # Ruby dependencies
├── 📄 Gemfile.lock            # Locked dependencies
├── 📄 Rakefile                # Rake tasks
└── 📄 README.md               # 📖 Main documentation
```

---

## 📚 Documentation (`docs/`)

```
docs/
├── COMPLETE_GUIDE.md          # 📘 Tài liệu tổng quan (400+ lines)
│   ├── 1. Tổng quan dự án
│   ├── 2. Kiến trúc hệ thống
│   ├── 3. Setup môi trường local
│   ├── 4. Docker & Containerization
│   ├── 5. Infrastructure as Code (Terraform)
│   ├── 6. Deployment Process
│   ├── 7. CI/CD Pipeline
│   ├── 8. Monitoring & Logging
│   ├── 9. Staging to Production
│   └── 10. Troubleshooting
│
├── DEPLOY_GUIDE.md            # 🚀 Hướng dẫn deploy (300+ lines)
│   ├── Scripts tóm tắt
│   ├── Yêu cầu hệ thống
│   ├── Lần đầu setup
│   ├── Deploy thường ngày (4 kịch bản)
│   ├── Chi tiết các scripts
│   ├── Troubleshooting
│   └── Monitoring & Logs
│
├── TERRAFORM_GUIDE.md         # 🏗️ Infrastructure (500+ lines)
│   ├── Giới thiệu Terraform
│   ├── Cấu trúc Terraform
│   ├── Module VPC
│   ├── Module ECS
│   ├── Module RDS
│   ├── Module ALB
│   ├── Environment Configuration
│   └── Best Practices
│
├── STATIC_IP_SOLUTIONS.md     # 🌐 Networking solutions
│   ├── ALB (Application Load Balancer)
│   ├── Elastic IP
│   ├── CloudFront + Origin
│   ├── So sánh chi phí
│   └── Khuyến nghị
│
└── PROJECT_STRUCTURE.md       # 📁 File này
```

---

## 🛠️ Scripts (`scripts/`)

```
scripts/
├── README.md                  # 📖 Hướng dẫn scripts
├── deploy.sh                  # 🚀 Deploy hoàn chỉnh
├── get-url.sh                 # 🌐 Lấy URL ứng dụng
├── logs.sh                    # 📝 Xem logs realtime
├── status.sh                  # 📊 Xem status service
├── start.sh                   # ▶️  Start service
├── stop.sh                    # ⏸️  Stop service
├── ssh.sh                     # 🔌 SSH vào container
└── migrate.sh                 # 🗄️  Run migrations
```

**Tất cả scripts đều:**
- ✅ Có quyền thực thi (`chmod +x`)
- ✅ User-friendly messages
- ✅ Error handling đầy đủ
- ✅ Emoji cho dễ đọc

---

## 🏗️ Terraform (`terraform/`)

```
terraform/
├── modules/                   # Reusable modules
│   ├── vpc/
│   │   ├── main.tf           # VPC resources
│   │   ├── variables.tf      # Input variables
│   │   └── outputs.tf        # Output values
│   │
│   ├── ecs/
│   │   ├── main.tf           # ECS cluster, service, task
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── rds/
│   │   ├── main.tf           # RDS instance, subnet group
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── alb/                  # (Future - Production)
│       ├── main.tf           # Application Load Balancer
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/              # Environment-specific configs
    ├── dev/                  # Development (Current: Staging)
    │   ├── main.tf           # Main configuration
    │   ├── variables.tf      # Variable definitions
    │   ├── outputs.tf        # Output values
    │   ├── terraform.tfvars  # Variable values (GITIGNORED!)
    │   └── backend.tf        # Remote state (Future)
    │
    ├── staging/              # Staging (Future)
    │   └── (same structure)
    │
    └── prod/                 # Production (Future)
        └── (same structure)
```

**Note:**
- `terraform.tfvars` chứa secrets → **KHÔNG COMMIT**
- Use `.tfvars.example` để document

---

## 💎 Application (`app/`)

```
app/
├── controllers/
│   ├── application_controller.rb
│   └── api/
│       └── v1/
│           ├── users_controller.rb
│           ├── vocabularies_controller.rb
│           └── ...
│
├── models/
│   ├── application_record.rb
│   ├── user.rb
│   ├── vocabulary.rb
│   └── ...
│
├── serializers/             # JSON API serializers
│   ├── user_serializer.rb
│   └── vocabulary_serializer.rb
│
├── jobs/                    # Background jobs
│   └── application_job.rb
│
├── mailers/                 # Email templates
│   └── application_mailer.rb
│
└── views/
    └── layouts/
        └── application.html.erb
```

---

## ⚙️ Configuration (`config/`)

```
config/
├── application.rb            # Rails application config
├── boot.rb                   # Boot config
├── environment.rb            # Environment loader
├── routes.rb                 # 🛣️ API routes
├── database.yml              # 🗄️ Database config
├── credentials.yml.enc       # 🔐 Encrypted credentials
├── master.key                # 🔑 Master key (GITIGNORED!)
│
├── environments/
│   ├── development.rb       # Dev environment
│   ├── production.rb        # Prod environment
│   └── test.rb              # Test environment
│
├── initializers/            # Initializers
│   ├── cors.rb              # CORS config
│   ├── filter_parameter_logging.rb
│   └── ...
│
└── locales/                 # I18n translations
    ├── en.yml
    ├── vi.yml
    └── ja.yml
```

---

## 🗄️ Database (`db/`)

```
db/
├── migrate/                 # Migration files
│   ├── 20241029_create_users.rb
│   ├── 20241029_create_vocabularies.rb
│   └── ...
│
├── seeds.rb                 # Seed data
├── schema.rb                # Database schema
└── structure.sql            # SQL structure (if using)
```

---

## 🧪 Tests (`spec/`)

```
spec/
├── spec_helper.rb           # RSpec config
├── rails_helper.rb          # Rails-specific config
│
├── controllers/
│   └── api/
│       └── v1/
│           └── users_controller_spec.rb
│
├── models/
│   ├── user_spec.rb
│   └── vocabulary_spec.rb
│
├── requests/                # Request specs
│   └── api/
│       └── v1/
│           └── users_spec.rb
│
├── factories/               # Test factories
│   ├── users.rb
│   └── vocabularies.rb
│
└── support/                 # Test helpers
    └── api_helpers.rb
```

---

## 🐳 Docker Files

### Dockerfile
```dockerfile
FROM ruby:3.3.4-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential default-libmysqlclient-dev git

# Set working directory
WORKDIR /app

# Copy Gemfile
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy application
COPY . .

# Expose port
EXPOSE 3000

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### docker-compose.yml (Local Development)
```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: nhaituvung_development
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql

  app:
    build: .
    command: bundle exec rails server -b 0.0.0.0
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: mysql2://root:password@db:3306/nhaituvung_development
    depends_on:
      - db

volumes:
  mysql_data:
```

---

## 📦 Gemfile (Key Dependencies)

```ruby
# Gemfile

# Core
gem 'rails', '~> 8.0.2'
gem 'mysql2', '~> 0.5'
gem 'puma', '>= 5.0'

# API
gem 'jbuilder'
gem 'rack-cors'

# Authentication
gem 'devise'
gem 'devise-jwt'

# Serialization
gem 'active_model_serializers'

# Background Jobs (Future)
# gem 'sidekiq'

# File Upload (Future)
# gem 'aws-sdk-s3'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'pry-rails'
end

group :development do
  gem 'annotate'
  gem 'bullet'
end

group :test do
  gem 'simplecov', require: false
  gem 'shoulda-matchers'
end
```

---

## 🔒 .gitignore

```gitignore
# Important files to ignore

# Environment
.env
.env.*

# Terraform
terraform/**/*.tfvars
terraform/**/.terraform/
terraform/**/*.tfstate*

# Rails
/log/*
/tmp/*
/storage/*
config/master.key
config/credentials/production.key

# Database
*.sqlite3
*.sqlite3-journal

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
```

---

## 🎯 Important Files

### Routes (`config/routes.rb`)
```ruby
Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API
  namespace :api do
    namespace :v1 do
      resources :users
      resources :vocabularies
      
      # Authentication
      post 'auth/login', to: 'authentication#login'
      post 'auth/logout', to: 'authentication#logout'
      
      # Learning
      resources :learning_progress
      resources :quiz_sessions
    end
  end
end
```

### Database Config (`config/database.yml`)
```yaml
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: <%= ENV.fetch("DATABASE_USERNAME", "root") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD", "password") %>
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
  port: <%= ENV.fetch("DATABASE_PORT", "3306") %>

development:
  <<: *default
  database: nhaituvung_development

test:
  <<: *default
  database: nhaituvung_test

production:
  <<: *default
  database: <%= ENV.fetch("DATABASE_NAME") %>
```

---

## 📊 File Statistics

### Code Base
- **Total Files:** ~200+
- **Total Lines:** ~10,000+
- **Documentation:** 1,500+ lines
- **Scripts:** 300+ lines
- **Terraform:** 800+ lines

### Documentation Coverage
- ✅ Setup guide
- ✅ Deploy guide
- ✅ Infrastructure guide
- ✅ Scripts documentation
- ✅ Troubleshooting guide
- ✅ Architecture diagrams
- ✅ Best practices

---

## 🔍 Finding Files

### Quick search commands

```bash
# Find all controllers
find app/controllers -name "*.rb"

# Find all models
find app/models -name "*.rb"

# Find all specs
find spec -name "*_spec.rb"

# Find all migrations
find db/migrate -name "*.rb"

# Find documentation
find docs -name "*.md"

# Find scripts
ls -lah scripts/
```

---

## 📝 File Naming Conventions

### Controllers
```
snake_case_controller.rb
users_controller.rb
vocabularies_controller.rb
```

### Models
```
snake_case.rb
user.rb
vocabulary.rb
learning_progress.rb
```

### Specs
```
*_spec.rb
user_spec.rb
users_controller_spec.rb
```

### Migrations
```
YYYYMMDDHHMMSS_description.rb
20241029120000_create_users.rb
20241029120100_add_index_to_users.rb
```

### Terraform
```
main.tf        # Resources
variables.tf   # Inputs
outputs.tf     # Outputs
backend.tf     # State config
```

---

## 🎓 Learning Path

### 1. Bắt đầu
1. Đọc `README.md`
2. Xem `docs/COMPLETE_GUIDE.md`
3. Setup local environment

### 2. Deployment
1. Đọc `docs/DEPLOY_GUIDE.md`
2. Tìm hiểu `scripts/`
3. Practice deployment

### 3. Infrastructure
1. Đọc `docs/TERRAFORM_GUIDE.md`
2. Hiểu terraform modules
3. Practice infrastructure changes

### 4. Development
1. Xem `app/` structure
2. Đọc code examples
3. Write tests
4. Submit PR

---

## 🆘 Need Help?

| Question | Where to look |
|----------|---------------|
| How to deploy? | `docs/DEPLOY_GUIDE.md` |
| How to use scripts? | `scripts/README.md` |
| Infrastructure questions? | `docs/TERRAFORM_GUIDE.md` |
| Complete overview? | `docs/COMPLETE_GUIDE.md` |
| Project structure? | This file! |

---

**Last Updated:** October 29, 2025  
**Version:** 1.0.0
