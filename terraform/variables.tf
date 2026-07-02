variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
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

variable "key_name" {
  description = "Name of the EC2 Key Pair to associate with instances"
  type        = string
  default     = "monitoring-system-key"
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the Bastion Host"
  type        = string
  default     = "t3.micro"
}

variable "monitoring_instance_type" {
  description = "EC2 instance type for the Grafana/Prometheus/Loki servers"
  type        = string
  default     = "t3.medium"
}

variable "git_repo_url" {
  description = "Git repository URL containing the Ansible code (for bootstrapping)"
  type        = string
  default     = "https://github.com/example/one-click-infra.git" # User will replace this or override it in Jenkins parameters
}

variable "git_repo_branch" {
  description = "Git branch to check out for Ansible playbooks"
  type        = string
  default     = "main"
}
