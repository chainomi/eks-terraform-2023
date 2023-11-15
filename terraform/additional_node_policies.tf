
# Use to add additional permissions to nodes 
resource "aws_iam_policy" "additional_node_policy" {
  name        = "eks-${var.application_name}-${var.environment}-additional-node-policy"
  path        = "/"
  description = "additional policy for managed node group"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [

                "s3:*",
                "sts:AssumeRoleWithWebIdentity",
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets",
                "route53:ListTagsForResource",
                "route53:ChangeResourceRecordSets",
                "elasticfilesystem:DescribeMountTargets",
                "elasticfilesystem:DescribeFileSystems",
                "elasticfilesystem:DescribeAccessPoints",
                "elasticfilesystem:CreateAccessPoint",
                "elasticfilesystem:DeleteAccessPoint",
                "ec2:DescribeAvailabilityZones",
                "ssm:CancelCommand",
                "ssm:GetCommandInvocation",
                "ssm:ListCommandInvocations",
                "ssm:ListCommands",
                "ssm:SendCommand",
                "ssm:GetAutomationExecution",
                "ssm:GetParameters",
                "ssm:StartAutomationExecution",
                "ssm:StopAutomationExecution",
                "ssm:ListTagsForResource",
                "ssm:GetCalendarState"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}