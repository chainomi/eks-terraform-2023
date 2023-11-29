
output "aws_account_id" {
  description = "Account ID for environment"
  value       = data.aws_caller_identity.current.id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_primary_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_primary_security_group_id
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.aws_auth_configmap_yaml
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.cluster_name
}

output "oidc_arn" {
  description = "Kubernetes OIDC arn"
  value       = module.eks.oidc_provider_arn
}

output "oidc_issuer_url" {
  description = "Kubernetes OIDC url"
  value       = module.eks.cluster_oidc_issuer_url
}

output "node_security_group_id" {
  description = "node group security group id"
  value       = module.eks.node_security_group_id
}

output "ecr_repo_url_map" {
  description = "List of ECR repo's created"
  value       = values(aws_ecr_repository.ecr)[*].repository_url
}

output "access_point_id" {
  description = "EFS access point id"
  value       = var.enable_jenkins ? aws_efs_access_point.jenkins_efs_access_point[0].id : null
}

output "jenkins_alb_dns" {
  description = "Jenkins ALB DNS name"
  value       = var.enable_jenkins && var.jenkins_enable_ssl == false ? "http://${data.kubernetes_ingress_v1.this[0].status.0.load_balancer.0.ingress.0.hostname}" : null

}

output "jenkins_domain" {
  description = "Jenkins domain name address"
  value       = var.enable_jenkins && var.jenkins_enable_ssl ? "https://${var.jenkins_domain_name}" : null
}