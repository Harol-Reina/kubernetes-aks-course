# 🚀 Área 2: Arquitectura y Fundamentos de Kubernetes

**Duración**: 12 horas  
**Modalidad**: Teórico-Práctico  
**Prerequisitos**: Área 1 completada (Fundamentos Docker)

## 🎯 Objetivos de Aprendizaje

Al completar esta área, serás capaz de:

- ✅ **Dominar la arquitectura completa** de Kubernetes y sus componentes
- ✅ **Gestionar clusters locales** con Minikube para desarrollo
- ✅ **Crear y administrar workloads** (Pods, ReplicaSets, Deployments)
- ✅ **Implementar networking avanzado** (Services, Ingress, Endpoints)
- ✅ **Organizar recursos** con Namespaces y control de acceso
- ✅ **Gestionar configuración** (ConfigMaps, Secrets, Variables)
- ✅ **Implementar persistencia** de datos con Volumes
- ✅ **Aplicar seguridad** con RBAC y ServiceAccounts

---

## 📚 Estructura Modular

### 🧱 **Módulo 1: Fundamentos y Arquitectura** (2 horas)

| Módulo | Título | Duración | Conceptos Clave |
|--------|--------|----------|-----------------|
| **[M01](./modulo-01-introduccion-kubernetes/)** | **Introducción a Kubernetes** | 30 min | Historia, evolución, casos de uso |
| **[M02](./modulo-02-arquitectura-cluster/)** | **Arquitectura de Cluster** | 60 min | Master, Workers, API Server, etcd |
| **[M03](./modulo-03-instalacion-minikube/)** | **Instalación de Minikube** | 30 min | Cluster local, kubectl, desarrollo |

**🎯 Resultado**: Entender qué es Kubernetes, su arquitectura y tener un entorno de desarrollo funcional.

---

### 🐳 **Módulo 2: Workloads y Objetos Fundamentales** (3 horas)

| Módulo | Título | Duración | Conceptos Clave |
|--------|--------|----------|-----------------|
| **[M04](./modulo-04-pods-vs-contenedores/)** | **Pods vs Contenedores Docker** | 45 min | Diferencias, ventajas, arquitectura |
| **[M05](./modulo-05-gestion-pods/)** | **Gestión Avanzada de Pods** | 45 min | Lifecycle, specs, troubleshooting |
| **[M06](./modulo-06-replicasets-replicas/)** | **ReplicaSets y Escalado** | 45 min | Réplicas, auto-healing, selectors |
| **[M07](./modulo-07-deployments-rollouts/)** | **Deployments y Rollouts** | 45 min | Rolling updates, rollbacks, estrategias |

**🎯 Resultado**: Dominar la gestión completa de cargas de trabajo desde Pods hasta Deployments.

---

### 🌐 **Módulo 3: Networking y Service Discovery** (2 horas)

| Módulo | Título | Duración | Conceptos Clave |
|--------|--------|----------|-----------------|
| **[M08](./modulo-08-services-endpoints/)** | **Services y Service Discovery** | 60 min | ClusterIP, NodePort, LoadBalancer |
| **[M09](./modulo-09-ingress-external-access/)** | **Ingress y Acceso Externo** | 60 min | Ingress Controllers, rutas, TLS |

**🎯 Resultado**: Implementar comunicación interna y externa de aplicaciones en Kubernetes.

---

### 📊 **Módulo 4: Gestión de Recursos y Organización** (1.5 horas)

| Módulo | Título | Duración | Conceptos Clave |
|--------|--------|----------|-----------------|
| **[M10](./modulo-10-namespaces-organizacion/)** | **Namespaces y Organización** | 30 min | Aislamiento lógico, multi-tenancy |
| **[M11](./modulo-11-resource-limits-pods/)** | **Resource Limits en Pods** | 30 min | CPU, memoria, requests, limits |
| **[M12](./modulo-12-limitrange-control/)** | **LimitRange y Control** | 15 min | Límites por defecto, validación |
| **[M13](./modulo-13-resourcequota-namespace/)** | **ResourceQuota Namespace** | 15 min | Cuotas globales, governance |

**🎯 Resultado**: Organizar y controlar el uso de recursos en clusters multi-tenant.

---

### ⚙️ **Módulo 5: Configuración y Datos** (2 horas)

| Módulo | Título | Duración | Conceptos Clave |
|--------|--------|----------|-----------------|
| **[M14](./modulo-14-health-checks-probes/)** | **Health Checks y Probes** | 30 min | Liveness, readiness, startup probes |
| **[M15](./modulo-15-configmaps-variables/)** | **ConfigMaps y Variables** | 30 min | Configuración externa, env vars |
| **[M16](./modulo-16-secrets-data-sensible/)** | **Secrets y Datos Sensibles** | 30 min | Credenciales, TLS, encriptación |
| **[M17](./modulo-17-volumes-conceptos/)** | **Volumes - Conceptos** | 15 min | Persistencia, tipos, casos de uso |
| **[M18](./modulo-18-volumes-tipos-storage/)** | **Volumes - Implementación** | 15 min | EmptyDir, HostPath, PV, PVC, SC |

**🎯 Resultado**: Gestionar configuración, secretos y persistencia de datos de forma profesional.

---

### 🔐 **Módulo 6: Seguridad y Control de Acceso** (1.5 horas)

| Módulo | Título | Duración | Conceptos Clave |
|--------|--------|----------|-----------------|
| **[M19](./modulo-19-rbac-users-groups/)** | **RBAC: Users & Groups** | 45 min | Roles, ClusterRoles, RoleBindings |
| **[M20](./modulo-20-rbac-serviceaccounts/)** | **RBAC: ServiceAccounts** | 45 min | Service accounts, tokens, automatización |

**🎯 Resultado**: Implementar control de acceso granular y seguridad en Kubernetes.

---

## 🛠️ Laboratorios Prácticos

### **Progresión de Complejidad:**

```
🔰 Nivel 1: Fundamentos
├── Instalación Minikube
├── Primer Pod
└── Comandos básicos kubectl

🔥 Nivel 2: Workloads
├── Deployments complejos
├── Services y networking
└── Rolling updates

⚡ Nivel 3: Avanzado
├── Ingress con TLS
├── RBAC completo
└── Aplicación multi-tier
```

### **Laboratorios destacados por módulo:**

| Módulo | Laboratorio Principal | Duración |
|--------|-----------------------|----------|
| **M03** | **[Setup Minikube + kubectl](./modulo-03-instalacion-minikube/laboratorios/)** | 30 min |
| **M05** | **[Pod Lifecycle Management](./modulo-05-gestion-pods/laboratorios/)** | 45 min |
| **M07** | **[Rolling Updates & Rollbacks](./modulo-07-deployments-rollouts/laboratorios/)** | 60 min |
| **M08** | **[Service Discovery Demo](./modulo-08-services-endpoints/laboratorios/)** | 45 min |
| **M09** | **[Ingress con NGINX](./modulo-09-ingress-external-access/laboratorios/)** | 60 min |
| **M16** | **[Secrets Management](./modulo-16-secrets-data-sensible/laboratorios/)** | 30 min |
| **M19** | **[RBAC Implementation](./modulo-19-rbac-users-groups/laboratorios/)** | 60 min |

---

## 🎓 Evolución desde Docker (Área 1)

### **Conceptos que evolucionan:**

| Docker (Área 1) | Kubernetes (Área 2) | Mejoras |
|------------------|---------------------|---------|
| **Contenedores individuales** | **Pods** | Multi-contenedor, networking compartido |
| **docker run** | **Deployments** | Auto-scaling, self-healing |
| **docker network** | **Services** | Service discovery automático |
| **docker volume** | **PersistentVolumes** | Storage dinámico, classes |
| **Docker Compose** | **Manifests YAML** | Declarativo, versionado |
| **Manual scaling** | **HPA/VPA** | Auto-scaling inteligente |

### **Nuevos conceptos únicos de K8s:**

- ✅ **Orquestación multi-host** vs single-host Docker
- ✅ **Declarative configuration** vs imperative commands  
- ✅ **Self-healing** automático vs reinicio manual
- ✅ **Service discovery** nativo vs networking manual
- ✅ **Rolling deployments** vs downtime deployments
- ✅ **Resource management** granular vs host-level

---

## 🧪 Metodología de Aprendizaje

### **Estructura por módulo:**

```
📁 modulo-XX-nombre/
├── 📄 README.md (Teoría + conceptos)
├── 📁 laboratorios/
│   ├── lab-01-basico.md
│   ├── lab-02-intermedio.md
│   └── lab-03-avanzado.md
├── 📁 ejemplos/
│   ├── manifests/
│   ├── scripts/
│   └── configs/
└── 📄 EJERCICIOS.md (Práctica adicional)
```

### **Flujo de aprendizaje:**

1. **📖 Leer teoría** en README del módulo
2. **🧪 Ejecutar laboratorios** paso a paso
3. **💡 Experimentar** con ejemplos proporcionados
4. **✍️ Completar ejercicios** de práctica
5. **🔄 Revisar** conceptos antes del siguiente módulo

---

## 📈 Prerrequisitos y Preparación

### **Del Área 1 (Requerido):**
- ✅ Conceptos de **virtualización y contenedores**
- ✅ **Docker** comandos básicos y avanzados
- ✅ **Namespaces** y aislamiento de procesos
- ✅ **Docker Compose** y aplicaciones multi-contenedor
- ✅ **Azure VMs** y conceptos de infraestructura

### **Herramientas necesarias:**
- ✅ **Minikube** (se instala en M03)
- ✅ **kubectl** (cliente Kubernetes)
- ✅ **Docker** (del área anterior)
- ✅ **Git** para ejemplos y manifests
- ✅ **Editor** con syntax highlighting YAML

### **Conocimientos recomendados:**
- 🔧 **YAML syntax** básico
- 🔧 **Linux command line** intermedio
- 🔧 **Networking** conceptos básicos
- 🔧 **SSH** y gestión de claves

---

## 🚀 Proyectos Integradores

### **Mini-Proyecto M1-M3**: Setup Completo
- Instalar y configurar Minikube
- Desplegar primera aplicación
- Explorar arquitectura del cluster

### **Mini-Proyecto M4-M7**: Aplicación Web
- Pod con múltiples contenedores
- ReplicaSet para alta disponibilidad  
- Deployment con rolling updates
- Comparación con Docker Compose

### **Mini-Proyecto M8-M9**: Networking
- Service para comunicación interna
- Ingress para acceso externo
- Load balancing y DNS

### **Mini-Proyecto M10-M13**: Multi-tenancy
- Namespaces para diferentes entornos
- Resource quotas y limits
- Organización empresarial

### **Mini-Proyecto M14-M18**: Aplicación Productiva
- Health checks completos
- ConfigMaps para configuración
- Secrets para credenciales
- Persistent storage

### **Mini-Proyecto M19-M20**: Seguridad
- RBAC para equipos específicos
- ServiceAccounts para automatización
- Principio de menor privilegio

---

## 🎯 Evaluación y Certificación

### **Evaluación continua:**
- ✅ **Laboratorios completados** (70% peso)
- ✅ **Mini-proyectos** funcionando (20% peso)  
- ✅ **Ejercicios conceptuales** (10% peso)

### **Proyecto final del área:**
**"Aplicación E-commerce Multi-Tier"**
- Frontend web (React/nginx)
- Backend API (Node.js/Python)
- Base de datos (PostgreSQL/MySQL)
- Cache (Redis)
- Monitoreo básico
- RBAC implementado
- Ingress con TLS

---

## 🔗 Navegación

### **⬅️ Áreas anteriores:**
- **[🐳 Área 1: Fundamentos Docker](../area-1-fundamentos-docker/README.md)**

### **➡️ Áreas siguientes:**
- **[🏭 Área 3: Implementación Práctica](../area-3-implementacion-practica/README.md)**
- **[☁️ Área 4: AKS y Producción](../area-4-aks-produccion/README.md)**

### **🏠 Navegación principal:**
- **[📚 Índice General del Curso](../README.md)**
- **[🎯 Proyecto Final](../proyecto-final/README.md)**
- **[📖 Recursos Adicionales](../recursos/README.md)**

---

## 📊 Resumen Ejecutivo

**🎯 Objetivo**: Transformar conocimientos de contenerización Docker en expertise completo de orquestación Kubernetes.

**⏱️ Duración**: 12 horas de contenido estructurado en 20 módulos especializados.

**🧪 Metodología**: Aprendizaje progresivo con teoría, laboratorios prácticos, y proyectos integradores.

**🚀 Resultado**: Capacidad completa para diseñar, implementar y gestionar aplicaciones en Kubernetes desde fundamentos hasta conceptos avanzados de producción.

**💼 Aplicación**: Preparación sólida para certificaciones CKA/CKAD y roles DevOps/SRE en entornos empresariales.

---

*Área diseñada para construcción progresiva de expertise en Kubernetes con base sólida en containerización Docker.*