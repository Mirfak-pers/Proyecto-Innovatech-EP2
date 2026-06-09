output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint del plano de control EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "frontend_ecr_url" {
  description = "URL del repositorio ECR del Frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ventas_backend_ecr_url" {
  description = "URL del repositorio ECR del Backend Ventas"
  value       = aws_ecr_repository.ventas_backend.repository_url
}

output "despachos_backend_ecr_url" {
  description = "URL del repositorio ECR del Backend Despachos"
  value       = aws_ecr_repository.despachos_backend.repository_url
}

output "kubeconfig_command" {
  description = "Comando para conectar kubectl al cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "github_secrets_to_create" {
  description = "Secrets necesarios en GitHub Actions"
  value       = <<-EOT
  Crear estos secrets en GitHub → Settings → Secrets and variables → Actions:

  AWS_ACCESS_KEY_ID     → desde AWS Academy
  AWS_SECRET_ACCESS_KEY → desde AWS Academy
  AWS_SESSION_TOKEN     → desde AWS Academy
  MYSQL_ROOT_PASSWORD   → contraseña segura para MySQL
  MYSQL_DATABASE        → innovatech_db
  EOT
}
