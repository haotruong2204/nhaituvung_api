# 📦 Scripts cho nhaituvung_api

Tất cả scripts để quản lý deployment lên AWS ECS.

## 📋 Danh sách Scripts

| Script | Mô tả | Sử dụng |
|--------|-------|---------|
| `deploy.sh` | **Deploy hoàn chỉnh**: Build + Push + Deploy | `./scripts/deploy.sh` |
| `get-url.sh` | Lấy URL hiện tại của app | `./scripts/get-url.sh` |
| `logs.sh` | Xem logs realtime từ CloudWatch | `./scripts/logs.sh` |
| `status.sh` | Xem trạng thái service (tasks, deployments, events) | `./scripts/status.sh` |
| `start.sh` | Start service (scale to 1) | `./scripts/start.sh` |
| `stop.sh` | Stop service (scale to 0) - tiết kiệm chi phí | `./scripts/stop.sh` |
| `ssh.sh` | SSH vào container đang chạy | `./scripts/ssh.sh` |
| `migrate.sh` | Chạy database migrations | `./scripts/migrate.sh` |

---

## 🚀 Quy trình Deploy nhanh

### 1️⃣ Deploy code mới

```bash
# Commit code
git add .
git commit -m "Your message"

# Deploy
./scripts/deploy.sh

# Đợi 30-60 giây...

# Lấy URL
./scripts/get-url.sh

# Test
curl http://<ip>:3000/up
```

**⏱️ Thời gian:** 3-5 phút

---

### 2️⃣ Deploy với database migration

```bash
# Tạo migration
bundle exec rails generate migration YourMigration

# Deploy
./scripts/deploy.sh

# Chạy migration
./scripts/migrate.sh
```

---

### 3️⃣ Debug issues

```bash
# Xem logs
./scripts/logs.sh

# Xem status
./scripts/status.sh

# SSH vào container
./scripts/ssh.sh
```

---

### 4️⃣ Stop service tạm thời (tiết kiệm chi phí)

```bash
# Stop
./scripts/stop.sh

# Start lại khi cần
./scripts/start.sh
```

---

## 📝 Chi tiết từng script

### `deploy.sh`

**Chức năng:**
1. Lấy thông tin từ Terraform
2. Login vào ECR
3. Build Docker image
4. Push lên ECR
5. Force redeploy ECS service

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 DEPLOY NHAITUVUNG API TO AWS ECS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
...
✅ DEPLOY THÀNH CÔNG!
```

---

### `get-url.sh`

**Chức năng:**
- Tìm ECS task đang chạy
- Lấy public IP từ ENI
- Hiển thị URLs

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 THÔNG TIN ỨNG DỤNG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 Application URL:
   http://18.143.176.57:3000

💚 Health Check:
   http://18.143.176.57:3000/up
```

**Lưu ý:** IP sẽ thay đổi mỗi lần deploy!

---

### `logs.sh`

**Chức năng:**
- Stream logs từ CloudWatch
- Format: short
- Press Ctrl+C để stop

**Sử dụng:**
```bash
./scripts/logs.sh

# Hoặc với grep:
./scripts/logs.sh | grep ERROR
```

---

### `status.sh`

**Chức năng:**
- Service status (ACTIVE/DRAINING)
- Tasks (desired/running/pending)
- Deployments
- 5 events gần nhất

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 STATUS CỦA ECS SERVICE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Service Status: ACTIVE

Tasks:
  • Desired:  1
  • Running:  1
  • Pending:  0
```

---

### `stop.sh` / `start.sh`

**Chức năng:**
- Stop: Scale service to 0 (tiết kiệm chi phí ~$15/tháng)
- Start: Scale service to 1

**Khi nào dùng:**
- Stop: Cuối ngày, cuối tuần nếu không cần dev
- Start: Khi bắt đầu làm việc lại

**Lưu ý:** RDS vẫn chạy và tính phí!

---

### `ssh.sh`

**Chức năng:**
- SSH vào container đang chạy
- Chạy commands trong production environment

**Ví dụ:**
```bash
./scripts/ssh.sh

# Trong container:
bundle exec rails console
bundle exec rails db:migrate
cat log/production.log
ps aux
free -h
```

**Lưu ý:** Cần enable `execute-command` trong task definition!

---

### `migrate.sh`

**Chức năng:**
- Chạy `bundle exec rails db:migrate` trong container

**Khi nào dùng:**
- Sau khi deploy code có migration mới
- Rollback migration

---

## 🐛 Troubleshooting

### Script báo "No running tasks found"

**Nguyên nhân:**
- Service đang deploy
- Container bị crash
- Chưa deploy lần nào

**Cách fix:**
```bash
./scripts/status.sh    # Xem status
./scripts/logs.sh      # Xem lỗi
./scripts/deploy.sh    # Deploy lại
```

---

### Deploy failed

**Cách fix:**
```bash
# 1. Xem logs
./scripts/logs.sh

# 2. Xem status
./scripts/status.sh

# 3. Common issues:
# - Docker build failed → fix Dockerfile
# - ECR login failed → check AWS credentials
# - Image too large → optimize Dockerfile
```

---

### Container keeps crashing

**Cách fix:**
```bash
# 1. Xem logs
./scripts/logs.sh

# 2. Common issues:
# - DB connection failed → check security groups
# - Missing env vars → check task definition
# - OOM killed → increase memory in Terraform
# - Port conflict → check port bindings
```

---

## 💡 Tips

### 1. Tạo alias để gõ nhanh hơn

```bash
# Thêm vào ~/.zshrc hoặc ~/.bashrc
alias ndeploy='cd ~/Desktop/nhaituvung_api && ./scripts/deploy.sh'
alias nurl='cd ~/Desktop/nhaituvung_api && ./scripts/get-url.sh'
alias nlogs='cd ~/Desktop/nhaituvung_api && ./scripts/logs.sh'
alias nstatus='cd ~/Desktop/nhaituvung_api && ./scripts/status.sh'
alias nssh='cd ~/Desktop/nhaituvung_api && ./scripts/ssh.sh'

# Sau đó:
source ~/.zshrc

# Dùng:
ndeploy
nurl
nlogs
```

---

### 2. Save URL vào biến môi trường

```bash
# Lấy URL và save
export API_URL=$(./scripts/get-url.sh | grep "http://" | grep "Application URL" -A1 | tail -1 | xargs)

# Dùng
curl $API_URL/up
curl $API_URL/api/v1/users
```

---

### 3. Xem logs với timestamp

```bash
./scripts/logs.sh | while read line; do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line"
done
```

---

### 4. Monitor resource usage

```bash
# SSH vào container
./scripts/ssh.sh

# Trong container:
free -h        # Memory usage
df -h          # Disk usage
ps aux         # Process list
top            # Real-time monitoring
```

---

## 🔒 Security Notes

- ⚠️ Scripts chứa thông tin nhạy cảm (cluster name, service name)
- ⚠️ Không commit scripts nếu có credentials
- ✅ Sử dụng AWS Profile thay vì hardcode keys
- ✅ Luôn dùng HTTPS trong production

---

## 📚 Tham khảo

- [Deploy Guide](../docs/DEPLOY_GUIDE.md) - Hướng dẫn đầy đủ
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Cập nhật:** 29/10/2025  
**Version:** 1.0.0
