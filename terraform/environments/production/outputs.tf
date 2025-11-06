output "alb_dns_name" {
  description = "Application Load Balancer DNS"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "Application URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS Address (without port)"
  value       = aws_db_instance.main.address
}

output "redis_endpoint" {
  description = "Redis Primary Endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "Redis Port"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}

output "redis_url" {
  description = "Redis Connection URL"
  value       = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}/0"
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.app.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.app.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = aws_subnet.private[*].id
}

output "deployment_summary" {
  description = "Deployment Summary"
  value       = <<-EOT
  ========================================
  🚀 Production-Demo Environment (Full Stack)
  ========================================
  Environment: ${var.environment}
  Purpose: Learning AWS + Product Demo
  Architecture: Production-grade with stop/start capability
  📊 ACCESS POINTS:
  • 🌐 Application URL: http://${aws_lb.main.dns_name}
  • 🐳 ECR: ${aws_ecr_repository.app.repository_url}
  • 🗄️  RDS: ${aws_db_instance.main.address}:3306
  • 🔴 Redis: ${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379
  • 📊 Logs: ${aws_cloudwatch_log_group.app.name}
  ⚙️  ECS CONFIGURATION:
  • Cluster: ${aws_ecs_cluster.main.name}
  • Service: ${aws_ecs_service.app.name}
  • Tasks: ${var.ecs_desired_count} (Min: ${var.ecs_min_count}, Max: ${var.ecs_max_count})
  • CPU/Memory: ${var.ecs_task_cpu} vCPU / ${var.ecs_task_memory} MB
  • Auto Scaling: ${var.enable_auto_scaling ? "Enabled" : "Disabled"}
  🔐 SECURITY:
  • VPC: ${aws_vpc.main.id}
  • Public Subnets: ${length(aws_subnet.public)}
  • Private Subnets: ${length(aws_subnet.private)}
  • Security Groups: ALB, ECS, RDS, Redis
  💰 COST CONTROL:
  • RDS Multi-AZ: ${var.db_multi_az} (Can stop when false)
  • Backups: Disabled (as requested)
  • Container Insights: ${var.enable_container_insights ? "Enabled" : "Disabled"}
  • NAT Gateway: Disabled (using public subnets)
  🎯 TO START/STOP:
  1. Stop ECS: aws ecs update-service --desired-count 0 --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.app.name}
  2. Stop RDS: aws rds stop-db-instance --db-instance-identifier ${aws_db_instance.main.id}
  3. Start ECS: aws ecs update-service --desired-count ${var.ecs_desired_count} --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.app.name}
  4. Start RDS: aws rds start-db-instance --db-instance-identifier ${aws_db_instance.main.id}
  📝 LOGS & MONITORING:
  • CloudWatch Logs: ${aws_cloudwatch_log_group.app.name}
  • Retention: 7 days
  • Health Check: ${var.health_check_path}
  🎓 LEARNING RESOURCES:
  • ALB: Application Load Balancer with health checks
  • ECS Fargate: Serverless containers with auto scaling
  • RDS: Managed MySQL database
  • ElastiCache: Managed Redis cluster
  • CloudWatch: Centralized logging and monitoring
  ========================================
  💵 Estimated Cost: ~$85-95/month
  When stopped (ECS=0, RDS stopped):
  • ALB: ~$16/month (always running)
  • Redis: ~$26/month (cannot stop)
  • RDS Storage: ~$7/month (storage only)
  • Others: ~$2/month
  • Total when stopped: ~$51/month
  Savings when stopped: ~$40/month (42%)
  ========================================
  EOT
}

output "stop_commands" {
  description = "Commands to stop services"
  value       = <<-EOT
  # Stop ECS Service (stop tasks)
  aws ecs update-service \
    --cluster ${aws_ecs_cluster.main.name} \
    --service ${aws_ecs_service.app.name} \
    --desired-count 0 \
    --profile ${var.aws_profile}
  # Stop RDS Instance (can stop for up to 7 days)
  aws rds stop-db-instance \
    --db-instance-identifier ${aws_db_instance.main.id} \
    --profile ${var.aws_profile}
  # Note: Redis cannot be stopped, only deleted
  # Note: ALB will keep running and charging (~$16/month)
  EOT
}

output "start_commands" {
  description = "Commands to start services"
  value       = <<-EOT
  # Start RDS Instance
  aws rds start-db-instance \
    --db-instance-identifier ${aws_db_instance.main.id} \
    --profile ${var.aws_profile}
  # Wait for RDS to be available (~5 minutes)
  aws rds wait db-instance-available \
    --db-instance-identifier ${aws_db_instance.main.id} \
    --profile ${var.aws_profile}
  # Start ECS Service (start tasks)
  aws ecs update-service \
    --cluster ${aws_ecs_cluster.main.name} \
    --service ${aws_ecs_service.app.name} \
    --desired-count ${var.ecs_desired_count} \
    --profile ${var.aws_profile}
  EOT
}
