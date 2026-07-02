# EFS File System
resource "aws_efs_file_system" "shared_storage" {
  creation_token = "monitoring-efs"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "monitoring-efs"
  }
}

# EFS Mount Targets in Private Subnets (Availability Zones)
resource "aws_efs_mount_target" "target" {
  count           = length(var.private_subnet_cidrs)
  file_system_id  = aws_efs_file_system.shared_storage.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
