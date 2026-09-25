resource "helm_release" "argocd" {
  name = "argocd"
  chart = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version = "7.8.2"
  namespace        = "argocd"
  create_namespace = true
  values = [
    file("${path.module}/argocd-values.yaml")
  ]
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"
  

  values = [
    jsonencode({
      clusterName = module.eks-cluster.cluster_name
      // replicaCount = 3  // HA
      vpcId = module.eks-vpc.vpc_id
      serviceAccount = {
        create = true
        name   = "aws-loadbalancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.aws_loadbalacer_controller_irsa_role.iam_role_arn
        }
      }

      nodeSelector = {
        role = "system"
      }

      tolerations = [
        {
          key      = "dedicated"
          operator = "Equal"
          value    = "system_pods"
          effect   = "NoSchedule"
        }
      ]
    })
  ]

  depends_on = [module.eks-cluster]
}
