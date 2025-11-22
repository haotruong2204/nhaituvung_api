variable "project_name" {
  description = "Project name"
  type        = string
  default     = "nhaituvung"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "prod-demo"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS Profile"
  type        = string
  default     = "nhaituvung"
}

# VPC - Multi-AZ for production
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

# RDS - Can stop/start (Single-AZ optimized)
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small" # Bigger for production feel
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "nhaituvung_production"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS (disable to allow stop/start)"
  type        = bool
  default     = false # Set false to allow stop/start
}

# ElastiCache Redis
variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.small" # Production-grade
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis nodes"
  type        = number
  default     = 1 # Single node to save cost
}

# ECS - Auto Scaling capable
variable "ecs_task_cpu" {
  description = "ECS Task CPU"
  type        = string
  default     = "512" # Production-grade
}

variable "ecs_task_memory" {
  description = "ECS Task Memory"
  type        = string
  default     = "1024" # Production-grade
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks (set to 0 to stop)"
  type        = number
  default     = 2 # Production: 2 tasks for HA
}

variable "ecs_min_count" {
  description = "Minimum number of ECS tasks for auto scaling"
  type        = number
  default     = 1
}

variable "ecs_max_count" {
  description = "Maximum number of ECS tasks for auto scaling"
  type        = number
  default     = 4
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3000
}

variable "secret_key_base" {
  description = "Rails secret key base"
  type        = string
  sensitive   = true
}

# ALB Health Check
variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/up"
}

# Enable/Disable features
variable "enable_auto_scaling" {
  description = "Enable ECS Auto Scaling"
  type        = bool
  default     = true
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights"
  type        = bool
  default     = false # Disable to save cost
}

# Domain Configuration
variable "domain_name" {
  description = "Root domain name (e.g., nhaituvung.com)"
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain for API (e.g., api)"
  type        = string
  default     = "api"
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
  default     = ""
}

variable "enable_https" {
  description = "Enable HTTPS with ACM certificate"
  type        = bool
  default     = true
}
