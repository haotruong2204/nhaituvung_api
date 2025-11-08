# Scripts Production - Hướng Dẫn Sử Dụng

## 🚀 Scripts Production

### **Trong thư mục `scripts/production/`:**

#### 1. **start-all.sh** - Khởi động tất cả services

```bash
cd scripts/production
./start-all.sh
```

**Chức năng:**

- Start RDS instance
- Wait for RDS available (~5-7 phút)
- Start ECS tasks (set desired count)
- Show application URL

#### 2. **stop-all.sh** - Dừng tất cả services (tiết kiệm chi phí)

```bash
cd scripts/production
./stop-all.sh
```

**Chức năng:**

- Stop ECS tasks (set desired count = 0)
- Stop RDS instance
- Tiết kiệm ~$61/tháng

**Lưu ý:** ALB và Redis vẫn chạy (~$49/tháng)

#### 3. **status.sh** - Kiểm tra trạng thái

```bash
cd scripts/production
./status.sh
```

**Hiển thị:**

- ECS Service status (running/desired/pending)
- RDS status (available/stopped/starting)
- Redis status
- ALB URL
- Cost estimate

---

## 🛠️ Scripts Root (thư mục `scripts/`)

### **deploy.sh** - Deploy toàn bộ application

```bash
./scripts/deploy.sh
```

**Pipeline:**

1. Login to ECR
2. Build Docker image
3. Tag and push to ECR
4. Force redeploy ECS service

**Config:**

- Terraform: `terraform/environments/production`
- AWS Profile: Default (không cần --profile)

### **get-app-url.sh** - Lấy URL application

```bash
./scripts/get-app-url.sh
```

**Note:** Script này cho dev environment (ECS với public IP, không có ALB)

Để lấy production URL với ALB:

```bash
cd terraform/environments/production
terraform output -raw alb_url
```

### **deploy-image.sh** - Deploy chỉ Docker image

```bash
./scripts/deploy-image.sh
```

Build và push image mới mà không thay đổi infrastructure.

---

## ⚙️ Cấu Hình AWS Profile

Tất cả scripts sử dụng **default AWS profile**.

### **Setup credentials:**

```bash
aws configure

# Nhập:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: ap-southeast-1
# - Output format: json
```

### **Verify:**

```bash
aws sts get-caller-identity

# Expected output:
# {
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-user"
# }
```

---

## 📊 Workflow Hoàn Chỉnh

### **1. Deploy Infrastructure (lần đầu):**

```bash
cd terraform/environments/production

# Create terraform.tfvars
cat > terraform.tfvars << EOF
aws_profile = "default"
aws_region = "ap-southeast-1"
db_password = "YourSecurePassword"
secret_key_base = "your-secret-key"
EOF

# Deploy
terraform init
terraform apply
```

### **2. Deploy Application:**

```bash
cd /path/to/nhaituvung_api
./scripts/deploy.sh
```

### **3. Get Application URL:**

```bash
cd terraform/environments/production
terraform output -raw alb_url

# Test
curl http://<ALB_URL>/up
```

### **4. Check Status:**

```bash
cd scripts/production
./status.sh
```

### **5. Stop Services (tiết kiệm chi phí):**

```bash
cd scripts/production
./stop-all.sh
```

### **6. Start Services lại:**

```bash
cd scripts/production
./start-all.sh
```

---

## 🔍 Troubleshooting

### **Lỗi: "Unable to locate credentials"**

```bash
# Setup AWS credentials
aws configure

# Verify
aws sts get-caller-identity
```

### **Lỗi: "Terraform directory not found"**

Đảm bảo bạn đã có terraform infrastructure:

```bash
ls terraform/environments/production/
# Phải có: main.tf, variables.tf, outputs.tf
```

### **Lỗi: "Could not get cluster/service names"**

Infrastructure chưa được deploy:

```bash
cd terraform/environments/production
terraform apply
```

---

## 💰 Quản Lý Chi Phí

### **Full Running:**

- ECS Fargate: ~$35/month
- RDS MySQL: ~$26/month
- Redis: ~$26/month
- ALB: ~$16/month
- **Total: ~$95/month**

### **Stopped (ECS=0, RDS stopped):**

- ALB: ~$16/month
- Redis: ~$26/month
- RDS Storage: ~$7/month
- **Total: ~$49/month**
- **Savings: ~$46/month (47%)**

### **Destroyed:**

```bash
cd terraform/environments/production
terraform destroy
```

- **Cost: $0/month**

---

## 📝 Thay Đổi So Với Trước

### **Đã sửa:**

✅ **AWS Profile:**

- ❌ Trước: `--profile nhaituvung` (hardcoded)
- ✅ Sau: Default profile (no flag)

✅ **Terraform Path:**

- ❌ Trước: `terraform/environments/production-demo`
- ✅ Sau: `terraform/environments/production`

✅ **Environment:**

- ❌ Trước: "Production-Demo"
- ✅ Sau: "Production"

### **Files đã sửa:**

```
scripts/production/
  ✓ start-all.sh
  ✓ status.sh
  ✓ stop-all.sh
scripts/
  ✓ deploy.sh
  ✓ deploy-image.sh
  ✓ get-app-url.sh
  ✓ get-url.sh
  ✓ logs.sh
  ✓ migrate.sh
  ✓ ssh.sh
  ✓ start.sh
  ✓ status.sh
  ✓ stop.sh
```

**Total: 13 files modified**

---

## 🎯 Quick Reference

```bash
# Deploy full stack
./scripts/deploy.sh

# Check status
cd scripts/production && ./status.sh

# Stop to save cost
cd scripts/production && ./stop-all.sh

# Start again
cd scripts/production && ./start-all.sh

# Get URL
cd terraform/environments/production
terraform output -raw alb_url

# Destroy everything
terraform destroy
```

---

## ✅ Checklist

- [ ] AWS credentials configured (`aws configure`)
- [ ] Terraform infrastructure deployed (`terraform apply`)
- [ ] Application deployed (`./scripts/deploy.sh`)
- [ ] ALB URL accessible
- [ ] Scripts tested and working

---

**All scripts now use default AWS profile!** 🚀
