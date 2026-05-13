# Innovatech Chile - EP2 DevOps Tres Capas

Proyecto preparado para la **Evaluación Parcial N°2**. Esta versión une la entrega EP1 con la EP2: mantiene la arquitectura de tres capas en AWS y agrega contenedorización, ECR y pipeline CI/CD.

## Arquitectura

```text
Internet
   |
   v
EC2 Frontend publica - Docker Frontend/Nginx - puerto 80
   |
   v
EC2 Backend privada - Docker Backend Spring Boot - puerto 8080 solo desde Frontend
   |
   v
EC2 Data privada - Docker MySQL - puerto 3306 solo desde Backend
```

## Qué incluye

- Git y GitHub con rama `deploy` como disparador.
- Dockerfile multi-stage para Frontend y Backend.
- Docker Compose local para pruebas.
- Terraform basado en la parte 1: VPC, subnet pública, subnet privada, IGW, NAT Gateway, Security Groups, EC2, ECR y CloudWatch.
- Pipeline GitHub Actions: `build -> push ECR -> deploy EC2`.
- Despliegue con AWS Systems Manager, para actualizar también las instancias privadas sin abrirlas a Internet.
- Persistencia de datos con volumen Docker `innovatech_mysql_data` en la instancia Data.

## 1. Prueba local

```powershell
copy .env.example .env
docker compose up --build -d
docker compose ps
```

Abrir:

```text
http://localhost:3000
http://localhost:3000/api/v1/ping
```

## 2. Crear infraestructura AWS

```powershell
cd infra\ep2_tres_capas
copy terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

El output entrega los datos que debes copiar en GitHub Secrets.

## 3. Secrets necesarios en GitHub Actions

En GitHub: `Settings -> Secrets and variables -> Actions -> New repository secret`.

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
AWS_REGION
FRONTEND_INSTANCE_ID
BACKEND_INSTANCE_ID
DATA_INSTANCE_ID
BACKEND_PRIVATE_IP
DATA_PRIVATE_IP
MYSQL_DATABASE
MYSQL_ROOT_PASSWORD
```

Valores recomendados:

```text
AWS_REGION=us-east-1
MYSQL_DATABASE=innovatech_db
MYSQL_ROOT_PASSWORD=elige_una_clave_segura
```

## 4. Ejecutar pipeline

```powershell
git checkout -b deploy
git add .
git commit -m "EP2 despliegue tres capas con ECR y SSM"
git push -u origin deploy
```

Cada nuevo push a `deploy` ejecuta el flujo completo.

## 5. Validación para la defensa

Desde el navegador:

```text
http://IP_PUBLICA_FRONTEND
http://IP_PUBLICA_FRONTEND/api/v1/ping
```

Desde AWS Systems Manager puedes entrar a cada instancia:

```powershell
aws ssm start-session --target ID_FRONTEND
aws ssm start-session --target ID_BACKEND
aws ssm start-session --target ID_DATA
```

Comandos útiles dentro de las EC2:

```bash
docker ps
docker logs innovatech-frontend
docker logs innovatech-backend
docker logs innovatech-mysql
docker volume ls
```

## Explicación técnica rápida

La solución aplica DevOps porque separa el código de la infraestructura, usa Docker para empaquetar los servicios, Terraform para crear recursos de AWS de manera repetible, GitHub Actions para automatizar la entrega y ECR como registro de imágenes. La seguridad se controla mediante subredes y security groups: el Frontend es la única capa pública, el Backend solo recibe tráfico desde Frontend y la base de datos solo recibe tráfico desde Backend.
