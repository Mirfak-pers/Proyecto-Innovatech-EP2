Innovatech Chile — EP2 DevOps
Infraestructura de 3 capas desplegada en AWS con Terraform, contenedorizada con Docker y automatizada mediante GitHub Actions.

📋 Descripción
El proyecto dockeriza y despliega tres servicios en AWS:

Frontend: React + Vite servido por Nginx como reverse proxy, expuesto públicamente en el puerto 80.
Backend Proyectos: microservicio Spring Boot en el puerto 8080, subred privada.
Backend Avances: microservicio Spring Boot en el puerto 8081, subred privada.
Base de datos: MySQL 8.0 en EC2 dedicada con persistencia mediante named volume.

Un push a la rama deploy construye las imágenes, las publica en Amazon ECR y las despliega automáticamente en las EC2 vía AWS SSM.

🗂️ Estructura del proyecto
Proyecto-Innovatech-EP2/
├── frontend/
│   ├── Dockerfile                  # Multi-stage: Node build + nginx-unprivileged runtime
│   ├── nginx/default.conf.template # Reverse proxy hacia los backends
│   └── src/
├── backend-proyectos/
│   ├── Dockerfile                  # Multi-stage: Maven build + JRE runtime, usuario no-root
│   └── src/
├── backend-avances/
│   ├── Dockerfile                  # Multi-stage: Maven build + JRE runtime, usuario no-root
│   └── src/
├── deploy/                         # Composes de producción (uno por capa EC2)
│   ├── frontend-compose.yml
│   ├── backend-compose.yml
│   └── data-compose.yml
├── infra/ep2_tres_capas/
│   ├── main.tf                     # VPC, subredes, SGs, EC2s, ECR, CloudWatch
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── .github/workflows/deploy.yml    # Pipeline CI/CD completo
├── docker-compose.yml              # Stack local para desarrollo
├── .env.example
└── README.md

🚀 Requisitos previos

Terraform CLI >= 1.5.0
AWS CLI configurado con credenciales activas
Docker Desktop instalado y en ejecución
Key Pair creado en AWS con el nombre ep2-devops-key
Provider AWS >= 5.0


⚙️ Flujo de uso
1. Levantar infraestructura AWS
bashcd infra/ep2_tres_capas
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
terraform output
2. Configurar GitHub Secrets
Con los valores del terraform output, crear los siguientes secrets en GitHub → Settings → Secrets and variables → Actions:
SecretDescripciónAWS_ACCESS_KEY_IDCredencial AWS AcademyAWS_SECRET_ACCESS_KEYCredencial AWS AcademyAWS_SESSION_TOKENToken de sesión AWS AcademyAWS_REGIONus-east-1FRONTEND_INSTANCE_IDID de la instancia frontendBACKEND_INSTANCE_IDID de la instancia backendDATA_INSTANCE_IDID de la instancia dataBACKEND_PRIVATE_IPIP privada del backend (ej. 10.0.2.X)DATA_PRIVATE_IPIP privada de la instancia dataMYSQL_DATABASEinnovatech_dbMYSQL_ROOT_PASSWORDContraseña segura para MySQL

⚠️ BACKEND_PRIVATE_IP debe ser la IP privada (ej. 10.0.2.15), no el ID de instancia.

3. Probar localmente
bashcp .env.example .env
docker compose up --build
Acceder a http://localhost:3000. Para detener: docker compose down
4. Desplegar a producción
bashgit checkout deploy
git merge main
git push origin deploy
El pipeline se activa automáticamente y despliega las 3 imágenes en AWS.

📌 Principios DevOps aplicados

Infraestructura como código: toda la infraestructura AWS se define en Terraform y es reproducible con un solo comando.
Contenedorización: cada servicio corre en su propio contenedor con dependencias aisladas, con multi-stage build y usuario no-root.
CI/CD automatizado: push a deploy desencadena el ciclo completo build → push ECR → deploy SSM sin intervención manual.
Persistencia declarativa: named volume para MySQL, independiente del ciclo de vida del contenedor.
Mínimo privilegio: contenedores sin root, Security Groups encadenados por capa, secrets en variables de entorno.
