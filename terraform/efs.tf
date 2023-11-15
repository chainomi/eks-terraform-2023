# Security group for EFS
resource "aws_security_group" "cluster_efs" {
  name        = "${local.cluster_name}-cluster efs security group"
  description = "Allow traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Cluster and all nodes to EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "TCP"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}


# Create EFS and mount targets
resource "aws_efs_file_system" "cluster_efs" {
  creation_token   = "eks-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
  tags             = local.tags
}

# EFS mount target
resource "aws_efs_mount_target" "cluster_efs" {

  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.cluster_efs.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.cluster_efs.id]
}
