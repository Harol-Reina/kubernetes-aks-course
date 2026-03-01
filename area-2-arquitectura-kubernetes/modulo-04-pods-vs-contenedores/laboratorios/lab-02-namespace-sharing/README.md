# Laboratorio 02: Namespace Sharing Deep Dive - Analisis de Namespaces en Pods

**Duracion estimada:** 40 minutos
**Nivel:** Intermedio
**Objetivo:** Explorar en detalle que namespaces comparten los contenedores dentro de un Pod de Kubernetes y cuales permanecen aislados, verificando experimentalmente cada comportamiento

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Network namespace compartido** | Ambos contenedores en un Pod tienen la misma IP de Pod y pueden comunicarse via localhost. Verificable con `ip addr show eth0` desde cada contenedor |
| **PID namespace (opcional)** | Por defecto cada contenedor ve solo sus propios procesos. Con `shareProcessNamespace: true` en el spec del Pod, todos los procesos son visibles entre contenedores |
| **UTS namespace compartido** | Ambos contenedores comparten el mismo hostname, que es el nombre del Pod. Verificable con el comando `hostname` desde cada contenedor |
| **IPC namespace compartido** | Los contenedores pueden usar mecanismos de IPC del kernel (shared memory, semaforos, colas de mensajes) entre si |
| **Mount namespace independiente** | Cada contenedor tiene su propio filesystem. Archivos creados en uno no son visibles en el otro sin usar volumes |
| **emptyDir volume** | Volume efimero que permite compartir datos entre contenedores del mismo Pod, compensando el aislamiento del mount namespace |
| **kubectl exec -c** | Ejecuta comandos en un contenedor especifico de un Pod multi-container usando el flag `-c nombre-contenedor` |

---

## Archivos del Laboratorio

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `namespace-pod.yaml` | 2 | Pod multi-container con dos busybox para analizar namespaces compartidos y aislados |
| `shared-pid-pod.yaml` | 4 | Pod con `shareProcessNamespace: true` para demostrar sharing opcional de PID namespace |
| `shared-volume-pod.yaml` | 8 | Pod writer + reader compartiendo datos via volume emptyDir |
| `cleanup.sh` | - | Script de limpieza de todos los Pods del laboratorio |

---

## Namespaces a Analizar

- **Network** - IP address, routing tables (compartido)
- **PID** - Process IDs visibility (compartido opcionalmente con flag)
- **IPC** - Inter-Process Communication (compartido)
- **UTS** - Hostname and domain name (compartido)
- **Mount** - Filesystem (NO compartido)
- **User** - User IDs (NO compartido)

## Practica

### Paso 1: Preparacion del Entorno

```bash
mkdir -p ~/labs/modulo-04/namespace-demo && cd ~/labs/modulo-04/namespace-demo

echo "NAMESPACE SHARING ANALYSIS"
echo "=============================="
```

### Paso 2: Crear Pod Multi-Container

Revisa el archivo `namespace-pod.yaml` antes de aplicarlo:

```bash
cat namespace-pod.yaml
```

Puntos clave del manifiesto:
- Dos contenedores identicos usando `busybox`
- Cada uno ejecuta un bucle infinito con `sleep 30` para mantenerse activo
- Sin ninguna configuracion especial de namespaces (comportamiento por defecto)

```bash
kubectl apply -f namespace-pod.yaml
```

Salida esperada:
```
pod/namespace-demo created
```

```bash
kubectl wait --for=condition=Ready pod/namespace-demo --timeout=60s
```

Salida esperada:
```
pod/namespace-demo condition met
```

### Paso 3: Analisis de Network Namespace (Compartido)

```bash
echo ""
echo "1. NETWORK NAMESPACE (Compartido)"
echo "- Ambos contenedores tienen la misma IP"

echo "Network interfaces container1:"
kubectl exec namespace-demo -c container1 -- ip addr show eth0

echo ""
echo "Network interfaces container2:"
kubectl exec namespace-demo -c container2 -- ip addr show eth0

echo ""
echo "Verificar IP del Pod:"
kubectl get pod namespace-demo -o jsonpath='{.status.podIP}'
```

Salida esperada (ambos contenedores muestran la misma IP):
```
2: eth0@if6: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    inet 10.244.0.X/24 brd 10.244.0.255 scope global eth0
```

**Analisis:**
- Ambos contenedores **comparten la misma interfaz `eth0`**
- Tienen la **misma direccion IP**
- Pueden comunicarse via `localhost`

### Paso 4: Analisis de PID Namespace (Compartido)

```bash
echo ""
echo "2. PID NAMESPACE (Compartido)"
echo "- Los contenedores pueden ver procesos entre si"

echo "Procesos en container1:"
kubectl exec namespace-demo -c container1 -- ps aux

echo ""
echo "Procesos en container2 (nota que ve ambos):"
kubectl exec namespace-demo -c container2 -- ps aux
```

**Analisis:**
- Por defecto, cada contenedor ve **solo sus propios procesos**
- Para habilitar PID namespace sharing, usar `shareProcessNamespace: true`
- Con el flag habilitado, veras los procesos de ambos contenedores desde cualquiera

**Nota:** Para ver el verdadero sharing de PID namespace, crea este Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shared-pid-demo
spec:
  shareProcessNamespace: true  # Habilita PID sharing
  containers:
  - name: container1
    image: busybox
    command: ["/bin/sh", "-c", "while true; do sleep 30; done"]
  - name: container2
    image: busybox
    command: ["/bin/sh", "-c", "while true; do sleep 30; done"]
```

```bash
# Aplicar el Pod con PID sharing habilitado
kubectl apply -f shared-pid-pod.yaml
kubectl wait --for=condition=Ready pod/shared-pid-demo --timeout=60s
```

Salida esperada:
```
pod/shared-pid-demo created
pod/shared-pid-demo condition met
```

```bash
echo "Procesos visibles desde container1 (con shareProcessNamespace=true):"
kubectl exec shared-pid-demo -c container1 -- ps aux
```

Salida esperada (container1 ve procesos de ambos contenedores):
```
PID   USER     TIME  COMMAND
    1 root      0:00 /pause
    7 root      0:00 /bin/sh -c while true; do sleep 30; done
   13 root      0:00 /bin/sh -c while true; do sleep 30; done
   19 root      0:00 sleep 30
   20 root      0:00 sleep 30
   21 root      0:00 ps aux
```

```bash
# Cleanup del Pod con PID sharing
kubectl delete pod shared-pid-demo
```

### Paso 5: Analisis de UTS Namespace (Compartido - Hostname)

```bash
echo ""
echo "3. UTS NAMESPACE (Compartido - Hostname)"
echo "- Ambos contenedores tienen el mismo hostname"

echo "Hostname container1:"
kubectl exec namespace-demo -c container1 -- hostname

echo "Hostname container2:"
kubectl exec namespace-demo -c container2 -- hostname

echo ""
echo "Hostname del Pod:"
kubectl get pod namespace-demo -o jsonpath='{.metadata.name}'
```

Salida esperada (ambos muestran el mismo nombre):
```
namespace-demo
namespace-demo
namespace-demo
```

**Analisis:**
- Ambos contenedores **comparten el mismo hostname**
- El hostname es el **nombre del Pod**

### Paso 6: Analisis de IPC Namespace (Compartido)

```bash
echo ""
echo "4. IPC NAMESPACE (Compartido)"
echo "- Pueden comunicarse via IPC"

echo "IPC resources container1:"
kubectl exec namespace-demo -c container1 -- ipcs

echo ""
echo "IPC resources container2:"
kubectl exec namespace-demo -c container2 -- ipcs
```

**Analisis:**
- Ambos contenedores **comparten el mismo IPC namespace**
- Pueden usar **shared memory**, **semaphores**, **message queues**

### Paso 7: Analisis de Mount Namespace (NO Compartido)

```bash
echo ""
echo "5. MOUNT NAMESPACE (NO compartido)"
echo "- Cada contenedor tiene su propio filesystem"

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

Salida esperada (container2 NO ve el archivo creado en container1):
```
(directorio /tmp/ vacio en container2)
```

**Analisis:**
- Cada contenedor tiene su **propio filesystem**
- Archivos creados en un contenedor **NO son visibles** en otro
- Para compartir archivos, usar **volumes**

### Paso 8: Analisis de User Namespace (NO Compartido)

```bash
echo ""
echo "6. USER NAMESPACE (NO compartido)"
echo "- Pueden tener diferentes users"

echo "User container1:"
kubectl exec namespace-demo -c container1 -- id

echo "User container2:"
kubectl exec namespace-demo -c container2 -- id
```

**Analisis:**
- Cada contenedor puede ejecutarse como **diferentes usuarios**
- User namespace permanece **independiente**

## Tabla Resumen

```
+--------------+-------------+------------------------------------------+
|  Namespace   |  Compartido |  Implicaciones                           |
+--------------+-------------+------------------------------------------+
|  Network     |     Si      |  Misma IP, comunicacion localhost        |
|  PID         |  Si (opt)   |  Procesos visibles (con flag)            |
|  UTS         |     Si      |  Mismo hostname                          |
|  IPC         |     Si      |  Shared memory, semaphores               |
|  Mount       |     No      |  Filesystem independiente                |
|  User        |     No      |  Users independientes                    |
+--------------+-------------+------------------------------------------+
```

## Experimento Avanzado: Shared Volumes

Para compartir datos entre contenedores (compensando Mount namespace separado), revisa el archivo `shared-volume-pod.yaml`:

```bash
cat shared-volume-pod.yaml
```

Puntos clave del manifiesto:
- Contenedor `writer` escribe timestamps en `/shared/log.txt` cada 5 segundos
- Contenedor `reader` lee el mismo archivo continuamente con `tail -f`
- Ambos montan el mismo volume `shared-data` de tipo `emptyDir`

```bash
kubectl apply -f shared-volume-pod.yaml
kubectl wait --for=condition=Ready pod/shared-volume-demo --timeout=60s
```

Salida esperada:
```
pod/shared-volume-demo created
pod/shared-volume-demo condition met
```

```bash
echo "Logs del reader (leyendo archivo escrito por writer):"
kubectl logs shared-volume-demo -c reader -f --tail=10
```

Salida esperada (timestamps escritos por writer, leidos por reader):
```
Sat Mar  1 12:00:00 UTC 2026
Sat Mar  1 12:00:05 UTC 2026
Sat Mar  1 12:00:10 UTC 2026
```

Presiona Ctrl+C para detener el seguimiento de logs.

```bash
# Cleanup del Pod de volumes
kubectl delete pod shared-volume-demo
```

## Resultados Esperados

Al completar este laboratorio, habras comprobado:

- **Network namespace**: Compartido - misma IP, localhost
- **PID namespace**: Opcional sharing con `shareProcessNamespace: true`
- **UTS namespace**: Compartido - mismo hostname
- **IPC namespace**: Compartido - shared memory
- **Mount namespace**: NO compartido - usar volumes para sharing
- **User namespace**: NO compartido - users independientes

## Limpieza

Ejecuta el script de limpieza incluido:

```bash
bash cleanup.sh
```

O si necesitas limpiar manualmente:

```bash
kubectl delete pod namespace-demo
kubectl delete pod shared-pid-demo 2>/dev/null
kubectl delete pod shared-volume-demo 2>/dev/null
rm -rf ~/labs/modulo-04/namespace-demo
```

## Conceptos Clave Aprendidos

1. **Namespace sharing** es la base del modelo de Pods
2. **Network sharing** permite comunicacion localhost
3. **Mount namespace separado** requiere volumes para compartir archivos
4. **PID sharing** es opcional y util para debugging
5. **IPC sharing** permite comunicacion avanzada entre procesos

## Referencias

- [Linux Namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [Kubernetes Pod Spec - shareProcessNamespace](https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/)

## Siguiente Paso

Continua con **Lab 03: Sidecar Pattern Real-World** para implementar un sidecar de logging con aplicacion real.
