# 💰 AWS Cost Estimate - nhaituvung_api (Staging Environment)

**Region:** ap-southeast-1 (Singapore)
**Environment:** Development/Staging
**Last Updated:** November 6, 2025
**Based on:** Terraform configuration in `terraform/environments/dev/`

---

## 📊 Infrastructure Overview

### Compute & Storage Resources

| Resource              | Configuration          | Quantity   | Running Time |
| --------------------- | ---------------------- | ---------- | ------------ |
| **ECS Fargate**       | 256 vCPU / 512 MB      | 1 task     | 24/7         |
| **RDS MySQL**         | db.t3.micro / 30GB gp3 | 1 instance | 24/7         |
| **ElastiCache Redis** | cache.t3.micro         | 1 node     | 24/7         |
| **ECR Repository**    | Docker images          | 1 repo     | Always       |
| **CloudWatch Logs**   | 3 days retention       | -          | Always       |

### Network Resources (FREE)

- ✅ VPC (1x)
- ✅ Subnets (3x - 1 public, 2 private)
- ✅ Internet Gateway (1x)
- ✅ Security Groups (3x - ECS, RDS, Redis)
- ✅ Route Tables
- ❌ **NO NAT Gateway** (ECS uses public subnet for internet access)
- ❌ **NO Load Balancer** (Direct IP access for dev/staging)

---

## 💵 Detailed Cost Breakdown

### 1. **Amazon ECS Fargate**

**Configuration:**

- vCPU: 0.25 vCPU (256 units)
- Memory: 0.5 GB (512 MB)
- Tasks: 1
- Running: 730 hours/month (24/7)

**Pricing (Singapore region):**

- vCPU: $0.04656 per vCPU-hour
- Memory: $0.00511 per GB-hour

**Calculation:**

```
vCPU cost:   0.25 vCPU × $0.04656 × 730 hours = $8.50/month
Memory cost: 0.5 GB × $0.00511 × 730 hours    = $1.87/month
---------------------------------------------------------------
Total ECS:                                      $10.37/month
```

---

### 2. **Amazon RDS for MySQL**

**Configuration:**

- Instance: db.t3.micro (2 vCPU, 1 GB RAM)
- Storage: 30 GB gp3 SSD
- Deployment: Single-AZ (no Multi-AZ)
- Backups: 0 days retention (no automated backups)
- Running: 730 hours/month

**Pricing:**

- Instance: $0.018 per hour (db.t3.micro Singapore)
- Storage: $0.138 per GB-month (gp3)

**Calculation:**

```
Instance cost: $0.018 × 730 hours = $13.14/month
Storage cost:  30 GB × $0.138     = $4.14/month
Backup cost:   0 GB               = $0.00/month
---------------------------------------------------------------
Total RDS:                          $17.28/month
```

---

### 3. **Amazon ElastiCache for Redis**

**Configuration:**

- Node type: cache.t3.micro (2 vCPU, 0.5 GB RAM)
- Nodes: 1 (single node, no replication)
- Engine: Redis 7.0
- Deployment: Single-AZ
- Snapshots: 0 (no retention)

**Pricing:**

- Node: $0.018 per hour (cache.t3.micro Singapore)

**Calculation:**

```
Node cost: $0.018 × 730 hours = $13.14/month
Backup cost: 0 snapshots      = $0.00/month
---------------------------------------------------------------
Total Redis:                    $13.14/month
```

---

### 4. **Amazon ECR (Elastic Container Registry)**

**Configuration:**

- Storage: ~2 GB (keeping last 3 images via lifecycle policy)
- Data transfer: Minimal (pulls from same region)

**Pricing:**

- Storage: $0.10 per GB-month

**Calculation:**

```
Storage cost: 2 GB × $0.10 = $0.20/month
Data transfer: ~negligible  = $0.00/month (within region)
---------------------------------------------------------------
Total ECR:                   $0.20/month
```

---

### 5. **Amazon CloudWatch Logs**

**Configuration:**

- Log group: `/ecs/nhaituvung-staging-app`
- Retention: 3 days
- Estimated ingestion: ~500 MB/month (Rails app logs)

**Pricing:**

- Ingestion: First 5 GB free, then $0.76 per GB
- Storage: $0.033 per GB-month (after free tier)

**Calculation:**

```
Ingestion: 0.5 GB (within free tier) = $0.00/month
Storage: 0.5 GB × $0.033            = $0.02/month
---------------------------------------------------------------
Total CloudWatch:                     $0.02/month
```

---

### 6. **Data Transfer OUT (Internet)**

**Estimated:**

- API responses: ~1-2 GB/month (dev/staging with light traffic)

**Pricing:**

- First 1 GB/month: FREE
- Next 9.999 TB: $0.12 per GB

**Calculation:**

```
First 1 GB: Free              = $0.00/month
Additional: 1 GB × $0.12      = $0.12/month
---------------------------------------------------------------
Total Data Transfer:            $0.12/month
```

---

## 📈 **TOTAL MONTHLY COST**

| Service                  | Monthly Cost     | Percentage |
| ------------------------ | ---------------- | ---------- | --- |
| **RDS MySQL**            | $17.28           | 40%        |
| **ElastiCache Redis**    | $13.14           | 30%        |
| **ECS Fargate**          | $10.37           | 24%        |
| **CloudWatch Logs**      | $0.02            | <1%        |
| **ECR Storage**          | $0.20            | <1%        |
| **Data Transfer**        | $0.12            | <1%        |
| **Network (VPC/SG/IGW)** | $0.00            | FREE       |
|                          |                  |            |     |
| **TOTAL**                | **$41.13/month** | 100%       |

### **Cost Range (with usage variation):**

- **Minimum:** ~$38/month (lighter usage)
- **Expected:** ~$41/month (normal dev/staging)
- **Maximum:** ~$45/month (heavier usage, more logs)

---

## 💡 Cost Optimization Tips

### ✅ **Already Optimized (Current Setup):**

1. ✅ **Smallest instance sizes** (t3.micro everywhere)
2. ✅ **Single-AZ deployment** (no Multi-AZ redundancy)
3. ✅ **No backups** for RDS (backup_retention_period = 0)
4. ✅ **No Redis snapshots** (snapshot_retention_limit = 0)
5. ✅ **Minimal ECS resources** (256 vCPU / 512 MB)
6. ✅ **Short log retention** (3 days only)
7. ✅ **ECR lifecycle policy** (keep last 3 images only)
8. ✅ **No NAT Gateway** (saves ~$32/month!)
9. ✅ **No Load Balancer** (saves ~$16/month!)
10. ✅ **Public subnet for ECS** (direct internet access)

### 🎯 **Further Cost Reduction Options:**

#### Option 1: **Stop resources during non-working hours**

```bash
# Stop ECS tasks at night (if not needed 24/7)
aws ecs update-service --desired-count 0  # Stop
aws ecs update-service --desired-count 1  # Start

# Savings: ~$7/month (if stopped 12 hours/day)
```

#### Option 2: **RDS Stop/Start manually**

```bash
# Stop RDS when not using (max 7 days)
aws rds stop-db-instance --db-instance-identifier nhaituvung-staging-db

# Savings: ~$8.50/month (if stopped 50% of time)
```

#### Option 3: **Use Amazon Lightsail instead**

- Lightsail Container + Database: $15-20/month
- Trade-off: Less flexibility, but much cheaper
- Good for: Early development phase

#### Option 4: **Share resources with other environments**

- Use same RDS/Redis for multiple environments
- Separate by database names
- Savings: ~$15/month (if sharing with 1 other env)

---

## 📊 Cost Comparison

### **Before Redis Migration:**

| Service     | Cost             |
| ----------- | ---------------- |
| ECS Fargate | $10.37           |
| RDS MySQL   | $17.28           |
| Others      | $0.34            |
| **Total**   | **$27.99/month** |

### **After Redis Migration (Current):**

| Service               | Cost             |
| --------------------- | ---------------- |
| ECS Fargate           | $10.37           |
| RDS MySQL             | $17.28           |
| **ElastiCache Redis** | **$13.14** ⬆️    |
| Others                | $0.34            |
| **Total**             | **$41.13/month** |

**Cost Increase:** +$13.14/month (+47%)

---

## 🚀 Production Cost Estimate

For **production** environment with proper redundancy:

| Service        | Staging                | Production            | Multiplier |
| -------------- | ---------------------- | --------------------- | ---------- |
| ECS Fargate    | 1 task × 256/512       | 3 tasks × 512/1024    | 6x         |
| RDS MySQL      | db.t3.micro, Single-AZ | db.t3.small, Multi-AZ | 4x         |
| ElastiCache    | cache.t3.micro × 1     | cache.t3.small × 2    | 6x         |
| Load Balancer  | None                   | ALB                   | +$16/month |
| NAT Gateway    | None                   | 1 NAT Gateway         | +$32/month |
| Backups        | 0 days                 | 7 days                | +$5/month  |
|                |                        |                       |            |
| **Staging**    | **$41/month**          |                       |            |
| **Production** |                        | **~$250-300/month**   | 6-7x       |

---

## 📝 Notes

1. **Prices are estimates** based on AWS Singapore (ap-southeast-1) pricing as of November 2025
2. **Free Tier** is NOT included in this calculation (assumes already used)
3. **Data transfer** costs may vary based on actual API usage
4. **Spot instances** not available for these services
5. **Reserved Instances** could save 30-40% for 1-year commitment

---

## 🔗 References

- [AWS Pricing Calculator](https://calculator.aws/)
- [ECS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [RDS Pricing](https://aws.amazon.com/rds/mysql/pricing/)
- [ElastiCache Pricing](https://aws.amazon.com/elasticache/pricing/)

---

**Generated from:** `terraform/environments/dev/` configuration
**Validated:** Terraform plan output
**Currency:** USD
