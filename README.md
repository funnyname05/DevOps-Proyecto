# Proyecto DevOps

Aplicación web que permite visualizar las ventas de una tienda, gestionar sus despachos y transformar una venta en un despacho con datos de envío.

## Arquitectura

El sistema se compone de **3 instancias EC2 en AWS**, cada una ejecutando contenedores Docker:

- **Frontend:** React + Vite. Actúa como proxy inverso hacia los backends.
- **Backend Ventas:** Spring Boot, gestiona las ventas de la tienda.
- **Backend Despachos:** Spring Boot, gestiona los despachos generados.
- **Base de datos:** MySQL con dos bases de datos separadas (`db_ventas` y `db_despachos`).

Las imágenes Docker se almacenan en **Amazon ECR** y el despliegue se automatiza con **GitHub Actions** usando **AWS SSM** para ejecutar comandos en las instancias.

---

## Requisitos previos

- Repositorios creados en Amazon ECR:
  - `proyecto-db`
  - `front-despacho`
  - `back-despacho`
  - `back-ventas`
- AWS SSM Agent activo en las 3 instancias
- Repositorio GitHub con Actions habilitado

---

## Configuración de Secrets en GitHub

En **Settings → Secrets and variables → Actions** agregar los siguientes secrets:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
AWS_REGION
ECR_REGISTRY
ECR_REPO_URL_DB
ECR_REPO_URL_FRONTEND
ECR_REPO_URL_BACKEND_DESPACHO
ECR_REPO_URL_BACKEND_VENTAS
EC2_DB_INSTANCE_ID
EC2_FRONTEND_INSTANCE_ID
EC2_BACKEND_INSTANCE_ID
```

---

## Configuración de Security Groups

| Instancia | Puerto | Origen |
|---|---|---|
| Frontend | 80 | 0.0.0.0/0 |
| Backend | 8080 | SG del Frontend |
| Backend | 8081 | SG del Frontend |
| DB | 3306 | SG del Backend |

---

## Configuración de las instancias EC2

Antes del primer despliegue, crear el archivo `.env` en cada instancia via **AWS SSM**.

### Instancia DB

```bash
cat > /home/ec2-user/.env << 'EOF'
AWS_REGION=<REGION>
ECR_REGISTRY=<ID_CUENTA>.dkr.ecr.us-east-1.amazonaws.com
ECR_REPO_URL_DB=<ID_CUENTA>.dkr.ecr.us-east-1.amazonaws.com/proyecto-db
DB_ROOT_PASSWORD=<password_seguro>
EOF
chmod 600 /home/ec2-user/.env
```

### Instancia Backend

```bash
cat > /home/ec2-user/.env << 'EOF'
AWS_REGION=<REGION>
ECR_REGISTRY=<ID_CUENTA>.dkr.ecr.us-east-1.amazonaws.com
ECR_REPO_URL_BACKEND_DESPACHO=<ID_CUENTA>.dkr.ecr.us-east-1.amazonaws.com/back-despacho
ECR_REPO_URL_BACKEND_VENTAS=<ID_CUENTA>.dkr.ecr.us-east-1.amazonaws.com/back-ventas
DB_ENDPOINT=<IP_PRIVADA_INSTANCIA_DB>
DB_PORT=3306
DB_NAME_DESPACHOS=db_despachos
DB_USER_DESPACHOS=user_despachos
DB_PASSWORD_DESPACHOS=<password_despachos>
DB_NAME_VENTAS=db_ventas
DB_USER_VENTAS=user_ventas
DB_PASSWORD_VENTAS=<password_ventas>
EOF
chmod 600 /home/ec2-user/.env
```

### Instancia Frontend

```bash
cat > /home/ec2-user/.env << 'EOF'
AWS_REGION=<REGION>
ECR_REGISTRY=<ID_CUENTA>.dkr.ecr.us-east-1.amazonaws.com
ECR_REPO_URL_FRONTEND=<ID_CUENTA>.dkr.ecr.us-east-1.amazonaws.com/front-despacho
EOF
chmod 600 /home/ec2-user/.env
```

---

## Despliegue

El despliegue es automático al hacer push a `main` en las rutas correspondientes:

| Cambio en | Workflow que se dispara |
|---|---|
| `db/**` | CI/CD Proyecto DB |
| `front_despacho/**` | CI/CD Frontend |
| `back-Despachos_SpringBoot/**` | CI/CD Backend Despacho |
| `back-Ventas_SpringBoot/**` | CI/CD Backend Ventas |

---

## Auto-arranque al reiniciar instancias

Para que los contenedores se levanten automáticamente al reiniciar cada EC2, configurar el servicio systemd **una sola vez** en cada instancia via SSM:

```bash
sudo bash -c 'cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=Docker Compose App
After=network.target docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ec2-user
EnvironmentFile=/home/ec2-user/.env
ExecStart=/bin/bash -c "source /home/ec2-user/.env && aws ecr get-login-password --region \$AWS_REGION | docker login --username AWS --password-stdin \$ECR_REGISTRY && docker compose up -d"
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable app.service
```
