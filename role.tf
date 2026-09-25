


resource "aws_iam_user" "dev_namespaced_users" {
  for_each = var.aws_namespaced_user_name
  name = "aws_namespaced_user_name_${each.key}"
  
}

resource "aws_iam_user_policy" "dev_namespaced_users_policy" {
  for_each = var.aws_namespaced_user_name
  name = "allow-assume-dev-namespaced-user-${each.key}-policy"
  user = aws_iam_user.dev_namespaced_users[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.dev_namespaced_role.arn
      },
      // describe cluster to generate kubeconfig file
      {
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = module.eks-cluster.cluster_arn
      }     
    ]

  })
}


resource "aws_iam_role" "dev_namespaced_role" {
  name = "dev_namespaced_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [                                       // allow multiple users to assume the role
            for user in aws_iam_user.dev_namespaced_users :
            user.arn
          ] 
        }
      },
    ]
  })
  
}


