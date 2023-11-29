# EKS Cluster with Jenkins
This repo contains code to deploy an EKS cluster and resources with Terraform and k8s resources via Terraform using the helm provider

Requirements
1. AWS CLI
2. Terraform
3. Kubectl

# AWS services used
1. EKS
2. EFS
3. S3
4. VPC
5. EC2
6. Route53
7. Secret manager

# Instructions

## Configure S3 backend(s)
1.  Create and S3 bucket with encryption and versioning enabled via AWS console
2.  Enter in the S3 bucket name in `terraform\backend\<env>.conf`
3.  Enter in the backend key and region in `terraform\backend.tf`

## Configure deploy parameters in tfvars file
1. Enter the name of the region, application name, service list for ecr's needed
2. Networking information, cert manager arn?
3. Enter role arn's for cluster access
4. Enter configurations for jenkins deploy

## Create secret for Jenkins admin user
1. Create a secret in AWS secret manager e.g. `jenkins_password` with a key e.g. `password` and value set to the desired password. Add the secret name and secret key in `terraform\env\<env>.tfvars`

## Configure Jenkins with domain name and ssl
 The default ingress on the helm chart for jenkins has been disabled and replaced with terraform managed ingress resources (via kubernetes manifest files in `jenkins.tf`). The ssl enabled ingress manifest allows through a domain and the ssl disabled manifest and access through a load balancer

 1. Enable SSL (for access through domain)  by setting the `jenkins_enable_ssl` variable to `true`
 2. Disable SSL (for access through load balancer) by setting the `jenkins_enable_ssl` variable to `false`


## Deploy EKS cluster, Networking, ECR and Jenkins (if enabled)
1. `cd terraform/`
2. `terraform init -backend-config="./backend/<env>.conf"`
3. `terraform plan -var-file=env/<env>.tfvars`
4. `terraform apply -var-file=env/<env>.tfvars --auto-approve`


## Access cluster
1. AWS CLI - with kubectl installed, and from terraform folder run command to authenticate with cluster and add credentials to kube config file - `aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)`
2. Run `kubectl get all` to confirm access
