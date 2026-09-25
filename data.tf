data "aws_caller_identity" "current" {}

output "oidc_provider_arn"{
    value = module.eks-cluster.oidc_provider_arn
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
  depends_on = [module.eks-cluster]
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
  depends_on = [module.eks-cluster]
}

output "cluster_token" {
  sensitive = true  
  value = data.aws_eks_cluster_auth.this.token
}
