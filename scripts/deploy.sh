#!/bin/bash
set -e

# Script để deploy ứng dụng nhaituvung_api lên AWS ECS
# Tác giả: haotruong
# Ngày tạo: 29/10/2025

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DEPLOY NHAITUVUNG API TO AWS ECS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Cấu hình
REGION="ap-southeast-1"
# PROFILE="nhaituvung" # Using default AWS profile
TERRAFORM_DIR="terraform/environments/production"

# Lấy thông tin từ Terraform outputs
echo "📋 Lấy thông tin từ Terraform..."
cd $TERRAFORM_DIR
ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null)
CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null)
SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null)
cd ../../..

if [ -z "$ECR_URL" ] || [ -z "$CLUSTER" ] || [ -z "$SERVICE" ]; then
  echo "❌ Không thể lấy thông tin từ Terraform!"
  echo "   Hãy chạy 'terraform apply' trước."
  exit 1
fi

echo "   ✓ ECR Repository: $ECR_URL"
echo "   ✓ Cluster: $CLUSTER"
echo "   ✓ Service: $SERVICE"
echo ""

# Bước 1: Login vào ECR
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Bước 1/4: Login vào ECR..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_URL
echo "   ✓ Đăng nhập thành công!"
echo ""

# Bước 2: Build Docker image
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏗️  Bước 2/4: Build Docker image..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker build -t nhaituvung-app .
echo "   ✓ Build thành công!"
echo ""

# Bước 3: Tag và Push image
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⬆️  Bước 3/4: Push image lên ECR..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker tag nhaituvung-app:latest $ECR_URL:latest
docker push $ECR_URL:latest
echo "   ✓ Push thành công!"
echo ""

# Bước 4: Force redeploy ECS service
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "♻️  Bước 4/4: Redeploy ECS service..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws ecs update-service \
  --cluster $CLUSTER \
  --service $SERVICE \
  --force-new-deployment \
  --region $REGION \
  \
  --no-cli-pager > /dev/null
echo "   ✓ Deployment đã được khởi động!"
echo ""

# Hoàn thành
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DEPLOY THÀNH CÔNG!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Bước tiếp theo:"
echo "   1. Đợi ~30-60 giây để container start"
echo "   2. Chạy: ./scripts/get-app-url.sh"
echo "   3. Xem logs: ./scripts/logs.sh"
echo ""
