
// namespaced users policy

resource "aws_iam_user_policy" "dev_namespaced_users_policy" {
  for_each = var.aws_namespaced_user_name
  name     = "allow-assume-dev-namespaced-user-${each.key}-policy"
  user     = aws_iam_user.dev_namespaced_users[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.dev_namespaced_role.arn
      },
      // describe cluster to generate kubeconfig file
      // only with this user can access cluster
      {
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = module.eks-cluster.cluster_arn
      }
    ]

  })
}

// Cluster user policy

resource "aws_iam_user_policy" "dev_user_policy" {
  name = "allow-assume-and-describe-cluster"
  user = aws_iam_user.dev_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      #  allowing the user to assume the role
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.dev_user_role.arn
      },
      # user to find the cluster to generate their kubeconfig file
      {
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = module.eks-cluster.cluster_arn
      }
    ]
  })
}