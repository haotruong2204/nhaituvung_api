# 🚀 Quy trình Deploy nhaituvung_api lên AWS ECS

> **Hướng dẫn đầy đủ từ A-Z để deploy Rails API lên AWS ECS Fargate**

---

## 📋 Mục lục

1. [Scripts tóm tắt](#scripts-tóm-tắt)
2. [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
3. [Kiến trúc hệ thống ] ### Kịch bản 2: Deploy với database migration

````bash
# 1. Tạo migration locally
bundle exec rails generate migration AddColumnToUsers

# 2. Commit và deploy code
git add . && git commit -m "Add migration"
./scripts/deploy.sh

# 3. Đợi deployment xong, chạy migration
./scripts/migrate.sh

# 4. Verify
./scripts/logs.sh
```úc-hệ-thống)
4. [Lần đầu tiên setup](#lần-đầu-tiên-setup)
5. [Quy trình deploy thường ngày](#quy-trình-deploy-thường-ngày)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Scripts tóm tắt

Tất cả scripts nằm trong thư mục `scripts/`:

| Script | Mô tả | Sử dụng |
|--------|-------|---------|
| `deploy.sh` | Build + Push + Deploy lên ECS | `./scripts/deploy.sh` |
| `get-url.sh` | Lấy URL hiện tại của app | `./scripts/get-url.sh` |
| `logs.sh` | Xem logs realtime | `./scripts/logs.sh` |
| `status.sh` | Xem trạng thái service | `./scripts/status.sh` |
| `start.sh` | Start service (scale to 1) | `./scripts/start.sh` |
| `stop.sh` | Stop service (scale to 0) | `./scripts/stop.sh` |
| `ssh.sh` | SSH vào container | `./scripts/ssh.sh` |
| `migrate.sh` | Chạy database migrations | `./scripts/migrate.sh` |

### ⚡ Quy trình nhanh nhất:

```bash
# 1. Deploy code mới
./scripts/deploy.sh

# 2. Đợi 30-60 giây, sau đó lấy URL
./scripts/get-url.sh

# 3. Xem logs
./scripts/logs.sh
````

**⏱️ Chỉ mất 3-5 phút!**

---

---

## 🛠️ Yêu cầu hệ thống

### Cài đặt cần thiết:

- ✅ Docker Desktop
- ✅ AWS CLI v2
- ✅ Terraform >= 1.0
- ✅ Git

### AWS Credentials:

```bash
# Profile: nhaituvung
# Region: ap-southeast-1 (Singapore)
# Account ID: 917914785208
```

### Kiểm tra cài đặt:

```bash
docker --version
aws --version
terraform --version
aws sts get-caller-identity --profile nhaituvung
```

---

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
                 ┌───────────────┐
                 │   Public IP   │ ← Thay đổi mỗi lần deploy
                 │ (Dynamic IP)  │
                 └───────┬───────┘
                         │
                         ▼
              ┌─────────────────────┐
              │    ECS Service      │
              │   (Fargate Task)    │
              │                     │
              │  - Rails App:3000   │
              │  - 512 CPU          │
              │  - 1024 Memory      │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │    RDS MySQL        │
              │   (db.t3.micro)     │
              │                     │
              │  - Storage: 20GB    │
              └─────────────────────┘
```

### Thông tin quan trọng:

- **Cluster:** nhaituvung-staging-cluster
- **Service:** nhaituvung-staging-service
- **ECR Repository:** 917914785208.dkr.ecr.ap-southeast-1.amazonaws.com/nhaituvung-staging-app
- **RDS Endpoint:** nhaituvung-staging-db.chyu886a87v6.ap-southeast-1.rds.amazonaws.com:3306
- **CloudWatch Logs:** /ecs/nhaituvung-staging-app

---

## 🎬 Lần đầu tiên setup

### Bước 1: Clone repository

```bash
cd ~/Desktop
git clone <repository-url> nhaituvung_api
cd nhaituvung_api
```

### Bước 2: Cấu hình AWS Profile

```bash
aws configure --profile nhaituvung
# AWS Access Key ID: <your-key>
# AWS Secret Access Key: <your-secret>
# Default region: ap-southeast-1
# Default output format: json
```

### Bước 3: Khởi tạo Terraform

```bash
cd terraform/environments/dev
terraform init
```

### Bước 4: Tạo infrastructure lần đầu

```bash
# Xem preview những gì sẽ tạo
terraform plan

# Tạo infrastructure
terraform apply
# Nhập 'yes' khi được hỏi
```

**⏱️ Thời gian:** ~10-15 phút

**Tài nguyên được tạo:**

- ✅ VPC + Subnets
- ✅ Security Groups
- ✅ ECS Cluster
- ✅ ECR Repository
- ✅ RDS MySQL Database
- ✅ IAM Roles
- ✅ CloudWatch Log Groups

### Bước 5: Build và push Docker image lần đầu

```bash
cd /Users/haotruong/Desktop/nhaituvung_api

# Chạy script deploy
./scripts/deploy.sh
```

**⏱️ Thời gian:** ~3-5 phút

### Bước 6: Lấy URL để access app

```bash
./scripts/get-url.sh
```

**Output mẫu:**

```
🔍 Finding ECS tasks...
✅ Task found: 1234567890abcdef

📡 Getting public IP...
✅ Public IP: 18.143.176.57

🌐 Application URL:
   http://18.143.176.57:3000

📊 Health check:
   http://18.143.176.57:3000/up

📝 View logs:
   aws logs tail /ecs/nhaituvung-staging-app --follow --profile nhaituvung --region ap-southeast-1
```

### Bước 7: Chạy database migrations (nếu cần)

```bash
# SSH vào container hoặc chạy task riêng
aws ecs execute-command \
  --cluster nhaituvung-staging-cluster \
  --task <task-id> \
  --container app \
  --interactive \
  --command "/bin/sh" \
  --profile nhaituvung \
  --region ap-southeast-1

# Trong container:
bundle exec rails db:migrate
bundle exec rails db:seed
```

---

## 🔄 Quy trình deploy thường ngày

### Kịch bản 1: Deploy code mới (THƯỜNG DÙNG NHẤT)

```bash
# 1. Commit code
git add .
git commit -m "Add new feature"
git push

# 2. Deploy lên AWS
./scripts/deploy.sh

# 3. Đợi 30-60 giây, sau đó lấy IP mới
./scripts/get-url.sh

# 4. Test thử
curl http://<new-ip>:3000/up

# 5. Xem logs nếu cần
./scripts/logs.sh
```

**⏱️ Thời gian:** ~3-5 phút

---

### Kịch bản 2: Deploy với database migration

```bash
# 1. Tạo migration
bundle exec rails generate migration AddColumnToUsers

# 2. Deploy code
./deploy-image.sh

# 3. Chạy migration trong container
# Xem phần "Chạy commands trong container" bên dưới
```

---

### Kịch bản 3: Chỉ thay đổi infrastructure (Terraform)

```bash
cd terraform/environments/dev

# 1. Sửa file .tf (ví dụ: tăng memory, thay đổi env vars)
vim main.tf

# 2. Preview thay đổi
terraform plan

# 3. Apply thay đổi
terraform apply

# 4. ECS sẽ tự động redeploy với config mới
```

---

### Kịch bản 4: Rollback về version cũ

```bash
# 1. Xem list các image tags trong ECR
aws ecr describe-images \
  --repository-name nhaituvung-staging-app \
  --profile nhaituvung \
  --region ap-southeast-1 \
  --query 'imageDetails[*].[imageTags[0],imagePushedAt]' \
  --output table

# 2. Update task definition với image cũ
# Sửa terraform/environments/dev/main.tf
# Thay đổi image tag trong container_definitions

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

## � Chi tiết các Scripts

Tất cả scripts đã được tổ chức trong thư mục `scripts/` với đầy đủ error handling và user-friendly messages.

### 1. **deploy.sh** - Deploy hoàn chỉnh

```bash
./scripts/deploy.sh
```

**Chức năng:**

1. ✅ Lấy thông tin từ Terraform outputs
2. 🔐 Login vào ECR
3. 🏗️ Build Docker image
4. ⬆️ Push lên ECR
5. ♻️ Force redeploy ECS service

**Output mẫu:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
� DEPLOY NHAITUVUNG API TO AWS ECS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Lấy thông tin từ Terraform...
   ✓ ECR Repository: xxx
   ✓ Cluster: nhaituvung-staging-cluster
   ✓ Service: nhaituvung-staging-service

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔐 Bước 1/4: Login vào ECR...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✓ Đăng nhập thành công!
...
✅ DEPLOY THÀNH CÔNG!

📝 Bước tiếp theo:
   1. Đợi ~30-60 giây để container start
   2. Chạy: ./scripts/get-url.sh
   3. Xem logs: ./scripts/logs.sh
```

---

### 2. **get-url.sh** - Lấy URL của app

```bash
./scripts/get-url.sh
```

**Chức năng:**

- Tìm ECS task đang chạy
- Lấy public IP
- Hiển thị URLs để access

**Output mẫu:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 LẤY URL ỨNG DỤNG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Đang tìm ECS task...
   ✓ Task ID: abc123

📡 Đang lấy Public IP...
   ✓ Public IP: 18.143.176.57

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 THÔNG TIN ỨNG DỤNG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 Application URL:
   http://18.143.176.57:3000

� Health Check:
   http://18.143.176.57:3000/up
```

---

### 3. **logs.sh** - Xem logs realtime

```bash
./scripts/logs.sh
```

**Chức năng:**

- Stream logs từ CloudWatch
- Format: short (dễ đọc)
- Press Ctrl+C để stop

---

### 4. **status.sh** - Xem trạng thái service

```bash
./scripts/status.sh
```

**Chức năng:**

- Hiển thị service status
- Số lượng tasks (desired/running/pending)
- Deployment status
- 5 events gần nhất

---

### 5. **stop.sh / start.sh** - Quản lý service

```bash
# Stop service (tiết kiệm chi phí)
./scripts/stop.sh

# Start service lại
./scripts/start.sh
```

---

### 6. **ssh.sh** - SSH vào container

```bash
./scripts/ssh.sh
```

**Chức năng:**

- Tự động tìm task đang chạy
- SSH vào container
- Chạy commands trong container

**Ví dụ sử dụng:**

```bash
./scripts/ssh.sh

# Trong container:
bundle exec rails console
bundle exec rails db:migrate
cat log/production.log
```

---

### 7. **migrate.sh** - Chạy database migrations

```bash
./scripts/migrate.sh
```

**Chức năng:**

- Tìm task đang chạy
- Chạy `bundle exec rails db:migrate`
- Hiển thị output

---

## 🐛 Troubleshooting

### Vấn đề 1: Container không start được

**Triệu chứng:**

```bash
./get-app-url.sh
❌ No running tasks found!
```

**Cách fix:**

```bash
# 1. Xem service status và events
./scripts/status.sh

# 2. Xem logs để tìm lỗi
./scripts/logs.sh

# 3. Common issues:
# - Image không tồn tại trong ECR → chạy ./scripts/deploy.sh
# - DB connection failed → check security groups
# - Không đủ memory → tăng memory trong Terraform
# - Container bị crash → xem logs để biết lý do

# 4. Nếu vẫn không fix được, redeploy
./scripts/deploy.sh
```

---

### Vấn đề 2: Image push failed

**Triệu chứng:**

```
denied: Your authorization token has expired
```

**Cách fix:**

```bash
# Login lại vào ECR
aws ecr get-login-password \
  --region ap-southeast-1 \
  --profile nhaituvung | \
  docker login --username AWS \
  --password-stdin 917914785208.dkr.ecr.ap-southeast-1.amazonaws.com
```

---

### Vấn đề 3: Database connection failed

**Triệu chứng:**

```
Can't connect to MySQL server
```

**Cách fix:**

```bash
# 1. Xem logs để confirm lỗi
./scripts/logs.sh

# 2. SSH vào container để test
./scripts/ssh.sh

# Trong container, test connection:
mysql -h nhaituvung-staging-db.chyu886a87v6.ap-southeast-1.rds.amazonaws.com -u admin -p

# 3. Nếu không connect được:
# - Check security group của RDS
# - Đảm bảo ECS security group có trong inbound rules của RDS
# - Check DATABASE_URL trong environment variables
```

---

### Vấn đề 4: Terraform state bị lock

**Triệu chứng:**

```
Error: Error acquiring the state lock
```

**Cách fix:**

```bash
cd terraform/environments/dev

# Force unlock (cẩn thận!)
terraform force-unlock <lock-id>
```

---

### Vấn đề 5: ECR repository không xóa được

**Triệu chứng:**

```
RepositoryNotEmptyException
```

**Cách fix:**
Đã được fix trong Terraform config:

```hcl
resource "aws_ecr_repository" "app" {
  # ...
  force_delete = true  # ← Thêm dòng này
}
```

---

## 📊 Monitoring & Logs

### Xem logs thường ngày

```bash
# Realtime logs (recommended)
./scripts/logs.sh

# Hoặc dùng AWS CLI trực tiếp:
aws logs tail /ecs/nhaituvung-staging-app \
  --follow \
  --profile nhaituvung \
  --region ap-southeast-1 \
  --format short
```

### Xem service status

```bash
./scripts/status.sh
```

---

## 💰 Chi phí ước tính

| Service         | Cấu hình          | Chi phí/tháng  |
| --------------- | ----------------- | -------------- |
| ECS Fargate     | 0.5 vCPU, 1GB RAM | ~$15           |
| RDS MySQL       | db.t3.micro, 20GB | ~$15           |
| ECR             | Storage           | ~$1            |
| CloudWatch Logs | Standard          | ~$3            |
| Data Transfer   | Minimal           | ~$1            |
| **TỔNG**        |                   | **~$35/tháng** |

**Lưu ý:** Đây là môi trường staging/dev. Production sẽ cao hơn.

---

## 🔒 Security Best Practices

### 1. Secrets Management

```bash
# Sử dụng AWS Secrets Manager hoặc SSM Parameter Store
aws secretsmanager create-secret \
  --name /nhaituvung/staging/database-password \
  --secret-string "your-password" \
  --profile nhaituvung \
  --region ap-southeast-1

# Update task definition để dùng secrets
```

### 2. Security Groups

- ✅ RDS chỉ cho phép traffic từ ECS security group
- ✅ ECS chỉ expose port 3000
- ✅ Không expose RDS ra internet

### 3. IAM Roles

- ✅ Task execution role: Pull image, write logs
- ✅ Task role: Access AWS services (S3, SES, etc.)

---

## 📚 Tài liệu tham khảo

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Rails Production Guide](https://guides.rubyonrails.org/configuring.html)

---

## 🆘 Support

Nếu gặp vấn đề:

1. Check logs trong CloudWatch
2. Xem ECS service events
3. Verify security groups
4. Check database connection
5. Review Terraform state

---

**Cập nhật lần cuối:** 29/10/2025
**Version:** 1.0.0
