# 🚀 nhaituvung_api

> **Rails API cho ứng dụng học tiếng Nhật - Deployed on AWS ECS**

[![Ruby](https://img.shields.io/badge/Ruby-3.3.4-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.0.2-red.svg)](https://rubyonrails.org/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-blue.svg)](https://www.mysql.com/)
[![AWS](https://img.shields.io/badge/AWS-ECS-orange.svg)](https://aws.amazon.com/ecs/)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-purple.svg)](https://www.terraform.io/)

---

## 📋 Mục lục

- [Tổng quan](#tổng-quan)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Deployment](#deployment)
- [Scripts](#scripts)
- [Architecture](#architecture)

---

## 🎯 Tổng quan

**nhaituvung_api** là một Rails API phục vụ ứng dụng học tiếng Nhật, cung cấp:

- ✅ RESTful API cho quản lý từ vựng JLPT (N1-N5)
- ✅ Authentication & Authorization
- ✅ User management
- ✅ Learning progress tracking
- ✅ Deployed trên AWS ECS Fargate
- ✅ Infrastructure as Code với Terraform

---

## 🛠️ Tech Stack

### Backend
- **Ruby:** 3.3.4
- **Rails:** 8.0.2
- **Database:** MySQL 8.0
- **Web Server:** Puma

### Infrastructure
- **Cloud:** AWS (Singapore - ap-southeast-1)
- **Container:** Docker
- **Orchestration:** ECS Fargate
- **Database:** RDS MySQL
- **Container Registry:** ECR
- **IaC:** Terraform
- **Monitoring:** CloudWatch

---

## 🚀 Quick Start

### Prerequisites

```bash
ruby 3.3.4
rails 8.0.2
mysql 8.0
docker 20.10+
terraform 1.0+
aws-cli 2.0+
```

### Local Development

```bash
# 1. Clone repository
git clone <repository-url>
cd nhaituvung_api

# 2. Install dependencies
bundle install

# 3. Setup database
rails db:create
rails db:migrate
rails db:seed

# 4. Run server
rails server

# 5. Test
curl http://localhost:3000/up
```

---

## 📚 Documentation

### 📖 Tài liệu đầy đủ

| Document | Description | Link |
|----------|-------------|------|
| **Complete Guide** | Tài liệu đầy đủ từ A-Z | [docs/COMPLETE_GUIDE.md](docs/COMPLETE_GUIDE.md) |
| **Deploy Guide** | Hướng dẫn deploy chi tiết | [docs/DEPLOY_GUIDE.md](docs/DEPLOY_GUIDE.md) |
| **Terraform Guide** | Infrastructure as Code | [docs/TERRAFORM_GUIDE.md](docs/TERRAFORM_GUIDE.md) |
| **Static IP Solutions** | Giải pháp IP tĩnh/Domain | [docs/STATIC_IP_SOLUTIONS.md](docs/STATIC_IP_SOLUTIONS.md) |
| **Scripts README** | Chi tiết về scripts | [scripts/README.md](scripts/README.md) |

---

## 🔧 Deployment

### Deploy to AWS Staging

```bash
# 1. Deploy code
./scripts/deploy.sh

# 2. Get application URL
./scripts/get-url.sh

# 3. Check logs
./scripts/logs.sh
```

### Available Scripts

| Script | Description |
|--------|-------------|
| `deploy.sh` | Build + Push + Deploy |
| `get-url.sh` | Lấy URL hiện tại |
| `logs.sh` | Xem logs realtime |
| `status.sh` | Xem trạng thái service |
| `migrate.sh` | Run database migrations |

Chi tiết: [scripts/README.md](scripts/README.md)

---

## 🏗️ Architecture

### Current (Staging)

```
Internet → Dynamic IP:3000 → ECS Fargate → RDS MySQL
```

### Future (Production)

```
Internet → Route53 → ALB → ECS Fargate (Auto Scaling) → RDS Multi-AZ
```

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/haotruong2204/nhaituvung_api/issues)
- **Maintainer:** haotruong

---

**Version:** 1.0.0  
**Last Updated:** October 29, 2025


2. Copy environment file:

```bash
cp .env.example .env
```

3. Build and start containers:

```bash
docker-compose build
docker-compose up -d
```

4. Create database:

```bash
docker-compose exec web rails db:create db:migrate db:seed
```

5. Access the application:

- API: http://localhost:3000
- Health check: http://localhost:3000/health

## API Endpoints

### Health Check

```
GET /health
```

### Posts API

```
GET    /api/v1/posts       # List all posts
GET    /api/v1/posts/:id   # Get single post
POST   /api/v1/posts       # Create post
PATCH  /api/v1/posts/:id   # Update post
DELETE /api/v1/posts/:id   # Delete post
```

## Docker Commands

```bash
# Build containers
docker-compose build

# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# View logs
docker-compose logs -f web

# Run Rails commands
docker-compose exec web rails console
docker-compose exec web rails db:migrate
```

## Deployment

Deployed to AWS using Terraform and GitHub Actions.

Region: Singapore (ap-southeast-1)
