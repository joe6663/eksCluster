

// namespaced role access for dev user to assume role for eks cluster access

resource "aws_eks_access_entry" "dev_namespaced_role_access" {
  cluster_name = module.eks-cluster.cluster_name
  principal_arn = aws_iam_role.dev_namespaced_role.arn
  type = "STANDARD"
  kubernetes_groups = [
    "dev_user_group"
  ]
}



// cluster entry for dev user to assume role for eks cluster access

resource "aws_eks_access_entry" "eks_access_entry_dev_users" {
  cluster_name = module.eks-cluster.cluster_name
  principal_arn = aws_iam_role.dev_user_role.arn
  type = "STANDARD"
}

// aws predefined policy for eks cluster access for dev user to assume role for eks cluster access

resource "aws_eks_access_policy_association" "eks_access_entry_dev_users_association" {
  cluster_name = module.eks-cluster.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn = aws_eks_access_entry.eks_access_entry_dev_users.principal_arn
  
    access_scope {
    type = "cluster"
  }
}