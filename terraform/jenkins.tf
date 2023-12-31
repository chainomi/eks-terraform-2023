# Helm chart for Jenkins

locals {
  jenkins_password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["password"]
}
resource "helm_release" "jenkins" {
  count = var.enable_jenkins ? 1 : 0

  name       = "jenkins"
  version    = "4.8.2"
  namespace  = var.jenkins_namespace
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"

  create_namespace = true

  values = [templatefile("../jenkins-helm/values.yaml",
    {
      admin_user     = var.jenkins_admin_user
      admin_password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["${var.jenkins_secret_key}"]

      #s3 backup parameters
      enable_backup = var.enable_jenkins_backup
      bucket_path   = "${var.backup_bucket_name}/${var.backup_bucket_folder}"
      cron_schedule = var.cron_schedule

  })]

  depends_on = [module.eks_blueprints_addons, kubectl_manifest.efs_persistent_claim]
}

# Secret manager - retrieve jenkins admin password

data "aws_secretsmanager_secret" "jenkins" {
  name = var.jenkins_secret_name
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.jenkins.id
}


# EFS resources for jenkins

resource "aws_efs_access_point" "jenkins_efs_access_point" {
  count          = var.enable_jenkins ? 1 : 0
  file_system_id = aws_efs_file_system.cluster_efs.id
  tags = {
    Name = "Jenkins EFS access point"
  }
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = var.jenkins_efs_access_point_directory
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = 777
    }
  }
}

# Create persistent volume on EFS

resource "kubectl_manifest" "namespace" {
  count     = var.enable_jenkins ? 1 : 0
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${var.jenkins_namespace}
YAML

}
resource "kubectl_manifest" "efs_persistent_volume" {
  count     = var.enable_jenkins ? 1 : 0
  yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: ${aws_efs_file_system.cluster_efs.id}::${aws_efs_access_point.jenkins_efs_access_point[count.index].id}

---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${aws_efs_file_system.cluster_efs.id}
  directoryPerms: "777"
YAML

  depends_on = [aws_efs_access_point.jenkins_efs_access_point, module.eks_blueprints_addons]
}

resource "kubectl_manifest" "efs_persistent_claim" {
  count      = var.enable_jenkins ? 1 : 0
  yaml_body  = <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-efs
  namespace: ${var.jenkins_namespace}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 100Gi
YAML
  depends_on = [kubectl_manifest.namespace, kubectl_manifest.efs_persistent_volume]
}


#S3 backup storage

resource "aws_s3_bucket" "jenkins_backup" {
  count  = var.enable_jenkins && var.enable_jenkins_backup ? 1 : 0
  bucket = var.backup_bucket_name

  tags = local.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_quarterly" {
  count  = var.enable_jenkins && var.enable_jenkins_backup ? 1 : 0
  bucket = aws_s3_bucket.jenkins_backup[count.index].id

  rule {
    id = "data_retention"

    expiration {
      days = var.backup_retention
    }


    filter {
      prefix = "${var.backup_bucket_folder}/"
    }

    status = "Enabled"
  }

}

# Get Jenkins ALB DNS address

data "kubernetes_ingress_v1" "this" {
  count     = var.enable_jenkins ? 1 : 0 
  metadata {
    name      = "jenkins"
    namespace = var.jenkins_namespace
  }
  depends_on = [
    helm_release.jenkins, kubectl_manifest.jenkins_ingress_no_ssl
  ]
}


resource "kubectl_manifest" "jenkins_ingress_no_ssl" {
  count     = var.enable_jenkins && var.jenkins_enable_ssl == false ? 1 : 0
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins
  namespace: ${var.jenkins_namespace} 
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/load-balancer-name: jenkins-alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/healthcheck-path: /login
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/success-codes: 200,302
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'    
  name: jenkins
             
spec:
  rules:
  - host: 
    http: 
      paths:    
      - path: /
        backend:
          service:
            name: jenkins
            port:
              number: 8080
        pathType: Prefix
YAML

  depends_on = [ helm_release.jenkins ]
}

resource "kubectl_manifest" "jenkins_ingress_ssl" {
  count     = var.enable_jenkins && var.jenkins_enable_ssl ? 1 : 0
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins
  namespace: ${var.jenkins_namespace} 
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/load-balancer-name: jenkins-alb-ssl
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    alb.ingress.kubernetes.io/certificate-arn: ${var.jenkins_alb_cert}
    alb.ingress.kubernetes.io/healthcheck-path: /login
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/success-codes: 200,302
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'    
  name: jenkins-ssl
             
spec:
  rules:
  - host: ${var.jenkins_domain_name}
    http: 
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ssl-redirect
            port:
              name: use-annotation               
      - path: /
        backend:
          service:
            name: jenkins
            port:
              number: 8080
        pathType: Prefix
YAML

  depends_on = [ helm_release.jenkins ]
}