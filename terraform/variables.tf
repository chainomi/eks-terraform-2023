variable "region" {
  description = "AWS region"
}

variable "application_name" {
  description = "Name of application e.g. DL Frame"
}

variable "environment" {
  description = "Name of environment e.g. dev, qa, prod"
}

variable "managed_node_group_name" {
  description = "Managed node group 1 name"
}

variable "managed_node_instance_types" {
  description = "Types of desired instance types for node groups"
}

variable "managed_node_capacity_type" {
  description = "Desired node capacity type for managed nodes e.g. SPOT or ON-DEMAND"
}

variable "managed_node_desired_size" {
  description = "Desired number of managed nodes"
}

variable "managed_node_max_size" {
  description = "Maximum number of managed nodes"

}

variable "managed_node_min_size" {
  description = "Minimum number of managed nodes"
}

variable "managed_node_disk_size" {
  description = "Disk size for managed node"
}


variable "vpc_cidr" {
  description = "CIDR for VPC network"
}

variable "private_subnet_cidrs" {
  description = "CIDR for private sub-network"
}

variable "public_subnet_cidrs" {
  description = "CIDR for public subnetwork"
}


variable "cert_manager_route53_hosted_zone_arns" {
    description = "Hosted zone ARN for Certificate Manager in EKS Cluster"
}

variable "service_list" {
  description = "List of services or applications run in the cluster, this is required to build ECR repos"
}

variable "ecr_image_mutability" {
    description = "Image tag mutability setting for ECR repositories"

}

variable "admin_access_role_arn" {
  description = "The ARN of an Admin role in AWS for cluster access"
}

variable "power_user_role_arn" {
  description = "The ARN of a power-user role in AWS for cluster access"
}

variable "read_access_role_arn" {
  description = "The ARN of a read only user role in AWS for cluster access"
}

variable "enable_jenkins" {
  description = "Use to enable or disable Jenkins controller resources deployed via Helm provider"
}

variable "jenkins_namespace" {
   description = "Name of the Namespace to deploy Jenkins controller resources in the EKS cluster" 
}

variable "jenkins_admin_user" {
  type        = string
  description = "Admin user of the Jenkins Application."
  default     = "admin"
}

variable "jenkins_efs_access_point_directory" {
    description = "The EFS directory to mount the Jenkins data folder"
}

variable "jenkins_secret_name" {
    description = "The name of the secret used to store Jenkins admin user login credential"
}

variable "jenkins_secret_key" {
    description = "The name of the key in the secret used to store Jenkins admin user password" 
}

variable "jenkins_domain_name" {
    description = "The domain name to assign to the Jenkins controller if host name and certificate are available"
}

variable "jenkins_alb_cert" {
    description = "The Jenkins controller load balancer certificate arn"
}

variable "backup_bucket_name" {
  description = "The name of the S3 bucket for backing up Jenkins controller data"
}

variable "backup_bucket_folder" {
  description = "The name of the folder in S3 bucket for backing up Jenkins controller data"
}

variable "backup_retention" {
  description = "The number of days to keep Jenkins backup data in the S3 bucket"
}

variable "cron_schedule" {
    description = "The schedule for the Kubernetes cronjob used in backing up Jenkins data"
  
}

variable "enable_jenkins_backup" {
  description = "This is used to enable or disable the S3 resources and cronjob for backing up Jenkins data"
}