#!/bin/bash
set -e

# Script để lấy public IP và URL của ứng dụng
# Tác giả: haotruong
# Ngày tạo: 29/10/2025

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 LẤY URL ỨNG DỤNG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Cấu hình
REGION="ap-southeast-1"
PROFILE="nhaituvung"
CLUSTER="nhaituvung-staging-cluster"
SERVICE="nhaituvung-staging-service"

# Lấy task đang chạy
echo "🔍 Đang tìm ECS task..."
TASK_ARN=$(aws ecs list-tasks \
  --cluster $CLUSTER \
  --service-name $SERVICE \
  --desired-status RUNNING \
  --region $REGION \
  --profile $PROFILE \
  --query 'taskArns[0]' \
  --output text 2>/dev/null)

if [ "$TASK_ARN" == "None" ] || [ -z "$TASK_ARN" ]; then
  echo "❌ Không tìm thấy task đang chạy!"
  echo ""
  echo "💡 Có thể do:"
  echo "   1. Service đang deploy (đợi thêm vài giây)"
  echo "   2. Container bị crash (xem logs)"
  echo "   3. Chưa deploy lần nào"
  echo ""
  echo "🔧 Hãy thử:"
  echo "   ./scripts/logs.sh       # Xem lỗi"
  echo "   ./scripts/deploy.sh     # Deploy lại"
  exit 1
fi

TASK_ID=${TASK_ARN##*/}
echo "   ✓ Task ID: $TASK_ID"
echo ""

# Lấy Public IP
echo "📡 Đang lấy Public IP..."
TASK_DETAILS=$(aws ecs describe-tasks \
  --cluster $CLUSTER \
  --tasks $TASK_ARN \
  --region $REGION \
  --profile $PROFILE 2>/dev/null)

ENI_ID=$(echo $TASK_DETAILS | jq -r '.tasks[0].attachments[0].details[] | select(.name=="networkInterfaceId") | .value')

PUBLIC_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --region $REGION \
  --profile $PROFILE \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text 2>/dev/null)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
  echo "❌ Không lấy được Public IP!"
  exit 1
fi

echo "   ✓ Public IP: $PUBLIC_IP"
echo ""

# Hiển thị thông tin
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 THÔNG TIN ỨNG DỤNG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Application URL:"
echo "   http://$PUBLIC_IP:3000"
echo ""
echo "💚 Health Check:"
echo "   http://$PUBLIC_IP:3000/up"
echo ""
echo "📊 API Documentation (nếu có):"
echo "   http://$PUBLIC_IP:3000/api-docs"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Lưu ý:"
echo "   • IP này sẽ thay đổi khi deploy lại"
echo "   • Muốn IP cố định? Dùng ALB (~\$16/tháng)"
echo ""
echo "🔧 Các lệnh hữu ích:"
echo "   ./scripts/logs.sh           # Xem logs"
echo "   ./scripts/status.sh         # Xem status"
echo "   curl http://$PUBLIC_IP:3000/up   # Test health"
echo ""
