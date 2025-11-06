# 🚀 Production-Demo Environment Guide

> **Full-featured Production Architecture with Start/Stop Capability**
>
> Perfect for: Learning AWS, Product Demos, Cost-Conscious Development

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Cost Analysis](#cost-analysis)
- [Quick Start](#quick-start)
- [Start/Stop Guide](#startstop-guide)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

The **Production-Demo** environment provides a full production-grade AWS infrastructure that can be stopped when not in use to save costs. This is ideal for:

✅ Learning AWS services hands-on
✅ Demonstrating products to clients
✅ Development/testing with production-like setup
✅ Cost control while maintaining production features

### Key Benefits

| Benefit               | Description                                       |
| --------------------- | ------------------------------------------------- |
| **Production-Grade**  | Full ALB, Auto Scaling, Multi-AZ, CloudWatch      |
| **Cost Control**      | Stop ECS/RDS when not in use (~42% savings)       |
| **Easy Management**   | Simple scripts to start/stop everything           |
| **Learning Friendly** | Real production patterns without production costs |

---

## 🏗️ Architecture

```
                    Internet
                       ↓
            ┌──────────────────┐
            │  Route 53 (opt)  │
            └────────┬─────────┘
                     ↓
            ┌──────────────────┐
            │ Application Load │  ← $16/month (always on)
            │    Balancer      │
            └────────┬─────────┘
                     ↓
    ┌────────────────┴────────────────┐
    │         ECS Fargate             │
    │    ┌─────────┬─────────┐       │  ← $35/month (can stop!)
    │    │ Task 1  │ Task 2  │       │
    │    │ AZ-1a   │ AZ-1b   │       │
    │    └─────────┴─────────┘       │
    │    Auto Scaling: 1-4 tasks     │
    └────────────────┬────────────────┘
                     ↓
         ┌───────────┴────────────┐
         ↓                        ↓
   ┌──────────┐            ┌──────────┐
   │   RDS    │            │  Redis   │
   │  MySQL   │            │ Cluster  │
   │ (Private)│            │(Private) │
   └──────────┘            └──────────┘
   $26/month                $26/month
   (can stop!)              (always on)
```

### Components

#### 1. **VPC & Networking**

- Multi-AZ: 2 Availability Zones (ap-southeast-1a, 1b)
- Public Subnets: 2 (for ALB)
- Private Subnets: 2 (for ECS, RDS, Redis)
- Internet Gateway: Yes
- NAT Gateway: **NO** (cost optimization - ECS uses public IPs)

#### 2. **Application Load Balancer (ALB)**

- Type: Application Load Balancer
- Scheme: Internet-facing
- Listeners: HTTP:80 (HTTPS optional)
- Health Checks: `/up` endpoint
- Cross-zone: Enabled
- **Cost: ~$16/month (cannot stop)**

#### 3. **ECS Fargate**

- Cluster: Production-grade
- Launch Type: Fargate (serverless)
- CPU: 512 vCPU (0.5 vCPU)
- Memory: 1024 MB (1 GB)
- Tasks: 2 (default), Min: 1, Max: 4
- Auto Scaling: CPU, Memory, ALB Request Count
- **Cost: ~$35/month (CAN STOP!)**

#### 4. **RDS MySQL**

- Instance: db.t3.small
- Storage: 50 GB gp3 SSD
- Multi-AZ: **NO** (to allow stop/start)
- Backups: Disabled
- Encryption: Enabled
- **Cost: ~$26/month (CAN STOP!)**

#### 5. **ElastiCache Redis**

- Node Type: cache.t3.small
- Nodes: 1
- Engine: Redis 7.0
- Snapshots: Disabled
- **Cost: ~$26/month (cannot stop)**

#### 6. **CloudWatch Logs**

- Retention: 7 days
- Log Group: `/ecs/nhaituvung-prod-demo-app`
- **Cost: ~$0.50/month**

---

## ✨ Features

### Production Features

✅ **Load Balancing**

- Application Load Balancer with health checks
- Multi-AZ distribution
- Automatic failover

✅ **Auto Scaling**

- CPU-based scaling (target: 70%)
- Memory-based scaling (target: 80%)
- Request count-based scaling (target: 1000 req/target)
- Scale out: 60s cooldown
- Scale in: 300s cooldown

✅ **High Availability**

- Multi-AZ subnets
- Multiple ECS tasks
- Automatic task recovery

✅ **Security**

- VPC with private subnets
- Security groups (least privilege)
- Encrypted RDS storage
- Private database endpoints

✅ **Monitoring**

- CloudWatch Logs
- ECS metrics
- RDS metrics
- ALB metrics

### Cost Control Features

💰 **Stop/Start Capability**

- ECS tasks can scale to 0
- RDS can be stopped (7 days max)
- Simple automation scripts
- 42% cost savings when stopped

💰 **Optimizations**

- No NAT Gateway (-$32/month)
- Single-AZ RDS (allow stop/start)
- No automated backups
- Minimal container insights
- Short log retention

---

## 💰 Cost Analysis

### Full Cost Breakdown (Running 24/7)

| Service                       | Configuration      | Monthly Cost   | Can Stop?  |
| ----------------------------- | ------------------ | -------------- | ---------- |
| **ECS Fargate**               | 2 tasks × 512/1024 | $35.00         | ✅ Yes     |
| **RDS MySQL**                 | db.t3.small, 50GB  | $26.00         | ✅ Yes     |
| **ElastiCache Redis**         | cache.t3.small     | $26.00         | ❌ No      |
| **Application Load Balancer** | Standard ALB       | $16.00         | ❌ No      |
| **CloudWatch Logs**           | 7 days, ~2GB/month | $0.50          | ⚠️ Partial |
| **ECR Storage**               | ~3GB images        | $0.30          | ❌ No      |
| **Data Transfer**             | ~3GB/month out     | $0.20          | ⚠️ Usage   |
| **VPC/Networking**            | IGW, Subnets, SG   | $0.00          | Free       |
|                               |                    |                |            |
| **TOTAL RUNNING**             |                    | **~$95/month** |            |

### Cost When Stopped

| Service               | Status            | Monthly Cost   | Savings  |
| --------------------- | ----------------- | -------------- | -------- |
| **ECS Fargate**       | Stopped (count=0) | $0.00          | -$35.00  |
| **RDS MySQL**         | Stopped           | $7.00\*        | -$19.00  |
| **ElastiCache Redis** | Running           | $26.00         | $0.00    |
| **ALB**               | Running           | $16.00         | $0.00    |
| **Others**            | Minimal           | $1.00          | -$1.00   |
|                       |                   |                |          |
| **TOTAL STOPPED**     |                   | **~$50/month** | **-$45** |

**Savings: 47% ($45/month)**

\*RDS stopped = only storage costs ($7 for 50GB)

### Cost Comparison

```
┌─────────────────────────────────┐
│  RUNNING (24/7)                 │
│  ECS:      $35  ████████████    │
│  RDS:      $26  █████████       │
│  Redis:    $26  █████████       │
│  ALB:      $16  █████           │
│  Others:   $2   █               │
│  ─────────────────────────────  │
│  TOTAL:    $95/month            │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│  STOPPED (when not using)       │
│  ECS:      $0   (stopped)       │
│  RDS:      $7   ███             │
│  Redis:    $26  █████████       │
│  ALB:      $16  █████           │
│  Others:   $1   █               │
│  ─────────────────────────────  │
│  TOTAL:    $50/month            │
│  SAVINGS:  $45/month (47%)      │
└─────────────────────────────────┘
```

### Usage Patterns & Costs

| Usage Pattern      | Running Time     | Monthly Cost |
| ------------------ | ---------------- | ------------ |
| **Always On**      | 100% (730h)      | $95          |
| **Business Hours** | 40% (8h×22d)     | $68          |
| **Weekdays Only**  | 30% (5d/week)    | $60          |
| **Weekends Only**  | 10% (2d/week)    | $52          |
| **Demo Only**      | ~5% (occasional) | $50          |

---

## 🚀 Quick Start

### Prerequisites

```bash
# Required tools
terraform >= 1.0
aws-cli >= 2.0
docker >= 20.10
jq (for scripts)

# AWS credentials configured
aws configure --profile nhaituvung
```

### Step 1: Deploy Infrastructure

```bash
cd terraform/environments/production-demo

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy (takes ~15-20 minutes)
terraform apply

# Save outputs
terraform output > outputs.txt
```

### Step 2: Build & Push Docker Image

```bash
# Build image
docker build -t nhaituvung-api .

# Tag for ECR
ECR_URL=$(terraform output -raw ecr_repository_url)
docker tag nhaituvung-api:latest $ECR_URL:latest

# Login to ECR
aws ecr get-login-password --profile nhaituvung | \
  docker login --username AWS --password-stdin $ECR_URL

# Push
docker push $ECR_URL:latest
```

### Step 3: Force ECS Deployment

```bash
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)

aws ecs update-service \
  --cluster $CLUSTER \
  --service $SERVICE \
  --force-new-deployment \
  --profile nhaituvung
```

### Step 4: Access Application

```bash
# Get ALB URL
terraform output alb_url

# Wait 2-3 minutes, then test
curl $(terraform output -raw alb_url)/up
```

---

## 🎮 Start/Stop Guide

### Using Automation Scripts

#### **Stop Everything** (Save $45/month)

```bash
cd scripts/production-demo
./stop-all.sh
```

What happens:

1. ECS tasks scale to 0 (~30 seconds)
2. RDS stops (~5 minutes)
3. ALB & Redis keep running

**Result: $50/month cost**

#### **Start Everything**

```bash
cd scripts/production-demo
./start-all.sh
```

What happens:

1. RDS starts (~5 minutes)
2. ECS tasks scale back to desired count
3. Wait for health checks (~2 minutes)

**Result: App is available in ~7 minutes**

#### **Check Status**

```bash
cd scripts/production-demo
./status.sh
```

Output shows:

- ECS: Running/Stopped + task counts
- RDS: Available/Stopped/Starting
- Redis: Always available
- ALB: Always running
- Current estimated cost

### Manual Commands

#### Stop ECS Only

```bash
aws ecs update-service \
  --cluster nhaituvung-prod-demo-cluster \
  --service nhaituvung-prod-demo-service \
  --desired-count 0 \
  --profile nhaituvung
```

#### Stop RDS Only

```bash
aws rds stop-db-instance \
  --db-instance-identifier nhaituvung-prod-demo-db \
  --profile nhaituvung
```

#### Start ECS

```bash
aws ecs update-service \
  --cluster nhaituvung-prod-demo-cluster \
  --service nhaituvung-prod-demo-service \
  --desired-count 2 \
  --profile nhaituvung
```

#### Start RDS

```bash
aws rds start-db-instance \
  --db-instance-identifier nhaituvung-prod-demo-db \
  --profile nhaituvung

# Wait for available
aws rds wait db-instance-available \
  --db-instance-identifier nhaituvung-prod-demo-db \
  --profile nhaituvung
```

---

## 📊 Monitoring

### CloudWatch Logs

```bash
# View logs
aws logs tail /ecs/nhaituvung-prod-demo-app \
  --follow \
  --profile nhaituvung

# Filter errors
aws logs tail /ecs/nhaituvung-prod-demo-app \
  --follow \
  --filter-pattern "ERROR" \
  --profile nhaituvung
```

### ECS Service Health

```bash
# Service status
aws ecs describe-services \
  --cluster nhaituvung-prod-demo-cluster \
  --services nhaituvung-prod-demo-service \
  --profile nhaituvung

# Task list
aws ecs list-tasks \
  --cluster nhaituvung-prod-demo-cluster \
  --service nhaituvung-prod-demo-service \
  --profile nhaituvung
```

### RDS Metrics

```bash
# Database status
aws rds describe-db-instances \
  --db-instance-identifier nhaituvung-prod-demo-db \
  --profile nhaituvung
```

### ALB Health

```bash
# Target health
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN> \
  --profile nhaituvung
```

---

## 🔧 Troubleshooting

### ECS Tasks Not Starting

**Symptoms:**

- Tasks go to PENDING then STOPPED
- No running tasks after start command

**Solutions:**

1. Check task logs:

```bash
aws ecs describe-tasks \
  --cluster nhaituvung-prod-demo-cluster \
  --tasks <TASK_ARN> \
  --profile nhaituvung
```

2. Common issues:
   - ❌ ECR image not found → Push image again
   - ❌ RDS not available → Wait for RDS to start
   - ❌ Memory/CPU limit → Check CloudWatch logs
   - ❌ Health check failing → Check `/up` endpoint

### ALB Returns 503

**Symptoms:**

- ALB is accessible but returns 503 Service Unavailable

**Solutions:**

1. Check target health:

```bash
# Get target group ARN from outputs
terraform output

# Check health
aws elbv2 describe-target-health \
  --target-group-arn <ARN> \
  --profile nhaituvung
```

2. Common causes:
   - ❌ No healthy targets → ECS tasks not running
   - ❌ Health check failing → App not responding on `/up`
   - ❌ Security group → Check ECS SG allows ALB traffic

### RDS Won't Stop

**Symptoms:**

- Stop command fails or RDS auto-restarts

**Solutions:**

1. Check Multi-AZ setting:

```bash
aws rds describe-db-instances \
  --db-instance-identifier nhaituvung-prod-demo-db \
  --query 'DBInstances[0].MultiAZ' \
  --profile nhaituvung
```

If `true`, you cannot stop RDS. Must be `false`.

2. Check for read replicas:

```bash
aws rds describe-db-instances \
  --db-instance-identifier nhaituvung-prod-demo-db \
  --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers' \
  --profile nhaituvung
```

Cannot stop if has read replicas.

### Cost Higher Than Expected

**Check:**

1. RDS is stopped:

```bash
./scripts/production-demo/status.sh
```

2. ECS tasks are at 0:

```bash
aws ecs describe-services \
  --cluster nhaituvung-prod-demo-cluster \
  --services nhaituvung-prod-demo-service \
  --query 'services[0].runningCount' \
  --profile nhaituvung
```

3. No unexpected resources:

```bash
# Check for NAT Gateways ($32/month each!)
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=available" \
  --profile nhaituvung

# Should be empty for this setup
```

---

## 📝 Best Practices

### For Learning AWS

1. ✅ Start small - understand each component
2. ✅ Use stop/start scripts - save money
3. ✅ Review CloudWatch logs - understand behavior
4. ✅ Experiment with scaling - see auto-scaling in action
5. ✅ Document learnings - build your knowledge base

### For Demos

1. ✅ Start 10 minutes before demo
2. ✅ Verify health with `status.sh`
3. ✅ Have backup slides (in case of issues)
4. ✅ Stop immediately after demo
5. ✅ Monitor costs weekly

### For Development

1. ✅ Stop every night (42% savings)
2. ✅ Use staging environment for daily work
3. ✅ Production-demo for final testing only
4. ✅ Enable auto-scaling for load testing
5. ✅ Regular terraform plan to catch drift

---

## 🎓 Learning Resources

### AWS Services Used

- [ECS Fargate Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [RDS MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/)
- [ElastiCache Redis](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/)
- [VPC Networking](https://docs.aws.amazon.com/vpc/latest/userguide/)

### Terraform

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Module Examples](https://github.com/terraform-aws-modules/terraform-aws-ecs)

---

## 🆘 Support

### Quick Links

- Documentation: `/docs/`
- Scripts: `/scripts/production-demo/`
- Terraform: `/terraform/environments/production-demo/`

### Common Commands

```bash
# Status
./scripts/production-demo/status.sh

# Logs
aws logs tail /ecs/nhaituvung-prod-demo-app --follow

# Terraform outputs
cd terraform/environments/production-demo && terraform output

# Force redeploy
aws ecs update-service --force-new-deployment \
  --cluster <cluster> --service <service>
```

---

**Last Updated:** November 6, 2025
**Version:** 1.0.0
**Environment:** production-demo
