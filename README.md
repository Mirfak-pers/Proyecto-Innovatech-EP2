

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


## Despliegue paso a paso

### 1. Clonar el repositorio

```powershell
git clone https://github.com/Mirfak-pers/Proyecto-Innovatech-EP2.git
cd Proyecto-Innovatech-EP2
```

### 2. Obtener credenciales AWS Academy

Entra a **AWS Academy → Start Lab**, espera el círculo verde, luego ve a **AWS Details → Show**.

Copia las tres credenciales y ejecútalas en PowerShell:

```powershell
aws configure set aws_access_key_id     TU_KEY
aws configure set aws_secret_access_key TU_SECRET
aws configure set aws_session_token     TU_TOKEN
aws configure set default.region        us-east-1
```

Verifica la identidad:

```powershell
aws sts get-caller-identity
```

### 3. Levantar infraestructura con Terraform

```powershell
cd infra\ep3_eks
terraform init
terraform apply -auto-approve
```

Espera **10–15 minutos** hasta que Terraform termine. Esto provisiona la VPC, subredes, NAT Gateway, node group y cluster EKS.

### 4. Conectar kubectl al cluster

```powershell
aws eks update-kubeconfig --region us-east-1 --name innovatech-cluster
kubectl get nodes
```

Espera a ver el nodo en estado `Ready` antes de continuar.

### 5. Actualizar GitHub Secrets

Ve a tu repo → **Settings → Secrets and variables → Actions** y actualiza estos tres secrets con las credenciales nuevas de AWS Academy:

| Secret | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID` | Tu key actual |
| `AWS_SECRET_ACCESS_KEY` | Tu secret actual |
| `AWS_SESSION_TOKEN` | Tu token actual |

### 6. Disparar el pipeline

```powershell
cd ..\..
git commit --allow-empty -m "ci: trigger EP3 deploy pipeline"
git push origin deploy
```

### 7. Verificar el pipeline

Abre: `https://github.com/Mirfak-pers/Proyecto-Innovatech-EP2/actions`

Confirma que todos los pasos del workflow **EP3 - Build, Push ECR y Deploy EKS** aparezcan en verde.

### 8. Verificar el cluster

```powershell
kubectl get pods
kubectl get services
kubectl get hpa
```

Todos los pods deben estar en `Running`. La URL pública del frontend aparece en la columna `EXTERNAL-IP` del service `frontend`.

---

## Evidencias EP3

### 1 · Cluster EKS activo

```powershell
aws eks describe-cluster `
  --region us-east-1 `
  --name innovatech-cluster `
  --query "cluster.{Nombre:name,Estado:status,Version:version,VPC:resourcesVpcConfig.vpcId}" `
  --output table

aws eks describe-nodegroup `
  --region us-east-1 `
  --cluster-name innovatech-cluster `
  --nodegroup-name innovatech-ep3-workers `
  --query "nodegroup.{Nombre:nodegroupName,Estado:status,Instancias:instanceTypes,Min:scalingConfig.minSize,Desired:scalingConfig.desiredSize,Max:scalingConfig.maxSize}" `
  --output table

kubectl get nodes -o wide
```

**Resultado esperado:** cluster `ACTIVE`, node group `ACTIVE`, 1 nodo en `Ready`.

---

### 2 · Red: VPC, subredes y Security Groups

```powershell
$VPC_ID = aws eks describe-cluster --region us-east-1 --name innovatech-cluster `
  --query "cluster.resourcesVpcConfig.vpcId" --output text

aws ec2 describe-subnets `
  --region us-east-1 `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "Subnets[].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,PublicIP:MapPublicIpOnLaunch,Nombre:Tags[?Key=='Name']|[0].Value}" `
  --output table

aws ec2 describe-security-groups `
  --region us-east-1 `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "SecurityGroups[].{Nombre:GroupName,ID:GroupId,Descripcion:Description}" `
  --output table
```

**Resultado esperado:** subredes públicas con `PublicIP=True`, privadas con `PublicIP=False`, Security Groups del cluster EKS visibles.

---

### 3 · Servicios desplegados

```powershell
kubectl get pods -o wide
kubectl get deployments
```

**Resultado esperado:** `mysql 1/1`, `backend-ventas 2/2`, `backend-despachos 2/2`, `frontend 1/1` — todos en `Running`.

---

### 4 · URL pública del frontend (Load Balancer)

```powershell
kubectl get services
kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Prueba en navegador:

```
http://URL_DEL_LOAD_BALANCER
http://URL_DEL_LOAD_BALANCER/api/v1/ventas
http://URL_DEL_LOAD_BALANCER/api/v1/despachos
```

**Resultado esperado:** `frontend` tipo `LoadBalancer` con hostname público; `backend-ventas`, `backend-despachos` y `mysql` tipo `ClusterIP`; endpoints responden JSON o `[]`.

---

### 5 · Autoscaling HPA

Primero instala metrics-server para que el HPA pueda leer el uso de CPU:

```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Espera unos 30–60 segundos y verifica que esté corriendo:

```powershell
kubectl get deployment metrics-server -n kube-system
```

Ahora consulta el HPA:

```powershell
kubectl get hpa
```

**Resultado esperado:** `hpa-backend-ventas` y `hpa-backend-despachos` con `min=2`, `max=5`, `target=50% CPU` y un valor de CPU real (ya no `<unknown>`).

---

### 6 · Auto-recuperación (self-healing)

Borra los pods de `backend-ventas` y observa cómo Kubernetes los recrea:

```powershell
kubectl delete pod -l app=backend-ventas
kubectl get pods -w
```

Cuando la columna `STATUS` vuelva a `Running`, presiona `Ctrl+C` y valida:

```powershell
kubectl get pods
kubectl get deployments
```

**Resultado esperado:** Kubernetes recrea los pods automáticamente y el deployment vuelve a `2/2`.
<img width="1801" height="1282" alt="Innovatech_EP3_EKS drawio (2)" src="https://github.com/user-attachments/assets/a021883d-8e3a-469b-88e7-6f1c9db2baa6" />
