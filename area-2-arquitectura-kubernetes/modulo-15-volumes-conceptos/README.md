# Capítulo 17: Volumes — Conceptos

En los capítulos anteriores logramos externalizar completamente la configuración de nuestras
aplicaciones: parámetros no sensibles en ConfigMaps, credenciales y certificados en Secrets.
Los Pods arrancan con exactamente la configuración que necesitan, inyectada en tiempo de
ejecución. Todo parece resuelto. Hasta que llega la primera base de datos.

El problema es fundamental a la naturaleza de los contenedores. El sistema de archivos de un
contenedor es efímero por diseño: cuando el contenedor muere, todo lo que escribió en su
sistema de archivos desaparece. Kubernetes reinicia el Pod — algo que hace continuamente en
respuesta a fallos, actualizaciones y rescheduling — y el nuevo Pod arranca con un sistema de
archivos completamente limpio. Para una aplicación stateless esto es perfecto. Para una base
de datos PostgreSQL, es catastrófico: todo el historial de transacciones, todas las tablas,
todos los datos de usuarios — borrados con cada reinicio. Para un servidor de archivos que
almacena documentos subidos por usuarios, cada reinicio del Pod vacía la carpeta de uploads
y los usuarios pierden sus archivos. Sin persistencia, solo puedes ejecutar aplicaciones que
no necesiten guardar nada entre reinicios.

Los Volumes en Kubernetes desacoplan el almacenamiento de datos del ciclo de vida del Pod.
Un volumen existe independientemente del contenedor que lo usa: si el contenedor muere y se
reinicia, el nuevo contenedor se conecta al mismo volumen y encuentra los datos intactos.

Piensa en guardar tu trabajo en un USB (el volumen) en lugar de solo en la RAM del ordenador.
Si el ordenador (el Pod) se apaga y reinicia, pierdes lo que estaba en RAM. Pero lo que
guardaste en el USB sigue ahí. El USB sobrevive al ciclo de vida del ordenador.

En este capítulo entenderás la arquitectura conceptual de los volúmenes en Kubernetes, la
diferencia entre almacenamiento efímero e persistente, los tipos básicos emptyDir y hostPath,
y el modelo de abstracción PersistentVolume / PersistentVolumeClaim que separa la provisión
del almacenamiento de su consumo. El capítulo siguiente implementará cada tipo de storage en
detalle.

---

## 📋 Índice de Contenido

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
│   Pod (efímero)  │          │ Volumen (persistente)│
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
│              │ Azure Disk / Azure Files│             │
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

## Tipos de Volúmenes Básicos

Kubernetes ofrece múltiples tipos de volúmenes para diferentes necesidades. Comenzaremos con los dos tipos más básicos: **emptyDir** y **hostPath**.

### emptyDir

#### ¿Qué es emptyDir?

**emptyDir** es el tipo de volumen más simple en Kubernetes. Como su nombre lo indica, es un **directorio vacío** que se crea cuando un Pod es asignado a un nodo y **existe solo mientras el Pod viva**.

#### ¿Cómo Funciona?

Imagina esta situación:

```
┌─────────────────────────────────────────────────────┐
│                    Pod                              │
│                                                     │
│  ┌──────────────────┐      ┌──────────────────┐     │
│  │  Contenedor 1    │      │  Contenedor 2    │     │
│  │                  │      │                  │     │
│  │  /var/cache/ ────┼──┐   │  /shared/data/ ──┼──┐  │
│  └──────────────────┘  │   └──────────────────┘  │  │
│                        │                         │  │
│                        └────────┬────────────────┘  │
│                                 ↓                   │
│                    ┌─────────────────────┐          │
│                    │  emptyDir Volume    │          │
│                    │  (directorio vacío) │          │
│                    └─────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

**Escenario práctico**:

1. **Se crea el Pod** → Kubernetes crea un directorio vacío en el nodo
2. **Contenedores montan el volumen** → Ambos contenedores pueden leer/escribir
3. **Contenedor 1 escribe datos** → Contenedor 2 puede leerlos inmediatamente
4. **Contenedor 1 muere** → Los datos siguen disponibles (el Pod aún vive)
5. **Contenedor 1 se reinicia** → Puede acceder a los datos que dejó
6. **El Pod muere** → ❌ El directorio y todos los datos se eliminan

#### Características Clave

| Característica | Valor |
|----------------|-------|
| **Alcance** | A nivel de Pod |
| **Duración** | Mientras el Pod exista |
| **Compartido entre contenedores** | ✅ Sí (en el mismo Pod) |
| **Sobrevive reinicio de contenedor** | ✅ Sí |
| **Sobrevive reinicio de Pod** | ❌ No |
| **Ubicación** | Disco del nodo (o RAM si `medium: Memory`) |

#### Casos de Uso

✅ **Cuándo usar emptyDir**:
- 📊 **Cache temporal** compartido entre contenedores
- 🔄 **Datos intermedios** en procesamiento por lotes
- 🔀 **Intercambio de archivos** entre contenedores sidecar
- 📝 **Logs temporales** antes de ser procesados
- 🧪 **Desarrollo y testing**

❌ **Cuándo NO usar emptyDir**:
- 💾 Datos que deben sobrevivir al Pod
- 🗄️ Bases de datos con información crítica
- 📁 Archivos de usuario permanentes
- 🔐 Configuraciones importantes

#### Sintaxis Básica

```yaml
volumes:
- name: cache-volume
  emptyDir: {}  # Directorio vacío por defecto
```

**Opciones disponibles**:
- `medium: ""` - Usa disco del nodo (por defecto)
- `medium: Memory` - Usa RAM del nodo (más rápido, más volátil)
- `sizeLimit: 128Mi` - Límite de tamaño

📁 **Ver implementación completa**: [Módulo 16 - Ejemplos emptyDir](../modulo-16-volumes-tipos-storage/ejemplos/01-emptydir/)

#### Visualización del Ciclo de Vida

```
Tiempo →

[1] Pod creado
    ↓
    ┌─────────────┐
    │  emptyDir   │  ← Directorio vacío creado
    │  (vacío)    │
    └─────────────┘

[2] Contenedor escribe datos
    ↓
    ┌─────────────┐
    │  emptyDir   │
    │  file1.txt  │  ← Datos escritos
    │  file2.txt  │
    └─────────────┘

[3] Contenedor muere y se reinicia
    ↓
    ┌─────────────┐
    │  emptyDir   │
    │  file1.txt  │  ← Datos siguen ahí (Pod vive)
    │  file2.txt  │
    └─────────────┘
    
[4] Pod eliminado
    ↓
    ❌ Directorio destruido
    ❌ Todos los datos perdidos
```

---

### hostPath

#### ¿Qué es hostPath?

**hostPath** monta un **archivo o directorio del nodo** (la máquina host) directamente en el Pod. Es similar a los volúmenes de Docker con `-v /host/path:/container/path`.

#### ¿Cómo Funciona?

```
┌──────────────────────────────────────────────────────┐
│                    Nodo (VM)                         │
│                                                      │
│  Sistema de archivos del nodo:                       │
│  ┌────────────────────────────────┐                  │
│  │  /mnt/data/                    │  ← Directorio    │
│  │    └── app-data/               │     en el nodo   │
│  │         └── database.db        │                  │
│  └────────────────────────────────┘                  │
│              ↑                                       │
│              │ monta                                 │
│              │                                       │
│  ┌───────────┴──────────────┐                        │
│  │        Pod               │                        │
│  │  ┌──────────────────┐    │                        │
│  │  │   Contenedor     │    │                        │
│  │  │                  │    │                        │
│  │  │  /data/  ────────┼────┼─→ apunta a /mnt/data/  │
│  │  │                  │    │   del nodo             │
│  │  └──────────────────┘    │                        │
│  └──────────────────────────┘                        │
└──────────────────────────────────────────────────────┘
```

#### El Problema con hostPath

**Escenario problemático**:

```
┌─────────────────────┐         ┌─────────────────────┐
│     Nodo 1          │         │     Nodo 2          │
│                     │         │                     │
│  /mnt/data/         │         │  /mnt/data/         │
│    └── info.txt     │         │    (vacío)          │
│                     │         │                     │
│  ┌───────────────┐  │         │                     │
│  │  Pod (v1)     │  │         │                     │
│  │  Lee/escribe  │  │         │                     │
│  │  en /mnt/data │  │         │                     │
│  └───────────────┘  │         │                     │
└─────────────────────┘         └─────────────────────┘
         ↓                               ↑
    Pod muere                     Pod recrea en Nodo 2
         ↓                               ↑
         └───────────────────────────────┘
         
Resultado: ❌ Pod (v2) no ve los datos de Pod (v1)
           Los datos están en Nodo 1, no en Nodo 2
```

⚠️ **Problema crítico**: 
- El volumen hostPath está **atado al nodo específico**
- Si el Pod se reprograma en otro nodo, **pierde acceso a los datos**
- No es portable entre nodos del cluster

#### Características Clave

| Característica | Valor |
|----------------|-------|
| **Alcance** | A nivel de Nodo |
| **Duración** | Mientras el nodo exista |
| **Portable entre nodos** | ❌ No |
| **Sobrevive reinicio de Pod** | ✅ Sí (en el mismo nodo) |
| **Comparte datos del host** | ✅ Sí |
| **Seguridad** | ⚠️ Riesgo elevado |

#### Casos de Uso

✅ **Cuándo usar hostPath** (solo desarrollo/testing):
- 🔧 **DaemonSets** que necesitan acceder a logs del nodo (`/var/log`)
- 🐳 **Monitoreo** que necesita acceder al socket de Docker (`/var/run/docker.sock`)
- 📊 **Métricas del sistema** (acceso a `/sys`, `/proc`)
- 🧪 **Desarrollo local** (compartir código fuente)

❌ **Cuándo NO usar hostPath**:
- 🚫 **Producción** (casi nunca)
- 💾 **Datos críticos** de aplicaciones
- 📁 **Bases de datos** en multi-nodo
- 🔄 **Aplicaciones que escalan** horizontalmente

#### Ejemplo Básico

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-hostpath
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    volumeMounts:
    - name: host-logs
      mountPath: /var/log/nginx  # Dentro del contenedor
      
  volumes:
  - name: host-logs
    hostPath:
      path: /tmp/nginx-logs      # ← Directorio en el nodo
      type: DirectoryOrCreate     # Crear si no existe
```

**Tipos de hostPath**:

```yaml
volumes:
- name: example
  hostPath:
    path: /path/on/host
    type: <tipo>
```

| Tipo | Descripción | Validación |
|------|-------------|------------|
| `DirectoryOrCreate` | Crea directorio si no existe | Recomendado para directorios |
| `Directory` | Debe existir como directorio | Falla si no existe |
| `FileOrCreate` | Crea archivo si no existe | Para archivos individuales |
| `File` | Debe existir como archivo | Falla si no existe |
| `Socket` | Socket UNIX debe existir | Para `/var/run/docker.sock` |
| `CharDevice` | Dispositivo de caracteres | Para dispositivos |
| `BlockDevice` | Dispositivo de bloques | Para dispositivos |

📁 **Ejemplo completo**: [Módulo 16 - Ejemplos hostPath](../modulo-16-volumes-tipos-storage/ejemplos/02-hostpath/pod-hostpath-basic.yaml)

#### Sintaxis Básica

```yaml
volumes:
- name: host-logs
  hostPath:
    path: /var/log        # Directorio en el nodo
    type: DirectoryOrCreate
```

**Tipos de hostPath disponibles**:

| Tipo | Descripción |
|------|-------------|
| `DirectoryOrCreate` | Crea directorio si no existe |
| `Directory` | Debe existir como directorio |
| `FileOrCreate` | Crea archivo si no existe |
| `File` | Debe existir como archivo |
| `Socket` | Socket UNIX (ej: `/var/run/docker.sock`) |

📁 **Ver implementación completa**: [Módulo 16 - Ejemplos hostPath](../modulo-16-volumes-tipos-storage/ejemplos/02-hostpath/)

#### Caso de Uso Legítimo: DaemonSets

El uso más común y aceptable de hostPath es con **DaemonSets** para acceder a recursos del nodo:
- Logs del sistema (`/var/log`)
- Socket de Docker (`/var/run/docker.sock`)
- Métricas del sistema (`/proc`, `/sys`)

Esto funciona porque cada Pod del DaemonSet accede solo a **su propio nodo**.

#### Riesgos de Seguridad

⚠️ **Advertencias críticas**:

```yaml
# ❌ PELIGROSO: Acceso total al nodo
hostPath:
  path: /
  
# ❌ PELIGROSO: Puede manipular el kubelet
hostPath:
  path: /var/lib/kubelet
  
# ❌ PELIGROSO: Puede reemplazar comandos del sistema
hostPath:
  path: /usr/bin
```

**Mejores prácticas de seguridad**:
- ✅ Usar `readOnly: true` cuando sea posible
- ✅ Limitar con PodSecurityPolicy/PodSecurity
- ✅ Usar rutas específicas, no directorios raíz
- ✅ Validar con `type` apropiado

#### Comparación: emptyDir vs hostPath

```
┌──────────────────────────────────────────────────────┐
│                  emptyDir                            │
├──────────────────────────────────────────────────────┤
│  Pod crea → Directorio vacío                         │
│  Pod muere → Datos perdidos                          │
│  ✅ Seguro (aislado)                                 │
│  ✅ Portable (funciona en cualquier nodo)            │
│  ❌ No persiste entre recreaciones de Pod            │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│                  hostPath                            │
├──────────────────────────────────────────────────────┤
│  Pod crea → Monta directorio del nodo                │
│  Pod muere → Datos sobreviven (en ese nodo)          │
│  ⚠️  Riesgo de seguridad (acceso al host)            │
│  ❌ No portable (atado a un nodo específico)         │
│  ✅ Datos persisten si Pod recrea en mismo nodo      │
└──────────────────────────────────────────────────────┘
```

#### Resumen

| Aspecto | emptyDir | hostPath |
|---------|----------|----------|
| **Ubicación** | Directorio temporal en nodo | Directorio/archivo del nodo |
| **Inicialización** | Vacío | Contenido del host |
| **Duración** | Vida del Pod | Vida del nodo |
| **Compartir entre Pods** | ❌ No | ✅ Sí (mismo nodo) |
| **Portabilidad** | ✅ Cualquier nodo | ❌ Nodo específico |
| **Seguridad** | ✅ Aislado | ⚠️ Expone sistema host |
| **Producción** | ✅ Testing/cache | ❌ Evitar (excepto DaemonSets) |

---

## Volúmenes en la Nube (Cloud Volumes)

### ¿Qué son los Cloud Volumes?

Los **Cloud Volumes** son volúmenes que utilizan servicios de almacenamiento proporcionados por proveedores de nube como Azure, AWS o Google Cloud. En el contexto de **Azure Kubernetes Service (AKS)**, tenemos principalmente dos opciones:

- **Azure Disk**: Almacenamiento de bloques (similar a EBS en AWS)
- **Azure Files**: Almacenamiento de archivos compartido (similar a EFS en AWS)

### El Problema con hostPath en la Nube

Recordemos el problema con `hostPath`:

```
┌─────────────────────┐         ┌─────────────────────┐
│   Nodo 1 (AKS)      │         │   Nodo 2 (AKS)      │
│                     │         │                     │
│  /mnt/data/         │         │  /mnt/data/         │
│    └── database.db  │         │    (diferente)      │
│         ↑           │         │                     │
│  ┌──────┴────────┐  │         │  ┌──────────────┐   │
│  │  Pod MySQL    │  │  muere  │  │  Pod MySQL   │   │
│  │  (datos aquí) │  ├────────→│  │  (sin datos) │   │
│  └───────────────┘  │         │  └──────────────┘   │
└─────────────────────┘         └─────────────────────┘
```

**Problema**: Los datos no viajan con el Pod entre nodos.

### La Solución: Almacenamiento en la Nube

Con almacenamiento en la nube, los datos están **fuera de los nodos**:

```
┌─────────────────────────────────────────────────────┐
│         Cluster AKS (Kubernetes)                    │
│                                                     │
│  ┌─────────────┐              ┌─────────────┐       │
│  │  Nodo 1     │              │  Nodo 2     │       │
│  │             │              │             │       │
│  │  Pod ───────┼────┐         │  Pod ───────┼───┐   │
│  │  (muere)    │    │         │  (recrea)   │   │   │
│  └─────────────┘    │         └─────────────┘   │   │
│                     │                           │   │
└─────────────────────┼───────────────────────────┼───┘
                      │                           │
                      └────────────┬──────────────┘
                                   ↓
                    ┌──────────────────────────┐
                    │   Azure Disk (PV)        │
                    │                          │
                    │   💾 Datos persistentes  │
                    │   (fuera del cluster)    │
                    └──────────────────────────┘
```

**Ventaja**: El Pod puede moverse entre nodos y seguir accediendo a los mismos datos.

### Azure Disk vs Azure Files

#### Azure Disk (Managed Disk)

**Características**:
- 💾 Almacenamiento de **bloques** (block storage)
- 🔒 **Un Pod a la vez** (ReadWriteOnce)
- ⚡ Alto rendimiento para bases de datos
- 💰 Diferentes niveles de rendimiento (Standard HDD, Standard SSD, Premium SSD, Ultra Disk)

**Analogía**: Es como un disco duro externo USB que solo puede conectarse a una computadora a la vez.

```yaml
# Ejemplo de volumen con Azure Disk (veremos sintaxis completa después)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
spec:
  accessModes:
  - ReadWriteOnce  # ← Solo un Pod
  storageClassName: managed-csi  # Azure Disk
  resources:
    requests:
      storage: 10Gi
```

**Casos de uso**:
- 🗄️ Bases de datos (MySQL, PostgreSQL, MongoDB)
- 📊 Aplicaciones que requieren alto I/O
- 💾 Volúmenes de un solo Pod

📁 **Ver implementación**: [Módulo 16 - Azure Disk](../modulo-16-volumes-tipos-storage/ejemplos/03-pvc-basico/)

#### Azure Files (SMB/NFS)

**Características**:
- 📁 Almacenamiento de **archivos** compartido (file storage)
- 🔀 **Múltiples Pods simultáneamente** (ReadWriteMany)
- 🌐 Accesible vía SMB 3.0 o NFS 4.1
- 📤 Puede montarse desde fuera del cluster

**Analogía**: Es como una carpeta compartida en red que varios usuarios pueden acceder al mismo tiempo.

**Casos de uso**:
- 📤 Archivos compartidos entre Pods
- 🖼️ Almacenamiento de assets estáticos (imágenes, videos)
- 📝 Logs centralizados
- 🔄 Aplicaciones que escalan horizontalmente con estado compartido

📁 **Ver implementación**: [Módulo 16 - Azure Files](../modulo-16-volumes-tipos-storage/ejemplos/03-pvc-basico/)

#### Comparación

```
┌────────────────────────────────────────────────────┐
│              Azure Disk                            │
├────────────────────────────────────────────────────┤
│                                                    │
│  Pod 1 ──────► 💾 Azure Disk (10GB)                │
│                                                    │
│  Pod 2 ──────► ❌ No puede conectar al mismo disco │
│                                                    │
│  ✅ Alto rendimiento                               │
│  ✅ Ideal para bases de datos                      │
│  ❌ Solo un Pod a la vez                           │
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│              Azure Files                           │
├────────────────────────────────────────────────────┤
│                                                    │
│  Pod 1 ──────┐                                     │
│              ├──► 📁 Azure Files (100GB)           │
│  Pod 2 ──────┤                                     │
│              │                                     │
│  Pod 3 ──────┘                                     │
│                                                    │
│  ✅ Múltiples Pods simultáneos                     │
│  ✅ Compartir archivos                             │
│  ⚠️  Rendimiento menor que Disk                    │
└────────────────────────────────────────────────────┘
```

### El Problema de Complejidad

Usar volúmenes de nube directamente en Pods requiere conocer detalles de infraestructura:
- Nombres de recursos en Azure
- URIs completos
- Tipos de sistemas de archivos
- Configuración de red y seguridad

**Solución**: Aquí es donde entran los **PersistentVolumes (PV)** y **PersistentVolumeClaims (PVC)**.

---

## PersistentVolume (PV) y PersistentVolumeClaim (PVC)

### La Abstracción: PV y PVC

Kubernetes introduce dos conceptos para **abstraer** el almacenamiento:

1. **PersistentVolume (PV)**: Representación de un recurso de almacenamiento en el cluster
2. **PersistentVolumeClaim (PVC)**: Solicitud de almacenamiento por parte de un usuario

### Analogía del Mundo Real

Piensa en el sistema como un **estacionamiento**:

```
┌─────────────────────────────────────────────────────┐
│            Estacionamiento (Cluster)                │
│                                                     │
│  🅿️  Espacio 1 (PV)  - 50 m² - Techado              │
│  🅿️  Espacio 2 (PV)  - 30 m² - Descubierto          │
│  🅿️  Espacio 3 (PV)  - 100 m² - Con cargador        │
│                                                     │
│  👤 Usuario (Pod): "Necesito espacio para mi auto"  │
│      ↓                                              │
│  📋 Ticket (PVC): "Solicito 40 m², techado"         │
│      ↓                                              │
│  ✅ Sistema asigna: Espacio 1 (50 m²)               │
│                                                     │
│  El usuario no necesita saber:                      │
│  - Dónde está exactamente el espacio                │
│  - Cómo se construyó                                │
│  - Detalles técnicos de infraestructura             │
└─────────────────────────────────────────────────────┘
```

### ¿Qué es un PersistentVolume (PV)?

Un **PersistentVolume (PV)** es un **recurso de almacenamiento** en el cluster que ha sido aprovisionado por un administrador o dinámicamente mediante Storage Classes.

**Características clave**:
- 🏗️ Representa almacenamiento **real** (Azure Disk, Azure Files, NFS, etc.)
- 👨‍💼 Gestionado por **administradores** del cluster
- ♻️ Tiene un **ciclo de vida independiente** de los Pods
- 📏 Define capacidad, modos de acceso, políticas de recuperación

**Ejemplo de PV con Azure Disk**:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-azure-disk
spec:
  capacity:
    storage: 10Gi                # Tamaño del volumen
  accessModes:
    - ReadWriteOnce              # Solo un Pod a la vez
  persistentVolumeReclaimPolicy: Retain  # Qué hacer al eliminar PVC
  storageClassName: managed-csi  # Clase de almacenamiento
  csi:
    driver: disk.csi.azure.com   # Driver de Azure Disk
    volumeHandle: /subscriptions/.../myDisk
    volumeAttributes:
      fsType: ext4
```

### ¿Qué es un PersistentVolumeClaim (PVC)?

Un **PersistentVolumeClaim (PVC)** es una **solicitud de almacenamiento** por parte de un usuario.

**Características clave**:
- 👨‍💻 Creado por **desarrolladores**
- 📋 Especifica requisitos (tamaño, modo de acceso)
- 🔗 Se vincula (bind) automáticamente con un PV que cumpla los requisitos
- 📦 Es lo que los **Pods utilizan** para montar volúmenes

**Ejemplo de PVC**:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-for-database
spec:
  accessModes:
    - ReadWriteOnce        # Necesito acceso exclusivo
  resources:
    requests:
      storage: 8Gi         # Solicito 8 GiB
  storageClassName: managed-csi  # Usar Azure Disk
```

### Flujo Completo: De la Solicitud al Uso

```
┌─────────────────────────────────────────────────────────┐
│  Paso 1: Crear PersistentVolume (PV)                    │
│  (Administrador o dinámico vía StorageClass)            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  apiVersion: v1                                         │
│  kind: PersistentVolume                                 │
│  metadata:                                              │
│    name: pv-10gb                                        │
│  spec:                                                  │
│    capacity:                                            │
│      storage: 10Gi                                      │
│    accessModes:                                         │
│      - ReadWriteOnce                                    │
│    storageClassName: managed-csi                        │
│                                                         │
│  Estado: Available (Disponible para reclamar)           │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  Paso 2: Crear PersistentVolumeClaim (PVC)              │
│  (Desarrollador)                                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  apiVersion: v1                                         │
│  kind: PersistentVolumeClaim                            │
│  metadata:                                              │
│    name: pvc-database                                   │
│  spec:                                                  │
│    accessModes:                                         │
│      - ReadWriteOnce                                    │
│    resources:                                           │
│      requests:                                          │
│        storage: 8Gi  # ← Solicito 8Gi                   │
│    storageClassName: managed-csi                        │
│                                                         │
│  Estado: Pending → Bound (vinculado a pv-10gb)          │
└─────────────────────────────────────────────────────────┘
                        ↓
                  Binding automático
                        ↓
┌─────────────────────────────────────────────────────────┐
│  Paso 3: Usar PVC en un Pod                             │
│  (Desarrollador)                                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  apiVersion: v1                                         │
│  kind: Pod                                              │
│  metadata:                                              │
│    name: postgres                                       │
│  spec:                                                  │
│    containers:                                          │
│    - name: postgres                                     │
│      image: postgres:alpine                             │
│      volumeMounts:                                      │
│      - name: data                                       │
│        mountPath: /var/lib/postgresql/data              │
│    volumes:                                             │
│    - name: data                                         │
│      persistentVolumeClaim:                             │
│        claimName: pvc-database  # ← Usa el PVC          │
│                                                         │
│  ✅ Pod escribe/lee datos en Azure Disk                 │
└─────────────────────────────────────────────────────────┘
```

📁 **Ejemplo completo manual**: [Módulo 16 - PV/PVC Manual](../modulo-16-volumes-tipos-storage/ejemplos/04-pv-pvc-manual/pv-pvc-manual.yaml)

### Binding (Vinculación)

El proceso de **binding** es automático y sigue estas reglas:

```
PVC solicita:                    PV disponible:
- storage: 8Gi                   - capacity: 10Gi
- accessMode: ReadWriteOnce      - accessMode: ReadWriteOnce
- storageClass: managed-csi      - storageClass: managed-csi

¿Coincide?
- ✅ Capacidad: PV (10Gi) >= PVC (8Gi)
- ✅ AccessMode: Coinciden
- ✅ StorageClass: Coinciden

Resultado: BOUND (vinculado)
```

**Estados del PVC**:

| Estado | Descripción |
|--------|-------------|
| **Pending** | Esperando un PV que cumpla los requisitos |
| **Bound** | Vinculado exitosamente a un PV |
| **Lost** | El PV asociado ya no existe |

**Verificar estado**:

```bash
# Ver PVCs
kubectl get pvc
# NAME             STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# pvc-database     Bound    pv-10gb    10Gi       RWO            managed-csi    5m

# Ver PVs
kubectl get pv
# NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   AGE
# pv-10gb   10Gi       RWO            Retain           Bound    default/pvc-database   managed-csi    10m
```

### Provisioning: Estático vs Dinámico

#### Provisioning Estático

**El administrador crea PVs manualmente**:

```yaml
# Administrador crea PV
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-static-10gb
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: disk.csi.azure.com
    volumeHandle: /subscriptions/.../existingDisk
```

```yaml
# Desarrollador crea PVC que se vincula al PV
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-static
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Ventajas**: Control total sobre el almacenamiento  
**Desventajas**: Administrador debe crear PVs anticipadamente

#### Provisioning Dinámico (Recomendado)

**No se crean PVs manualmente. Se usa una StorageClass**:

```yaml
# Solo crear PVC - PV se crea automáticamente
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-dynamic
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi  # ← StorageClass crea PV automáticamente
  resources:
    requests:
      storage: 10Gi
```

**Proceso automático**:

```
1. PVC creado
   ↓
2. StorageClass "managed-csi" detecta el PVC
   ↓
3. StorageClass crea Azure Disk de 10Gi automáticamente
   ↓
4. StorageClass crea PV que apunta al Azure Disk
   ↓
5. PVC se vincula al PV recién creado
   ↓
6. ✅ Listo para usar
```

**Ventajas**: 
- ✅ No requiere intervención del administrador
- ✅ Crea almacenamiento bajo demanda
- ✅ Más ágil para desarrolladores

**En AKS, esto es lo más común** (veremos StorageClasses en detalle después).

📁 **Ejemplo completo dinámico**: [Módulo 16 - PVC Dinámico](../modulo-16-volumes-tipos-storage/ejemplos/03-pvc-basico/pvc-dynamic-azure.yaml)

### Cómo Usar PVC en un Pod

```yaml
volumes:
- name: postgres-storage
  persistentVolumeClaim:
    claimName: postgres-pvc  # ← Referencia al PVC
```

**Flujo de uso**:
1. PVC solicita almacenamiento (ej: 20Gi con Azure Disk)
2. AKS crea automáticamente un Azure Managed Disk
3. PVC se vincula al PV automáticamente
4. Pod monta el PVC
5. Si el Pod muere y se recrea → datos intactos ✅

📁 **Ver implementación completa**: [Módulo 16 - PVC con PostgreSQL](../modulo-16-volumes-tipos-storage/ejemplos/03-pvc-basico/)

### Diagrama Completo del Flujo

```
┌────────────────────────────────────────────────────────────────┐
│                    Cluster AKS                                 │
│                                                                │
│  ┌──────────────┐                                              │
│  │ Desarrollador │                                             │
│  └───────┬──────┘                                              │
│          │                                                     │
│          │ 1. Crea PVC                                         │
│          ↓                                                     │
│  ┌────────────────────────┐                                    │
│  │  PersistentVolumeClaim │                                    │
│  │  - storage: 20Gi       │                                    │
│  │  - class: managed-csi  │                                    │
│  └───────┬────────────────┘                                    │
│          │                                                     │
│          │ 2. StorageClass detecta                             │
│          ↓                                                     │
│  ┌────────────────────────┐                                    │
│  │   StorageClass         │                                    │
│  │   (managed-csi)        │                                    │
│  └───────┬────────────────┘                                    │
│          │                                                     │
│          │ 3. Provisiona disco                                 │
│          ↓                                                     │
└──────────┼─────────────────────────────────────────────────────┘
           │
           ↓
┌──────────────────────────────────────────────────────────────┐
│                    Azure Cloud                               │
│                                                              │
│  ┌──────────────────────────────────┐                        │
│  │     Azure Managed Disk           │                        │
│  │     - 20 GiB                     │  ← Disco real creado   │
│  │     - Premium SSD                │                        │
│  └──────────────────────────────────┘                        │
│                  ↑                                           │
└──────────────────┼───────────────────────────────────────────┘
                   │
                   │ 4. PV creado automáticamente
                   ↓
┌──────────────────────────────────────────────────────────────┐
│                    Cluster AKS                               │
│                                                              │
│  ┌────────────────────────┐                                  │
│  │   PersistentVolume     │                                  │
│  │   - 20Gi               │  ← Representa el disco Azure     │
│  └───────┬────────────────┘                                  │
│          │                                                   │
│          │ 5. Binding                                        │
│          ↓                                                   │
│  ┌────────────────────────┐                                  │
│  │  PVC (Bound)           │                                  │
│  └───────┬────────────────┘                                  │
│          │                                                   │
│          │ 6. Pod monta PVC                                  │
│          ↓                                                   │
│  ┌────────────────────────┐                                  │
│  │  Pod (PostgreSQL)      │                                  │
│  │  - Escribe datos       │                                  │
│  └────────────────────────┘                                  │
│                                                              │
│  ✅ Datos persistentes en Azure Disk                         │
│  ✅ Pod puede moverse entre nodos                            │
│  ✅ Datos sobreviven reinicios                               │
└──────────────────────────────────────────────────────────────┘
```

### Resumen: PV vs PVC

| Aspecto | PersistentVolume (PV) | PersistentVolumeClaim (PVC) |
|---------|----------------------|----------------------------|
| **¿Quién lo crea?** | Administrador o StorageClass | Desarrollador |
| **¿Qué representa?** | Almacenamiento real | Solicitud de almacenamiento |
| **Alcance** | Cluster | Namespace |
| **Ciclo de vida** | Independiente de Pods | Independiente de Pods |
| **Usa en Pod** | ❌ No directamente | ✅ Sí (vía `persistentVolumeClaim`) |
| **Analogía** | Disco duro físico | Ticket de solicitud |

---

## Políticas de Recuperación (Reclaim Policies)

### ¿Qué son las Reclaim Policies?

Las **Políticas de Recuperación** (Reclaim Policies) definen **qué sucede con un PersistentVolume** cuando el PersistentVolumeClaim que lo usa es **eliminado**.

### El Escenario

Imagina esta situación:

```
Tiempo 0: Estado Inicial
┌────────────────────────────────────────────────┐
│  PVC (pvc-database)  ◄───────► PV (pv-10gb)    │
│       Bound                     Bound          │
│         ↓                          ↓           │
│    Pod MySQL                  Azure Disk       │
│    (escribe datos)            (con datos)      │
└────────────────────────────────────────────────┘

Tiempo 1: Eliminar PVC
┌────────────────────────────────────────────────┐
│  PVC (pvc-database)  ❌ ELIMINADO              │
│                                                │
│  ¿Qué pasa con el PV?                          │
│  ¿Qué pasa con el Azure Disk?                  │
│  ¿Qué pasa con los datos?                      │
└────────────────────────────────────────────────┘
```

La **Reclaim Policy** responde estas preguntas.

### Las Tres Políticas

#### 1. Retain (Retener) - Recomendada para Producción

**Comportamiento**: 
- ✅ El PV **NO** se elimina
- ✅ El disco Azure **NO** se elimina  
- ✅ Los datos **se mantienen**
- ⚠️ El PV queda en estado **Released** (no disponible para nuevos claims)

**Sintaxis**:
```yaml
spec:
  persistentVolumeReclaimPolicy: Retain
```

**Flujo con Retain**:

```
[1] Estado inicial
    PVC ◄──► PV (Bound) ◄──► Azure Disk (con datos)

[2] Eliminar PVC
    kubectl delete pvc pvc-database

[3] Resultado
    PV (Released) ◄──► Azure Disk (datos intactos)
    
    Estado PV: Released
    - No está disponible para nuevos PVCs
    - Administrador debe intervenir para recuperar/eliminar

[4] Opciones del administrador:
    - Recuperar datos y reutilizar PV
    - Mantener como backup
    - Eliminar manualmente
```

**Ventajas**:
- ✅ Previene **pérdida accidental** de datos
- ✅ Permite **recuperación** de datos
- ✅ Ideal para **producción**

**Desventajas**:
- ⚠️ Requiere **intervención manual** del administrador

📁 **Ver implementación**: [Módulo 16 - Retain Policy](../modulo-16-volumes-tipos-storage/ejemplos/06-reclaim-policies/)

#### 2. Delete (Eliminar) - Por Defecto en Provisioning Dinámico

**Comportamiento**:
- ❌ El PV **se elimina** automáticamente
- ❌ El disco Azure **se elimina** automáticamente
- ❌ Los datos **se pierden** permanentemente

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-delete-example
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete  # ← Política Delete
  storageClassName: managed-csi
  csi:
    driver: disk.csi.azure.com
    volumeHandle: /subscriptions/.../myDisk
```

**Flujo con Delete**:

```
[1] Estado inicial
    PVC ◄──► PV (Bound) ◄──► Azure Disk (con datos)

[2] Eliminar PVC
    kubectl delete pvc pvc-database

[3] Resultado automático
    ❌ PV eliminado
    ❌ Azure Disk eliminado
    ❌ Datos perdidos permanentemente
    
[4] No hay vuelta atrás
    Los datos se han ido para siempre
```

**⚠️ Importante en AKS**:
```yaml
# StorageClass por defecto en AKS usa Delete
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi
provisioner: disk.csi.azure.com
reclaimPolicy: Delete  # ← Delete por defecto
parameters:
  skuname: StandardSSD_LRS
```

Esto significa:
- PVCs creados dinámicamente usan `Delete` por defecto
- **Cuidado**: Eliminar PVC = perder datos permanentemente

**Ventajas**:
- ✅ **Limpieza automática** (no discos huérfanos)
- ✅ **Costos optimizados** (no se paga por discos no usados)
- ✅ Ideal para **desarrollo/testing**

**Desventajas**:
- ❌ **Pérdida de datos** si se elimina PVC accidentalmente
- ❌ No hay oportunidad de **recuperación**

📁 **Ver implementación**: [Módulo 16 - Delete Policy](../modulo-16-volumes-tipos-storage/ejemplos/06-reclaim-policies/)

#### 3. Recycle (Reciclar) - DEPRECATED ⚠️

**Estado**: Obsoleto desde Kubernetes 1.15+

**Comportamiento** (ya no recomendado):
- El PV se mantiene
- Los datos se **eliminan** (`rm -rf` en el volumen)
- El PV queda **Available** para nuevos claims

⚠️ **No usar** - Reemplazado por **provisioning dinámico**

### Comparación de Políticas

```
┌──────────────────────────────────────────────────────────┐
│                     RETAIN                               │
├──────────────────────────────────────────────────────────┤
│  PVC eliminado → PV: Released                            │
│                → Disco: Intacto                          │
│                → Datos: Preservados                      │
│                                                          │
│  ✅ Producción                                           │
│  ✅ Datos críticos                                       │
│  ⚠️  Requiere limpieza manual                            │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                     DELETE                               │
├──────────────────────────────────────────────────────────┤
│  PVC eliminado → PV: Eliminado                           │
│                → Disco: Eliminado                        │
│                → Datos: Perdidos                         │
│                                                          │
│  ✅ Desarrollo/Testing                                   │
│  ✅ Datos temporales                                     │
│  ❌ Riesgo de pérdida de datos                           │
└──────────────────────────────────────────────────────────┘
```

### Cambiar Política de un PV

**Concepto**: Puedes cambiar la política de un PV existente para proteger datos antes de eliminar un PVC.

```bash
# Cambiar de Delete a Retain (proteger datos)
kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

⚠️ **Recomendación**: Cambiar a `Retain` ANTES de eliminar PVCs importantes en producción.

📁 **Ver comandos detallados**: [Módulo 16 - Gestión de Reclaim Policies](../modulo-16-volumes-tipos-storage/README.md#reclaim-policies)

### Tabla Resumen

| Política | PV Después de Eliminar PVC | Disco Cloud | Datos | Uso Recomendado |
|----------|---------------------------|-------------|-------|-----------------|
| **Retain** | Released (manual) | Intacto | ✅ Preservados | 🏭 Producción |
| **Delete** | Eliminado | Eliminado | ❌ Perdidos | 🧪 Dev/Testing |
| **Recycle** | Available (reciclado) | Limpiado | ❌ Eliminados | ⚠️ Deprecated |

---

## Modos de Acceso (Access Modes)

### ¿Qué son los Access Modes?

Los **Modos de Acceso** (Access Modes) definen **cómo un volumen puede ser montado** por los Pods:

- ¿Puede montarse en **múltiples Pods**?
- ¿Puede tener **escritura simultánea**?
- ¿Es **solo lectura**?

### Los Tres Modos de Acceso

#### 1. ReadWriteOnce (RWO) - Más Común

**Significado**: 
- ✅ Lectura y escritura
- ⚠️ Solo **un nodo** a la vez puede montar el volumen
- ⚠️ Múltiples Pods en el **mismo nodo** pueden compartirlo

**Sintaxis**:
```yaml
spec:
  accessModes:
    - ReadWriteOnce  # RWO
```

**Escenario**:

```
┌──────────────────────────────────────────────────────┐
│                  Nodo 1                              │
│                                                      │
│  Pod A ──┐                                           │
│          ├──► Azure Disk (RWO) ✅ Ambos pueden       │
│  Pod B ──┘                         leer/escribir     │
│                                    (mismo nodo)      │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│                  Nodo 2                              │
│                                                      │
│  Pod C ──────► Azure Disk (RWO) ❌ NO puede montar   │
│                                    (diferente nodo)  │
└──────────────────────────────────────────────────────┘
```

**Compatible con**: Azure Disk, mayoría de almacenamientos de bloques  
**Casos de uso**: Bases de datos, StatefulSets, aplicaciones de un solo Pod

📁 **Ver implementación**: [Módulo 16 - Access Modes RWO](../modulo-16-volumes-tipos-storage/ejemplos/05-access-modes/)

#### 2. ReadOnlyMany (ROX)

**Significado**:
- ✅ Solo **lectura** (no escritura)
- ✅ **Múltiples nodos** pueden montar simultáneamente

**Sintaxis**:
```yaml
spec:
  accessModes:
    - ReadOnlyMany  # ROX
```

**Escenario**:

```
┌──────────────────────┐
│   Nodo 1             │    Todos pueden LEER
│   Pod A (lee) ───┐   │    Nadie puede ESCRIBIR
└──────────────────┼───┘
                   │
┌──────────────────┼───┐
│   Nodo 2         ↓   │
│   Pod B (lee) ───┼───► Volumen (ROX)
└──────────────────┼───┘
                   │
┌──────────────────┼───┐
│   Nodo 3         ↓   │
│   Pod C (lee) ───┘   │
└──────────────────────┘
```

**Compatible con**: Azure Files (Azure Disk NO soporta ROX)  
**Casos de uso**: Configuraciones compartidas, assets estáticos, datos de referencia

📁 **Ver implementación**: [Módulo 16 - Access Modes ROX](../modulo-16-volumes-tipos-storage/ejemplos/05-access-modes/)

#### 3. ReadWriteMany (RWX) - Compartido

**Significado**:
- ✅ Lectura y escritura
- ✅ **Múltiples nodos** pueden montar simultáneamente
- ✅ **Escritura concurrente** (requiere sistema de archivos compatible)

**Sintaxis**:
```yaml
spec:
  accessModes:
    - ReadWriteMany  # RWX
  storageClassName: azurefile-csi  # Azure Files soporta RWX
```

**Escenario**:

```
┌──────────────────────┐
│   Nodo 1             │    Todos pueden LEER y ESCRIBIR
│   Pod A (R/W) ───┐   │    simultáneamente
└──────────────────┼───┘
                   │
┌──────────────────┼───┐
│   Nodo 2         ↓   │
│   Pod B (R/W) ───┼───► Azure Files (RWX)
└──────────────────┼───┘
                   │
┌──────────────────┼───┐
│   Nodo 3         ↓   │
│   Pod C (R/W) ───┘   │
└──────────────────────┘
```

**Compatible con**: Azure Files (Azure Disk NO soporta RWX)  
**Casos de uso**: Cargas de archivos compartidos, logs centralizados, CMS multi-réplica

⚠️ **Importante**: Requiere sistema de archivos compatible con escritura concurrente (SMB, NFS)

📁 **Ver implementación**: [Módulo 16 - Access Modes RWX](../modulo-16-volumes-tipos-storage/ejemplos/05-access-modes/)

### Soporte por Tipo de Almacenamiento en Azure

| Tipo de Almacenamiento | RWO | ROX | RWX |
|------------------------|-----|-----|-----|
| **Azure Disk** | ✅ | ❌ | ❌ |
| **Azure Files (SMB)** | ✅ | ✅ | ✅ |
| **Azure Files (NFS)** | ✅ | ✅ | ✅ |

### Tabla Resumen de Access Modes

| Modo | Abreviatura | Lectura | Escritura | Múltiples Nodos | Ejemplo Azure |
|------|-------------|---------|-----------|-----------------|---------------|
| **ReadWriteOnce** | RWO | ✅ | ✅ | ❌ (solo 1 nodo) | Azure Disk |
| **ReadOnlyMany** | ROX | ✅ | ❌ | ✅ | Azure Files (lectura) |
| **ReadWriteMany** | RWX | ✅ | ✅ | ✅ | Azure Files (R/W) |

📁 **Ver comparación práctica**: [Módulo 16 - Comparación Access Modes](../modulo-16-volumes-tipos-storage/ejemplos/05-access-modes/access-modes-comparison.yaml)

---

## Storage Classes en Azure AKS

### ¿Qué es una StorageClass?

Una **StorageClass** es una abstracción que permite **provisioning dinámico** de volúmenes. Define:

- 🔧 **Provisioner**: Quién crea el volumen (Azure Disk, Azure Files)
- ⚙️ **Parámetros**: Tipo de disco (SSD, HDD), replicación, etc.
- ♻️ **Reclaim Policy**: Qué hacer al eliminar PVC
- 🔗 **Binding Mode**: Cuándo crear el volumen

### StorageClasses Predeterminadas en AKS

AKS incluye varias StorageClasses por defecto:

```bash
# Ver StorageClasses disponibles
kubectl get storageclass

# NAME                    PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION
# azurefile               file.csi.azure.com   Delete          Immediate              true
# azurefile-csi           file.csi.azure.com   Delete          Immediate              true
# azurefile-csi-premium   file.csi.azure.com   Delete          Immediate              true
# azurefile-premium       file.csi.azure.com   Delete          Immediate              true
# default (default)       disk.csi.azure.com   Delete          WaitForFirstConsumer   true
# managed                 disk.csi.azure.com   Delete          WaitForFirstConsumer   true
# managed-csi             disk.csi.azure.com   Delete          WaitForFirstConsumer   true
# managed-csi-premium     disk.csi.azure.com   Delete          WaitForFirstConsumer   true
# managed-premium         disk.csi.azure.com   Delete          WaitForFirstConsumer   true
```

### StorageClasses Principales en AKS

AKS incluye StorageClasses predeterminadas. Ver con:

```bash
kubectl get storageclass
```

**Tipos principales**:

| StorageClass | Tipo | Rendimiento | Access Modes | Uso |
|--------------|------|-------------|--------------|-----|
| **managed-csi** | Azure Disk SSD | Medio | RWO | Apps generales |
| **managed-csi-premium** | Azure Disk Premium | Alto | RWO | Producción, DBs |
| **azurefile-csi** | Azure Files Standard | Bajo | RWO/ROX/RWX | Archivos compartidos |
| **azurefile-csi-premium** | Azure Files Premium | Alto | RWO/ROX/RWX | Compartido alta performance |

### Parámetros Clave de StorageClass

**Volume Binding Mode**:
- `WaitForFirstConsumer` - Crea disco cuando Pod se programa (recomendado para Disk)
- `Immediate` - Crea disco inmediatamente (usado en Files)

**Allow Volume Expansion**:
- `allowVolumeExpansion: true` - Permite expandir volúmenes sin recrearlos
- ⚠️ Solo puede aumentar tamaño, no reducir

**Reclaim Policy**:
- `reclaimPolicy: Delete` - Elimina disco al eliminar PVC (por defecto)
- `reclaimPolicy: Retain` - Mantiene disco al eliminar PVC (producción)

📁 **Ver StorageClasses personalizadas**: [Módulo 16 - StorageClasses](../modulo-16-volumes-tipos-storage/ejemplos/03-pvc-basico/storageclass-custom.yaml)

---

## Troubleshooting

### Problemas Comunes y Causas

#### 1. PVC en Estado Pending

**Posibles causas**:
- No hay PV disponible (provisioning estático)
- StorageClass no existe
- Cuota de Azure agotada
- Error de permisos en Azure
- Zona de disponibilidad incompatible

**Diagnóstico básico**:
```bash
kubectl describe pvc <pvc-name>
```

#### 2. Pod no puede montar PVC

**Posibles causas**:
- PVC no está en estado Bound
- Access Mode incompatible (ej: RWO en múltiples nodos)
- Disco ya montado en otro nodo
- Problema de red entre nodo y almacenamiento
- PVC y Pod en diferentes namespaces

**Diagnóstico básico**:
```bash
kubectl describe pod <pod-name>
kubectl get pvc -n <namespace>
```

#### 3. Volumen lleno

**Posibles causas**:
- Aplicación genera más datos que la capacidad del volumen
- Logs no rotados
- Datos temporales acumulados

**Solución conceptual**: Expandir volumen (si `allowVolumeExpansion: true`)

#### 4. Rendimiento lento

**Posibles causas**:
- StorageClass inadecuada (Standard vs Premium)
- Límites IOPS alcanzados
- Tamaño del disco afecta rendimiento
- Múltiples Pods accediendo (RWX)

**Solución conceptual**: Migrar a Premium SSD o disco más grande

#### 5. PV en Released no reutilizable

**Causa**: PVC eliminado con política Retain

**Solución conceptual**: Eliminar y recrear PV, o cambiar a nueva reclaim policy

#### 6. Error "Volume already attached"

**Causa**: Volumen RWO intenta montarse en múltiples nodos

**Solución conceptual**: Asegurar que Pod con RWO esté en un solo nodo

📁 **Ver soluciones detalladas**: [Módulo 16 - Troubleshooting Práctico](../modulo-16-volumes-tipos-storage/README.md#troubleshooting)

---

## Resumen del Módulo

### Conceptos Clave Aprendidos

✅ **Volúmenes básicos**:
- emptyDir: Temporal, a nivel de Pod
- hostPath: Monta directorio del nodo (solo desarrollo/DaemonSets)

✅ **Almacenamiento en la nube**:
- Azure Disk: Block storage, RWO, alto rendimiento
- Azure Files: File storage, RWX, archivos compartidos

✅ **Abstracción PV/PVC**:
- PV: Recurso de almacenamiento
- PVC: Solicitud de almacenamiento
- Binding automático
- Provisioning estático vs dinámico

✅ **Políticas de recuperación**:
- Retain: Preserva datos (producción)
- Delete: Elimina datos (desarrollo)
- Recycle: Deprecated

✅ **Modos de acceso**:
- ReadWriteOnce (RWO): Un nodo a la vez
- ReadOnlyMany (ROX): Múltiples nodos, solo lectura
- ReadWriteMany (RWX): Múltiples nodos, lectura/escritura

✅ **StorageClasses**:
- Provisioning dinámico
- managed-csi: Standard SSD
- managed-csi-premium: Premium SSD
- azurefile-csi: Azure Files compartido

### Próximos Pasos

📘 **Práctica**: Continúa con el [Módulo 16 - Volúmenes: Tipos de Storage](../modulo-16-volumes-tipos-storage/) para:
- Implementar todos los ejemplos prácticos
- Realizar laboratorios hands-on
- Troubleshooting con comandos reales
- Casos de uso de producción
```

**Causas comunes**:

#### Causa 1: PVC no existe

```yaml
spec:
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: non-existent-pvc  # ← No existe
```

**Solución**:
```bash
# Verificar PVC existe
kubectl get pvc non-existent-pvc

# Crear PVC si falta
kubectl apply -f pvc.yaml
```

#### Causa 2: Volumen ya montado en otro nodo (RWO)

```bash
kubectl describe pod my-pod
# Events:
#   Warning  FailedAttachVolume  AttachVolume.Attach failed: volume is already attached to node "aks-nodepool1-12345"
```

**Escenario**:
```
Nodo 1: Pod A usando PVC (RWO)
Nodo 2: Pod B intenta usar el mismo PVC ← ❌ Falla
```

**Solución**:
```bash
# Opción 1: Eliminar Pod en Nodo 1
kubectl delete pod pod-a

# Opción 2: Escalar a 0 réplicas y volver a 1
kubectl scale deployment my-app --replicas=0
kubectl scale deployment my-app --replicas=1

# Opción 3: Usar ReadWriteMany si necesitas múltiples Pods
# (cambiar a Azure Files)
```

#### Causa 3: Node selector incompatible con zona del disco

```bash
kubectl describe pod my-pod
# Events:
#   Warning  FailedMount  volume is in zone "eastus-1" but node is in zone "eastus-2"
```

**Solución**: Usar `WaitForFirstConsumer` en StorageClass:
```yaml
volumeBindingMode: WaitForFirstConsumer  # ← Espera al Pod para crear disco en zona correcta
```

### Problema 3: No se puede eliminar PVC

**Síntoma**:
```bash
kubectl delete pvc my-pvc
# persistentvolumeclaim "my-pvc" deleted

# Pero sigue apareciendo:
kubectl get pvc
# NAME     STATUS        VOLUME    CAPACITY   ACCESS MODES   AGE
# my-pvc   Terminating   pv-123    10Gi       RWO            5m
```

**Causa**: PVC en uso por un Pod

```bash
kubectl describe pvc my-pvc
# Used By:  my-pod
```

**Solución**:
```bash
# 1. Eliminar Pods que usan el PVC
kubectl delete pod my-pod

# O eliminar Deployment/StatefulSet
kubectl delete deployment my-app

# 2. Ahora el PVC se eliminará
kubectl get pvc
# No resources found
```

### Problema 4: Disco lleno

**Síntoma**:
```bash
kubectl logs my-pod
# Error: No space left on device
```

**Verificar uso**:
```bash
kubectl exec my-pod -- df -h /data
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sdc        10G   10G     0 100% /data
```

**Solución**: Expandir PVC (si `allowVolumeExpansion: true`):

```bash
# 1. Verificar StorageClass permite expansión
kubectl get storageclass managed-csi -o jsonpath='{.allowVolumeExpansion}'
# true

# 2. Aumentar tamaño del PVC
kubectl patch pvc my-pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# 3. Verificar expansión
kubectl get pvc my-pvc
# NAME     STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# my-pvc   Bound    pv-123    20Gi       RWO            managed-csi    10m

# 4. Reiniciar Pod para que detecte nuevo tamaño
kubectl delete pod my-pod
```

### Problema 5: Rendimiento lento

**Síntoma**: Operaciones de I/O lentas

**Diagnóstico**:
```bash
# Verificar tipo de disco
kubectl get pvc my-pvc -o jsonpath='{.spec.storageClassName}'
# managed-csi  ← Standard SSD

# Ver parámetros del StorageClass
kubectl get storageclass managed-csi -o yaml
# parameters:
#   skuname: StandardSSD_LRS  ← Standard (no Premium)
```

**Solución**: Usar Premium SSD:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-premium
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi-premium  # ← Cambiar a Premium
  resources:
    requests:
      storage: 128Gi  # Premium requiere mínimo 128Gi
```

### Problema 6: PV en estado Released

**Síntoma**:
```bash
kubectl get pv
# NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM
# pv-123    10Gi       RWO            Retain           Released   default/old-pvc
```

**Causa**: PVC fue eliminado, PV tiene política `Retain`

**Solución**: Recuperar datos y reutilizar PV:

```bash
# Opción 1: Crear nuevo PVC con mismo nombre
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: old-pvc  # ← Mismo nombre que antes
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ""  # ← Vacío para binding manual
  volumeName: pv-123    # ← Especificar PV
EOF

# Opción 2: Limpiar y recrear PV
# 1. Hacer backup de datos
# 2. Eliminar PV
kubectl delete pv pv-123
# 3. Crear nuevo PV apuntando al mismo disco Azure
```

### Comandos Útiles de Diagnóstico

```bash
# Ver todos los PVCs y su estado
kubectl get pvc -A

# Ver todos los PVs
kubectl get pv

# Describir PVC (eventos detallados)
kubectl describe pvc <pvc-name>

# Ver logs del provisioner
kubectl logs -n kube-system -l app=csi-azuredisk-controller

# Ver qué Pods usan un PVC
kubectl get pods -o json | jq -r '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName=="<pvc-name>") | .metadata.name'

# Verificar uso de disco en Pod
kubectl exec <pod-name> -- df -h

# Ver StorageClasses disponibles
kubectl get storageclass

# Ver detalles de StorageClass
kubectl describe storageclass managed-csi
```

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de volumes — conceptos, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
