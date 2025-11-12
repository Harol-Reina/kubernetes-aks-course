# Arquitectura de Kubernetes - Diagrama Interactivo

Este documento proporciona diagramas visuales detallados de la arquitectura de Kubernetes, explicando cada componente y cómo interactúan.

## Tabla de Contenidos

1. [Arquitectura General](#arquitectura-general)
2. [Control Plane en Detalle](#control-plane-en-detalle)
3. [Worker Nodes en Detalle](#worker-nodes-en-detalle)
4. [Flujo de Creación de un Pod](#flujo-de-creación-de-un-pod)
5. [Flujo de Networking](#flujo-de-networking)

---

## Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         KUBERNETES CLUSTER                              │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │                    CONTROL PLANE                              │    │
│  │              (Cerebro del Cluster)                            │    │
│  │                                                               │    │
│  │  ┌──────────────────┐  ┌──────────────────┐                 │    │
│  │  │   API Server     │  │   Scheduler      │                 │    │
│  │  ├──────────────────┤  ├──────────────────┤                 │    │
│  │  │ • Puerto: 6443   │  │ • Asigna pods    │                 │    │
│  │  │ • REST API       │  │ • Considera CPU  │                 │    │
│  │  │ • Autenticación  │  │ • Considera RAM  │                 │    │
│  │  │ • Validación     │  │ • Afinidades     │                 │    │
│  │  └────────┬─────────┘  └──────────────────┘                 │    │
│  │           │                                                   │    │
│  │  ┌────────▼─────────┐  ┌──────────────────┐                 │    │
│  │  │      etcd        │  │ Controller Mgr   │                 │    │
│  │  ├──────────────────┤  ├──────────────────┤                 │    │
│  │  │ • Key-Value DB   │  │ • Replication    │                 │    │
│  │  │ • Cluster State  │  │ • Node           │                 │    │
│  │  │ • Configuración  │  │ • Endpoints      │                 │    │
│  │  │ • Distribuido    │  │ • ServiceAccount │                 │    │
│  │  └──────────────────┘  └──────────────────┘                 │    │
│  └───────────────────────────────┬───────────────────────────────┘    │
│                                  │                                    │
│                       ┌──────────┼──────────┐                        │
│                       │          │          │                         │
│  ┌────────────────────▼───┐  ┌──▼──────────▼────┐  ┌───────────┐   │
│  │   WORKER NODE 1        │  │  WORKER NODE 2    │  │  NODE 3   │   │
│  │  (donde corren apps)   │  │ (donde corren apps│  │  ...      │   │
│  │                        │  │                   │  │           │   │
│  │  ┌──────────────────┐ │  │  ┌──────────────┐ │  └───────────┘   │
│  │  │     kubelet      │ │  │  │   kubelet    │ │                   │
│  │  │  (agente nodo)   │ │  │  │ (agente nodo)│ │                   │
│  │  └────────┬─────────┘ │  │  └──────┬───────┘ │                   │
│  │           │            │  │         │         │                   │
│  │  ┌────────▼─────────┐ │  │  ┌──────▼───────┐ │                   │
│  │  │ Container Runtime│ │  │  │  Container   │ │                   │
│  │  │  (Docker/cri-o)  │ │  │  │   Runtime    │ │                   │
│  │  └────────┬─────────┘ │  │  └──────┬───────┘ │                   │
│  │           │            │  │         │         │                   │
│  │  ┌────────▼─────────┐ │  │  ┌──────▼───────┐ │                   │
│  │  │   kube-proxy     │ │  │  │  kube-proxy  │ │                   │
│  │  │ (red networking) │ │  │  │(red network) │ │                   │
│  │  └──────────────────┘ │  │  └──────────────┘ │                   │
│  │                        │  │                   │                   │
│  │  ┌─────────────────┐  │  │  ┌──────────────┐ │                   │
│  │  │  POD 1          │  │  │  │  POD 3       │ │                   │
│  │  │ ┌─────────────┐ │  │  │  │ ┌──────────┐ │ │                   │
│  │  │ │ Container 1 │ │  │  │  │ │Container │ │ │                   │
│  │  │ └─────────────┘ │  │  │  │ └──────────┘ │ │                   │
│  │  └─────────────────┘  │  │  └──────────────┘ │                   │
│  │  ┌─────────────────┐  │  │  ┌──────────────┐ │                   │
│  │  │  POD 2          │  │  │  │  POD 4       │ │                   │
│  │  │ ┌─────────────┐ │  │  │  │ ┌──────────┐ │ │                   │
│  │  │ │ Container 2 │ │  │  │  │ │Container │ │ │                   │
│  │  │ └─────────────┘ │  │  │  │ └──────────┘ │ │                   │
│  │  └─────────────────┘  │  │  └──────────────┘ │                   │
│  └────────────────────────┘  └───────────────────┘                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Control Plane en Detalle

El Control Plane es el conjunto de componentes que controlan el cluster. Toma decisiones globales (por ejemplo, scheduling) y detecta y responde a eventos del cluster.

### Componentes y Responsabilidades

```
┌──────────────────────────────────────────────────────────────┐
│                    API SERVER (kube-apiserver)               │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Rol: Punto de entrada único para todas las operaciones     │
│                                                              │
│  Responsabilidades:                                          │
│  ✓ Expone API REST de Kubernetes (puerto 6443)             │
│  ✓ Valida y procesa peticiones                              │
│  ✓ Autenticación y autorización (RBAC)                      │
│  ✓ Único componente que lee/escribe en etcd                 │
│  ✓ Punto de comunicación entre componentes                  │
│                                                              │
│  Ejemplo de petición:                                        │
│  kubectl get pods → HTTP GET /api/v1/pods                   │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                         etcd                                 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Rol: Base de datos distribuida (clave-valor)               │
│                                                              │
│  Almacena:                                                   │
│  • Estado del cluster (qué pods existen)                    │
│  • Configuración (deployments, services, secrets)           │
│  • Metadatos (labels, annotations)                          │
│                                                              │
│  Características:                                            │
│  ✓ Altamente disponible (múltiples réplicas)               │
│  ✓ Consistencia fuerte (RAFT consensus)                     │
│  ✓ Solo API Server puede acceder directamente               │
│  ✓ Backups críticos para disaster recovery                  │
│                                                              │
│  Ejemplo de datos:                                           │
│  /registry/pods/default/nginx-pod → {metadata, spec, ...}  │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                      SCHEDULER (kube-scheduler)              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Rol: Asignar pods a nodos (scheduling)                     │
│                                                              │
│  Proceso de decisión:                                        │
│  1. Detecta nuevos pods sin nodo asignado                   │
│  2. Filtra nodos que NO cumplen requisitos:                 │
│     ✗ Recursos insuficientes (CPU/RAM)                      │
│     ✗ NodeSelector no coincide                              │
│     ✗ Taints que el pod no tolera                           │
│  3. Puntúa nodos que SÍ cumplen:                            │
│     • Balance de recursos                                    │
│     • Afinidades y anti-afinidades                          │
│     • Distribución de pods                                   │
│  4. Selecciona nodo con mayor puntuación                    │
│  5. Actualiza etcd con asignación                           │
│                                                              │
│  Ejemplo:                                                    │
│  Pod necesita 2GB RAM:                                       │
│  Node1: 1GB libre ✗                                         │
│  Node2: 4GB libre ✓ (puntuación: 70)                       │
│  Node3: 8GB libre ✓ (puntuación: 90) ← ELEGIDO             │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│            CONTROLLER MANAGER (kube-controller-manager)      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Rol: Ejecutar controladores que regulan el estado          │
│                                                              │
│  Loop de control: Estado Actual → Estado Deseado            │
│                                                              │
│  Controladores principales:                                  │
│                                                              │
│  ┌──────────────────────────────────────────────┐          │
│  │ Node Controller                               │          │
│  │ • Detecta nodos caídos (heartbeat)           │          │
│  │ • Evacua pods de nodos no saludables         │          │
│  │ • Actualiza estado de nodos                  │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  ┌──────────────────────────────────────────────┐          │
│  │ Replication Controller                        │          │
│  │ • Mantiene número deseado de réplicas        │          │
│  │ • Crea pods si hay menos de lo deseado       │          │
│  │ • Elimina pods si hay más de lo deseado      │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  ┌──────────────────────────────────────────────┐          │
│  │ Endpoint Controller                           │          │
│  │ • Conecta Services con Pods                  │          │
│  │ • Actualiza endpoints cuando pods cambian    │          │
│  │ • Gestiona balanceo de carga                 │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  ┌──────────────────────────────────────────────┐          │
│  │ ServiceAccount Controller                     │          │
│  │ • Crea ServiceAccounts por defecto           │          │
│  │ • Genera tokens para autenticación           │          │
│  │ • Gestiona secretos de API                   │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Worker Nodes en Detalle

Los Worker Nodes son las máquinas donde realmente corren tus aplicaciones (Pods).

```
┌──────────────────────────────────────────────────────────────┐
│                    WORKER NODE                               │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │               kubelet                                   │ │
│  ├────────────────────────────────────────────────────────┤ │
│  │                                                         │ │
│  │  Rol: Agente que corre en cada nodo                    │ │
│  │                                                         │ │
│  │  Responsabilidades:                                     │ │
│  │  ✓ Registra el nodo en el cluster                     │ │
│  │  ✓ Monitorea pods asignados a su nodo                 │ │
│  │  ✓ Asegura que contenedores estén corriendo           │ │
│  │  ✓ Reporta estado al API Server                       │ │
│  │  ✓ Ejecuta health checks (liveness/readiness)         │ │
│  │  ✓ Monta volúmenes para pods                          │ │
│  │                                                         │ │
│  │  Loop principal:                                        │ │
│  │  1. Consulta API Server: ¿pods para este nodo?        │ │
│  │  2. Compara con pods corriendo actualmente            │ │
│  │  3. Inicia pods nuevos via Container Runtime          │ │
│  │  4. Detiene pods que ya no deberían correr            │ │
│  │  5. Reporta estado de salud                           │ │
│  │  6. Repite cada 10 segundos                           │ │
│  │                                                         │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │          Container Runtime (Docker/containerd)         │ │
│  ├────────────────────────────────────────────────────────┤ │
│  │                                                         │ │
│  │  Rol: Software que ejecuta contenedores                │ │
│  │                                                         │ │
│  │  Implementaciones:                                      │ │
│  │  • Docker (tradicional)                                │ │
│  │  • containerd (lightweight, recomendado)              │ │
│  │  • CRI-O (optimizado para Kubernetes)                 │ │
│  │                                                         │ │
│  │  Tareas:                                                │ │
│  │  ✓ Pull de imágenes desde registry                    │ │
│  │  ✓ Crear y iniciar contenedores                       │ │
│  │  ✓ Detener y eliminar contenedores                    │ │
│  │  ✓ Gestionar ciclo de vida de contenedores            │ │
│  │  ✓ Exponer logs de contenedores                       │ │
│  │                                                         │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                kube-proxy                              │ │
│  ├────────────────────────────────────────────────────────┤ │
│  │                                                         │ │
│  │  Rol: Proxy de red para Services                      │ │
│  │                                                         │ │
│  │  Modos de operación:                                    │ │
│  │  • iptables (por defecto): Reglas firewall            │ │
│  │  • IPVS: Más eficiente para muchos servicios          │ │
│  │  • userspace: Modo legacy                             │ │
│  │                                                         │ │
│  │  Función principal:                                     │ │
│  │  Traduce: Service IP → Pod IPs reales                 │ │
│  │                                                         │ │
│  │  Ejemplo:                                               │ │
│  │  Service "nginx" → 10.96.0.50:80                      │ │
│  │  Pod 1 → 192.168.1.10:80                              │ │
│  │  Pod 2 → 192.168.1.11:80                              │ │
│  │  Pod 3 → 192.168.1.12:80                              │ │
│  │                                                         │ │
│  │  kube-proxy crea reglas para balancear:                │ │
│  │  10.96.0.50:80 → {192.168.1.10, .11, .12} (round-robin│ │
│  │                                                         │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

---

## Flujo de Creación de un Pod

Veamos paso a paso qué sucede cuando ejecutas `kubectl create -f pod.yaml`:

```
┌─────────────────────────────────────────────────────────────────────┐
│  PASO 1: Usuario ejecuta comando                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  $ kubectl create -f pod.yaml                                       │
│                                                                     │
│  kubectl lee el archivo YAML y envía petición HTTP POST            │
│  a API Server (puerto 6443)                                         │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PASO 2: API Server recibe y valida                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  API Server hace:                                                   │
│  1. Autenticación: ¿Quién eres? (usuario/service account)         │
│  2. Autorización: ¿Puedes crear pods? (RBAC)                      │
│  3. Validación: ¿El YAML es correcto?                             │
│     • Sintaxis correcta                                             │
│     • Campos obligatorios presentes                                 │
│     • Valores válidos                                               │
│  4. Admission Control: Plugins adicionales                         │
│     • Establecer valores por defecto                                │
│     • Inyectar sidecars                                             │
│     • Aplicar políticas                                             │
│                                                                     │
│  Si todo OK, continúa...                                            │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PASO 3: Guardar en etcd                                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  API Server escribe el pod en etcd:                                 │
│                                                                     │
│  Key: /registry/pods/default/mi-pod                                 │
│  Value: {                                                           │
│    "metadata": {...},                                               │
│    "spec": {...},                                                   │
│    "status": {                                                      │
│      "phase": "Pending",  ← Estado inicial                         │
│      "conditions": []                                               │
│    }                                                                │
│  }                                                                  │
│                                                                     │
│  kubectl recibe respuesta: "pod/mi-pod created"                    │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PASO 4: Scheduler detecta pod sin asignar                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Scheduler constantemente consulta:                                 │
│  "¿Hay pods sin spec.nodeName asignado?"                           │
│                                                                     │
│  Encuentra: mi-pod (phase: Pending, nodeName: null)                │
│                                                                     │
│  Inicia algoritmo de scheduling:                                    │
│                                                                     │
│  ┌─────────────────────────────────────────┐                      │
│  │ FILTRADO (elimina nodos no viables)     │                      │
│  ├─────────────────────────────────────────┤                      │
│  │ Node1: 1GB RAM libre                    │                      │
│  │   Pod necesita 2GB → ✗ DESCARTADO      │                      │
│  │                                          │                      │
│  │ Node2: 4GB RAM libre ✓                  │                      │
│  │ Node3: 8GB RAM libre ✓                  │                      │
│  └─────────────────────────────────────────┘                      │
│                                                                     │
│  ┌─────────────────────────────────────────┐                      │
│  │ PUNTUACIÓN (prioriza mejor nodo)        │                      │
│  ├─────────────────────────────────────────┤                      │
│  │ Node2:                                   │                      │
│  │  • Balance de recursos: 60 puntos       │                      │
│  │  • Afinidad con zona-a: 20 puntos       │                      │
│  │  • Total: 80 puntos                      │                      │
│  │                                          │                      │
│  │ Node3:                                   │                      │
│  │  • Balance de recursos: 90 puntos       │                      │
│  │  • Sin afinidad especial: 0 puntos      │                      │
│  │  • Total: 90 puntos ← GANADOR           │                      │
│  └─────────────────────────────────────────┘                      │
│                                                                     │
│  Scheduler actualiza etcd:                                          │
│  spec.nodeName = "node3"                                            │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PASO 5: kubelet en Node3 detecta pod asignado                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  kubelet cada 10s pregunta a API Server:                            │
│  "¿Hay pods nuevos para mi nodo (node3)?"                          │
│                                                                     │
│  Detecta: mi-pod asignado a node3                                   │
│                                                                     │
│  kubelet prepara:                                                    │
│  1. Crear directorios para volúmenes                                │
│  2. Montar secretos/configmaps                                      │
│  3. Configurar red del pod                                          │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PASO 6: kubelet le dice a Container Runtime que ejecute           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  kubelet → Container Runtime (CRI):                                 │
│  "Ejecuta contenedor con imagen nginx:latest"                      │
│                                                                     │
│  Container Runtime:                                                 │
│  1. Pull imagen si no existe:                                       │
│     docker pull nginx:latest                                        │
│                                                                     │
│  2. Crea contenedor:                                                │
│     docker create --name k8s_nginx_mi-pod_default_... nginx        │
│                                                                     │
│  3. Inicia contenedor:                                              │
│     docker start k8s_nginx_mi-pod_default_...                      │
│                                                                     │
│  4. Configura red (asigna IP del pod)                              │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PASO 7: kubelet reporta estado "Running"                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  kubelet actualiza estado en API Server:                            │
│                                                                     │
│  status.phase = "Running"                                           │
│  status.podIP = "192.168.1.50"                                      │
│  status.containerStatuses = [                                       │
│    {                                                                │
│      "name": "nginx",                                               │
│      "state": {"running": {"startedAt": "2024-..."}},              │
│      "ready": true                                                  │
│    }                                                                │
│  ]                                                                  │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PASO 8: Usuario puede verificar                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  $ kubectl get pods                                                 │
│  NAME     READY   STATUS    RESTARTS   AGE                         │
│  mi-pod  1/1     Running   0          30s                          │
│                                                                     │
│  $ kubectl describe pod mi-pod                                      │
│  ...                                                                │
│  Node:         node3/192.168.1.3                                    │
│  Status:       Running                                              │
│  IP:           192.168.1.50                                         │
│  ...                                                                │
│                                                                     │
│  ✅ Pod creado exitosamente                                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Tiempo total**: Típicamente 5-15 segundos (dependiendo de si la imagen ya está descargada).

---

## Flujo de Networking

Cómo los Pods se comunican entre sí y con el exterior:

```
┌─────────────────────────────────────────────────────────────────────┐
│                   MODELO DE RED DE KUBERNETES                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Principios fundamentales:                                          │
│  1. Cada Pod tiene una IP única                                    │
│  2. Pods pueden comunicarse sin NAT                                │
│  3. Contenedores en un Pod comparten la misma IP                   │
│  4. Services proporcionan IPs estables y DNS                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

ESCENARIO: Pod Frontend necesita llamar a Pod Backend

┌──────────────────────────────────────────────────────────────────┐
│  Node 1                          Node 2                          │
│                                                                  │
│  ┌────────────────────┐          ┌────────────────────┐        │
│  │  Pod: frontend     │          │  Pod: backend-1    │        │
│  │  IP: 10.244.1.5    │          │  IP: 10.244.2.10   │        │
│  │                    │          │                    │        │
│  │  [nginx]           │          │  [API server]      │        │
│  │   Port 80          │          │   Port 8080        │        │
│  └─────────┬──────────┘          └──────────┬─────────┘        │
│            │                                │                   │
│            │                     ┌────────────────────┐        │
│            │                     │  Pod: backend-2    │        │
│            │                     │  IP: 10.244.2.11   │        │
│            │                     │                    │        │
│            │                     │  [API server]      │        │
│            │                     │   Port 8080        │        │
│            │                     └──────────┬─────────┘        │
└────────────┼────────────────────────────────┼──────────────────┘
             │                                │
             │                                │
             └────────────┬───────────────────┘
                          │
                          │
              ┌───────────▼─────────────┐
              │   Service: backend      │
              │   ClusterIP: 10.96.0.50 │
              │   DNS: backend.default. │
              │        svc.cluster.local│
              │                          │
              │   Endpoints:             │
              │   - 10.244.2.10:8080    │
              │   - 10.244.2.11:8080    │
              └──────────────────────────┘

FLUJO DE COMUNICACIÓN:

1. Frontend hace petición:
   curl http://backend.default.svc.cluster.local:8080/api

2. DNS del cluster resuelve:
   backend.default.svc.cluster.local → 10.96.0.50

3. Petición sale del pod frontend:
   Origen: 10.244.1.5 → Destino: 10.96.0.50:8080

4. kube-proxy intercepta (en ambos nodos):
   Detecta que 10.96.0.50 es un Service

5. kube-proxy aplica reglas de iptables:
   Reescribe destino a uno de los pods backend (load balancing):
   10.96.0.50:8080 → 10.244.2.10:8080 (50% probabilidad)
                   → 10.244.2.11:8080 (50% probabilidad)

6. Petición se enruta al nodo correcto:
   Overlay network (CNI plugin) enruta entre nodos

7. Petición llega al pod backend:
   Pod backend-1 recibe en puerto 8080

8. Respuesta hace el camino inverso:
   backend-1 → Service IP → frontend

9. Frontend recibe respuesta

✅ Todo esto ocurre transparentemente, sin configuración manual
```

---

## Comandos para Explorar Arquitectura

```bash
# Ver componentes del control plane
kubectl get pods -n kube-system

# Ver detalles del API server
kubectl get pod -n kube-system kube-apiserver-<nombre> -o yaml

# Ver configuración de etcd
kubectl get pod -n kube-system etcd-<nombre> -o yaml

# Ver nodos y sus recursos
kubectl describe nodes

# Ver eventos del cluster (útil para debugging)
kubectl get events --sort-by='.lastTimestamp'

# Ver servicios del sistema
kubectl get svc -n kube-system

# Ver endpoints de un servicio
kubectl get endpoints <service-name>

# Ver reglas de kube-proxy (en el nodo)
sudo iptables -t nat -L -n -v | grep <service-name>

# Ver logs del kubelet (en el nodo)
sudo journalctl -u kubelet -f

# Ver logs de container runtime (en el nodo)
sudo journalctl -u docker -f  # o containerd
```

---

## Resumen

La arquitectura de Kubernetes parece compleja, pero cada componente tiene un rol específico:

- **API Server**: El cerebro que coordina todo
- **etcd**: La memoria que almacena el estado
- **Scheduler**: El asignador que decide dónde va cada pod
- **Controller Manager**: El supervisor que mantiene el estado deseado
- **kubelet**: El agente en cada nodo que ejecuta pods
- **Container Runtime**: El ejecutor real de contenedores
- **kube-proxy**: El proxy que habilita networking

Todos trabajan juntos para proporcionar una plataforma robusta, escalable y auto-reparable para tus aplicaciones.
