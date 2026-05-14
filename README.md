# Innovatech Chile - EP2 DevOps Tres Capas

Proyecto preparado para la **Evaluación Parcial N°2**. Mantiene la arquitectura de tres capas de la EP1 y agrega contenedorización, ECR y pipeline CI/CD con GitHub Actions.

## Arquitectura

```text
Internet
   |
   v
EC2 Frontend pública - Docker Frontend/Nginx - puerto 80
   |
   v
EC2 Backend privada
   |-- Docker Proyectos Backend Spring Boot - puerto 8080 solo desde Frontend
   |-- Docker Avances Backend Spring Boot   - puerto 8081 solo desde Frontend
   |
   v
EC2 Data privada - Docker MySQL - puerto 3306 solo desde Backend
```

## Contenedores locales

```text
innovatech-frontend
innovatech-proyectos-backend
innovatech-avances-backend
innovatech-mysql
```

## Imágenes propias publicadas en ECR

```text
innovatech-ep2-frontend
innovatech-ep2-proyectos-backend
innovatech-ep2-avances-backend
```

MySQL usa la imagen oficial `mysql:8.0`, por eso no se publica en ECR.

## Qué incluye

- Flujo de ramas recomendado: `Develop`/`develop` -> `main` -> `deploy`.
- Dockerfile multi-stage para Frontend, Proyectos Backend y Avances Backend.
- Docker Compose local con cuatro servicios.
- Persistencia de datos mediante volumen Docker `innovatech_mysql_data`.
- Terraform con VPC, subnet pública, subnet privada, IGW, NAT Gateway, Security Groups, EC2, ECR y CloudWatch.
- Pipeline GitHub Actions: `build -> push ECR -> deploy EC2`.
- Despliegue por AWS Systems Manager hacia EC2 privadas sin abrir SSH público al backend ni a data.

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
http://localhost:3000/api/v1/ping/avances
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

El workflow se ejecuta con push a la rama `deploy`.

```powershell
git checkout deploy
git merge main
git push origin deploy
```

## 5. Validación para la defensa

Desde el navegador:

```text
http://IP_PUBLICA_FRONTEND
http://IP_PUBLICA_FRONTEND/api/v1/ping
http://IP_PUBLICA_FRONTEND/api/v1/ping/avances
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
docker logs innovatech-proyectos-backend
docker logs innovatech-avances-backend
docker logs innovatech-mysql
docker volume ls
```

## Justificación técnica rápida

La solución aplica DevOps porque separa el código de la infraestructura, usa Docker para empaquetar los servicios, Terraform para crear recursos de AWS de manera repetible, GitHub Actions para automatizar la entrega y ECR como registro de imágenes. La seguridad se controla mediante subredes y Security Groups: el Frontend es la única capa pública, los microservicios backend solo reciben tráfico desde Frontend y la base de datos solo recibe tráfico desde Backend.
