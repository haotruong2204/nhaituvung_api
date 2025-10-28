###########################################
# Outputs - Important Information
###########################################

# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

# Subnets
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# Security Groups
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS Security Group ID"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

# ECR
output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "ECR Repository Name"
  value       = aws_ecr_repository.app.name
}

# RDS
output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS Address (hostname)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS Port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS Database Name"
  value       = aws_db_instance.main.db_name
}

# ALB
output "alb_dns_name" {
  description = "Application Load Balancer DNS Name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}

output "alb_url" {
  description = "Application URL (HTTP)"
  value       = "http://${aws_lb.main.dns_name}"
}

# ECS
output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "ecs_service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.app.name
}

output "ecs_task_definition_family" {
  description = "ECS Task Definition Family"
  value       = aws_ecs_task_definition.app.family
}

# CloudWatch
output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.app.name
}

# IAM
output "ecs_task_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ECS Task Role ARN"
  value       = aws_iam_role.ecs_task.arn
}

# Summary
output "deployment_summary" {
  description = "Deployment Summary"
  value       = <<-EOT
  ========================================
  🚀 Deployment Information
  ========================================
  
  Environment: ${var.environment}
  Region:      ${var.aws_region}
  
  📦 Application:
     - URL:    http://${aws_lb.main.dns_name}
     - Health: http://${aws_lb.main.dns_name}/health
  
  🐳 Docker:
     - ECR:    ${aws_ecr_repository.app.repository_url}
  
  🗄️  Database:
     - Host:   ${aws_db_instance.main.address}
     - Port:   ${aws_db_instance.main.port}
     - Name:   ${aws_db_instance.main.db_name}
  
  📊 Monitoring:
     - Logs:   ${aws_cloudwatch_log_group.app.name}
  
  ========================================
  EOT
}
