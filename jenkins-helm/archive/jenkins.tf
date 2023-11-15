# Helm chart for Jenkins

locals {
   jenkins_password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["password"]
}
resource "helm_release" "jenkins" {
  count = var.enable_jenkins ? 1 : 0  
  
  name       = "jenkins"
  version    = "4.8.2" 
  namespace   = var.jenkins_namespace
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"

  create_namespace = true

  values = [
    "${file("../jenkins-helm/values.yaml")}"
  ]

  set_sensitive {
    name  = "controller.adminUser"
    value = var.jenkins_admin_user
  }

  set_sensitive {
    name  = "controller.adminPassword"
    value = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["password"]
  }


  depends_on = [ aws_efs_access_point.jenkins_efs_access_point, kubectl_manifest.efs_persistent_claim ]
}

# Secret manager 

data "aws_secretsmanager_secret" "jenkins" {
  arn = var.jenkins_secret_arn
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.jenkins.id
}




# EFS resources for jenkins

resource "aws_efs_access_point" "jenkins_efs_access_point" {
#   count = var.enable_jenkins ? 1 : 0  
  file_system_id = aws_efs_file_system.cluster_efs.id
  tags = {
    Name = "Jenkins EFS access point"
  }
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory  {
    path          = var.jenkins_efs_access_point_directory
    creation_info  {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = 777
    }
  }
}

# Create persistent volume on EFS

resource "kubectl_manifest" "namespace" {
    count = var.enable_jenkins ? 1 : 0
    yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${var.jenkins_namespace}
YAML

}
resource "kubectl_manifest" "efs_persistent_volume" {
    count = var.enable_jenkins ? 1 : 0
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
    volumeHandle: ${aws_efs_file_system.cluster_efs.id}::${aws_efs_access_point.jenkins_efs_access_point.id}

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

}

resource "kubectl_manifest" "efs_persistent_claim" {
    count = var.enable_jenkins ? 1 : 0
    yaml_body = <<YAML
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
 depends_on = [ kubectl_manifest.namespace  ]
}