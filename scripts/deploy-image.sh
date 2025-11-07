#!/bin/bash

set -e

# export AWS_PROFILE=nhaituvung # Using default AWS profile
REGION=ap-southeast-1

cd terraform/environments/dev

# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repository_url)
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)

echo "🔧 Building and pushing Docker image..."
echo ""
echo "📦 ECR Repository: $ECR_URL"
echo ""

# Go back to project root
cd ../../..

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_URL

# Build image
echo ""
echo "🏗️  Building Docker image..."
docker build -t nhaituvung-app .

# Tag image
echo ""
echo "🏷️  Tagging image..."
docker tag nhaituvung-app:latest $ECR_URL:latest

# Push image
echo ""
echo "⬆️  Pushing image to ECR..."
docker push $ECR_URL:latest

# Force new deployment
echo ""
echo "🚀 Forcing new ECS deployment..."
aws ecs update-service \
  --cluster $CLUSTER \
  --service $SERVICE \
  --force-new-deployment \
  --region $REGION \
  > /dev/null

echo ""
echo "✅ Done! Wait a few moments for the service to update..."
echo ""
echo "📊 Check deployment status:"
echo "   aws ecs describe-services --cluster $CLUSTER --services $SERVICE --region $REGION"
echo ""
echo "📋 View logs:"
echo "   aws logs tail /ecs/nhaituvung-staging-app --follow --region $REGION"
echo ""
