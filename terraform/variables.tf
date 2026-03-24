variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "devops-demo"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

# --- VPC ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# --- ECS ---

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS worker nodes"
  type        = string
  default     = "t2.micro"
}

variable "ecs_min_instances" {
  description = "Minimum number of ECS EC2 instances"
  type        = number
  default     = 2
}

variable "ecs_max_instances" {
  description = "Maximum number of ECS EC2 instances"
  type        = number
  default     = 4
}

variable "ecs_desired_instances" {
  description = "Desired number of ECS EC2 instances"
  type        = number
  default     = 2
}

variable "app_desired_count" {
  description = "Desired number of application containers"
  type        = number
  default     = 2
}

variable "app_version" {
  description = "Application version tag"
  type        = string
  default     = "v1.0"
}

variable "app_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

# --- RDS ---

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "devops_demo"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# --- DNS (Cloudflare) ---

variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit permissions"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Root domain name managed by Cloudflare"
  type        = string
  default     = "lathiya.com"
}

variable "subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "demo"
}
