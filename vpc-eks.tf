module "eks-vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "~> 5.0"

    name = "EKS-VPC"
    cidr = "172.0.0.0/16"


    azs = ["us-east-1a","us-east-1b","us-east-1c"]
    private_subnets =  ["172.0.1.0/24","172.0.3.0/24","172.0.5.0/24"]
    public_subnets =  ["172.0.2.0/24","172.0.4.0/24","172.0.6.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = false  //  HA

    // one_nat_gateway_per_az = false # Explicitly tell the module to map all private subnets to the single NAT

    public_subnet_tags = {
        "kubernetes.io/role/elb"              = "1"
        "kubernetes.io/cluster/eks-cluster"   = "shared" # Added cluster discovery tag
    }

    private_subnet_tags = {
        "kubernetes.io/role/internal-elb"     = "1"
        "kubernetes.io/cluster/eks-cluster"   = "shared" # Added cluster discovery tag
    }


/*
      public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
*/
  tags = {
    Environment = "DEV"
  }
  
}


module "eks-cluster" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 21.0"

    name = var.cluster_name
    kubernetes_version = "1.33"

    //  generate module.eks-cluster.oidc_provider_arn
    enable_irsa        = true

    vpc_id = module.eks-vpc.vpc_id
    subnet_ids = module.eks-vpc.private_subnets

    // enable_cluster_creator_admin_permissions = false
    endpoint_public_access = true
    endpoint_private_access = true
 
    authentication_mode = "API"

    // user accessing kube cluster need to be defined first and its accessibilty for enable_cluster_creator_admin_permissions = false
    enable_cluster_creator_admin_permissions = true // make it false and create roles this is testing

    # HIPAA, or SOC2

    encryption_config = {
        resources        = ["secrets"]
        provider_key_arn = aws_kms_key.eks.arn 
    }
 

    eks_managed_node_groups = {
      # sys nodes (ON DEMAND)
      # sys pods nodeAffinity as system
        system_nodes = {
            name           = "prod-system-nodes"
            min_size       = 1 # HA 3 zone
            max_size       = 5
            desired_size   = 1 // make it 3

        
            instance_types = ["m6i.large"] # 2 vCPU, 8 GiB RAM
            capacity_type  = "ON_DEMAND"

            labels = {
                role = "system"
            }            
            taints = {
                dedicated ={
                key    = "dedicated"
                value  = "system_pods"
                effect = "NO_SCHEDULE"
                }
            }
        }

    # App nodes (SPOT svae money)
    # app pod should have toleration of taint and nodeAffinity (application)
        app_nodes = {
            name           = "prod-app-nodes"
            min_size       = 1   // make it 3
            max_size       = 10 
            desired_size   = 1   // make it 3

       
            instance_types = ["m6i.xlarge", "m6a.xlarge", "m5.xlarge"] 
            capacity_type  = "SPOT" 

            labels = {
                role = "application"
            }
        
        
            taints = {
                dedicated ={
                key    = "dedicated"
                value  = "application"
                effect = "NO_SCHEDULE"
                }
            }
        }
    }



    # -----------------------------------------------------------------
    # Map of attribute maps for all enabled EKS cluster addons
    # -----------------------------------------------------------------
    addons = {
        # 1. Networking Plugin
        vpc-cni = {
        most_recent                 = true
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"

        before_compute              = true 
        
        # Custom tuning: e.g., enabling prefix delegation for higher pod density
        configuration_values = jsonencode({
            env = {
            ENABLE_PREFIX_DELEGATION = "true"
            WARM_PREFIX_TARGET       = "1"
            }
        })
        }

        # 2. Cluster DNS Service
        coredns = {
        most_recent                 = true
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
        configuration_values = jsonencode(yamldecode(file("${path.module}/coredns-values.yaml")))
#        configuration_values = jsonencode(yamldecode(file("${path.module}/system_node_taint-values.yaml")))
        }

        # 3. Network Proxy
        kube-proxy = {
        most_recent                 = true
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
        }

        # 4. Storage Driver (Automates IAM / IRSA creation within the module) need permission because it will ask aws to create volumes in ec2
        aws-ebs-csi-driver = {
        most_recent                 = true
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
        configuration_values = jsonencode(yamldecode(file("${path.module}/ebs-csi-values.yaml")))
        service_account_role_arn    = module.ebs_csi_irsa_role.iam_role_arn  // from policy attach_ebs_csi_policy = true
#        configuration_values = jsonencode(yamldecode(file("${path.module}/system_node_taint-values.yaml")))
        # The module can dynamically create the required IAM role for the addon
        //attach_volume_node_to_cluster_policy = true
        }
    }

/*
    eks_managed_node_groups = {
    general_nodes = {
            min_size     = 1
            max_size     = 4
            desired_size = 2

            instance_types = ["t3.medium"]
            capacity_type  = "ON_DEMAND"
        }
    }
    tags = {
        Environment= "DEV"
    }
*/

// depends_on = [  ]

}

/*

// IAM role for eks cluster creation

resource "aws_iam_role" "cluster_create" {
    name = "eks_cluster_create"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"

        Statement = [{
        Effect = "Allow"
        Action = "sts:AssumeRole"       

        Principal = {
            Service = "eks.amazonaws.com"
        }
        }]
    })
  
}

resource "aws_iam_role_policy_attachment" "cluster_create_policy" {
    role = aws_iam_role.cluster_create.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}


*/