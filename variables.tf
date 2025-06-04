variable "aws_region" {
  description = "A região da AWS onde os recursos serão criados."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "fiap-tc-lambda"
}

variable sg_eks_id {
  description = "ID do Security Group do EKS"
  type        = string
  default     = "sg-03f836b2047886ae0"
}

variable "regionDefault" {
  default = "us-east-1"
}

variable "projectName" {
  default = "tc-fiap"
}

variable "labRole" {
  default = "arn:aws:iam::062491649647:role/LabRole"
}

variable "accessConfig" {
  default = "API_AND_CONFIG_MAP"
}

variable "nodeGroup" {
  default = "fiap"
}

variable "instanceType" {
  default = "t3.medium"
}

variable "principalArn" {
  default = "arn:aws:iam::062491649647:role/voclabs"
}

variable "policyArn" {
  default = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}