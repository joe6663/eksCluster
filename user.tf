
// namespaced users environment

resource "aws_iam_user" "dev_namespaced_users" {
  for_each = var.aws_namespaced_user_name
  name     = "aws_namespaced_user_name_${each.key}"

}

// cluster user

resource "aws_iam_user" "dev_user" {
  name = "dev_user"

}