# ============================================================
# Innovatech Chile - EP3 DevOps
# Orquestación con AWS EKS (Elastic Kubernetes Service)
# Incluye: VPC, subnets públicas en 2 AZ, IGW, EKS cluster,
#          Node Group (autoscaling), ECR x3, CloudWatch Logs.
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------
# Data sources
# ------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# AWS Academy entrega el rol LabRole con los permisos necesarios.
data "aws_iam_role" "labrole" {
  name = "LabRole"
}

# ------------------------------------------------------------
# VPC y subredes (2 AZ obligatorio para EKS)
# ------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
    Stage   = "EP3"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-public-a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    Project                                     = var.project_name
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-public-b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    Project                                     = var.project_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------
# Security Group para los nodos EKS
# ------------------------------------------------------------

resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-sg"
  description = "Trafico entre nodos EKS y plano de control"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Todo el trafico interno entre nodos"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "NodePort para LoadBalancer services (frontend)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-eks-nodes-sg"
    Project = var.project_name
  }
}

# ------------------------------------------------------------
# EKS Cluster
# ------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.labrole.arn

  vpc_config {
    subnet_ids              = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_group_ids      = [aws_security_group.eks_nodes.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  tags = {
    Name    = var.cluster_name
    Project = var.project_name
    Stage   = "EP3"
  }
}

# ------------------------------------------------------------
# EKS Node Group (con autoscaling para HPA)
# ------------------------------------------------------------

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-workers"
  node_role_arn   = data.aws_iam_role.labrole.arn

  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  # t3.medium es el mínimo recomendado para correr Spring Boot en K8s
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 4
  }

  # Permite rolling updates sin downtime
  update_config {
    max_unavailable = 1
  }

  tags = {
    Name    = "${var.project_name}-workers"
    Project = var.project_name
    Stage   = "EP3"
  }

  depends_on = [aws_eks_cluster.main]
}

# ------------------------------------------------------------
# ECR - Repositorios de imágenes Docker
# ------------------------------------------------------------

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-frontend"
    Project = var.project_name
    Stage   = "EP3"
  }
}

resource "aws_ecr_repository" "ventas_backend" {
  name                 = "${var.project_name}-ventas-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-ventas-backend"
    Project = var.project_name
    Stage   = "EP3"
    Service = "Ventas"
  }
}

resource "aws_ecr_repository" "despachos_backend" {
  name                 = "${var.project_name}-despachos-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-despachos-backend"
    Project = var.project_name
    Stage   = "EP3"
    Service = "Despachos"
  }
}

# ------------------------------------------------------------
# CloudWatch Log Groups (logs del cluster y aplicaciones)
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Project = var.project_name
    Stage   = "EP3"
  }
}

resource "aws_cloudwatch_log_group" "app_frontend" {
  name              = "/${var.project_name}/frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_ventas" {
  name              = "/${var.project_name}/ventas-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_despachos" {
  name              = "/${var.project_name}/despachos-backend"
  retention_in_days = 7
}
