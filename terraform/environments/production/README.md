# 🚀 Production-Demo Environment

> **Full Production Stack with Stop/Start Capability**
> Perfect for learning AWS and product demos without production costs!

---

## 🎯 Quick Start

```bash
# 1. Deploy infrastructure
terraform init
terraform apply

# 2. Start/Stop scripts
cd ../../../scripts/production-demo

./start-all.sh   # Start everything
./stop-all.sh    # Stop ECS + RDS (save $45/month)
./status.sh      # Check status
```

---

## 💰 Cost Summary

| State       | Monthly Cost   | Services Running |
| ----------- | -------------- | ---------------- |
| **Running** | **$95/month**  | ALL              |
| **Stopped** | **$50/month**  | ALB + Redis only |
| **Savings** | **-$45 (47%)** | When stopped     |

---

## 🏗️ Architecture

```
Internet → ALB → ECS Fargate (Auto Scaling) → RDS + Redis
         $16    $35 (can stop!)              $26   $26
```

**Features:**

- ✅ Application Load Balancer
- ✅ ECS Auto Scaling (1-4 tasks)
- ✅ Multi-AZ High Availability
- ✅ Production-grade monitoring
- ✅ Can stop ECS & RDS to save cost!

---

## 📖 Full Documentation

See [PRODUCTION_DEMO_GUIDE.md](../../../docs/PRODUCTION_DEMO_GUIDE.md) for:

- Detailed architecture
- Complete cost breakdown
- Start/stop procedures
- Monitoring & troubleshooting
- Best practices

---

## 🔧 Configuration

### Key Variables

```hcl
# In variables.tf or terraform.tfvars
# ECS Scaling
ecs_desired_count = 2    # Set to 0 to stop
ecs_min_count = 1
ecs_max_count = 4
# RDS
db_multi_az = false      # Must be false to allow stop/start
db_instance_class = "db.t3.small"
# Redis
redis_node_type = "cache.t3.small"
# Auto Scaling
enable_auto_scaling = true
```

### Required Secrets

```bash
# Create terraform.tfvars
cat > terraform.tfvars <<EOF
db_password = "your-strong-password-here"
secret_key_base = "$(openssl rand -hex 64)"
EOF
```

---

## 🎮 Common Operations

### Deploy Application

```bash
# Get ECR URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Build & push
docker build -t app .
docker tag app:latest $ECR_URL:latest
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:latest

# Force deployment
aws ecs update-service --force-new-deployment \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name)
```

### Stop for Night/Weekend

```bash
cd ../../../scripts/production-demo
./stop-all.sh

# Costs drop from $95 → $50/month
```

### Start in Morning

```bash
cd ../../../scripts/production-demo
./start-all.sh

# Ready in ~7 minutes
```

### Check Status

```bash
cd ../../../scripts/production-demo
./status.sh

# Shows:
# - ECS: Running/Stopped + task counts
# - RDS: Available/Stopped
# - Redis: Always available
# - Current cost estimate
```

---

## 📊 What You Get

### Production Features ✅

- **Load Balancing** - ALB with health checks
- **Auto Scaling** - CPU, Memory, Request-based
- **High Availability** - Multi-AZ, multiple tasks
- **Security** - VPC, Private subnets, Security groups
- **Monitoring** - CloudWatch Logs & Metrics
- **Container Registry** - ECR with lifecycle policies

### Cost Optimizations 💰

- **Stop/Start** - ECS & RDS can be stopped
- **No NAT Gateway** - Saves $32/month
- **Single-AZ RDS** - Allows stop/start
- **No Backups** - Learning/demo environment
- **Minimal Logging** - 7 days retention

---

## ⚠️ Important Notes

### Can Stop ✅

- **ECS Fargate** - Scale to 0, instant savings
- **RDS MySQL** - Stop for up to 7 days
- **Cost Savings** - $45/month when stopped

### Cannot Stop ❌

- **ALB** - Always running ($16/month)
- **Redis** - In-memory, cannot stop ($26/month)
- **Auto-starts** - RDS restarts after 7 days

### Limitations

- ⚠️ Not for real production (no backups, no Multi-AZ RDS)
- ⚠️ RDS stops for max 7 days (auto-restarts)
- ⚠️ Redis always on (can only delete)
- ⚠️ ALB always charging

---

## 🎓 Learning Path

### Week 1: Basics

1. Deploy infrastructure
2. Understand each component
3. Practice start/stop
4. Monitor costs

### Week 2: Operations

1. Deploy application
2. Scale tasks manually
3. View logs
4. Check health

### Week 3: Advanced

1. Trigger auto-scaling
2. Simulate failures
3. Monitor recovery
4. Optimize costs

### Week 4: Production

1. Add HTTPS (ACM)
2. Add domain (Route 53)
3. Add CDN (CloudFront)
4. Setup CI/CD

---

## 🔗 Related Files

- **Main Config**: `main.tf`
- **Variables**: `variables.tf`
- **Outputs**: `outputs.tf`
- **Scripts**: `../../../scripts/production-demo/`
- **Full Guide**: `../../../docs/PRODUCTION_DEMO_GUIDE.md`

---

## 🆘 Quick Help

```bash
# Infrastructure status
terraform output

# Application URL
terraform output alb_url

# View logs
aws logs tail /ecs/nhaituvung-prod-demo-app --follow

# Service status
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name)

# RDS status
aws rds describe-db-instances \
  --db-instance-identifier nhaituvung-prod-demo-db
```

---

**Created:** November 6, 2025
**Purpose:** Learning AWS + Product Demos
**Cost:** $95/month (running) | $50/month (stopped)
**Savings:** 47% when stopped
