# Retrieving AWS account ID for ECR push command
data "aws_caller_identity" "current" {}

# Create ECR
resource "aws_ecr_repository" "ecr" {
  for_each             = toset(var.service_list)
  name                 = each.key
  image_tag_mutability = var.ecr_image_mutability

  tags = local.tags
}


