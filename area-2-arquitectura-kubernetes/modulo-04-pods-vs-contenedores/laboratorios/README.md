# 🧪 Laboratorios Prácticos - Módulo 04: Pods vs Contenedores

## 📚 Descripción

Esta carpeta contiene **5 laboratorios prácticos** diseñados para profundizar en los conceptos de Pods, contenedores, y patrones de diseño en Kubernetes.

## 🎯 Laboratorios Disponibles

### 🚀 Lab 1: Evolución Histórica Práctica
**Archivo**: [lab-01-evolucion.md](./lab-01-evolucion.md)

- **Duración**: 30 minutos
- **Nivel**: Principiante
- **Objetivo**: Experimentar las diferencias entre enfoques LXC, Docker y Kubernetes
- **Conceptos**: Evolución del networking, aislamiento vs simplicidad

**Lo que aprenderás**:
- ✅ Diferencias prácticas entre LXC, Docker bridge, y Pods
- ✅ Comunicación localhost en Kubernetes
- ✅ Trade-offs entre aislamiento y simplicidad

---

### 🔬 Lab 2: Namespace Sharing Deep Dive
**Archivo**: [lab-02-namespace-sharing.md](./lab-02-namespace-sharing.md)

- **Duración**: 40 minutos
- **Nivel**: Intermedio
- **Objetivo**: Explorar qué namespaces comparten los contenedores en un Pod
- **Conceptos**: Linux namespaces, shared resources, isolation

**Lo que aprenderás**:
- ✅ Network namespace: misma IP, comunicación localhost
- ✅ PID namespace: visibilidad de procesos (con `shareProcessNamespace`)
- ✅ UTS, IPC namespaces: hostname e IPC compartidos
- ✅ Mount, User namespaces: filesystem y users independientes
- ✅ Uso de volumes para compartir archivos

---

### 🏗️ Lab 3: Sidecar Pattern Real-World
**Archivo**: [lab-03-sidecar-real-world.md](./lab-03-sidecar-real-world.md)

- **Duración**: 60 minutos
- **Nivel**: Intermedio-Avanzado
- **Objetivo**: Implementar un sidecar de logging con aplicación real
- **Conceptos**: Sidecar pattern, Fluent Bit, shared volumes, separation of concerns

**Lo que aprenderás**:
- ✅ Flask app que genera logs estructurados (JSON)
- ✅ Fluent Bit sidecar para procesamiento de logs
- ✅ Comunicación vía shared volume (emptyDir)
- ✅ Resource limits independientes por contenedor
- ✅ Separación de responsabilidades

---

### 🚀 Lab 4: Init Container Migration Pattern
**Archivo**: [lab-04-init-migration.md](./lab-04-init-migration.md)

- **Duración**: 70 minutos
- **Nivel**: Avanzado
- **Objetivo**: Migrar setup complejo de Docker a Init Containers
- **Conceptos**: Init containers, sequential execution, dependency management

**Lo que aprenderás**:
- ✅ Problemas del setup Docker tradicional (manual, complejo)
- ✅ Init containers: wait-for-db → migrations → config
- ✅ Ejecución secuencial garantizada
- ✅ Retry automático de Kubernetes
- ✅ Separación setup vs runtime

---

### 🔄 Lab 5: Migración de Docker Compose
**Archivo**: [lab-05-compose-migration.md](./lab-05-compose-migration.md)

- **Duración**: 50 minutos
- **Nivel**: Intermedio
- **Objetivo**: Migrar aplicación multi-container de docker-compose.yml a Kubernetes
- **Conceptos**: Deployments, Services, ConfigMaps, Secrets, PVC

**Lo que aprenderás**:
- ✅ Conversión docker-compose.yml → Deployments + Services
- ✅ Networking Docker bridge → Kubernetes Services + DNS
- ✅ Named volumes → PersistentVolumeClaims
- ✅ Environment variables → ConfigMaps/Secrets
- ✅ Escalabilidad con `replicas`
- ✅ Alta disponibilidad con Load Balancing

---

## 📊 Ruta de Aprendizaje Recomendada

```
┌───────────────────────────────────────────────────────────────┐
│                    Progreso Recomendado                       │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Lab 1 (30min)  →  Lab 2 (40min)  →  Lab 3 (60min)           │
│       ↓                                                       │
│  Lab 4 (70min)  →  Lab 5 (50min)                             │
│                                                               │
│  Duración total: ~4 horas                                     │
└───────────────────────────────────────────────────────────────┘
```

### Secuencia Lógica:

1. **Lab 1**: Fundamentos de la evolución (LXC → Docker → K8s)
2. **Lab 2**: Entender qué comparten los contenedores en Pods
3. **Lab 3**: Aplicar patrón Sidecar en caso real
4. **Lab 4**: Dominar Init Containers para setup
5. **Lab 5**: Migrar aplicación completa de Docker Compose

## ✅ Prerrequisitos Generales

### Software Requerido:
- ✅ **Docker** instalado y funcionando
- ✅ **kubectl** configurado
- ✅ **Cluster Kubernetes** activo (minikube, kind, o similar)
- ✅ **Terminal** bash/zsh

### Conocimientos Previos:
- Conceptos básicos de contenedores
- Docker y docker-compose
- Comandos básicos de kubectl
- Networking básico

### Verificar Prerrequisitos:

```bash
# Verificar Docker
docker --version
docker ps

# Verificar kubectl
kubectl version --client
kubectl cluster-info

# Verificar cluster activo
kubectl get nodes
```

## 🎓 Resultados de Aprendizaje

Al completar estos laboratorios, serás capaz de:

- ✅ **Entender la evolución** de la containerización (LXC → Docker → Kubernetes)
- ✅ **Explicar qué namespaces** comparten los contenedores en Pods
- ✅ **Implementar patrones** Sidecar, Init Containers, Ambassador
- ✅ **Migrar aplicaciones** de Docker Compose a Kubernetes
- ✅ **Diseñar Pods** siguiendo mejores prácticas
- ✅ **Aplicar separación de responsabilidades** en microservicios

## 📂 Estructura de Archivos

```
laboratorios/
├── README.md                        # Este archivo (índice)
├── lab-01-evolucion.md              # Lab 1: Evolución LXC → Docker → K8s
├── lab-02-namespace-sharing.md      # Lab 2: Namespace sharing analysis
├── lab-03-sidecar-real-world.md     # Lab 3: Sidecar pattern con Flask + Fluent Bit
├── lab-04-init-migration.md         # Lab 4: Init containers migration
└── lab-05-compose-migration.md      # Lab 5: Docker Compose → Kubernetes
```

## 🚀 Inicio Rápido

```bash
# 1. Navegar a la carpeta de laboratorios
cd ~/K8S/area-2-arquitectura-kubernetes/modulo-04-pods-vs-contenedores/laboratorios/

# 2. Abrir el primer lab
cat lab-01-evolucion.md

# 3. Seguir las instrucciones paso a paso
# Cada lab incluye:
# - Objetivos claros
# - Código completo copy-paste ready
# - Explicaciones detalladas
# - Verificaciones y tests
# - Cleanup al final
```

## 💡 Tips para Completar los Labs

1. **Ejecuta cada comando**: No solo leas, ejecuta y observa
2. **Lee las observaciones**: Los bloques "🔍 Observaciones" explican qué ver
3. **Completa el cleanup**: Limpia recursos después de cada lab
4. **Toma notas**: Documenta tus aprendizajes
5. **Experimenta**: Modifica valores y observa qué cambia

## 🆘 Troubleshooting

### Problema: Cluster no disponible
```bash
# Verificar cluster
kubectl cluster-info

# Si usas minikube
minikube status
minikube start
```

### Problema: Pods en estado Pending
```bash
# Ver eventos
kubectl describe pod <pod-name>

# Ver recursos del cluster
kubectl top nodes
```

### Problema: Imágenes no se descargan
```bash
# Verificar conexión a Internet
ping docker.io

# Si usas minikube, cargar imagen local
minikube image load <image-name>
```

## 📚 Referencias Adicionales

- [Kubernetes Pods Documentation](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Multi-Container Patterns](https://kubernetes.io/blog/2015/06/the-distributed-system-toolkit-patterns/)
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Docker Compose to Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)

## 🏠 Navegación

- **[⬅️ Volver al README Principal](../README.md)**
- **[📖 Ver Ejemplos YAML](../ejemplos/README.md)**
- **[➡️ Módulo 05: Gestión de Pods](../../modulo-05-gestion-pods/README.md)**

---

**¡Éxito con los laboratorios! 🚀**
