# 📖 HƯỚNG DẪN DEPLOY THỦ CÔNG - TỪNG BƯỚC

> **Mục đích:** Hướng dẫn chi tiết từng bước để deploy Rails API lên AWS với domain và HTTPS

---

## 📋 MỤC LỤC

1. [Chuẩn bị](#1-chuẩn-bị)
2. [Tạo Infrastructure với Terraform](#2-tạo-infrastructure-với-terraform)
3. [Build và Push Docker Image](#3-build-và-push-docker-image)
4. [Deploy Application](#4-deploy-application)
5. [Chạy Database Migrations](#5-chạy-database-migrations)
6. [Kiểm tra và Test](#6-kiểm-tra-và-test)
7. [Quản lý và Maintenance](#7-quản-lý-và-maintenance)

---

## 1. CHUẨN BỊ

### 1.1. Kiểm tra môi trường

```bash
# Kiểm tra Ruby
ruby --version
# Expected: ruby 3.3.4

# Kiểm tra Rails
rails --version
# Expected: Rails 8.0.3

# Kiểm tra Docker
docker --version
# Expected: Docker version 20.10+

# Kiểm tra Terraform
terraform --version
# Expected: Terraform v1.0+

# Kiểm tra AWS CLI
aws --version
# Expected: aws-cli/2.0+
```

### 1.2. Xác nhận AWS credentials

```bash
# Kiểm tra AWS account
aws sts get-caller-identity

# Kết quả mong đợi:
# {
#     "UserId": "...",
#     "Account": "YOUR_AWS_ACCOUNT_ID",
#     "Arn": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:user/admin"
# }
```

### 1.3. Kiểm tra domain trong Route53

```bash
# Kiểm tra hosted zone
aws route53 list-hosted-zones --query 'HostedZones[?Name==`nhaikanji.com.`]'

# Lưu lại Hosted Zone ID
# Expected: Z0292892220G6OADIHM9E
```

---

## 2. TẠO INFRASTRUCTURE VỚI TERRAFORM

### 2.1. Di chuyển vào thư mục Terraform

```bash
cd /Users/haotruong/Desktop/nhaituvung_api/terraform/environments/production
```

### 2.2. Kiểm tra cấu hình

```bash
# Xem file terraform.tfvars
cat terraform.tfvars
```

**Đảm bảo có các thông tin:**
```hcl
project_name = "nhaituvung"
environment  = "production"
aws_region   = "ap-southeast-1"
aws_profile  = "default"

# Database
db_password = "YOUR_SECURE_PASSWORD_HERE"
db_name     = "nhaituvung_production"

# ECS
ecs_task_cpu    = "256"
ecs_task_memory = "512"

# Rails Secret (generate with: bundle exec rails secret)
secret_key_base = "YOUR_SECRET_KEY_BASE_HERE"

# Domain
domain_name      = "nhaikanji.com"
subdomain        = "api"
route53_zone_id  = "Z0292892220G6OADIHM9E"
enable_https     = true
```

### 2.3. Initialize Terraform

```bash
terraform init
```

**Kết quả mong đợi:**
- Terraform has been successfully initialized!

### 2.4. Plan infrastructure

```bash
terraform plan -out=tfplan
```

**Xem kỹ output:**
- Số lượng resources sẽ tạo: `Plan: 44 to add, 0 to change, 0 to destroy`

**Resources chính sẽ tạo:**
- VPC với 2 Availability Zones
- Public & Private Subnets
- Internet Gateway
- Security Groups (ALB, ECS, RDS, Redis)
- Application Load Balancer (ALB)
- Target Group
- ACM Certificate cho `api.nhaikanji.com`
- Route53 A Record
- ECS Cluster
- ECS Task Definition
- ECS Service
- RDS MySQL Database
- ElastiCache Redis
- ECR Repository
- CloudWatch Log Groups
- IAM Roles & Policies
- Auto Scaling Policies

### 2.5. Apply infrastructure

```bash
terraform apply "tfplan"
```

**Nhập:** `yes` khi được hỏi

**Thời gian chờ:** 15-20 phút
- RDS khởi động: ~10 phút
- Redis khởi động: ~5 phút
- ACM Certificate validation: ~5 phút (tự động qua DNS)

**Theo dõi tiến độ:**
```bash
# Trong terminal khác, theo dõi resources
watch -n 5 'terraform show | grep -E "resource|id ="'
```

### 2.6. Kiểm tra kết quả

```bash
# Xem summary
terraform output deployment_summary

# Lưu lại các thông tin quan trọng:
terraform output api_url              # https://api.nhaikanji.com
terraform output alb_dns_name         # ALB DNS name
terraform output ecr_repository_url   # ECR URL
terraform output certificate_arn      # ACM Certificate
```

**Verify từng thành phần:**

```bash
# 1. Check ACM Certificate
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw certificate_arn) \
  --query 'Certificate.Status' \
  --output text
# Expected: ISSUED

# 2. Check RDS
aws rds describe-db-instances \
  --db-instance-identifier nhaituvung-production-db \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text
# Expected: available

# 3. Check ECS Cluster
aws ecs describe-clusters \
  --clusters nhaituvung-production-cluster \
  --query 'clusters[0].status' \
  --output text
# Expected: ACTIVE

# 4. Check ECS Service
aws ecs describe-services \
  --cluster nhaituvung-production-cluster \
  --services nhaituvung-production-service \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}' \
  --output json
# Expected: Status: ACTIVE, Running: 0 (chưa có image), Desired: 2
```

---

## 3. BUILD VÀ PUSH DOCKER IMAGE

### 3.1. Quay về thư mục gốc

```bash
cd /Users/haotruong/Desktop/nhaituvung_api
```

### 3.2. Lấy ECR repository URL

```bash
cd terraform/environments/production
ECR_URL=$(terraform output -raw ecr_repository_url)
echo "ECR Repository: $ECR_URL"

# Quay về thư mục gốc
cd /Users/haotruong/Desktop/nhaituvung_api
```

### 3.3. Login vào ECR

```bash
# Login ECR
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin \
  YOUR_AWS_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com
```

**Kết quả mong đợi:** `Login Succeeded`

### 3.4. Build Docker image

```bash
# Build image
docker build -t nhaituvung-api .
```

**Thời gian:** 2-3 phút (lần đầu), ~30 giây (các lần sau nếu có cache)

**Theo dõi build:**
- Các layer được build
- Dependencies được install
- Application code được copy

### 3.5. Tag image

```bash
# Tag image với ECR URL
docker tag nhaituvung-api:latest \
  YOUR_AWS_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/nhaituvung-production-app:latest
```

### 3.6. Push image lên ECR

```bash
# Push image
docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/nhaituvung-production-app:latest
```

**Thời gian:** 1-2 phút

**Verify image đã push:**
```bash
aws ecr describe-images \
  --repository-name nhaituvung-production-app \
  --query 'imageDetails[0].[imageTags,imageSizeInBytes,imagePushedAt]' \
  --output table
```

---

## 4. DEPLOY APPLICATION

### 4.1. Force deployment để pull image mới

```bash
# ECS sẽ tự động pull image và start tasks
aws ecs update-service \
  --cluster nhaituvung-production-cluster \
  --service nhaituvung-production-service \
  --force-new-deployment \
  --region ap-southeast-1
```

### 4.2. Theo dõi deployment

```bash
# Xem status
aws ecs describe-services \
  --cluster nhaituvung-production-cluster \
  --services nhaituvung-production-service \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Deployments:deployments[*].{Status:status,Running:runningCount}}' \
  --output json
```

**Chờ cho đến khi:**
- `Running: 2`
- `Desired: 2`
- Deployment status: `PRIMARY`

**Thời gian:** 2-3 phút

### 4.3. Xem logs realtime

```bash
# Stream logs
aws logs tail /ecs/nhaituvung-production-app --follow --region ap-southeast-1
```

**Tìm các dòng quan trọng:**
- `Booting Puma`
- `Rails 8.0.3 application starting in production`
- `Redis initialized at redis://...`
- `Puma starting in single mode...`
- `Listening on http://0.0.0.0:3000`

**Nhấn Ctrl+C để thoát**

### 4.4. Kiểm tra task health

```bash
# Get task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster nhaituvung-production-cluster \
  --service-name nhaituvung-production-service \
  --query 'taskArns[0]' \
  --output text)

# Check health
aws ecs describe-tasks \
  --cluster nhaituvung-production-cluster \
  --tasks $TASK_ARN \
  --query 'tasks[0].{LastStatus:lastStatus,HealthStatus:healthStatus}' \
  --output json
```

**Expected:**
```json
{
    "LastStatus": "RUNNING",
    "HealthStatus": "HEALTHY"
}
```

---

## 5. CHẠY DATABASE MIGRATIONS

**⚠️ QUAN TRỌNG:** Application đã running nhưng chưa có database tables. Cần chạy migrations trước.

### 5.1. Cài đặt Session Manager Plugin (nếu chưa có)

```bash
# macOS
brew install --cask session-manager-plugin

# Verify
session-manager-plugin --version
```

### 5.2. Chạy migrations qua AWS Console (CÁCH DỄ NHẤT)

**Bước 1:** Truy cập ECS Console
```
https://ap-southeast-1.console.aws.amazon.com/ecs/v2/clusters/nhaituvung-production-cluster/services/nhaituvung-production-service/tasks
```

**Bước 2:** Click vào task đang chạy

**Bước 3:** Click tab "Execute command"

**Bước 4:** Command: `/bin/sh`

**Bước 5:** Click "Execute"

**Bước 6:** Trong terminal, chạy:
```bash
bundle exec rails db:migrate
bundle exec rails db:seed
exit
```

### 5.3. Hoặc dùng ECS Run Task (CÁCH TỰ ĐỘNG)

```bash
# Get subnet và security group
SUBNET=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=*nhaituvung-production-public*" \
  --query 'Subnets[0].SubnetId' \
  --output text)

SG=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=*nhaituvung-production-ecs*" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Run one-off task để chạy migrations
aws ecs run-task \
  --cluster nhaituvung-production-cluster \
  --task-definition nhaituvung-production-app:2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"app","command":["bundle","exec","rails","db:migrate","db:seed"]}]}' \
  --region ap-southeast-1
```

### 5.4. Verify migrations đã chạy

```bash
# Xem logs để tìm "Created X posts"
aws logs tail /ecs/nhaituvung-production-app --since 2m --region ap-southeast-1
```

**Tìm dòng:**
- `Created 5 posts` (hoặc số lượng tương tự)

---

## 6. KIỂM TRA VÀ TEST

### 6.1. Test health check

```bash
# HTTPS
curl -I https://api.nhaikanji.com/up

# Expected: HTTP/2 200
```

### 6.2. Test HTTP to HTTPS redirect

```bash
curl -I http://api.nhaikanji.com/up

# Expected: HTTP/1.1 301 Moved Permanently
# Location: https://api.nhaikanji.com:443/up
```

### 6.3. Test API endpoints

```bash
# List posts
curl https://api.nhaikanji.com/api/v1/posts | jq '.'

# Get single post
curl https://api.nhaikanji.com/api/v1/posts/1 | jq '.'

# Create post (nếu có authentication)
curl -X POST https://api.nhaikanji.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -d '{"post":{"title":"Test Post","content":"Test content","published":true}}'
```

### 6.4. Test Sidekiq UI

```bash
# Mở browser
open https://api.nhaikanji.com/sidekiq
```

### 6.5. Verify SSL Certificate

```bash
# Check certificate details
openssl s_client -connect api.nhaikanji.com:443 -servername api.nhaikanji.com < /dev/null | openssl x509 -noout -text | grep -E "Subject:|Issuer:|Not"

# Hoặc dùng browser
# → Click vào ô khóa trong address bar
# → View certificate
```

---

## 7. QUẢN LÝ VÀ MAINTENANCE

### 7.1. Xem logs

```bash
# Realtime logs
./scripts/logs.sh

# Hoặc
aws logs tail /ecs/nhaituvung-production-app --follow
```

### 7.2. SSH vào container

```bash
# Dùng script
./scripts/ssh.sh

# Trong container:
bundle exec rails console    # Rails console
ls -la                       # List files
cat log/production.log       # View logs
env                          # View environment variables
```

### 7.3. Check service status

```bash
./scripts/status.sh

# Hoặc
aws ecs describe-services \
  --cluster nhaituvung-production-cluster \
  --services nhaituvung-production-service \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Events:events[0:3]}' \
  --output json
```

### 7.4. Deploy code mới

```bash
# 1. Commit code
git add .
git commit -m "Your message"

# 2. Build và push image mới
./scripts/deploy-image.sh

# 3. Force deployment
./scripts/deploy.sh

# 4. Kiểm tra
./scripts/status.sh
./scripts/logs.sh
```

### 7.5. Chạy migrations mới

```bash
# 1. Tạo migration
bundle exec rails generate migration YourMigration

# 2. Deploy code
./scripts/deploy-image.sh
./scripts/deploy.sh

# 3. Chạy migration
./scripts/migrate.sh
```

### 7.6. Scale up/down

```bash
# Scale up (thêm tasks)
aws ecs update-service \
  --cluster nhaituvung-production-cluster \
  --service nhaituvung-production-service \
  --desired-count 4

# Scale down
aws ecs update-service \
  --cluster nhaituvung-production-cluster \
  --service nhaituvung-production-service \
  --desired-count 1
```

### 7.7. Stop service (tiết kiệm chi phí)

```bash
# Stop ECS
./scripts/stop.sh

# Stop RDS
aws rds stop-db-instance \
  --db-instance-identifier nhaituvung-production-db

# Start lại khi cần
./scripts/start.sh
aws rds start-db-instance \
  --db-instance-identifier nhaituvung-production-db
```

### 7.8. Destroy toàn bộ

```bash
cd terraform/environments/production
terraform destroy

# Nhập: yes
```

---

## 📊 CHECKLIST DEPLOY THÀNH CÔNG

### Infrastructure
- [ ] Terraform apply thành công (44 resources)
- [ ] ACM Certificate status: ISSUED
- [ ] RDS status: available
- [ ] Redis status: available
- [ ] ECS Cluster: ACTIVE
- [ ] ALB: running

### Application
- [ ] Docker image đã push lên ECR
- [ ] ECS tasks running: 2/2
- [ ] Tasks health: HEALTHY
- [ ] Logs hiển thị "Puma listening on port 3000"

### Database
- [ ] Migrations đã chạy thành công
- [ ] Seeds đã tạo dữ liệu mẫu
- [ ] API endpoint trả về dữ liệu

### Domain & SSL
- [ ] https://api.nhaikanji.com/up → 200 OK
- [ ] http://api.nhaikanji.com → redirect to HTTPS
- [ ] SSL certificate valid
- [ ] API endpoints hoạt động qua HTTPS

---

## 🐛 TROUBLESHOOTING

### Issue: ACM Certificate không validate

**Nguyên nhân:** DNS records chưa được tạo

**Giải pháp:**
```bash
# Kiểm tra DNS records
aws route53 list-resource-record-sets \
  --hosted-zone-id Z0292892220G6OADIHM9E \
  --query 'ResourceRecordSets[?Type==`CNAME`]'

# Nếu chưa có, Terraform sẽ tự tạo
# Chờ 5-10 phút
```

### Issue: ECS tasks không start

**Nguyên nhân:** Image không có trong ECR hoặc task không pull được

**Giải pháp:**
```bash
# 1. Check image trong ECR
aws ecr describe-images --repository-name nhaituvung-production-app

# 2. Check ECS events
aws ecs describe-services \
  --cluster nhaituvung-production-cluster \
  --services nhaituvung-production-service \
  --query 'services[0].events[0:5]'

# 3. Check logs
aws logs tail /ecs/nhaituvung-production-app --since 10m
```

### Issue: API không trả về dữ liệu

**Nguyên nhân:** Chưa chạy migrations

**Giải pháp:**
```bash
# Chạy migrations theo hướng dẫn Bước 5
./scripts/migrate.sh
# hoặc dùng AWS Console
```

### Issue: Cannot connect to database

**Nguyên nhân:** Security group chưa đúng hoặc RDS chưa ready

**Giải pháp:**
```bash
# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier nhaituvung-production-db

# Check security groups
aws ec2 describe-security-groups \
  --group-ids $(aws ecs describe-services \
    --cluster nhaituvung-production-cluster \
    --services nhaituvung-production-service \
    --query 'services[0].networkConfiguration.awsvpcConfiguration.securityGroups[0]' \
    --output text)
```

---

## 💰 CHI PHÍ DỰ KIẾN

**Chạy 24/7:**
- RDS MySQL (db.t3.small): ~$30/tháng
- ElastiCache Redis (cache.t3.small): ~$25/tháng
- ECS Fargate (2 tasks @ 256 CPU/512 MB): ~$20/tháng
- ALB: ~$16/tháng
- Data transfer + CloudWatch: ~$7/tháng
- Route53: ~$0.5/tháng
- **TỔNG: ~$98.5/tháng**

**Khi stop (ECS=0, RDS stopped):**
- ALB: ~$16/tháng (không stop được)
- Redis: ~$25/tháng (không stop được)
- RDS storage: ~$2/tháng
- CloudWatch: ~$0.5/tháng
- **TỔNG: ~$43.5/tháng**

---

## 📚 TÀI LIỆU THAM KHẢO

- AWS ECS Documentation: https://docs.aws.amazon.com/ecs/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Rails Deployment: https://guides.rubyonrails.org/deployment.html
- Docker Best Practices: https://docs.docker.com/develop/dev-best-practices/

---

**Created:** 2025-11-22
**Author:** Claude Code
**Version:** 1.0.0
