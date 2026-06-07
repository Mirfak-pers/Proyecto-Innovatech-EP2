variable "aws_region" {
  description = "Region AWS del laboratorio"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base para recursos AWS y ECR"
  type        = string
  default     = "innovatech-ep3"
}

variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "innovatech-cluster"
}
