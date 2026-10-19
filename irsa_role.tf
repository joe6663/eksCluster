
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "eks-ebs-csi-driver-role"

  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks-cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "aws_loadbalacer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "eks-aws-loadbalancer-controller-role"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks-cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-loadbalancer-controller"]
    }
  }

}