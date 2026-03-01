# Capítulo 29: Gestión de Clústeres AKS

En el capítulo anterior cerramos el área de arquitectura Kubernetes con el framework de troubleshooting: ahora podemos diagnosticar y resolver fallos en cualquier capa del cluster. Tenemos dominio completo de Kubernetes en entornos locales y on-premises. Es el momento de dar el salto a donde la mayoría de los equipos ejecutan sus cargas de trabajo en producción: la nube.

El problema con gestionar tu propio control plane en producción es la cantidad de trabajo operativo que recae sobre ti. Tienes que hacer backups de etcd periódicamente, rotar los certificados TLS del API server antes de que expiren, gestionar los upgrades del control plane sin que la API deje de responder, escalar etcd cuando el cluster crece, y responder cuando uno de los nodos del control plane falla a las 3am. Todo ese trabajo no aporta valor de negocio directo: es infraestructura que sostiene tu infraestructura. Para la mayoría de los equipos, ese tiempo se gasta mejor construyendo las aplicaciones que el negocio necesita.

Azure Kubernetes Service (AKS) elimina esa carga: gestiona el control plane por ti, incluyendo etcd, el API server, el scheduler y el controller manager. Microsoft se encarga de los upgrades, los certificados, la alta disponibilidad del control plane y la monitorización de sus componentes. Tú te concentras en tus node pools, tus aplicaciones y tus políticas de acceso.

Es como la diferencia entre ser propietario de una casa y alquilar un apartamento en un edificio con portero: en la casa propia gestionas la fontanería, la electricidad y el tejado; en el apartamento AKS, el edificio (control plane) lo gestiona el propietario y tú te encargas de decorar y vivir en él (desplegar y operar tus aplicaciones).

En este capítulo aprenderás a crear y configurar clusters AKS desde la CLI de Azure y el portal, a gestionar node pools para diferentes tipos de carga de trabajo, a elegir entre las opciones de networking (kubenet vs Azure CNI), a integrar AKS con otros servicios de Azure como Container Registry y Key Vault, y a monitorizar el cluster con Azure Monitor y Container Insights.

---

## ¿Qué es un Servicio Gestionado?

Antes de ver los comandos, necesitas entender exactamente qué quiere decir "gestionado" y qué implica para tu día a día como operador.

### La división de responsabilidades

Cuando despliegas Kubernetes con kubeadm (como hicimos en los módulos anteriores), eres responsable de todo. Cuando usas AKS, Microsoft asume la responsabilidad de la capa del control plane. La forma más clara de verlo es esta división:

```
Self-managed (kubeadm):          AKS (managed):
┌─────────────────────┐          ┌─────────────────────┐
│ TÚ gestionas:       │          │ AZURE gestiona:     │
│ • Control Plane     │          │ • Control Plane     │
│ • etcd backups      │          │ • etcd backups      │
│ • Certificados TLS  │          │ • Certificados TLS  │
│ • Upgrades API srv  │          │ • Upgrades API srv  │
│ • Networking base   │          │ • HA del control    │
│ • Monitoreo base    │          │   plane             │
├─────────────────────┤          ├─────────────────────┤
│ TÚ gestionas:       │          │ TÚ gestionas:       │
│ • Worker nodes      │          │ • Worker nodes      │
│ • Apps              │          │ • Apps              │
│ • RBAC              │          │ • RBAC              │
│ • Network Policies  │          │ • Network Policies  │
│ • Storage           │          │ • Storage           │
│ • Ingress           │          │ • Ingress           │
└─────────────────────┘          └─────────────────────┘
```

La línea divisoria es el control plane. En AKS no tienes acceso SSH a los nodos del control plane, no puedes ejecutar `kubectl get pods -n kube-system` y ver el etcd pod que administras tú, y no puedes (ni necesitas) hacer backups manuales de etcd. Azure lo gestiona como un servicio con SLA del 99,9 % (o 99,95 % con zonas de disponibilidad).

### ¿Qué significa esto en la práctica?

Para un equipo de desarrollo que usa Kubernetes como plataforma de despliegue, la diferencia es enorme:

- **Sin AKS**: 1-2 ingenieros dedicados parcialmente a operar el control plane, responder alertas de certificados expirados, ejecutar procedimientos de upgrade cada 3 meses, y mantener la documentación del runbook de recuperación de etcd.
- **Con AKS**: esos mismos ingenieros se dedican a gestionar node pools, políticas de acceso, networking de aplicaciones, y optimización de costes.

El control plane de AKS no tiene coste por sí mismo: pagas por los nodos del worker pool (las VMs) y por los recursos que consumen (disco, red, load balancers). Esto hace que AKS sea competitivo con autogestionar Kubernetes, ya que los costes de las VMs del control plane en kubeadm tampoco son gratuitos.

### Comparativa: AKS vs EKS vs GKE

Las tres grandes clouds ofrecen Kubernetes gestionado, pero con diferencias importantes. Esta tabla te ayuda a posicionarte cuando trabajas en entornos multi-cloud o cuando evalúas opciones:

| Característica          | AKS (Azure)              | EKS (AWS)                 | GKE (Google)             |
|-------------------------|--------------------------|---------------------------|--------------------------|
| Coste control plane     | Gratuito                 | $0,10/hora por cluster    | Gratuito (tier Autopilot aparte) |
| CNI por defecto         | kubenet / Azure CNI      | VPC CNI (aws-node)        | VPC-native (alias IPs)   |
| Integración IAM         | Azure AD / Entra ID      | AWS IAM + IRSA            | Google IAM + Workload Identity |
| Monitoreo nativo        | Azure Monitor + Container Insights | CloudWatch + Container Insights | Cloud Monitoring + Cloud Logging |
| CLI principal           | `az aks`                 | `eksctl` / `aws eks`      | `gcloud container`       |
| Versiones soportadas    | N-2 (últimas 3)          | N-2 (últimas 3)           | N-3 (últimas 4)          |
| Upgrade automático      | Sí (configurable)        | Sí (managed node groups)  | Sí (release channels)    |
| Spot/Preemptible nodes  | Spot VMs                 | Spot Instances            | Preemptible VMs          |
| Almacenamiento nativo   | Azure Disk / Azure Files | EBS / EFS                 | Persistent Disk / Filestore |

Para este curso trabajamos con AKS, pero los conceptos de node pools, networking, RBAC y monitoreo que verás aquí se aplican (con variaciones de CLI) a EKS y GKE.

---

## Creación de un Cluster AKS paso a paso

### Prerrequisitos antes de crear el cluster

Antes de ejecutar el primer comando, necesitas tres cosas:

**1. Suscripción de Azure activa**

Puedes usar una cuenta gratuita (Azure Free Tier ofrece $200 de crédito por 30 días) o una suscripción de pago. Verifica que tienes acceso:

```bash
# Verificar que Azure CLI está instalado y autenticado
az account show

# Salida esperada:
# {
#   "environmentName": "AzureCloud",
#   "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#   "isDefault": true,
#   "name": "Mi Suscripción Azure",
#   "state": "Enabled",
#   "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#   "user": {
#     "name": "usuario@empresa.com",
#     "type": "user"
#   }
# }
```

Si no estás autenticado, ejecuta `az login` y sigue el flujo en el navegador.

**2. Azure CLI versión 2.49 o superior**

```bash
az version

# Salida esperada:
# {
#   "azure-cli": "2.56.0",
#   "azure-cli-core": "2.56.0",
#   ...
# }

# Actualizar si es necesario:
az upgrade
```

**3. Resource Group creado**

Un Resource Group es el contenedor lógico de todos los recursos Azure asociados a tu cluster. Todos los recursos de AKS, incluyendo las VMs de los worker nodes, los discos y los load balancers, vivirán en este grupo (o en uno relacionado que Azure crea automáticamente).

```bash
# Crear el resource group
az group create \
  --name rg-kubernetes-course \
  --location eastus

# Salida esperada:
# {
#   "id": "/subscriptions/.../resourceGroups/rg-kubernetes-course",
#   "location": "eastus",
#   "name": "rg-kubernetes-course",
#   "properties": {
#     "provisioningState": "Succeeded"
#   },
#   "type": "Microsoft.Resources/resourceGroups"
# }
```

### El comando az aks create explicado

Este es el comando fundamental para crear un cluster. Cada flag tiene una razón de ser:

```bash
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --kubernetes-version 1.28.0 \
  --network-plugin azure \
  --network-policy azure \
  --enable-managed-identity \
  --generate-ssh-keys \
  --location eastus
```

La creación tarda entre 5 y 10 minutos. A continuación la explicación de cada parámetro:

| Flag | Valor | Por qué |
|------|-------|---------|
| `--resource-group` | `rg-kubernetes-course` | Resource group donde se crean todos los recursos asociados |
| `--name` | `aks-k8s-course` | Nombre único del cluster dentro del resource group |
| `--node-count` | `2` | Número inicial de nodos en el system node pool. Mínimo recomendado: 2 (sin HA), 3 (con HA) |
| `--node-vm-size` | `Standard_D2s_v3` | SKU de la VM: 2 vCPUs, 8GB RAM. Para producción usa D4s_v3 o mayor |
| `--kubernetes-version` | `1.28.0` | Versión de K8s. Omitir para usar la versión estable por defecto |
| `--network-plugin` | `azure` | Azure CNI: cada Pod obtiene una IP real de la VNet (explicado en sección Networking) |
| `--network-policy` | `azure` | Activa NetworkPolicies usando el motor de Azure (alternativa: `calico`) |
| `--enable-managed-identity` | (flag) | AKS usa una Managed Identity para gestionar recursos Azure en tu nombre, sin credenciales |
| `--generate-ssh-keys` | (flag) | Genera un par de claves SSH para acceso a los nodos worker (para troubleshooting de nodo) |
| `--location` | `eastus` | Región Azure. Si omites, usa la región del resource group |

**Salida esperada tras la creación (resumen):**

```bash
# La creación muestra una barra de progreso y termina con:
# {
#   "id": "/subscriptions/.../resourceGroups/rg-kubernetes-course/providers/Microsoft.ContainerService/managedClusters/aks-k8s-course",
#   "kubernetesVersion": "1.28.0",
#   "location": "eastus",
#   "name": "aks-k8s-course",
#   "provisioningState": "Succeeded",
#   "agentPoolProfiles": [
#     {
#       "count": 2,
#       "name": "nodepool1",
#       "vmSize": "Standard_D2s_v3",
#       "mode": "System"
#     }
#   ]
# }
```

### Opciones avanzadas de creación

Para entornos de producción real, añadirías flags adicionales:

```bash
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course-prod \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3 \
  --kubernetes-version 1.28.0 \
  --network-plugin azure \
  --network-policy azure \
  --enable-managed-identity \
  --generate-ssh-keys \
  --location eastus \
  --zones 1 2 3 \
  --enable-cluster-autoscaler \
  --min-count 3 \
  --max-count 10 \
  --node-osdisk-size 128 \
  --enable-addons monitoring \
  --workspace-resource-id "/subscriptions/.../resourcegroups/rg-k8s/providers/Microsoft.OperationalInsights/workspaces/law-k8s"
```

Los flags adicionales hacen lo siguiente:

- `--zones 1 2 3`: distribuye los nodos entre las 3 zonas de disponibilidad de la región, garantizando que el cluster sobrevive a la caída de un datacenter completo
- `--enable-cluster-autoscaler` + `--min-count`/`--max-count`: activa el Cluster Autoscaler de Kubernetes, que escala los nodos automáticamente según la demanda de Pods
- `--node-osdisk-size 128`: tamaño del disco OS de cada nodo en GB (por defecto es 128GB)
- `--enable-addons monitoring`: instala el addon de Container Insights para monitorización
- `--workspace-resource-id`: ID del Log Analytics Workspace donde se envían los logs

### Creación desde el Portal de Azure

Si prefieres usar la interfaz gráfica, el flujo en el portal es el siguiente. La creación se divide en pestañas:

**Pestaña "Basics"**
- Suscripción y Resource Group (selecciona `rg-kubernetes-course`)
- Nombre del cluster: `aks-k8s-course`
- Región: East US
- Versión de Kubernetes: 1.28.0 (o la más reciente estable)
- Tier: Free (suficiente para el curso), Standard (SLA 99,95% para producción)

**Pestaña "Node pools"**
- Node pool por defecto: nombre `nodepool1`, 2 nodos, SKU `Standard_D2s_v3`
- Puedes activar el autoscaler aquí: min 1, max 5
- Zonas de disponibilidad: selecciona 1, 2, 3 para HA

**Pestaña "Networking"**
- Network configuration: `kubenet` (más simple) o `Azure CNI` (más potente)
- DNS name prefix: se usa para el FQDN del API server
- Network policy: `Azure` o `Calico` (solo disponible con Azure CNI)

**Pestaña "Integrations"**
- Container Registry: conecta un ACR existente o crea uno nuevo
- Key Vault: para gestión de Secrets con Azure Key Vault Provider

**Pestaña "Monitoring"**
- Enable Container Insights: recomendado activar siempre
- Selecciona o crea un Log Analytics Workspace

**Pestaña "Advanced"**
- Infrastructure encryption: para discos con encryption at rest con customer-managed keys
- Image Cleaner: limpia automáticamente imágenes no usadas de los nodos

**Pestaña "Tags"**
- Añade etiquetas Azure como `environment: dev`, `team: platform`, `cost-center: 123`

**Pestaña "Review + create"**
- Validación automática de la configuración
- Resumen del coste estimado
- Pulsa "Create" para iniciar el despliegue

### Conectarse al cluster recién creado

Una vez creado el cluster, necesitas obtener las credenciales para que `kubectl` sepa cómo conectarse:

```bash
# Descargar y configurar las credenciales en ~/.kube/config
az aks get-credentials \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Salida esperada:
# Merged "aks-k8s-course" as current context in /home/usuario/.kube/config

# Verificar la conexión
kubectl get nodes

# Salida esperada:
# NAME                                STATUS   ROLES   AGE    VERSION
# aks-nodepool1-12345678-vmss000000   Ready    agent   5m     v1.28.0
# aks-nodepool1-12345678-vmss000001   Ready    agent   5m     v1.28.0

# Ver todos los pods del sistema que AKS despliega automáticamente
kubectl get pods -n kube-system

# Salida esperada (selección):
# NAME                                    READY   STATUS    RESTARTS   AGE
# azure-ip-masq-agent-xxxxx               1/1     Running   0          5m
# coredns-autoscaler-xxxxx                1/1     Running   0          5m
# coredns-xxxxx                           1/1     Running   0          5m
# coredns-xxxxx                           1/1     Running   0          5m
# konnectivity-agent-xxxxx                1/1     Running   0          5m
# metrics-server-xxxxx                    1/1     Running   0          5m
```

Nota que en AKS los nodos tienen el rol `agent`, no `control-plane` ni `master`, porque los nodos del control plane no son visibles para ti: son gestionados por Azure.

También nota la presencia de `konnectivity-agent`: este Pod establece el túnel seguro entre el control plane (gestionado por Azure) y tus worker nodes. Es el componente que permite que el API server se comunique con los Pods en tus nodos.

---

## Node Pools en Profundidad

### ¿Qué es un node pool?

Un node pool es un grupo de nodos (VMs) con la misma configuración: mismo SKU de VM, mismo sistema operativo, misma versión de Kubernetes, mismo conjunto de taints y labels. AKS gestiona los node pools como VMSS (Virtual Machine Scale Sets) de Azure, lo que permite escalar automáticamente añadiendo o eliminando VMs del VMSS.

Cada cluster AKS tiene obligatoriamente un **system node pool** y puede tener opcionalmente uno o más **user node pools**:

```
┌──────────────────────────────────────────────────┐
│                   AKS Cluster                    │
├──────────────────┬───────────────────────────────┤
│   System Pool    │       User Pool(s)             │
│   (obligatorio)  │       (opcionales)             │
│                  │                               │
│  • kube-system   │  • Pool GPU                   │
│    workloads     │    (SKU: NC6s_v3)             │
│  • CoreDNS       │    Taint: gpu=true:NoSchedule │
│  • konnectivity  │                               │
│  • metrics-srv   │  • Pool spot-instances        │
│  • azure-policy  │    (SKU: D4s_v3, spot)        │
│                  │    Taint: spot=true:NoSchedule│
│  Min: 1 nodo     │                               │
│  Recomendado: 3  │  • Pool high-memory           │
│                  │    (SKU: E8s_v3, 64GB RAM)    │
│                  │    Label: workload=memory      │
│                  │                               │
│                  │  Min: 0 nodos (scale to zero) │
└──────────────────┴───────────────────────────────┘
```

La diferencia clave entre system y user pools:

- El **system pool** ejecuta los componentes del sistema de Kubernetes. Tiene el taint `CriticalAddonsOnly=true:NoSchedule` por defecto, lo que impide que tus aplicaciones de usuario se programen ahí a menos que tengan la toleration correspondiente.
- Los **user pools** están diseñados para cargas de trabajo de aplicación. Pueden tener 0 nodos cuando no hay trabajo, lo que permite ahorrar costes fuera del horario laboral.

### Crear pools especializados

**Pool para cargas de trabajo con GPU (machine learning, rendering):**

```bash
az aks nodepool add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name gpupool \
  --node-count 1 \
  --node-vm-size Standard_NC6s_v3 \
  --node-taints gpu=true:NoSchedule \
  --labels workload=gpu accelerator=nvidia \
  --no-wait

# Salida esperada:
# The behavior of this command has been altered by the following extension: aks-preview
# (iniciando creación en background, tarda 5-10 minutos)
```

Las aplicaciones que necesiten GPU incluyen la toleration:

```yaml
# Ejemplo: Pod que requiere GPU del pool especializado
spec:
  tolerations:
  - key: gpu
    operator: Equal
    value: "true"
    effect: NoSchedule
  nodeSelector:
    workload: gpu
  containers:
  - name: ml-training
    image: pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime
    resources:
      limits:
        nvidia.com/gpu: 1   # Solicita 1 GPU
```

**Pool con Spot instances para cargas tolerantes a interrupciones:**

Las Spot VMs cuestan entre un 60-90% menos que VMs On-Demand, pero Azure puede reclamarlas con 30 segundos de aviso cuando necesita la capacidad. Son ideales para tareas de batch, CI/CD runners, y cargas stateless que pueden reiniciarse.

```bash
az aks nodepool add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name spotpool \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --node-count 0 \
  --min-count 0 \
  --max-count 10 \
  --enable-cluster-autoscaler \
  --node-vm-size Standard_D4s_v3 \
  --node-taints kubernetes.azure.com/scalesetpriority=spot:NoSchedule \
  --labels kubernetes.azure.com/scalesetpriority=spot

# --spot-max-price -1 significa "acepta el precio de mercado actual"
# --eviction-policy Delete: cuando se evicta, el nodo se elimina (alternativa: Deallocate)
```

**Pool con nodos de alta memoria para bases de datos en memoria:**

```bash
az aks nodepool add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name mempool \
  --node-count 2 \
  --node-vm-size Standard_E8s_v3 \
  --node-taints workload=memory-intensive:NoSchedule \
  --labels workload=memory-intensive tier=data
```

### Escalar node pools

**Escalado manual:**

```bash
# Escalar a 4 nodos el pool workerpool
az aks scale \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --node-count 4 \
  --nodepool-name workerpool

# Salida esperada (tras completarse):
# {
#   "agentPoolProfiles": [
#     {
#       "count": 4,
#       "name": "workerpool",
#       ...
#     }
#   ]
# }
```

**Activar Cluster Autoscaler en un pool existente:**

```bash
az aks nodepool update \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name workerpool \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 8

# Salida esperada:
# {
#   "enableAutoScaling": true,
#   "minCount": 1,
#   "maxCount": 8,
#   ...
# }
```

El Cluster Autoscaler monitoriza los Pods en estado `Pending` por falta de recursos. Cuando detecta Pods pendientes, añade nodos al pool. Cuando los nodos llevan más de 10 minutos subutilizados (menos del 50% de CPU/memoria usada), los elimina.

### Listar y eliminar pools

```bash
# Ver estado de todos los pools
az aks nodepool list \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --output table

# Salida esperada:
# Name        OsType    KubernetesVersion    VmSize             Count    Mode
# ----------  --------  -------------------  -----------------  -------  ------
# nodepool1   Linux     1.28.0               Standard_D2s_v3    2        System
# workerpool  Linux     1.28.0               Standard_D2s_v3    2        User
# gpupool     Linux     1.28.0               Standard_NC6s_v3   1        User

# Eliminar un pool (primero asegúrate de que no tiene Pods críticos)
az aks nodepool delete \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name workerpool \
  --no-wait
```

---

## Networking en AKS

La elección de networking en AKS es una de las decisiones más importantes al crear un cluster y **no se puede cambiar después de la creación**. Aquí explicamos las opciones con sus implicaciones reales.

### kubenet vs Azure CNI

La diferencia fundamental está en cómo se asignan las IPs a los Pods:

**kubenet (más simple, menos IPs):**
- Los nodos obtienen IPs de la VNet de Azure
- Los Pods obtienen IPs de un rango separado (overlay network, por defecto `10.244.0.0/16`)
- El tráfico entre un Pod y destinos fuera del nodo pasa por NAT en el nodo
- Azure crea rutas UDR (User Defined Routes) para el tráfico inter-nodo

**Azure CNI (más potente, más IPs):**
- Tanto los nodos como los Pods obtienen IPs directamente de la VNet de Azure
- No hay NAT: cada Pod es directamente enrutable desde la VNet
- Requiere más IPs en la subred (por nodo: 1 IP + número máximo de Pods por nodo, por defecto 30)

```
kubenet:
┌─────────────────────────────────────────┐
│  VNet: 10.0.0.0/16                      │
│  ┌──────────────────────────────────┐   │
│  │ Subnet: 10.0.1.0/24             │   │
│  │ Node1: 10.0.1.4                  │   │
│  │ Node2: 10.0.1.5                  │   │
│  └──────────────────────────────────┘   │
│                                         │
│  Pod network (overlay): 10.244.0.0/16   │
│  Pod en Node1: 10.244.0.5 (no visible   │
│                desde VNet sin ruta)      │
└─────────────────────────────────────────┘

Azure CNI:
┌─────────────────────────────────────────┐
│  VNet: 10.0.0.0/16                      │
│  ┌──────────────────────────────────┐   │
│  │ Subnet: 10.0.1.0/24 (grande)    │   │
│  │ Node1: 10.0.1.4                  │   │
│  │ Node2: 10.0.1.5                  │   │
│  │ Pod1 en Node1: 10.0.1.20        │   │
│  │ Pod2 en Node1: 10.0.1.21        │   │
│  │ Pod1 en Node2: 10.0.1.50        │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

Comparativa completa:

| Característica | kubenet | Azure CNI |
|----------------|---------|-----------|
| Asignación IP | Overlay NAT | IP directa de VNet |
| Rendimiento | Bueno (overhead NAT pequeño) | Mejor (sin NAT) |
| Network Policies | Solo Calico | Azure NP + Calico |
| Escala máxima | ~400 nodos | ~1.000 nodos |
| IPs de VNet necesarias | Solo para nodos | Por nodo: 1 + max Pods |
| Coste de IPs | Menor | Mayor (más IPs en subred) |
| Conectividad directa con VMs Azure | No (requiere configuración) | Sí (misma VNet) |
| Complejidad de configuración | Baja | Media |
| Diagnóstico de red | Más complejo (overlay) | Más fácil (IPs reales) |

### ¿Cuándo usar cada uno?

**Elige kubenet si:**
- Es un cluster de desarrollo o staging con pocos nodos
- El espacio de IPs de tu VNet es limitado
- No necesitas conectividad directa entre Pods y VMs u otros servicios Azure en la misma VNet
- Quieres la configuración más simple

**Elige Azure CNI si:**
- Los Pods necesitan comunicarse directamente con recursos en la VNet (VMs, Azure SQL, App Service)
- Necesitas Network Policies con el motor de Azure (más integrado que Calico)
- El cluster podría crecer a más de 400 nodos
- Estás en producción y el diagnóstico de red simplificado justifica el mayor consumo de IPs

### Planificación de subredes para Azure CNI

Antes de crear el cluster con Azure CNI, calcula cuántas IPs necesitas:

```
IPs necesarias = (nodos_max × pods_max_por_nodo) + nodos_max + 5 (reservadas por Azure)

Ejemplo para 20 nodos con 30 Pods cada uno:
= (20 × 30) + 20 + 5
= 600 + 20 + 5
= 625 IPs mínimas

Subred recomendada: /22 (1.022 IPs usables)
```

```bash
# Crear VNet y subred antes del cluster (para Azure CNI)
az network vnet create \
  --resource-group rg-kubernetes-course \
  --name vnet-aks-k8s \
  --address-prefixes 10.0.0.0/8

az network vnet subnet create \
  --resource-group rg-kubernetes-course \
  --vnet-name vnet-aks-k8s \
  --name subnet-aks-nodes \
  --address-prefixes 10.240.0.0/16

# Obtener el ID de la subred para usarlo en la creación del cluster
SUBNET_ID=$(az network vnet subnet show \
  --resource-group rg-kubernetes-course \
  --vnet-name vnet-aks-k8s \
  --name subnet-aks-nodes \
  --query id \
  --output tsv)

# Crear cluster con Azure CNI en la subred específica
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course-cni \
  --network-plugin azure \
  --vnet-subnet-id $SUBNET_ID \
  --service-cidr 10.2.0.0/24 \
  --dns-service-ip 10.2.0.10 \
  --node-count 2 \
  --generate-ssh-keys
```

### Load Balancer en AKS

Cuando creas un Service de tipo `LoadBalancer` en AKS, Azure crea automáticamente un Azure Load Balancer en el resource group del cluster. AKS soporta dos tiers:

| Tier | Escenario | Límite de reglas | Zonas de disponibilidad |
|------|-----------|-----------------|------------------------|
| Basic | Dev/test | 150 reglas de LB | No |
| Standard | Producción | 1.500 reglas de LB | Sí |

Por defecto, los clusters nuevos usan Standard Load Balancer. Para crear un Internal Load Balancer (IP privada, no expuesto a internet), usa la anotación:

```yaml
# Service con Load Balancer interno (IP privada de la VNet)
apiVersion: v1
kind: Service
metadata:
  name: backend-api
  annotations:
    # Crea un Internal Load Balancer en vez de público
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    # Opcionalmente, especifica la subred donde crear el LB interno
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "subnet-internal-lb"
spec:
  type: LoadBalancer
  selector:
    app: backend-api
  ports:
  - name: http
    port: 80
    targetPort: http
```

---

## Monitoreo y Diagnóstico

### Container Insights

Container Insights es el sistema de monitorización nativo de AKS. Se basa en un DaemonSet que corre en cada nodo y envía métricas y logs a un Log Analytics Workspace de Azure Monitor.

Activar Container Insights en un cluster existente:

```bash
# Primero, crea o identifica un Log Analytics Workspace
WORKSPACE_ID=$(az monitor log-analytics workspace create \
  --resource-group rg-kubernetes-course \
  --workspace-name law-aks-k8s-course \
  --query id \
  --output tsv)

# Activa Container Insights en el cluster
az aks enable-addons \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --addons monitoring \
  --workspace-resource-id $WORKSPACE_ID

# Salida esperada:
# {
#   "addonProfiles": {
#     "omsagent": {
#       "enabled": true,
#       ...
#     }
#   }
# }

# Verificar que el DaemonSet de monitorización está corriendo
kubectl get daemonset -n kube-system | grep ama

# Salida esperada:
# ama-logs   2         2         2       2            2           <none>   5m
```

Una vez activado, en el portal de Azure puedes acceder a:
- **Metrics**: CPU, memoria y red de nodos y Pods en tiempo real
- **Logs**: consultas KQL para buscar en logs de contenedores, eventos de K8s y métricas históricas
- **Workbooks**: dashboards predefinidos para análisis de carga, distribución de nodos, y análisis de imágenes

### Comandos de diagnóstico desde kubectl

Estos comandos funcionan en cualquier cluster Kubernetes, pero son especialmente útiles en AKS para diagnosticar desde la perspectiva del cluster:

```bash
# Ver el consumo actual de CPU y memoria de los nodos
kubectl top nodes

# Salida esperada:
# NAME                                CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# aks-nodepool1-12345678-vmss000000   285m         14%    1842Mi          24%
# aks-nodepool1-12345678-vmss000001   198m         9%     1654Mi          22%

# Ver el consumo de los Pods (todos los namespaces)
kubectl top pods --all-namespaces --sort-by=memory

# Salida esperada:
# NAMESPACE     NAME                           CPU(cores)   MEMORY(bytes)
# kube-system   omsagent-xxxxx                 12m          68Mi
# kube-system   coredns-xxxxx                  3m           16Mi
# default       my-app-deployment-xxxxx        8m           45Mi

# Ver detalles completos del cluster desde Azure
az aks show \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --output json | jq '{
    nombre: .name,
    estado: .provisioningState,
    version_k8s: .kubernetesVersion,
    fqdn: .fqdn,
    nodos_sistema: .agentPoolProfiles[0].count,
    autoscaler: .agentPoolProfiles[0].enableAutoScaling
  }'

# Salida esperada:
# {
#   "nombre": "aks-k8s-course",
#   "estado": "Succeeded",
#   "version_k8s": "1.28.0",
#   "fqdn": "aks-k8s-course-xxxxx.hcp.eastus.azmk8s.io",
#   "nodos_sistema": 2,
#   "autoscaler": false
# }

# Ver condiciones de los nodos (salud del nodo)
kubectl get nodes -o custom-columns=\
'NAME:.metadata.name,STATUS:.status.conditions[-1].type,REASON:.status.conditions[-1].reason'

# Salida esperada:
# NAME                                STATUS   REASON
# aks-nodepool1-12345678-vmss000000   Ready    KubeletReady
# aks-nodepool1-12345678-vmss000001   Ready    KubeletReady

# Ver eventos recientes de todos los recursos (muy útil para diagnóstico)
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20
```

### Diagnóstico de nodo con az aks

AKS ofrece comandos de diagnóstico específicos que no existen en un cluster genérico:

```bash
# Ver el estado de salud del cluster desde Azure
az aks check-health \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --output table

# Obtener logs del nodo directamente (sin SSH)
az aks run-command invoke \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --command "journalctl -u kubelet --no-pager | tail -50"

# Ver quotas y límites del cluster
az aks show \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --query 'agentPoolProfiles[].{pool:name, count:count, maxPods:maxPods}' \
  --output table

# Salida esperada:
# Pool        Count    MaxPods
# ----------  -------  ---------
# nodepool1   2        110
# workerpool  2        110
```

---

## Upgrade del Cluster

Los upgrades de versión son una de las operaciones más críticas en AKS. Un upgrade mal gestionado puede causar interrupciones de servicio. AKS los hace manejables, pero requieren planificación.

### Política de soporte de versiones (N-2)

AKS soporta las 3 últimas minor versions de Kubernetes. Cuando sale una nueva versión, la más antigua deja de tener soporte. Por ejemplo:

```
Versiones soportadas (ejemplo con K8s 1.28 recién liberado):
  ✓ 1.28.x  ← Más reciente (N)
  ✓ 1.27.x  ← N-1
  ✓ 1.26.x  ← N-2 (última con soporte)
  ✗ 1.25.x  ← Sin soporte, AKS fuerza upgrade

Las patch versions dentro de cada minor también se actualizan.
AKS retira patch versions antiguas ~ cada 30 días.
```

Si tu cluster corre una versión sin soporte, Azure puede upgradearlo automáticamente a la más cercana soportada (con aviso previo). Esta es una de las razones por las que los upgrades planificados son importantes.

### Ver versiones disponibles

```bash
# Ver todas las versiones disponibles en tu región
az aks get-versions \
  --location eastus \
  --output table

# Salida esperada:
# KubernetesVersion    Upgrades
# -------------------  ----------------------------------------
# 1.28.0               None available
# 1.27.7               1.28.0
# 1.27.3               1.28.0
# 1.26.10              1.27.3, 1.27.7
# 1.26.6               1.27.3, 1.27.7
# 1.25.15              1.26.6, 1.26.10

# Ver las opciones de upgrade específicas de tu cluster
az aks get-upgrades \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --output table

# Salida esperada:
# Name     ResourceGroup           MasterVersion    Upgrades
# -------  ----------------------  ---------------  ----------
# default  rg-kubernetes-course    1.27.3           1.27.7, 1.28.0
```

### Proceso de upgrade paso a paso

El upgrade de AKS funciona con un rolling upgrade que garantiza que siempre hay nodos disponibles:

1. Azure crea un nuevo nodo con la nueva versión
2. Los Pods del nodo más antiguo se drenan (evicted) al nuevo nodo
3. El nodo antiguo se elimina
4. Se repite para cada nodo del pool

```bash
# PASO 1: Hacer snapshot del estado actual (recomendado antes de cualquier upgrade)
kubectl get all --all-namespaces -o yaml > pre-upgrade-state.yaml

# PASO 2: Verificar que el upgrade es posible (solo se puede subir una minor version a la vez)
az aks get-upgrades \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# PASO 3: Ejecutar el upgrade (el --no-wait permite que sea asíncrono)
az aks upgrade \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --kubernetes-version 1.28.0 \
  --yes

# Salida esperada durante el upgrade:
# Kubernetes may be unavailable during cluster upgrades.
# Are you sure you want to perform this operation? (y/N): y
# {
#   "provisioningState": "Upgrading",
#   ...
# }

# PASO 4: Monitorizar el progreso
watch az aks show \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --query '{estado: provisioningState, version: kubernetesVersion}'

# Salida mientras upgrading:
# {
#   "estado": "Upgrading",
#   "version": "1.27.3"
# }

# Salida cuando completa:
# {
#   "estado": "Succeeded",
#   "version": "1.28.0"
# }

# PASO 5: Verificar el estado post-upgrade
kubectl get nodes

# Salida esperada:
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-nodepool1-12345678-vmss000002   Ready    agent   5m    v1.28.0
# aks-nodepool1-12345678-vmss000003   Ready    agent   3m    v1.28.0
```

Nota que los nombres de los nodos cambian después del upgrade porque se crean VMs nuevas en el VMSS.

### Node image upgrades (independiente de la versión K8s)

Aparte del upgrade de versión de Kubernetes, los nodos reciben actualizaciones de la imagen del sistema operativo (parches de seguridad de Ubuntu/Windows). Estas son independientes de la versión K8s:

```bash
# Ver la versión actual de la imagen de nodo
az aks nodepool show \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name nodepool1 \
  --query nodeImageVersion

# Salida esperada:
# "AKSUbuntu-2204gen2containerd-202402.26.0"

# Ver si hay actualizaciones disponibles para la imagen del nodo
az aks nodepool get-upgrades \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --nodepool-name nodepool1

# Actualizar solo la imagen del nodo (sin cambiar la versión K8s)
az aks nodepool upgrade \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name nodepool1 \
  --node-image-only
```

### Automatizar upgrades con Maintenance Windows

Para evitar upgrades en horario de negocio, configura una ventana de mantenimiento:

```bash
# Configurar que los upgrades automáticos ocurran solo los domingos entre las 2:00 y las 6:00 AM UTC
az aks maintenanceconfiguration add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name aksManagedAutoUpgradeSchedule \
  --schedule-type Weekly \
  --day-of-week Sunday \
  --start-time "02:00" \
  --duration 4 \
  --utc-offset "+00:00"
```

### Estrategia Blue-Green para upgrades sin downtime

Para aplicaciones críticas, la estrategia más segura es crear un nuevo cluster con la versión actualizada, migrar las cargas de trabajo gradualmente, y eliminar el viejo:

```
Cluster viejo (1.27.3):          Cluster nuevo (1.28.0):
┌─────────────────────┐          ┌─────────────────────┐
│ • Producción activa │    →     │ • Validación        │
│ • 100% tráfico      │          │ • Tests de humo     │
│ • Todas las apps    │          │ • Apps migradas      │
└─────────────────────┘          └─────────────────────┘
         ↓                                ↓
   Cortar tráfico               Recibir todo el tráfico
   (Traffic Manager              (actualizar DNS/LB
    o DNS TTL bajo)                apuntando al nuevo)
```

Este enfoque es más costoso (dos clusters en paralelo), pero elimina el riesgo de downtime por upgrade fallido.

---

## Administración a través de Azure Portal

### Acceso al Portal

1. **Navegación**: Azure Portal → Kubernetes services
2. **Overview**: Estado general del clúster
3. **Node pools**: Gestión de grupos de nodos
4. **Networking**: Configuración de red
5. **Security**: Configuraciones de seguridad
6. **Monitoring**: Métricas y logs

### Operaciones Básicas en Portal

**Scaling del Clúster:**
```
Portal → AKS → Node pools → Scale
- Manual scaling
- Auto-scaling configuration
- Node pool settings
```

**Upgrade del Clúster:**
```
Portal → AKS → Upgrade
- Kubernetes version
- Rolling upgrade
- Maintenance windows
```

## Administración con Azure CLI

### Comandos Fundamentales

```bash
# Listar clústeres AKS
az aks list --output table

# Obtener información detallada
az aks show \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Estado del clúster
az aks get-credentials \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Verificar versiones disponibles
az aks get-versions --location eastus --output table
```

### Scaling y Actualización

```bash
# Escalar node pool
az aks scale \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --node-count 3

# Habilitar autoscaling
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Actualizar versión de Kubernetes
az aks upgrade \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --kubernetes-version 1.28.0
```

### Node Pools Adicionales

```bash
# Crear node pool adicional
az aks nodepool add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name workerpool \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --node-taints dedicated=worker:NoSchedule

# Listar node pools
az aks nodepool list \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --output table

# Eliminar node pool
az aks nodepool delete \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name workerpool
```

## Integración con Azure Container Registry

### Configuración de ACR

```bash
# Attach ACR al clúster AKS
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --attach-acr acrk8scourse

# Verificar integración
az aks check-acr \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --acr acrk8scourse
```

### Usar Imágenes desde ACR

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-from-acr
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: acrk8scourse.azurecr.io/mi-app-nodejs:latest
        ports:
        - containerPort: 3000
```

---

## Troubleshooting AKS

Esta sección cubre los problemas más frecuentes en producción con AKS. El patrón de diagnóstico es siempre: síntoma → identificar causa → aplicar solución → verificar.

### Escenario 1: API server no responde

**Síntoma:** `kubectl get nodes` cuelga o devuelve `Unable to connect to the server`

**Causa:** Problema en el control plane gestionado por Azure, expiración de las credenciales locales, o problemas de red entre tu máquina y el API server.

**Diagnóstico y solución:**

```bash
# Paso 1: Verificar si el problema es de credenciales
az aks get-credentials \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --overwrite-existing

kubectl cluster-info

# Salida esperada si el cluster responde:
# Kubernetes control plane is running at https://aks-k8s-course-xxxx.hcp.eastus.azmk8s.io:443
# CoreDNS is running at https://...

# Paso 2: Verificar el estado del cluster en Azure
az aks show \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --query '{estado: provisioningState, powerState: powerState.code}'

# Si powerState es "Stopped", el cluster está parado:
az aks start \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Paso 3: Ver el Service Health de Azure para incidentes regionales
# https://status.azure.com/status/  (o buscar en el portal: Service Health)
```

### Escenario 2: Nodos en estado NotReady

**Síntoma:** `kubectl get nodes` muestra uno o más nodos como `NotReady`

**Causa habitual:** VM del nodo con problemas (disco lleno, memoria agotada, kubelet detenido, problema de red con el API server).

**Diagnóstico y solución:**

```bash
# Paso 1: Identificar el nodo problemático
kubectl get nodes

# Paso 2: Ver las condiciones del nodo en detalle
kubectl describe node aks-nodepool1-12345678-vmss000000

# En la sección Conditions busca:
# MemoryPressure: True → nodo con memoria casi llena
# DiskPressure: True   → nodo con disco casi lleno
# PIDPressure: True    → nodo con demasiados procesos
# Ready: False         → kubelet no responde al API server

# Paso 3: Si el disco está lleno, usa el Image Cleaner de AKS
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --enable-image-cleaner \
  --image-cleaner-interval-hours 24

# Paso 4: Para casos graves, cordon + drain + delete del nodo
# (AKS creará uno nuevo automáticamente via VMSS)
kubectl cordon aks-nodepool1-12345678-vmss000000
kubectl drain aks-nodepool1-12345678-vmss000000 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force

# Eliminar el nodo desde Azure (el VMSS crea uno nuevo)
az vmss delete-instances \
  --resource-group MC_rg-kubernetes-course_aks-k8s-course_eastus \
  --name aks-nodepool1-12345678-vmss \
  --instance-ids 0
```

Nota: el resource group `MC_rg-kubernetes-course_aks-k8s-course_eastus` es el "Node Resource Group" que AKS crea automáticamente para los recursos de infraestructura (VMs, discos, NICs). No lo elimines: AKS lo gestiona.

### Escenario 3: API throttling (demasiadas peticiones)

**Síntoma:** Errores `429 Too Many Requests` en los logs del scheduler, controller manager o del addon de monitorización. Las operaciones de kubectl se vuelven lentas o fallan intermitentemente.

**Causa:** AKS tiene límites de llamadas a la API de Azure Resource Manager (ARM). Si tienes muchos nodos escal ándose, muchas operaciones de PVC, o un cluster muy grande, puedes alcanzar el límite.

**Diagnóstico y solución:**

```bash
# Ver los headers de rate limiting en las respuestas
kubectl get events --field-selector reason=FailedToCreateEndpoint 2>/dev/null

# Ver los límites actuales desde Azure
az account show --query 'id' -o tsv | xargs -I {} \
  az rest --method get \
  --url "https://management.azure.com/subscriptions/{}/providers/Microsoft.Compute/locations/eastus/operations?api-version=2023-07-01" \
  --query 'value[0].properties.throttledRequests' 2>/dev/null || \
  echo "Revisar Azure Monitor → Metrics → 'ARM API calls throttled'"

# Mitigaciones:
# 1. Reducir la frecuencia de operaciones de scaling (aumentar cooldown del autoscaler)
kubectl -n kube-system edit configmap cluster-autoscaler-status
# Añadir en data.status: scale-down-delay-after-add: "10m"

# 2. Usar el flag --disable-local-accounts para reducir llamadas de RBAC
# 3. Revisar si hay controladores custom haciendo muchas llamadas a la API de Azure
kubectl logs -n kube-system -l app=cluster-autoscaler | grep "throttl"
```

### Escenario 4: PVC atascado en estado Pending

**Síntoma:** Los PersistentVolumeClaims se quedan en `Pending` indefinidamente y los Pods que los necesitan no arrancan.

**Causa habitual:** StorageClass incorrecta, zona de disponibilidad incompatible con el nodo, o cuota de discos alcanzada.

**Diagnóstico y solución:**

```bash
# Paso 1: Ver el estado del PVC
kubectl describe pvc mi-pvc

# En Events busca mensajes como:
# "no volume plugin matched" → StorageClass incorrecta
# "ProvisioningFailed: StorageAccountType Premium_LRS is not supported for zone" → zona incompatible
# "disk quota exceeded" → cuota de discos en la suscripción Azure alcanzada

# Paso 2: Ver las StorageClasses disponibles en AKS
kubectl get storageclasses

# Salida esperada en un cluster AKS estándar:
# NAME                    PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      AGE
# azuredisk-csi           disk.csi.azure.com         Delete          WaitForFirstConsumer   30d
# azuredisk-csi-premium   disk.csi.azure.com         Delete          WaitForFirstConsumer   30d
# azurefile-csi           file.csi.azure.com         Delete          Immediate              30d
# azurefile-csi-premium   file.csi.azure.com         Delete          Immediate              30d
# default (default)       disk.csi.azure.com         Delete          WaitForFirstConsumer   30d
# managed (deprecated)    kubernetes.io/azure-disk   Delete          WaitForFirstConsumer   30d
# managed-csi             disk.csi.azure.com         Delete          WaitForFirstConsumer   30d
# managed-premium         disk.csi.azure.com         Delete          WaitForFirstConsumer   30d

# Paso 3: Verificar que el PVC usa la StorageClass correcta
# Para discos estándar (HDD):
kubectl patch pvc mi-pvc -p '{"spec":{"storageClassName":"azuredisk-csi"}}'
# Nota: no puedes cambiar la SC de un PVC existente;
# debes eliminar el PVC y recrearlo con la SC correcta
```

### Escenario 5: Pods en estado Pending por falta de capacidad

**Síntoma:** Pods se quedan en `Pending` con el mensaje `0/2 nodes are available: 2 Insufficient cpu`

**Causa:** El node pool no tiene suficientes recursos para el Pod, o el Cluster Autoscaler no está activo/configurado.

**Diagnóstico y solución:**

```bash
# Paso 1: Ver por qué el Pod está Pending
kubectl describe pod mi-pod-xxxxx | grep -A 5 "Events:"

# Salida esperada:
# Events:
#   Warning  FailedScheduling  2m   default-scheduler
#            0/2 nodes are available: 2 Insufficient cpu.
#            preemption: 0/2 nodes are available: 2 No preemption victims found for incoming pod.

# Paso 2: Ver los recursos disponibles en los nodos
kubectl top nodes

# Paso 3: Si el autoscaler está activo, revisar sus logs
kubectl logs -n kube-system -l app=cluster-autoscaler | tail -30

# Paso 4: Escalar manualmente si el autoscaler no está activo
az aks scale \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --node-count 4 \
  --nodepool-name nodepool1

# Paso 5: Si el Pod tiene requests muy altos para las VMs del pool,
# considera ajustar los requests del Pod o usar un pool con VMs más grandes
kubectl edit deployment mi-deployment
# Reducir resources.requests.cpu/memory al mínimo necesario real
```

### Escenario 6: Errores al hacer pull de imágenes desde ACR

**Síntoma:** Pods en estado `ImagePullBackOff` o `ErrImagePull` usando imágenes de Azure Container Registry.

**Causa:** La integración AKS-ACR no está configurada, o se configuró pero se eliminó/expiró la asignación de roles.

**Diagnóstico y solución:**

```bash
# Paso 1: Ver el error exacto
kubectl describe pod mi-pod-xxxxx | grep -A 5 "Failed"

# Salida esperada:
# Failed to pull image "acrk8scourse.azurecr.io/mi-app:v1.0": rpc error: code = Unknown
# desc = failed to pull and unpack image: failed to resolve reference "acrk8scourse.azurecr.io/mi-app:v1.0":
# unexpected status code 401 Unauthorized

# Paso 2: Verificar la integración AKS-ACR
az aks check-acr \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --acr acrk8scourse

# Si devuelve error, la integración no está activa

# Paso 3: Reconfigurar la integración (adjuntar el ACR al cluster)
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --attach-acr acrk8scourse

# Salida esperada:
# {
#   "provisioningState": "Succeeded",
#   ...
# }

# Paso 4: Verificar que la imagen existe en el ACR
az acr repository show-tags \
  --name acrk8scourse \
  --repository mi-app \
  --output table

# Salida esperada:
# Result
# --------
# v1.0
# latest
```

La integración AKS-ACR funciona asignando el rol `AcrPull` a la Managed Identity del cluster sobre el ACR. Si alguien elimina esa asignación de roles en Azure IAM, el pull de imágenes falla con 401.

---

## Resumen del Capítulo

En este capítulo hemos transitado de Kubernetes autoservicio a la gestión de clústeres en producción con Azure Kubernetes Service. La diferencia fundamental es la división de responsabilidades: Azure gestiona el control plane (API server, etcd, certificados, HA), y tú te concentras en los worker nodes, las aplicaciones y las políticas.

Los conceptos clave que cubrimos:

- **Servicios gestionados**: AKS vs self-managed vs otros proveedores cloud (EKS, GKE). La tabla de comparativa te ayuda a posicionarte en conversaciones de arquitectura multi-cloud.

- **Creación de clusters**: el comando `az aks create` con sus flags explicados uno a uno. Cada flag tiene una razón: `--network-plugin azure` elige el modelo de red, `--enable-managed-identity` elimina la gestión de service principals, `--zones 1 2 3` garantiza supervivencia ante caída de datacenter.

- **Node pools**: el sistema pool es obligatorio y corre componentes del sistema; los user pools son opcionales y pueden escalarse a cero. Pools especializados con taints permiten aislar cargas de trabajo: GPUs para ML, Spot para batch, alta memoria para bases de datos en memoria.

- **Networking**: la elección entre kubenet (overlay NAT, menos IPs, más simple) y Azure CNI (IPs directas de VNet, más rendimiento, más planificación de subredes) es irreversible una vez creado el cluster. Para la mayoría de los casos de producción, Azure CNI es la opción recomendada.

- **Monitoreo**: Container Insights + kubectl top + az aks show te dan visibilidad completa del estado del cluster. Las métricas de nodos y Pods en tiempo real son esenciales para el capacity planning.

- **Upgrades**: la política N-2 obliga a mantenerse en las 3 últimas versiones. El proceso de rolling upgrade de AKS garantiza disponibilidad, pero los Pods sin PodDisruptionBudgets pueden verse afectados. La estrategia blue-green elimina el riesgo para aplicaciones críticas.

- **Troubleshooting**: los seis escenarios cubiertos (API server, NotReady, throttling, PVC, Pending, ACR) representan el 80% de los problemas que verás en producción. El patrón diagnóstico es siempre: `kubectl describe` → buscar en `Events` → correlacionar con `az aks show` → aplicar solución → verificar.

En el próximo capítulo profundizaremos en la seguridad de AKS: Azure AD integration para autenticación, RBAC en AKS, Azure Policy para gobernanza, y la protección de Secrets con Azure Key Vault.
