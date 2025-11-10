# Módulo 15: Volúmenes en Kubernetes - Conceptos Fundamentales

## 📋 Índice

1. [Introducción a los Volúmenes](#introducción-a-los-volúmenes)
2. [Aplicaciones Stateless vs Stateful](#aplicaciones-stateless-vs-stateful)
3. [Ciclo de Vida de los Volúmenes](#ciclo-de-vida-de-los-volúmenes)
4. [Tipos de Volúmenes Básicos](#tipos-de-volúmenes-básicos)
   - [emptyDir](#emptydir)
   - [hostPath](#hostpath)
5. [Volúmenes en la Nube (Cloud Volumes)](#volúmenes-en-la-nube-cloud-volumes)
6. [PersistentVolume (PV) y PersistentVolumeClaim (PVC)](#persistentvolume-pv-y-persistentvolumeclaim-pvc)
7. [Políticas de Recuperación (Reclaim Policies)](#políticas-de-recuperación-reclaim-policies)
8. [Modos de Acceso (Access Modes)](#modos-de-acceso-access-modes)
9. [Storage Classes en Azure AKS](#storage-classes-en-azure-aks)
10. [Troubleshooting](#troubleshooting)
11. [Laboratorios Prácticos](#laboratorios-prácticos)
12. [Referencias](#referencias)

---

## Introducción a los Volúmenes

### ¿Qué es un Volumen en Kubernetes?

Un **volumen** en Kubernetes es un mecanismo para **persistir datos** más allá del ciclo de vida de un contenedor individual. Si ya tienes experiencia con Docker, sabrás que los volúmenes se utilizan para mantener datos cuando los contenedores son efímeros.

En Kubernetes, los volúmenes resuelven un problema fundamental:

> **¿Cómo garantizar que los datos sobrevivan cuando un Pod muere y es recreado?**

### El Problema: Sistema de Archivos Efímero

Por defecto, el sistema de archivos de un contenedor es **efímero**:

```
┌─────────────────────────────────────────────────────────┐
│                    Pod (efímero)                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │          Contenedor                               │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │   Sistema de archivos efímero               │  │  │
│  │  │                                             │  │  │
│  │  │   /var/data/  ← Datos importantes           │  │  │
│  │  │                                             │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
         ↓ Pod muere
         ↓
    ❌ Datos perdidos
```

**Problema**: Cuando el contenedor o el Pod muere, **todos los datos se pierden**.

### La Solución: Volúmenes como Objetos Independientes

Kubernetes abstrae el almacenamiento como un **objeto separado** del Pod:

```
┌──────────────────┐          ┌──────────────────────┐
│   Pod (efímero)  │          │  Volumen (persistente)│
│                  │          │                      │
│  Contenedor      │ ◄──────► │  /var/data/          │
│  monta volumen   │          │  (datos protegidos)  │
└──────────────────┘          └──────────────────────┘
         ↓                              ↑
    Pod muere                      Volumen intacto
         ↓                              ↑
┌──────────────────┐                    │
│  Nuevo Pod       │ ───────────────────┘
│  (mismo volumen) │
└──────────────────┘
    ✅ Datos recuperados
```

**Ventajas**:
- 📦 Los datos están **separados** del ciclo de vida del Pod
- 🔄 Los Pods pueden ser **recreados** sin perder información
- 🔒 Garantiza **persistencia** de datos críticos
- 🌐 Permite **compartir** datos entre contenedores en un Pod

### Conceptos Clave

| Concepto | Descripción |
|----------|-------------|
| **Volume** | Directorio accesible por contenedores en un Pod |
| **Mount** | Punto de montaje donde el volumen se conecta al sistema de archivos del contenedor |
| **Persistencia** | Capacidad de mantener datos después de que el Pod muere |
| **Backing Storage** | Almacenamiento físico subyacente (disco local, red, nube) |

---

## Aplicaciones Stateless vs Stateful

### Aplicaciones Stateless (Sin Estado)

**Definición**: Aplicaciones que **no necesitan guardar estado** entre peticiones. Pueden destruirse y recrearse sin afectar funcionalidad.

**Características**:
- ✅ No almacenan datos locales
- ✅ Cada petición es independiente
- ✅ Fáciles de escalar horizontalmente
- ✅ Tolerantes a fallos (se pueden recrear en cualquier nodo)

**Ejemplos**:
```yaml
# Aplicación web estática (stateless)
apiVersion: v1
kind: Pod
metadata:
  name: nginx-stateless
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    # No necesita volúmenes - solo sirve contenido estático
```

**Casos de uso**:
- 🌐 Servidores web estáticos (Nginx, Apache)
- 🔄 APIs RESTful sin sesión
- 📡 Proxies inversos
- 🎨 Frontends React/Angular

### Aplicaciones Stateful (Con Estado)

**Definición**: Aplicaciones que **necesitan persistir datos** entre ejecuciones. Los datos deben sobrevivir reinicios del Pod.

**Características**:
- 💾 Almacenan datos críticos (bases de datos, archivos)
- 🔗 Requieren identidad persistente
- 📊 Necesitan volúmenes para mantener estado
- ⚙️ Más complejas de escalar y gestionar

**Ejemplos**:
```yaml
# Base de datos (stateful)
apiVersion: v1
kind: Pod
metadata:
  name: postgres-stateful
spec:
  containers:
  - name: postgres
    image: postgres:alpine
    volumeMounts:
    - name: postgres-data
      mountPath: /var/lib/postgresql/data  # Datos persistentes
  volumes:
  - name: postgres-data
    persistentVolumeClaim:
      claimName: postgres-pvc  # Reclama almacenamiento persistente
```

**Casos de uso**:
- 🗄️ Bases de datos (PostgreSQL, MySQL, MongoDB)
- 📁 Sistemas de archivos compartidos
- 📊 Aplicaciones de análisis de datos
- 💬 Sistemas de mensajería (Kafka, RabbitMQ)

### Comparación

```
┌────────────────────────────────────────────────────────────┐
│                    STATELESS                               │
├────────────────────────────────────────────────────────────┤
│  Pod 1 (Nodo A)    Pod 2 (Nodo B)    Pod 3 (Nodo C)        │
│  [Nginx]           [Nginx]           [Nginx]               │
│    ↓                 ↓                 ↓                   │
│  Sin datos        Sin datos        Sin datos               │
│                                                            │
│  ✅ Cualquier Pod puede manejar cualquier petición         │
│  ✅ Fácil de escalar y reemplazar                          │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                    STATEFUL                                │
├────────────────────────────────────────────────────────────┤
│  Pod 1 (Nodo A)                                            │
│  [PostgreSQL]                                              │
│       ↓                                                    │
│  ┌─────────────┐                                           │
│  │ Volumen PV  │  ← Datos persistentes                     │
│  └─────────────┘                                           │
│                                                            │
│  ⚠️  Pod necesita reconectar al mismo volumen              │
│  ⚠️  Requiere estrategia de backup y recuperación          │
└────────────────────────────────────────────────────────────┘
```

---

## Ciclo de Vida de los Volúmenes

### Niveles de Persistencia

En Kubernetes, los volúmenes tienen diferentes **duraciones de vida** según su tipo:

#### 1. **Nivel Contenedor** (Más Efímero)

```
Contenedor 1 muere → Datos perdidos
       ↓
Contenedor 2 inicia → Sistema de archivos vacío
```

**Duración**: Solo mientras el contenedor existe  
**Ejemplo**: Sistema de archivos del contenedor (sin volúmenes)

#### 2. **Nivel Pod** (Intermedio)

```
┌─────────────────────────────────┐
│            Pod                  │
│  ┌──────────────────────────┐   │
│  │  Volumen emptyDir        │   │  ← Compartido por contenedores
│  └──────────────────────────┘   │
│         ↑            ↑          │
│  Contenedor 1  Contenedor 2     │
└─────────────────────────────────┘
   ↓ Contenedor 1 muere
   ↓ Contenedor 1 se recrea
   ✅ Datos siguen disponibles (el Pod aún vive)
   
   ↓ Pod muere
   ❌ Datos perdidos
```

**Duración**: Mientras el Pod existe  
**Ejemplo**: `emptyDir`

#### 3. **Nivel Nodo** (Más Duradero Localmente)

```
┌─────────────────────────────────┐
│         Nodo (VM)               │
│  ┌──────────────────────────┐   │
│  │  /mnt/data/ (hostPath)   │   │
│  └──────────────────────────┘   │
│         ↑                       │
│  ┌──────────────┐               │
│  │  Pod 1       │ muere         │
│  └──────────────┘               │
│         ↓                       │
│  ┌──────────────┐               │
│  │  Pod 2       │ ← Mismo nodo  │
│  └──────────────┘               │
│         ✅ Datos disponibles    │
└─────────────────────────────────┘

⚠️ Si Pod 2 se programa en otro nodo → Datos no disponibles
```

**Duración**: Mientras el nodo existe  
**Ejemplo**: `hostPath`

#### 4. **Nivel Cluster** (Persistencia Total)

```
┌──────────────────────────────────────────────────────┐
│              Cluster Kubernetes                      │
│  ┌────────────┐      ┌────────────┐                  │
│  │  Nodo A    │      │  Nodo B    │                  │
│  │            │      │            │                  │
│  │  Pod 1 ────┼──┐   │            │                  │
│  │  (muere)   │  │   │  Pod 2 ────┼───┐              │
│  └────────────┘  │   │  (recrea)  │   │              │
│                  │   └────────────┘   │              │
│                  │                    │              │
│                  └────────────────────┘              │
│                           ↓                          │
│              ┌─────────────────────────┐             │
│              │  PersistentVolume (PV)  │             │
│              │                         │             │
│              │  Azure Disk / Azure Files│            │
│              └─────────────────────────┘             │
│                  ✅ Datos persistentes               │
└──────────────────────────────────────────────────────┘
```

**Duración**: Independiente del Pod/Nodo  
**Ejemplo**: PersistentVolume con Azure Disk

### Resumen de Ciclo de Vida

| Tipo de Volumen | Alcance | Sobrevive reinicio de contenedor | Sobrevive reinicio de Pod | Sobrevive cambio de nodo | Persistencia |
|-----------------|---------|----------------------------------|---------------------------|--------------------------|--------------|
| **Contenedor (sin volumen)** | Contenedor | ❌ | ❌ | ❌ | Ninguna |
| **emptyDir** | Pod | ✅ | ❌ | ❌ | Temporal |
| **hostPath** | Nodo | ✅ | ✅ (mismo nodo) | ❌ | Local |
| **PersistentVolume** | Cluster | ✅ | ✅ | ✅ | Total |

### Flujo de Vida de un Volumen Persistente

```
1. Provisión
   ↓
   Administrador crea PV (o dinámicamente por StorageClass)
   
2. Binding
   ↓
   Desarrollador crea PVC → Se vincula automáticamente con PV disponible
   
3. Uso
   ↓
   Pod monta PVC → Escribe/lee datos
   
4. Liberación
   ↓
   PVC se elimina → PV queda "Released"
   
5. Reclaim (según política)
   ↓
   - Retain: PV se mantiene con datos
   - Delete: PV y disco se eliminan
   - Recycle (deprecated): PV se limpia para reutilizar
```

---

