# Kubernetes y Azure AKS: De Cero a Producción

**Curso profesional de 32 horas** | Certificaciones: CKAD, CKA, Azure AKS Specialty

---

## Audiencia

Este material está dirigido a ingenieros de software, administradores de sistemas y profesionales DevOps que desean dominar Kubernetes desde los fundamentos hasta operaciones en producción con Azure AKS. No se requiere experiencia previa con contenedores.

---

## Prerrequisitos Generales

### Conocimientos Previos

- Conceptos básicos de redes (TCP/IP, DNS, HTTP/HTTPS)
- Línea de comandos Linux (navegación, archivos, permisos)
- Conceptos básicos de programación (variables, loops, condicionales)
- Familiaridad con YAML y JSON como formatos de datos

### Herramientas Necesarias

| Herramienta | Versión mínima | Propósito |
|-------------|---------------|-----------|
| **Docker Desktop** | 20.10+ | Motor de contenedores |
| **Minikube** | 1.30+ | Cluster local de Kubernetes |
| **kubectl** | 1.27+ | CLI de Kubernetes |
| **Helm** | 3.12+ | Gestor de paquetes K8s |
| **Azure CLI** | 2.50+ | Operaciones en Azure AKS |
| **VS Code** | Último | Editor con extensiones YAML/K8s |
| **Git** | 2.30+ | Control de versiones |

### Verificación del Entorno

```bash
# Docker
docker --version && docker run hello-world

# Minikube
minikube version && minikube status

# kubectl
kubectl version --client

# Helm
helm version --short

# Azure CLI (para Partes III y IV)
az --version && az account show
```

---

## Rutas de Estudio

### Principiante (32 horas — curso completo)

Sigue todos los capítulos en orden, completando cada laboratorio antes de avanzar. Esta ruta construye una base sólida paso a paso.

```
Parte I  → Parte II (todos los capítulos) → Parte III → Parte IV → Proyecto Final
```

### Intermedio (20 horas — con experiencia Docker)

Si ya conoces Docker, comienza en el Capítulo 3. Puedes saltar los laboratorios básicos y enfocarte en los intermedios y avanzados.

```
Cap 3-5 (rápido) → Cap 6-11 → Cap 12-18 → Cap 19-28 → Parte III-IV
```

### Certificación CKAD (15 horas)

Enfoque en desarrollo de aplicaciones sobre Kubernetes:

```
Cap 6-11 → Cap 14-16 → Cap 21-22 → Labs de práctica
```

### Certificación CKA (20 horas)

Enfoque en administración de clusters:

```
Cap 3-5 → Cap 6-11 → Cap 12-13 → Cap 17-20 → Cap 24-28 → Parte III
```

### Azure AKS Specialty (12 horas)

Enfoque en operaciones cloud:

```
Parte III completa → Parte IV completa → Proyecto Final
```

---

## Convenciones del Material

- **Idioma**: Todo el contenido está en español. Los términos técnicos (Pod, Deployment, Service, etc.) se mantienen en inglés.
- **Manifiestos YAML**: Cada archivo incluye un comentario `# Uso: kubectl apply -f archivo.yaml` al inicio.
- **Laboratorios**: Cada laboratorio tiene un `README.md` con pasos, un `SETUP.md` con prerrequisitos y un `cleanup.sh` para limpiar recursos.
- **Resúmenes**: Cada capítulo tiene un `RESUMEN-MODULO.md` como guía de estudio autónoma.
- **Ejemplos**: En subdirectorios numerados (`01-nombre/`, `02-nombre/`) con su propio README y cleanup.

---

## Índice General

### Parte I: Fundamentos de Virtualización y Docker

| Cap | Título | Ruta |
|-----|--------|------|
| 1 | [Virtualización Tradicional](area-1-fundamentos-docker/modulo-1-virtualizacion/README.md) | `area-1/modulo-1-virtualizacion/` |
| 2 | [Docker y Contenerización](area-1-fundamentos-docker/modulo-2-docker/README.md) | `area-1/modulo-2-docker/` |

### Parte II: Arquitectura y Fundamentos de Kubernetes

| Cap | Título | Ruta |
|-----|--------|------|
| 3 | [Introducción a Kubernetes](area-2-arquitectura-kubernetes/modulo-01-introduccion-kubernetes/README.md) | `area-2/modulo-01-introduccion-kubernetes/` |
| 4 | [Arquitectura de Cluster](area-2-arquitectura-kubernetes/modulo-02-arquitectura-cluster/README.md) | `area-2/modulo-02-arquitectura-cluster/` |
| 5 | [Instalación de Minikube](area-2-arquitectura-kubernetes/modulo-03-instalacion-minikube/README.md) | `area-2/modulo-03-instalacion-minikube/` |
| 6 | [Pods vs Contenedores Docker](area-2-arquitectura-kubernetes/modulo-04-pods-vs-contenedores/README.md) | `area-2/modulo-04-pods-vs-contenedores/` |
| 7 | [Gestión Avanzada de Pods](area-2-arquitectura-kubernetes/modulo-05-gestion-pods/README.md) | `area-2/modulo-05-gestion-pods/` |
| 8 | [ReplicaSets y Escalado](area-2-arquitectura-kubernetes/modulo-06-replicasets-replicas/README.md) | `area-2/modulo-06-replicasets-replicas/` |
| 9 | [Deployments y Rollouts](area-2-arquitectura-kubernetes/modulo-07-deployments-rollouts/README.md) | `area-2/modulo-07-deployments-rollouts/` |
| 10 | [Services y Service Discovery](area-2-arquitectura-kubernetes/modulo-08-services-endpoints/README.md) | `area-2/modulo-08-services-endpoints/` |
| 11 | [Ingress y Acceso Externo](area-2-arquitectura-kubernetes/modulo-09-ingress-external-access/README.md) | `area-2/modulo-09-ingress-external-access/` |
| 12 | [Namespaces y Organización](area-2-arquitectura-kubernetes/modulo-10-namespaces-organizacion/README.md) | `area-2/modulo-10-namespaces-organizacion/` |
| 13 | [Resource Limits en Pods](area-2-arquitectura-kubernetes/modulo-11-resource-limits-pods/README.md) | `area-2/modulo-11-resource-limits-pods/` |
| 14 | [Health Checks y Probes](area-2-arquitectura-kubernetes/modulo-12-health-checks-probes/README.md) | `area-2/modulo-12-health-checks-probes/` |
| 15 | [ConfigMaps y Variables](area-2-arquitectura-kubernetes/modulo-13-configmaps-variables/README.md) | `area-2/modulo-13-configmaps-variables/` |
| 16 | [Secrets y Datos Sensibles](area-2-arquitectura-kubernetes/modulo-14-secrets-data-sensible/README.md) | `area-2/modulo-14-secrets-data-sensible/` |
| 17 | [Volumes — Conceptos](area-2-arquitectura-kubernetes/modulo-15-volumes-conceptos/README.md) | `area-2/modulo-15-volumes-conceptos/` |
| 18 | [Volumes — Tipos y Storage](area-2-arquitectura-kubernetes/modulo-16-volumes-tipos-storage/README.md) | `area-2/modulo-16-volumes-tipos-storage/` |
| 19 | [RBAC: Users y Groups](area-2-arquitectura-kubernetes/modulo-17-rbac-users-groups/README.md) | `area-2/modulo-17-rbac-users-groups/` |
| 20 | [RBAC: ServiceAccounts](area-2-arquitectura-kubernetes/modulo-18-rbac-serviceaccounts/README.md) | `area-2/modulo-18-rbac-serviceaccounts/` |
| 21 | [Jobs y CronJobs](area-2-arquitectura-kubernetes/modulo-19-jobs-cronjobs/README.md) | `area-2/modulo-19-jobs-cronjobs/` |
| 22 | [Init Containers y Sidecar Patterns](area-2-arquitectura-kubernetes/modulo-20-init-sidecar-patterns/README.md) | `area-2/modulo-20-init-sidecar-patterns/` |
| 23 | [Helm Basics](area-2-arquitectura-kubernetes/modulo-21-helm-basics/README.md) | `area-2/modulo-21-helm-basics/` |
| 24 | [Cluster Setup con kubeadm](area-2-arquitectura-kubernetes/modulo-22-cluster-setup-kubeadm/README.md) | `area-2/modulo-22-cluster-setup-kubeadm/` |
| 25 | [Mantenimiento y Upgrades](area-2-arquitectura-kubernetes/modulo-23-maintenance-upgrades/README.md) | `area-2/modulo-23-maintenance-upgrades/` |
| 26 | [Advanced Scheduling](area-2-arquitectura-kubernetes/modulo-24-advanced-scheduling/README.md) | `area-2/modulo-24-advanced-scheduling/` |
| 27 | [Networking Avanzado](area-2-arquitectura-kubernetes/modulo-25-networking/README.md) | `area-2/modulo-25-networking/` |
| 28 | [Troubleshooting](area-2-arquitectura-kubernetes/modulo-26-troubleshooting/README.md) | `area-2/modulo-26-troubleshooting/` |

### Parte III: Operación, Seguridad y Almacenamiento en AKS

| Cap | Título | Ruta |
|-----|--------|------|
| 29 | [Gestión de Clústeres AKS](area-3-operacion-seguridad/modulo-01-gestion-clusters-aks/README.md) | `area-3/modulo-01-gestion-clusters-aks/` |
| 30 | [RBAC y Control de Acceso](area-3-operacion-seguridad/modulo-02-rbac-control-acceso/README.md) | `area-3/modulo-02-rbac-control-acceso/` |
| 31 | [Network Policies y Seguridad de Red](area-3-operacion-seguridad/modulo-03-network-policies/README.md) | `area-3/modulo-03-network-policies/` |
| 32 | [Almacenamiento Persistente](area-3-operacion-seguridad/modulo-04-almacenamiento-persistente/README.md) | `area-3/modulo-04-almacenamiento-persistente/` |
| 33 | [Azure Key Vault](area-3-operacion-seguridad/modulo-05-azure-key-vault/README.md) | `area-3/modulo-05-azure-key-vault/` |

### Parte IV: Observabilidad, Alta Disponibilidad e Integración

| Cap | Título | Ruta |
|-----|--------|------|
| 34 | [Logging y Observabilidad](area-4-observabilidad-ha/modulo-01-logging-observabilidad/README.md) | `area-4/modulo-01-logging-observabilidad/` |
| 35 | [Prometheus y Grafana](area-4-observabilidad-ha/modulo-02-prometheus-grafana/README.md) | `area-4/modulo-02-prometheus-grafana/` |
| 36 | [Alta Disponibilidad y Autoescalado](area-4-observabilidad-ha/modulo-03-alta-disponibilidad/README.md) | `area-4/modulo-03-alta-disponibilidad/` |
| 37 | [Troubleshooting Avanzado](area-4-observabilidad-ha/modulo-04-troubleshooting-avanzado/README.md) | `area-4/modulo-04-troubleshooting-avanzado/` |
| 38 | [CI/CD y GitOps](area-4-observabilidad-ha/modulo-05-cicd-gitops/README.md) | `area-4/modulo-05-cicd-gitops/` |

### Apéndices

| Apéndice | Título | Ruta |
|----------|--------|------|
| A | [Objetivos de Aprendizaje por Capítulo](apendices/A-objetivos-por-capitulo.md) | `apendices/` |
| B | [Cheat Sheet de kubectl](apendices/B-cheat-sheet-kubectl.md) | `apendices/` |
| C | [Mapa de Certificaciones](apendices/C-mapa-certificaciones.md) | `apendices/` |
| D | [Glosario](apendices/D-glosario.md) | `apendices/` |
| E | [Evaluaciones y Checkpoints](apendices/E-evaluaciones-checkpoints.md) | `apendices/` |
| F | [Referencias por Capítulo](apendices/F-referencias.md) | `apendices/` |

### Proyecto Final

| | Título | Ruta |
|--|--------|------|
| | [Aplicación 3-Tier en Kubernetes](proyecto-final/README.md) | `proyecto-final/` |

---

## Cómo Usar Este Material

1. **Lectura secuencial**: Los capítulos están diseñados para leerse en orden. Cada uno conecta con el anterior mediante un párrafo de transición.
2. **Laboratorios**: Después de leer la teoría de cada capítulo, completa los laboratorios en `laboratorios/`. Cada lab incluye pasos detallados y salida esperada.
3. **Resúmenes**: Usa `RESUMEN-MODULO.md` de cada capítulo como guía de repaso rápido antes de exámenes o certificaciones.
4. **Ejemplos**: Los directorios `ejemplos/` contienen manifiestos YAML listos para aplicar con `kubectl apply -f`.
5. **Limpieza**: Cada laboratorio y ejemplo incluye un `cleanup.sh` para restaurar el cluster a su estado original.
