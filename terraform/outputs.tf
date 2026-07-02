output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "bastion_public_ip" {
  description = "The public IP of the Bastion Host"
  value       = aws_eip.bastion.public_ip
}

output "bastion_private_ip" {
  description = "The private IP of the Bastion Host"
  value       = aws_instance.bastion.private_ip
}

output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer"
  value       = aws_lb.external.dns_name
}

output "efs_id" {
  description = "The ID of the Elastic File System"
  value       = aws_efs_file_system.shared_storage.id
}

output "monitoring_asg_name" {
  description = "The name of the Monitoring Auto Scaling Group"
  value       = aws_autoscaling_group.monitoring_asg.name
}
