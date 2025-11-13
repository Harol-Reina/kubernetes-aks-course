# 📚 RESUMEN - Módulo 15: Volúmenes - Conceptos Fundamentales

**Guía de Estudio Conceptual | Sin Implementación Práctica**

---

## 🎯 Visión General del Módulo

Este módulo cubre los **conceptos fundamentales** de volúmenes en Kubernetes. Aprenderás **qué son**, **por qué existen**, **qué tipos hay** y **cuándo usar cada uno** - sin entrar en YAMLs complejos ni implementación práctica (eso es el Módulo 16).

**Duración**: 4 horas (teoría + diagramas)  
**Nivel**: Fundamentos Conceptuales  
**Prerequisitos**: Pods, Deployments, conceptos de persistencia

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Comprender el problema del almacenamiento efímero
- ✅ Entender qué son los volúmenes y por qué son necesarios
- ✅ Diferenciar aplicaciones stateless vs stateful
- ✅ Conocer el ciclo de vida de los volúmenes

### Conceptual
- ✅ Identificar tipos de volúmenes (emptyDir, hostPath, cloud)
- ✅ Comprender abstracción PV/PVC
- ✅ Conocer modos de acceso (RWO, ROX, RWX)
- ✅ Entender políticas de recuperación (Retain, Delete, Recycle)
- ✅ Familiarizarse con StorageClasses

### Diseño
- ✅ Decidir cuándo usar cada tipo de volumen
- ✅ Elegir modos de acceso apropiados
- ✅ Seleccionar políticas de recuperación
- ✅ Diseñar arquitecturas de almacenamiento

---

## 🔗 Relación con Módulo 16

**⚠️ CRÍTICO**: Este módulo es **solo conceptos**. El Módulo 16 es **implementación práctica**.

```
┌────────────────────────────────────────┐
│  MÓDULO 15: Conceptos                  │
│  (Este resumen)                        │
│                                        │
│  📖 Qué son los volúmenes              │
│  📊 Tipos de volúmenes                 │
│  🎨 PV/PVC (abstracción)               │
│  📋 Access Modes (teoría)              │
│  📚 Reclaim Policies (concepto)        │
│                                        │
│  ❌ SIN YAMLs complejos                │
│  ❌ SIN kubectl detallado              │
│  ❌ SIN labs hands-on                  │
└────────────────────────────────────────┘
              ↓
        Continúa con...
              ↓
┌────────────────────────────────────────┐
│  MÓDULO 16: Implementación Práctica    │
│                                        │
│  ✅ YAMLs completos de PV/PVC          │
│  ✅ Comandos kubectl paso a paso       │
│  ✅ Troubleshooting práctico           │
│  ✅ Laboratorios hands-on              │
│  ✅ Azure Disk y Azure Files           │
└────────────────────────────────────────┘
```

---

## 🗺️ Estructura de Aprendizaje

### Fase 1: El Problema del Almacenamiento Efímero (20 min)
**Teoría**: Sección 1 del README

#### ¿Por Qué Necesitamos Volúmenes?

**Problema**: Por defecto, el sistema de archivos de un contenedor es **efímero**.

```
┌─────────────────────────────┐
│   Pod (efímero)             │
│  ┌────────────────────────┐ │
│  │ Contenedor             │ │
│  │ /var/data/  ← Datos    │ │
│  └────────────────────────┘ │
└─────────────────────────────┘
         ↓ Pod muere
    ❌ Datos perdidos
```

**Consecuencias**:
- Cuando el contenedor crashea → datos perdidos
- Cuando el Pod es eliminado → datos perdidos
- Cuando se hace un rollout → datos perdidos

#### La Solución: Volúmenes como Objetos Independientes

**Volumen** = Almacenamiento **separado** del ciclo de vida del Pod.

```
┌──────────────┐     ┌────────────────────┐
│ Pod (efímero)│ ←→  │ Volumen (persist.) │
└──────────────┘     └────────────────────┘
       ↓                      ↑
  Pod muere              Volumen intacto
       ↓                      ↑
┌──────────────┐              │
│ Nuevo Pod    │ ─────────────┘
└──────────────┘
   ✅ Datos recuperados
```

**Ventajas**:
- ✅ Persistencia más allá del ciclo de vida del Pod
- ✅ Compartir datos entre contenedores en un Pod
- ✅ Separación de responsabilidades (almacenamiento vs cómputo)

---

### Fase 2: Stateless vs Stateful (20 min)
**Teoría**: Sección 2 del README

#### Aplicaciones Stateless (Sin Estado)

**Definición**: No guardan estado entre peticiones. Cualquier instancia puede servir cualquier petición.

**Características**:
- ✅ Sin datos persistentes
- ✅ Fáciles de escalar (añadir/quitar Pods)
- ✅ Fáciles de actualizar (rolling updates sin riesgo)
- ✅ Alta disponibilidad (si un Pod muere, otro lo reemplaza sin problema)

**Ejemplos**:
- Frontend web (React, Angular, Vue)
- API REST sin sesiones
- Microservicios stateless
- Load balancers

**Volúmenes típicos**: `emptyDir` (temporal, para caché o logs)

---

#### Aplicaciones Stateful (Con Estado)

**Definición**: Guardan estado persistente. Cada instancia tiene datos únicos.

**Características**:
- ⚠️ Requieren almacenamiento persistente
- ⚠️ Más complejas de escalar
- ⚠️ Orden de inicio/parada importa
- ⚠️ Cada Pod tiene identidad única

**Ejemplos**:
- Bases de datos (MySQL, PostgreSQL, MongoDB)
- Colas de mensajes (RabbitMQ, Kafka)
- Sistemas de archivos distribuidos
- Aplicaciones con sesiones persistentes

**Volúmenes típicos**: `PersistentVolume` (persistente, sobrevive al Pod)

---

#### Comparación

| Aspecto | Stateless | Stateful |
|---------|-----------|----------|
| **Estado** | Sin datos persistentes | Datos persistentes |
| **Escalado** | Fácil (horizontal) | Complejo (requiere orden) |
| **Volúmenes** | emptyDir (temporal) | PV/PVC (persistente) |
| **HA** | Fácil (réplicas idénticas) | Difícil (datos únicos) |
| **Ejemplo** | Frontend web | Base de datos |

---

### Fase 3: Ciclo de Vida de Volúmenes (25 min)
**Teoría**: Sección 3 del README

#### Volúmenes Efímeros

**Ciclo de vida**: Atado al **Pod**.

```
Pod creado → Volumen creado
Pod elimínado → Volumen eliminado
```

**Tipos efímeros**:
- `emptyDir`: Directorio vacío, compartido entre contenedores del Pod
- `configMap`: ConfigMaps montados como archivos
- `secret`: Secrets montados como archivos

**Cuándo usar**:
- ✅ Datos temporales (caché, scratch space)
- ✅ Compartir datos entre contenedores en el mismo Pod
- ✅ No necesitas persistencia

---

#### Volúmenes Persistentes

**Ciclo de vida**: **Independiente** del Pod.

```
PV creado → Existe independientemente
Pod usa PV → Monta el volumen
Pod eliminado → PV sigue existiendo
Nuevo Pod → Puede montar el mismo PV
```

**Tipos persistentes**:
- `PersistentVolume (PV)`: Almacenamiento físico (disco, NFS, cloud storage)
- Cloud volumes: `azureDisk`, `azureFile`, `awsElasticBlockStore`, `gcePersistentDisk`

**Cuándo usar**:
- ✅ Bases de datos
- ✅ Archivos de usuario
- ✅ Logs que deben sobrevivir al Pod
- ✅ Cualquier dato que no puede perderse

---

### Fase 4: Tipos de Volúmenes Básicos (30 min)
**Teoría**: Sección 4 del README

#### 1. emptyDir

**Descripción**: Directorio vacío creado cuando el Pod inicia. Se elimina cuando el Pod muere.

**Uso típico**:
- Compartir archivos entre contenedores en el mismo Pod
- Scratch space (espacio temporal)
- Caché

**Ejemplo conceptual**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: shared-data
      mountPath: /data    # ← Donde se monta
  
  - name: sidecar
    image: logger:1.0
    volumeMounts:
    - name: shared-data
      mountPath: /logs    # ← Mismo volumen, diferente path
  
  volumes:
  - name: shared-data
    emptyDir: {}    # ← Volumen efímero
```

**Características**:
- ✅ Efímero (se borra con el Pod)
- ✅ Rápido (en memoria o disco local)
- ✅ Sin configuración compleja
- ❌ No persiste datos

---

#### 2. hostPath

**Descripción**: Monta un directorio del **nodo** (host) en el Pod.

**Uso típico**:
- Acceder a archivos del nodo (logs de sistema, /var/run/docker.sock)
- DaemonSets que necesitan acceso al host
- Testing/desarrollo

**Ejemplo conceptual**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-reader
spec:
  containers:
  - name: reader
    image: busybox
    volumeMounts:
    - name: host-logs
      mountPath: /host-logs    # ← Dentro del contenedor
      readOnly: true
  
  volumes:
  - name: host-logs
    hostPath:
      path: /var/log           # ← Directorio del nodo
      type: Directory
```

**Características**:
- ⚠️ Datos persisten en el nodo (no en el Pod)
- ⚠️ **Riesgoso**: acceso directo al nodo
- ⚠️ No portátil (depende del nodo específico)
- ❌ No usar en producción para datos persistentes

**Tipos de hostPath**:
- `DirectoryOrCreate`: Directorio o crear si no existe
- `Directory`: Directorio (debe existir)
- `FileOrCreate`: Archivo o crear si no existe
- `File`: Archivo (debe existir)
- `Socket`: Socket Unix
- `BlockDevice`: Dispositivo de bloques

---

#### Comparación: emptyDir vs hostPath

| Aspecto | emptyDir | hostPath |
|---------|----------|----------|
| **Ubicación** | Temporal del Pod | Directorio del nodo |
| **Ciclo de vida** | Muere con el Pod | Persiste en el nodo |
| **Compartir** | Entre contenedores del Pod | Entre Pods en el mismo nodo |
| **Seguridad** | Seguro | Riesgoso (acceso al host) |
| **Portabilidad** | Alta | Baja (depende del nodo) |
| **Uso típico** | Scratch space, caché | Logs del sistema, sockets |

---

### Fase 5: Cloud Volumes (20 min)
**Teoría**: Sección 5 del README

#### Concepto General

**Cloud Volumes** = Almacenamiento proporcionado por proveedores de nube (Azure, AWS, GCP).

**Ventajas**:
- ✅ Persistencia real (sobrevive a Pods y nodos)
- ✅ Backups automáticos
- ✅ Replicación y alta disponibilidad
- ✅ Escalabilidad

---

#### Azure Disk

**Descripción**: Disco persistente de Azure montado en un Pod.

**Características**:
- 📀 **Acceso**: ReadWriteOnce (solo un Pod a la vez)
- 💾 **Uso**: Bases de datos, datos de un solo Pod
- 🔒 **Persistencia**: Datos sobreviven al Pod

**Ejemplo conceptual**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: database
spec:
  containers:
  - name: postgres
    image: postgres:14
    volumeMounts:
    - name: data
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: data
    azureDisk:
      diskName: my-disk
      diskURI: /subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/disks/my-disk
```

**Cuándo usar**:
- ✅ Bases de datos (MySQL, PostgreSQL)
- ✅ Aplicaciones stateful con un solo Pod
- ❌ NO para compartir entre múltiples Pods

---

#### Azure Files

**Descripción**: Sistema de archivos compartido (SMB) de Azure.

**Características**:
- 📂 **Acceso**: ReadWriteMany (múltiples Pods simultáneamente)
- 🔀 **Uso**: Archivos compartidos, static assets
- 🌐 **Persistencia**: Datos accesibles desde múltiples Pods

**Ejemplo conceptual**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: shared-files
      mountPath: /usr/share/nginx/html
  volumes:
  - name: shared-files
    azureFile:
      secretName: azure-storage-secret
      shareName: myshare
```

**Cuándo usar**:
- ✅ Archivos estáticos compartidos (imágenes, CSS, JS)
- ✅ Aplicaciones que necesitan acceso compartido
- ✅ Content Management Systems (CMS)

---

#### Comparación: Azure Disk vs Azure Files

| Aspecto | Azure Disk | Azure Files |
|---------|------------|-------------|
| **Acceso** | ReadWriteOnce | ReadWriteMany |
| **Tipo** | Disco de bloques | Sistema de archivos |
| **Performance** | Alta (SSD) | Media (SMB) |
| **Precio** | Medio | Bajo |
| **Uso típico** | Bases de datos | Static assets compartidos |
| **Múltiples Pods** | ❌ No | ✅ Sí |

---

### Fase 6: PV y PVC - Abstracción (40 min)
**Teoría**: Sección 6 del README

#### El Problema sin PV/PVC

**Sin abstracción**, cada desarrollador necesita saber detalles de infraestructura:

```yaml
# ❌ Desarrollador debe conocer detalles de Azure
volumes:
- name: data
  azureDisk:
    diskName: my-disk-prod-eastus-001
    diskURI: /subscriptions/abc123.../disks/my-disk
```

**Problemas**:
- ⚠️ Desarrollador necesita permisos de Azure
- ⚠️ Acoplamiento con infraestructura
- ⚠️ No portátil entre entornos

---

#### La Solución: Abstracción PV/PVC

**PersistentVolume (PV)** = **Almacenamiento físico** (administrador lo crea)
**PersistentVolumeClaim (PVC)** = **Solicitud de almacenamiento** (desarrollador la usa)

```
┌─────────────────────────────────────────────┐
│           Administrador                      │
│                                             │
│  Crea PersistentVolume (PV)                 │
│  - Conecta a Azure Disk                     │
│  - Define tamaño (100Gi)                    │
│  - Define access mode (RWO)                 │
└─────────────────────────────────────────────┘
                    ↓
                  Binding
                    ↓
┌─────────────────────────────────────────────┐
│           Desarrollador                      │
│                                             │
│  Crea PersistentVolumeClaim (PVC)           │
│  - Solicita almacenamiento (50Gi)           │
│  - Especifica access mode (RWO)             │
│                                             │
│  Usa PVC en Pod                             │
│  - volumeMounts: usa nombre del PVC         │
│  - ¡No necesita saber detalles de Azure!   │
└─────────────────────────────────────────────┘
```

---

#### PersistentVolume (PV)

**Definición**: Recurso de almacenamiento en el clúster, provisionado por el administrador.

**Ejemplo conceptual**:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-azure-disk
spec:
  capacity:
    storage: 100Gi          # ← Tamaño
  accessModes:
    - ReadWriteOnce         # ← Modo de acceso
  persistentVolumeReclaimPolicy: Retain  # ← Qué hacer al eliminar PVC
  azureDisk:                # ← Detalles de infraestructura
    diskName: my-disk
    diskURI: /subscriptions/.../disks/my-disk
```

**Administrador** define:
- Tamaño (`capacity.storage`)
- Modo de acceso (`accessModes`)
- Política de recuperación (`persistentVolumeReclaimPolicy`)
- Backend de almacenamiento (`azureDisk`, `azureFile`, `nfs`, etc.)

---

#### PersistentVolumeClaim (PVC)

**Definición**: Solicitud de almacenamiento por parte del desarrollador.

**Ejemplo conceptual**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-database
spec:
  accessModes:
    - ReadWriteOnce         # ← Lo que necesito
  resources:
    requests:
      storage: 50Gi         # ← Cuánto necesito
```

**Desarrollador** especifica:
- Modo de acceso que necesita
- Tamaño mínimo requerido
- (Opcional) StorageClass

**Kubernetes** hace el **binding**:
- Busca un PV que cumpla los requisitos
- Vincula PVC → PV
- PVC queda en estado `Bound`

---

#### Usar PVC en un Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: database
spec:
  containers:
  - name: postgres
    image: postgres:14
    volumeMounts:
    - name: data
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-database    # ← Usa el PVC
```

**Ventaja**: Desarrollador NO necesita saber que es Azure Disk, solo usa `pvc-database`.

---

#### Flujo Completo PV/PVC

```
1. Admin crea PV (100Gi, RWO, Azure Disk)
            ↓
2. PV queda disponible (estado: Available)
            ↓
3. Desarrollador crea PVC (50Gi, RWO)
            ↓
4. Kubernetes hace binding: PVC ← PV
            ↓
5. PVC queda en estado: Bound
   PV queda en estado: Bound
            ↓
6. Desarrollador crea Pod usando PVC
            ↓
7. Pod monta el volumen
            ↓
8. ✅ Datos persisten en Azure Disk
```

---

#### Estados de PV y PVC

**Estados de PV**:
- `Available`: Listo para ser usado
- `Bound`: Vinculado a un PVC
- `Released`: PVC eliminado, PV liberado
- `Failed`: Error en el volumen

**Estados de PVC**:
- `Pending`: Esperando binding
- `Bound`: Vinculado a un PV
- `Lost`: PV perdido

---

### Fase 7: Reclaim Policies (20 min)
**Teoría**: Sección 7 del README

#### ¿Qué son las Reclaim Policies?

**Reclaim Policy** = Qué hacer con el **PV** cuando el **PVC es eliminado**.

```
Pod eliminado → PVC eliminado → ¿Qué pasa con el PV?
                                    ↓
                          (depende de Reclaim Policy)
```

---

#### 1. Retain (Retener)

**Comportamiento**: PV **no se elimina** automáticamente.

```
PVC eliminado → PV queda en estado "Released"
             → Datos intactos en el disco
             → Admin debe limpiar manualmente
```

**Cuándo usar**:
- ✅ **Producción** (seguridad de datos)
- ✅ Backups manuales antes de eliminar
- ✅ Investigación post-mortem

**Ejemplo**:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-prod
spec:
  persistentVolumeReclaimPolicy: Retain    # ← Retain
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
```

---

#### 2. Delete (Eliminar)

**Comportamiento**: PV **y disco físico** se eliminan automáticamente.

```
PVC eliminado → PV eliminado
             → Disco de Azure eliminado
             → ❌ Datos perdidos permanentemente
```

**Cuándo usar**:
- ✅ **Desarrollo/Testing** (limpieza automática)
- ✅ Datos no críticos
- ❌ **NO en producción** (riesgo de pérdida de datos)

**Ejemplo**:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-dev
spec:
  persistentVolumeReclaimPolicy: Delete    # ← Delete
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
```

---

#### 3. Recycle (Reciclado) - DEPRECATED

**Comportamiento**: Limpia datos (`rm -rf /volume/*`) y hace PV disponible de nuevo.

**Estado**: **Deprecated** (no usar).

---

#### Comparación de Reclaim Policies

| Política | Datos | PV | Disco Físico | Uso |
|----------|-------|----|--------------|----|
| **Retain** | ✅ Mantiene | ✅ Mantiene (Released) | ✅ Mantiene | Producción |
| **Delete** | ❌ Elimina | ❌ Elimina | ❌ Elimina | Dev/Test |
| **Recycle** | ❌ Elimina | ✅ Mantiene (Available) | ✅ Mantiene | Deprecated |

---

### Fase 8: Access Modes (25 min)
**Teoría**: Sección 8 del README

#### ¿Qué son los Access Modes?

**Access Mode** = Cómo los Pods pueden **acceder** al volumen.

---

#### 1. ReadWriteOnce (RWO)

**Descripción**: Lectura/escritura por **un solo nodo** a la vez.

**Características**:
- ✅ Un Pod (en un nodo) puede leer/escribir
- ✅ Múltiples Pods en el **mismo nodo** pueden compartir
- ❌ Pods en **diferentes nodos** NO pueden compartir

**Uso típico**:
- Bases de datos (MySQL, PostgreSQL, MongoDB)
- Aplicaciones stateful con un solo Pod

**Ejemplo conceptual**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-database
spec:
  accessModes:
    - ReadWriteOnce    # ← RWO
  resources:
    requests:
      storage: 50Gi
```

**Diagrama**:
```
┌─────────────┐
│   Nodo 1    │
│             │
│  Pod A  ✅  │ ← Puede leer/escribir
│  Pod B  ✅  │ ← También (mismo nodo)
└─────────────┘

┌─────────────┐
│   Nodo 2    │
│             │
│  Pod C  ❌  │ ← NO puede acceder (diferente nodo)
└─────────────┘
```

---

#### 2. ReadOnlyMany (ROX)

**Descripción**: Lectura por **múltiples nodos** simultáneamente. **Sin escritura**.

**Características**:
- ✅ Múltiples Pods pueden leer
- ❌ Ningún Pod puede escribir

**Uso típico**:
- Static assets (HTML, CSS, JS, imágenes)
- Configuración compartida (solo lectura)
- Datos de referencia

**Ejemplo conceptual**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-static-files
spec:
  accessModes:
    - ReadOnlyMany    # ← ROX
  resources:
    requests:
      storage: 10Gi
```

**Diagrama**:
```
┌─────────────┐
│   Nodo 1    │
│             │
│  Pod A  ✅  │ ← Puede leer
│  Pod B  ✅  │ ← Puede leer
└─────────────┘

┌─────────────┐
│   Nodo 2    │
│             │
│  Pod C  ✅  │ ← Puede leer
│  Pod D  ✅  │ ← Puede leer
└─────────────┘

    ❌ Ninguno puede escribir
```

---

#### 3. ReadWriteMany (RWX)

**Descripción**: Lectura/escritura por **múltiples nodos** simultáneamente.

**Características**:
- ✅ Múltiples Pods pueden leer/escribir
- ✅ Pods en diferentes nodos

**Uso típico**:
- Sistemas de archivos compartidos (NFS, Azure Files)
- CMS (WordPress, Drupal)
- Aplicaciones que comparten archivos

**Ejemplo conceptual**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-shared-files
spec:
  accessModes:
    - ReadWriteMany    # ← RWX
  resources:
    requests:
      storage: 100Gi
```

**Diagrama**:
```
┌─────────────┐
│   Nodo 1    │
│             │
│  Pod A  ✅  │ ← Puede leer/escribir
│  Pod B  ✅  │ ← Puede leer/escribir
└─────────────┘

┌─────────────┐
│   Nodo 2    │
│             │
│  Pod C  ✅  │ ← Puede leer/escribir
│  Pod D  ✅  │ ← Puede leer/escribir
└─────────────┘
```

---

#### Comparación de Access Modes

| Modo | Lectura | Escritura | Múltiples Nodos | Uso Típico |
|------|---------|-----------|-----------------|------------|
| **RWO** | ✅ Sí | ✅ Sí | ❌ No | Bases de datos |
| **ROX** | ✅ Sí | ❌ No | ✅ Sí | Static assets |
| **RWX** | ✅ Sí | ✅ Sí | ✅ Sí | Archivos compartidos |

---

#### Access Modes por Tipo de Volumen

| Tipo de Volumen | RWO | ROX | RWX |
|-----------------|-----|-----|-----|
| **emptyDir** | ✅ | ❌ | ❌ |
| **hostPath** | ✅ | ✅ | ❌ |
| **Azure Disk** | ✅ | ❌ | ❌ |
| **Azure Files** | ✅ | ✅ | ✅ |
| **NFS** | ✅ | ✅ | ✅ |

---

### Fase 9: StorageClasses (20 min)
**Teoría**: Sección 9 del README

#### ¿Qué es una StorageClass?

**StorageClass** = Plantilla para **provisioning dinámico** de volúmenes.

**Sin StorageClass** (manual):
```
Admin crea PV → Desarrollador crea PVC → Binding manual
                                      ↓
                            (Admin debe crear PV para cada PVC)
```

**Con StorageClass** (dinámico):
```
Desarrollador crea PVC → Kubernetes crea PV automáticamente
                                    ↓
                      (Usa StorageClass para saber cómo crear PV)
```

---

#### Provisioning Dinámico

**Ventaja**: No necesitas crear PV manualmente.

**Ejemplo**:
```yaml
# StorageClass (ya existe en Azure AKS)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi
provisioner: disk.csi.azure.com    # ← Driver de Azure Disk
parameters:
  storageaccounttype: Standard_LRS
---
# PVC usa StorageClass
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-database
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi    # ← Usa StorageClass
  resources:
    requests:
      storage: 50Gi
```

**Flujo**:
1. Desarrollador crea PVC con `storageClassName: managed-csi`
2. Kubernetes detecta StorageClass
3. Provisioner de Azure (`disk.csi.azure.com`) crea Azure Disk automáticamente
4. Kubernetes crea PV automáticamente
5. PVC queda `Bound` al PV recién creado

---

#### StorageClasses en Azure AKS

**Por defecto** en AKS:
- `managed-csi` (default): Azure Disk Standard LRS
- `managed-csi-premium`: Azure Disk Premium SSD
- `azurefile-csi`: Azure Files Standard
- `azurefile-csi-premium`: Azure Files Premium

**Ver StorageClasses**:
```bash
kubectl get storageclass

# NAME                    PROVISIONER
# managed-csi (default)   disk.csi.azure.com
# managed-csi-premium     disk.csi.azure.com
# azurefile-csi           file.csi.azure.com
```

---

#### StorageClass Default

**Default StorageClass** = Se usa si no especificas `storageClassName` en el PVC.

**Identificar default**:
```bash
kubectl get storageclass

# NAME                    PROVISIONER            RECLAIMPOLICY
# managed-csi (default)   disk.csi.azure.com     Delete
```

**Usar default** (omitir storageClassName):
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-database
spec:
  accessModes:
    - ReadWriteOnce
  # storageClassName no especificado → usa default
  resources:
    requests:
      storage: 50Gi
```

---

### Fase 10: Troubleshooting Conceptual (15 min)
**Teoría**: Sección 10 del README

#### Problema 1: PVC en estado Pending

**Síntoma**: PVC no se vincula a ningún PV.

```bash
kubectl get pvc
# NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES
# pvc-database   Pending   -        -          -
```

**Causas posibles**:
1. **No hay PV disponible** que cumpla requisitos (tamaño, access mode)
2. **StorageClass no existe** o tiene error de configuración
3. **Permisos insuficientes** para provisionar en la nube

**Diagnóstico**:
```bash
kubectl describe pvc pvc-database

# Events:
#   Warning  ProvisioningFailed  no persistent volumes available
```

---

#### Problema 2: Pod en estado Pending (volumen)

**Síntoma**: Pod no puede iniciar por problemas de volumen.

```bash
kubectl get pods
# NAME       READY   STATUS    RESTARTS   AGE
# database   0/1     Pending   0          2m
```

**Diagnóstico**:
```bash
kubectl describe pod database

# Events:
#   Warning  FailedScheduling  persistentvolumeclaim "pvc-database" not found
```

**Causas**:
- PVC no existe
- PVC en estado Pending

---

#### Problema 3: Pod no puede montar volumen

**Síntoma**: Pod en `ContainerCreating` permanente.

**Causas**:
- PV en uso por otro Pod (RWO)
- Access mode incompatible
- Problema de red/conectividad con storage

---

## 🎯 Conceptos Clave para Recordar

### Stateless vs Stateful

```
STATELESS:
  - Sin datos persistentes
  - Fácil escalar y actualizar
  - Volumen típico: emptyDir

STATEFUL:
  - Datos persistentes
  - Complejo escalar
  - Volumen típico: PV/PVC
```

### Tipos de Volúmenes

```
EFÍMEROS (mueren con el Pod):
  - emptyDir: temporal, compartido entre contenedores
  - configMap/secret: config como archivos

PERSISTENTES (independientes del Pod):
  - PersistentVolume (PV): almacenamiento físico
  - Cloud volumes: azureDisk, azureFile
```

### PV vs PVC

```
PV (PersistentVolume):
  - Recurso de clúster
  - Creado por admin
  - Almacenamiento físico

PVC (PersistentVolumeClaim):
  - Solicitud de almacenamiento
  - Creado por desarrollador
  - Se vincula a un PV
```

### Access Modes

```
RWO (ReadWriteOnce):    Un nodo, lectura/escritura
ROX (ReadOnlyMany):     Múltiples nodos, solo lectura
RWX (ReadWriteMany):    Múltiples nodos, lectura/escritura
```

### Reclaim Policies

```
Retain:  Datos y PV persisten (producción)
Delete:  Datos y PV se eliminan (dev/test)
Recycle: Deprecated (no usar)
```

### StorageClass

```
Provisioning Dinámico:
  - PVC especifica storageClassName
  - Kubernetes crea PV automáticamente
  - No necesitas crear PV manualmente
```

---

## ✅ Checklist de Dominio

### Fundamentos
- [ ] Entiendo el problema del almacenamiento efímero
- [ ] Sé qué son los volúmenes y por qué son necesarios
- [ ] Diferencio aplicaciones stateless vs stateful
- [ ] Comprendo ciclo de vida de volúmenes efímeros vs persistentes

### Tipos de Volúmenes
- [ ] Conozco emptyDir (temporal, compartido)
- [ ] Conozco hostPath (acceso al nodo)
- [ ] Entiendo cloud volumes (Azure Disk, Azure Files)
- [ ] Sé cuándo usar cada tipo

### Abstracción PV/PVC
- [ ] Comprendo qué es un PersistentVolume (PV)
- [ ] Comprendo qué es un PersistentVolumeClaim (PVC)
- [ ] Entiendo el binding entre PV y PVC
- [ ] Sé por qué se usa abstracción (separación admin/desarrollador)

### Access Modes
- [ ] Conozco ReadWriteOnce (RWO)
- [ ] Conozco ReadOnlyMany (ROX)
- [ ] Conozco ReadWriteMany (RWX)
- [ ] Sé elegir access mode según caso de uso

### Reclaim Policies
- [ ] Conozco Retain (producción)
- [ ] Conozco Delete (dev/test)
- [ ] Sé cuándo usar cada política

### StorageClasses
- [ ] Entiendo provisioning dinámico
- [ ] Conozco StorageClasses en Azure AKS
- [ ] Sé cómo se vincula PVC con StorageClass

### Diseño
- [ ] Puedo decidir qué tipo de volumen usar
- [ ] Puedo elegir access mode apropiado
- [ ] Puedo seleccionar reclaim policy según requisitos
- [ ] Entiendo diferencias Azure Disk vs Azure Files

### Preparación para Práctica
- [ ] Listo para implementar YAMLs (Módulo 16)
- [ ] Listo para comandos kubectl (Módulo 16)
- [ ] Listo para troubleshooting práctico (Módulo 16)

---

## 🎓 Evaluación Final

### Preguntas Clave
1. ¿Cuál es el problema que resuelven los volúmenes?
2. ¿Qué diferencia hay entre aplicaciones stateless y stateful?
3. ¿Cuándo usar emptyDir vs PersistentVolume?
4. ¿Qué es un PV y qué es un PVC?
5. ¿Cuáles son los 3 access modes y cuándo usar cada uno?
6. ¿Qué diferencia hay entre Retain y Delete (reclaim policies)?
7. ¿Qué es una StorageClass?

<details>
<summary>Ver Respuestas</summary>

1. **Problema de volúmenes**:
   - Sistema de archivos de contenedor es efímero
   - Datos se pierden cuando Pod muere
   - Volúmenes separan almacenamiento del ciclo de vida del Pod

2. **Stateless vs Stateful**:
   - **Stateless**: Sin datos persistentes, fácil escalar (frontend, API REST)
   - **Stateful**: Datos persistentes, complejo escalar (bases de datos)

3. **emptyDir vs PersistentVolume**:
   - **emptyDir**: Temporal, muere con el Pod, para caché/scratch space
   - **PersistentVolume**: Persistente, independiente del Pod, para datos críticos

4. **PV vs PVC**:
   - **PV**: Recurso físico creado por admin (disco de Azure)
   - **PVC**: Solicitud de almacenamiento por desarrollador
   - **Relación**: PVC se vincula (bind) a un PV

5. **Access Modes**:
   - **RWO**: Un nodo, lectura/escritura (bases de datos)
   - **ROX**: Múltiples nodos, solo lectura (static assets)
   - **RWX**: Múltiples nodos, lectura/escritura (archivos compartidos)

6. **Retain vs Delete**:
   - **Retain**: PV y datos persisten cuando PVC se elimina (producción)
   - **Delete**: PV y datos se eliminan automáticamente (dev/test)

7. **StorageClass**:
   - Plantilla para provisioning dinámico
   - PVC especifica storageClassName → Kubernetes crea PV automáticamente
   - No necesitas crear PV manualmente

</details>

---

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)

### Próximo Módulo
➡️ **Módulo 16**: Volúmenes - Implementación Práctica en Azure AKS

**En el Módulo 16 aprenderás**:
- ✅ YAMLs completos de PV/PVC
- ✅ Comandos kubectl paso a paso
- ✅ Provisioning dinámico en AKS
- ✅ Azure Disk y Azure Files hands-on
- ✅ Troubleshooting práctico
- ✅ Laboratorios completos

---

## 🎉 ¡Felicitaciones!

Has completado el Módulo 15 de Conceptos de Volúmenes. Ahora comprendes:

- ✅ Qué son los volúmenes y por qué existen
- ✅ Diferencias entre stateless y stateful
- ✅ Tipos de volúmenes (emptyDir, hostPath, cloud)
- ✅ Abstracción PV/PVC
- ✅ Access Modes (RWO, ROX, RWX)
- ✅ Reclaim Policies (Retain, Delete)
- ✅ StorageClasses y provisioning dinámico

**Próximos pasos**:
1. Revisar este resumen periódicamente
2. **Continuar con Módulo 16** para implementación práctica
3. Practicar con laboratorios hands-on (Módulo 16)

¡Sigue adelante con la implementación práctica! 🚀
