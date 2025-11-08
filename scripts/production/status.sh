#!/bin/bash

# Check status of all services in production-demo environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform/environments/production"

echo "📊 Production Status"
echo "=========================================="
echo ""

# Get outputs from Terraform
cd "$TF_DIR"

CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
DB_IDENTIFIER=$(terraform output -json | jq -r '.rds_endpoint.value' | cut -d':' -f1 | cut -d'.' -f1 2>/dev/null || echo "")
AWS_PROFILE=$(terraform output -raw aws_profile 2>/dev/null || echo "nhaituvung")
ALB_URL=$(terraform output -raw alb_url 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ]; then
    echo "❌ Error: Infrastructure not deployed"
    echo "   Run 'terraform apply' first"
    exit 1
fi

echo "🐳 ECS Service Status:"
ECS_INFO=$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$SERVICE_NAME" \
    --profile "$AWS_PROFILE" \
    --no-cli-pager \
    --output json)

DESIRED_COUNT=$(echo "$ECS_INFO" | jq -r '.services[0].desiredCount')
RUNNING_COUNT=$(echo "$ECS_INFO" | jq -r '.services[0].runningCount')
PENDING_COUNT=$(echo "$ECS_INFO" | jq -r '.services[0].pendingCount')

echo "   Desired: $DESIRED_COUNT"
echo "   Running: $RUNNING_COUNT"
echo "   Pending: $PENDING_COUNT"

if [ "$RUNNING_COUNT" -eq 0 ]; then
    echo "   Status: 🛑 STOPPED"
else
    echo "   Status: ✅ RUNNING"
fi

echo ""
echo "🗄️  RDS Status:"
RDS_STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_IDENTIFIER" \
    --profile "$AWS_PROFILE" \
    --no-cli-pager \
    --output json | jq -r '.DBInstances[0].DBInstanceStatus')

echo "   Status: $RDS_STATUS"

if [ "$RDS_STATUS" == "available" ]; then
    echo "   🟢 AVAILABLE"
elif [ "$RDS_STATUS" == "stopped" ]; then
    echo "   🔴 STOPPED"
elif [ "$RDS_STATUS" == "stopping" ]; then
    echo "   🟡 STOPPING..."
elif [ "$RDS_STATUS" == "starting" ]; then
    echo "   🟡 STARTING..."
else
    echo "   ⚠️  $RDS_STATUS"
fi

echo ""
echo "🔴 Redis Status:"
REDIS_STATUS=$(aws elasticache describe-cache-clusters \
    --profile "$AWS_PROFILE" \
    --no-cli-pager \
    --output json 2>/dev/null | jq -r ".CacheClusters[] | select(.CacheClusterId | contains(\"$DB_IDENTIFIER\")) | .CacheClusterStatus" || echo "unknown")

if [ "$REDIS_STATUS" == "available" ]; then
    echo "   Status: ✅ AVAILABLE (cannot stop)"
else
    echo "   Status: $REDIS_STATUS"
fi

echo ""
echo "🌐 Load Balancer:"
echo "   URL: $ALB_URL"
echo "   Status: ✅ ALWAYS RUNNING"

echo ""
echo "=========================================="

# Overall status
if [ "$RUNNING_COUNT" -gt 0 ] && [ "$RDS_STATUS" == "available" ]; then
    echo "✅ System is FULLY OPERATIONAL"
    echo "💰 Current Cost: ~$95/month"
elif [ "$RUNNING_COUNT" -eq 0 ] && [ "$RDS_STATUS" == "stopped" ]; then
    echo "🛑 System is STOPPED"
    echo "💰 Current Cost: ~$49/month"
    echo "▶️  To start: ./start-all.sh"
else
    echo "⚠️  System is PARTIALLY RUNNING"
    echo "💰 Current Cost: Variable"
fi

echo "=========================================="
echo ""
