#!/bin/bash

# Script để xem logs từ CloudWatch
# Tác giả: haotruong
# Ngày tạo: 29/10/2025

REGION="ap-southeast-1"
PROFILE="nhaituvung"
LOG_GROUP="/ecs/nhaituvung-staging-app"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 XEM LOGS REALTIME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Log Group: $LOG_GROUP"
echo "Press Ctrl+C to stop"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Đợi 2 giây trước khi tail logs
sleep 2

aws logs tail $LOG_GROUP \
  --follow \
  \
  --region $REGION \
  --format short
