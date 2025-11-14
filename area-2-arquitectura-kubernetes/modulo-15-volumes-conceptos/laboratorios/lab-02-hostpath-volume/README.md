# 🗂️ Lab 02: HostPath Volume - Acceso al Sistema de Archivos del Nodo

## 📋 Objetivo

Aprender a usar volúmenes `hostPath` para montar directorios del nodo en Pods, entendiendo sus riesgos y casos de uso apropiados.

**Conceptos clave**:
- Acceso directo al filesystem del nodo
- Persistencia más allá del ciclo de vida del Pod
- Consideraciones de seguridad y portabilidad
- Casos de uso: logs del sistema, sockets Docker/containerd

---

## ⏱️ Duración Estimada

- **Nivel**: 🟡 Intermedio
- **Tiempo**: 25-30 minutos
- **Comandos**: ~18

---

## ⚠️ Advertencias Importantes

**HostPath tiene limitaciones serias**:
- ❌ No portátil entre nodos
- ❌ Riesgos de seguridad (acceso root al nodo)
- ❌ No recomendado para producción multi-nodo
- ✅ Útil para: desarrollo local, DaemonSets, agentes de sistema

---

## 📝 Paso a Paso

### 1️⃣ Preparar Directorio en el Nodo

**Para Minikube**:

```bash
# Acceder al nodo de Minikube
minikube ssh

# Crear directorio de prueba
sudo mkdir -p /mnt/data
sudo chmod 777 /mnt/data
echo "Hello from host node" | sudo tee /mnt/data/test.txt

# Salir del nodo
exit
```

**Para clusters multi-nodo**: Necesitarás crear el directorio en cada nodo o usar `nodeSelector` para forzar scheduling.

---

### 2️⃣ Pod con HostPath Básico

**Archivo**: `pod-hostpath-basic.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-hostpath-basic
  labels:
    app: hostpath-demo
spec:
  containers:
  - name: reader
    image: busybox
    command: ["sh", "-c"]
    args:
      - while true; do
          echo "=== Content from host ===";
          cat /host-data/test.txt 2>/dev/null || echo "File not found";
          ls -la /host-data/;
          sleep 10;
        done
    volumeMounts:
    - name: host-volume
      mountPath: /host-data
  
  volumes:
  - name: host-volume
    hostPath:
      path: /mnt/data
      type: Directory
```

**Crear el Pod**:

```bash
kubectl apply -f pod-hostpath-basic.yaml
```

**Verificar logs**:

```bash
kubectl logs pod-hostpath-basic --tail=15
```

**Salida esperada**:
```
=== Content from host ===
Hello from host node
total 4
-rw-r--r-- 1 root root 20 Nov 13 10:30 test.txt
```

---

### 3️⃣ Escribir desde el Pod al Host

**Archivo**: `pod-hostpath-writer.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-hostpath-writer
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh", "-c"]
    args:
      - echo "Written by Pod at $(date)" > /host-data/pod-output.txt;
        echo "File created successfully";
        cat /host-data/pod-output.txt;
        sleep 3600
    volumeMounts:
    - name: host-volume
      mountPath: /host-data
  
  volumes:
  - name: host-volume
    hostPath:
      path: /mnt/data
      type: DirectoryOrCreate
```

**Crear y verificar**:

```bash
kubectl apply -f pod-hostpath-writer.yaml

# Ver logs
kubectl logs pod-hostpath-writer

# Verificar archivo en el nodo
minikube ssh "cat /mnt/data/pod-output.txt"
```

---

### 4️⃣ HostPath Types (Tipos)

**Archivo**: `pod-hostpath-types.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-hostpath-types
spec:
  containers:
  - name: explorer
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run/docker.sock
      readOnly: true
    - name: etc-config
      mountPath: /host-etc
      readOnly: true
  
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
      type: Socket  # Espera un socket Unix
  
  - name: etc-config
    hostPath:
      path: /etc
      type: Directory  # Espera un directorio existente
```

**Tipos disponibles**:

| Type | Descripción | Validación |
|------|-------------|------------|
| `DirectoryOrCreate` | Crea directorio si no existe | ✅ Crea |
| `Directory` | Debe existir | ❌ Falla si no existe |
| `FileOrCreate` | Crea archivo si no existe | ✅ Crea |
| `File` | Debe existir | ❌ Falla si no existe |
| `Socket` | Debe ser un socket Unix | ❌ Falla si no es socket |
| `CharDevice` | Dispositivo de caracteres | ❌ Falla si no es char device |
| `BlockDevice` | Dispositivo de bloque | ❌ Falla si no es block device |

**Probar**:

```bash
kubectl apply -f pod-hostpath-types.yaml

# Verificar acceso al socket Docker (si existe)
kubectl exec pod-hostpath-types -- ls -l /var/run/docker.sock
```

---

### 5️⃣ Persistencia entre Pods

**Crear primer Pod**:

```bash
kubectl run pod-writer --image=busybox --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "writer",
      "image": "busybox",
      "command": ["sh", "-c", "echo \"Persistent data\" > /data/persistent.txt; sleep 10"],
      "volumeMounts": [{"name": "host-vol", "mountPath": "/data"}]
    }],
    "volumes": [{"name": "host-vol", "hostPath": {"path": "/mnt/data", "type": "DirectoryOrCreate"}}]
  }
}'

# Esperar a que termine
kubectl wait --for=condition=Ready pod/pod-writer --timeout=30s
```

**Crear segundo Pod para leer**:

```bash
kubectl run pod-reader --image=busybox --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "reader",
      "image": "busybox",
      "command": ["cat", "/data/persistent.txt"],
      "volumeMounts": [{"name": "host-vol", "mountPath": "/data"}]
    }],
    "volumes": [{"name": "host-vol", "hostPath": {"path": "/mnt/data"}}]
  }
}'

# Ver logs
kubectl logs pod-reader
# Salida: Persistent data
```

**📌 Conclusión**: Datos persisten entre Pods en el mismo nodo.

---

### 6️⃣ DaemonSet con HostPath (Caso de Uso Real)

**Archivo**: `daemonset-log-collector.yaml`

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      containers:
      - name: collector
        image: busybox
        command: ["sh", "-c"]
        args:
          - while true; do
              echo "Scanning /var/log at $(date)";
              ls -lh /host-logs/ | head -10;
              sleep 30;
            done
        volumeMounts:
        - name: var-log
          mountPath: /host-logs
          readOnly: true
      
      volumes:
      - name: var-log
        hostPath:
          path: /var/log
          type: Directory
```

**Crear DaemonSet**:

```bash
kubectl apply -f daemonset-log-collector.yaml

# Ver Pods (uno por nodo)
kubectl get pods -l app=log-collector

# Ver logs de uno
kubectl logs -l app=log-collector --tail=20
```

---

## 🔍 Troubleshooting

### Problema 1: "Path does not exist"

**Síntoma**:
```
Warning  FailedMount  pod/my-pod  MountVolume.SetUp failed: hostPath type check failed
```

**Diagnóstico**:

```bash
kubectl describe pod <pod-name>

# Verificar en el nodo
minikube ssh "ls -la /mnt/data"
```

**Solución**: Cambiar `type: Directory` a `type: DirectoryOrCreate` o crear el directorio manualmente.

---

### Problema 2: Permission Denied

**Síntoma**:
```
Error: Permission denied when writing to /host-data
```

**Solución**: Ajustar permisos del directorio en el host:

```bash
minikube ssh "sudo chmod 777 /mnt/data"
```

O usar `securityContext`:

```yaml
securityContext:
  runAsUser: 0  # Ejecutar como root (cuidado en producción)
```

---

### Problema 3: Pod Scheduled en Nodo Diferente

**Síntoma**: En cluster multi-nodo, el Pod va a un nodo sin el directorio.

**Solución**: Usar `nodeSelector` o `nodeAffinity`:

```yaml
spec:
  nodeSelector:
    kubernetes.io/hostname: node-1
```

---

## 📊 Comparación: EmptyDir vs HostPath

| Aspecto | EmptyDir | HostPath |
|---------|----------|----------|
| **Persistencia** | Vida del Pod | Más allá del Pod |
| **Portabilidad** | ✅ Cualquier nodo | ❌ Específico del nodo |
| **Seguridad** | ✅ Aislado | ⚠️ Acceso al host |
| **Casos de uso** | Datos temporales | Logs, sockets, configs |
| **Producción** | ✅ Seguro | ⚠️ Usar con precaución |

---

## ✅ Verificación de Aprendizaje

**Checklist**:

- [ ] ✅ Creé un Pod que lee archivos del nodo con hostPath
- [ ] ✅ Escribí datos desde un Pod al filesystem del nodo
- [ ] ✅ Verifiqué persistencia de datos entre diferentes Pods
- [ ] ✅ Entiendo los diferentes `type` de hostPath
- [ ] ✅ Implementé un DaemonSet con hostPath
- [ ] ✅ Entiendo los riesgos de seguridad de hostPath

---

## 🎓 Preguntas de Repaso

1. **¿Por qué hostPath no es recomendado para producción multi-nodo?**
   <details>
   <summary>Ver respuesta</summary>
   
   - No es portátil: el path solo existe en nodos específicos
   - Si el Pod se reprograma en otro nodo, pierde acceso a los datos
   - Dificulta balanceo de carga y escalado horizontal
   </details>

2. **¿Cuándo SÍ deberías usar hostPath?**
   <details>
   <summary>Ver respuesta</summary>
   
   - DaemonSets que necesitan acceso a logs/métricas del nodo
   - Acceso a sockets Docker/containerd para monitoring
   - Desarrollo local con Minikube/Kind
   - Agentes de sistema que requieren acceso al nodo
   </details>

3. **¿Qué riesgos de seguridad tiene hostPath?**
   <details>
   <summary>Ver respuesta</summary>
   
   - Acceso directo al filesystem del nodo (potencial escape del contenedor)
   - Puede leer/escribir archivos sensibles del sistema
   - Escalación de privilegios si se monta `/` o directorios críticos
   - Requiere PodSecurityPolicy/SecurityContext estrictos en producción
   </details>

---

## 🔗 Recursos Adicionales

- [HostPath Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [DaemonSet Best Practices](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)

---

## 🧹 Limpieza

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete pod pod-hostpath-basic pod-hostpath-writer pod-hostpath-types
kubectl delete pod pod-writer pod-reader
kubectl delete daemonset log-collector

# Limpiar archivos del nodo (opcional)
minikube ssh "sudo rm -rf /mnt/data/*"
```

---

## 📚 Siguientes Pasos

➡️ **Lab 03**: ConfigMap Volume - Inyectar configuración como archivos

---

**🎯 Has completado el Lab 02 - HostPath Volume**

Ahora entiendes cómo acceder al filesystem del nodo, sus riesgos y casos de uso apropiados. ¡Continúa con ConfigMap volumes! 🚀
