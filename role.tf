
// role for namespaced users to assume role for eks cluster access

resource "aws_iam_role" "dev_namespaced_role" {
  name = "dev_namespaced_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [ // allow multiple users to assume the role
            for user in aws_iam_user.dev_namespaced_users :
            user.arn
          ]
        }
      },
    ]
  })

}

// role for cluster dev user to assume role for eks cluster access

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

