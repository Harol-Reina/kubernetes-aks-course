# 🔬 Linux Namespaces en Kubernetes - Ejemplos Prácticos

Esta carpeta contiene **7 ejemplos completos** que demuestran cómo funcionan los **Linux Namespaces** en Kubernetes.

## 📚 ¿Qué son los Namespaces en Linux?

Un **namespace** en Linux es un mecanismo del kernel que **aísla recursos** entre procesos.

### Los 7 tipos de Namespaces:

| Namespace | Abrev. | Aísla | En Pods |
|-----------|--------|-------|---------|
| Network | `net` | Stack de red (IP, puertos, interfaces) | ✅ **Compartido** |
| IPC | `ipc` | Comunicación entre procesos (shared memory) | ✅ **Compartido** |
| UTS | `uts` | Hostname y domainname | ✅ **Compartido** |
| PID | `pid` | IDs de procesos | ⚙️ **Opcional** |
| Mount | `mnt` | Puntos de montaje del filesystem | 🚫 **NO compartido** |
| User | `user` | UIDs y GIDs de usuarios | 🚫 **NO compartido** |
| Cgroup | `cgroup` | Control groups (recursos) | 🚫 **NO compartido** |

---

## 📂 Contenido de la Carpeta

```
02-namespaces/
├── 01-network-namespace.yaml    # 🌐 Network - Compartido
├── 02-pid-namespace.yaml         # 🔄 PID - Opcional
├── 03-ipc-namespace.yaml         # 💬 IPC - Compartido
├── 04-uts-namespace.yaml         # 🏷️ UTS - Compartido
├── 05-mount-namespace.yaml       # 📁 Mount - NO compartido
├── 06-user-namespace.yaml        # 👤 User - NO compartido
├── 07-cgroup-namespace.yaml      # ⚙️ Cgroup - NO compartido
├── namespace-pod.yaml            # Demo básica (legacy)
├── test-all-namespaces.sh        # Script de prueba completo
└── README.md                     # Este archivo
```

---

## 🚀 Inicio Rápido

### Opción 1: Probar TODO con un script

```bash
cd 02-namespaces/
./test-all-namespaces.sh
```

Este script:
- ✅ Despliega todos los ejemplos
- ✅ Valida que funcionen correctamente
- ✅ Muestra resultados en tiempo real
- ✅ Ofrece cleanup automático

---

### Opción 2: Probar ejemplos individualmente

#### 🌐 1. Network Namespace (Compartido)

```bash
# Aplicar
kubectl apply -f 01-network-namespace.yaml

# Verificar misma IP
kubectl exec network-namespace-demo -c web-server -- ip addr show eth0
kubectl exec network-namespace-demo -c web-client -- ip addr show eth0

# Probar comunicación localhost
kubectl exec network-namespace-demo -c web-client -- curl localhost:8080

# Cleanup
kubectl delete pod network-namespace-demo
```

**✅ Demuestra**: Misma IP, comunicación vía localhost

---

#### 🔄 2. PID Namespace (Opcional)

```bash
# Aplicar (crea 2 Pods)
kubectl apply -f 02-pid-namespace.yaml

# Comparar procesos visibles
echo "=== SIN shareProcessNamespace ==="
kubectl exec pid-namespace-isolated -c debug -- ps aux

echo "=== CON shareProcessNamespace ==="
kubectl exec pid-namespace-shared -c debug -- ps aux

# Cleanup
kubectl delete pod pid-namespace-isolated pid-namespace-shared
```

**⚙️ Demuestra**: Visibilidad de procesos con `shareProcessNamespace: true`

---

#### 💬 3. IPC Namespace (Compartido)

```bash
# Aplicar
kubectl apply -f 03-ipc-namespace.yaml

# Ver producer escribiendo en shared memory
kubectl logs ipc-namespace-demo -c producer

# Ver consumer leyendo los mismos datos
kubectl logs ipc-namespace-demo -c consumer -f

# Verificar shared memory desde ambos
kubectl exec ipc-namespace-demo -c producer -- cat /dev/shm/data.txt
kubectl exec ipc-namespace-demo -c consumer -- cat /dev/shm/data.txt

# Prueba bidireccional
kubectl exec ipc-namespace-demo -c consumer -- sh -c "echo 'Test' > /dev/shm/test.txt"
kubectl exec ipc-namespace-demo -c producer -- cat /dev/shm/test.txt

# Cleanup
kubectl delete pod ipc-namespace-demo
```

**✅ Demuestra**: Shared memory, comunicación ultra-rápida

---

#### 🏷️ 4. UTS Namespace (Compartido)

```bash
# Aplicar
kubectl apply -f 04-uts-namespace.yaml

# Verificar mismo hostname
kubectl exec uts-namespace-demo -c container1 -- hostname
kubectl exec uts-namespace-demo -c container2 -- hostname

# Ver logs con análisis
kubectl logs uts-namespace-demo -c container1
kubectl logs uts-namespace-demo -c container2

# Cleanup
kubectl delete pod uts-namespace-demo
```

**✅ Demuestra**: Mismo hostname compartido

---

#### 📁 5. Mount Namespace (NO Compartido)

```bash
# Aplicar
kubectl apply -f 05-mount-namespace.yaml

# Ver logs explicativos
kubectl logs mount-namespace-demo -c writer
kubectl logs mount-namespace-demo -c reader
kubectl logs mount-namespace-demo -c isolated

# Verificar archivos privados NO visibles
kubectl exec mount-namespace-demo -c reader -- ls /tmp/private-writer.txt
# ↑ Error esperado: No such file

# Verificar volumen compartido SÍ accesible
kubectl exec mount-namespace-demo -c writer -- cat /shared/data.txt
kubectl exec mount-namespace-demo -c reader -- cat /shared/data.txt

# Verificar contenedor aislado sin volumen
kubectl exec mount-namespace-demo -c isolated -- ls /shared/
# ↑ Error esperado: No such file or directory

# Cleanup
kubectl delete pod mount-namespace-demo
```

**🚫 Demuestra**: Filesystem independiente, volúmenes compartibles

---

#### 👤 6. User Namespace (NO Compartido)

```bash
# Aplicar
kubectl apply -f 06-user-namespace.yaml

# Comparar UIDs
kubectl exec user-namespace-demo -c root-container -- id      # UID=0
kubectl exec user-namespace-demo -c user-container -- id      # UID=1000
kubectl exec user-namespace-demo -c custom-user-container -- id  # UID=2000

# Ver logs con análisis de permisos
kubectl logs user-namespace-demo -c root-container
kubectl logs user-namespace-demo -c user-container
kubectl logs user-namespace-demo -c custom-user-container

# Intentar operación privilegiada desde user
kubectl exec user-namespace-demo -c user-container -- apk add curl
# ↑ Fallará por falta de permisos

# Cleanup
kubectl delete pod user-namespace-demo
```

**🚫 Demuestra**: UIDs/GIDs diferentes, seguridad

---

#### ⚙️ 7. Cgroup Namespace (NO Compartido)

```bash
# Aplicar
kubectl apply -f 07-cgroup-namespace.yaml

# Ver uso de recursos en tiempo real
kubectl top pod cgroup-namespace-demo --containers

# Ver logs con información de cgroups
kubectl logs cgroup-namespace-demo -c cpu-intensive
kubectl logs cgroup-namespace-demo -c memory-intensive

# Generar carga y observar throttling
kubectl exec cgroup-namespace-demo -c cpu-intensive -- sh -c "dd if=/dev/zero of=/dev/null &"
kubectl top pod cgroup-namespace-demo --containers

# Cleanup
kubectl delete pod cgroup-namespace-demo
```

**🚫 Demuestra**: Control independiente de CPU/Memory

---

## 📊 Tabla Comparativa

| Ejemplo | Namespace | Compartido | Qué verás |
|---------|-----------|------------|-----------|
| 01 | Network | ✅ Sí | Misma IP, localhost funciona |
| 02 | PID | ⚙️ Opcional | Procesos visibles con flag |
| 03 | IPC | ✅ Sí | Shared memory bidireccional |
| 04 | UTS | ✅ Sí | Mismo hostname |
| 05 | Mount | 🚫 No | Archivos privados aislados |
| 06 | User | 🚫 No | UIDs diferentes (0, 1000, 2000) |
| 07 | Cgroup | 🚫 No | Recursos independientes |

---

## 🎯 Casos de Uso por Namespace

### ✅ **Network Namespace (Compartido)**
- Comunicación localhost entre contenedores
- Sidecar patterns (logging, monitoring)
- Service mesh (Istio, Linkerd)

### ✅ **IPC Namespace (Compartido)**
- High-performance computing
- Machine learning pipelines
- Producer-consumer patterns con shared memory

### ✅ **UTS Namespace (Compartido)**
- Logging consistente con mismo hostname
- Métricas agregadas por Pod

### ⚙️ **PID Namespace (Opcional)**
- Debugging de procesos
- Monitoring sidecars
- Process management entre contenedores

### 🚫 **Mount Namespace (NO Compartido)**
- Aislamiento de archivos temporales
- Volúmenes compartidos cuando se necesite
- Seguridad: cada contenedor su filesystem

### 🚫 **User Namespace (NO Compartido)**
- Seguridad: root en container != root en host
- Permisos granulares por contenedor
- Aislamiento de usuarios

### 🚫 **Cgroup Namespace (NO Compartido)**
- Control independiente de recursos
- Evitar resource starvation
- Aislamiento de CPU/Memory

---

## 🧠 Conceptos Clave

### Por Defecto en Kubernetes:
```
Pod:
  ├─ ✅ Network Namespace: COMPARTIDO
  ├─ ✅ IPC Namespace: COMPARTIDO
  ├─ ✅ UTS Namespace: COMPARTIDO
  ├─ ⚙️ PID Namespace: NO (habilitable con shareProcessNamespace)
  ├─ 🚫 Mount Namespace: NO (volúmenes compartibles)
  ├─ 🚫 User Namespace: NO
  └─ 🚫 Cgroup Namespace: NO
```

### Para habilitar PID compartido:
```yaml
spec:
  shareProcessNamespace: true  # ← Habilita PID namespace compartido
```

---

## 🔍 Debugging y Verificación

### Ver namespaces desde el nodo (requiere acceso SSH):
```bash
# Obtener PID de un contenedor
crictl ps | grep <pod-name>
crictl inspect <container-id> | grep pid

# Listar namespaces del proceso
lsns -p <pid>

# Ejemplo de output:
#        NS TYPE   NPROCS   PID USER  COMMAND
# 4026532198 mnt       2     1 root  /pause
# 4026532199 uts       3     1 root  /pause  ← Compartido
# 4026532200 ipc       3     1 root  /pause  ← Compartido
# 4026532202 net       3     1 root  /pause  ← Compartido
```

---

## 📚 Recursos Adicionales

- [Linux Namespaces man page](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [Kubernetes Pod Spec](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/#pod-v1-core)
- [shareProcessNamespace](https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/)
- [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

---

## ✅ Checklist de Validación

Después de ejecutar los ejemplos, deberías poder responder:

- [ ] ¿Por qué dos contenedores en un Pod pueden comunicarse vía localhost?
- [ ] ¿Qué namespace permite shared memory entre contenedores?
- [ ] ¿Cómo habilito visibilidad de procesos entre contenedores?
- [ ] ¿Por qué un archivo en `/tmp` de container1 NO se ve en container2?
- [ ] ¿Cómo puedo compartir archivos entre contenedores del mismo Pod?
- [ ] ¿Por qué es importante ejecutar contenedores como no-root?
- [ ] ¿Cómo evito que un contenedor consuma todos los recursos del nodo?

---

## 🏠 Navegación

- **[⬆️ Volver a ejemplos principales](../README.md)**
- **[📖 Documentación del módulo](../../README.md)**

---

**¡Experimenta con estos ejemplos para entender profundamente cómo funcionan los Pods en Kubernetes!** 🚀
