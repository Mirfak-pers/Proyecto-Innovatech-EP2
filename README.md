# Innovatech Chile – EP3: Orquestación con AWS EKS

## Descripción

Continuación del EP2. La infraestructura de 3 capas en EC2 fue migrada a **AWS EKS (Elastic Kubernetes Service)**, logrando orquestación automática, autoscaling y despliegue continuo desde GitHub.

### Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Orquestación | AWS EKS (Kubernetes 1.29) |
| Imágenes | Amazon ECR |
| Infraestructura | Terraform |
| CI/CD | GitHub Actions |
| Frontend | React + Vite + nginx |
| Backend Proyectos | Spring Boot 3 (puerto 8080) |
| Backend Avances | Spring Boot 3 (puerto 8081) |
| Base de datos | MySQL 8.0 en pod K8s |
| Logs | kubectl logs + CloudWatch |

---

## Arquitectura

```
Internet
    │
    ▼
AWS Load Balancer (creado automáticamente por EKS)
    │  puerto 80
    ▼
┌─────────────────────────────────────────────┐
│           EKS Cluster (VPC 10.0.0.0/16)     │
│                                             │
│  Pod: frontend (nginx)                      │
│    │  proxy /api/v1/proyectos → :8080       │
│    │  proxy /api/v1/avances   → :8081       │
│    ▼                                        │
│  Pod: backend-proyectos x2 (:8080)          │
│  Pod: backend-avances   x2 (:8081)          │
│    │                                        │
│    ▼                                        │
│  Pod: mysql (:3306)  [PVC 5Gi]              │
└─────────────────────────────────────────────┘
```

### Flujo CI/CD

```
Push a rama deploy
       │
       ▼
GitHub Actions
       │
       ├─ Build imágenes Docker (linux/amd64)
       ├─ Push a Amazon ECR (tag = SHA del commit)
       ├─ kubectl apply -f infra/k8s/
       ├─ kubectl set image (actualiza cada Deployment)
       └─ kubectl rollout status (espera que todos los pods levanten)
```

---

## Estructura del proyecto

```
Proyecto-Innovatech-EP3/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← Pipeline CI/CD
├── backend-proyectos/
│   ├── Dockerfile
│   └── src/
├── backend-avances/
│   ├── Dockerfile
│   └── src/
├── frontend/
│   ├── Dockerfile
│   ├── nginx/default.conf.template
│   └── src/
├── infra/
│   ├── ep3_eks/
│   │   ├── main.tf             ← EKS, ECR, VPC, CloudWatch
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── k8s/
│       ├── mysql.yml           ← MySQL + PVC + ClusterIP Service
│       ├── mysql-secret.yml    ← Referencia (valores reales en GitHub Secrets)
│       ├── backend-proyectos.yml
│       ├── backend-avances.yml
│       ├── frontend.yml        ← LoadBalancer Service (URL pública)
│       └── hpa-backends.yml    ← HPA: escala entre 2-5 réplicas al 50% CPU
├── docker-compose.yml          ← Desarrollo local
└── README.md
```

---

## Requisitos previos

- Cuenta AWS Academy activa (laboratorio con LabRole disponible)
- Terraform CLI >= 1.5.0
- AWS CLI configurado (`aws configure`)
- kubectl instalado
- Docker Desktop
- Git

---

## Uso con Terraform (levantar infraestructura)

```bash
cd infra/ep3_eks

terraform init
terraform validate
terraform plan
terraform apply
```

Al terminar, ejecutar el comando de kubeconfig que aparece en los outputs:

```bash
aws eks update-kubeconfig --region us-east-1 --name innovatech-cluster
```

Verificar conexión:

```bash
kubectl get nodes
```

> **Nota:** El cluster EKS tarda aproximadamente 10-15 minutos en estar listo.

---

## GitHub Secrets requeridos

Ir a **Settings → Secrets and variables → Actions** en el repositorio y crear:

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Credencial AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS Academy |
| `AWS_SESSION_TOKEN` | Token de sesión AWS Academy |
| `MYSQL_ROOT_PASSWORD` | Contraseña segura para MySQL |
| `MYSQL_DATABASE` | Nombre de la BD (ej: `innovatech_db`) |

---

## Despliegue

El pipeline se activa automáticamente al hacer push a la rama `deploy`:

```bash
git add .
git commit -m "feat: migración a EKS EP3"
git push origin deploy
```

Para ver el progreso en tiempo real:

```bash
# Pods levantando
kubectl get pods -w

# Logs de un pod específico
kubectl logs -f deployment/backend-proyectos

# URL pública del frontend
kubectl get service frontend
```

---

## Desarrollo local

```bash
docker compose up --build
```

Servicios locales:

| Servicio | URL |
|----------|-----|
| Frontend | http://localhost:3000 |
| Backend Proyectos | http://localhost:8080 |
| Backend Avances | http://localhost:8081 |
| MySQL | localhost:3306 |

---

## Autoscaling (HPA)

El HPA escala los backends automáticamente entre **2 y 5 réplicas** cuando la CPU supera el **50%**.

```bash
# Ver estado del autoscaler
kubectl get hpa

# Descripción detallada
kubectl describe hpa hpa-backend-proyectos
kubectl describe hpa hpa-backend-avances
```

Para simular carga y observar el HPA en acción:

```bash
# Abrir terminal con un pod de carga
kubectl run -it --rm load-test --image=busybox --restart=Never -- /bin/sh

# Dentro del pod, hacer requests al backend
while true; do wget -q -O- http://backend-proyectos:8080/actuator/health; done
```

---

## Logs y métricas

```bash
# Logs en tiempo real por servicio
kubectl logs -f deployment/frontend
kubectl logs -f deployment/backend-proyectos
kubectl logs -f deployment/backend-avances
kubectl logs -f deployment/mysql

# Ver eventos del cluster (útil para debug)
kubectl get events --sort-by='.lastTimestamp'

# Métricas de uso de recursos
kubectl top pods
kubectl top nodes
```

---

## Comandos útiles para la defensa

```bash
# Ver todos los recursos desplegados
kubectl get all

# Ver pods con nodo asignado
kubectl get pods -o wide

# Describir un deployment
kubectl describe deployment backend-proyectos

# Ver el Service del frontend con su URL pública
kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Reiniciar un deployment (simular redeploy)
kubectl rollout restart deployment/backend-proyectos

# Ver historial de rollouts
kubectl rollout history deployment/backend-proyectos
```

---

## Secrets en Kubernetes

Los secrets de MySQL **nunca** están hardcodeados en los manifiestos. El pipeline los inyecta en el cluster usando:

```bash
kubectl create secret generic mysql-secret \
  --from-literal=MYSQL_ROOT_PASSWORD=... \
  --from-literal=MYSQL_DATABASE=...     \
  --dry-run=client -o yaml | kubectl apply -f -
```

Los pods los consumen como variables de entorno a través de `secretKeyRef`, sin que el valor quede expuesto en el código.

---

## Limpieza de recursos

Para no gastar créditos AWS Academy cuando no se usa:

```bash
# Eliminar deployments (mantiene el cluster)
kubectl delete -f infra/k8s/

# Eliminar toda la infraestructura
cd infra/ep3_eks
terraform destroy
```

---

## Diferencias respecto al EP2

| Aspecto | EP2 (EC2 + Docker Compose) | EP3 (EKS + Kubernetes) |
|---------|--------------------------|------------------------|
| Orquestación | Manual (SSM + docker compose up) | Kubernetes automático |
| Autoscaling | No | HPA (CPU 50%, 2-5 réplicas) |
| Alta disponibilidad | No (1 instancia por capa) | Sí (múltiples pods en 2 AZ) |
| Recuperación ante fallos | Manual | Automática (K8s reinicia pods) |
| Deploy | SSM RunCommand | kubectl set image |
| Logs | docker logs en EC2 | kubectl logs + CloudWatch |
| Secrets | Variables en SSM scripts | Kubernetes Secrets |
