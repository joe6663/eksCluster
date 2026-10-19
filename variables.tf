variable "aws_region_2" {
  type        = string
  description = "region"
  default     = "us-east-1"
}

/*
variable "aws_access_key_2"{}

variable "aws_secret_key_2"{}
*/
/*

variable "aws_access_key_joe_dev"{}

variable "aws_secret_key_joe_dev"{}

*/

variable "aws_access_key_2" {}

variable "aws_secret_key_2" {}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "eks-cluster"
}


variable "kubernetes_role_rules" {
  description = "kubernetes RBAC rules"
  type = list(object({
    apiGroups = list(string)
    resources = list(string)
    verbs     = list(string)
  }))

}


variable "aws_namespaced_user_name" {
  description = "AWS IAM user name for namespaced access"
  type        = set(string)
}