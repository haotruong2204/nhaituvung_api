#!/bin/bash

# Start all services in production environment
# This script will start RDS and ECS tasks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform/environments/production"

echo "🚀 Starting Production Services..."
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
DESIRED_COUNT=$(terraform output -json | jq -r '.deployment_summary.value' | grep -oP 'Tasks: \K\d+' | head -1 2>/dev/null || echo "2")
DB_IDENTIFIER=$(terraform output -json | jq -r '.rds_endpoint.value' | cut -d':' -f1 | cut -d'.' -f1 2>/dev/null || echo "")
AWS_PROFILE=$(terraform output -raw aws_profile 2>/dev/null || echo "nhaituvung")
ALB_URL=$(terraform output -raw alb_url 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
    echo "❌ Error: Could not get cluster/service names from Terraform"
    echo "   Make sure you have run 'terraform apply' first"
    exit 1
fi

echo ""
echo "🎯 Configuration:"
echo "   Cluster: $CLUSTER_NAME"
echo "   Service: $SERVICE_NAME"
echo "   Desired Tasks: $DESIRED_COUNT"
echo "   Database: $DB_IDENTIFIER"
echo "   Profile: $AWS_PROFILE"
echo ""

# Confirm before starting
read -p "▶️  Start all services? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Cancelled"
    exit 0
fi

echo ""
echo "1️⃣  Starting RDS Instance..."
aws rds start-db-instance \
    --db-instance-identifier "$DB_IDENTIFIER" \
    \
    --no-cli-pager \
    >/dev/null 2>&1 || echo "   ⚠️  RDS might already be starting or running"

echo "   ⏳ Waiting for RDS to be available (this takes 5-7 minutes)..."
aws rds wait db-instance-available \
    --db-instance-identifier "$DB_IDENTIFIER" \
    \
    2>&1 | grep -v "Waiting" || true

echo "   ✅ RDS is now available"

echo ""
echo "2️⃣  Starting ECS Service (setting desired count to $DESIRED_COUNT)..."
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --desired-count "$DESIRED_COUNT" \
    \
    --no-cli-pager \
    >/dev/null

echo "   ⏳ Waiting for ECS tasks to start (2-3 minutes)..."
sleep 30

# Check task status
RUNNING_TASKS=$(aws ecs list-tasks \
    --cluster "$CLUSTER_NAME" \
    --service-name "$SERVICE_NAME" \
    --desired-status RUNNING \
    \
    --no-cli-pager \
    --output json | jq -r '.taskArns | length')

echo "   ✅ ECS tasks starting ($RUNNING_TASKS/$DESIRED_COUNT running)"

echo ""
echo "=========================================="
echo "✅ SERVICES STARTED!"
echo "=========================================="
echo ""
echo "🌐 Application URL:"
echo "   $ALB_URL"
echo ""
echo "⏱️  Wait 2-3 minutes for:"
echo "   • ECS tasks to fully start"
echo "   • Health checks to pass"
echo "   • ALB to register targets"
echo ""
echo "🔍 Check status:"
echo "   ./status.sh"
echo ""
echo "📊 View logs:"
echo "   ./logs.sh"
echo ""
echo "💰 Cost resumed: ~$95/month (when fully running)"
echo ""
