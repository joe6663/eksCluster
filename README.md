1 **Architecture Overview**

<img width="1024" height="559" alt="eks-cluster" src="https://github.com/user-attachments/assets/2089f4c2-b111-49f0-a0d1-a3cd68b3f3fe" />


2. **Key Components**
   
2.1 Networking (VPC)
   
    • Region & AZs: AWS Region us-east-1 spanning 3 Availability Zones (us-east-1a, us-east-1b, us-east-1c).
   
    • Subnet Strategy: Public subnets (tagged 'kubernetes.io/role/elb = 1') and private subnets (tagged 'kubernetes.io/role/internal-elb = 1') across all three AZs.
   
    • NAT Gateways: Multi-AZ NAT Gateways deployed in public subnets ensure highly available and fault-tolerant outbound connectivity for private worker nodes.
   
2.2 EKS Managed Node Groups

    • System Node Group (prod-system-nodes): Configured with capacityType = ON_DEMAND.
    
    •  Dedicated taint: 'dedicated=system:NoSchedule'.
    
    •  Allocated workloads: Core cluster add-ons (coredns, vpc-cni, kube-proxy, aws-load-balancer-controller) and the ArgoCD control stack (argocd-server, argocd-repo-server, argocd-redis).
    
    • Application Node Group (prod-app-nodes): Configured with capacityType = SPOT for aggressive cost optimization.
    
    •  Dedicated taint: 'role=application:NoExecute' (or 'dedicated=application:NoSchedule').
    
    •  Allocated workloads: Multi-tier microservices (app-frontend-v1, app-backend-v1) tolerating the application taint.
2.3 Add-ons & Controllers

    • AWS Load Balancer Controller (LBC): Automatically provisions and configures Application Load Balancers (ALBs) and Network Load Balancers (NLBs) via Kubernetes Ingress/Service objects.
    
    • ArgoCD: Deployed via Helm provider to manage declarative GitOps continuous delivery pipelines.
    
    • Native EKS Add-ons: Managed AWS add-ons for vpc-cni, coredns, kube-proxy, and aws-ebs-csi-driver.
    
2.4 Granular RBAC Mapping

    • DevOps Team: Bound to ClusterRole: dev with cluster-wide permissions to list pods, nodes, and cluster-level resources.
    
    • App Developers: Bound to Role: variable-access scoped strictly to the 'app-ns' namespace with permissions to read/list Secrets and ConfigMaps

4. **Deployment Instructions**
   
Step 1: Remote State Setup

Ensure your remote state S3 bucket and DynamoDB/Lockfile settings are configured in backend.tf:
terraform {
  backend "s3" {
    bucket       = "your-terraform-state-bucket"
    key          = "eks-cluster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # Native S3 locking (Terraform 1.10+) or dynamodb_table for earlier versions
  }
}

Step 2: Initialize and Apply

Run the Terraform lifecycle commands from the project root directory:

**initialize providers and modules**

Run the terraform code https://github.com/joe6663/terraform-execution-role.git to create user, role and policy which will be used to create the cluster

terraform init

**Review execution plan**

terraform plan

**Apply infrastructure changes**

terraform apply

Step 3: Configure kubectl Access

Update your local kubeconfig to assume the Terraform deployment role:

 **Authenticate using the deployment role**

aws eks update-kubeconfig \
  --name eks-cluster \
  --region us-east-1 \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/dev-terraform-execution-role

**Verify node connectivity across both node groups**

kubectl get nodes -L eks.amazonaws.com/capacityType,role

4. **Deploying Workloads to Dedicated Nodes**
   
4.1 Scheduling onto System Nodes

System nodes enforce the taint dedicated=system:NoSchedule. Pods scheduled here must define matching affinity and toleration blocks:
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: role
              operator: In
              values:
                - system
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "system"
    effect: "NoSchedule"

4.2 Scheduling onto Application Nodes

Application nodes enforce the taint role=application:NoExecute (or NoSchedule) and capacityType=SPOT:
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: role
              operator: In
              values:
                - application
tolerations:
  - key: "role"
    operator: "Equal"
    value: "application"
    effect: "NoExecute"

5. **Verifying RBAC Permissions**
   
Verify authorization boundaries across personas using the kubectl auth can-i command:

**Check developer permissions in app-ns (Expected: yes)**

kubectl auth can-i get secrets -n app-ns --as=arn:aws:iam::<ACCOUNT_ID>:role/dev_user_role

**Check developer permissions outside scope (Expected: no)**

kubectl auth can-i list pods -n app-ns --as=arn:aws:iam::<ACCOUNT_ID>:role/dev_user_role

**Check DevOps permissions for cluster-wide node access (Expected: yes)**

kubectl auth can-i list nodes --as=arn:aws:iam::<ACCOUNT_ID>:role/dev_namespaced_role


6. Clean-Up & Teardown
   
Important Teardown Sequence: Always remove in-cluster Ingresses and LoadBalancer Services before running terraform destroy. If active ALBs hold VPC subnets or security groups, AWS will reject the subnet and VPC deletion calls.


**1. Delete all deployed Ingresses and LoadBalancer services**

kubectl delete ingress -A --all
kubectl delete svc -A --field-selector spec.type=LoadBalancer

**2. Scale node groups to 0 (prevents Auto Scaling race conditions during teardown)**

aws eks update-nodegroup-config --cluster-name eks-cluster --nodegroup-name <SYSTEM_NODEGROUP_NAME> --scaling-config minSize=0,maxSize=1,desiredSize=0
aws eks update-nodegroup-config --cluster-name eks-cluster --nodegroup-name <APP_NODEGROUP_NAME> --scaling-config minSize=0,maxSize=1,desiredSize=0

**3. Destroy infrastructure via Terraform**

terraform destroy







     
