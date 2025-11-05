#!/bin/bash

# Script để chạy Rails migrations
# Tác giả: haotruong
# Ngày tạo: 29/10/2025

REGION="ap-southeast-1"
PROFILE="nhaituvung"
CLUSTER="nhaituvung-staging-cluster"
SERVICE="nhaituvung-staging-service"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗄️  RUN DATABASE MIGRATIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Lấy task đang chạy
echo "🔍 Đang tìm task..."
TASK_ARN=$(aws ecs list-tasks \
  --cluster $CLUSTER \
  --service-name $SERVICE \
  --desired-status RUNNING \
  --region $REGION \
  --profile $PROFILE \
  --query 'taskArns[0]' \
  --output text)

if [ "$TASK_ARN" == "None" ] || [ -z "$TASK_ARN" ]; then
  echo "❌ Không tìm thấy task đang chạy!"
  exit 1
fi

TASK_ID=${TASK_ARN##*/}
echo "   ✓ Task ID: $TASK_ID"
echo ""
echo "🗄️  Đang chạy migrations..."
echo ""

# Chạy migrations
aws ecs execute-command \
  --cluster $CLUSTER \
  --task $TASK_ID \
  --container app \
  --interactive \
  --command "bundle exec rails db:migrate" \
  --profile $PROFILE \
  --region $REGION

echo ""
echo "✅ Migrations hoàn thành!"
