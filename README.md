# Proyecto DevOps

Aplicación web que permite visualizar las ventas de una tienda, gestionar sus despachos y transformar una venta en un despacho con datos de envío.

---

## Arquitectura

El sistema se despliega en **Amazon EKS** con los siguientes componentes:

```
Internet
    │
    ▼
Application Load Balancer (internet-facing)
    │
    ▼
EKS Cluster (proyecto-despachos-eks)
    ├── Pod: front-despacho x2  (Nginx + React, puerto 80)
    ├── Pod: back-ventas x2     (Spring Boot, puerto 8080)
    ├── Pod: back-despacho x2   (Spring Boot, puerto 8081)
    └── Pod: proyecto-db x1     (MySQL 8, puerto 3306)
```

- **Frontend:** React + Vite servido con Nginx. Actúa como proxy inverso hacia los backends.
- **Backend Ventas:** Spring Boot, gestiona las ventas de la tienda en `db_ventas`.
- **Backend Despachos:** Spring Boot, gestiona los despachos en `db_despachos`.
- **Base de datos:** MySQL 8, con dos bases de datos separadas.

---

## Configuración del Clúster EKS

### Especificaciones del clúster

| Parámetro | Valor |
|---|---|
| Nombre | proyecto-despachos-eks |
| Versión Kubernetes | 1.30 |
| Región | us-east-1 |
| Rol IAM | LabEksClusterRole |

### Add-ons instalados
```
Amazon VPC CNI
Metrics Server
Amazon CloudWatch Observability
```

---

## Configuración de los Nodos

### Node Group

| Parámetro | Valor |
|---|---|
| Nombre | proyecto-nodes |
| Rol IAM | LabEksNodeRole |
| Tipo de instancia | t3.medium |
| AMI | Amazon Linux 2 |
| Mínimo de nodos | 2 |
| Máximo de nodos | 4 |
| Nodos deseados | 2 |
| Subnets | Públicas (us-east-1a, us-east-1b) |

---

## Horizontal Pod Autoscaler (HPA)

### Configuración

| Deployment | CPU umbral | Mínimo | Máximo |
|---|---|---|---|
| front-despacho | 50% | 2 | 5 |
| back-ventas | 50% | 2 | 5 |
| back-despacho | 50% | 2 | 5 |

### Justificación del umbral de 50% CPU

Se eligió el **50% de CPU** como umbral de escalado por:

- **Eficiencia de recursos:** evita escalar prematuramente con cargas bajas transitorias.
- **Tiempo de respuesta:** al escalar antes de saturar el CPU (100%), los nuevos pods están listos antes de que el servicio se degrade.

---

## Balanceo de Carga

### Application Load Balancer

El frontend expone un servicio de tipo `LoadBalancer` que AWS convierte automáticamente en un ALB:

```yaml
type: LoadBalancer
annotations:
  service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```

---

## Networking y Seguridad

### VPC
```
CIDR: 10.0.0.0/20
├── Subnet pública 1a  → nodos EKS, LoadBalancer
├── Subnet pública 1b  → nodos EKS, LoadBalancer
├── Subnet privada 1a  → recursos internos
└── Subnet privada 1b  → recursos internos
```

### Tags de subnets para EKS
```
Subnets públicas:
  kubernetes.io/role/elb: 1
  kubernetes.io/cluster/proyecto-despachos-eks: shared

Subnets privadas:
  kubernetes.io/role/internal-elb: 1
```

### Gestión de Secretos

Los datos sensibles se gestionan con **Kubernetes Secrets**, nunca expuestos en GitHub:

```bash
# Secret de base de datos
kubectl create secret generic db-secrets \
  --from-literal=DB_ROOT_PASSWORD=<password> \
  --from-literal=DB_PASSWORD_VENTAS=<password> \
  --from-literal=DB_PASSWORD_DESPACHOS=<password> \
  -n proyecto

# Secret para acceso a ECR
kubectl create secret docker-registry ecr-secret \
  --docker-server=<ID>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password) \
  -n proyecto
```

---

## Pipeline CI/CD

El pipeline se ejecuta automáticamente al hacer push a la rama **deploy**:

```
Push a rama Deploy
        │
        ▼
GitHub Actions
        ├── Checkout código
        ├── Configurar credenciales AWS
        ├── Login en ECR
        ├── Build imagen Docker
        ├── Push a ECR con tag :SHA del commit
        ├── Desplegar via SSM (Docker/EC2) [continue-on-error]
        ├── Instalar kubectl
        └── Actualizar imagen en EKS
```

### Secrets de GitHub requeridos
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
EKS_CLUSTER_NAME
```
---

## Despliegue desde cero

### 1. Crear repositorios ECR
```
AWS Console → ECR → Create repository
├── devops/proyecto-db
├── devops/front-despacho
├── devops/back-despacho
└── devops/back-ventas
```

### 2. Crear clúster EKS
```
AWS Console → EKS → Create cluster
→ Seguir configuración documentada arriba
```

### 3. Crear node group
```
EKS → proyecto-despachos-eks → Compute → Add node group
→ Seguir configuración documentada arriba
```

### 4. Configurar kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name proyecto-despachos-eks
```

### 5. Crear Kubernetes Secrets
```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl create secret generic db-secrets ...
kubectl create secret docker-registry ecr-secret ...
```

### 6. Desplegar servicios
```bash
kubectl apply -f kubernetes/db/
kubectl apply -f kubernetes/backend-despacho/
kubectl apply -f kubernetes/backend-ventas/
kubectl apply -f kubernetes/frontend/
```

### 7. Configurar HPA
```bash
kubectl autoscale deployment back-despacho --cpu-percent=50 --min=2 --max=5 -n proyecto
kubectl autoscale deployment back-ventas --cpu-percent=50 --min=2 --max=5 -n proyecto
kubectl autoscale deployment front-despacho --cpu-percent=50 --min=2 --max=5 -n proyecto
```
