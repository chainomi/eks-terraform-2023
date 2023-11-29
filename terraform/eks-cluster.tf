locals {
  cluster_name = "${var.environment}-${var.application_name}"
  tags = {
    environment = var.environment
  }
}

# Create EKS cluster 
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.27"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets


  # EKS Managed Node Group(s)
  # Note - a security group is automatically created for the node group with rules limiting traffic between the node and other cluster resources
  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    # Use below to add additional sg's as to all managed node groups e.g. efs
    vpc_security_group_ids = [aws_security_group.cluster_efs.id]
    iam_role_additional_policies = {
      additional = aws_iam_policy.additional_node_policy.arn
    }
  }



  eks_managed_node_groups = {
    "${var.managed_node_group_name}" = {
      min_size     = var.managed_node_min_size
      max_size     = var.managed_node_max_size
      desired_size = var.managed_node_desired_size
      disk_size    = var.managed_node_disk_size

      instance_types = var.managed_node_instance_types
      capacity_type  = var.managed_node_capacity_type

      labels = {
        name = "${var.managed_node_group_name}"

      }

      tags = local.tags
    }
  }

  fargate_profiles = {
    default = {
      name = "fargate-deploy" #turn to var
      selectors = [
        {
          namespace = "fargate-jenkins" #turn to var
        }

      ]

      tags = local.tags

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = var.read_access_role_arn
      username = "reader"
      groups   = ["reader"]
    },
    {
      rolearn  = var.power_user_role_arn
      username = "power-user"
      groups   = ["admin"]
    }, 
    {
      rolearn  = var.admin_access_role_arn
      username = "admin-1"
      groups   = ["system:masters"]
    }      
  
  ]

  aws_auth_users = []

}


module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.11.0" 

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }

  }


  enable_aws_efs_csi_driver              = true
  enable_argocd                          = false
  enable_argo_rollouts                   = false
  enable_argo_workflows                  = false
  enable_aws_cloudwatch_metrics          = true
  enable_aws_load_balancer_controller    = true
  enable_cluster_autoscaler              = true
  enable_cluster_proportional_autoscaler = false
  enable_karpenter                       = false
  enable_kube_prometheus_stack           = true
  enable_metrics_server                  = true
  enable_cert_manager                    = true
  cert_manager_route53_hosted_zone_arns  = var.cert_manager_route53_hosted_zone_arns

  tags = local.tags

  depends_on = [module.eks]
}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${local.cluster_name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}


# This module updates the Route 53 record for the ingress domain with the proper alb dns address 

module "external_dns" {
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-external-dns.git"

  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  cluster_name                     = module.eks.cluster_name
  helm_chart_version               = "6.14.4"

  settings = {
    "policy"     = "sync"                                              # Modify how DNS records are sychronized between sources and providers.
    "txtOwnerId" = "${var.environment}-${var.application_name}-domain" #unique identifier for each external DNS instance
  }
# Helm chart repo - https://artifacthub.io/packages/helm/bitnami/external-dns
# Module repo - https://github.com/DNXLabs/terraform-aws-eks-external-dns

}

