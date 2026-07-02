# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name        = "monitoring-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = aws_vpc.main.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from internet"
  }

  # Web App (Nginx) Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Nginx Web App HTTP from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-bastion-sg"
  }
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "monitoring-alb-sg"
  description = "Security group for public ALB"
  vpc_id      = aws_vpc.main.id

  # Grafana Dashboard Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for Grafana UI"
  }

  # Loki API port (for Promtail logs)
  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Loki push endpoint from internal VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-alb-sg"
  }
}

# Security Group for Private EC2 Instances (ASG)
resource "aws_security_group" "private_instances" {
  name        = "monitoring-private-sg"
  description = "Security group for private autoscaled monitoring servers"
  vpc_id      = aws_vpc.main.id

  # SSH from Bastion Host
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from Bastion"
  }

  # Grafana UI from ALB
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Grafana port from ALB"
  }

  # Loki port from ALB (for Promtail log pushes)
  ingress {
    from_port       = 3100
    to_port         = 3100
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Loki API from ALB"
  }

  # Prometheus direct port (optional - for troubleshooting/querying from ALB)
  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Prometheus UI/API from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-private-sg"
  }
}

# Security Group for EFS Shared File System
resource "aws_security_group" "efs" {
  name        = "monitoring-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  # NFS port from Private Instances only
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.private_instances.id]
    description     = "NFS traffic from monitoring instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-efs-sg"
  }
}

# Separate security group rules to break the circular dependency cycle:
# bastion -> private_instances -> alb -> bastion
resource "aws_security_group_rule" "bastion_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion.id
  source_security_group_id = aws_security_group.private_instances.id
  description              = "Allow Prometheus scraping of Node Exporter"
}

resource "aws_security_group_rule" "bastion_nginx_exporter" {
  type                     = "ingress"
  from_port                = 9113
  to_port                  = 9113
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion.id
  source_security_group_id = aws_security_group.private_instances.id
  description              = "Allow Prometheus scraping of Nginx Exporter"
}

resource "aws_security_group_rule" "alb_loki_from_bastion_public" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 3100
  to_port           = 3100
  protocol          = "tcp"
  cidr_blocks       = ["${aws_eip.bastion.public_ip}/32"]
  description       = "Allow Loki push from Bastion public EIP"
}
