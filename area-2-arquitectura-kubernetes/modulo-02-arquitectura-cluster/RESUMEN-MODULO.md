# 📝 RESUMEN: Arquitectura de Cluster Kubernetes

> **Guía de Estudio Rápida** - Componentes técnicos, comunicación, y troubleshooting del cluster

---

## 🎯 Conceptos Clave en 5 Minutos

### ¿Qué es la Arquitectura de K8s?
Kubernetes es un **sistema distribuido** compuesto por múltiples componentes que trabajan juntos. Se divide en dos partes principales:

```
┌─────────────────────────────────────────────────────────┐
│                    CLUSTER KUBERNETES                   │
├─────────────────────────────────────────────────────────┤
│  CONTROL PLANE (Cerebro)    │    WORKERS (Músculo)      │
│  ├─ API Server (6443)       │    ├─ kubelet             │
│  ├─ etcd (2379)             │    ├─ kube-proxy          │
│  ├─ Scheduler               │    └─ Container Runtime   │
│  └─ Controller Manager      │                           │
└─────────────────────────────────────────────────────────┘
```

### Analogía Simple
**Kubernetes = Hospital**
- **Control Plane** = Administración (recepción, gerencia, archivos)
- **Workers** = Áreas de atención (consultorios donde trabajan los médicos)
- **API Server** = Recepcionista (punto único de contacto)
- **etcd** = Sistema de archivos médicos (base de datos)
- **Scheduler** = Gerente asignando pacientes a consultorios
- **kubelet** = Enfermera en cada consultorio (ejecuta órdenes)
- **Pods** = Pacientes siendo atendidos

---

## 📊 Componentes del Control Plane

### 1. kube-apiserver (El Núcleo)

**Función**: Punto de entrada único para TODAS las operaciones del cluster.

**Características**:
- ✅ Expone API REST en puerto **6443** (HTTPS)
- ✅ Autenticación, autorización, validación
- ✅ **ÚNICO** componente que habla con etcd
- ✅ Stateless (puede escalar horizontalmente)

**Flujo típico**:
```
kubectl create pod → API Server → Valida YAML → Guarda en etcd → Responde OK
```

**Comandos útiles**:
```bash
# Ver logs del API Server
kubectl logs -n kube-system kube-apiserver-<master-node>

# Verificar puerto del API Server
netstat -tlnp | grep 6443

# Probar conectividad
curl -k https://<master-ip>:6443/version
```

---

### 2. etcd (La Memoria del Cluster)

**Función**: Base de datos clave-valor distribuida que almacena TODO el estado del cluster.

**Características**:
- ✅ Almacena configuración, secrets, estados de recursos
- ✅ Distribuido con algoritmo **Raft** (consenso)
- ✅ Puerto **2379** (cliente), **2380** (peers)
- ✅ Requiere **quorum** para funcionalidad (ej: 3 nodos = mínimo 2 activos)

**Datos que almacena**:
```
/registry/
├── pods/              # Estado de todos los pods
├── services/          # Definiciones de services
├── deployments/       # Configuraciones de deployments
├── secrets/           # Datos sensibles (encriptados)
└── configmaps/        # Variables de configuración
```

**Comandos útiles**:
```bash
# Ver miembros del cluster etcd (desde pod etcd)
ETCDCTL_API=3 etcdctl member list

# Backup de etcd
ETCDCTL_API=3 etcdctl snapshot save backup.db

# Ver todas las keys
ETCDCTL_API=3 etcdctl get / --prefix --keys-only
```

**⚠️ CRÍTICO**: Si pierdes etcd, pierdes TODO el cluster. Siempre hacer backups.

---

### 3. kube-scheduler (El Asignador)

**Función**: Decide en qué Worker Node debe ejecutarse cada nuevo Pod.

**Proceso de decisión**:
```
1. FILTRADO (Filtering)
   ├─ Elimina nodos sin recursos suficientes
   ├─ Elimina nodos con taints incompatibles
   └─ Elimina nodos que no cumplen nodeSelector

2. SCORING (Puntuación)
   ├─ Balance de recursos (CPU, RAM)
   ├─ Anti-afinidad (no poner todos en un nodo)
   └─ Topología (spread across zones)

3. BINDING
   └─ Actualiza etcd: "Pod X va al Nodo Y"
```

**Características**:
- ✅ Solo **asigna**, no ejecuta pods
- ✅ Lee continuamente etcd buscando pods sin nodo
- ✅ Considera: recursos, afinidad, taints, tolerations

**Ejemplo visual**:
```
Pod Nuevo → Scheduler busca nodo → Scoring:
  Nodo A: 85 puntos (70% RAM libre)
  Nodo B: 60 puntos (40% RAM libre)
  Nodo C: 30 puntos (10% RAM libre)
→ Scheduler asigna al Nodo A
```

**Comandos útiles**:
```bash
# Ver eventos del scheduler
kubectl get events --sort-by='.metadata.creationTimestamp'

# Ver logs del scheduler
kubectl logs -n kube-system kube-scheduler-<master-node>
```

---

### 4. kube-controller-manager (El Vigilante)

**Función**: Ejecuta múltiples "controllers" que vigilan el estado deseado vs real.

**Controllers principales**:

| Controller | Función | Ejemplo |
|-----------|---------|---------|
| **Node Controller** | Detecta nodos caídos | Si nodo no responde 5 min → marca pods como terminados |
| **Replication Controller** | Mantiene réplicas correctas | Si hay 2/3 pods → crea 1 más |
| **Endpoints Controller** | Actualiza endpoints de Services | Si pod nuevo → añade IP a Service |
| **ServiceAccount Controller** | Crea ServiceAccounts para namespaces | Namespace nuevo → crea SA "default" |

**Loop de control**:
```
1. Lee estado DESEADO de etcd (ej: Deployment con 3 réplicas)
2. Lee estado REAL del cluster (ej: solo 2 pods running)
3. ACTÚA para reconciliar (crea 1 pod más)
4. Espera 5-10 segundos
5. Repite infinitamente
```

**Comandos útiles**:
```bash
# Ver logs de controllers
kubectl logs -n kube-system kube-controller-manager-<master-node>

# Ver qué controllers están activos
kubectl get componentstatuses
```

---

## 🖥️ Componentes de Worker Nodes

### 1. kubelet (El Ejecutor)

**Función**: Agente en cada Worker que ejecuta y supervisa los Pods.

**Responsabilidades**:
- ✅ Registra el nodo en el cluster
- ✅ Lee PodSpecs asignados a su nodo (desde API Server)
- ✅ Ejecuta contenedores usando el container runtime
- ✅ Monitorea salud de pods (health checks)
- ✅ Reporta estado al API Server

**Flujo de trabajo**:
```
1. kubelet consulta API Server cada 10s: "¿Hay pods para mí?"
2. API Server responde: "Sí, ejecuta pod X con imagen nginx:1.21"
3. kubelet descarga imagen (si no existe)
4. kubelet dice al runtime: "Crea contenedor con esta spec"
5. kubelet monitorea contenedor
6. kubelet reporta estado a API Server
```

**Características**:
- ✅ Corre como **systemd service** (no como pod)
- ✅ Puerto **10250** (API del kubelet)
- ✅ Ejecuta health checks (liveness, readiness, startup)

**Comandos útiles**:
```bash
# Ver estado del kubelet
systemctl status kubelet

# Ver logs del kubelet
journalctl -u kubelet -f

# Ver configuración del kubelet
kubectl get --raw /api/v1/nodes/<node-name>/proxy/configz
```

---

### 2. kube-proxy (El Enrutador)

**Función**: Implementa las reglas de red para que los Services funcionen.

**Cómo funciona**:
```
Service "mi-app" = ClusterIP 10.96.0.50:80
Pods backend:
  - Pod A: 192.168.1.10:8080
  - Pod B: 192.168.1.11:8080
  - Pod C: 192.168.1.12:8080

kube-proxy crea reglas iptables:
  "Si alguien intenta conectar a 10.96.0.50:80 
   → redirige a uno de los pods aleatoriamente"
```

**Modos de operación**:

| Modo | Descripción | Performance |
|------|-------------|-------------|
| **iptables** | Reglas de firewall (default) | ⭐⭐⭐ Bueno |
| **IPVS** | Balanceo avanzado | ⭐⭐⭐⭐⭐ Excelente |
| **userspace** | Proxy en espacio de usuario | ⭐ Lento (legacy) |

**Comandos útiles**:
```bash
# Ver reglas iptables creadas por kube-proxy
sudo iptables-save | grep <service-name>

# Ver logs de kube-proxy
kubectl logs -n kube-system kube-proxy-<pod-id>

# Ver modo de kube-proxy
kubectl logs -n kube-system kube-proxy-<pod> | grep "Using"
```

---

### 3. Container Runtime (El Motor)

**Función**: Software que ejecuta contenedores (Docker, containerd, CRI-O).

**Evolución histórica**:
```
2014-2020: Docker (runtime + builder + registry)
      ↓
2020+: containerd (solo runtime, más ligero)
      ↓
Alternativas: CRI-O (Red Hat), gVisor (Google)
```

**Interface CRI** (Container Runtime Interface):
- ✅ Estándar para que kubelet hable con cualquier runtime
- ✅ Operaciones: PullImage, CreateContainer, StartContainer, StopContainer

**Comandos útiles**:
```bash
# Ver runtime configurado
kubectl get nodes -o wide
# Columna CONTAINER-RUNTIME

# Con Docker
docker ps

# Con containerd
crictl ps

# Ver imágenes descargadas
crictl images
```

---

## 🔄 Flujo de Comunicación Completo

### Ejemplo: `kubectl create deployment nginx --image=nginx:1.21 --replicas=3`

```
PASO 1: kubectl → API Server (puerto 6443)
  ├─ kubectl autentica con certificado
  ├─ API Server valida YAML
  └─ API Server guarda Deployment en etcd

PASO 2: Controller Manager detecta cambio
  ├─ Deployment Controller lee: "Necesito 3 réplicas"
  ├─ Crea 3 PodSpecs
  └─ API Server guarda Pods en etcd (estado: Pending)

PASO 3: Scheduler asigna Pods a Nodos
  ├─ Lee pods con estado "Pending"
  ├─ Scoring de nodos (recursos disponibles)
  ├─ Asigna: Pod1→NodeA, Pod2→NodeB, Pod3→NodeC
  └─ API Server actualiza etcd

PASO 4: kubelet en cada nodo ejecuta
  ├─ NodeA: kubelet detecta Pod1 asignado
  ├─ Descarga imagen nginx:1.21
  ├─ Dice a containerd: "Crea contenedor"
  └─ Reporta a API Server: "Pod1 Running"

PASO 5: kube-proxy configura networking
  ├─ Detecta nuevo pod con label app=nginx
  ├─ Actualiza reglas iptables
  └─ Service puede enviar tráfico al pod

RESULTADO: 3 pods nginx ejecutándose en 3 nodos diferentes
```

---

## 🏢 Alta Disponibilidad (HA)

### Arquitectura Multi-Master

**Problema**: Si el Control Plane falla, el cluster queda inoperable.

**Solución**: Múltiples Control Planes con Load Balancer.

```
                    ┌──────────────┐
                    │Load Balancer │ (puerto 6443)
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
      ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
      │ Master1 │     │ Master2 │     │ Master3 │
      │ API:6443│     │ API:6443│     │ API:6443│
      └────┬────┘     └────┬────┘     └────┬────┘
           │               │               │
           └───────────────┼───────────────┘
                           │
                    ┌──────▼───────┐
                    │ etcd Cluster │ (quorum: 2/3)
                    │ ┌─┐ ┌─┐ ┌─┐  │
                    │ │1│ │2│ │3│  │
                    │ └─┘ └─┘ └─┘  │
                    └──────────────┘
```

**Configuración típica**:

| Componente | Instancias | Razón |
|-----------|------------|-------|
| **API Server** | 3+ | Load balancer distribuye carga |
| **etcd** | 3, 5, 7 (impar) | Quorum requiere mayoría |
| **Scheduler** | 3+ | Leader election (solo 1 activo) |
| **Controller Manager** | 3+ | Leader election (solo 1 activo) |

**Leader Election**:
- Scheduler y Controller Manager usan algoritmo de elección
- Solo UNO está activo (líder)
- Si líder falla → otro toma el liderazgo en ~15s

**Comandos útiles**:
```bash
# Ver cuál es el líder actual
kubectl get endpoints kube-scheduler -n kube-system -o yaml

# Ver miembros de etcd
kubectl exec -n kube-system etcd-master1 -- etcdctl member list
```

---

## 🧩 Addons Esenciales

### CoreDNS (DNS Interno)

**Función**: Resuelve nombres de Services a IPs dentro del cluster.

**Ejemplo**:
```yaml
# Service llamado "mi-app" en namespace "produccion"
# Se puede acceder como:
mi-app.produccion.svc.cluster.local → 10.96.0.50
```

**Comandos útiles**:
```bash
# Ver pods de CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Probar resolución DNS desde pod
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes
```

---

### Metrics Server (Métricas)

**Función**: Recolecta métricas de CPU/RAM de pods y nodos.

**Habilita comandos**:
```bash
kubectl top nodes       # Uso de CPU/RAM por nodo
kubectl top pods        # Uso de CPU/RAM por pod
```

**Instalación**:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

### Dashboard (UI Web)

**Función**: Interfaz gráfica para gestionar cluster (opcional).

**Acceso**:
```bash
kubectl proxy
# Abrir: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## 🛠️ Comandos de Diagnóstico Esencial

### Verificar Salud del Cluster

```bash
# Estado de componentes (deprecado pero útil)
kubectl get componentstatuses
# NAME                 STATUS    MESSAGE             ERROR
# scheduler            Healthy   ok
# controller-manager   Healthy   ok
# etcd-0               Healthy   {"health":"true"}

# Ver nodos y su estado
kubectl get nodes
# NAME      STATUS   ROLES           AGE   VERSION
# master1   Ready    control-plane   10d   v1.28.0
# worker1   Ready    <none>          10d   v1.28.0
# worker2   Ready    <none>          10d   v1.28.0

# Ver pods del sistema
kubectl get pods -n kube-system
# Buscar: Running (todos deberían estar running)

# Ver eventos del cluster (errores recientes)
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

---

### Diagnosticar Control Plane

```bash
# Logs del API Server
kubectl logs -n kube-system kube-apiserver-<master-node> --tail=100

# Logs del Scheduler
kubectl logs -n kube-system kube-scheduler-<master-node> --tail=100

# Logs del Controller Manager
kubectl logs -n kube-system kube-controller-manager-<master-node> --tail=100

# Verificar etcd (desde pod de etcd)
kubectl exec -n kube-system etcd-master1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

---

### Diagnosticar Worker Nodes

```bash
# Ver detalles de un nodo (condiciones, capacidad, info)
kubectl describe node <node-name>

# Logs del kubelet (en el nodo directamente)
ssh <node-name>
journalctl -u kubelet -f

# Ver recursos usados en nodo
kubectl top node <node-name>

# Ver qué pods están en un nodo
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node-name>
```

---

## 📋 Checklist de Conceptos Clave

### Control Plane
- [ ] Sé que API Server es el ÚNICO punto de entrada
- [ ] Entiendo que etcd almacena TODO el estado del cluster
- [ ] Puedo explicar qué hace el Scheduler (asignar pods a nodos)
- [ ] Comprendo el loop de control de Controller Manager
- [ ] Sé que múltiples masters requieren Load Balancer

### Worker Nodes
- [ ] Entiendo que kubelet ejecuta pods en cada nodo
- [ ] Sé que kube-proxy maneja las reglas de red
- [ ] Conozco la diferencia entre Docker y containerd
- [ ] Puedo verificar el estado de kubelet con `systemctl status kubelet`

### Comunicación
- [ ] Puedo trazar el flujo de `kubectl create deployment`
- [ ] Entiendo cómo interactúan todos los componentes
- [ ] Sé que SOLO API Server habla con etcd

### Alta Disponibilidad
- [ ] Comprendo por qué etcd necesita quorum (mayoría)
- [ ] Entiendo leader election en Scheduler y Controllers
- [ ] Sé que API Server puede escalar horizontalmente

### Troubleshooting
- [ ] Puedo verificar salud con `kubectl get nodes`
- [ ] Sé cómo ver logs de componentes del Control Plane
- [ ] Puedo diagnosticar problemas de kubelet con `journalctl`

---

## ❓ Preguntas de Repaso

### Conceptuales

1. **¿Por qué API Server es el único componente que habla con etcd?**
   <details>
   <summary>Ver respuesta</summary>
   
   - **Seguridad**: Un único punto de acceso es más fácil de proteger
   - **Consistencia**: API Server valida y serializa todos los cambios
   - **Auditoría**: Todos los cambios pasan por un punto central
   - **Encriptación**: API Server puede encriptar datos antes de guardarlos
   </details>

2. **¿Qué sucede si etcd falla completamente?**
   <details>
   <summary>Ver respuesta</summary>
   
   - **Pods existentes siguen ejecutándose** (kubelet los mantiene)
   - **NO puedes crear/modificar recursos** (API Server no puede guardar)
   - **NO puedes ver estado del cluster** (kubectl get no funciona)
   - **Scheduler y Controllers se detienen** (no pueden leer/escribir estado)
   - **SOLUCIÓN**: Restaurar etcd desde backup
   </details>

3. **¿Por qué se recomienda un número impar de nodos etcd?**
   <details>
   <summary>Ver respuesta</summary>
   
   - **Quorum**: Necesitas mayoría para tomar decisiones
   - Con 3 nodos: toleras 1 fallo (2/3 = mayoría)
   - Con 4 nodos: toleras 1 fallo (3/4 = mayoría) ← mismo que con 3
   - Con 5 nodos: toleras 2 fallos (3/5 = mayoría)
   - Con 6 nodos: toleras 2 fallos (4/6 = mayoría) ← mismo que con 5
   - **Conclusión**: 4 y 6 no aportan ventaja sobre 3 y 5
   </details>

---

### Técnicas

4. **¿Cómo verificas que el Scheduler está funcionando?**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Opción 1: Ver estado de componentes
   kubectl get componentstatuses
   
   # Opción 2: Ver logs del scheduler
   kubectl logs -n kube-system kube-scheduler-<master-node>
   
   # Opción 3: Crear pod y ver si se asigna
   kubectl run test-pod --image=nginx
   kubectl get pod test-pod -o wide
   # Si tiene NODO asignado → Scheduler funciona
   
   # Opción 4: Ver eventos
   kubectl get events --sort-by='.metadata.creationTimestamp'
   # Buscar: "Successfully assigned..."
   ```
   </details>

5. **¿Cómo determinas qué container runtime está usando tu cluster?**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Opción 1: Ver en información de nodos
   kubectl get nodes -o wide
   # Columna CONTAINER-RUNTIME
   
   # Opción 2: Describe del nodo
   kubectl describe node <node-name> | grep "Container Runtime"
   
   # Opción 3: Desde el nodo directamente
   ssh <node>
   crictl version  # Si usa containerd/CRI-O
   docker version  # Si usa Docker
   ```
   </details>

6. **¿Cómo verificas que kube-proxy está creando reglas correctamente?**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Ver logs de kube-proxy
   kubectl logs -n kube-system kube-proxy-<pod-id>
   
   # Desde un worker node, ver reglas iptables
   ssh <node>
   sudo iptables-save | grep <service-name>
   
   # Ver modo de operación
   kubectl logs -n kube-system kube-proxy-<pod> | grep "Using"
   # "Using iptables Proxier" o "Using ipvs Proxier"
   
   # Probar conectividad a un Service
   kubectl run test --image=busybox -it --rm --restart=Never -- wget -O- http://<service-name>
   ```
   </details>

---

### Troubleshooting

7. **Un nodo aparece como "NotReady". ¿Cómo diagnosticas?**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Paso 1: Ver detalles del nodo
   kubectl describe node <node-name>
   # Buscar sección "Conditions" → razón del NotReady
   
   # Paso 2: Verificar kubelet en el nodo
   ssh <node-name>
   systemctl status kubelet
   journalctl -u kubelet -f
   
   # Paso 3: Verificar recursos del nodo
   df -h          # Espacio en disco
   free -h        # Memoria
   top            # CPU
   
   # Paso 4: Verificar conectividad con API Server
   telnet <master-ip> 6443
   
   # Paso 5: Reiniciar kubelet
   sudo systemctl restart kubelet
   ```
   </details>

8. **Creaste un Deployment pero los pods no se ejecutan. ¿Qué revisas?**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Paso 1: Ver estado de pods
   kubectl get pods
   # Estados posibles: Pending, ImagePullBackOff, CrashLoopBackOff, etc.
   
   # Paso 2: Describe del pod
   kubectl describe pod <pod-name>
   # Buscar "Events" al final
   
   # Paso 3: Si está Pending
   kubectl get events --sort-by='.metadata.creationTimestamp'
   # Puede ser: sin recursos, sin nodos, taints
   
   # Paso 4: Ver recursos disponibles
   kubectl top nodes
   kubectl describe nodes | grep -A 5 "Allocated resources"
   
   # Paso 5: Ver logs del Scheduler
   kubectl logs -n kube-system kube-scheduler-<master-node>
   ```
   </details>

9. **¿Cómo sabes si etcd está saludable en un cluster HA?**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Paso 1: Ver pods de etcd
   kubectl get pods -n kube-system -l component=etcd
   # Todos deberían estar "Running"
   
   # Paso 2: Verificar salud de endpoints
   kubectl exec -n kube-system etcd-master1 -- etcdctl \
     --endpoints=https://127.0.0.1:2379 \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key \
     endpoint health
   
   # Paso 3: Ver miembros del cluster
   kubectl exec -n kube-system etcd-master1 -- etcdctl member list
   # Todos deberían aparecer
   
   # Paso 4: Verificar que hay quorum
   # Con 3 nodos, mínimo 2 deben estar "healthy"
   ```
   </details>

---

### Profesionales

10. **¿Cuándo necesitas realmente un cluster HA?**
    <details>
    <summary>Ver respuesta</summary>
    
    **SÍ necesitas HA**:
    - ✅ Producción con SLA crítico (99.9%+)
    - ✅ Aplicaciones 24/7 sin downtime permitido
    - ✅ Múltiples equipos dependiendo del cluster
    - ✅ Regulaciones de compliance (finanzas, salud)
    
    **NO necesitas HA**:
    - ❌ Entorno de desarrollo/testing
    - ❌ Demos o PoCs
    - ❌ Minikube/K3s para aprendizaje
    - ❌ Clusters efímeros (recreables fácilmente)
    
    **Trade-offs**:
    - Costo: 3-5x más infraestructura
    - Complejidad: Más difícil de mantener
    - Networking: Load balancers adicionales
    </details>

11. **¿Qué componentes puedes escalar horizontalmente?**
    <details>
    <summary>Ver respuesta</summary>
    
    | Componente | Escalable | Notas |
    |-----------|-----------|-------|
    | **API Server** | ✅ SÍ | Stateless, usa Load Balancer |
    | **etcd** | ⚠️ SÍ | Quorum, solo números impares |
    | **Scheduler** | ⚠️ Parcial | Leader election, solo 1 activo |
    | **Controller Mgr** | ⚠️ Parcial | Leader election, solo 1 activo |
    | **kubelet** | ❌ NO | 1 por nodo (no aplica) |
    | **kube-proxy** | ❌ NO | 1 por nodo (no aplica) |
    | **Worker Nodes** | ✅ SÍ | Añade cuantos necesites |
    </details>

12. **¿Cómo decides el tamaño del Control Plane?**
    <details>
    <summary>Ver respuesta</summary>
    
    **Reglas generales**:
    
    | Tamaño Cluster | Control Plane | etcd | Razón |
    |---------------|---------------|------|-------|
    | < 10 nodos | 1 master | 1 nodo | Dev/testing |
    | 10-100 nodos | 3 masters | 3 nodos | Producción típica |
    | 100-1000 nodos | 5 masters | 5 nodos | Alta escala |
    | 1000+ nodos | 7+ masters | 7 nodos | Enterprise |
    
    **Recursos mínimos por master**:
    - CPU: 2-4 cores
    - RAM: 4-8 GB
    - Disco: 50-100 GB SSD (para etcd)
    - Red: 1 Gbps
    
    **Factores a considerar**:
    - Número de objetos (pods, services, etc.)
    - Frecuencia de cambios (deployments por minuto)
    - Uso de admission webhooks (aumentan carga en API)
    </details>

---

## 🎓 Para Certificaciones

### CKA (Certified Kubernetes Administrator)

**Temas de este módulo en el examen**:
- ✅ Arquitectura de cluster (10-15% del examen)
- ✅ Instalación y configuración de componentes
- ✅ Backup y restore de etcd
- ✅ Troubleshooting de cluster

**Comandos que DEBES saber**:
```bash
# Backup de etcd
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Restore de etcd
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restore

# Ver componentes
kubectl get componentstatuses
kubectl get nodes
kubectl get pods -n kube-system

# Diagnosticar nodo NotReady
kubectl describe node <node-name>
journalctl -u kubelet -f
```

---

### CKAD (Certified Kubernetes Application Developer)

**Relevancia para CKAD**: Baja directa, alta contextual

- No te preguntarán arquitectura detallada
- Pero ayuda entender:
  - Por qué tu pod no se ejecuta (Scheduler)
  - Cómo funcionan Services (kube-proxy)
  - Por qué necesitas crear resources en namespaces (API Server)

**Enfócate en**: Módulos 04-18 (aplicaciones, no infraestructura)

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [Kubernetes Architecture](https://kubernetes.io/docs/concepts/architecture/)
- [Control Plane Components](https://kubernetes.io/docs/concepts/overview/components/#control-plane-components)
- [Node Components](https://kubernetes.io/docs/concepts/overview/components/#node-components)

### Diagramas Interactivos
- [Kubernetes Architecture Diagram](https://kubernetes.io/docs/concepts/architecture/)
- [Picturing Kubernetes](https://azure.microsoft.com/en-us/resources/videos/picturing-kubernetes/)

### Herramientas de Visualización
- **K9s**: Terminal UI para clusters
- **Lens**: IDE gráfico para Kubernetes
- **kube-ops-view**: Vista en tiempo real del cluster

---

## 🎯 Siguiente Paso

Ahora que entiendes CÓMO funciona Kubernetes internamente:

➡️ **Módulo 03: Instalación de Minikube** - Verás estos componentes en acción

Aprenderás a:
- Instalar Minikube (cluster local)
- Verificar componentes del Control Plane
- Interactuar con el cluster vía kubectl
- Crear tus primeros recursos

**Conexión**: Módulo 02 (teoría) + Módulo 03 (práctica) = Base sólida para el resto del curso.

---

**📊 Estadísticas de este módulo**:
- Componentes Control Plane: 4 principales
- Componentes Worker: 3 principales
- Addons esenciales: 3 (CoreDNS, Metrics Server, Dashboard)
- Puertos clave: 6443 (API), 2379/2380 (etcd), 10250 (kubelet)
- Comandos de diagnóstico: 15+ cubiertos

**✅ Checklist**: ¿Puedes explicar el flujo completo de `kubectl create deployment` sin mirar las notas? Si sí, estás listo para continuar.
