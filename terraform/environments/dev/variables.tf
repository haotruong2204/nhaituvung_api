variable "project_name" {
  description = "Project name"
  type        = string
  default     = "nhaituvung"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "staging"
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

# VPC - Simple 1 AZ
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone" {
  description = "Single AZ for dev"
  type        = string
  default     = "ap-southeast-1a"
}

# RDS
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "nhaituvung_staging"
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

# ECS - Minimal
variable "ecs_task_cpu" {
  description = "ECS Task CPU"
  type        = string
  default     = "256" # Minimum
}

variable "ecs_task_memory" {
  description = "ECS Task Memory"
  type        = string
  default     = "512" # Minimum
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
