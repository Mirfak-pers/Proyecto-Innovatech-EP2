# Innovatech EP3 - EKS, ECR y GitHub Actions

Proyecto adaptado al enunciado del profesor usando la estructura original:

```text
back-Ventas_SpringBoot/Springboot-API-REST
back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
front_despacho
infra/ep3_eks
infra/k8s
.github/workflows/deploy.yml
```

## Arquitectura

- **Frontend:** React/Vite (`front_despacho`) servido con Nginx no-root.
- **Backend Ventas:** Spring Boot en puerto `8080`, endpoint `/api/v1/ventas`.
- **Backend Despachos:** Spring Boot en puerto `8081`, endpoint `/api/v1/despachos`.
- **Base de datos:** MySQL 8.0 como `ClusterIP` interno.
- **Orquestación:** AWS EKS con nodos EC2.
- **Imágenes:** Amazon ECR, etiquetadas con `${{ github.sha }}` desde GitHub Actions.
- **Exposición pública:** Service `frontend` tipo `LoadBalancer`.
- **Autoscaling:** HPA para `backend-ventas` y `backend-despachos` al 50% CPU.

## Secrets requeridos en GitHub Actions

Crear en `Settings → Secrets and variables → Actions`:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
MYSQL_ROOT_PASSWORD
MYSQL_DATABASE
```

Ejemplo para MySQL:

```text
MYSQL_ROOT_PASSWORD = admin12345
MYSQL_DATABASE = innovatech_db
```

Sin comillas.

## Despliegue

1. Crear infraestructura:

```powershell
cd infra/ep3_eks
terraform init
terraform apply -auto-approve
```

2. Conectar kubectl:

```powershell
aws eks update-kubeconfig --region us-east-1 --name innovatech-cluster
kubectl get nodes
```

3. Ejecutar pipeline:

```powershell
git checkout deploy
git add .
git commit -m "feat: adaptar ventas despachos a eks"
git push origin deploy
```

## Validación

```powershell
kubectl get pods -o wide
kubectl get services
kubectl get hpa
kubectl logs deployment/backend-ventas
kubectl logs deployment/backend-despachos
kubectl logs deployment/mysql
```

URL pública:

```powershell
kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Endpoints esperados:

```text
http://URL_DEL_BALANCEADOR/api/v1/ventas
http://URL_DEL_BALANCEADOR/api/v1/despachos
```
