#!/bin/bash

# Script để start ECS service (scale to 1)
# Tác giả: haotruong
# Ngày tạo: 29/10/2025

REGION="ap-southeast-1"
PROFILE="default"
CLUSTER="nhaituvung-production-cluster"
SERVICE="nhaituvung-production-service"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▶️  START ECS SERVICE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Service sẽ start (scale to 1)"
echo "   Cluster: $CLUSTER"
echo "   Service: $SERVICE"
echo ""

echo "▶️  Đang start service..."

aws ecs update-service \
  --cluster $CLUSTER \
  --service $SERVICE \
  --desired-count 1 \
  --region $REGION \
  --profile $PROFILE \
  --no-cli-pager > /dev/null

echo "   ✓ Service đã được start!"
echo ""
echo "📝 Bước tiếp theo:"
echo "   1. Đợi ~30-60 giây để container start"
echo "   2. Chạy: ./scripts/get-url.sh"
echo "   3. Xem logs: ./scripts/logs.sh"
echo ""
