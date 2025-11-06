output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.main.endpoint
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

output "deployment_summary" {
  description = "Deployment Summary"
  value       = <<-EOT
  ========================================
  🚀 Simple Dev Environment (Month 1-2)
  ========================================
  
  Environment: ${var.environment}
  Phase: Ultra-simple dev (~$15-20/month)
  
  🐳 ECR: ${aws_ecr_repository.app.repository_url}
  🗄️  RDS: ${aws_db_instance.main.address}:3306
  🔴 Redis: ${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379
  📊 Logs: ${aws_cloudwatch_log_group.app.name}
  
  ⚠️  To access app:
  1. Get ECS task details:
     aws ecs list-tasks --cluster ${aws_ecs_cluster.main.name} --profile nhaituvung
  
  2. Get task public IP (will provide script later)
  
  3. Access: http://<PUBLIC_IP>:3000/health
  
  💰 Cost: ~$15-20/month
  ========================================
  EOT
}
