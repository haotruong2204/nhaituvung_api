#!/bin/bash

# export AWS_PROFILE=nhaituvung # Using default AWS profile
cd terraform/environments/dev

CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)

echo "🔍 Getting ECS task public IP..."
echo ""

# Get task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster $CLUSTER \
  --service-name $SERVICE \
  --desired-status RUNNING \
  --query 'taskArns[0]' \
  --output text)

if [ "$TASK_ARN" == "None" ] || [ -z "$TASK_ARN" ]; then
  echo "❌ No running tasks found"
  echo "   Check ECS service status:"
  echo "   aws ecs describe-services --cluster $CLUSTER --services $SERVICE"
  exit 1
fi

echo "Task ARN: ${TASK_ARN##*/}"

# Get ENI ID
ENI_ID=$(aws ecs describe-tasks \
  --cluster $CLUSTER \
  --tasks $TASK_ARN \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text)

if [ -z "$ENI_ID" ]; then
  echo "❌ Could not get network interface ID"
  exit 1
fi

# Get Public IP
PUBLIC_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
  echo "❌ No public IP assigned"
  exit 1
fi

echo ""
echo "✅ Public IP: $PUBLIC_IP"
echo ""
echo "🚀 Access your app:"
echo "   Health Check: http://$PUBLIC_IP:3000/up"
echo "   Posts API:    http://$PUBLIC_IP:3000/api/v1/posts"
echo ""
echo "📊 View logs:"
echo "   aws logs tail /ecs/nhaituvung-staging-app --follow --region ap-southeast-1"
echo ""
