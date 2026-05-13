# Comandos EP2 tres capas

## Local

```powershell
copy .env.example .env
docker compose up --build -d
docker compose ps
```

## Terraform

```powershell
cd infra\ep2_tres_capas
copy terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

## GitHub

```powershell
git init
git add .
git commit -m "Proyecto EP2 DevOps tres capas"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/TU-REPO.git
git push -u origin main
git checkout -b deploy
git push -u origin deploy
```

## Verificar EC2 con SSM

```powershell
aws ssm start-session --target ID_FRONTEND
aws ssm start-session --target ID_BACKEND
aws ssm start-session --target ID_DATA
```

Dentro de cada EC2:

```bash
docker ps
docker compose ps
docker volume ls
docker logs innovatech-frontend
docker logs innovatech-backend
docker logs innovatech-mysql
```

## Destruir infraestructura al terminar

```powershell
cd infra\ep2_tres_capas
terraform destroy
```
