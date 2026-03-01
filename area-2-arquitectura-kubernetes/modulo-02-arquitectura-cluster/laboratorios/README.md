# Laboratorios - Modulo 02: Arquitectura del Cluster

Laboratorios practicos para comprender la arquitectura interna de Kubernetes a nivel de cluster.
Cada laboratorio incluye pasos guiados, salida esperada de los comandos, y un script de limpieza.

**Total de laboratorios:** 4 labs + 1 lab de resumen
**Tiempo total estimado:** 5-6 horas

---

## Estructura de Directorios

```
laboratorios/
├── README.md                          # Este archivo (indice)
├── lab-01-exploracion-arquitectura/   # 3 archivos
│   ├── README.md
│   ├── SETUP.md
│   └── cleanup.sh
├── lab-02-control-plane-practico/     # 3 archivos
│   ├── README.md
│   ├── SETUP.md
│   └── cleanup.sh
├── lab-03-worker-nodes/               # 11 archivos
│   ├── README.md
│   ├── SETUP.md
│   ├── cleanup.sh
│   ├── unhealthy-pod.yaml
│   ├── high-cpu-pod.yaml
│   ├── memory-hog-pod.yaml
│   ├── multi-container-pod.yaml
│   ├── guaranteed-pod.yaml
│   ├── external-db-service.yaml
│   ├── netpol-deny-all.yaml
│   └── netpol-allow-frontend.yaml
├── lab-04-troubleshooting-networking/ # 6 archivos
│   ├── README.md
│   ├── SETUP.md
│   ├── cleanup.sh
│   ├── broken-app-service.yaml
│   ├── backend-label-mismatch.yaml
│   └── netshoot-pod.yaml
└── lab-resumen-arquitectura/          # 3 archivos
    ├── README.md
    ├── arquitectura-lab.yaml
    └── cleanup.sh
```

---

## Indice de Laboratorios

### Lab 01: Exploracion de Arquitectura

**Directorio:** `lab-01-exploracion-arquitectura/`
**Duracion:** 60-90 minutos | **Nivel:** Basico

Exploracion practica de todos los componentes del Control Plane y Worker Nodes
en un cluster Minikube. Usa comandos imperativos para observar el cluster desde adentro.

**Objetivos:**
- Identificar pods del Control Plane en el namespace kube-system
- Inspeccionar el API Server, etcd, Scheduler y Controller Manager
- Rastrear el flujo de creacion de un Deployment en tiempo real
- Verificar la comunicacion entre componentes via API Watch

**Herramientas necesarias:** kubectl, minikube

---

### Lab 02: Control Plane Practico

**Directorio:** `lab-02-control-plane-practico/`
**Duracion:** 90-120 minutos | **Nivel:** Intermedio

Interaccion directa con el API Server via REST, backup conceptual de etcd,
analisis del Scheduler y observacion del reconciliation loop del Controller Manager.

**Objetivos:**
- Hacer peticiones REST directas al API Server con curl y token JWT
- Comprender el proceso de backup y restore de etcd (conceptual en Minikube)
- Observar decisiones del Scheduler con nodeSelector y scheduling manual
- Ver el reconciliation loop en accion con ReplicaSet y Endpoint Controllers

**Herramientas necesarias:** kubectl, minikube, curl, jq

---

### Lab 03: Worker Nodes

**Directorio:** `lab-03-worker-nodes/`
**Duracion:** 90-120 minutos | **Nivel:** Intermedio

Analisis en profundidad de kubelet (health probes, resource management, eviction),
kube-proxy (iptables, IPVS), container runtime (crictl) y NetworkPolicies.

**Objetivos:**
- Crear pods con liveness/readiness probes que fallan y observar el comportamiento de kubelet
- Analizar resource requests/limits y su traduccion a cgroups
- Interactuar con el container runtime usando crictl
- Crear y verificar NetworkPolicies con Calico

**Herramientas necesarias:** kubectl, minikube con CNI Calico, crictl (en nodos)

**YAML files (8):**

| Archivo | Descripcion |
|---------|-------------|
| `unhealthy-pod.yaml` | Pod con livenessProbe que falla |
| `high-cpu-pod.yaml` | Pod de estres de CPU con resource limits |
| `memory-hog-pod.yaml` | Pod que consume memoria (eviction demo) |
| `multi-container-pod.yaml` | Pod multi-contenedor para crictl |
| `guaranteed-pod.yaml` | Pod con QoS Guaranteed |
| `external-db-service.yaml` | Service + Endpoints para BD externa |
| `netpol-deny-all.yaml` | NetworkPolicy deny-all |
| `netpol-allow-frontend.yaml` | NetworkPolicy allow desde frontend |

---

### Lab 04: Troubleshooting de Networking

**Directorio:** `lab-04-troubleshooting-networking/`
**Duracion:** 90-120 minutos | **Nivel:** Avanzado

Diagnostico sistematico de problemas de networking: Services sin endpoints,
selector/label mismatch, DNS resolution, tcpdump en pods y ephemeral containers.

**Objetivos:**
- Diagnosticar por que un Service no responde (targetPort incorrecto)
- Resolver problemas de selector que no coincide con labels de Pods
- Troubleshootear problemas de DNS con CoreDNS
- Capturar trafico de red con tcpdump usando el pod netshoot
- Usar ephemeral debug containers para depurar pods sin herramientas

**Herramientas necesarias:** kubectl, minikube, curl

**YAML files (3):**

| Archivo | Descripcion |
|---------|-------------|
| `broken-app-service.yaml` | Deployment + Service con targetPort incorrecto |
| `backend-label-mismatch.yaml` | Deployment + Service con selector incorrecto |
| `netshoot-pod.yaml` | Pod de diagnostico con nicolaka/netshoot |

---

### Lab Resumen: Arquitectura del Cluster

**Directorio:** `lab-resumen-arquitectura/`
**Duracion:** 15 minutos | **Nivel:** Intermedio

Lab de revision rapida que despliega un conjunto minimo de recursos para repasar
todos los componentes de la arquitectura (API Server, Scheduler, kubelet, kube-proxy,
container runtime) en un solo flujo guiado. Ideal para repaso previo a examen.

**Objetivos:**
- Repasar el rol de cada componente del cluster en 15 minutos
- Verificar la colaboracion entre componentes con un Deployment real
- Confirmar el funcionamiento de Services, probes y NetworkPolicies

**YAML files (1):**

| Archivo | Descripcion |
|---------|-------------|
| `arquitectura-lab.yaml` | YAML unificado con Namespace, Deployment, Service, Pods y NetworkPolicy |

---

## Ruta de Aprendizaje Recomendada

```
Nivel Basico
  Lab 01 - Exploracion de Arquitectura (60-90 min)

Nivel Intermedio
  Lab 02 - Control Plane Practico (90-120 min)
  Lab 03 - Worker Nodes (90-120 min)

Nivel Avanzado
  Lab 04 - Troubleshooting Networking (90-120 min)

Repaso / Examen
  Lab Resumen - Arquitectura del Cluster (15 min)
```

---

## Como Usar Cada Lab

```bash
# 1. Leer los pre-requisitos
cat lab-XX-nombre/SETUP.md

# 2. Verificar el entorno segun SETUP.md
kubectl cluster-info
kubectl get nodes

# 3. Seguir el README.md paso a paso
# Los comandos muestran la salida esperada

# 4. Limpiar recursos al terminar
cd lab-XX-nombre
./cleanup.sh
```

---

## Verificacion Previa (Todos los Labs)

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar componentes del sistema
kubectl get pods -n kube-system
```
