#!/bin/bash

# Script để xem status của ECS service
# Tác giả: haotruong
# Ngày tạo: 29/10/2025

REGION="ap-southeast-1"
PROFILE="default"
CLUSTER="nhaituvung-production-cluster"
SERVICE="nhaituvung-production-service"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 STATUS CỦA ECS SERVICE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Lấy thông tin service
SERVICE_INFO=$(aws ecs describe-services \
  --cluster $CLUSTER \
  --services $SERVICE \
  --region $REGION \
  --profile $PROFILE)

# Parse thông tin
STATUS=$(echo $SERVICE_INFO | jq -r '.services[0].status')
DESIRED=$(echo $SERVICE_INFO | jq -r '.services[0].desiredCount')
RUNNING=$(echo $SERVICE_INFO | jq -r '.services[0].runningCount')
PENDING=$(echo $SERVICE_INFO | jq -r '.services[0].pendingCount')

echo "Service Status: $STATUS"
echo ""
echo "Tasks:"
echo "  • Desired:  $DESIRED"
echo "  • Running:  $RUNNING"
echo "  • Pending:  $PENDING"
echo ""

# Hiển thị deployment status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 DEPLOYMENTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo $SERVICE_INFO | jq -r '.services[0].deployments[] | "ID: \(.id)\nStatus: \(.status)\nDesired: \(.desiredCount)\nRunning: \(.runningCount)\nPending: \(.pendingCount)\nCreated: \(.createdAt)\n"'

# Hiển thị recent events
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RECENT EVENTS (5 gần nhất)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo $SERVICE_INFO | jq -r '.services[0].events[0:5][] | "[\(.createdAt)] \(.message)"'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check nếu có lỗi
if [ "$RUNNING" -eq 0 ] && [ "$DESIRED" -gt 0 ]; then
  echo "⚠️  CẢNH BÁO: Không có task nào đang chạy!"
  echo ""
  echo "🔧 Hãy thử:"
  echo "   ./scripts/logs.sh       # Xem logs lỗi"
  echo "   ./scripts/deploy.sh     # Deploy lại"
fi
