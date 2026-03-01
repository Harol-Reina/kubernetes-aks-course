# Capítulo 32: Almacenamiento Persistente en AKS

La red está segura con Network Policies. Ahora resolvemos la persistencia de datos en la nube. Azure ofrece dos opciones principales: Azure Disk (ReadWriteOnce, alto rendimiento) y Azure Files (ReadWriteMany, compartido entre Pods).

---

## Conceptos de Almacenamiento en Kubernetes

### Tipos de Volúmenes

1. **Ephemeral**: Temporales, se eliminan con el Pod
2. **Persistent**: Sobreviven al ciclo de vida del Pod

### Componentes Principales

- **PersistentVolume (PV)**: Recurso de almacenamiento en el clúster
- **PersistentVolumeClaim (PVC)**: Solicitud de almacenamiento por un usuario
- **StorageClass**: Define tipos de almacenamiento disponibles

## Azure Storage en AKS

### Azure Disk

**Características:**
- **ReadWriteOnce**: Solo un Pod puede montar el disco
- **Rendimiento**: Standard HDD, Standard SSD, Premium SSD
- **Snapshots**: Soporte nativo
- **Encryption**: Azure Disk Encryption

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: managed-premium
```

### Azure Files

**Características:**
- **ReadWriteMany**: Múltiples Pods pueden montar el volumen
- **Protocolos**: SMB y NFS
- **Compartido**: Entre múltiples nodos
- **Backup**: Azure Backup integration

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-files-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: azurefile
```

## StorageClasses en AKS

### StorageClasses por Defecto

```bash
# Listar StorageClasses
kubectl get storageclass

# Describir StorageClass
kubectl describe storageclass managed-premium
```

**StorageClasses principales:**
- **default**: Standard SSD (ReadWriteOnce)
- **managed-premium**: Premium SSD (ReadWriteOnce)
- **azurefile**: Azure Files (ReadWriteMany)
- **azurefile-premium**: Azure Files Premium

### StorageClass Personalizada

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
  cachingmode: ReadOnly
  kind: Managed
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

## Laboratorio 3.3: Configurar Almacenamiento Persistente

### Paso 1: Azure Disk con StatefulSet

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database-statefulset
  namespace: desarrollo
spec:
  serviceName: database-headless
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: appuser
        - name: POSTGRES_PASSWORD
          value: secretpassword
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: managed-premium
      resources:
        requests:
          storage: 20Gi
---
apiVersion: v1
kind: Service
metadata:
  name: database-headless
  namespace: desarrollo
spec:
  clusterIP: None
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF

# Verificar StatefulSet y PVC
kubectl get statefulset -n desarrollo
kubectl get pvc -n desarrollo
kubectl get pv
```

### Paso 2: Azure Files Compartido

```bash
# Crear PVC para Azure Files
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-storage
  namespace: desarrollo
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: azurefile
EOF

# Deployment que usa Azure Files
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: file-share-app
  namespace: desarrollo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: file-share
  template:
    metadata:
      labels:
        app: file-share
    spec:
      containers:
      - name: app
        image: nginx:1.21
        volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html
        - name: logs
          mountPath: /var/log/nginx
      volumes:
      - name: shared-data
        persistentVolumeClaim:
          claimName: shared-storage
      - name: logs
        persistentVolumeClaim:
          claimName: shared-storage
EOF

# Verificar que múltiples pods comparten el volumen
kubectl get pods -n desarrollo -l app=file-share
kubectl exec -n desarrollo deployment/file-share-app -- ls -la /usr/share/nginx/html
```

### Paso 3: Probar Persistencia

```bash
# Escribir datos en el StatefulSet
kubectl exec -n desarrollo database-statefulset-0 -- psql -U appuser -d myapp -c "CREATE TABLE test (id SERIAL PRIMARY KEY, data TEXT);"
kubectl exec -n desarrollo database-statefulset-0 -- psql -U appuser -d myapp -c "INSERT INTO test (data) VALUES ('Datos persistentes');"

# Eliminar pod para probar persistencia
kubectl delete pod database-statefulset-0 -n desarrollo

# Esperar a que se recree y verificar datos
kubectl wait --for=condition=ready pod database-statefulset-0 -n desarrollo --timeout=60s
kubectl exec -n desarrollo database-statefulset-0 -- psql -U appuser -d myapp -c "SELECT * FROM test;"
```

### Paso 4: Snapshots de Volúmenes

```bash
# Crear VolumeSnapshot
cat << 'EOF' | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-snapshot
  namespace: desarrollo
spec:
  volumeSnapshotClassName: csi-azuredisk-vsc
  source:
    persistentVolumeClaimName: postgres-storage-database-statefulset-0
EOF

# Verificar snapshot
kubectl get volumesnapshot -n desarrollo
kubectl describe volumesnapshot postgres-snapshot -n desarrollo

# Restaurar desde snapshot
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-postgres-pvc
  namespace: desarrollo
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: managed-premium
  dataSource:
    name: postgres-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF
```

---

## Resumen del Capítulo

El almacenamiento persistente en AKS se resuelve con Azure Disk (alto rendimiento, un Pod) y Azure Files (compartido, múltiples Pods). Aprendimos a usar StorageClasses para provisión dinámica, StatefulSets para bases de datos con identidad estable, y VolumeSnapshots para backup y restauración. La elección entre Disk y Files depende del patrón de acceso: ReadWriteOnce vs ReadWriteMany.
