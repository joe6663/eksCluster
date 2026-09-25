resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secret encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "eks-secrets"
    Environment = "prod"
  }
}