## 📋 Mục Lục

1. [Chuẩn Bị](#chuẩn-bị)

2. [Bước 1: Xác Thực AWS](#bước-1-xác-thực-aws)

3. [Bước 2: Chuẩn Bị Infrastructure với Terraform](#bước-2-chuẩn-bị-infrastructure-với-terraform)

4. [Bước 3: Build và Push Docker Image](#bước-3-build-và-push-docker-image)

5. [Bước 4: Deploy Application](#bước-4-deploy-application)

6. [Bước 5: Database Setup](#bước-5-database-setup)

7. [Bước 6: Verify và Monitor](#bước-6-verify-và-monitor)

8. [Quản Lý Sau Deploy](#quản-lý-sau-deploy)

9. [Troubleshooting](#troubleshooting)

---

## Chuẩn Bị

### Kiểm tra tools cần thiết:

```bash

# Kiểm tra AWS CLI

aws --version

# Kết quả mong đợi: aws-cli/2.x.x



# Kiểm tra Terraform

terraform --version

# Kết quả mong đợi: Terraform v1.x.x



# Kiểm tra Docker

docker --version

# Kết quả mong đợi: Docker version 20.x.x



# Kiểm tra AWS credentials

aws sts get-caller-identity

# Sẽ hiện Account ID, User ARN của bạn

```

### Cấu trúc thư mục cần biết:

```

nhaituvung_api/

├── terraform/

│   └── environments/

│       └── production/

│           ├── main.tf           # Infrastructure definition

│           ├── terraform.tfvars  # Biến cấu hình

│           └── outputs.tf        # Output values

├── Dockerfile                    # Docker image build instructions

└── config/

    └── database.yml             # Rails database config

```

---

## Bước 1: Xác Thực AWS

### 1.1. Kiểm tra AWS profile hiện tại

```bash

# Xem cấu hình AWS

cat ~/.aws/credentials



# Xem config

cat ~/.aws/config



# Test authentication

aws sts get-caller-identity

```

**Kết quả sẽ hiện:**

```json
{
  "UserId": "AIDAI...",

  "Account": "123456789012",

  "Arn": "arn:aws:iam::123456789012:user/your-name"
}
```

### 1.2. Set region (nếu cần)

```bash

export AWS_DEFAULT_REGION=ap-southeast-1



# Verify

echo $AWS_DEFAULT_REGION

```

---

## Bước 2: Chuẩn Bị Infrastructure với Terraform

### 2.1. Di chuyển vào thư mục Terraform

```bash

cd terraform/environments/production

```

### 2.2. Xem file cấu hình

```bash

# Xem biến cần thiết

cat terraform.tfvars

```

**Nội dung terraform.tfvars:**

```hcl

aws_profile = "default"

aws_region  = "ap-southeast-1"

db_name     = "nhaituvung_production"

db_username = "admin"

db_password = "NhaiTuVung2024_SecurePass_987"

secret_key_base = "aadf64b2d2fb9c61d6a5aacb13593162..."

```

### 2.3. Initialize Terraform

```bash

# Download providers và setup backend

terraform init



# Kết quả mong đợi:

# - Terraform has been successfully initialized!

# - Provider plugins installed: hashicorp/aws

```

**Giải thích:**

- `terraform init` download AWS provider plugin

- Tạo `.terraform/` directory với dependencies

- Setup backend để lưu state file

### 2.4. Validate cấu hình

```bash

# Kiểm tra syntax

terraform validate



# Kết quả: Success! The configuration is valid.

```

### 2.5. Xem plan trước khi apply

```bash

# Xem những gì sẽ được tạo

terraform plan



# Hoặc save plan để review kỹ

terraform plan -out=tfplan



# Xem chi tiết plan đã save

terraform show tfplan

```

**Giải thích output:**

```

Plan: 45 to add, 0 to change, 0 to destroy.



Terraform will perform the following actions:



  # aws_vpc.main will be created

  + resource "aws_vpc" "main" {

      + cidr_block = "10.0.0.0/16"

      ...

  }



  # aws_ecs_cluster.main will be created

  # aws_rds_instance.main will be created

  # aws_elasticache_cluster.redis will be created

  ...

```

**Resources sẽ được tạo:**

- VPC với public/private subnets

- Application Load Balancer (ALB)

- ECS Cluster và Task Definition

- RDS MySQL instance

- ElastiCache Redis

- ECR repository

- Security Groups

- CloudWatch Log Groups

### 2.6. Apply infrastructure (LẦN ĐẦU TIÊN)

```bash

# Apply changes

terraform apply



# Hoặc dùng plan đã save

terraform apply tfplan

```

**Lưu ý:**

- Terraform sẽ hỏi confirm: gõ `yes`

- Quá trình mất **15-20 phút**

- Theo dõi progress trong terminal

**Troubleshooting common errors:**

```bash

# Nếu gặp lỗi về credentials

aws sts get-caller-identity  # Verify lại authentication



# Nếu gặp lỗi về resources đã tồn tại

terraform state list         # Xem state hiện tại

terraform state rm <resource>  # Remove resource khỏi state nếu cần



# Nếu cần retry sau lỗi

terraform apply  # Terraform sẽ tiếp tục từ chỗ dừng

```

### 2.7. Lấy thông tin outputs sau khi apply xong

```bash

# Xem tất cả outputs

terraform output



# Lấy từng giá trị cụ thể

terraform output ecr_repository_url

terraform output alb_dns_name

terraform output ecs_cluster_name

terraform output ecs_service_name

```

**Lưu các giá trị này, bạn sẽ cần:**

```bash

# Save vào biến môi trường để dùng sau

export ECR_REPO=$(terraform output -raw ecr_repository_url)

export CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)

export SERVICE_NAME=$(terraform output -raw ecs_service_name)

export ALB_DNS=$(terraform output -raw alb_dns_name)



# Verify

echo "ECR: $ECR_REPO"

echo "Cluster: $CLUSTER_NAME"

echo "Service: $SERVICE_NAME"

echo "ALB: $ALB_DNS"

```

---

## Bước 3: Build và Push Docker Image

### 3.1. Di chuyển về project root

```bash

cd /home/user/nhaituvung_api

```

### 3.2. Lấy ECR repository URL

```bash

# Nếu chưa lưu biến ở bước 2.7

cd terraform/environments/production

export ECR_REPO=$(terraform output -raw ecr_repository_url)

cd -



echo $ECR_REPO

# Kết quả: 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/nhaituvung-production-api

```

### 3.3. Login vào ECR

```bash

# Lấy password và login Docker vào ECR

aws ecr get-login-password --region ap-southeast-1 | \

  docker login --username AWS --password-stdin $ECR_REPO



# Kết quả: Login Succeeded

```

**Giải thích:**

- `aws ecr get-login-password`: Lấy temporary password (valid 12 hours)

- `docker login`: Authenticate Docker CLI với ECR

- Password được pipe qua stdin (không lưu vào history)

### 3.4. Build Docker image

```bash

# Build image với tag latest

docker build -t nhaituvung-api:latest .



# Theo dõi build process

# Dockerfile sẽ:

# - Dùng Ruby 3.3.6 base image

# - Install dependencies (gems)

# - Copy application code

# - Precompile assets (nếu có)

# - Setup entrypoint

```

**Build arguments (nếu cần customize):**

```bash

# Build với build args

docker build \

  --build-arg RAILS_ENV=production \

  --build-arg SECRET_KEY_BASE=$SECRET_KEY_BASE \

  -t nhaituvung-api:latest \

  .

```

### 3.5. Tag image cho ECR

```bash

# Tag với latest

docker tag nhaituvung-api:latest $ECR_REPO:latest



# Tag với timestamp (recommended cho tracking)

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

docker tag nhaituvung-api:latest $ECR_REPO:$TIMESTAMP



# Tag với git commit SHA (best practice)

GIT_SHA=$(git rev-parse --short HEAD)

docker tag nhaituvung-api:latest $ECR_REPO:$GIT_SHA



# Xem các images đã tag

docker images | grep nhaituvung

```

**Kết quả:**

```

REPOSITORY                                               TAG            IMAGE ID       CREATED

123...ecr...amazonaws.com/nhaituvung-production-api     latest         abc123def456   2 minutes ago

123...ecr...amazonaws.com/nhaituvung-production-api     20250108-1430  abc123def456   2 minutes ago

123...ecr...amazonaws.com/nhaituvung-production-api     cabe1d0        abc123def456   2 minutes ago

nhaituvung-api                                          latest         abc123def456   2 minutes ago

```

### 3.6. Push image lên ECR

```bash

# Push latest tag

docker push $ECR_REPO:latest



# Push timestamp tag (để rollback nếu cần)

docker push $ECR_REPO:$TIMESTAMP



# Push git SHA tag

docker push $ECR_REPO:$GIT_SHA

```

**Theo dõi progress:**

```

The push refers to repository [123...ecr...amazonaws.com/nhaituvung-production-api]

abc123def: Pushed

def456ghi: Pushed

latest: digest: sha256:789... size: 3456

```

### 3.7. Verify image trên ECR

```bash

# List images trong ECR repository

aws ecr describe-images \

  --repository-name nhaituvung-production-api \

  --region ap-southeast-1



# Hoặc chỉ xem tags

aws ecr list-images \

  --repository-name nhaituvung-production-api \

  --region ap-southeast-1 \

  --query 'imageIds[*].imageTag' \

  --output table

```

---

## Bước 4: Deploy Application

### 4.1. Lấy thông tin ECS cluster và service

```bash

cd terraform/environments/production



# Lấy cluster name

export CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)



# Lấy service name

export SERVICE_NAME=$(terraform output -raw ecs_service_name)



# Verify

echo "Cluster: $CLUSTER_NAME"

echo "Service: $SERVICE_NAME"

```

### 4.2. Force new deployment (ECS sẽ pull image mới)

```bash

# Update service để pull latest image từ ECR

aws ecs update-service \

  --cluster $CLUSTER_NAME \

  --service $SERVICE_NAME \

  --force-new-deployment \

  --region ap-southeast-1



# Kết quả sẽ hiện service configuration mới

```

**Giải thích:**

- `--force-new-deployment`: Bắt ECS tạo task mới với image mới nhất

- ECS sẽ:

  1. Pull image từ ECR

  2. Tạo task mới

  3. Đợi task healthy (health check pass)

  4. Stop task cũ

  5. Đăng ký task mới vào ALB target group

### 4.3. Theo dõi deployment progress

```bash

# Xem service events (real-time)

aws ecs describe-services \

  --cluster $CLUSTER_NAME \

  --services $SERVICE_NAME \

  --region ap-southeast-1 \

  --query 'services[0].events[0:10]' \

  --output table

```

**Events bạn sẽ thấy:**

```

(service SERVICE_NAME) has started 1 tasks: (task abc123).

(service SERVICE_NAME) registered 1 targets in (target-group arn:...)

(service SERVICE_NAME) has reached a steady state.

```

### 4.4. Xem running tasks

```bash

# List tất cả tasks đang chạy

aws ecs list-tasks \

  --cluster $CLUSTER_NAME \

  --service-name $SERVICE_NAME \

  --region ap-southeast-1



# Lấy task ARN

export TASK_ARN=$(aws ecs list-tasks \

  --cluster $CLUSTER_NAME \

  --service-name $SERVICE_NAME \

  --region ap-southeast-1 \

  --query 'taskArns[0]' \

  --output text)



echo "Task ARN: $TASK_ARN"

```

### 4.5. Xem chi tiết task

```bash

# Xem task details

aws ecs describe-tasks \

  --cluster $CLUSTER_NAME \

  --tasks $TASK_ARN \

  --region ap-southeast-1



# Chỉ xem container status

aws ecs describe-tasks \

  --cluster $CLUSTER_NAME \

  --tasks $TASK_ARN \

  --region ap-southeast-1 \

  --query 'tasks[0].containers[*].[name,lastStatus,healthStatus]' \

  --output table

```

**Kết quả mong đợi:**

```

-----------------------

|   DescribeTasks     |

+---------+----------+--------+

|  nhaituvung-api | RUNNING | HEALTHY |

+---------+----------+--------+

```

### 4.6. Lấy URL của application

```bash

cd terraform/environments/production



# Lấy ALB DNS name

export ALB_DNS=$(terraform output -raw alb_dns_name)



echo "Application URL: http://$ALB_DNS"



# Test với curl

curl http://$ALB_DNS/health

# Hoặc

curl http://$ALB_DNS

```

---

## Bước 5: Database Setup

### 5.1. Chờ RDS instance sẵn sàng

```bash

# Lấy RDS instance identifier

cd terraform/environments/production

export DB_INSTANCE=$(terraform output -raw db_instance_id)



# Check RDS status

aws rds describe-db-instances \

  --db-instance-identifier $DB_INSTANCE \

  --region ap-southeast-1 \

  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address,Endpoint.Port]' \

  --output table

```

**Status cần là "available":**

```

--------------------------

|  DescribeDBInstances   |

+------------+-------------------+------+

|  available |  db-endpoint.rds. |  3306|

+------------+-------------------+------+

```

### 5.2. Run database migrations

```bash

# Lấy task ARN (nếu chưa có)

export TASK_ARN=$(aws ecs list-tasks \

  --cluster $CLUSTER_NAME \

  --service-name $SERVICE_NAME \

  --region ap-southeast-1 \

  --query 'taskArns[0]' \

  --output text)



# Run migration command trong container

aws ecs execute-command \

  --cluster $CLUSTER_NAME \

  --task $TASK_ARN \

  --container nhaituvung-api \

  --interactive \

  --command "bundle exec rails db:migrate RAILS_ENV=production" \

  --region ap-southeast-1

```

**Lưu ý:** Nếu ECS Exec chưa được enable, dùng cách khác:

```bash

# Chạy migration bằng cách chạy one-off task

aws ecs run-task \

  --cluster $CLUSTER_NAME \

  --task-definition nhaituvung-production-api \

  --launch-type FARGATE \

  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \

  --overrides '{"containerOverrides":[{"name":"nhaituvung-api","command":["bundle","exec","rails","db:migrate"]}]}' \

  --region ap-southeast-1

```

### 5.3. (Optional) Seed database

```bash

# Run db:seed nếu cần data mẫu

aws ecs execute-command \

  --cluster $CLUSTER_NAME \

  --task $TASK_ARN \

  --container nhaituvung-api \

  --interactive \

  --command "bundle exec rails db:seed RAILS_ENV=production" \

  --region ap-southeast-1

```

---

## Bước 6: Verify và Monitor

### 6.1. Test application endpoints

```bash

# Health check

curl http://$ALB_DNS/health



# Test main endpoint

curl http://$ALB_DNS/



# Test với verbose để xem headers

curl -v http://$ALB_DNS/

```

### 6.2. Xem application logs

```bash

# Lấy log group name

cd terraform/environments/production

export LOG_GROUP=$(terraform output -raw cloudwatch_log_group)



echo "Log Group: $LOG_GROUP"



# Xem recent logs (last 10 minutes)

aws logs tail $LOG_GROUP \

  --follow \

  --region ap-southeast-1



# Hoặc xem logs của specific stream

aws logs describe-log-streams \

  --log-group-name $LOG_GROUP \

  --region ap-southeast-1 \

  --order-by LastEventTime \

  --descending \

  --max-items 1



# Lấy stream name và xem logs

export LOG_STREAM=$(aws logs describe-log-streams \

  --log-group-name $LOG_GROUP \

  --region ap-southeast-1 \

  --order-by LastEventTime \

  --descending \

  --max-items 1 \

  --query 'logStreams[0].logStreamName' \

  --output text)



aws logs get-log-events \

  --log-group-name $LOG_GROUP \

  --log-stream-name $LOG_STREAM \

  --region ap-southeast-1

```

### 6.3. Monitor ECS service health

```bash

# Xem service metrics

aws ecs describe-services \

  --cluster $CLUSTER_NAME \

  --services $SERVICE_NAME \

  --region ap-southeast-1 \

  --query 'services[0].[runningCount,desiredCount,deployments[*].[status,runningCount,desiredCount]]' \

  --output json

```

**Healthy service sẽ có:**

- `runningCount == desiredCount`

- `deployments[0].status == PRIMARY`

- All tasks in RUNNING state

### 6.4. Check ALB target health

```bash

# Lấy target group ARN

cd terraform/environments/production

export TG_ARN=$(terraform output -raw target_group_arn)



# Xem target health

aws elbv2 describe-target-health \

  --target-group-arn $TG_ARN \

  --region ap-southeast-1 \

  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]' \

  --output table

```

**Kết quả mong đợi:**

```

--------------------------------------

|     DescribeTargetHealth           |

+----------------------+--------+-----+

|  ip-10-0-1-123      | healthy| None |

+----------------------+--------+-----+

```

---

## Quản Lý Sau Deploy

### Start Services (Khi đã stop trước đó)

#### Start RDS

```bash

# Lấy DB instance ID

cd terraform/environments/production

export DB_INSTANCE=$(terraform output -raw db_instance_id)



# Start RDS

aws rds start-db-instance \

  --db-instance-identifier $DB_INSTANCE \

  --region ap-southeast-1



# Check progress

aws rds describe-db-instances \

  --db-instance-identifier $DB_INSTANCE \

  --region ap-southeast-1 \

  --query 'DBInstances[0].DBInstanceStatus' \

  --output text



# Đợi cho đến khi status = "available" (mất ~5 phút)

```

#### Start ECS Service

```bash

# Update desired count từ 0 về 1

aws ecs update-service \

  --cluster $CLUSTER_NAME \

  --service $SERVICE_NAME \

  --desired-count 1 \

  --region ap-southeast-1



# Verify

aws ecs describe-services \

  --cluster $CLUSTER_NAME \

  --services $SERVICE_NAME \

  --region ap-southeast-1 \

  --query 'services[0].[desiredCount,runningCount]' \

  --output table

```

### Stop Services (Để tiết kiệm chi phí)

#### Stop ECS Service

```bash

# Set desired count = 0

aws ecs update-service \

  --cluster $CLUSTER_NAME \

  --service $SERVICE_NAME \

  --desired-count 0 \

  --region ap-southeast-1



# Verify tasks đã stop

aws ecs list-tasks \

  --cluster $CLUSTER_NAME \

  --service-name $SERVICE_NAME \

  --region ap-southeast-1

# Kết quả: taskArns: [] (empty)

```

#### Stop RDS

```bash

# Stop RDS (có thể stop tối đa 7 ngày)

aws rds stop-db-instance \

  --db-instance-identifier $DB_INSTANCE \

  --region ap-southeast-1



# Check status

aws rds describe-db-instances \

  --db-instance-identifier $DB_INSTANCE \

  --region ap-southeast-1 \

  --query 'DBInstances[0].DBInstanceStatus' \

  --output text

# Status sẽ: stopping -> stopped

```

### Check Overall Status

```bash

# Check tất cả services cùng lúc



echo "=== RDS Status ==="

aws rds describe-db-instances \

  --db-instance-identifier $DB_INSTANCE \

  --region ap-southeast-1 \

  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' \

  --output table



echo -e "\n=== ECS Service Status ==="

aws ecs describe-services \

  --cluster $CLUSTER_NAME \

  --services $SERVICE_NAME \

  --region ap-southeast-1 \

  --query 'services[0].[status,desiredCount,runningCount]' \

  --output table



echo -e "\n=== ECS Tasks ==="

aws ecs list-tasks \

  --cluster $CLUSTER_NAME \

  --service-name $SERVICE_NAME \

  --region ap-southeast-1 \

  --query 'taskArns' \

  --output table



echo -e "\n=== ElastiCache Status ==="

aws elasticache describe-cache-clusters \

  --region ap-southeast-1 \

  --query 'CacheClusters[?contains(CacheClusterId,`nhaituvung`)].[CacheClusterId,CacheClusterStatus]' \

  --output table

```

---

## Update Code (Deploy Changes)

### Khi có code mới:

```bash

# 1. Commit code changes

git add .

git commit -m "feat: new feature"



# 2. Build new image

cd /home/user/nhaituvung_api

docker build -t nhaituvung-api:latest .



# 3. Get ECR info

cd terraform/environments/production

export ECR_REPO=$(terraform output -raw ecr_repository_url)

cd -



# 4. Login ECR

aws ecr get-login-password --region ap-southeast-1 | \

  docker login --username AWS --password-stdin $ECR_REPO



# 5. Tag image

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

docker tag nhaituvung-api:latest $ECR_REPO:latest

docker tag nhaituvung-api:latest $ECR_REPO:$TIMESTAMP



# 6. Push image

docker push $ECR_REPO:latest

docker push $ECR_REPO:$TIMESTAMP



# 7. Force ECS deployment

aws ecs update-service \

  --cluster $CLUSTER_NAME \

  --service $SERVICE_NAME \

  --force-new-deployment \

  --region ap-southeast-1



# 8. Monitor deployment

aws logs tail $(terraform output -raw cloudwatch_log_group) \

  --follow \

  --region ap-southeast-1

```

---

## Troubleshooting

### 1. ECS Task không start được

**Check task stopped reason:**

```bash

# List tất cả tasks (bao gồm stopped)

aws ecs list-tasks \

  --cluster $CLUSTER_NAME \

  --service-name $SERVICE_NAME \

  --desired-status STOPPED \

  --region ap-southeast-1



# Lấy stopped task ARN

export STOPPED_TASK=$(aws ecs list-tasks \

  --cluster $CLUSTER_NAME \

  --service-name $SERVICE_NAME \

  --desired-status STOPPED \

  --region ap-southeast-1 \

  --query 'taskArns[0]' \

  --output text)



# Xem lý do stopped

aws ecs describe-tasks \

  --cluster $CLUSTER_NAME \

  --tasks $STOPPED_TASK \

  --region ap-southeast-1 \

  --query 'tasks[0].[stoppedReason,containers[0].reason]'

```

**Common issues:**

- `CannotPullContainerError`: ECR permissions hoặc image không tồn tại

- `Essential container exited`: Application crashed (xem logs)

- `OutOfMemory`: Tăng memory trong task definition

### 2. Application không response

**Check ALB target health:**

```bash

aws elbv2 describe-target-health \

  --target-group-arn $TG_ARN \

  --region ap-southeast-1

```

**Nếu targets unhealthy:**

- Check health check endpoint: `/health` có response 200?

- Check security groups: Container có cho phép traffic từ ALB?

- Check logs: Application có lỗi gì?

### 3. Database connection errors

**Check RDS status:**

```bash

aws rds describe-db-instances \

  --db-instance-identifier $DB_INSTANCE \

  --region ap-southeast-1 \

  --query 'DBInstances[0].[DBInstanceStatus,Endpoint]'

```

**Check security groups:**

```bash

# RDS security group phải allow traffic từ ECS tasks

# Verify trong terraform outputs:

terraform output db_security_group_id

terraform output ecs_security_group_id

```

**Test connection từ ECS task:**

```bash

# SSH vào container

aws ecs execute-command \

  --cluster $CLUSTER_NAME \

  --task $TASK_ARN \

  --container nhaituvung-api \

  --interactive \

  --command "/bin/bash" \

  --region ap-southeast-1



# Trong container, test MySQL connection

mysql -h $DB_ENDPOINT -u admin -p

```

### 4. Xem detailed logs

```bash

# Container logs từ CloudWatch

aws logs get-log-events \

  --log-group-name $LOG_GROUP \

  --log-stream-name $LOG_STREAM \

  --start-time $(date -d '10 minutes ago' +%s)000 \

  --region ap-southeast-1



# Filter logs by pattern

aws logs filter-log-events \

  --log-group-name $LOG_GROUP \

  --filter-pattern "ERROR" \

  --region ap-southeast-1

```

### 5. Rollback deployment

**Rollback về image cũ:**

```bash

# 1. List images trong ECR

aws ecr describe-images \

  --repository-name nhaituvung-production-api \

  --region ap-southeast-1 \

  --query 'sort_by(imageDetails,&imagePushedAt)[*].[imageTags[0],imagePushedAt]' \

  --output table



# 2. Update task definition với image cũ

# (Hoặc đơn giản là push lại image cũ với tag latest)



# 3. Force new deployment

aws ecs update-service \

  --cluster $CLUSTER_NAME \

  --service $SERVICE_NAME \

  --force-new-deployment \

  --region ap-southeast-1

```

---

## Chi Phí và Optimization

### Tính chi phí hiện tại

```bash

# Xem resources đang chạy

echo "=== RDS ==="

aws rds describe-db-instances \

  --region ap-southeast-1 \

  --query 'DBInstances[?contains(DBInstanceIdentifier,`nhaituvung`)].[DBInstanceClass,Engine,MultiAZ,StorageType,AllocatedStorage]' \

  --output table

# db.t3.small, MySQL, Single-AZ, gp2, 20GB ≈ $30/month



echo -e "\n=== ElastiCache ==="

aws elasticache describe-cache-clusters \

  --region ap-southeast-1 \

  --query 'CacheClusters[?contains(CacheClusterId,`nhaituvung`)].[CacheNodeType,Engine,NumCacheNodes]' \

  --output table

# cache.t3.small, redis, 1 node ≈ $29/month



echo -e "\n=== ECS Tasks ==="

# Fargate: 0.25 vCPU, 0.5 GB ≈ $10/month



echo -e "\n=== ALB ==="

# Application Load Balancer ≈ $20/month



# Total: ~$95/month running, ~$49/month stopped

```

---

## Cleanup Resources (Xoá Hẳn)

### Nếu muốn destroy toàn bộ infrastructure:

```bash

# 1. Di chuyển vào Terraform directory

cd terraform/environments/production



# 2. Preview những gì sẽ bị xoá

terraform plan -destroy



# 3. Destroy (CẢNH BÁO: Sẽ mất hết data!)

terraform destroy



# Terraform sẽ hỏi confirm: gõ "yes"



# 4. Verify ECR images (terraform không xoá images)

aws ecr describe-images \

  --repository-name nhaituvung-production-api \

  --region ap-southeast-1



# 5. Xoá ECR images nếu muốn

aws ecr batch-delete-image \

  --repository-name nhaituvung-production-api \

  --image-ids imageTag=latest \

  --region ap-southeast-1

```

---

## Useful Commands Summary

```bash

# === AWS Authentication ===

aws sts get-caller-identity

aws configure list



# === Terraform ===

terraform init

terraform validate

terraform plan

terraform apply

terraform output

terraform destroy



# === Docker ===

docker build -t <name>:<tag> .

docker tag <source> <target>

docker push <image>

docker images



# === ECR ===

aws ecr get-login-password | docker login --username AWS --password-stdin <repo>

aws ecr describe-images --repository-name <name>

aws ecr list-images --repository-name <name>



# === ECS ===

aws ecs update-service --cluster <cluster> --service <service> --force-new-deployment

aws ecs describe-services --cluster <cluster> --services <service>

aws ecs list-tasks --cluster <cluster> --service-name <service>

aws ecs describe-tasks --cluster <cluster> --tasks <task-arn>

aws ecs execute-command --cluster <cluster> --task <task> --container <name> --interactive --command "<cmd>"



# === RDS ===

aws rds describe-db-instances --db-instance-identifier <id>

aws rds start-db-instance --db-instance-identifier <id>

aws rds stop-db-instance --db-instance-identifier <id>



# === CloudWatch Logs ===

aws logs tail <log-group> --follow

aws logs describe-log-streams --log-group-name <group>

aws logs get-log-events --log-group-name <group> --log-stream-name <stream>



# === ALB ===

aws elbv2 describe-target-health --target-group-arn <arn>

aws elbv2 describe-load-balancers

```

---

## Next Steps

Sau khi đã hiểu rõ CLI commands, bạn có thể:

1. **Tự động hoá:** Viết scripts riêng của bạn

2. **CI/CD:** Integrate vào GitHub Actions hoặc GitLab CI

3. **Monitoring:** Setup CloudWatch alarms

4. **SSL/HTTPS:** Setup ACM certificate và configure ALB listener

5. **Custom Domain:** Point api.nhaituvung.com tới ALB

6. **Auto-scaling:** Configure ECS service auto-scaling based on metrics

---

**Tài liệu này được tạo để học cách deploy bằng CLI thuần tuý. Sau khi hiểu rõ, bạn có thể dùng scripts trong `/scripts` và `/scripts/production` để tự động hoá các bước.**
