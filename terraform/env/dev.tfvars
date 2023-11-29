#General 
region = "us-west-1"
environment ="dev"
application_name = "jenkins"
service_list = ["flask-api", "jenkins-images"]
ecr_image_mutability = "MUTABLE"

# AWS managed nodes configuration
managed_node_group_name     = "jenkins-node-group-1"
managed_node_instance_types = ["t2.medium", "t3.medium"]
managed_node_capacity_type  = "SPOT" #choose between "SPOT" and "ON-DEMAND"
managed_node_desired_size   = 2
managed_node_max_size       = 5
managed_node_min_size       = 2
managed_node_disk_size      = 50

# Networking
vpc_cidr = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

#cert manager
cert_manager_route53_hosted_zone_arns = [""]

# Cluster access
admin_access_role_arn = ""
power_user_role_arn = ""
read_access_role_arn = ""

# Jenkins - General
enable_jenkins = true
jenkins_namespace = "jenkins"
jenkins_secret_name = "jenkins_password"
jenkins_secret_key = "password"
jenkins_efs_access_point_directory = "/jenkins"
jenkins_admin_user = "admin"

# Jenkins - DNS
jenkins_enable_ssl = false
jenkins_domain_name = ""
jenkins_alb_cert = ""

# Jenkins - backup
backup_bucket_name = "jenkins-test-chai-2023"
backup_bucket_folder = "backup"
backup_retention = 90
cron_schedule = "0 2 * * *"
enable_jenkins_backup = false