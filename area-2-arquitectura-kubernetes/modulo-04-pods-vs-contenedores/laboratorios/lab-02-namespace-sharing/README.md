# 🔬 Lab 2: Namespace Sharing Deep Dive

## 📋 Información del Laboratorio

- **Duración estimada**: 40 minutos
- **Nivel**: Intermedio
- **Prerrequisitos**:
  - kubectl configurado
  - Cluster Kubernetes activo (minikube/kind)
  - Conocimientos básicos de Linux namespaces

## 🎯 Objetivo

Explorar en detalle **qué namespaces comparten** los contenedores dentro de un Pod de Kubernetes y cuáles permanecen aislados.

### Namespaces a Analizar:

- ✅ **Network** - IP address, routing tables
- ✅ **PID** - Process IDs visibility
- ✅ **IPC** - Inter-Process Communication
- ✅ **UTS** - Hostname and domain name
- ❌ **Mount** - Filesystem (NO compartido)
- ❌ **User** - User IDs (NO compartido)

## 🧪 Práctica

### Paso 1: Preparación del Entorno

```bash
mkdir -p ~/labs/modulo-04/namespace-demo && cd ~/labs/modulo-04/namespace-demo

echo "🔬 NAMESPACE SHARING ANALYSIS"
echo "=============================="
```

### Paso 2: Crear Pod Multi-Container

```bash
# Crear Pod multi-container para análisis
cat > namespace-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: namespace-demo
spec:
  containers:
  - name: container1
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo 'Container 1 running'; sleep 30; done"]
    
  - name: container2
    image: busybox  
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo 'Container 2 running'; sleep 30; done"]
EOF

kubectl apply -f namespace-pod.yaml
kubectl wait --for=condition=Ready pod/namespace-demo --timeout=60s
```

### Paso 3: Análisis de Network Namespace (Compartido)

```bash
echo ""
echo "🌐 1. NETWORK NAMESPACE (Compartido)"
echo "├─ Ambos contenedores tienen la misma IP"

echo "Network interfaces container1:"
kubectl exec namespace-demo -c container1 -- ip addr show eth0

echo ""
echo "Network interfaces container2:"
kubectl exec namespace-demo -c container2 -- ip addr show eth0

echo ""
echo "Verificar IP del Pod:"
kubectl get pod namespace-demo -o jsonpath='{.status.podIP}'
```

**🔍 Análisis**:
- Ambos contenedores **comparten la misma interfaz `eth0`**
- Tienen la **misma dirección IP**
- Pueden comunicarse vía `localhost`

### Paso 4: Análisis de PID Namespace (Compartido)

```bash
echo ""
echo "🔄 2. PID NAMESPACE (Compartido)"
echo "├─ Los contenedores pueden ver procesos entre sí"

echo "Procesos en container1:"
kubectl exec namespace-demo -c container1 -- ps aux

echo ""
echo "Procesos en container2 (nota que ve ambos):"
kubectl exec namespace-demo -c container2 -- ps aux
```

**🔍 Análisis**:
- Por defecto, cada contenedor ve **solo sus propios procesos**
- Para habilitar PID namespace sharing, usar `shareProcessNamespace: true`
- Verás los procesos de ambos contenedores desde cualquiera

**📝 Nota**: Para ver el verdadero sharing de PID namespace, crea este Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shared-pid-demo
spec:
  shareProcessNamespace: true  # ← Habilita PID sharing
  containers:
  - name: container1
    image: busybox
    command: ["/bin/sh", "-c", "while true; do sleep 30; done"]
  - name: container2
    image: busybox
    command: ["/bin/sh", "-c", "while true; do sleep 30; done"]
```

```bash
# Aplicar y probar
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: shared-pid-demo
spec:
  shareProcessNamespace: true
  containers:
  - name: container1
    image: busybox
    command: ["/bin/sh", "-c", "while true; do sleep 30; done"]
  - name: container2
    image: busybox
    command: ["/bin/sh", "-c", "while true; do sleep 30; done"]
EOF

kubectl wait --for=condition=Ready pod/shared-pid-demo --timeout=60s

echo "Procesos visibles desde container1 (con shareProcessNamespace=true):"
kubectl exec shared-pid-demo -c container1 -- ps aux

# Cleanup
kubectl delete pod shared-pid-demo
```

### Paso 5: Análisis de UTS Namespace (Compartido - Hostname)

```bash
echo ""
echo "🏷️ 3. UTS NAMESPACE (Compartido - Hostname)"
echo "├─ Ambos contenedores tienen el mismo hostname"

echo "Hostname container1:"
kubectl exec namespace-demo -c container1 -- hostname

echo "Hostname container2:"
kubectl exec namespace-demo -c container2 -- hostname

echo ""
echo "Hostname del Pod:"
kubectl get pod namespace-demo -o jsonpath='{.metadata.name}'
```

**🔍 Análisis**:
- Ambos contenedores **comparten el mismo hostname**
- El hostname es el **nombre del Pod**

### Paso 6: Análisis de IPC Namespace (Compartido)

```bash
echo ""
echo "💬 4. IPC NAMESPACE (Compartido)"
echo "├─ Pueden comunicarse via IPC"

echo "IPC resources container1:"
kubectl exec namespace-demo -c container1 -- ipcs

echo ""
echo "IPC resources container2:"
kubectl exec namespace-demo -c container2 -- ipcs
```

**🔍 Análisis**:
- Ambos contenedores **comparten el mismo IPC namespace**
- Pueden usar **shared memory**, **semaphores**, **message queues**

### Paso 7: Análisis de Mount Namespace (NO Compartido)

```bash
echo ""
echo "📁 5. MOUNT NAMESPACE (NO compartido)"
echo "├─ Cada contenedor tiene su propio filesystem"

echo "Filesystem container1:"
kubectl exec namespace-demo -c container1 -- df -h

echo ""
echo "Filesystem container2:"
kubectl exec namespace-demo -c container2 -- df -h

echo ""
echo "Crear archivo en container1:"
kubectl exec namespace-demo -c container1 -- touch /tmp/test-file

echo "Intentar leer desde container2:"
kubectl exec namespace-demo -c container2 -- ls /tmp/
```

**🔍 Análisis**:
- Cada contenedor tiene su **propio filesystem**
- Archivos creados en un contenedor **NO son visibles** en otro
- Para compartir archivos, usar **volumes**

### Paso 8: Análisis de User Namespace (NO Compartido)

```bash
echo ""
echo "👤 6. USER NAMESPACE (NO compartido)"
echo "├─ Pueden tener diferentes users"

echo "User container1:"
kubectl exec namespace-demo -c container1 -- id

echo "User container2:"  
kubectl exec namespace-demo -c container2 -- id
```

**🔍 Análisis**:
- Cada contenedor puede ejecutarse como **diferentes usuarios**
- User namespace permanece **independiente**

## 📊 Tabla Resumen

```
┌──────────────┬─────────────┬──────────────────────────────────────────┐
│  Namespace   │  Compartido │  Implicaciones                           │
├──────────────┼─────────────┼──────────────────────────────────────────┤
│  Network     │     ✅      │  Misma IP, comunicación localhost        │
│  PID         │  ✅ (opt)   │  Procesos visibles (con flag)            │
│  UTS         │     ✅      │  Mismo hostname                          │
│  IPC         │     ✅      │  Shared memory, semaphores               │
│  Mount       │     ❌      │  Filesystem independiente                │
│  User        │     ❌      │  Users independientes                    │
└──────────────┴─────────────┴──────────────────────────────────────────┘
```

## 🔬 Experimento Avanzado: Shared Volumes

Para compartir datos entre contenedores (compensando Mount namespace separado):

```bash
cat > shared-volume-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: shared-volume-demo
spec:
  containers:
  - name: writer
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do date >> /shared/log.txt; sleep 5; done"]
    volumeMounts:
    - name: shared-data
      mountPath: /shared
      
  - name: reader
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do tail -f /shared/log.txt; sleep 10; done"]
    volumeMounts:
    - name: shared-data
      mountPath: /shared
      
  volumes:
  - name: shared-data
    emptyDir: {}
EOF

kubectl apply -f shared-volume-pod.yaml
kubectl wait --for=condition=Ready pod/shared-volume-demo --timeout=60s

echo "Logs del reader (leyendo archivo escrito por writer):"
kubectl logs shared-volume-demo -c reader -f --tail=10

# Cleanup
kubectl delete pod shared-volume-demo
```

## ✅ Resultados Esperados

Al completar este laboratorio, habrás comprobado:

- ✅ **Network namespace**: Compartido → misma IP, localhost
- ✅ **PID namespace**: Opcional sharing con `shareProcessNamespace: true`
- ✅ **UTS namespace**: Compartido → mismo hostname
- ✅ **IPC namespace**: Compartido → shared memory
- ✅ **Mount namespace**: NO compartido → usar volumes para sharing
- ✅ **User namespace**: NO compartido → users independientes

## 🧹 Limpieza

```bash
kubectl delete pod namespace-demo
kubectl delete pod shared-pid-demo 2>/dev/null
kubectl delete pod shared-volume-demo 2>/dev/null
rm -rf ~/labs/modulo-04/namespace-demo
```

## 🎓 Conceptos Clave Aprendidos

1. **Namespace sharing** es la base del modelo de Pods
2. **Network sharing** permite comunicación localhost
3. **Mount namespace separado** requiere volumes para compartir archivos
4. **PID sharing** es opcional y útil para debugging
5. **IPC sharing** permite comunicación avanzada entre procesos

## 📚 Referencias

- [Linux Namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [Kubernetes Pod Spec - shareProcessNamespace](https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/)

## ⏭️ Siguiente Paso

Continúa con **[Lab 3: Sidecar Pattern Real-World](./lab-03-sidecar-real-world.md)** para implementar un sidecar de logging con aplicación real.
