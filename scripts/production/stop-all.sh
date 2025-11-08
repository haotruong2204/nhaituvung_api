#!/bin/bash

# Stop all services in production-demo environment
# This script will stop ECS tasks and RDS to save cost
# Note: ALB and Redis will continue running and charging

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform/environments/production"

echo "🛑 Stopping Production Services..."
echo "=========================================="
echo ""

# Check if terraform directory exists
if [ ! -d "$TF_DIR" ]; then
    echo "❌ Error: Terraform directory not found: $TF_DIR"
    exit 1
fi

# Get outputs from Terraform
cd "$TF_DIR"

echo "📊 Getting infrastructure details..."
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
DB_IDENTIFIER=$(terraform output -json | jq -r '.rds_endpoint.value' | cut -d':' -f1 | cut -d'.' -f1 2>/dev/null || echo "")
AWS_PROFILE=$(terraform output -raw aws_profile 2>/dev/null || echo "nhaituvung")

if [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
    echo "❌ Error: Could not get cluster/service names from Terraform"
    echo "   Make sure you have run 'terraform apply' first"
    exit 1
fi

echo ""
echo "🎯 Configuration:"
echo "   Cluster: $CLUSTER_NAME"
echo "   Service: $SERVICE_NAME"
echo "   Database: $DB_IDENTIFIER"
echo "   Profile: $AWS_PROFILE"
echo ""

# Confirm before stopping
read -p "⚠️  Are you sure you want to stop all services? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Cancelled"
    exit 0
fi

echo ""
echo "1️⃣  Stopping ECS Service (setting desired count to 0)..."
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --desired-count 0 \
    --profile "$AWS_PROFILE" \
    --no-cli-pager \
    >/dev/null

echo "   ✅ ECS tasks will stop in ~30 seconds"

echo ""
echo "2️⃣  Stopping RDS Instance..."
aws rds stop-db-instance \
    --db-instance-identifier "$DB_IDENTIFIER" \
    --profile "$AWS_PROFILE" \
    --no-cli-pager \
    >/dev/null 2>&1 || echo "   ⚠️  RDS might already be stopped or stopping"

echo "   ✅ RDS will stop in ~5 minutes"

echo ""
echo "=========================================="
echo "✅ STOP COMMAND SENT!"
echo "=========================================="
echo ""
echo "💰 Cost Savings:"
echo "   • ECS Fargate: ~$35/month → $0"
echo "   • RDS Instance: ~$26/month → $0"
echo "   • Total Saved: ~$61/month"
echo ""
echo "💸 Still Running (unavoidable):"
echo "   • ALB: ~$16/month"
echo "   • Redis: ~$26/month"
echo "   • RDS Storage: ~$7/month"
echo "   • Total: ~$49/month"
echo ""
echo "⏱️  Timeline:"
echo "   • ECS tasks: Stopped in 30-60 seconds"
echo "   • RDS: Stopped in 5-7 minutes"
echo ""
echo "⚠️  Important Notes:"
echo "   • RDS will auto-start after 7 days"
echo "   • Redis cannot be stopped (in-memory database)"
echo "   • ALB continues to run (needed for infrastructure)"
echo ""
echo "🔄 To start again, run: ./start-all.sh"
echo ""
