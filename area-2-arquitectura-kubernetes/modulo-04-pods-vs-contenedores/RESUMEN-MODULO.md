# 📚 Guía de Estudio: Módulo 04 - Pods vs Contenedores

> **Guía estructurada para maximizar tu aprendizaje del módulo**

---

## 🎯 Cómo Usar Esta Guía

Esta guía te ayudará a navegar el módulo siguiendo una progresión pedagógica óptima:

1. **Lee la teoría** en el README principal
2. **Prueba los ejemplos** referenciados después de cada concepto
3. **Completa el laboratorio** al final de cada sección temática
4. **Verifica tu comprensión** con los checkpoints

---

## 📖 Ruta de Aprendizaje Recomendada

### Fase 1: Fundamentos (45-60 min)

#### 1.1. Evolución Histórica
📖 **Leer**: [README.md - Sección 1](./README.md#1-la-evolución-de-los-contenedores)  
🔑 **Conceptos clave**:
- LXC: Aislamiento total (2008)
- Docker: Red bridge compartida (2013)
- Kubernetes: Pods con namespaces compartidos (2014+)

💡 **Ejemplo práctico**:
```bash
kubectl apply -f ejemplos/01-evolucion/evolution-pod.yaml
kubectl get pods
kubectl exec evolution-demo -c web -- wget -qO- http://localhost:8080
```

✅ **Checkpoint**: Deberías poder explicar:
- ¿Por qué LXC hacía la comunicación muy compleja?
- ¿Qué mejora introdujo Docker con la red bridge?
- ¿Cuál fue la motivación para crear el concepto de Pod?

🧪 **Lab 01**: [`laboratorios/lab-01-evolucion.md`](./laboratorios/lab-01-evolucion.md)
- Duración: 30 min
- Experimenta con los 3 enfoques históricos

---

#### 1.2. ¿Qué es un Pod?
📖 **Leer**: [README.md - Sección 2](./README.md#2-qué-es-un-pod-la-evolución-final)  
🔑 **Conceptos clave**:
- Pod como "wrapper" de contenedores
- El contenedor "pause" (k8s.gcr.io/pause)
- Herencia de namespaces

💡 **Visualización clave**:
```
Paso 1: K8s crea contenedor pause
  └─ Establece namespaces base (Network, IPC, UTS, PID)

Paso 2: Otros contenedores "heredan" estos namespaces
  ├─ Comparten: Network, IPC, UTS
  └─ NO comparten: Mount, User, Cgroup
```

✅ **Checkpoint**: Deberías poder explicar:
- ¿Qué función cumple el contenedor "pause"?
- ¿Qué significa "heredar" un namespace?
- ¿Por qué algunos namespaces NO se comparten?

---

### Fase 2: Namespaces Linux (60-90 min)

#### 2.1. Los 7 Tipos de Namespaces
📖 **Leer**: [README.md - Sección 2: Namespaces](./README.md#los-linux-namespaces-en-kubernetes)  
🔑 **Concepto fundamental**:

| Namespace | ¿Compartido en Pod? | Función |
|-----------|---------------------|---------|
| Network | ✅ Sí (automático) | IP, puertos, interfaces |
| IPC | ✅ Sí (automático) | Shared memory, semaphores |
| UTS | ✅ Sí (automático) | Hostname |
| PID | ⚙️ Opcional | Visibilidad de procesos |
| Mount | ❌ No (pero volumes sí) | Filesystem |
| User | ❌ No | UIDs/GIDs |
| Cgroup | ❌ No | Resource limits |

---

#### 2.2. Network Namespace (Compartido)
📖 **Leer**: [README.md - Network Namespace](./README.md#1--network-namespace-net---compartido)  
💡 **Ejemplo práctico**:
```bash
kubectl apply -f ejemplos/02-namespaces/01-network-namespace.yaml
kubectl exec multi-container-net -c container1 -- ip addr show eth0
kubectl exec multi-container-net -c container2 -- ip addr show eth0
# Ambos mostrarán la MISMA IP
```

✅ **Checkpoint**:
- Verifica que ambos contenedores tengan la misma IP
- Prueba comunicación vía localhost entre contenedores

---

#### 2.3. IPC Namespace (Compartido)
📖 **Leer**: [README.md - IPC Namespace](./README.md#2--ipc-namespace-ipc---compartido)  
💡 **Ejemplo práctico - Shared Memory**:
```bash
kubectl apply -f ejemplos/02-namespaces/03-ipc-namespace.yaml

# Container 1: Escribir en shared memory
kubectl exec ipc-demo -c writer -- sh -c 'echo "Hello IPC" > /dev/shm/data.txt'

# Container 2: Leer desde shared memory
kubectl exec ipc-demo -c reader -- cat /dev/shm/data.txt
```

✅ **Checkpoint**:
- Entiende la diferencia entre PID (ver procesos) e IPC (comunicarse entre procesos)
- Explica cuándo usar shared memory vs HTTP

---

#### 2.4. PID Namespace (Opcional)
📖 **Leer**: [README.md - PID Namespace](./README.md#4--pid-namespace-pid---opcional)  
💡 **Ejemplo práctico**:
```bash
# Pod SIN shareProcessNamespace
kubectl apply -f ejemplos/02-namespaces/02-pid-namespace.yaml
kubectl exec pid-demo -c container1 -- ps aux
# Solo ve sus propios procesos

# Pod CON shareProcessNamespace: true
kubectl apply -f ejemplos/02-namespaces/02-pid-namespace-shared.yaml
kubectl exec pid-shared -c debug -- ps aux
# Ve TODOS los procesos del Pod
```

✅ **Checkpoint**:
- ¿Cuándo es útil compartir el PID namespace?
- Menciona 2 casos de uso (debugging, monitoring)

---

🧪 **Lab 02**: [`laboratorios/lab-02-namespace-sharing.md`](./laboratorios/lab-02-namespace-sharing.md)
- Duración: 40 min
- Exploración práctica de todos los 7 namespaces

---

### Fase 3: Patrones Multi-Contenedor (90-120 min)

Esta es la sección **más importante** del módulo. Domina estos patrones.

---

#### 3.1. Patrón Sidecar
📖 **Leer**: [README.md - Sidecar Pattern](./README.md#patrón-1-sidecar-container)  
🔑 **Concepto clave**:

> Sidecar = Contenedor auxiliar que **extiende/mejora** el contenedor principal **sin modificar su código**.

**Características**:
- ✅ Corre **simultáneamente** con el main container
- ✅ Comparte volumes y networking
- ✅ Funcionalidad cross-cutting (logging, monitoring, security)

**Casos de uso comunes**:
- 📊 Logging (Fluentd, Logstash)
- 📈 Monitoring (Prometheus exporters)
- 🔐 Security (OAuth2 Proxy)
- 🌐 Service Mesh (Envoy, Istio)

💡 **Ejemplos prácticos**:

**Ejemplo 1: Logging Sidecar**
```bash
kubectl apply -f ejemplos/03-multi-container/01-sidecar-logging.yaml
kubectl logs web-with-logging -c log-processor -f
```
👉 **Archivo**: [`01-sidecar-logging.yaml`](./ejemplos/03-multi-container/01-sidecar-logging.yaml)

**Ejemplo 2: Monitoring Sidecar**
```bash
kubectl apply -f ejemplos/03-multi-container/02-sidecar-monitoring.yaml
kubectl port-forward pod/app-with-monitoring 9113:9113
curl localhost:9113/metrics
```
👉 **Archivo**: [`02-sidecar-monitoring.yaml`](./ejemplos/03-multi-container/02-sidecar-monitoring.yaml)

**Ejemplo 3: Service Mesh Sidecar (Envoy)**
```bash
kubectl apply -f ejemplos/03-multi-container/03-sidecar-service-mesh.yaml
kubectl port-forward pod/app-with-proxy 8080:10000
```
👉 **Archivo**: [`03-sidecar-service-mesh.yaml`](./ejemplos/03-multi-container/03-sidecar-service-mesh.yaml)

✅ **Checkpoint**:
- Menciona 3 casos de uso del patrón Sidecar
- ¿Qué ventaja tiene vs modificar la imagen del app?
- ¿Cuándo NO deberías usar un Sidecar?

🧪 **Lab 03**: [`laboratorios/lab-03-sidecar-real-world.md`](./laboratorios/lab-03-sidecar-real-world.md)
- Duración: 60 min
- Implementación real: Flask + Fluent Bit

---

#### 3.2. Patrón Init Container
📖 **Leer**: [README.md - Init Container](./README.md#patrón-2-init-container)  
🔑 **Concepto clave**:

> Init Container = Se ejecuta y **completa ANTES** de que los main containers inicien.

**Características**:
- ⏰ Ejecuta **ANTES** de main containers
- 📝 Ejecución **secuencial** (uno tras otro)
- ⚡ **Termina** (no corre indefinidamente)
- 🔁 Si falla → Pod restart completo

**Casos de uso comunes**:
- 🗄️ Database migrations
- ⏳ Wait for dependencies
- 📥 Download configs/assets
- 🔧 Setup de permisos

💡 **Ejemplos prácticos**:

**Ejemplo 1: Database Migration**
```bash
kubectl apply -f ejemplos/04-init-containers/01-init-db-migration.yaml
kubectl get pods -w  # Ver progreso de init containers
kubectl logs web-with-init -c database-migration
```
👉 **Archivo**: [`01-init-db-migration.yaml`](./ejemplos/04-init-containers/01-init-db-migration.yaml)

**Ejemplo 2: Wait for Dependencies**
```bash
kubectl apply -f ejemplos/04-init-containers/02-init-wait-for-deps.yaml
kubectl logs app-wait-deps -c wait-for-redis
```
👉 **Archivo**: [`02-init-wait-for-deps.yaml`](./ejemplos/04-init-containers/02-init-wait-for-deps.yaml)

**Ejemplo 3: Configuration Setup**
```bash
kubectl apply -f ejemplos/04-init-containers/03-init-config-setup.yaml
kubectl exec app-config-setup -- cat /app/config/app.conf
```
👉 **Archivo**: [`03-init-config-setup.yaml`](./ejemplos/04-init-containers/03-init-config-setup.yaml)

✅ **Checkpoint**:
- ¿Cuál es la diferencia clave entre Init Container y Sidecar?
- ¿En qué orden se ejecutan múltiples init containers?
- ¿Qué pasa si un init container falla?

🧪 **Lab 04**: [`laboratorios/lab-04-init-migration.md`](./laboratorios/lab-04-init-migration.md)
- Duración: 70 min
- Migración de database con validación

---

#### 3.3. Patrón Ambassador
📖 **Leer**: [README.md - Ambassador](./README.md#patrón-3-ambassador-container)  
🔑 **Concepto clave**:

> Ambassador = Contenedor que actúa como **proxy/intermediario** entre el main container y servicios externos.

**Características**:
- 🔄 Corre **simultáneamente** con main container
- 🌐 Abstrae **conexión a servicios externos**
- 🔀 Funciones: load balancing, pooling, SSL, circuit breaking

**Casos de uso comunes**:
- 🗄️ Database connection pooling (PgBouncer)
- 🔄 Load balancing (HAProxy)
- 🔐 SSL/TLS termination (Nginx)
- 🌐 Service discovery proxy

💡 **Ejemplos prácticos**:

**Ejemplo 1: Database Connection Pooling**
```bash
kubectl apply -f ejemplos/05-ambassador/01-ambassador-db-pool.yaml
kubectl logs app-with-pooling -c db-ambassador
```
👉 **Archivo**: [`01-ambassador-db-pool.yaml`](./ejemplos/05-ambassador/01-ambassador-db-pool.yaml)

**Ejemplo 2: Load Balancing**
```bash
kubectl apply -f ejemplos/05-ambassador/02-ambassador-loadbalancer.yaml
kubectl port-forward pod/app-with-lb 8404:8404
# Ver stats: http://localhost:8404/stats
```
👉 **Archivo**: [`02-ambassador-loadbalancer.yaml`](./ejemplos/05-ambassador/02-ambassador-loadbalancer.yaml)

**Ejemplo 3: SSL/TLS Termination**
```bash
kubectl apply -f ejemplos/05-ambassador/03-ambassador-ssl.yaml
kubectl port-forward pod/app-with-ssl 8443:443
curl -k https://localhost:8443
```
👉 **Archivo**: [`03-ambassador-ssl.yaml`](./ejemplos/05-ambassador/03-ambassador-ssl.yaml)

✅ **Checkpoint**:
- ¿Qué beneficio aporta un Ambassador al main container?
- Menciona 2 diferencias entre Ambassador y Sidecar
- ¿Cuándo NO deberías usar Ambassador?

---

#### 3.4. Comparación de los 3 Patrones

| Aspecto | Sidecar | Init Container | Ambassador |
|---------|---------|----------------|------------|
| **Cuándo corre** | 🔄 Simultáneo | ⏰ Antes | 🔄 Simultáneo |
| **Duración** | ♾️ Indefinida | ⚡ Termina | ♾️ Indefinida |
| **Propósito** | Extender funcionalidad | Setup/preparación | Proxy intermedio |
| **Interacción** | Shared volumes | Shared volumes | Network localhost |
| **Ejemplos** | Logging, monitoring | Migrations, wait-for | Load balancing, SSL |
| **Si falla** | Container restart | Pod restart | Container restart |

---

### Fase 4: Decisiones de Arquitectura (45-60 min)

#### 4.1. ¿Un Pod o Múltiples Pods?
📖 **Leer**: [README.md - Decisión Matrix](./README.md#decisión-matrix-un-pod-o-múltiples-pods)  
🔑 **Regla de oro**:

```
🟢 UN SOLO POD cuando:
├─ Comunicación muy frecuente (microsegundos)
├─ Shared memory o IPC necesario
├─ Mismo ciclo de vida ESTRICTO
└─ Imposible separar funcionalmente

🔴 PODS SEPARADOS cuando:
├─ Escalado independiente necesario
├─ Actualizaciones independientes
├─ Comunicación vía HTTP/gRPC
└─ Fault isolation deseado
```

✅ **Checkpoint**:
- ¿Cuándo usarías un Pod multi-contenedor?
- ¿Cuándo preferirías múltiples Pods?
- ¿Qué preguntas debes hacerte antes de decidir?

---

#### 4.2. Migración de Docker Compose a Kubernetes
📖 **Leer**: [README.md - Migration](./README.md#5-migración-docker-compose--kubernetes)  
💡 **Ejemplo práctico**:

**Docker Compose original**: [`ejemplos/05-migracion-compose/docker-compose.yml`](./ejemplos/05-migracion-compose/docker-compose.yml)

**Opciones de migración**:

**Opción A: Pods Separados (Recomendado)**
- `web-deployment.yaml` - Frontend con réplicas
- `api-deployment.yaml` - Backend con réplicas
- `db-deployment.yaml` - Database con PVC

**Opción B: Multi-Container Pod (Solo casos específicos)**
- Solo cuando hay tight coupling extremo
- Ejemplo: Procesamiento en tiempo real

```bash
# Aplicar migración
kubectl apply -f ejemplos/05-migracion-compose/k8s/
kubectl get all
```

✅ **Checkpoint**:
- ¿Por qué la opción A (Pods separados) es generalmente mejor?
- ¿En qué casos usarías la opción B (Multi-container Pod)?

🧪 **Lab 05**: [`laboratorios/lab-05-compose-migration.md`](./laboratorios/lab-05-compose-migration.md)
- Duración: 50 min
- Migración completa paso a paso

---

### Fase 5: Best Practices y Antipatrones (30-45 min)

#### 5.1. Antipatrones Comunes
📖 **Leer**: [README.md - Antipatrones](./README.md#9-antipatrones-y-mejores-prácticas)  
📁 **Ejemplos**: [`ejemplos/09-antipatrones/`](./ejemplos/09-antipatrones/)

**❌ Antipatrón 1: Fat Pods**
- Demasiados contenedores no relacionados en un Pod
- 👉 [`01-fat-pods.yaml`](./ejemplos/09-antipatrones/01-fat-pods.yaml)

**❌ Antipatrón 2: Singleton Services**
- Pod único (single point of failure)
- 👉 [`02-singleton-services.yaml`](./ejemplos/09-antipatrones/02-singleton-services.yaml)

**❌ Antipatrón 3: Volume Abuse**
- Usar filesystem para comunicación entre contenedores
- 👉 [`03-volume-abuse.yaml`](./ejemplos/09-antipatrones/03-volume-abuse.yaml)

✅ **Checkpoint**:
- Menciona 3 antipatrones y sus soluciones
- ¿Por qué es malo tener demasiados contenedores en un Pod?

---

#### 5.2. Mejores Prácticas

1. **Un Pod = Una responsabilidad principal**
2. **Sidecar solo si es esencial** para la función principal
3. **Init containers para setup** que debe completarse antes
4. **Shared volumes solo para datos compartidos** reales
5. **Use Deployments**, no Pods directos en producción
6. **Mínimo necesario**: Menos contenedores = más simple

---

## 🎯 Verificación Final de Conocimientos

Antes de continuar al Módulo 05, asegúrate de poder responder:

### Fundamentos
- [ ] ¿Cuál fue la evolución LXC → Docker → Kubernetes?
- [ ] ¿Qué es un Pod y por qué es la unidad básica de K8s?
- [ ] ¿Qué función cumple el contenedor "pause"?

### Namespaces
- [ ] ¿Cuáles son los 7 tipos de namespaces Linux?
- [ ] ¿Cuáles se comparten en un Pod y cuáles no?
- [ ] ¿Cuál es la diferencia entre PID namespace e IPC namespace?

### Patrones
- [ ] ¿Cuándo usarías un Sidecar?
- [ ] ¿Cuándo usarías un Init Container?
- [ ] ¿Cuándo usarías un Ambassador?
- [ ] ¿Cuáles son las diferencias entre los 3 patrones?

### Arquitectura
- [ ] ¿Cuándo usarías un Pod multi-contenedor vs múltiples Pods?
- [ ] ¿Cómo migrarías una app de Docker Compose a K8s?
- [ ] ¿Cuáles son los 3 antipatrones principales?

---

## 📚 Recursos Adicionales

### Documentación
- 📖 [README Principal](./README.md) - Teoría completa
- 📖 [Ejemplos README](./ejemplos/README.md) - Guía de todos los ejemplos
- 📖 [Laboratorios README](./laboratorios/README.md) - Guía de laboratorios

### Comandos de Diagnóstico
```bash
# Ver todos los pods
kubectl get pods

# Describir un Pod
kubectl describe pod <nombre>

# Ver logs de contenedor específico
kubectl logs <pod> -c <contenedor>

# Ejecutar comandos en contenedor
kubectl exec -it <pod> -c <contenedor> -- bash

# Ver eventos
kubectl get events --field-selector involvedObject.name=<pod>
```

---

## ⏭️ Siguiente Paso

Una vez completado este módulo, continúa con:

**Módulo 05: Gestión Avanzada de Pods**
- Manifiestos complejos
- Resource requests y limits
- Health checks (liveness, readiness, startup probes)
- Pod lifecycle hooks
- Security contexts
- Pod affinity/anti-affinity

**Diferencia clave**:
- **Módulo 04** (este): **Qué es un Pod** y patrones básicos
- **Módulo 05**: **Cómo gestionarlos** de forma avanzada en producción

---

## 🏆 Checklist de Finalización

Marca cada item a medida que avanzas:

### Teoría
- [ ] Leí Sección 1: Evolución histórica
- [ ] Leí Sección 2: Anatomía del Pod
- [ ] Leí Sección 3: Namespaces Linux
- [ ] Leí Sección 4: Patrones multi-contenedor
- [ ] Leí Sección 5: Decisiones de arquitectura
- [ ] Leí Sección 6: Best practices

### Ejemplos
- [ ] Probé ejemplo de evolución
- [ ] Probé ejemplos de namespaces (al menos 3)
- [ ] Probé ejemplo de Sidecar
- [ ] Probé ejemplo de Init Container
- [ ] Probé ejemplo de Ambassador
- [ ] Probé ejemplo de migración Docker Compose

### Laboratorios
- [ ] Completé Lab 01 (Evolución)
- [ ] Completé Lab 02 (Namespaces)
- [ ] Completé Lab 03 (Sidecar)
- [ ] Completé Lab 04 (Init Containers)
- [ ] Completé Lab 05 (Migración Compose)

### Verificación
- [ ] Puedo explicar los 3 patrones multi-contenedor
- [ ] Sé cuándo usar un Pod vs múltiples Pods
- [ ] Identifico antipatrones comunes
- [ ] Estoy listo para el Módulo 05

---

**🎉 ¡Felicitaciones!** Si completaste todos los checkpoints, dominas los fundamentos de Pods en Kubernetes.
