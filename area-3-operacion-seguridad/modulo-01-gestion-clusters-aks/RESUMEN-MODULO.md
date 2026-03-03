# 📚 RESUMEN - Módulo 01 (Área 3): Gestión de Clústeres AKS

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre la **gestión de clusters Azure Kubernetes Service (AKS)** — el servicio gestionado de Kubernetes en Azure. Aprenderás a crear y configurar clusters AKS, gestionar node pools, elegir opciones de networking, integrar con servicios Azure, y monitorizar el cluster con Container Insights.

**Duración**: 6 horas (teoría + labs)
**Nivel**: Intermedio
**Prerequisitos**: Kubernetes básico (Pods, Deployments, Services, Namespaces)

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### Fundamentos
- ✅ Explicar qué es un servicio Kubernetes gestionado vs self-managed
- ✅ Describir la división de responsabilidades en AKS (Azure vs usuario)
- ✅ Comparar AKS con EKS (AWS) y GKE (Google Cloud)
- ✅ Entender el modelo de costes de AKS

### Técnico
- ✅ Crear un cluster AKS con `az aks create`
- ✅ Gestionar node pools (system y user)
- ✅ Configurar networking (kubenet vs Azure CNI)
- ✅ Integrar AKS con Azure Container Registry (ACR)
- ✅ Configurar autoescalado de cluster y Pods

### Operaciones
- ✅ Actualizar la versión de Kubernetes del cluster
- ✅ Gestionar mantenimiento con PodDisruptionBudgets
- ✅ Monitorizar con Azure Monitor y Container Insights
- ✅ Configurar alertas basadas en métricas

### Troubleshooting
- ✅ Diagnosticar nodos en estado NotReady
- ✅ Resolver problemas de networking entre node pools
- ✅ Depurar fallos de autoscaling

---

## 🗺️ Estructura de Aprendizaje

### Fase 1: Conceptos Fundamentales (30 min)

#### ¿Qué es AKS?

**Azure Kubernetes Service** es un servicio gestionado donde Azure administra el control plane (API Server, etcd, scheduler, controller manager) y tú administras los worker nodes y tus aplicaciones.

**Analogía**: Es como la diferencia entre tener casa propia y alquilar un apartamento. En casa propia gestionas fontanería, electricidad y tejado (control plane). En el apartamento, el edificio se encarga de eso y tú te dedicas a vivir (desplegar apps).

#### Diagrama Mental:

```
┌──────────────────────────────────────────────┐
│             CLUSTER AKS                       │
│                                               │
│  ┌─────────────────┐  ┌──────────────────┐   │
│  │  AZURE gestiona  │  │  TÚ gestionas    │   │
│  │  (Control Plane) │  │  (Data Plane)    │   │
│  │                  │  │                  │   │
│  │  • API Server    │  │  • Node Pools    │   │
│  │  • etcd          │  │  • Deployments   │   │
│  │  • Scheduler     │  │  • Services      │   │
│  │  • Controller    │  │  • RBAC          │   │
│  │  • Certificates  │  │  • Networking    │   │
│  │  • Upgrades      │  │  • Monitoring    │   │
│  └─────────────────┘  └──────────────────┘   │
└──────────────────────────────────────────────┘
```

#### Diferencias Clave:

| Aspecto | Self-Managed (kubeadm) | AKS (Gestionado) |
|---------|----------------------|-------------------|
| **Control Plane** | Tú lo instalas y mantienes | Azure lo gestiona |
| **Coste** | VMs para control + workers | Solo workers (control plane gratis) |
| **Upgrades** | Manual (riesgo de downtime) | Automatizados por Azure |
| **Certificados** | Rotar manualmente cada año | Rotación automática |
| **etcd Backups** | Configurar y monitorear tú | Azure los hace automáticamente |
| **SLA** | Depende de tu configuración | 99.9% (99.95% con AZs) |
| **Complejidad** | Alta (2-3 personas dedicadas) | Media (1 persona part-time) |

### Fase 2: Creación y Configuración (45 min)

#### Comando Principal: az aks create

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

| Parámetro | Descripción |
|-----------|-------------|
| `--resource-group` | Contenedor lógico de recursos Azure |
| `--name` | Nombre único del cluster |
| `--node-count` | Nodos iniciales (mínimo 2 para HA) |
| `--node-vm-size` | Tipo de VM: Standard_D2s_v3 = 2 vCPU, 8GB RAM |
| `--network-plugin` | `kubenet` (básico) o `azure` (CNI avanzado) |
| `--enable-managed-identity` | Identidad para acceso a recursos Azure |

#### Conectar kubectl al cluster

```bash
# Descargar credenciales del cluster
az aks get-credentials \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Verificar conexión
kubectl get nodes
```

### Fase 3: Node Pools (30 min)

#### Tipos de Node Pools

```
Cluster AKS
├── System Node Pool (obligatorio)
│   ├── Ejecuta componentes del sistema (CoreDNS, metrics-server)
│   ├── Taint: CriticalAddonsOnly
│   └── Mínimo 1 nodo (recomendado 2-3)
│
└── User Node Pool (opcional, puede haber varios)
    ├── Ejecuta tus aplicaciones
    ├── Puede escalar a 0 nodos
    └── Puedes tener pools especializados (GPU, memoria alta)
```

#### Comandos de Node Pools

```bash
# Agregar un user node pool
az aks nodepool add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name apppool \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3

# Escalar un node pool
az aks nodepool scale \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name apppool \
  --node-count 5

# Listar node pools
az aks nodepool list \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  -o table
```

### Fase 4: Networking (30 min)

#### kubenet vs Azure CNI

| Aspecto | kubenet | Azure CNI |
|---------|---------|-----------|
| **IP del Pod** | IP interna (NAT) | IP real de la VNet |
| **Escalabilidad** | Hasta ~400 nodos | Miles de nodos |
| **Complejidad** | Simple | Mayor planificación IP |
| **Acceso directo** | No (necesita NAT) | Sí (Pod accesible directamente) |
| **Uso recomendado** | Dev/test, clusters pequeños | Producción, integración con VNet |

### Fase 5: Monitorización (20 min)

#### Container Insights

Container Insights es la solución de monitorización nativa de AKS. Despliega un DaemonSet en cada nodo que recolecta:
- Métricas de CPU y memoria por Pod/contenedor
- Logs de stdout/stderr de todos los contenedores
- Métricas del nodo (disco, red, CPU del host)

```bash
# Habilitar Container Insights
az aks enable-addons \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --addons monitoring
```

---

## 🔧 Comandos Esenciales

### Básicos

```bash
# Crear cluster
az aks create --resource-group <rg> --name <name> --node-count 2

# Obtener credenciales
az aks get-credentials --resource-group <rg> --name <name>

# Ver estado del cluster
az aks show --resource-group <rg> --name <name> -o table

# Listar clusters
az aks list -o table

# Ver nodos
kubectl get nodes -o wide

# Ver versiones disponibles
az aks get-versions --location eastus -o table
```

### Intermedios

```bash
# Agregar node pool
az aks nodepool add --resource-group <rg> --cluster-name <name> \
  --name <pool> --node-count 3

# Escalar node pool
az aks nodepool scale --resource-group <rg> --cluster-name <name> \
  --name <pool> --node-count 5

# Habilitar autoescalado
az aks nodepool update --resource-group <rg> --cluster-name <name> \
  --name <pool> --enable-cluster-autoscaler \
  --min-count 1 --max-count 10

# Actualizar versión K8s
az aks upgrade --resource-group <rg> --name <name> \
  --kubernetes-version 1.29.0

# Ver consumo de recursos
kubectl top nodes
kubectl top pods -n <namespace>
```

### Troubleshooting

```bash
# Diagnosticar nodo NotReady
kubectl describe node <node-name>
kubectl get events --field-selector involvedObject.kind=Node

# Ver logs del sistema
kubectl logs -n kube-system -l component=kube-apiserver

# Verificar networking
kubectl run test --image=busybox --rm -it -- wget -qO- <service-url>

# Estado del cluster detallado
az aks show --resource-group <rg> --name <name> --query "powerState"

# Reiniciar un nodo problemático
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl uncordon <node>
```

---

## 📝 Cheat Sheet: YAML Snippets

### PodDisruptionBudget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: mi-app-pdb
spec:
  minAvailable: 2        # Mínimo 2 Pods siempre corriendo
  # o usar: maxUnavailable: 1  # Máximo 1 Pod caído
  selector:
    matchLabels:
      app: mi-app
```

### ResourceQuota para Namespace

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota-equipo
  namespace: equipo-backend
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "50"
```

### LimitRange con Defaults

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: equipo-backend
spec:
  limits:
  - type: Container
    default:
      cpu: "200m"
      memory: "128Mi"
    defaultRequest:
      cpu: "100m"
      memory: "64Mi"
    max:
      cpu: "2"
      memory: "2Gi"
```

### DaemonSet para Monitoreo

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: agente-logs
spec:
  selector:
    matchLabels:
      app: agente-logs
  template:
    metadata:
      labels:
        app: agente-logs
    spec:
      tolerations:
      - operator: Exists   # Corre en TODOS los nodos
      containers:
      - name: collector
        image: fluent/fluent-bit:latest
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

---

## ❗ Problemas Comunes y Soluciones

### 1. Error al crear cluster: "QuotaExceeded"

```
(QuotaExceeded) Operation could not be completed as it results in
exceeding approved Total Regional Cores quota.
```

**Causa**: Tu suscripción Azure no tiene suficiente cuota de CPU para la región.
**Solución**: Solicitar aumento de cuota en Azure Portal > Subscriptions > Usage + quotas, o usar una región diferente.

### 2. Nodos en estado NotReady

**Causa**: El nodo no puede comunicarse con el control plane.
**Diagnóstico**:
```bash
kubectl describe node <node-name>
# Buscar en "Conditions": MemoryPressure, DiskPressure, PIDPressure
```
**Solución**: Si es DiskPressure, limpiar imágenes no usadas. Si es NetworkUnavailable, verificar la VNet y NSG.

### 3. Pods en Pending por recursos insuficientes

**Causa**: No hay nodos con suficiente CPU/memoria disponible.
**Solución**:
```bash
# Verificar recursos disponibles
kubectl describe node <node> | grep -A5 "Allocated"
# Escalar el node pool
az aks nodepool scale --name <pool> --node-count <N+1>
```

### 4. Fallos de actualización del cluster

**Causa**: PDBs muy restrictivos que impiden drenar nodos.
**Solución**: Temporalmente ajustar PDBs antes del upgrade:
```bash
kubectl get pdb -A   # Ver PDBs existentes
# Verificar que ALLOWED DISRUPTIONS > 0
```

### 5. Container Insights no muestra datos

**Causa**: El addon de monitoring no está habilitado o el workspace de Log Analytics no está configurado.
**Solución**:
```bash
az aks enable-addons --addons monitoring \
  --resource-group <rg> --name <name>
```

### 6. kubectl no conecta al cluster

**Causa**: Las credenciales expiraron o el contexto apunta a otro cluster.
**Solución**:
```bash
# Regenerar credenciales
az aks get-credentials --resource-group <rg> --name <name> --overwrite-existing
# Verificar contexto actual
kubectl config current-context
```

---

## ✅ Checklist de Conceptos

- [ ] Sé explicar la diferencia entre Kubernetes self-managed y AKS
- [ ] Puedo crear un cluster AKS con `az aks create`
- [ ] Entiendo la diferencia entre system node pool y user node pool
- [ ] Sé configurar autoescalado de node pools
- [ ] Entiendo kubenet vs Azure CNI y cuándo usar cada uno
- [ ] Puedo configurar ResourceQuotas y LimitRanges
- [ ] Sé usar PodDisruptionBudgets para mantenimiento seguro
- [ ] Entiendo cómo funciona Container Insights (DaemonSet de monitoreo)
- [ ] Puedo actualizar la versión de Kubernetes del cluster
- [ ] Sé diagnosticar nodos en estado NotReady
- [ ] Puedo integrar AKS con Azure Container Registry

---

## 📝 Preguntas de Repaso

### 1. ¿Qué componente gestiona Azure en AKS y cuál gestionas tú?

<details>
<summary>Ver respuesta</summary>

**Azure gestiona**: El control plane completo (API Server, etcd, scheduler, controller manager), incluyendo backups de etcd, rotación de certificados TLS, actualizaciones del control plane, y alta disponibilidad.

**Tú gestionas**: Los worker nodes (node pools), tus aplicaciones (Deployments, Services), RBAC, Network Policies, almacenamiento, y monitorización de aplicaciones.

</details>

### 2. ¿Cuál es la diferencia entre un System Node Pool y un User Node Pool?

<details>
<summary>Ver respuesta</summary>

- **System Node Pool**: Obligatorio, ejecuta componentes del sistema de Kubernetes (CoreDNS, metrics-server, kube-proxy). Tiene el taint `CriticalAddonsOnly` que impide que Pods de usuario se programen ahí. Mínimo 1 nodo, recomendado 2-3.
- **User Node Pool**: Opcional, donde corren las aplicaciones de usuario. Puede escalar a 0 nodos. Puedes tener varios con diferentes configuraciones de VM (ej: uno para CPU, otro para GPU).

</details>

### 3. ¿Cuándo usarías kubenet vs Azure CNI?

<details>
<summary>Ver respuesta</summary>

- **kubenet**: Clusters pequeños, desarrollo/testing, cuando no necesitas integración directa con la VNet. Los Pods obtienen IPs de un rango interno y usan NAT para comunicarse fuera del nodo. Más simple pero menos escalable.
- **Azure CNI**: Producción, clusters grandes, cuando necesitas que los Pods sean accesibles directamente desde la VNet (ej: comunicación con VMs o bases de datos en la misma VNet). Cada Pod obtiene una IP real de la VNet.

</details>

### 4. ¿Qué es un PodDisruptionBudget y por qué es importante en AKS?

<details>
<summary>Ver respuesta</summary>

Un PDB garantiza que siempre haya un número mínimo de Pods corriendo durante operaciones de mantenimiento (como drain de nodos o actualizaciones de Kubernetes). En AKS es crítico porque durante los upgrades, Azure necesita reiniciar nodos uno por uno. Sin PDB, Azure podría apagar todos los Pods de tu aplicación simultáneamente.

Ejemplo: Si tienes 3 réplicas y un PDB con `minAvailable: 2`, AKS solo puede apagar 1 Pod a la vez durante el upgrade.

</details>

### 5. ¿Qué hace un DaemonSet y cuál es su uso principal en AKS?

<details>
<summary>Ver respuesta</summary>

Un DaemonSet garantiza que un Pod específico corra en todos los nodos del cluster (o un subconjunto). En AKS, Container Insights usa un DaemonSet para desplegar un agente de monitoreo (ama-logs) en cada nodo que recolecta métricas de CPU, memoria y logs de contenedores, y los envía a Azure Monitor/Log Analytics.

</details>

### 6. ¿Cómo limitas los recursos que un equipo puede usar en el cluster?

<details>
<summary>Ver respuesta</summary>

Usando una combinación de:
1. **Namespaces**: Aislar los recursos de cada equipo en su propio namespace.
2. **ResourceQuota**: Limitar el total de CPU, memoria y número de Pods que el namespace puede usar.
3. **LimitRange**: Establecer defaults y máximos para contenedores individuales.
4. **RBAC**: Controlar quién puede crear/modificar recursos en cada namespace.

</details>

### 7. ¿Qué pasa si un Pod excede la ResourceQuota del namespace?

<details>
<summary>Ver respuesta</summary>

Kubernetes rechaza la creación del Pod con un error `Forbidden: exceeded quota`. El Pod nunca llega a crearse. El mensaje de error detalla qué recurso se excedió, cuánto se pidió, cuánto se ha usado, y cuál es el límite.

</details>

### 8. ¿Cómo se actualiza la versión de Kubernetes en AKS?

<details>
<summary>Ver respuesta</summary>

```bash
# 1. Ver versiones disponibles
az aks get-upgrades --resource-group <rg> --name <name> -o table

# 2. Ejecutar el upgrade
az aks upgrade --resource-group <rg> --name <name> --kubernetes-version <nueva-version>
```

Azure actualiza primero el control plane y luego los nodos uno por uno (node surge upgrade), respetando los PodDisruptionBudgets.

</details>

### 9. ¿Qué es el autoescalado de cluster y cómo se configura?

<details>
<summary>Ver respuesta</summary>

El **Cluster Autoscaler** agrega o elimina nodos automáticamente según la demanda:
- **Scale up**: Cuando hay Pods en estado Pending porque no hay nodos con suficientes recursos.
- **Scale down**: Cuando un nodo tiene utilización baja (<50%) por más de 10 minutos y los Pods pueden reprogramarse en otros nodos.

```bash
az aks nodepool update --enable-cluster-autoscaler \
  --min-count 2 --max-count 10 \
  --resource-group <rg> --cluster-name <name> --name <pool>
```

</details>

### 10. ¿Cuál es la diferencia entre escalar Pods y escalar Nodos?

<details>
<summary>Ver respuesta</summary>

- **Escalar Pods** (Horizontal Pod Autoscaler / HPA): Ajusta el número de réplicas de un Deployment basándose en métricas (CPU, memoria, métricas custom). Usa los recursos existentes del cluster más eficientemente.
- **Escalar Nodos** (Cluster Autoscaler): Agrega o elimina VMs (nodos) al cluster. Aumenta la capacidad total del cluster.

Ambos trabajan juntos: el HPA escala los Pods, y cuando el cluster no tiene recursos suficientes para los nuevos Pods, el Cluster Autoscaler agrega más nodos.

</details>

---

## 🎓 Relevancia para Certificaciones

### CKA (Certified Kubernetes Administrator)
- **Cluster Management**: Dominio 25% del examen. Cubre gestión de clusters, node maintenance, upgrades.
- **PodDisruptionBudgets**: Pregunta frecuente sobre cómo garantizar disponibilidad durante mantenimiento.
- **ResourceQuota y LimitRange**: Configuración de namespaces multi-tenant.

### CKAD (Certified Kubernetes Application Developer)
- **ResourceQuota**: Entender cómo afecta al deployment de aplicaciones.
- **LimitRange**: Saber que puede asignar defaults automáticamente.
- **ConfigMaps**: Externalizar configuración de aplicaciones.

### AKS Specialty
- **az aks create/manage**: Comandos fundamentales del examen.
- **Node Pools**: System vs User, escalado, VM sizes.
- **Networking**: kubenet vs Azure CNI, Network Policies.
- **Container Insights**: Monitorización y alertas.

---

## 🔗 Siguiente Paso

Continúa con el **Módulo 02: RBAC y Control de Acceso** para aprender a controlar quién puede hacer qué dentro del cluster AKS. RBAC es fundamental para entornos multi-equipo donde diferentes personas necesitan diferentes niveles de acceso.
