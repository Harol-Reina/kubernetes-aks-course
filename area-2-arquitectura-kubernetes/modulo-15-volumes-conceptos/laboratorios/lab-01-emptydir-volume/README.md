# 🔄 Lab 01: EmptyDir Volume - Almacenamiento Temporal Compartido

## 📋 Objetivo

Aprender a usar volúmenes `emptyDir` para compartir datos temporales entre contenedores en un mismo Pod.

**Conceptos clave**:
- Volumen efímero que vive con el Pod
- Compartir datos entre contenedores
- Casos de uso: caches, datos temporales, sidecars

---

## ⏱️ Duración Estimada

- **Nivel**: 🟢 Principiante
- **Tiempo**: 20-25 minutos
- **Comandos**: ~15

---

## 🎯 Escenarios de Aprendizaje

### Escenario 1: Contenedores Compartiendo Datos

Dos contenedores en un Pod que comparten un directorio de logs.

**Flujo**:
1. Producer escribe logs en `/data/logs`
2. Consumer lee logs desde `/data/logs`
3. Ambos usan el mismo volumen `emptyDir`

### Escenario 2: EmptyDir en RAM (tmpfs)

Volumen en memoria para datos ultra-rápidos.

---

## 📝 Paso a Paso

### 1️⃣ Crear Pod con EmptyDir Compartido

**Archivo**: `pod-emptydir-shared.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-emptydir-shared
  labels:
    app: emptydir-demo
spec:
  containers:
  - name: producer
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - while true; do
          echo "$(date): Log entry from producer" >> /data/logs/app.log;
          sleep 5;
        done
    volumeMounts:
    - name: shared-data
      mountPath: /data/logs
  
  - name: consumer
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - while true; do
          echo "=== Latest logs ===";
          tail -5 /data/logs/app.log;
          sleep 10;
        done
    volumeMounts:
    - name: shared-data
      mountPath: /data/logs
      readOnly: true
  
  volumes:
  - name: shared-data
    emptyDir: {}
```

**Crear el Pod**:

```bash
kubectl apply -f pod-emptydir-shared.yaml
```

**Verificar estado**:

```bash
# Ver estado del Pod
kubectl get pod pod-emptydir-shared

# Ver logs del producer
kubectl logs pod-emptydir-shared -c producer

# Ver logs del consumer
kubectl logs pod-emptydir-shared -c consumer --tail=20
```

**Salida esperada del consumer**:
```
=== Latest logs ===
Wed Nov 13 10:15:30 UTC 2025: Log entry from producer
Wed Nov 13 10:15:35 UTC 2025: Log entry from producer
Wed Nov 13 10:15:40 UTC 2025: Log entry from producer
```

---

### 2️⃣ Verificar Datos Compartidos

**Ejecutar comando en producer**:

```bash
kubectl exec pod-emptydir-shared -c producer -- cat /data/logs/app.log
```

**Ejecutar comando en consumer**:

```bash
kubectl exec pod-emptydir-shared -c consumer -- cat /data/logs/app.log
```

**✅ Validación**: Ambos contenedores leen el mismo archivo.

---

### 3️⃣ EmptyDir en Memoria (tmpfs)

**Archivo**: `pod-emptydir-memory.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-emptydir-memory
spec:
  containers:
  - name: cache-app
    image: nginx:alpine
    volumeMounts:
    - name: cache-volume
      mountPath: /cache
  
  volumes:
  - name: cache-volume
    emptyDir:
      medium: Memory
      sizeLimit: 128Mi
```

**Crear el Pod**:

```bash
kubectl apply -f pod-emptydir-memory.yaml
```

**Verificar montaje**:

```bash
# Ver información del Pod
kubectl describe pod pod-emptydir-memory

# Verificar montaje en memoria
kubectl exec pod-emptydir-memory -- df -h /cache
```

**Salida esperada**:
```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           128M     0  128M   0% /cache
```

---

### 4️⃣ Probar Persistencia del Volumen

**Escribir datos en emptyDir**:

```bash
kubectl exec pod-emptydir-shared -c producer -- sh -c \
  "echo 'Test data' > /data/logs/test.txt"
```

**Leer datos**:

```bash
kubectl exec pod-emptydir-shared -c consumer -- cat /data/logs/test.txt
```

**Eliminar y recrear el Pod**:

```bash
kubectl delete pod pod-emptydir-shared
kubectl apply -f pod-emptydir-shared.yaml

# Intentar leer el archivo (no existirá)
kubectl exec pod-emptydir-shared -c consumer -- cat /data/logs/test.txt
# Error: cat: can't open '/data/logs/test.txt': No such file or directory
```

**📌 Conclusión**: EmptyDir es efímero, los datos se pierden al eliminar el Pod.

---

### 5️⃣ EmptyDir con SizeLimit

**Archivo**: `pod-emptydir-sized.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-emptydir-sized
spec:
  containers:
  - name: writer
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - dd if=/dev/zero of=/data/file.dat bs=1M count=150 || true;
        sleep 3600
    volumeMounts:
    - name: limited-storage
      mountPath: /data
  
  volumes:
  - name: limited-storage
    emptyDir:
      sizeLimit: 100Mi
```

**Crear y observar**:

```bash
kubectl apply -f pod-emptydir-sized.yaml

# Ver eventos (debería mostrar error de espacio)
kubectl get events --field-selector involvedObject.name=pod-emptydir-sized
```

---

## 🔍 Troubleshooting

### Problema 1: Contenedor No Puede Escribir

**Síntoma**:
```
Error: Permission denied
```

**Diagnóstico**:

```bash
kubectl describe pod pod-emptydir-shared
kubectl logs pod-emptydir-shared -c producer
```

**Solución**: Verificar permisos del volumen o usar `securityContext`:

```yaml
containers:
- name: producer
  securityContext:
    runAsUser: 1000
    fsGroup: 1000
```

---

### Problema 2: Datos No Se Comparten

**Síntoma**: Consumer no ve datos del producer.

**Diagnóstico**:

```bash
# Verificar montajes
kubectl exec pod-emptydir-shared -c producer -- ls -la /data/logs
kubectl exec pod-emptydir-shared -c consumer -- ls -la /data/logs
```

**Solución**: Verificar que `mountPath` sea idéntico en ambos contenedores.

---

### Problema 3: Out of Memory con EmptyDir en RAM

**Síntoma**:
```
Pod evicted due to ephemeral storage limit
```

**Solución**: Ajustar `sizeLimit` o cambiar `medium` a disco:

```yaml
volumes:
- name: cache-volume
  emptyDir:
    medium: ""  # Usa disco en lugar de memoria
```

---

## 📊 Resumen de Conceptos

| Aspecto | EmptyDir | Detalles |
|---------|----------|----------|
| **Ciclo de vida** | Ligado al Pod | Se borra al eliminar Pod |
| **Compartición** | Entre contenedores del Pod | ✅ Sí |
| **Persistencia** | ❌ No | Datos efímeros |
| **Ubicación** | Disco o RAM | Configurable con `medium` |
| **Tamaño** | Sin límite por defecto | Ajustable con `sizeLimit` |
| **Casos de uso** | Caches, logs temporales | Sidecars, procesamiento |

---

## ✅ Verificación de Aprendizaje

**Checklist**:

- [ ] ✅ Creé un Pod con emptyDir compartido entre 2 contenedores
- [ ] ✅ Verifiqué que ambos contenedores leen/escriben los mismos datos
- [ ] ✅ Probé emptyDir en memoria (tmpfs)
- [ ] ✅ Confirmé que los datos se pierden al eliminar el Pod
- [ ] ✅ Configuré un sizeLimit en emptyDir
- [ ] ✅ Entiendo cuándo usar emptyDir vs volúmenes persistentes

---

## 🎓 Preguntas de Repaso

1. **¿Qué sucede con los datos de emptyDir cuando el Pod se reinicia?**
   <details>
   <summary>Ver respuesta</summary>
   
   Los datos **se pierden**. EmptyDir está ligado al ciclo de vida del Pod, no del contenedor. Al eliminar el Pod, el volumen también se elimina.
   </details>

2. **¿Cuál es la diferencia entre `medium: Memory` y sin especificar `medium`?**
   <details>
   <summary>Ver respuesta</summary>
   
   - `medium: Memory`: Crea un tmpfs en RAM (más rápido, pero limitado por memoria del nodo)
   - Sin especificar: Usa el disco del nodo (más lento, pero más espacio disponible)
   </details>

3. **¿Puedo compartir un emptyDir entre Pods diferentes?**
   <details>
   <summary>Ver respuesta</summary>
   
   ❌ **No**. EmptyDir es exclusivo de un Pod. Para compartir entre Pods, usa PersistentVolumes o volúmenes de red.
   </details>

4. **¿Cuándo usarías emptyDir en lugar de PersistentVolume?**
   <details>
   <summary>Ver respuesta</summary>
   
   - Datos temporales que no necesitan persistir
   - Caches que se pueden regenerar
   - Procesamiento de datos en pipeline
   - Sidecars que generan archivos auxiliares
   </details>

---

## 🔗 Recursos Adicionales

- [Kubernetes Volumes - EmptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)
- [Ephemeral Volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/)
- [Storage Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

## 🧹 Limpieza

Ejecuta el script de limpieza:

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete pod pod-emptydir-shared pod-emptydir-memory pod-emptydir-sized
```

---

## 📚 Siguientes Pasos

➡️ **Lab 02**: HostPath Volume - Montar directorios del nodo  
➡️ **Lab 03**: ConfigMap Volume - Configuración como archivos

---

**🎯 Has completado el Lab 01 - EmptyDir Volume**

Ahora entiendes cómo usar volúmenes efímeros para compartir datos temporales entre contenedores. ¡Continúa con hostPath para acceder al sistema de archivos del nodo! 🚀
