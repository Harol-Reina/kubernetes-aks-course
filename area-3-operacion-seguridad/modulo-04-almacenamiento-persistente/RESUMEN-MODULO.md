# 📚 RESUMEN - Módulo 04 (Área 3): Almacenamiento Persistente

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre el **almacenamiento persistente** en Kubernetes — cómo mantener datos que sobreviven al reinicio o eliminación de Pods. Aprenderás PersistentVolumes, PersistentVolumeClaims, StorageClasses, y la integración con Azure Disk y Azure Files.

**Duración**: 6 horas (teoría + labs)
**Nivel**: Intermedio
**Prerequisitos**: Pods, Deployments, Namespaces, volúmenes básicos (emptyDir)

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Explicar por qué los contenedores pierden datos al reiniciarse
- ✅ Diferenciar entre volúmenes efímeros y persistentes
- ✅ Entender el flujo PV → PVC → Pod
- ✅ Conocer los modos de acceso (RWO, ROX, RWX)

### Técnico
- ✅ Crear PersistentVolumes y PersistentVolumeClaims
- ✅ Configurar StorageClasses para aprovisionamiento dinámico
- ✅ Usar Azure Disk y Azure Files en AKS
- ✅ Configurar StatefulSets con volumeClaimTemplates
- ✅ Gestionar Reclaim Policies (Retain, Delete)

### Troubleshooting
- ✅ Diagnosticar PVC en estado Pending
- ✅ Resolver problemas de montaje de volúmenes
- ✅ Depurar permisos de acceso a storage

---

## 🗺️ Estructura de Aprendizaje

### El Problema: Los Contenedores Son Efímeros

```
Sin almacenamiento persistente:
┌──────────┐   kubectl delete   ┌──────────┐
│ Pod v1   │   ───────────►     │ Pod v2   │
│ datos: ✅│                    │ datos: ❌│
│ (existe) │                    │ (perdidos)│
└──────────┘                    └──────────┘

Con almacenamiento persistente (PVC):
┌──────────┐   kubectl delete   ┌──────────┐
│ Pod v1   │   ───────────►     │ Pod v2   │
│ /data ───┼──┐                 │ /data ───┼──┐
└──────────┘  │                 └──────────┘  │
              ▼                               ▼
         ┌──────────┐                    ┌──────────┐
         │ PVC/PV   │  (datos persisten) │ PVC/PV   │
         │ datos: ✅│  ════════════════► │ datos: ✅│
         └──────────┘                    └──────────┘
```

### Flujo de Almacenamiento

```
1. Admin crea    2. Dev solicita    3. K8s conecta    4. Pod monta
┌─────────┐     ┌──────────┐      ┌──────────────┐  ┌─────────┐
│   PV    │ ◄── │   PVC    │ ◄─── │  Kubernetes  │──►│  Pod    │
│ 10Gi    │     │ "dame    │      │  (binding)   │  │ /data   │
│ disco   │     │  5Gi"    │      └──────────────┘  └─────────┘
└─────────┘     └──────────┘
```

### Tabla Comparativa: Tipos de Volúmenes

| Tipo | Persistencia | Caso de uso | Acceso |
|------|-------------|-------------|--------|
| `emptyDir` | Solo vida del Pod | Cache temporal, datos compartidos entre contenedores | N/A |
| `hostPath` | Vida del nodo | Testing local, acceso a archivos del host | N/A |
| `PV/PVC` | Independiente del Pod | Bases de datos, archivos de app | RWO/ROX/RWX |
| `Azure Disk` | Persistente en Azure | Bases de datos, alto rendimiento | RWO |
| `Azure Files` | Persistente en Azure | Archivos compartidos entre Pods | RWX |

### Modos de Acceso

| Modo | Abreviación | Significado | Uso típico |
|------|------------|-------------|------------|
| ReadWriteOnce | RWO | Un solo nodo puede montar lectura/escritura | Bases de datos |
| ReadOnlyMany | ROX | Múltiples nodos lectura | Configuración compartida |
| ReadWriteMany | RWX | Múltiples nodos lectura/escritura | Archivos compartidos |

---

## 🔧 Comandos Esenciales

### Básicos

```bash
# Ver PersistentVolumes
kubectl get pv

# Ver PersistentVolumeClaims
kubectl get pvc -n <namespace>

# Ver StorageClasses
kubectl get sc

# Ver detalles de un PVC
kubectl describe pvc <name> -n <namespace>

# Ver qué PV está usando un PVC
kubectl get pvc <name> -n <ns> -o jsonpath='{.spec.volumeName}'
```

### Intermedios

```bash
# Crear PVC dinámicamente
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mi-datos
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
EOF

# Verificar que el PVC está Bound
kubectl get pvc mi-datos

# Ver capacidad usada
kubectl exec <pod> -- df -h /data
```

---

## 📝 Cheat Sheet: YAML Snippets

### PersistentVolume (estático)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mi-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /data/mi-pv
```

### PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mi-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ""    # "" = binding estático
```

### Pod con PVC

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-con-datos
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: datos
      mountPath: /data
  volumes:
  - name: datos
    persistentVolumeClaim:
      claimName: mi-pvc
```

### StatefulSet con volumeClaimTemplate

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
spec:
  replicas: 3
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: db
        image: postgres:15
        volumeMounts:
        - name: db-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: db-data
    spec:
      accessModes: [ReadWriteOnce]
      resources:
        requests:
          storage: 10Gi
```

---

## ❗ Problemas Comunes y Soluciones

### 1. PVC en estado Pending

**Causa**: No hay PV disponible que coincida con los requisitos.
**Diagnóstico**: `kubectl describe pvc <name>`
**Solución**: Crear un PV compatible o verificar que la StorageClass existe.

### 2. Error "volume is already used by pod"

**Causa**: El PV con modo RWO ya está montado en otro Pod/nodo.
**Solución**: Usar ReadWriteMany (RWX) o Azure Files para acceso compartido.

### 3. Datos perdidos después de eliminar PVC

**Causa**: La Reclaim Policy es `Delete` (borra el PV y los datos).
**Solución**: Usar `Retain` para PVs con datos importantes.

### 4. Pod no arranca: "Unable to mount volumes"

**Causa**: El PVC no está Bound o el storage no está accesible.
**Diagnóstico**: `kubectl describe pod <name>` → Events

---

## ✅ Checklist de Conceptos

- [ ] Entiendo por qué los contenedores pierden datos al reiniciarse
- [ ] Sé la diferencia entre emptyDir, hostPath y PVC
- [ ] Puedo crear PVs y PVCs
- [ ] Entiendo los modos de acceso (RWO, ROX, RWX)
- [ ] Sé configurar StorageClasses
- [ ] Puedo usar volumeClaimTemplates en StatefulSets
- [ ] Entiendo las Reclaim Policies (Retain vs Delete)
- [ ] Sé diagnosticar PVCs en estado Pending

---

## 📝 Preguntas de Repaso

### 1. ¿Cuál es la diferencia entre un PV y un PVC?

<details><summary>Ver respuesta</summary>
Un **PersistentVolume (PV)** es el almacenamiento real (el disco). Un **PersistentVolumeClaim (PVC)** es una solicitud de almacenamiento por parte de un Pod. El PV es creado por el admin; el PVC es creado por el desarrollador. Kubernetes los conecta automáticamente (binding).
</details>

### 2. ¿Qué pasa si eliminas un PVC con Reclaim Policy "Retain"?

<details><summary>Ver respuesta</summary>
El PV pasa a estado "Released" pero NO se elimina. Los datos permanecen intactos. Un admin debe manualmente limpiar y reciclar el PV antes de que pueda ser reutilizado por otro PVC.
</details>

### 3. ¿Cuándo usar Azure Disk vs Azure Files?

<details><summary>Ver respuesta</summary>
**Azure Disk**: Para alto rendimiento (bases de datos, SSD). Solo soporta RWO (un nodo a la vez). **Azure Files**: Para datos compartidos entre múltiples Pods/nodos. Soporta RWX. Menor rendimiento que Disk pero más flexible.
</details>

### 4. ¿Qué es el aprovisionamiento dinámico?

<details><summary>Ver respuesta</summary>
Con una StorageClass configurada, Kubernetes crea automáticamente el PV cuando se crea un PVC. No necesitas crear PVs manualmente. Es el método preferido en producción y en AKS.
</details>

### 5. ¿Por qué los StatefulSets usan volumeClaimTemplates?

<details><summary>Ver respuesta</summary>
Cada réplica del StatefulSet necesita su propio PVC independiente (ej: database-0, database-1, database-2). El volumeClaimTemplate crea un PVC único por réplica automáticamente, garantizando que cada réplica tiene su propio almacenamiento persistente.
</details>

---

## 🎓 Relevancia para Certificaciones

- **CKA**: PV, PVC, StorageClasses, modos de acceso (~8% del examen)
- **CKAD**: Usar PVCs en Pods, volumeMounts
- **AKS**: Azure Disk, Azure Files, CSI drivers, StorageClasses de Azure

---

## 🔗 Siguiente Paso

Continúa con el **Módulo 05: Azure Key Vault** para aprender a gestionar secrets de forma segura.
