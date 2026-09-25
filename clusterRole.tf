
// access entry for cluster dev user to assume role for eks cluster access

resource "aws_iam_user" "dev_user" {
  name = "dev_user"
  
}


resource "aws_iam_role" "dev_user_role" {
  name = "dev_user_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.dev_user.arn
        }
      },
    ]
  })
}
/*
resource "aws_iam_user_policy" "dev_user_policy" {
  name = "allow-assume-developer-role"
  user = aws_iam_user.dev_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.dev_user_role.arn
      }
    ]
  })
}
*/
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

