# 📚 Tài liệu Đầy đủ - Dự án nhaituvung_api

> **Hướng dẫn toàn diện từ A-Z: Build, Deploy và Scale Rails API lên AWS ECS**

---

## 📋 Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Setup môi trường local](#3-setup-môi-trường-local)
4. [Docker & Containerization](#4-docker--containerization)
5. [Infrastructure as Code (Terraform)](#5-infrastructure-as-code-terraform)
6. [Deployment Process](#6-deployment-process)
7. [CI/CD Pipeline](#7-cicd-pipeline)
8. [Monitoring & Logging](#8-monitoring--logging)
9. [Staging to Production](#9-staging-to-production)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Tổng quan dự án

### 1.1. Thông tin dự án

| Thông tin | Chi tiết |
|-----------|----------|
| **Tên dự án** | nhaituvung_api |
| **Mô tả** | Rails API cho ứng dụng học tiếng Nhật |
| **Tech Stack** | Ruby 3.3.4, Rails 8.0.2, MySQL 8.0 |
| **Cloud Provider** | AWS (Singapore - ap-southeast-1) |
| **Infrastructure** | ECS Fargate, RDS MySQL, ECR |
| **IaC Tool** | Terraform 1.0+ |

### 1.2. Kiến trúc tổng quan

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
                 ┌───────────────┐
                 │  CloudFront   │  (Optional - Future)
                 │     (CDN)     │
                 └───────┬───────┘
                         │
                         ▼
              ┌─────────────────────┐
              │  Application LB     │  (Optional - Future)
              │   (Static DNS)      │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │   ECS Service       │
              │   (Fargate Tasks)   │  ← Current: Dynamic IP
              │                     │
              │  - Rails App:3000   │
              │  - CPU: 512         │
              │  - Memory: 1024     │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │    RDS MySQL        │
              │   (db.t3.micro)     │
              │                     │
              │  - Storage: 20GB    │
              │  - Multi-AZ: No     │
              └─────────────────────┘
```

### 1.3. Chi phí dự kiến

#### **Staging Environment (Hiện tại)**
| Service | Cấu hình | Chi phí/tháng |
|---------|----------|---------------|
| ECS Fargate | 0.5 vCPU, 1GB RAM | ~$15 |
| RDS MySQL | db.t3.micro, 20GB | ~$15 |
| ECR Storage | ~2GB | ~$1 |
| CloudWatch Logs | Standard | ~$3 |
| Data Transfer | Minimal | ~$1 |
| **TỔNG STAGING** | | **~$35/tháng** |

#### **Production Environment (Tương lai)**
| Service | Cấu hình | Chi phí/tháng |
|---------|----------|---------------|
| ECS Fargate | 2 tasks x 1vCPU x 2GB | ~$90 |
| Application LB | Standard | ~$16 |
| RDS MySQL | db.t3.small, Multi-AZ, 100GB | ~$60 |
| ECR Storage | ~5GB | ~$2.5 |
| CloudWatch Logs | Enhanced | ~$10 |
| CloudFront | Optional | ~$5 |
| Route53 | 1 hosted zone | ~$0.5 |
| ACM Certificate | Free | $0 |
| **TỔNG PRODUCTION** | | **~$184/tháng** |

---

## 2. Kiến trúc hệ thống

### 2.1. AWS Resources

```
AWS Account: 917914785208
Region: ap-southeast-1 (Singapore)
Profile: nhaituvung

Resources:
├── VPC (10.0.0.0/16)
│   ├── Public Subnet (10.0.1.0/24)
│   ├── Private Subnet (10.0.2.0/24)
│   ├── Internet Gateway
│   └── Route Tables
│
├── ECS
│   ├── Cluster: nhaituvung-staging-cluster
│   ├── Service: nhaituvung-staging-service
│   └── Task Definition: nhaituvung-staging-app
│
├── ECR
│   └── Repository: nhaituvung-staging-app
│
├── RDS
│   └── Instance: nhaituvung-staging-db
│       ├── Engine: MySQL 8.0
│       ├── Class: db.t3.micro
│       └── Storage: 20GB
│
├── Security Groups
│   ├── ECS SG (allow 3000)
│   └── RDS SG (allow 3306 from ECS)
│
├── IAM Roles
│   ├── ECS Task Execution Role
│   └── ECS Task Role
│
└── CloudWatch
    └── Log Group: /ecs/nhaituvung-staging-app
```

### 2.2. Network Flow

```
Request Flow:
1. User → Public IP:3000
2. ECS Task → Process Request
3. Rails App → Query Database
4. RDS MySQL → Return Data
5. Rails App → Render Response
6. User ← JSON Response

Database Connection:
ECS Task → Security Group → RDS Security Group → MySQL:3306
```

### 2.3. Data Flow

```
┌──────────────┐
│   Developer  │
└──────┬───────┘
       │ git push
       ▼
┌──────────────┐
│    GitHub    │
└──────┬───────┘
       │ (Future: GitHub Actions)
       ▼
┌──────────────┐
│  Local Build │
└──────┬───────┘
       │ ./scripts/deploy.sh
       ▼
┌──────────────┐     ┌──────────────┐
│  Docker Hub  │────▶│     ECR      │
└──────────────┘     └──────┬───────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  ECS Service │
                     └──────┬───────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  RDS MySQL   │
                     └──────────────┘
```

---

## 3. Setup môi trường local

### 3.1. Yêu cầu hệ thống

```bash
# Kiểm tra version
ruby --version    # >= 3.3.4
rails --version   # >= 8.0.2
docker --version  # >= 20.10.0
terraform version # >= 1.0.0
aws --version     # >= 2.0.0
git --version     # >= 2.30.0
```

### 3.2. Cài đặt dependencies

#### **macOS**
```bash
# 1. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Ruby (via rbenv)
brew install rbenv ruby-build
rbenv install 3.3.4
rbenv global 3.3.4

# 3. MySQL
brew install mysql@8.0
brew services start mysql@8.0

# 4. Docker Desktop
brew install --cask docker

# 5. AWS CLI
brew install awscli

# 6. Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# 7. jq (for scripts)
brew install jq
```

#### **Ubuntu/Debian**
```bash
# 1. Ruby
sudo apt update
sudo apt install -y rbenv
rbenv install 3.3.4

# 2. MySQL
sudo apt install -y mysql-server

# 3. Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 4. AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 5. Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 3.3. Clone và setup project

```bash
# 1. Clone repository
git clone <repository-url> nhaituvung_api
cd nhaituvung_api

# 2. Install gems
bundle install

# 3. Setup database
rails db:create
rails db:migrate
rails db:seed

# 4. Run local server
rails server

# Test: http://localhost:3000/up
```

### 3.4. AWS Credentials Setup

```bash
# 1. Tạo AWS profile
aws configure --profile nhaituvung
# AWS Access Key ID: <your-key>
# AWS Secret Access Key: <your-secret>
# Default region: ap-southeast-1
# Default output format: json

# 2. Verify
aws sts get-caller-identity --profile nhaituvung

# Output:
# {
#     "UserId": "AIDAXXXXXXXXXXXXX",
#     "Account": "917914785208",
#     "Arn": "arn:aws:iam::917914785208:user/haotruong"
# }

# 3. Test ECR access
aws ecr describe-repositories --profile nhaituvung --region ap-southeast-1
```

---

## 4. Docker & Containerization

### 4.1. Dockerfile Architecture

```dockerfile
# File: Dockerfile
FROM ruby:3.3.4-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy application
COPY . .

# Precompile assets (if needed)
# RUN bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### 4.2. Docker Build Process

```bash
# 1. Build locally
docker build -t nhaituvung-app .

# 2. Test locally
docker run -p 3000:3000 \
  -e DATABASE_URL="mysql2://user:pass@host:3306/db" \
  nhaituvung-app

# 3. Check logs
docker logs <container-id>

# 4. Shell into container
docker exec -it <container-id> /bin/sh
```

### 4.3. Multi-stage Build (Optimize size)

```dockerfile
# Build stage
FROM ruby:3.3.4-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    git

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Runtime stage
FROM ruby:3.3.4-slim

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install -y \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application
COPY . .

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### 4.4. Docker Compose (Local Development)

```yaml
# File: docker-compose.yml
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
      - bundle_cache:/usr/local/bundle
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: mysql2://root:password@db:3306/nhaituvung_development
      RAILS_ENV: development
    depends_on:
      - db

volumes:
  mysql_data:
  bundle_cache:
```

---

## 5. Infrastructure as Code (Terraform)

### 5.1. Cấu trúc Terraform

```
terraform/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecs/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── alb/  (Future)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/
    ├── dev/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars
    ├── staging/
    │   └── (same structure)
    └── prod/
        └── (same structure)
```

### 5.2. Main Terraform Configuration

Xem file chi tiết tại: `docs/TERRAFORM_GUIDE.md`

### 5.3. Terraform Commands

```bash
# 1. Initialize
cd terraform/environments/dev
terraform init

# 2. Validate
terraform validate

# 3. Plan
terraform plan

# 4. Apply
terraform apply

# 5. Destroy (cẩn thận!)
terraform destroy

# 6. Show current state
terraform show

# 7. List resources
terraform state list

# 8. Output values
terraform output
```

---

## 6. Deployment Process

### 6.1. Quy trình Deploy Staging

#### **Bước 1: Code changes**
```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes
vim app/controllers/api/v1/users_controller.rb

# 3. Test locally
bundle exec rspec
bundle exec rubocop

# 4. Commit
git add .
git commit -m "Add new feature"

# 5. Push
git push origin feature/new-feature
```

#### **Bước 2: Deploy**
```bash
# 1. Merge to main
git checkout main
git merge feature/new-feature
git push

# 2. Deploy to staging
./scripts/deploy.sh

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 DEPLOY NHAITUVUNG API TO AWS ECS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 
# 📋 Lấy thông tin từ Terraform...
#    ✓ ECR Repository: xxx
#    ✓ Cluster: nhaituvung-staging-cluster
#    ✓ Service: nhaituvung-staging-service
# 
# 🔐 Bước 1/4: Login vào ECR...
#    ✓ Đăng nhập thành công!
# 
# 🏗️  Bước 2/4: Build Docker image...
#    ✓ Build thành công!
# 
# ⬆️  Bước 3/4: Push image lên ECR...
#    ✓ Push thành công!
# 
# ♻️  Bước 4/4: Redeploy ECS service...
#    ✓ Deployment đã được khởi động!
# 
# ✅ DEPLOY THÀNH CÔNG!
```

#### **Bước 3: Verify**
```bash
# 1. Wait for deployment
sleep 60

# 2. Get new URL
./scripts/get-url.sh

# 3. Test health check
curl http://<ip>:3000/up

# 4. Test API
curl http://<ip>:3000/api/v1/users

# 5. Check logs
./scripts/logs.sh
```

#### **Bước 4: Database Migration (nếu có)**
```bash
# 1. Run migration
./scripts/migrate.sh

# 2. Verify
./scripts/ssh.sh
# Trong container:
bundle exec rails console
> User.count
```

### 6.2. Rollback Process

```bash
# 1. List image tags in ECR
aws ecr describe-images \
  --repository-name nhaituvung-staging-app \
  --profile nhaituvung \
  --region ap-southeast-1 \
  --query 'imageDetails[*].[imageTags[0],imagePushedAt]' \
  --output table

# 2. Update task definition to use old image
vim terraform/environments/dev/main.tf
# Change image tag in container_definitions

# 3. Apply
cd terraform/environments/dev
terraform apply

# 4. Force redeploy
aws ecs update-service \
  --cluster nhaituvung-staging-cluster \
  --service nhaituvung-staging-service \
  --force-new-deployment \
  --profile nhaituvung \
  --region ap-southeast-1
```

---

## 7. CI/CD Pipeline

### 7.1. GitHub Actions Workflow

```yaml
# File: .github/workflows/deploy-staging.yml
name: Deploy to Staging

on:
  push:
    branches: [main]

env:
  AWS_REGION: ap-southeast-1
  ECR_REPOSITORY: nhaituvung-staging-app
  ECS_CLUSTER: nhaituvung-staging-cluster
  ECS_SERVICE: nhaituvung-staging-service

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: test
        ports:
          - 3306:3306
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.4
          bundler-cache: true
      
      - name: Run tests
        env:
          DATABASE_URL: mysql2://root:password@127.0.0.1:3306/test
          RAILS_ENV: test
        run: |
          bundle exec rails db:create
          bundle exec rails db:migrate
          bundle exec rspec
      
      - name: Run rubocop
        run: bundle exec rubocop

  deploy:
    needs: test
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
      
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster ${{ env.ECS_CLUSTER }} \
            --service ${{ env.ECS_SERVICE }} \
            --force-new-deployment
      
      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster ${{ env.ECS_CLUSTER }} \
            --services ${{ env.ECS_SERVICE }}
      
      - name: Notify Slack (optional)
        if: success()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{"text":"✅ Staging deployment successful!"}'
```

### 7.2. GitLab CI/CD

```yaml
# File: .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  AWS_REGION: ap-southeast-1
  ECR_REPOSITORY: nhaituvung-staging-app
  ECS_CLUSTER: nhaituvung-staging-cluster
  ECS_SERVICE: nhaituvung-staging-service

test:
  stage: test
  image: ruby:3.3.4
  services:
    - mysql:8.0
  variables:
    MYSQL_ROOT_PASSWORD: password
    MYSQL_DATABASE: test
    DATABASE_URL: mysql2://root:password@mysql:3306/test
  script:
    - bundle install
    - bundle exec rails db:create
    - bundle exec rails db:migrate
    - bundle exec rspec
    - bundle exec rubocop

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - apk add --no-cache python3 py3-pip
    - pip3 install awscli
    - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
  script:
    - docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$CI_COMMIT_SHA .
    - docker push $ECR_REGISTRY/$ECR_REPOSITORY:$CI_COMMIT_SHA
    - docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$CI_COMMIT_SHA $ECR_REGISTRY/$ECR_REPOSITORY:latest
    - docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

deploy:
  stage: deploy
  image: amazon/aws-cli
  script:
    - aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment
    - aws ecs wait services-stable --cluster $ECS_CLUSTER --services $ECS_SERVICE
  only:
    - main
```

---

## 8. Monitoring & Logging

### 8.1. CloudWatch Logs

```bash
# Xem logs realtime
./scripts/logs.sh

# Hoặc dùng AWS CLI
aws logs tail /ecs/nhaituvung-staging-app \
  --follow \
  --profile nhaituvung \
  --region ap-southeast-1

# Lọc ERROR logs
aws logs tail /ecs/nhaituvung-staging-app \
  --follow \
  --filter-pattern "ERROR" \
  --profile nhaituvung \
  --region ap-southeast-1

# Xem logs từ 1 giờ trước
aws logs tail /ecs/nhaituvung-staging-app \
  --since 1h \
  --profile nhaituvung \
  --region ap-southeast-1
```

### 8.2. CloudWatch Metrics

```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=nhaituvung-staging-service Name=ClusterName,Value=nhaituvung-staging-cluster \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average Maximum \
  --profile nhaituvung \
  --region ap-southeast-1

# Memory Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=nhaituvung-staging-service Name=ClusterName,Value=nhaituvung-staging-cluster \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average Maximum \
  --profile nhaituvung \
  --region ap-southeast-1
```

### 8.3. Application Performance Monitoring (Future)

**Sử dụng New Relic hoặc Datadog:**

```ruby
# Gemfile
gem 'newrelic_rpm'
# hoặc
gem 'ddtrace'

# config/newrelic.yml
production:
  license_key: <%= ENV['NEW_RELIC_LICENSE_KEY'] %>
  app_name: nhaituvung-api-production
```

---

## 9. Staging to Production

### 9.1. Khác biệt Staging vs Production

| Aspect | Staging | Production |
|--------|---------|------------|
| **Environment** | `staging` | `production` |
| **ECS Tasks** | 1 task | 2+ tasks (HA) |
| **Task Size** | 0.5 vCPU, 1GB | 1 vCPU, 2GB |
| **RDS Instance** | db.t3.micro | db.t3.small+ |
| **Multi-AZ** | No | Yes |
| **Load Balancer** | No (Dynamic IP) | Yes (ALB) |
| **Auto Scaling** | No | Yes |
| **Backup** | Daily | Hourly |
| **Monitoring** | Basic | Enhanced |
| **Domain** | IP-based | Custom domain |
| **SSL** | No | Yes (ACM) |
| **WAF** | No | Optional |
| **Chi phí** | ~$35/month | ~$184/month |

### 9.2. Tạo Production Environment

#### **Bước 1: Duplicate Terraform cho Production**

```bash
# 1. Copy staging to prod
cp -r terraform/environments/dev terraform/environments/prod

# 2. Update variables
vim terraform/environments/prod/terraform.tfvars
```

```hcl
# terraform/environments/prod/terraform.tfvars
environment     = "production"
aws_region      = "ap-southeast-1"
aws_profile     = "nhaituvung"

# ECS Configuration
ecs_task_cpu    = "1024"   # 1 vCPU
ecs_task_memory = "2048"   # 2 GB
ecs_desired_count = 2      # High Availability

# RDS Configuration
db_instance_class     = "db.t3.small"
db_allocated_storage  = 100
db_multi_az          = true
db_backup_retention  = 7
db_backup_window     = "03:00-04:00"

# Tags
tags = {
  Environment = "production"
  Project     = "nhaituvung"
  ManagedBy   = "terraform"
}
```

#### **Bước 2: Update main.tf cho Production**

```hcl
# terraform/environments/prod/main.tf

# Add Application Load Balancer
module "alb" {
  source = "../../modules/alb"
  
  name_prefix        = local.name_prefix
  vpc_id             = aws_vpc.main.id
  public_subnet_ids  = [aws_subnet.public.id, aws_subnet.public_2.id]
  container_port     = 3000
  certificate_arn    = var.acm_certificate_arn  # SSL Certificate
}

# Update ECS Service
resource "aws_ecs_service" "app" {
  name                               = "${local.name_prefix}-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.app.arn
  desired_count                      = var.ecs_desired_count  # 2
  launch_type                        = "FARGATE"
  
  # Health check grace period
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = [aws_subnet.private.id]  # Private subnet
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false  # No public IP needed with ALB
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "app"
    container_port   = 3000
  }

  # Auto Scaling
  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [module.alb]
}

# Add Auto Scaling
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${local.name_prefix}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
```

#### **Bước 3: Setup Domain & SSL**

```bash
# 1. Request SSL Certificate in ACM
aws acm request-certificate \
  --domain-name api.yourdomain.com \
  --validation-method DNS \
  --region ap-southeast-1 \
  --profile nhaituvung

# 2. Validate certificate (add DNS records)
# Follow AWS Console instructions

# 3. Create Route53 hosted zone
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference $(date +%s) \
  --profile nhaituvung

# 4. Add A record pointing to ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch file://dns-record.json \
  --profile nhaituvung
```

```json
// dns-record.json
{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "api.yourdomain.com",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z1234567890ABC",
        "DNSName": "nhaituvung-prod-alb-123456789.ap-southeast-1.elb.amazonaws.com",
        "EvaluateTargetHealth": true
      }
    }
  }]
}
```

#### **Bước 4: Deploy Production**

```bash
# 1. Initialize Terraform
cd terraform/environments/prod
terraform init

# 2. Plan
terraform plan

# 3. Apply
terraform apply

# 4. Verify
terraform output
```

#### **Bước 5: Deploy Application**

```bash
# 1. Update scripts/deploy.sh for production
export ENV=production  # hoặc tạo scripts/deploy-prod.sh

# 2. Deploy
./scripts/deploy-prod.sh

# 3. Run migrations
./scripts/migrate-prod.sh

# 4. Verify
curl https://api.yourdomain.com/up
```

### 9.3. Blue-Green Deployment Strategy

```bash
# 1. Deploy green environment
terraform apply -var="environment=production-green"

# 2. Update Route53 to point to green ALB (50/50 split)
# Test green environment

# 3. If OK, switch 100% traffic to green
# Update Route53 weighted routing

# 4. Destroy blue environment
terraform destroy -var="environment=production-blue"
```

### 9.4. Database Migration Strategy

#### **Zero-downtime migration approach:**

1. **Phase 1: Add new columns (backward compatible)**
   ```ruby
   class AddNewColumns < ActiveRecord::Migration[7.0]
     def change
       add_column :users, :new_email, :string
       # Keep old column
     end
   end
   ```

2. **Phase 2: Deploy code that writes to both columns**
   ```ruby
   def email=(value)
     self[:email] = value
     self[:new_email] = value
   end
   ```

3. **Phase 3: Backfill data**
   ```ruby
   User.find_each do |user|
     user.update(new_email: user.email)
   end
   ```

4. **Phase 4: Deploy code that reads from new column**
   ```ruby
   def email
     new_email || self[:email]
   end
   ```

5. **Phase 5: Remove old column**
   ```ruby
   class RemoveOldEmail < ActiveRecord::Migration[7.0]
     def change
       remove_column :users, :email
       rename_column :users, :new_email, :email
     end
   end
   ```

---

## 10. Troubleshooting

### 10.1. Common Issues

Xem chi tiết tại `docs/DEPLOY_GUIDE.md` section Troubleshooting

### 10.2. Emergency Procedures

#### **Rollback Production**
```bash
# 1. Quick rollback via AWS Console
# ECS → Service → Update → Revision (select previous)

# 2. Or via CLI
aws ecs update-service \
  --cluster nhaituvung-production-cluster \
  --service nhaituvung-production-service \
  --task-definition nhaituvung-production-app:PREVIOUS_REVISION \
  --profile nhaituvung \
  --region ap-southeast-1
```

#### **Database Recovery**
```bash
# 1. List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier nhaituvung-production-db \
  --profile nhaituvung \
  --region ap-southeast-1

# 2. Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier nhaituvung-production-db-restored \
  --db-snapshot-identifier rds:nhaituvung-production-db-2025-10-29-03-00 \
  --profile nhaituvung \
  --region ap-southeast-1
```

---

## 📚 Phụ lục

### A. Tài liệu tham khảo
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Rails Deployment Guide](https://guides.rubyonrails.org/deploying_rails_applications.html)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### B. Scripts Directory
- `scripts/README.md` - Chi tiết về scripts
- `docs/DEPLOY_GUIDE.md` - Hướng dẫn deploy
- `docs/STATIC_IP_SOLUTIONS.md` - Giải pháp IP tĩnh

### C. Contact & Support
- **Repository:** <your-repo-url>
- **Team Lead:** haotruong
- **Email:** <your-email>

---

**Cập nhật lần cuối:** 29/10/2025  
**Version:** 1.0.0  
**Tác giả:** haotruong
