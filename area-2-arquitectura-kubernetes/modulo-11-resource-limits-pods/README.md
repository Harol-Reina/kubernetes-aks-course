# Capítulo 13: Resource Limits en Pods

Los Namespaces organizan. Ahora controlamos cuántos recursos consume cada Pod: requests, limits, y las consecuencias de no definirlos.

---

## 🎓 Metodología de Aprendizaje

Este módulo sigue el patrón pedagógico del curso:

1. **Teoría estructurada**: Cada sección explica conceptos con analogías y diagramas
2. **Ejemplos inline**: YAMLs completos en `ejemplos/` referenciados inmediatamente
3. **Laboratorios prácticos**: 3 labs progresivos con escenarios realistas
4. **Resumen ejecutivo**: [RESUMEN-MODULO.md](RESUMEN-MODULO.md) para repaso rápido

### Consejos de Estudio
- ⚠️ **Crítico**: Entender la diferencia entre requests y limits (80% de problemas vienen de aquí)
- 📊 Experimentar con las 3 QoS classes en el clúster
- 🧪 Provocar OOMKilled intencionalmente para entender su comportamiento
- 📈 Usar `kubectl top` constantemente para correlacionar teoría con realidad
- 🔍 Leer logs del kubelet cuando un Pod no se programa

---

## Índice Detallado

1. [Introducción](#introducción)
2. [Conceptos Fundamentales](#conceptos-fundamentales)
3. [Requests vs Limits](#requests-vs-limits)
4. [Tipos de Recursos](#tipos-de-recursos)
5. [Unidades de Recursos](#unidades-de-recursos)
6. [Quality of Service (QoS) Classes](#quality-of-service-qos-classes)
7. [Configuración de Recursos](#configuración-de-recursos)
8. [Pod-level Resources (Beta K8s 1.34)](#pod-level-resources-beta-k8s-134)
9. [Ephemeral Storage](#ephemeral-storage)
10. [Extended Resources](#extended-resources)
11. [Comportamiento del Scheduler](#comportamiento-del-scheduler)
12. [Enforcement de Límites](#enforcement-de-límites)
13. [Monitoreo de Recursos](#monitoreo-de-recursos)
14. [Best Practices](#best-practices)
15. [Troubleshooting](#troubleshooting)
16. [Laboratorios](#laboratorios)
17. [Referencias](#referencias)

---

## Introducción

La gestión de recursos es **crítica** para la estabilidad y eficiencia de aplicaciones en Kubernetes. Este módulo cubre en profundidad cómo especificar y gestionar recursos (CPU, memoria, almacenamiento) para contenedores y Pods.

### ¿Por qué es importante?

- **Estabilidad del clúster**: Prevenir que un Pod consuma todos los recursos del nodo
- **Scheduling eficiente**: El scheduler necesita saber cuántos recursos requiere cada Pod
- **Calidad de Servicio**: Garantizar recursos mínimos para aplicaciones críticas
- **Optimización de costos**: Evitar sobre-aprovisionamiento de recursos
- **Prevención de OOMKilled**: Controlar el uso de memoria para evitar terminaciones inesperadas

### Actualización Noviembre 2025

Este documento está actualizado para **Kubernetes 1.28+** e incluye:
- ✅ Pod-level resources (feature beta en K8s 1.34)
- ✅ Memory QoS considerations (feature stalled)
- ✅ Ephemeral storage management mejorado
- ✅ Extended resources con DRA (Dynamic Resource Allocation)
- ✅ Best practices actualizadas para producción

---

## Conceptos Fundamentales

### ¿Qué son los Resource Requests y Limits?

Los **requests** y **limits** son dos mecanismos para controlar el uso de recursos:

```
┌─────────────────────────────────────────────────────────┐
│                    NODO (8 CPU, 16 GB)                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Pod A                                            │   │
│  │  Request: 1 CPU, 2 GB  ◄── Scheduler garantiza   │   │
│  │  Limit:   2 CPU, 4 GB  ◄── Kubelet enforza       │   │
│  │                                                  │   │
│  │  Uso real: 1.5 CPU, 3 GB ✓ (dentro del límite)   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Pod B                                            │   │
│  │  Request: 0.5 CPU, 1 GB                          │   │
│  │  Limit:   1 CPU, 2 GB                            │   │
│  │                                                  │   │
│  │  Uso real: 0.8 CPU, 1.5 GB ✓                     │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  Total Requests:  1.5 CPU, 3 GB   (scheduler check)     │
│  Total Limits:    3 CPU, 6 GB     (puede overcommit)    │
│  Capacidad nodo:  8 CPU, 16 GB                          │
└─────────────────────────────────────────────────────────┘
```

### Diferencias clave

| Aspecto | Request | Limit |
|---------|---------|-------|
| **Propósito** | Reservar recursos mínimos | Restringir uso máximo |
| **Scheduler** | ✅ Usa para decidir nodo | ❌ No considera |
| **Enforcement** | ❌ No enforza límite | ✅ Kubelet enforza |
| **Overcommit** | ❌ No puede exceder capacidad total | ✅ Puede sumar más que capacidad nodo |
| **QoS Class** | ✅ Influye en clasificación | ✅ Influye en clasificación |

---

## Requests vs Limits

### Requests (Peticiones)

**Definición**: Cantidad **mínima garantizada** de recursos que un contenedor necesita.

#### Características:

1. **Scheduler lo usa para placement**: 
   - El scheduler suma todos los requests de Pods ya programados en un nodo
   - Solo programa un nuevo Pod si: `sum(requests) + new_pod_request <= node.allocatable`
   - **No considera el uso real** de recursos en el nodo

2. **No es un límite**:
   - El contenedor puede usar MÁS recursos que su request
   - Solo está garantizado que tendrá AL MENOS esa cantidad disponible

3. **CPU Shares (Linux cgroups)**:
   - Para CPU, el request se traduce a `cpu.shares` en cgroups
   - Si hay contención de CPU, los Pods con mayor request reciben más tiempo de CPU

#### Ejemplo práctico:

```yaml
resources:
  requests:
    cpu: "500m"      # Garantiza 0.5 CPU cores
    memory: "256Mi"  # Garantiza 256 MiB de RAM
```

**Comportamiento**:
- ✅ El scheduler busca un nodo con al menos 500m CPU y 256Mi memoria disponibles
- ✅ Si el nodo tiene recursos libres, el contenedor puede usar 2 CPU y 2 GB si lo necesita
- ✅ En contención de CPU, este contenedor recibe al menos su share proporcional

📄 **Ejemplo completo**: Ver [`ejemplos/04-solo-requests/pod.yaml`](./ejemplos/04-solo-requests/pod.yaml) para un Pod con solo requests definidos

### Limits (Límites)

**Definición**: Cantidad **máxima** de recursos que un contenedor puede usar.

#### Características:

1. **Hard limit enforced por kernel**:
   - **CPU**: Throttling (restricción de acceso)
   - **Memory**: OOM Kill (terminación del proceso)

2. **Diferencia entre CPU y Memory**:

   **CPU Limit (soft enforcement)**:
   ```
   - El kernel usa cgroups para throttling
   - Si el contenedor intenta usar más CPU, simplemente se frena
   - El Pod NO se termina por exceso de CPU
   - Puede causar latencia/lentitud en la aplicación
   ```

   **Memory Limit (hard enforcement)**:
   ```
   - El kernel detecta exceso de memoria
   - Activa el OOM (Out of Memory) killer
   - Termina el proceso que excedió el límite
   - El Pod puede reiniciarse (si restartPolicy lo permite)
   - Reason: "OOMKilled", Exit Code: 137
   ```

3. **Overcommit permitido**:
   - La suma de limits de todos los Pods puede exceder la capacidad del nodo
   - Esto se llama "overcommit" y es normal en Kubernetes
   - Si todos los Pods intentan usar sus límites simultáneamente → eviction

#### Ejemplo práctico:

```yaml
resources:
  limits:
    cpu: "1"         # Máximo 1 CPU core
    memory: "512Mi"  # Máximo 512 MiB de RAM
```

**Comportamiento**:
- ✅ CPU: Si intenta usar más de 1 core → **throttling** (se frena)
- ❌ Memory: Si intenta usar más de 512Mi → **OOMKilled** (se termina)

📄 **Ejemplo completo**: Ver [`ejemplos/05-solo-limits/pod.yaml`](./ejemplos/05-solo-limits/pod.yaml) para un Pod con solo limits definidos

### Combinaciones Request + Limit

📄 **Ejemplo básico completo**: [`ejemplos/01-requests-limits-basico/pod.yaml`](./ejemplos/01-requests-limits-basico/pod.yaml)

#### 1. Solo Request (sin limit)

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  # No limits definidos
```

**Comportamiento**:
- ✅ Garantiza 500m CPU y 256Mi memoria
- ⚠️ Puede usar TODA la CPU/memoria disponible del nodo (peligroso)
- ⚠️ QoS Class: **BestEffort** o **Burstable**

📄 **Ver ejemplo**: [`ejemplos/04-solo-requests/pod.yaml`](./ejemplos/04-solo-requests/pod.yaml)

#### 2. Solo Limit (sin request)

```yaml
resources:
  limits:
    cpu: "1"
    memory: "512Mi"
  # No requests definidos
```

**Comportamiento Kubernetes**:
- 🔄 Kubernetes **copia automáticamente** el limit al request
- Equivale a: `requests.cpu = "1"`, `requests.memory = "512Mi"`
- ⚠️ Puede resultar en over-provisioning (reserva más de lo necesario)

📄 **Ver ejemplo**: [`ejemplos/05-solo-limits/pod.yaml`](./ejemplos/05-solo-limits/pod.yaml)

#### 3. Request = Limit (recomendado para producción crítica)

```yaml
resources:
  requests:
    cpu: "1"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "512Mi"
```

**Comportamiento**:
- ✅ Recursos garantizados y límite conocido
- ✅ QoS Class: **Guaranteed** (máxima prioridad)
- ✅ Última en ser evicted en caso de presión de recursos
- ✅ Ideal para bases de datos, aplicaciones críticas

📄 **Ver ejemplos**:
- QoS Guaranteed: [`ejemplos/07-qos-guaranteed/pod.yaml`](./ejemplos/07-qos-guaranteed/pod.yaml)

#### 4. Request < Limit (común en desarrollo/staging)

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  limits:
    cpu: "2"
    memory: "1Gi"
```

**Comportamiento**:
- ✅ Reserva mínimo (500m, 256Mi) pero puede crecer hasta (2, 1Gi)
- ✅ QoS Class: **Burstable**
- ✅ Flexible para picos de carga
- ⚠️ Puede sufrir throttling/OOMKill si excede límites

📄 **Ver ejemplos**:
- Burstable flexible: [`ejemplos/08-qos-burstable/flexible.yaml`](./ejemplos/08-qos-burstable/flexible.yaml)
- Burstable mixed: [`ejemplos/08-qos-burstable/mixed.yaml`](./ejemplos/08-qos-burstable/mixed.yaml)

### Multi-Container y Init Containers

Para Pods con múltiples contenedores o init containers, los recursos se gestionan de forma especial.

📄 **Ver ejemplos**:
- Multi-container: [`ejemplos/02-multi-container/pod.yaml`](./ejemplos/02-multi-container/pod.yaml)
- Init containers: [`ejemplos/03-init-containers/pod.yaml`](./ejemplos/03-init-containers/pod.yaml)

---

## Tipos de Recursos

Kubernetes soporta varios tipos de recursos que se pueden gestionar:

### 1. Recursos de Computación (Compute Resources)

#### CPU

- **Unidad base**: Kubernetes CPU (equivalente a 1 vCPU/core o 1 hyperthread)
- **Medición**: Unidades absolutas (no relativas)
- **Ejemplos**: `1`, `0.5`, `500m` (500 millicpu)
- **Precisión mínima**: `1m` (0.001 CPU)

#### Memory

- **Unidad base**: Bytes
- **Sufijos soportados**:

| Tipo | Sufijo | Nombre | Valor | Equivalente en bytes |
|------|--------|--------|-------|---------------------|
| **Decimal (Base 10)** | | | | |
| | `k` | kilobyte | 10³ | 1,000 bytes |
| | `M` | megabyte | 10⁶ | 1,000,000 bytes |
| | `G` | gigabyte | 10⁹ | 1,000,000,000 bytes |
| | `T` | terabyte | 10¹² | 1,000,000,000,000 bytes |
| | `P` | petabyte | 10¹⁵ | 1,000,000,000,000,000 bytes |
| | `E` | exabyte | 10¹⁸ | 1,000,000,000,000,000,000 bytes |
| **Binario (Base 2)** | | | | |
| | `Ki` | kibibyte | 2¹⁰ | 1,024 bytes |
| | `Mi` | mebibyte | 2²⁰ | 1,048,576 bytes |
| | `Gi` | gibibyte | 2³⁰ | 1,073,741,824 bytes |
| | `Ti` | tebibyte | 2⁴⁰ | 1,099,511,627,776 bytes |
| | `Pi` | pebibyte | 2⁵⁰ | 1,125,899,906,842,624 bytes |
| | `Ei` | exbibyte | 2⁶⁰ | 1,152,921,504,606,846,976 bytes |

**Diferencia clave**: 
- `1 GB` (decimal) = 1,000,000,000 bytes
- `1 GiB` (binario) = 1,073,741,824 bytes (~7.4% más)

**⚠️ Importante**: Para memoria, siempre usa sufijos binarios (`Mi`, `Gi`) ya que la memoria se maneja en potencias de 2.

- **Ejemplos**: `128974848`, `129M`, `123Mi`, `1Gi`

### 2. Ephemeral Storage (Almacenamiento Efímero)

- **Desde**: Kubernetes 1.8+ (stable desde 1.25)
- **Recurso**: `ephemeral-storage`
- **Incluye**:
  - Volúmenes `emptyDir` (excepto `tmpfs`)
  - Logs de contenedor a nivel de nodo
  - Writable container layers (imágenes de contenedor)

#### Ejemplo:

```yaml
resources:
  requests:
    ephemeral-storage: "2Gi"
  limits:
    ephemeral-storage: "4Gi"
```

**⚠️ Consideraciones**:

1. **tmpfs emptyDir NO cuenta como ephemeral-storage**:
   - Se cuenta como **uso de memoria del contenedor**
   - Afecta al límite de memoria, no de storage

2. **Enforcement**:
   - Si excede el límite → **Pod eviction**
   - Kubelet monitorea con escaneo periódico o project quotas (XFS)

3. **Configuración del nodo**:
   - Single filesystem: Todo en un filesystem (típico `/var/lib/kubelet`)
   - Two filesystems: Separar kubelet data y container runtime

### 3. Huge Pages (Páginas Grandes)

- **Linux-specific feature**
- **Recurso**: `hugepages-<size>` (ej: `hugepages-2Mi`, `hugepages-1Gi`)
- **Uso**: Optimización de rendimiento para aplicaciones que usan mucha memoria
- **⚠️ No se puede overcommit** (diferencia con CPU/memory)

#### Ejemplo:

```yaml
resources:
  requests:
    hugepages-2Mi: "80Mi"  # 40 páginas de 2Mi cada una
  limits:
    hugepages-2Mi: "80Mi"
```

### 4. Extended Resources (Recursos Extendidos)

Recursos personalizados fuera del dominio `kubernetes.io`:

#### Tipos:

1. **Node-level** (gestionados por device plugins):
   - GPUs: `nvidia.com/gpu`, `amd.com/gpu`
   - FPGAs: `vendor.com/fpga`
   - High-performance NICs: `vendor.com/nic`

2. **Cluster-level** (gestionados por scheduler extenders):
   - Licencias de software
   - Recursos compartidos

#### Ejemplo GPU:

```yaml
resources:
  limits:
    nvidia.com/gpu: 2  # Solicita 2 GPUs NVIDIA
```

**⚠️ Características**:
- ✅ Deben ser **cantidades enteras** (no fraccionarias)
- ✅ **No se puede overcommit**
- ✅ Request y Limit deben ser **iguales**

---

## Unidades de Recursos

### CPU

#### Representación

- **1 Kubernetes CPU** = 1 vCPU/core físico o 1 vCore (VM)
- **Fraccionario**: Se permiten fracciones con precisión hasta `1m` (milliCPU)

#### Formatos equivalentes:

```yaml
cpu: "1"      # 1 CPU completo
cpu: "0.5"    # Mitad de un CPU
cpu: "500m"   # 500 millicpu = 0.5 CPU
cpu: "100m"   # 100 millicpu = 0.1 CPU
```

#### ⚠️ Valores inválidos:

```yaml
cpu: "0.5m"   # ❌ Inválido (< 1m)
cpu: "0.0005" # ❌ Inválido (= 0.5m)
cpu: "1500m"  # ✅ Válido (= 1.5 CPU)
```

#### 💡 Best Practice:

**Usa millicpu (`m`) para valores < 1 CPU**:
- ✅ `100m` es más legible que `0.1`
- ✅ Evita errores con decimales inválidos

### Memory

#### Sufijos soportados

| Sufijo | Tipo | Potencia | Nombre | Ejemplo | Bytes Reales |
|--------|------|----------|--------|---------|--------------|
| **Decimal (Base 10)** | | | | | |
| `k` | Decimal | 10³ | kilobyte | `1000k` | 1,000,000 |
| `M` | Decimal | 10⁶ | megabyte | `500M` | 500,000,000 |
| `G` | Decimal | 10⁹ | gigabyte | `2G` | 2,000,000,000 |
| `T` | Decimal | 10¹² | terabyte | `1T` | 1,000,000,000,000 |
| **Binario (Base 2)** | | | | | |
| `Ki` | Binario | 2¹⁰ | kibibyte | `1000Ki` | 1,024,000 |
| `Mi` | Binario | 2²⁰ | mebibyte | `500Mi` | 524,288,000 |
| `Gi` | Binario | 2³⁰ | gibibyte | `2Gi` | 2,147,483,648 |
| `Ti` | Binario | 2⁴⁰ | tebibyte | `1Ti` | 1,099,511,627,776 |

**Comparación práctica**:
```
1 MB  = 1,000,000 bytes        (decimal)
1 MiB = 1,048,576 bytes        (binario, +4.8% más)

1 GB  = 1,000,000,000 bytes    (decimal)
1 GiB = 1,073,741,824 bytes    (binario, +7.4% más)
```

#### Valores equivalentes:

```yaml
memory: "128974848"    # Bytes exactos
memory: "129e6"        # Notación científica
memory: "129M"         # 129 megabytes (decimal)
memory: "123Mi"        # 123 mebibytes (binario)
```

#### ⚠️ Cuidado con los sufijos:

```yaml
# ❌ COMÚN ERROR: confundir "m" (milli) con "M" (mega)
memory: "400m"   # ❌ 0.4 bytes (casi nada!)
memory: "400M"   # ✅ 400 megabytes
memory: "400Mi"  # ✅ 400 mebibytes (recomendado)
```

#### 💡 Best Practice:

**Usa sufijos binarios (`Mi`, `Gi`) para memoria**:
- ✅ Más preciso (memoria se asigna en potencias de 2)
- ✅ Evita confusión con millibytes (`m`)

### Ephemeral Storage

Usa las mismas unidades que memoria:

```yaml
ephemeral-storage: "2Gi"   # 2 gibibytes
ephemeral-storage: "500Mi" # 500 mebibytes
```

---

## Quality of Service (QoS) Classes

Kubernetes asigna automáticamente una **QoS Class** a cada Pod basándose en sus recursos configurados. Esta clase determina la **prioridad de eviction** cuando el nodo está bajo presión de recursos.

### Clasificación Automática

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESIÓN DE RECURSOS                      │
│                                                             │
│  Orden de Eviction (primero → último)                       │
│                                                             │
│  1. BestEffort  ◄─── Sin requests/limits                    │
│     └─ Se eliminan PRIMERO                                  │
│                                                             │
│  2. Burstable   ◄─── Request < Limit                        │
│     └─ Se eliminan según uso vs request                     │
│                                                             │
│  3. Guaranteed  ◄─── Request = Limit (todos los recursos)   │
│     └─ Se eliminan ÚLTIMO (máxima protección)               │
└─────────────────────────────────────────────────────────────┘
```

### 1. Guaranteed (Garantizado)

**Condiciones** (TODAS deben cumplirse):

1. ✅ **Todos** los contenedores tienen `requests` Y `limits` para CPU y Memory
2. ✅ Para **cada** contenedor: `requests.cpu == limits.cpu`
3. ✅ Para **cada** contenedor: `requests.memory == limits.memory`

#### Ejemplo Guaranteed:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-guaranteed
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "500m"
        memory: "256Mi"
      limits:
        cpu: "500m"      # ✅ Igual a request
        memory: "256Mi"  # ✅ Igual a request
```

**Características**:
- 🛡️ **Máxima protección**: Última clase en ser evicted
- 🎯 **Recursos predecibles**: Sabe exactamente cuánto puede usar
- 💰 **Costo**: Puede resultar en over-provisioning
- 🎯 **Uso**: Bases de datos, aplicaciones críticas, stateful sets

📄 **Ver ejemplo completo**: [`ejemplos/07-qos-guaranteed/pod.yaml`](./ejemplos/07-qos-guaranteed/pod.yaml)

### 2. Burstable (Flexible)

**Condiciones**:

1. ✅ No califica para Guaranteed
2. ✅ **Al menos UN** contenedor tiene request o limit para CPU o Memory

#### Ejemplo Burstable (request < limit):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-burstable
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "250m"
        memory: "128Mi"
      limits:
        cpu: "1"        # ✅ Mayor que request
        memory: "512Mi" # ✅ Mayor que request
```

#### Ejemplo Burstable (solo request):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-burstable-request-only
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "250m"
        memory: "128Mi"
      # Sin limits → puede usar todos los recursos disponibles
```

**Características**:
- ⚖️ **Prioridad media**: Se evicted después de BestEffort, antes de Guaranteed
- 📈 **Flexible**: Puede usar más recursos si están disponibles
- ⚠️ **Riesgo**: Puede sufrir throttling o OOMKill
- 🎯 **Uso**: Aplicaciones web, servicios stateless, desarrollo/staging

**Orden de eviction dentro de Burstable**:
- Pods que exceden más su request se evicted primero
- Cálculo: `(current_usage - request) / request`

📄 **Ver ejemplos completos**:
- Flexible (request < limit): [`ejemplos/08-qos-burstable/flexible.yaml`](./ejemplos/08-qos-burstable/flexible.yaml)
- Solo requests: [`ejemplos/08-qos-burstable/request-only.yaml`](./ejemplos/08-qos-burstable/request-only.yaml)
- Configuración mixta: [`ejemplos/08-qos-burstable/mixed.yaml`](./ejemplos/08-qos-burstable/mixed.yaml)

### 3. BestEffort (Mejor Esfuerzo)

**Condiciones**:

1. ❌ **NINGÚN** contenedor tiene requests o limits para CPU o Memory

#### Ejemplo BestEffort:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-besteffort
spec:
  containers:
  - name: app
    image: nginx
    # ❌ Sin resources definidos
```

**Características**:
- ⚠️ **Primera en ser evicted**: Menor prioridad
- 🎲 **Sin garantías**: Puede usar recursos disponibles, pero sin protección
- 💸 **Bajo costo**: No reserva recursos
- 🎯 **Uso**: Batch jobs no críticos, tareas de limpieza, desarrollo/testing

📄 **Ver ejemplos completos**:
- Pod BestEffort: [`ejemplos/09-qos-besteffort/pod.yaml`](./ejemplos/09-qos-besteffort/pod.yaml)
- Deployment BestEffort: [`ejemplos/09-qos-besteffort/deployment.yaml`](./ejemplos/09-qos-besteffort/deployment.yaml)

### Tabla Comparativa QoS

| QoS Class | Request | Limit | Eviction Priority | Uso Típico |
|-----------|---------|-------|-------------------|------------|
| **Guaranteed** | ✅ CPU + Memory | ✅ = Request | 🛡️ 3 (última) | Prod crítica, DBs |
| **Burstable** | ✅ Al menos 1 recurso | ⚖️ Opcional o > Request | ⚠️ 2 (media) | Web apps, APIs |
| **BestEffort** | ❌ Ninguno | ❌ Ninguno | 🔥 1 (primera) | Batch jobs, testing |

### Verificar QoS Class de un Pod

```bash
# Ver QoS class asignada
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}'

# Ejemplo completo con detalles
kubectl describe pod <pod-name> | grep QoS
```

### Ejemplo de Eviction por QoS

Supongamos un nodo con 4 GB de memoria que se queda sin memoria:

```yaml
# Pod A - Guaranteed (usando 1 GB, limit 1 GB)
qosClass: Guaranteed

# Pod B - Burstable (usando 1.5 GB, request 500 MB, limit 2 GB)
qosClass: Burstable

# Pod C - BestEffort (usando 500 MB, sin limits)
qosClass: BestEffort
```

**Orden de eviction**:
1. ❌ **Pod C** (BestEffort) → evicted primero
2. Si aún hay presión → ❌ **Pod B** (Burstable, excede request)
3. Solo en extremo → ❌ **Pod A** (Guaranteed)

---

## Configuración de Recursos

### Sintaxis Básica

#### Para contenedores individuales:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "250m"          # Mínimo garantizado
        memory: "128Mi"
        ephemeral-storage: "1Gi"
      limits:
        cpu: "500m"          # Máximo permitido
        memory: "256Mi"
        ephemeral-storage: "2Gi"
```

### Pod con Múltiples Contenedores

Los requests/limits del **Pod** son la **suma** de todos sus contenedores:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "250m"
        memory: "64Mi"
      limits:
        cpu: "500m"
        memory: "128Mi"
  
  - name: sidecar
    image: log-forwarder
    resources:
      requests:
        cpu: "250m"
        memory: "64Mi"
      limits:
        cpu: "500m"
        memory: "128Mi"

# Recursos totales del Pod:
# requests: cpu=500m, memory=128Mi
# limits:   cpu=1, memory=256Mi
```

### Init Containers

Los init containers **NO se suman** a los recursos del Pod. Se usa el **máximo**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-container-demo
spec:
  initContainers:
  - name: init-setup
    image: busybox
    resources:
      requests:
        cpu: "1"         # ← Init necesita 1 CPU
        memory: "512Mi"
      limits:
        cpu: "1"
        memory: "512Mi"
  
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "250m"      # ← App necesita 250m CPU
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"

# Recursos efectivos del Pod:
# requests: cpu=1 (máximo entre init y app), memory=512Mi
# limits:   cpu=1, memory=512Mi
```

**Regla de cálculo**:
```
Pod Request = MAX(
  MAX(init_container_requests),
  SUM(container_requests)
)
```

### Recursos por Namespace (con LimitRange)

Puedes establecer valores por defecto con `LimitRange`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-resources
  namespace: development
spec:
  limits:
  - default:  # Limits por defecto si no se especifican
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:  # Requests por defecto si no se especifican
      cpu: "250m"
      memory: "128Mi"
    max:  # Máximo permitido
      cpu: "2"
      memory: "2Gi"
    min:  # Mínimo requerido
      cpu: "100m"
      memory: "64Mi"
    type: Container
```

**Ver referencia completa**: [Módulo 10 - Namespaces y Organización (Sección LimitRange)](../modulo-10-namespaces-organizacion/#limitrange)

---

## Pod-level Resources (Beta K8s 1.34)

### Introducción

**Desde Kubernetes 1.34** (beta), puedes especificar recursos **a nivel de Pod** en lugar de solo por contenedor.

**⚠️ Requisito**: Feature gate `PodLevelResources` habilitado (default: true en 1.34+)

### ¿Por qué Pod-level resources?

**Problema actual**: Difícil calcular recursos exactos cuando tienes muchos contenedores

**Ejemplo**:
```yaml
# ❌ Difícil: Asignar recursos a 5 sidecars
containers:
- name: app
- name: sidecar1
- name: sidecar2
- name: sidecar3
- name: sidecar4
- name: sidecar5
# ¿Cuánto CPU dar a cada uno? Difícil predecir
```

**Solución**: Especificar presupuesto total del Pod

```yaml
# ✅ Fácil: Presupuesto total del Pod
spec:
  resources:
    limits:
      cpu: "2"
      memory: "2Gi"
  # Los contenedores comparten estos recursos
```

### Sintaxis Pod-level

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-level-demo
spec:
  resources:  # ← A nivel de Pod
    requests:
      cpu: "1"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "2Gi"
  
  containers:
  - name: app
    image: nginx
    resources:  # ← Opcional: límite individual
      limits:
        cpu: "1"
        memory: "1Gi"
  
  - name: sidecar
    image: logger
    # Sin resources → comparte del presupuesto del Pod
```

### Reglas de Combinación

#### 1. Solo Pod-level resources:

```yaml
spec:
  resources:
    limits:
      cpu: "2"
      memory: "2Gi"
  containers:
  - name: app
    # Sin resources
  - name: sidecar
    # Sin resources
# Los contenedores comparten 2 CPU y 2 Gi entre ellos
```

#### 2. Pod-level + Container-level:

```yaml
spec:
  resources:
    limits:
      cpu: "2"       # ← Presupuesto total
      memory: "2Gi"
  containers:
  - name: app
    resources:
      limits:
        cpu: "1"     # ← Límite individual (dentro del presupuesto)
        memory: "1Gi"
  - name: sidecar
    # Sin limits → puede usar hasta (2-1)=1 CPU restante
```

**⚠️ Validación**:
```
SUM(container.limits) <= pod.limits
```

Si la suma de límites de contenedores excede el límite del Pod → ❌ Error de validación

### Ventajas

✅ **Simplifica configuración** con muchos contenedores  
✅ **Resource sharing** entre contenedores del mismo Pod  
✅ **Reduce over-provisioning** (no necesitas calcular límites exactos por contenedor)  
✅ **Mejor utilización** de recursos idle entre contenedores  

### Limitaciones

⚠️ **Solo CPU y Memory** (no ephemeral-storage, extended resources)  
⚠️ **Beta feature** (puede cambiar en futuras versiones)  
⚠️ Requiere K8s 1.34+ con feature gate habilitado

📄 **Ver ejemplos completos**:
- Pod-level básico: [`ejemplos/11-pod-level-resources/01-pod-level-basico.yaml`](./ejemplos/11-pod-level-resources/01-pod-level-basico.yaml)
- Pod-level híbrido: [`ejemplos/11-pod-level-resources/02-pod-level-hibrido.yaml`](./ejemplos/11-pod-level-resources/02-pod-level-hibrido.yaml)
- Deployment multi-sidecar: [`ejemplos/11-pod-level-resources/03-deployment-multi-sidecar.yaml`](./ejemplos/11-pod-level-resources/03-deployment-multi-sidecar.yaml)

---

## Ephemeral Storage

### ¿Qué es Ephemeral Storage?

Almacenamiento **local temporal** en el nodo, sin garantía de durabilidad a largo plazo.

**Incluye**:
1. Volúmenes `emptyDir` (excepto tmpfs)
2. Logs de contenedor a nivel de nodo (`/var/log`)
3. Writable container layers (imágenes de contenedor)

📄 **Ejemplo básico**: [`ejemplos/06-ephemeral-storage-basico/pod.yaml`](./ejemplos/06-ephemeral-storage-basico/pod.yaml)

### Configuración

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ephemeral-demo
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        ephemeral-storage: "2Gi"
      limits:
        ephemeral-storage: "4Gi"
    volumeMounts:
    - name: cache
      mountPath: /cache
  
  volumes:
  - name: cache
    emptyDir:
      sizeLimit: "1Gi"  # Límite del volumen específico
```

### Enforcement

**Kubelet monitorea** el uso de ephemeral storage:

1. **Periodic scanning** (por defecto):
   - Escaneo programado de directorios
   - Mide uso de espacio en disco
   
2. **Filesystem project quotas** (XFS):
   - Más eficiente
   - Enforcement en tiempo real

**Si se excede el límite** → Pod eviction

### ⚠️ Consideraciones Críticas

#### 1. tmpfs emptyDir NO es ephemeral-storage

```yaml
volumes:
- name: tmp
  emptyDir:
    medium: Memory  # ← Esto es tmpfs (en RAM)
```

**Comportamiento**:
- ❌ NO cuenta como `ephemeral-storage`
- ✅ Cuenta como **uso de memoria** del contenedor
- Afecta el límite de `memory`, no de `ephemeral-storage`

#### 2. emptyDir sin sizeLimit puede consumir todo el límite del Pod

```yaml
volumes:
- name: data
  emptyDir: {}  # ⚠️ Sin sizeLimit
```

**Riesgo**:
- Puede consumir hasta el `limits.memory` del Pod
- Puede causar OOM si se llena
- Puede causar denial of service en el nodo

**💡 Best Practice**: Siempre especificar `sizeLimit`:

```yaml
volumes:
- name: data
  emptyDir:
    sizeLimit: "500Mi"  # ✅ Límite explícito
```

📄 **Ver ejemplos completos de Ephemeral Storage**:
- EmptyDir con sizeLimit: [`ejemplos/10-ephemeral-storage/01-emptydir-con-sizelimit.yaml`](./ejemplos/10-ephemeral-storage/01-emptydir-con-sizelimit.yaml)
- EmptyDir sin sizeLimit (peligroso): [`ejemplos/10-ephemeral-storage/02-emptydir-sin-sizelimit-peligroso.yaml`](./ejemplos/10-ephemeral-storage/02-emptydir-sin-sizelimit-peligroso.yaml)
- Tmpfs (memory-backed): [`ejemplos/10-ephemeral-storage/03-tmpfs-memory-backed.yaml`](./ejemplos/10-ephemeral-storage/03-tmpfs-memory-backed.yaml)
- Múltiples emptyDir: [`ejemplos/10-ephemeral-storage/04-multiples-emptydir.yaml`](./ejemplos/10-ephemeral-storage/04-multiples-emptydir.yaml)
- Monitoreo de uso: [`ejemplos/10-ephemeral-storage/05-monitoreo.yaml`](./ejemplos/10-ephemeral-storage/05-monitoreo.yaml)
- Demo de eviction: [`ejemplos/10-ephemeral-storage/06-eviction-demo.yaml`](./ejemplos/10-ephemeral-storage/06-eviction-demo.yaml)
- Deployment best practices: [`ejemplos/10-ephemeral-storage/07-deployment-best-practices.yaml`](./ejemplos/10-ephemeral-storage/07-deployment-best-practices.yaml)

#### 3. Múltiples emptyDir pueden agotar memoria

```yaml
volumes:
- name: cache
  emptyDir: {}
- name: temp
  emptyDir: {}
- name: logs
  emptyDir: {}
# ⚠️ Cada uno puede consumir hasta limits.memory
```

**Solución**: ResourceQuota + LimitRange en namespace

### Monitoreo

```bash
# Ver uso de ephemeral storage por Pod
kubectl describe node <node-name> | grep -A 10 "Allocated resources"

# Ver eventos de eviction por storage
kubectl get events --all-namespaces | grep -i evict
```

---

## Extended Resources

### Definición

Recursos **fuera del dominio `kubernetes.io`** gestionados por:
1. Device plugins (node-level)
2. Scheduler extenders (cluster-level)
3. Dynamic Resource Allocation - DRA (K8s 1.26+)

### Tipos Comunes

#### 1. GPUs

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  containers:
  - name: cuda-app
    image: nvidia/cuda:latest
    resources:
      limits:
        nvidia.com/gpu: 2  # Solicita 2 GPUs
```

#### 2. FPGAs

```yaml
resources:
  limits:
    xilinx.com/fpga: 1
```

#### 3. Custom Hardware

```yaml
resources:
  limits:
    example.com/nic: 1  # Network Interface Card específica
```

### Características

⚠️ **Restricciones**:
1. ✅ Solo **cantidades enteras** (no `0.5`, `1.5m`)
2. ✅ Request == Limit (deben ser iguales si ambos existen)
3. ✅ **No se puede overcommit**

📄 **Ver ejemplos completos de Extended Resources**:
- NVIDIA GPU: [`ejemplos/12-extended-resources/01-nvidia-gpu.yaml`](./ejemplos/12-extended-resources/01-nvidia-gpu.yaml)
- AMD GPU: [`ejemplos/12-extended-resources/02-amd-gpu.yaml`](./ejemplos/12-extended-resources/02-amd-gpu.yaml)
- Custom resources: [`ejemplos/12-extended-resources/03-custom-resources.yaml`](./ejemplos/12-extended-resources/03-custom-resources.yaml)

### Anunciar Extended Resources (node-level)

```bash
# Ejemplo: Añadir 5 recursos "example.com/foo" a un nodo
curl --header "Content-Type: application/json-patch+json" \
  --request PATCH \
  --data '[{"op": "add", "path": "/status/capacity/example.com~1foo", "value": "5"}]' \
  http://k8s-master:8080/api/v1/nodes/node-1/status
```

**Nota**: `~1` es la codificación del carácter `/` en JSON-Patch

### Device Plugins

Los device plugins **anuncian automáticamente** recursos:

**Ejemplos**:
- [NVIDIA GPU Device Plugin](https://github.com/NVIDIA/k8s-device-plugin)
- [Intel Device Plugins](https://github.com/intel/intel-device-plugins-for-kubernetes)
- [AMD GPU Device Plugin](https://github.com/RadeonOpenCompute/k8s-device-plugin)

**Instalación típica** (NVIDIA GPU):

```bash
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/main/nvidia-device-plugin.yml
```

---

## Comportamiento del Scheduler

### Proceso de Scheduling

```
┌──────────────────────────────────────────────────────────────┐
│ 1. Pod creado con requests                                   │
│    requests: cpu=500m, memory=1Gi                            │
└─────────────────┬────────────────────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. Scheduler evalúa CADA nodo                                │
│    ┌──────────────────────────────────────────────────────┐  │
│    │ Nodo A                                               │  │
│    │  Capacity:    cpu=4, memory=8Gi                      │  │
│    │  Allocatable: cpu=3.8, memory=7.5Gi (después daemons)│  │
│    │  Allocated:   cpu=2.5, memory=5Gi (Pods existentes)  │  │
│    │  Available:   cpu=1.3, memory=2.5Gi                  │  │
│    │                                                      │  │
│    │  Check: 500m <= 1.3 ✅ AND 1Gi <= 2.5Gi ✅           │  │
│    │  → Nodo A es CANDIDATO                               │  │
│    └──────────────────────────────────────────────────────┘  │
│                                                              │
│    ┌──────────────────────────────────────────────────────┐  │
│    │ Nodo B                                               │  │
│    │  Available: cpu=300m, memory=3Gi                     │  │
│    │  Check: 500m <= 300m ❌                              │  │
│    │  → Nodo B RECHAZADO                                  │  │
│    └──────────────────────────────────────────────────────┘  │
└─────────────────┬────────────────────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. De los candidatos, aplica scoring                         │
│    (NodeResourcesBalancedAllocation, etc.)                   │
└─────────────────┬────────────────────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. Selecciona nodo con mejor score                           │
│    Pod scheduled en Nodo A                                   │
└──────────────────────────────────────────────────────────────┘
```

### Puntos Clave

1. **Solo usa requests** (NO limits):
   ```
   sum(pod.requests) <= node.allocatable
   ```

2. **No considera uso real**:
   - Un nodo puede tener 90% de CPU idle
   - Pero si los requests suman 100% → NO programa más Pods

3. **Node.Allocatable < Node.Capacity**:
   - Daemons del sistema reservan recursos
   - `kubelet`, `kube-proxy`, `system daemons`

### Ver Capacidad y Allocatable

```bash
# Ver recursos del nodo
kubectl describe node <node-name>

# Salida ejemplo:
# Capacity:
#   cpu:                4
#   memory:             8Gi
# Allocatable:
#   cpu:                3800m
#   memory:             7500Mi
# 
# Non-terminated Pods:
#   Namespace  Name        CPU Requests  Memory Requests
#   ---------  ----        ------------  ---------------
#   default    pod-a       500m (13%)    1Gi (13%)
#   default    pod-b       250m (6%)     512Mi (6%)
# 
# Allocated resources:
#   CPU Requests: 750m (19%)
#   Memory Requests: 1536Mi (20%)
```

### Fallo de Scheduling

Si no encuentra nodo → Pod queda en **Pending**:

```bash
kubectl describe pod <pod-name>

# Events:
# Type     Reason            Message
# ----     ------            -------
# Warning  FailedScheduling  0/3 nodes available: insufficient cpu
```

---

## Enforcement de Límites

### CPU Throttling

#### Mecanismo (Linux cgroups)

**CPU limits se enforzan con throttling** (restricción de tiempo de CPU):

```
┌────────────────────────────────────────────────────────────┐
│ Período de CPU: 100ms (cfs_period_us=100000)               │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ Contenedor con limit cpu=1 → quota=100ms por período       │
│                                                            │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ 0ms                     50ms                 100ms   │   │
│ │  ├────────────── RUNNING ────────────┤               │   │
│ │                                      └─ Usa 50ms     │   │
│ │                                                      │   │
│ │  ✅ OK: Solo usó 50ms de 100ms permitidos            │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                            │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ 0ms                                            100ms │   │
│ │  ├────────────── RUNNING ──────────────────────┤     │   │
│ │                                                │     │   │
│ │  ⚠️ THROTTLED: Usó 100ms completos             │     │   │
│ │  Siguiente período: debe esperar hasta obtener cuota │   │
│ └──────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

#### Consecuencias del Throttling

```yaml
resources:
  limits:
    cpu: "500m"  # 0.5 CPU
```

**Si el contenedor intenta usar más**:
- ⚠️ **Kernel throttles** el proceso
- ⏱️ **Latencia aumenta** (requests tardan más)
- 🔥 **CPU usage = 100%** del límite (stuck)
- ❌ **NO se termina** el contenedor

**Síntomas**:
- Aplicación lenta
- Timeouts en requests HTTP
- `kubectl top pod` muestra CPU en el límite

#### Detectar Throttling

```bash
# Ver métricas de throttling (requiere cAdvisor/metrics-server)
kubectl exec -it <pod-name> -- cat /sys/fs/cgroup/cpu/cpu.stat

# Salida:
# nr_periods 1000        # Número de períodos
# nr_throttled 500       # Cuántos fueron throttled
# throttled_time 25000   # Tiempo total throttled (nanosegundos)
```

**💡 Si `nr_throttled` es alto** → Aumenta el CPU limit

### Memory OOMKilled

#### Mecanismo (Linux OOM Killer)

**Memory limits se enforzan con terminación del proceso**:

```
┌──────────────────────────────────────────────────────────┐
│ Contenedor con limit memory=512Mi                        │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ Uso de memoria crece gradualmente:                       │
│                                                          │
│  256Mi  ✅ OK                                            │
│  384Mi  ✅ OK                                            │
│  512Mi  ⚠️ En el límite                                  │
│  513Mi  ❌ EXCEDE LÍMITE                                 │
│         │                                                │
│         └──► Kernel detecta exceso de memoria            │
│              │                                           │
│              └──► OOM Killer selecciona proceso          │
│                   │                                      │
│                   └──► SIGKILL al proceso                │
│                        (típicamente PID 1)               │
│                        │                                 │
│                        └──► Exit Code: 137               │
│                             Reason: OOMKilled            │
└──────────────────────────────────────────────────────────┘
```

#### Consecuencias del OOMKilled

```yaml
resources:
  limits:
    memory: "512Mi"
```

**Si el contenedor excede el límite**:
- ❌ **Kernel termina** el proceso (SIGKILL)
- 🔄 **Pod puede reiniciarse** (si `restartPolicy: Always`)
- 📊 **Restart Count** aumenta
- ⚠️ **CrashLoopBackOff** si ocurre repetidamente

#### Detectar OOMKilled

```bash
# Ver eventos del Pod
kubectl describe pod <pod-name>

# Buscar en eventos:
# Last State:     Terminated
#   Reason:       OOMKilled
#   Exit Code:    137

# Ver restart count
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].restartCount}'

# Ver último estado
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState}'
```

#### Prevenir OOMKilled

1. **Aumentar memory limit** (si la app necesita más):
   ```yaml
   limits:
     memory: "1Gi"  # ← Aumentado
   ```

2. **Investigar memory leaks**:
   ```bash
   # Heap dump (Java)
   kubectl exec -it <pod> -- jmap -dump:file=/tmp/heap.bin 1
   
   # Ver uso detallado
   kubectl top pod <pod-name> --containers
   ```

3. **Usar memory profiling**:
   - Java: JVM heap analysis
   - Python: `memory_profiler`
   - Go: `pprof`

### Ephemeral Storage Eviction

```yaml
resources:
  limits:
    ephemeral-storage: "2Gi"
```

**Si excede el límite**:
- ❌ **Pod eviction** (no OOMKill)
- 📝 Reason: `Evicted`
- 🚫 **No se reinicia automáticamente**
- ⚠️ Debes recrear el Pod

```bash
# Ver Pods evicted
kubectl get pods --field-selector=status.phase=Failed

# Ver razón
kubectl describe pod <evicted-pod>
# Reason: Evicted
# Message: Pod ephemeral local storage usage exceeds the total limit of containers 2Gi
```

---

## Monitoreo de Recursos

### Metrics Server

**Instalación** (si no está instalado):

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### kubectl top

#### Ver uso de Pods

```bash
# Todos los Pods del namespace
kubectl top pods

# Salida:
# NAME                CPU(cores)   MEMORY(bytes)
# nginx-deployment    10m          50Mi
# redis-pod           5m           100Mi

# Pod específico con contenedores
kubectl top pod <pod-name> --containers

# Todos los namespaces
kubectl top pods --all-namespaces

# Ordenar por CPU
kubectl top pods --sort-by=cpu

# Ordenar por memoria
kubectl top pods --sort-by=memory
```

#### Ver uso de Nodos

```bash
# Todos los nodos
kubectl top nodes

# Salida:
# NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# node-1     500m         25%    2Gi             40%
# node-2     800m         40%    3Gi             60%
```

### Ver Recursos Asignados vs Disponibles

```bash
# Recursos asignados en un nodo
kubectl describe node <node-name>

# Extracto relevante:
# Allocated resources:
#   (Total limits may be over 100%, i.e., overcommitted)
#   Resource           Requests      Limits
#   --------           --------      ------
#   cpu                1500m (37%)   3000m (75%)
#   memory             3Gi (40%)     6Gi (80%)
#   ephemeral-storage  0 (0%)        0 (0%)
```

### Alertas y Monitoreo Avanzado

#### Prometheus + Grafana

**Métricas clave**:

```yaml
# CPU throttling
rate(container_cpu_cfs_throttled_seconds_total[5m])

# Memory usage vs limit
container_memory_usage_bytes / container_spec_memory_limit_bytes

# OOMKilled count
rate(container_oom_events_total[5m])

# Pods en estado Pending
kube_pod_status_phase{phase="Pending"}
```

#### Configurar alertas

```yaml
# Ejemplo alerta Prometheus
groups:
- name: resources
  rules:
  - alert: HighMemoryUsage
    expr: |
      container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
    for: 5m
    annotations:
      summary: "Container {{ $labels.container }} using >90% memory"
  
  - alert: CPUThrottling
    expr: |
      rate(container_cpu_cfs_throttled_seconds_total[5m]) > 0.1
    for: 10m
    annotations:
      summary: "Container {{ $labels.container }} is being throttled"
```

---

## Best Practices

### 1. Siempre Especifica Requests y Limits

❌ **Evitar**:
```yaml
# Sin resources - QoS: BestEffort
containers:
- name: app
  image: nginx
```

✅ **Recomendado**:
```yaml
# Con resources - QoS: Burstable o Guaranteed
containers:
- name: app
  image: nginx
  resources:
    requests:
      cpu: "250m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"
```

### 2. Request = Limit para Producción Crítica

✅ **Aplicaciones stateful, bases de datos**:
```yaml
# QoS: Guaranteed
resources:
  requests:
    cpu: "2"
    memory: "4Gi"
  limits:
    cpu: "2"
    memory: "4Gi"
```

**Ventajas**:
- 🛡️ Máxima protección contra eviction
- 📊 Uso predecible de recursos
- 🎯 No sufre throttling inesperado

### 3. Request < Limit para Aplicaciones Bursty

✅ **APIs, web apps con picos de tráfico**:
```yaml
# QoS: Burstable
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  limits:
    cpu: "2"
    memory: "1Gi"
```

**Ventajas**:
- 📈 Puede manejar picos de carga
- 💰 Usa menos recursos en estado idle
- ⚖️ Balance entre costo y flexibilidad

### 4. Calcula Requests Basándote en Uso Real

**Proceso recomendado**:

1. **Empezar conservador**:
   ```yaml
   requests:
     cpu: "100m"
     memory: "128Mi"
   ```

2. **Monitorear en staging/desarrollo**:
   ```bash
   kubectl top pods --containers
   ```

3. **Ajustar basándote en percentil 95**:
   ```yaml
   # Si p95 de uso es: cpu=250m, memory=200Mi
   requests:
     cpu: "300m"      # +20% margen
     memory: "250Mi"
   ```

4. **Limits = 2x Requests** (regla general):
   ```yaml
   limits:
     cpu: "600m"
     memory: "500Mi"
   ```

### 5. Usa LimitRange para Defaults

✅ **Establecer defaults en namespace**:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "250m"
      memory: "128Mi"
    type: Container
```

**Beneficio**: Pods sin resources definidos obtienen valores seguros automáticamente

### 6. Usa ResourceQuota para Limitar Namespace

✅ **Prevenir que un namespace consuma todo el clúster**:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
```

**Ver referencia**: [Módulo 10 - Namespaces y Organización (Sección ResourceQuota)](../modulo-10-namespaces-organizacion/#resourcequota)

### 7. Monitorea Throttling y OOMKilled

```bash
# Script para detectar problemas de recursos

# Pods con restart count alto (posible OOMKilled)
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.status.containerStatuses[].restartCount > 5) | 
  "\(.metadata.namespace)/\(.metadata.name): \(.status.containerStatuses[].restartCount) restarts"'

# Pods OOMKilled recientemente
kubectl get events --all-namespaces --field-selector reason=OOMKilled

# Pods en CrashLoopBackOff
kubectl get pods --all-namespaces --field-selector status.phase=Failed
```

### 8. Ephemeral Storage: Siempre Define sizeLimit

❌ **Evitar**:
```yaml
volumes:
- name: cache
  emptyDir: {}  # Puede llenar el disco del nodo
```

✅ **Recomendado**:
```yaml
volumes:
- name: cache
  emptyDir:
    sizeLimit: "1Gi"
```

### 9. Considera Vertical Pod Autoscaler (VPA)

**VPA ajusta automáticamente** requests/limits basándose en uso histórico:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: nginx-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: nginx
  updatePolicy:
    updateMode: "Auto"  # Actualiza automáticamente
```

**Ventajas**:
- 🤖 Optimización automática
- 📊 Basado en datos reales
- 💰 Reduce costos eliminando over-provisioning

**Limitación**: No compatible con HPA (Horizontal Pod Autoscaler) en la misma métrica

### 10. Testing de Límites

✅ **Probar comportamiento bajo presión**:

```bash
# Simular carga de CPU
kubectl run stress-cpu --image=polinux/stress --restart=Never -- stress --cpu 2 --timeout 60s

# Simular carga de memoria
kubectl run stress-mem --image=polinux/stress --restart=Never -- stress --vm 1 --vm-bytes 512M --timeout 60s

# Ver comportamiento
kubectl top pod stress-cpu
kubectl top pod stress-mem
```

---

## Troubleshooting

### Problema 1: Pod Pending - FailedScheduling

#### Síntoma

```bash
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# my-pod  0/1     Pending   0          5m
```

#### Diagnóstico

```bash
kubectl describe pod my-pod

# Events:
# Type     Reason            Message
# ----     ------            -------
# Warning  FailedScheduling  0/3 nodes available: insufficient cpu
```

#### Causas Comunes

1. **Requests demasiado altos**:
   ```yaml
   requests:
     cpu: "10"  # ← Si ningún nodo tiene 10 CPUs disponibles
   ```

2. **Nodos saturados**:
   ```bash
   kubectl describe nodes
   # Allocated resources: cpu 95%, memory 90%
   ```

3. **Taints en nodos**:
   ```bash
   kubectl describe node <node> | grep Taints
   # Taints: dedicated=gpu:NoSchedule
   ```

#### Soluciones

**1. Reducir requests**:
```yaml
requests:
  cpu: "500m"  # ← Más razonable
```

**2. Escalar el clúster** (añadir nodos):
```bash
# GKE
gcloud container clusters resize my-cluster --num-nodes=5

# EKS
eksctl scale nodegroup --cluster=my-cluster --name=ng-1 --nodes=5

# AKS
az aks scale --resource-group myRG --name myCluster --node-count 5
```

**3. Limpiar Pods innecesarios**:
```bash
kubectl delete deployment <unused-deployment>
```

**4. Añadir tolerations** (si hay taints):
```yaml
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "gpu"
  effect: "NoSchedule"
```

### Problema 2: Container OOMKilled

#### Síntoma

```bash
kubectl get pods
# NAME    READY   STATUS             RESTARTS   AGE
# my-pod  0/1     CrashLoopBackOff   5          3m

kubectl describe pod my-pod
# Last State:     Terminated
#   Reason:       OOMKilled
#   Exit Code:    137
```

#### Diagnóstico

```bash
# Ver restart count
kubectl get pod my-pod -o jsonpath='{.status.containerStatuses[0].restartCount}'
# Output: 5

# Ver eventos
kubectl get events --field-selector involvedObject.name=my-pod

# Ver logs antes del crash
kubectl logs my-pod --previous
```

#### Causas Comunes

1. **Memory limit demasiado bajo**:
   ```yaml
   limits:
     memory: "128Mi"  # ← App necesita más
   ```

2. **Memory leak** en la aplicación

3. **Pico inesperado** de memoria

#### Soluciones

**1. Aumentar memory limit**:
```yaml
limits:
  memory: "512Mi"  # ← Incrementado
```

**2. Investigar memory leak**:
```bash
# Java
kubectl exec -it my-pod -- jmap -histo:live 1 | head -20

# Python
kubectl exec -it my-pod -- python -m memory_profiler app.py

# Node.js
kubectl exec -it my-pod -- node --inspect app.js
```

**3. Configurar heap size** (Java):
```yaml
env:
- name: JAVA_OPTS
  value: "-Xmx400m -Xms400m"  # 80% del memory limit (500Mi)
```

**4. Usar memory profiling** en desarrollo

📄 **Ver ejemplos de troubleshooting OOMKilled**:
- Memory stress test: [`ejemplos/13-troubleshooting-oom/01-oomkilled-demo.yaml`](./ejemplos/13-troubleshooting-oom/01-oomkilled-demo.yaml)
- Gradual memory leak: [`ejemplos/13-troubleshooting-oom/02-gradual-leak.yaml`](./ejemplos/13-troubleshooting-oom/02-gradual-leak.yaml)

🧪 **Laboratorio**: Ver [Lab 02: Troubleshooting](./laboratorios/lab-02-troubleshooting.md#parte-1-oomkilled) para práctica guiada

### Problema 3: CPU Throttling - Alta Latencia

#### Síntoma

```bash
# Aplicación lenta, timeouts
kubectl top pod my-pod
# NAME     CPU(cores)   MEMORY(bytes)
# my-pod   500m         200Mi

# CPU stuck en el límite
```

#### Diagnóstico

```bash
# Ver throttling stats (requiere acceso al nodo)
kubectl exec -it my-pod -- cat /sys/fs/cgroup/cpu/cpu.stat
# nr_periods 1000
# nr_throttled 800  # ← 80% del tiempo throttled!
# throttled_time 400000000000

# Ver métricas Prometheus
rate(container_cpu_cfs_throttled_seconds_total{pod="my-pod"}[5m])
```

#### Causas Comunes

1. **CPU limit demasiado bajo**:
   ```yaml
   limits:
     cpu: "250m"  # ← App necesita más
   ```

2. **Picos de carga**

3. **Ineficiencia en el código**

#### Soluciones

**1. Aumentar CPU limit**:
```yaml
limits:
  cpu: "1"  # ← Incrementado
```

**2. Optimizar código**:
- Profiling de CPU
- Reducir operaciones costosas
- Usar caching

**3. Horizontal scaling** en lugar de vertical:
```yaml
# Deployment con HPA
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

📄 **Ver ejemplos de troubleshooting CPU Throttling**:
- CPU stress test: [`ejemplos/14-troubleshooting-cpu/01-cpu-stress.yaml`](./ejemplos/14-troubleshooting-cpu/01-cpu-stress.yaml)
- CPU monitoring y comparación: [`ejemplos/14-troubleshooting-cpu/02-cpu-comparison.yaml`](./ejemplos/14-troubleshooting-cpu/02-cpu-comparison.yaml)
- Deployment con HPA: [`ejemplos/14-troubleshooting-cpu/03-deployment-con-hpa.yaml`](./ejemplos/14-troubleshooting-cpu/03-deployment-con-hpa.yaml)

🧪 **Laboratorio**: Ver [Lab 02: Troubleshooting](./laboratorios/lab-02-troubleshooting.md#parte-2-cpu-throttling) para práctica guiada

### Problema 4: Ephemeral Storage - Pod Evicted

#### Síntoma

```bash
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# my-pod  0/1     Evicted   0          1h

kubectl describe pod my-pod
# Status:  Failed
# Reason:  Evicted
# Message: Pod ephemeral local storage usage exceeds the total limit
```

#### Diagnóstico

```bash
# Ver uso de storage (si el Pod aún existe)
kubectl exec -it my-pod -- df -h

# Ver eventos
kubectl get events | grep -i evict
```

#### Causas Comunes

1. **emptyDir sin sizeLimit**:
   ```yaml
   volumes:
   - name: cache
     emptyDir: {}  # ← Puede crecer sin límite
   ```

2. **Logs excesivos**

3. **Cache no limpiado**

#### Soluciones

**1. Definir sizeLimit**:
```yaml
volumes:
- name: cache
  emptyDir:
    sizeLimit: "1Gi"
```

**2. Aumentar ephemeral-storage limit**:
```yaml
limits:
  ephemeral-storage: "5Gi"
```

**3. Log rotation**:
```yaml
# Configurar en la app o usar logrotate
env:
- name: LOG_MAX_SIZE
  value: "100MB"
- name: LOG_MAX_FILES
  value: "3"
```

**4. Cleanup periódico**:
```yaml
# Cronjob para limpiar cache
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cache-cleanup
spec:
  schedule: "0 */6 * * *"  # Cada 6 horas
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cleanup
            image: busybox
            command: ["/bin/sh", "-c", "rm -rf /cache/*"]
            volumeMounts:
            - name: cache
              mountPath: /cache
```

### Problema 5: ResourceQuota - No Puedo Crear Pods

#### Síntoma

```bash
kubectl create -f my-pod.yaml
# Error from server (Forbidden): pods "my-pod" is forbidden: 
# exceeded quota: compute-quota, requested: requests.cpu=1, 
# used: requests.cpu=9, limited: requests.cpu=10
```

#### Diagnóstico

```bash
# Ver quotas del namespace
kubectl describe resourcequota -n my-namespace

# Output:
# Name:            compute-quota
# Namespace:       my-namespace
# Resource         Used   Hard
# --------         ----   ----
# requests.cpu     9      10     # ← Solo 1 CPU disponible
# requests.memory  18Gi   20Gi
```

#### Soluciones

**1. Reducir requests del nuevo Pod**:
```yaml
requests:
  cpu: "500m"  # ← De 1 a 0.5
```

**2. Eliminar Pods innecesarios**:
```bash
kubectl delete deployment <unused-app>
```

**3. Aumentar quota** (si tienes permisos):
```bash
kubectl patch resourcequota compute-quota -n my-namespace --patch '
spec:
  hard:
    requests.cpu: "20"
    requests.memory: "40Gi"
'
```

### Tabla Resumen de Troubleshooting

| Síntoma | Exit Code | Reason | Solución Principal |
|---------|-----------|--------|-------------------|
| Pending | - | FailedScheduling | Reducir requests o añadir nodos |
| CrashLoopBackOff | 137 | OOMKilled | Aumentar memory limit |
| Lentitud | - | CPU Throttling | Aumentar CPU limit o HPA |
| Evicted | - | Ephemeral storage | Definir sizeLimit, aumentar limite |
| Forbidden | - | ResourceQuota | Reducir requests o aumentar quota |

📄 **Catálogo completo de ejemplos**: Ver [ejemplos/README.md](./ejemplos/README.md) para 29 ejemplos organizados por categoría

---

## Laboratorios
📄 **Catálogo completo de ejemplos**: Ver [ejemplos/README.md](./ejemplos/README.md) para 29 ejemplos organizados por categoría

---

## Laboratorios

### Lab 01: Fundamentos de Resource Limits (35-40 min)

**Objetivos**:
- Configurar requests y limits
- Observar comportamiento de QoS classes
- Usar kubectl top para monitoreo

**[Ver laboratorio completo](./laboratorios/lab-01-fundamentos.md)**

### Lab 02: Troubleshooting Avanzado (45-50 min)

**Objetivos**:
- Simular y resolver OOMKilled
- Detectar CPU throttling
- Gestión de ephemeral storage
- Análisis de métricas

**[Ver laboratorio completo](./laboratorios/lab-02-troubleshooting.md)**

### Lab 03: Optimización para Producción (50-60 min)

**Objetivos**:
- Pod-level resources (K8s 1.34)
- Vertical Pod Autoscaler (VPA)
- Best practices de sizing
- Monitoreo con Prometheus

**[Ver laboratorio completo](./laboratorios/lab-03-produccion.md)**

---

## Referencias

### Documentación Oficial

- **Kubernetes Docs**: [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- **API Reference**: [Container Resources](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#Container)
- **Quality of Service**: [Configure Quality of Service for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
- **Ephemeral Storage**: [Ephemeral Volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/)

### Módulos Relacionados

- **[Módulo 10 - Namespaces y Organización](../modulo-10-namespaces-organizacion/)**: Organización de recursos, ResourceQuota y LimitRange
- **[Módulo 12 - Health Checks y Probes](../modulo-12-health-checks-probes/)**: Liveness y Readiness probes
- **[Módulo 13 - ConfigMaps y Variables](../modulo-13-configmaps-variables/)**: Configuración externa para Pods

### Herramientas

- **[Metrics Server](https://github.com/kubernetes-sigs/metrics-server)**: Métricas de recursos
- **[Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)**: Ajuste automático de resources
- **[Goldilocks](https://github.com/FairwindsOps/goldilocks)**: Recomendaciones de resources
- **[kubectl-resource-view](https://github.com/appvia/kubectl-resource_view)**: Vista de recursos

### Artículos y Guías

- **CNCF**: [Resource Requests and Limits Best Practices](https://www.cncf.io/blog/2023/01/13/kubernetes-resource-requests-and-limits/)
- **Google Cloud**: [Best practices for managing Kubernetes resources](https://cloud.google.com/architecture/best-practices-for-running-cost-effective-kubernetes-applications-on-gke)
- **AWS**: [Amazon EKS Best Practices - Resource Management](https://aws.github.io/aws-eks-best-practices/reliability/docs/dataplane/#configure-and-size-resource-requests-and-limits-for-all-workloads)

### Videos

- **Kubernetes Resource Management Explained** - KubeCon 2024
- **Right-sizing Kubernetes Applications** - Google Cloud Next

---

## Resumen

### Puntos Clave

1. **Requests** = Mínimo garantizado (scheduler lo usa)
2. **Limits** = Máximo permitido (kubelet lo enforza)
3. **QoS Classes**:
   - Guaranteed (request = limit) → Máxima protección
   - Burstable (request < limit) → Flexible
   - BestEffort (sin resources) → Primera en eviction
4. **CPU**: Throttling (no termina)
5. **Memory**: OOMKilled (termina con Exit Code 137)
6. **Ephemeral Storage**: Eviction (no reinicia)

### Comandos Esenciales

```bash
# Monitoreo
kubectl top pods
kubectl top nodes
kubectl describe node <node>

# Troubleshooting
kubectl describe pod <pod>
kubectl logs <pod> --previous
kubectl get events --field-selector involvedObject.name=<pod>

# Recursos del cluster
kubectl describe resourcequota
kubectl describe limitrange
```

### Checklist para Producción

- [ ] Todos los Pods tienen requests y limits definidos
- [ ] Apps críticas usan QoS Guaranteed (request = limit)
- [ ] emptyDir volumes tienen sizeLimit
- [ ] ResourceQuota configurado por namespace
- [ ] LimitRange con defaults sensatos
- [ ] Monitoreo de throttling y OOMKilled
- [ ] Alertas configuradas (Prometheus/Grafana)
- [ ] VPA considerado para optimización automática
- [ ] Requests basados en uso real (no guess)
- [ ] Testing de límites en staging

---

**Última actualización**: Noviembre 2025  
**Versión de Kubernetes**: 1.28+  
**Autor**: Curso de Kubernetes - Arquitectura

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de resource limits en pods, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
