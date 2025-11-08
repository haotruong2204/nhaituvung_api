#!/bin/bash

# Script để stop ECS service (scale to 0)
# Tác giả: haotruong
# Ngày tạo: 29/10/2025

REGION="ap-southeast-1"
PROFILE="default"
CLUSTER="nhaituvung-production-cluster"
SERVICE="nhaituvung-production-service"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏸️  STOP ECS SERVICE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  Service sẽ stop (scale to 0)"
echo "   Cluster: $CLUSTER"
echo "   Service: $SERVICE"
echo ""
read -p "Bạn có chắc chắn? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Đã hủy"
  exit 1
fi

echo ""
echo "⏸️  Đang stop service..."

aws ecs update-service \
  --cluster $CLUSTER \
  --service $SERVICE \
  --desired-count 0 \
  --region $REGION \
  --profile $PROFILE \
  --no-cli-pager > /dev/null

echo "   ✓ Service đã được stop!"
echo ""
echo "💡 Để start lại:"
echo "   ./scripts/start.sh"
echo ""
