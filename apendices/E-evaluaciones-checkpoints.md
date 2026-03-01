# Apéndice E: Evaluaciones y Checkpoints

Este apéndice recopila las evaluaciones y checkpoints de cada capítulo, extraídos de los módulos originales. Úsalos para verificar tu progreso antes de avanzar al siguiente capítulo.

---

## Capítulo 1: Virtualización Tradicional

### 🧠 Resultado esperado

Al finalizar este módulo, el estudiante podrá:

### **🎯 Conceptos fundamentales:**
- ✅ Comprender qué es la virtualización y cómo funciona a nivel técnico
- ✅ Explicar el rol del hipervisor en la gestión de recursos
- ✅ Diferenciar entre hipervisores tipo 1 (bare-metal) y tipo 2 (hosted)
- ✅ Identificar los diferentes tipos de virtualización (servidores, red, almacenamiento, aplicaciones)

### **💼 Habilidades prácticas:**
- ✅ Implementar una máquina virtual básica en Azure
- ✅ Conectarse y gestionar VMs remotamente via SSH
- ✅ Monitorear recursos y rendimiento de máquinas virtuales
- ✅ Realizar migración básica de VMs entre hosts

### **📊 Análisis comparativo:**
- ✅ Evaluar ventajas y desventajas de la virtualización vs. hardware dedicado
- ✅ Comparar eficiencia de recursos entre VMs y contenedores
- ✅ Identificar casos de uso apropiados para cada tecnología
- ✅ Justificar por qué surgieron los contenedores como evolución natural

### **🔮 Visión estratégica:**
- ✅ Entender el rol de la virtualización en la evolución hacia cloud computing
- ✅ Planificar estrategias de migración y modernización
- ✅ Reconocer cuándo usar VMs vs. contenedores vs. serverless
- ✅ Prepararse conceptualmente para Kubernetes y orquestación de contenedores

---

### 📋 Checkpoint del Módulo

Antes de continuar al Módulo 2, asegúrate de poder:

- [ ] Explicar qué es la virtualización y sus componentes
- [ ] Crear una VM en Azure Portal
- [ ] Conectarte por SSH y verificar recursos del sistema
- [ ] Describir 3 ventajas y 3 desventajas de la virtualización
- [ ] Justificar por qué surgieron los contenedores

---

---

## Capítulo 2: Docker y Contenerización

### **🎯 Checkpoint de Conceptos Fundamentales**

Antes de continuar a las tecnologías subyacentes, asegúrate de poder:

- [ ] Explicar la diferencia entre imagen y contenedor
- [ ] Describir qué es un Dockerfile y para qué sirve
- [ ] Entender que un contenedor es un proceso que puede terminar
- [ ] Conocer la diferencia entre CMD y ENTRYPOINT
- [ ] Saber cómo publicar una imagen en Docker Hub
- [ ] Ejecutar múltiples contenedores de la misma imagen
- [ ] Explicar el workflow completo: Dockerfile → Image → Container

**👉 Con estos conceptos claros, ahora estás listo para entender las tecnologías Linux subyacentes que hacen posible el aislamiento de contenedores.**

---

### 📋 **Checkpoint de la Sección 8:**

✅ **Deberías poder:**
1. Ejecutar contenedores con diferentes configuraciones (`run`, `-p`, `-v`, `-e`)
2. Gestionar el ciclo de vida de contenedores (`start`, `stop`, `restart`, `rm`)
3. Inspeccionar contenedores y ver logs (`logs`, `inspect`, `stats`, `exec`)
4. Trabajar con imágenes (`pull`, `build`, `tag`, `push`)
5. Usar redes y volúmenes para comunicación y persistencia
6. Limpiar recursos Docker para liberar espacio

🎯 **Comando más importante:**
```bash
docker run -d --name miapp -p 8080:80 -v datos:/app nginx
```
Este único comando cubre: ejecución, naming, port mapping, volúmenes e imagen.

---

### 🧠 Resultado esperado

Al finalizar este módulo, el estudiante podrá:

- ✅ Comprender qué es la contenerización y cómo difiere de la virtualización
- ✅ Identificar las tecnologías Linux subyacentes (namespaces, cgroups)
- ✅ Instalar y configurar Docker correctamente
- ✅ Ejecutar y gestionar contenedores básicos
- ✅ Entender las ventajas de los contenedores para aplicaciones modernas
- ✅ Reconocer las limitaciones que llevan a la necesidad de orquestación con Kubernetes

---

### 📋 Checkpoint del Módulo

Antes de continuar al Área 2, asegúrate de poder:

- [ ] Instalar Docker en un sistema Linux
- [ ] Ejecutar contenedores básicos con diferentes opciones
- [ ] Gestionar imágenes y contenedores con comandos CLI
- [ ] Explicar las diferencias entre VMs y contenedores
- [ ] Identificar cuándo necesitas un orquestador como Kubernetes

---

---

## Capítulo 7: Gestión Avanzada de Pods

### ✅ Checkpoint Sección 1

Antes de continuar, verifica que puedes:
- [ ] Explicar los 4 campos raíz obligatorios de un manifiesto
- [ ] Distinguir entre labels y annotations
- [ ] Escribir un Pod con variables de entorno
- [ ] Crear un Pod con volume compartido entre contenedores
- [ ] Configurar resources básicos (requests/limits)

---

### 🧪 Laboratorio 01: Crear Manifiestos YAML

**Duración**: 45 minutos

📁 **Laboratorio**: [`laboratorios/lab-01-crear-pods.md`](./laboratorios/lab-01-crear-pods.md)

**Objetivos**:
1. Crear Pod desde cero con todas las secciones
2. Agregar labels y annotations
3. Configurar variables de entorno
4. Implementar volume compartido
5. Aplicar resources básicos

---

### ✅ Checkpoint Sección 2

Antes de continuar, verifica que puedes:
- [ ] Explicar los 5 estados de un Pod
- [ ] Distinguir entre Succeeded y Failed
- [ ] Configurar restart policies apropiadamente
- [ ] Identificar por qué un Pod está en Pending
- [ ] Debuggear un CrashLoopBackOff
- [ ] Recrear un Pod para modificarlo

---

### 🧪 Laboratorio 02: Gestión del Ciclo de Vida

**Duración**: 40 minutos

📁 **Laboratorio**: [`laboratorios/lab-02-multi-contenedor-labels.md`](./laboratorios/lab-02-multi-contenedor-labels.md) *(adaptar para ciclo de vida)* o **propuesto**: `lab-02-ciclo-vida.md`

**Objetivos**:
1. Observar transiciones de estados
2. Experimentar con restart policies
3. Simular y resolver CrashLoopBackOff
4. Practicar recreación de Pods
5. Analizar eventos y logs

---

### ✅ Checkpoint Sección 3

Antes de continuar, verifica que puedes:
- [ ] Explicar diferencia entre labels y annotations
- [ ] Crear Pods con labels específicos
- [ ] Filtrar Pods con equality-based selectors
- [ ] Filtrar Pods con set-based selectors
- [ ] Combinar múltiples condiciones (AND)
- [ ] Agregar/modificar/eliminar labels dinámicamente
- [ ] Decidir cuándo usar label vs annotation
- [ ] Entender cómo Deployments seleccionan Pods

---

### 🧪 Laboratorio 03: Labels y Selectors

**Duración**: 30 minutos

📁 **Laboratorio**: [`laboratorios/lab-02-multi-contenedor-labels.md`](./laboratorios/lab-02-multi-contenedor-labels.md) *(incluye labels)* o **propuesto**: `lab-03-labels-selectors.md`

**Objetivos**:
1. Crear Pods con estrategia de labels multi-dimensionales
2. Practicar filtrado avanzado con selectors
3. Simular canary deployment con labels
4. Gestionar labels dinámicamente
5. Diferenciar annotations de labels en casos reales

---

### ✅ Checkpoint Sección 4

Antes de continuar, verifica que puedes:
- [ ] Explicar diferencia entre requests y limits
- [ ] Configurar resources en un Pod
- [ ] Entender unidades (millicores, Mi, Gi)
- [ ] Predecir comportamiento al exceder limit (CPU vs Memory)
- [ ] Identificar las 3 QoS classes
- [ ] Diagnosticar un Pod Pending por recursos
- [ ] Resolver un OOMKilled ajustando limits
- [ ] Usar `kubectl top` para monitoring

---

### 🧪 Laboratorio 04: Resource Management

**Duración**: 50 minutos

📁 **Laboratorio propuesto**: `laboratorios/lab-04-resources.md` *(pendiente de crear)*

**Objetivos**:
1. Configurar requests y limits apropiados
2. Observar comportamiento de QoS classes
3. Simular y resolver OOMKilled
4. Practicar cálculo de recursos óptimos
5. Implementar resource quotas a nivel namespace

---

### ✅ Checkpoint Sección 5

Antes de continuar, verifica que puedes:
- [ ] Explicar diferencia entre liveness, readiness, y startup probes
- [ ] Configurar los 3 tipos de probes (HTTP, TCP, Exec)
- [ ] Calcular tiempo máximo hasta reinicio con failureThreshold
- [ ] Decidir cuándo usar startup probe vs solo liveness
- [ ] Diseñar endpoints /healthz/live y /healthz/ready apropiadamente
- [ ] Diagnosticar por qué un Pod reinicia repetidamente
- [ ] Diagnosticar por qué un Pod no recibe tráfico

---

### 🧪 Laboratorio 05: Health Checks y Probes

**Duración**: 60 minutos

📁 **Laboratorio propuesto**: `laboratorios/lab-05-health-checks.md` *(pendiente de crear)*

**Objetivos**:
1. Implementar liveness probe y observar reinicios automáticos
2. Implementar readiness probe y verificar eliminación de endpoints
3. Usar startup probe para app con arranque lento
4. Simular y resolver fallos de probes
5. Optimizar configuración de probes para diferentes escenarios

---

### ✅ Checkpoint Sección 6

Antes de continuar, verifica que puedes:
- [ ] Explicar qué es un Security Context
- [ ] Configurar runAsUser y runAsNonRoot
- [ ] Implementar readOnlyRootFilesystem con volumes necesarios
- [ ] Drop ALL capabilities y agregar solo las necesarias
- [ ] Entender allowPrivilegeEscalation
- [ ] Diferenciar Pod-level vs Container-level security
- [ ] Usar el template de security completo

---

### 🧪 Laboratorio 06: Security Contexts

**Duración**: 50 minutos

📁 **Laboratorio propuesto**: `laboratorios/lab-06-security-contexts.md` *(pendiente de crear)*

**Objetivos**:
1. Crear Pod inseguro vs Pod hardened
2. Implementar readOnlyRootFilesystem con volumes
3. Configurar capabilities mínimas
4. Verificar security contexts aplicados
5. Aplicar template de security a aplicación real

---

---

## Capítulo 8: ReplicaSets y Escalado

### **✅ Checkpoint 01: Verificación de Conceptos**

Antes de continuar, asegúrate de poder responder:

- [ ] ¿Qué problema resuelven los ReplicaSets?
- [ ] ¿Cuál es la diferencia clave entre un Pod y un ReplicaSet?
- [ ] ¿Qué es el "reconciliation loop"?
- [ ] ¿Qué son los "owner references"?
- [ ] ¿Qué pasa si eliminas un Pod gestionado por un ReplicaSet?

📁 **Laboratorio**: [`laboratorios/lab-01-conceptos-replicasets.md`](./laboratorios/lab-01-conceptos-replicasets.md)
- Duración: 30 minutos
- Experimenta con reconciliación y ownership

---

### **✅ Checkpoint 02: Verificación de Manifiestos**

Antes de continuar, asegúrate de poder:

- [ ] Escribir un manifiesto básico de ReplicaSet
- [ ] Identificar los 4 campos obligatorios
- [ ] Explicar la regla selector ⊆ template.labels
- [ ] Crear un ReplicaSet con template de Pod completo
- [ ] Usar kubectl para crear y gestionar ReplicaSets

📁 **Laboratorio**: [`laboratorios/lab-02-manifiestos-replicasets.md`](./laboratorios/lab-02-manifiestos-replicasets.md)
- Duración: 40 minutos
- Crea ReplicaSets con configuraciones progresivamente complejas

### **✅ Checkpoint 03: Verificación de Selectors**

Antes de continuar, asegúrate de poder:

- [ ] Explicar qué es un selector y su función
- [ ] Usar `matchLabels` para selección simple
- [ ] Usar `matchExpressions` con los 4 operadores
- [ ] Combinar `matchLabels` y `matchExpressions`
- [ ] Identificar el peligro de adopción de Pods
- [ ] Segregar ambientes usando selectores

📁 **Laboratorio**: [`laboratorios/lab-03-selectors-avanzados.md`](./laboratorios/lab-03-selectors-avanzados.md)

### **✅ Checkpoint 04: Verificación de Escalado**

Antes de continuar, asegúrate de poder:

- [ ] Explicar la diferencia entre escalado horizontal y vertical
- [ ] Escalar un ReplicaSet de forma declarativa
- [ ] Escalar un ReplicaSet de forma imperativa
- [ ] Reducir réplicas y observar terminación de Pods
- [ ] Escalar a cero y volver a escalar
- [ ] Simular escalado bajo carga

📁 **Laboratorio**: [`laboratorios/lab-04-escalado-horizontal.md`](./laboratorios/lab-04-escalado-horizontal.md)
- Duración: 35 minutos
- Practica escalado en escenarios reales

---

### **✅ Checkpoint 05: Verificación de Self-Healing**

Antes de continuar, asegúrate de poder:

- [ ] Explicar qué es self-healing
- [ ] Demostrar auto-recuperación eliminando un Pod
- [ ] Identificar tiempo de detección y recuperación
- [ ] Reconocer escenarios donde self-healing NO funciona
- [ ] Interpretar eventos de recreación de Pods
- [ ] Diagnosticar CrashLoopBackOff

📁 **Laboratorio**: [`laboratorios/lab-05-self-healing.md`](./laboratorios/lab-05-self-healing.md)
- Duración: 40 minutos
- Simula fallos y observa recuperación automática

---

### **✅ Checkpoint 06: Verificación de Limitaciones**

Antes de continuar, asegúrate de poder:

- [ ] Explicar por qué ReplicaSets NO actualizan Pods existentes
- [ ] Demostrar el problema de actualización manual
- [ ] Comparar ReplicaSet vs Deployment
- [ ] Identificar 4 limitaciones clave de ReplicaSets
- [ ] Decidir cuándo usar ReplicaSet vs Deployment
- [ ] Justificar por qué Deployments son mejores para producción

📁 **Laboratorio**: [`laboratorios/lab-06-limitaciones-replicasets.md`](./laboratorios/lab-06-limitaciones-replicasets.md)
- Duración: 35 minutos
- Experimenta con problemas de actualización

---

### **✅ Checkpoint 07: Verificación de Best Practices**

Antes de continuar, asegúrate de poder:

- [ ] Aplicar naming conventions consistentes
- [ ] Crear selectores específicos y seguros
- [ ] Definir resources (requests/limits) apropiados
- [ ] Implementar health checks (liveness/readiness/startup)
- [ ] Aplicar security contexts
- [ ] Identificar 4 antipatrones comunes
- [ ] Crear un template production-ready completo

📁 **Laboratorio**: [`laboratorios/lab-07-production-ready.md`](./laboratorios/lab-07-production-ready.md)
- Duración: 50 minutos
- Crea ReplicaSet production-ready desde cero

---

---

## Capítulo 9: Deployments y Rollouts

### **✅ Checkpoint 01: Fundamentos de Deployments**

Antes de continuar, asegúrate de poder:

- [ ] Explicar el problema que tienen los ReplicaSets con updates
- [ ] Describir cómo Deployments resuelven ese problema
- [ ] Mencionar 5 ventajas de Deployments sobre ReplicaSets
- [ ] Identificar cuándo usar Deployment vs StatefulSet
- [ ] Dibujar la jerarquía: Deployment → ReplicaSet → Pod
- [ ] Explicar qué es un rolling update

📁 **Laboratorio**: [`laboratorios/lab-01-crear-primer-deployment.md`](./laboratorios/lab-01-crear-primer-deployment.md)
- Duración: 30 minutos
- Crea tu primer Deployment
- Observa rolling update en acción
- Compara comportamiento vs ReplicaSet

---

### **✅ Checkpoint 02: Creación y Gestión**

Antes de continuar, asegúrate de poder:

- [ ] Crear un Deployment desde un manifiesto YAML
- [ ] Identificar las 4 secciones principales del manifiesto
- [ ] Explicar la diferencia entre `spec.replicas` y `spec.template`
- [ ] Listar Deployments, ReplicaSets y Pods relacionados
- [ ] Inspeccionar el estado de un Deployment con `describe`
- [ ] Ver eventos de creación y escalado
- [ ] Escalar un Deployment imperativamente
- [ ] Explicar qué es `spec.selector` y por qué debe coincidir con `template.labels`

📁 **Laboratorio**: [`laboratorios/lab-02-gestion-deployments.md`](./laboratorios/lab-02-gestion-deployments.md)
- Duración: 35 minutos
- Crea Deployments simple y production-ready
- Practica comandos de gestión (get, describe, scale)
- Inspecciona ReplicaSets y Pods gestionados
- Observa owner references

---

### **✅ Checkpoint 03: Rolling Updates**

Antes de continuar, asegúrate de poder:

- [ ] Explicar qué es un rolling update
- [ ] Describir el flujo: crear ReplicaSet v2 → escalar UP/DOWN gradualmente
- [ ] Mencionar 5 cambios que activan rolling update
- [ ] Explicar `maxSurge` y `maxUnavailable` con ejemplos
- [ ] Configurar zero downtime (maxUnavailable: 0)
- [ ] Usar `kubectl rollout status` para ver progreso
- [ ] Observar rolling update en tiempo real con `--watch`
- [ ] Identificar ReplicaSets históricos vs activos

📁 **Laboratorio**: [`laboratorios/lab-03-rolling-updates.md`](./laboratorios/lab-03-rolling-updates.md)
- Duración: 45 minutos
- Practica rolling updates con diferentes configuraciones
- Experimenta con maxSurge y maxUnavailable
- Simula escenarios: zero downtime, update rápido, recursos limitados
- Monitorea progreso del rollout

---

### **✅ Checkpoint 04: Rollback y Versiones**

Antes de continuar, asegúrate de poder:

- [ ] Ver historial de revisiones con `kubectl rollout history`
- [ ] Explicar qué es `revisionHistoryLimit` y su impacto
- [ ] Ver detalles de una revisión específica
- [ ] Hacer rollback a la revisión anterior con `undo`
- [ ] Hacer rollback a revisión específica con `--to-revision`
- [ ] Explicar que rollback crea una nueva revisión
- [ ] Configurar `progressDeadlineSeconds` para timeout
- [ ] Pausar y reanudar rolling updates
- [ ] Diagnosticar rollout bloqueado (ImagePullBackOff, Pending, etc.)

📁 **Laboratorio**: [`laboratorios/lab-04-rollback-versiones.md`](./laboratorios/lab-04-rollback-versiones.md)
- Duración: 40 minutos
- Practica rollback manual y automático
- Simula fallos de despliegue (imagen incorrecta)
- Experimenta con pause/resume
- Troubleshooting de rollouts bloqueados

---

### **✅ Checkpoint 05: Estrategias Avanzadas**

Antes de continuar, asegúrate de poder:

- [ ] Comparar RollingUpdate vs Recreate (downtime, velocidad, recursos)
- [ ] Explicar cuándo usar Recreate (bases de datos, incompatibilidad)
- [ ] Describir Blue-Green deployment (2 entornos, switch instantáneo)
- [ ] Implementar Blue-Green con 2 Deployments + Service selector
- [ ] Describir Canary deployment (porcentaje gradual)
- [ ] Implementar Canary con scaling manual de replicas
- [ ] Calcular porcentajes: 1 canary + 9 stable = 10% canary
- [ ] Explicar ventajas/desventajas de cada estrategia

📁 **Laboratorio**: [`laboratorios/lab-05-estrategias-avanzadas.md`](./laboratorios/lab-05-estrategias-avanzadas.md)
- Duración: 60 minutos
- Implementa Blue-Green deployment
- Practica Canary con diferentes porcentajes (10%, 50%, 100%)
- Simula rollback de Canary
- Compara tiempos y recursos de cada estrategia

---

### **✅ Checkpoint 06: Best Practices**

Antes de continuar, asegúrate de poder:

- [ ] Aplicar naming conventions (app-component-environment)
- [ ] Definir resources (requests + limits) con cálculos apropiados
- [ ] Configurar liveness y readiness probes correctamente
- [ ] Explicar diferencia entre liveness y readiness
- [ ] Implementar security contexts (runAsNonRoot, readOnlyRootFilesystem, capabilities)
- [ ] Identificar 5 anti-patterns comunes
- [ ] Usar semantic versioning (NO :latest)
- [ ] Configurar zero downtime (maxUnavailable: 0)
- [ ] Agregar change-cause annotations

📁 **Laboratorio**: [`laboratorios/lab-06-best-practices.md`](./laboratorios/lab-06-best-practices.md)
- Duración: 50 minutos
- Transforma un Deployment básico a production-ready
- Implementa todos los best practices
- Testing de health checks (simula fallos)
- Valida security contexts

---

### **✅ Checkpoint 07: Monitoreo y Troubleshooting**

Antes de continuar, asegúrate de poder:

- [ ] Usar comandos de diagnóstico rápido (get, describe, events, logs)
- [ ] Diagnosticar ImagePullBackOff (imagen incorrecta)
- [ ] Diagnosticar CrashLoopBackOff (logs, previous logs)
- [ ] Diagnosticar Pods Pending (resources, node selector)
- [ ] Diagnosticar readiness probe failing
- [ ] Identificar métricas clave de disponibilidad
- [ ] Configurar alertas básicas (Deployment not available)

📁 **Laboratorio**: [`laboratorios/lab-07-troubleshooting.md`](./laboratorios/lab-07-troubleshooting.md)
- Duración: 45 minutos
- Simula 5 problemas comunes y resuélvelos
- Practica debugging con kubectl logs/describe/events
- Configura alertas básicas

---

### **✅ Checkpoint Final**

Autoevaluación completa del módulo:

**Conceptos (Sección 1)**:
- [ ] Explicar el problema que resuelven los Deployments
- [ ] Describir la arquitectura: Deployment → ReplicaSet → Pods
- [ ] Comparar Deployment vs ReplicaSet (cuándo usar cada uno)

**Gestión (Sección 2)**:
- [ ] Crear Deployment desde manifiesto YAML
- [ ] Usar kubectl para gestionar Deployments (get, describe, scale, delete)
- [ ] Inspeccionar ReplicaSets y Pods gestionados

**Rolling Updates (Sección 3)**:
- [ ] Explicar flujo de rolling update (crear RS v2, escalar gradualmente)
- [ ] Configurar maxSurge y maxUnavailable apropiadamente
- [ ] Observar rolling update en tiempo real con --watch

**Rollback (Sección 4)**:
- [ ] Ver historial de revisiones
- [ ] Hacer rollback a versión anterior o específica
- [ ] Pausar/reanudar rolling updates
- [ ] Troubleshoot rollouts bloqueados

**Estrategias (Sección 5)**:
- [ ] Implementar Blue-Green deployment
- [ ] Implementar Canary deployment
- [ ] Elegir estrategia apropiada según caso de uso

**Best Practices (Sección 6)**:
- [ ] Aplicar naming conventions
- [ ] Definir resources apropiadamente
- [ ] Configurar health checks (liveness + readiness)
- [ ] Implementar security contexts
- [ ] Evitar anti-patterns comunes

**Troubleshooting (Sección 7)**:
- [ ] Diagnosticar problemas comunes (ImagePullBackOff, CrashLoopBackOff, Pending)
- [ ] Usar comandos de debugging efectivamente
- [ ] Configurar monitoreo y alertas

---

---

## Capítulo 10: Services y Service Discovery

### ✅ Checkpoint 1: Conceptos Fundamentales

Antes de continuar, asegúrate de comprender:

**Preguntas de Autoevaluación**:
1. ¿Por qué los Pods necesitan Services? ¿Qué problema resuelven?
2. ¿Qué sucede cuando un Pod muere y se recrea? ¿Cómo afecta su IP?
3. ¿Qué componentes intervienen entre un cliente y un Pod backend?
4. Explica con tus palabras: ¿Qué es un Endpoint?

**Respuestas esperadas**:
<details>
<summary>Ver respuestas</summary>

1. Los Pods son efímeros (IP cambia al recrearse). Services proporcionan una IP estable y nombre DNS para acceder a un grupo de Pods dinámico.

2. Cuando un Pod muere, se recrea con una **nueva IP**. Sin Service, los clientes perderían la conexión. El Service mantiene una IP estable y actualiza automáticamente sus Endpoints.

3. Cliente → DNS (resuelve nombre) → Service (ClusterIP) → kube-proxy (balanceo) → Endpoint (IP del Pod) → Pod backend

4. Un Endpoint es la dirección IP:Puerto de un Pod que cumple con el selector del Service. Es el "puente" entre el Service (abstracción) y los Pods reales (implementación).
</details>

**Mini-ejercicio**:
```bash
# Ejecuta estos comandos y observa la relación
kubectl get pods -o wide  # Ver IPs de Pods
kubectl get svc           # Ver ClusterIP del Service
kubectl get endpoints     # Ver mapping Service → Pods
```

**¿Listo para continuar?** Si respondiste correctamente, avanza a la siguiente sección. Si tienes dudas, revisa la Sección 1.

---

### 2. Anatomía de un Service

#### Componentes Fundamentales

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service          # Nombre del Service
  namespace: default        # Namespace
  labels:
    app: my-app             # Labels del Service
spec:
  selector:                 # Selector para encontrar Pods
    app: my-app
    tier: backend
  ports:                    # Puertos expuestos
    - name: http
      protocol: TCP
      port: 80              # Puerto del Service
      targetPort: 8080      # Puerto del Pod
  type: ClusterIP           # Tipo de Service
```

#### Flujo de Comunicación

```
1. Cliente hace petición a Service
   ↓
   curl http://my-service:80

2. DNS resuelve a ClusterIP
   ↓
   my-service → 10.96.0.10

3. kube-proxy intercepta tráfico
   ↓
   iptables/IPVS rules

4. Selecciona un Endpoint (Pod)
   ↓
   Balanceo: Pod-1, Pod-2, o Pod-3

5. NAT hacia targetPort del Pod
   ↓
   10.1.2.3:8080
```

---

### 3. Tipos de Services

#### Comparativa Rápida

| Tipo | Alcance | IP Externa | Puerto | Caso de Uso |
|------|---------|------------|--------|-------------|
| **ClusterIP** | Interno | No | N/A | Comunicación entre microservicios |
| **NodePort** | Interno + Externo | No (usa IP nodo) | 30000-32767 | Testing, acceso externo simple |
| **LoadBalancer** | Interno + Externo | Sí | Cualquiera | Producción en cloud (AWS, GCP, Azure) |
| **ExternalName** | Interno | N/A | N/A | Redirigir a servicios externos vía DNS |

#### Diagrama de Tipos de Services

```
┌─────────────────────────────────────────────────────────────┐
│                     CLUSTER KUBERNETES                      │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    ClusterIP                         │   │
│  │  IP: 10.96.0.10 (solo interna)                       │   │
│  │  ├─> Pod-1: 10.1.2.3:8080                            │   │
│  │  ├─> Pod-2: 10.1.2.4:8080                            │   │
│  │  └─> Pod-3: 10.1.2.5:8080                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↑                                  │
│                    Solo accesible                           │
│                  dentro del cluster                         │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    NodePort                          │   │
│  │  ClusterIP: 10.96.0.20                               │   │
│  │  NodePort: 30080 (en cada nodo)                      │   │
│  │                                                      │   │
│  │  Node-1 (IP: 192.168.1.10:30080) ──┐                 │   │
│  │  Node-2 (IP: 192.168.1.11:30080) ──┼─> Pods          │   │
│  │  Node-3 (IP: 192.168.1.12:30080) ──┘                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↑                                  │
│               Accesible desde fuera                         │
│              <NodeIP>:<NodePort>                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                          ↑
                          │
┌─────────────────────────┴──────────────────────────┐
│                 LoadBalancer                       │
│  IP Pública: 203.0.113.25                          │
│  ├─> NodePort: 30080                               │
│  │   ├─> ClusterIP: 10.96.0.30                     │
│  │   │   ├─> Pod-1                                 │
│  │   │   ├─> Pod-2                                 │
│  │   │   └─> Pod-3                                 │
└────────────────────────────────────────────────────┘
        ↑
  Accesible desde
    Internet
```

---

### 4. Service ClusterIP (Por Defecto)

#### Descripción

- **Tipo por defecto** si no se especifica `type`
- **IP interna** solo accesible dentro del cluster
- **Uso principal**: Comunicación entre microservicios

#### Ejemplo Básico

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
    tier: api
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP  # Opcional, es el valor por defecto
```

#### ¿Cómo Funciona?

1. **Creación**: Kubernetes asigna una IP del rango de ClusterIP (ej: `10.96.0.0/12`)
2. **DNS**: Se crea automáticamente un registro DNS
   - Mismo namespace: `backend-service`
   - Otros namespaces: `backend-service.default.svc.cluster.local`
3. **Endpoints**: Controlador crea objeto Endpoints con IPs de Pods que coinciden con selector
4. **kube-proxy**: Configura reglas iptables/IPVS para balanceo de carga

#### Acceso al Service

**Desde un Pod en el mismo namespace**:
```bash
curl http://backend-service:80
```

**Desde un Pod en otro namespace**:
```bash
curl http://backend-service.default.svc.cluster.local:80
```

**Desde un Pod con variables de entorno** (legacy):
```bash
echo $BACKEND_SERVICE_SERVICE_HOST  # 10.96.0.10
echo $BACKEND_SERVICE_SERVICE_PORT  # 80
```

#### Ver también
- [Ejemplo: service-clusterip-basic.yaml](ejemplos/01-clusterip/service-clusterip-basic.yaml)
- [Ejemplo: service-multi-port.yaml](ejemplos/01-clusterip/service-multi-port.yaml)

---

### 5. Endpoints

#### ¿Qué son los Endpoints?

Los **Endpoints** son objetos de Kubernetes que contienen la lista de direcciones IP de los Pods que coinciden con el selector de un Service.

#### Relación Service ↔ Endpoints ↔ Pods

```
Service (my-service)
    ↓ (selector: app=backend)
Endpoints (my-service)
    ├── addresses:
    │   ├── ip: 10.1.2.3
    │   ├── ip: 10.1.2.4
    │   └── ip: 10.1.2.5
    └── ports:
        └── port: 8080
             ↓
Pods con label app=backend
    ├── Pod-1: 10.1.2.3:8080
    ├── Pod-2: 10.1.2.4:8080
    └── Pod-3: 10.1.2.5:8080
```

#### Ver Endpoints

```bash
# Listar todos los Endpoints
kubectl get endpoints

# Ver Endpoints de un Service específico
kubectl get endpoints my-service

# Ver detalles en YAML
kubectl get endpoints my-service -o yaml
```

**Output ejemplo**:
```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: my-service
subsets:
  - addresses:
      - ip: 10.1.2.3
        nodeName: node-1
        targetRef:
          kind: Pod
          name: backend-pod-1
          namespace: default
      - ip: 10.1.2.4
        nodeName: node-2
        targetRef:
          kind: Pod
          name: backend-pod-2
          namespace: default
    ports:
      - name: http
        port: 8080
        protocol: TCP
```

#### Endpoints Automáticos vs Manuales

**Automáticos** (con selector):
- Kubernetes crea y actualiza Endpoints automáticamente
- Se sincronizan con los Pods que coinciden con el selector

**Manuales** (sin selector):
```yaml
# Service sin selector
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306

---
# Endpoints manuales
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db  # Mismo nombre que el Service
subsets:
  - addresses:
      - ip: 192.168.1.100  # IP externa (ej: base de datos)
    ports:
      - port: 3306
```

**Uso**: Servicios externos, bases de datos legacy, migración gradual a Kubernetes.

#### Ver también
- [Ejemplo: service-manual-endpoints.yaml](ejemplos/05-endpoints/service-manual-endpoints.yaml)
- [Laboratorio 1: Endpoints en detalle](laboratorios/lab-01-clusterip-basics.md#ejercicio-2-explorar-endpoints)

---

### ✅ Checkpoint 2: ClusterIP y Endpoints

Verifica tu comprensión antes de avanzar a exposición externa:

**Preguntas de Autoevaluación**:
1. ¿Cuál es la diferencia entre el `port` y el `targetPort` en un Service?
2. ¿Cómo sabe un Service qué Pods debe incluir en sus Endpoints?
3. ¿Qué sucede si cambias el selector de un Service existente?
4. ¿Cuándo necesitarías crear Endpoints manuales (sin selector)?
5. ¿Qué comando usarías para verificar que un Service tiene Endpoints configurados?

**Respuestas esperadas**:
<details>
<summary>Ver respuestas</summary>

1. **`port`**: Puerto expuesto por el Service (donde escucha el Service). **`targetPort`**: Puerto donde escucha el contenedor en el Pod. Ejemplo: Service en puerto 80 → redirige a puerto 8080 del Pod.

2. El Service usa el **`selector`** para encontrar Pods. El controlador de Endpoints busca todos los Pods con labels que coincidan con el selector y crea/actualiza el objeto Endpoints automáticamente.

3. Kubernetes actualiza los Endpoints inmediatamente. Los Pods que cumplan el nuevo selector se agregan; los que ya no cumplan se eliminan de los Endpoints.

4. Endpoints manuales se usan para:
   - Servicios externos (bases de datos fuera de K8s)
   - Migración gradual a Kubernetes
   - Servicios legacy que no son Pods

5. `kubectl get endpoints <service-name>` o `kubectl describe service <service-name>` (ver sección Endpoints)
</details>

**Ejercicio Práctico**:
```bash
# Crea un Deployment y Service
kubectl create deployment nginx --image=nginx --replicas=3
kubectl expose deployment nginx --port=80 --target-port=80

# Verifica la cadena completa
kubectl get pods -o wide -l app=nginx        # Ver IPs de Pods
kubectl get svc nginx                        # Ver ClusterIP
kubectl get endpoints nginx                  # Ver mapping
kubectl describe svc nginx                   # Ver todo junto

# Test desde otro Pod
kubectl run test --image=busybox -it --rm -- wget -O- http://nginx
```

**¿Listo?** Si entiendes ClusterIP y Endpoints, ¡continuemos con exposición externa!

---

### 6. Service NodePort

#### Descripción

- Expone el Service en **cada nodo del cluster** en un puerto estático
- Rango de puertos: **30000-32767** (configurable)
- Crea automáticamente un ClusterIP
- **Uso**: Testing, desarrollo, acceso externo simple

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-nodeport
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
    - name: http
      protocol: TCP
      port: 80          # Puerto del Service (interno)
      targetPort: 8080  # Puerto del Pod
      nodePort: 30080   # Puerto en cada nodo (30000-32767)
```

#### ¿Cómo Funciona?

```
1. Petición externa
   ↓
   http://192.168.1.10:30080

2. Llega a NodePort en cualquier nodo
   ↓
   Node-1, Node-2, o Node-3:30080

3. kube-proxy redirige a ClusterIP
   ↓
   10.96.0.20:80

4. Balanceo a Pod backend
   ↓
   Pod en cualquier nodo del cluster
```

#### Acceso

**Desde fuera del cluster**:
```bash
# Con IP de cualquier nodo
curl http://192.168.1.10:30080
curl http://192.168.1.11:30080
curl http://192.168.1.12:30080

# Todos los nodos redirigen al mismo Service
```

**Desde dentro del cluster** (funciona igual que ClusterIP):
```bash
curl http://webapp-nodeport:80
```

#### Asignación de NodePort

**Automática**:
```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
      # nodePort no especificado → Kubernetes asigna uno aleatorio
```

**Manual**:
```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080  # Asignación manual (debe estar libre)
```

#### Limitaciones

- ❌ Solo un Service por puerto (30000-32767)
- ❌ Rango de puertos limitado
- ❌ Si cambias IPs de nodos, debes actualizar clientes
- ❌ No hay balanceo externo real

#### Ver también
- [Ejemplo: service-nodeport-basic.yaml](ejemplos/02-nodeport/service-nodeport-basic.yaml)
- [Laboratorio 2: NodePort en acción](laboratorios/lab-02-nodeport-loadbalancer.md#ejercicio-1-crear-service-nodeport)

---

### 7. Service LoadBalancer

#### Descripción

- Crea un **balanceador de carga externo** (en cloud providers)
- Asigna una **IP pública** automáticamente
- Crea automáticamente NodePort y ClusterIP
- **Uso**: Producción en AWS, GCP, Azure, etc.

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: webapp
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 8080
```

#### ¿Cómo Funciona?

```
1. Kubernetes solicita LoadBalancer al cloud provider
   ↓
   AWS ELB / GCP Load Balancer / Azure LB

2. Cloud crea balanceador con IP pública
   ↓
   IP Pública: 203.0.113.25

3. Balanceador dirige a NodePort
   ↓
   NodePort automático (ej: 31234)

4. NodePort redirige a ClusterIP
   ↓
   ClusterIP: 10.96.0.30:80

5. Balanceo entre Pods
   ↓
   Pods backend
```

#### Ver Estado del LoadBalancer

```bash
kubectl get service webapp-loadbalancer
```

**Output**:
```
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
webapp-loadbalancer    LoadBalancer   10.96.0.30     203.0.113.25     80:31234/TCP   2m
```

**Campos importantes**:
- `CLUSTER-IP`: IP interna (10.96.0.30)
- `EXTERNAL-IP`: IP pública del balanceador (203.0.113.25)
- `PORT(S)`: `80:31234/TCP` → Puerto 80 mapeado a NodePort 31234

#### Acceso

**Desde Internet**:
```bash
curl http://203.0.113.25
```

**Desde dentro del cluster**:
```bash
curl http://webapp-loadbalancer:80
```

#### Configuración Específica por Cloud Provider

**AWS (ELB)**:
```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # Network Load Balancer
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"  # Interno
```

**GCP**:
```yaml
metadata:
  annotations:
    cloud.google.com/load-balancer-type: "Internal"  # LB interno
```

**Azure**:
```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```

#### Limitaciones

- ❌ Solo funciona en cloud providers soportados
- ❌ Costo adicional por balanceador (cada Service = 1 LB)
- ❌ En clusters locales (minikube, kind) queda en `<pending>`

#### Ver también
- [Ejemplo: service-loadbalancer-basic.yaml](ejemplos/03-loadbalancer/service-loadbalancer-basic.yaml)
- [Ejemplo: service-loadbalancer-annotations.yaml](ejemplos/03-loadbalancer/service-loadbalancer-annotations.yaml)
- [Laboratorio 2: NodePort y LoadBalancer](laboratorios/lab-02-nodeport-loadbalancer.md)

---

### ✅ Checkpoint 3: Exposición Externa

Evalúa tu dominio de NodePort y LoadBalancer:

**Preguntas de Autoevaluación**:
1. ¿Cuál es el rango de puertos válido para NodePort? ¿Por qué existe ese rango?
2. ¿Qué sucede "bajo el capó" cuando creas un Service de tipo LoadBalancer?
3. Si tienes un NodePort en el puerto 30080, ¿puedes acceder al Service desde cualquier nodo del cluster?
4. ¿Por qué un LoadBalancer queda en `<pending>` en minikube? ¿Cómo lo solucionarías?
5. Compara: ¿Cuándo usarías NodePort vs LoadBalancer en producción?

**Respuestas esperadas**:
<details>
<summary>Ver respuestas</summary>

1. **Rango**: 30000-32767. Este rango existe para evitar conflictos con puertos del sistema (0-1023) y aplicaciones comunes (1024-29999). Es configurable en la API server.

2. LoadBalancer crea **tres capas**:
   - ClusterIP (interno)
   - NodePort automático (para que LB pueda llegar)
   - Solicitud al cloud provider para crear balanceador externo con IP pública

3. **Sí**, el tráfico llega a cualquier nodo:30080 y kube-proxy lo redirige internamente a Pods en cualquier nodo. Todos los nodos escuchan en el NodePort.

4. Minikube no tiene cloud provider. Soluciones:
   - `minikube tunnel` (simula LoadBalancer)
   - Usar MetalLB (bare-metal load balancer)
   - Cambiar a NodePort para testing local

5. **NodePort**: Solo para testing/dev o clusters sin cloud provider. **LoadBalancer**: Producción en cloud (AWS/GCP/Azure) - proporciona IP pública, health checks, distribución de tráfico real.
</details>

**Comparación Rápida**:
| Aspecto | ClusterIP | NodePort | LoadBalancer |
|---------|-----------|----------|--------------|
| Acceso | Solo interno | Interno + Externo (IP nodo) | Interno + Externo (IP pública) |
| Producción | ✅ Microservicios | ❌ Solo dev/test | ✅ Apps públicas |
| Costo | Gratis | Gratis | 💰 Costo por LB |
| Complejidad | Baja | Media | Media-Alta |

**Mini-Lab**:
```bash
# Experimenta con los 3 tipos
kubectl create deployment web --image=nginx --replicas=2

# 1. ClusterIP (interno)
kubectl expose deployment web --port=80 --name=web-clusterip

# 2. NodePort (externo)
kubectl expose deployment web --port=80 --type=NodePort --name=web-nodeport

# 3. LoadBalancer (si tienes cloud o minikube tunnel)
kubectl expose deployment web --port=80 --type=LoadBalancer --name=web-lb

# Compara
kubectl get svc
```

**Continúa cuando domines la diferencia entre los 3 tipos principales!**

---

### 8. Service ExternalName

#### Descripción

- Mapea un Service a un **nombre DNS externo**
- No crea proxy ni IP propia
- Usa **CNAME** DNS record
- **Uso**: Redirigir a servicios externos (bases de datos, APIs externas)

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-api
spec:
  type: ExternalName
  externalName: api.example.com  # FQDN externo
```

#### ¿Cómo Funciona?

```
1. Pod consulta DNS interno
   ↓
   curl http://external-api.default.svc.cluster.local

2. DNS retorna CNAME record
   ↓
   external-api → api.example.com

3. Cliente resuelve DNS externo
   ↓
   api.example.com → 203.0.113.50

4. Conexión directa a servicio externo
   ↓
   http://203.0.113.50
```

#### Casos de Uso

**1. Migración gradual a Kubernetes**:
```yaml
# Fase 1: Base de datos externa
apiVersion: v1
kind: Service
metadata:
  name: database
spec:
  type: ExternalName
  externalName: legacy-db.company.com

# Fase 2: Migrar a Kubernetes (cambiar type, mantener nombre)
apiVersion: v1
kind: Service
metadata:
  name: database  # Mismo nombre!
spec:
  type: ClusterIP
  selector:
    app: postgres
```

**2. Diferentes entornos**:
```yaml
# Production
apiVersion: v1
kind: Service
metadata:
  name: payment-api
  namespace: production
spec:
  type: ExternalName
  externalName: payment.prod.company.com

---
# Development
apiVersion: v1
kind: Service
metadata:
  name: payment-api
  namespace: development
spec:
  type: ExternalName
  externalName: payment-sandbox.company.com
```

#### Limitaciones

- ❌ No hay balanceo de carga
- ❌ No hay verificación de salud (health checks)
- ❌ Solo funciona con protocolos que usan nombres de host
- ⚠️ Problemas con TLS/SSL si el hostname difiere

#### Ver también
- [Ejemplo: service-externalname-basic.yaml](ejemplos/04-externalname/service-externalname-basic.yaml)
- [Laboratorio 3: ExternalName avanzado](laboratorios/lab-03-advanced-services.md#ejercicio-1-externalname-service)

---

### 9. Services Headless

#### Descripción

Un Service **headless** es un Service sin ClusterIP (`clusterIP: None`). No tiene balanceo de carga; en su lugar, retorna **todas las IPs de los Pods** directamente.

#### ¿Por Qué Usar Headless?

- 🎯 **Control directo**: Aplicaciones necesitan conectarse a Pods específicos
- 🎯 **StatefulSets**: Cada Pod tiene identidad única (ej: bases de datos)
- 🎯 **Service discovery**: Obtener lista de todos los Pods

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: database-headless
spec:
  clusterIP: None  # ¡Headless!
  selector:
    app: database
  ports:
    - name: mysql
      protocol: TCP
      port: 3306
      targetPort: 3306
```

#### Resolución DNS

**Service normal (ClusterIP)**:
```bash
nslookup my-service.default.svc.cluster.local
# Retorna: 10.96.0.10 (IP del Service)
```

**Service headless**:
```bash
nslookup database-headless.default.svc.cluster.local
# Retorna: Lista de IPs de TODOS los Pods
# 10.1.2.3
# 10.1.2.4
# 10.1.2.5
```

#### Con StatefulSet

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
    - port: 3306

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql  # Usa el headless Service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
```

**DNS de cada Pod**:
```
mysql-0.mysql.default.svc.cluster.local → 10.1.2.3
mysql-1.mysql.default.svc.cluster.local → 10.1.2.4
mysql-2.mysql.default.svc.cluster.local → 10.1.2.5
```

#### Ver también
- [Ejemplo: service-headless-statefulset.yaml](ejemplos/06-headless/service-headless-statefulset.yaml)
- [Laboratorio 3: Services headless](laboratorios/lab-03-advanced-services.md#ejercicio-2-headless-services)

---

### 10. Descubrimiento de Servicios

Kubernetes ofrece dos métodos principales para descubrir Services:

#### 10.1 DNS (Recomendado)

**CoreDNS** (addon estándar) crea registros DNS automáticamente para cada Service.

**Formato DNS**:
```
<service-name>.<namespace>.svc.<cluster-domain>
```

**Ejemplo**:
```
my-service.default.svc.cluster.local
│         │       │   │
│         │       │   └── Dominio del cluster (por defecto)
│         │       └────── Sufijo de Service
│         └────────────── Namespace
└──────────────────────── Nombre del Service
```

**Shortcuts**:
- Mismo namespace: `my-service`
- Mismo namespace con puerto: `my-service:80`
- Otro namespace: `my-service.other-namespace`
- FQDN completo: `my-service.default.svc.cluster.local`

**Ejemplo práctico**:
```bash
# Desde un Pod en namespace "default"
curl http://backend-service:80

# Desde un Pod en namespace "frontend" accediendo a "default"
curl http://backend-service.default:80

# FQDN completo (siempre funciona)
curl http://backend-service.default.svc.cluster.local:80
```

#### 10.2 Variables de Entorno (Legacy)

Cuando un Pod se crea, Kubernetes inyecta variables de entorno para **todos los Services existentes** en el mismo namespace.

**Formato**:
```bash
{SVCNAME}_SERVICE_HOST=<clusterIP>
{SVCNAME}_SERVICE_PORT=<port>
```

**Ejemplo**:
```bash
# Service "backend-service" en puerto 80
BACKEND_SERVICE_SERVICE_HOST=10.96.0.10
BACKEND_SERVICE_SERVICE_PORT=80

# Compatible con Docker links
BACKEND_SERVICE_PORT=tcp://10.96.0.10:80
BACKEND_SERVICE_PORT_80_TCP=tcp://10.96.0.10:80
BACKEND_SERVICE_PORT_80_TCP_PROTO=tcp
BACKEND_SERVICE_PORT_80_TCP_PORT=80
BACKEND_SERVICE_PORT_80_TCP_ADDR=10.96.0.10
```

**Limitación importante**:
⚠️ Las variables solo se inyectan para Services que **existen ANTES** de crear el Pod. No se actualizan dinámicamente.

**Orden correcto**:
```bash
# 1. Crear Service primero
kubectl apply -f service.yaml

# 2. Luego crear Pods/Deployment
kubectl apply -f deployment.yaml
```

**Orden incorrecto (no funciona)**:
```bash
# 1. Crear Pods primero
kubectl apply -f deployment.yaml  # ❌ Variables no disponibles

# 2. Luego crear Service
kubectl apply -f service.yaml     # Pods ya creados, no tienen variables
```

**Recomendación**: Usar **DNS en lugar de variables de entorno**.

---

### 11. kube-proxy y Modos de Proxy

#### ¿Qué es kube-proxy?

**kube-proxy** es un componente que corre en cada nodo y gestiona las reglas de red para los Services. Implementa la VIP (Virtual IP) del Service.

#### Modos de Operación

**1. Userspace** (Deprecated)
```
Cliente → iptables → kube-proxy (userspace) → Pod
```
- ❌ Lento (context switching)
- ❌ Obsoleto desde Kubernetes 1.2

**2. iptables** (Default en muchas distros)
```
Cliente → iptables rules → Pod (directo)
```
- ✅ Más rápido que userspace
- ✅ No requiere kube-proxy en data path
- ❌ Escala mal con >5000 Services (reglas lineales)
- ❌ No tiene health checks activos

**3. IPVS** (Recomendado)
```
Cliente → IPVS rules → Pod
```
- ✅ Muy rápido (hash table en kernel)
- ✅ Escala a decenas de miles de Services
- ✅ Algoritmos de balanceo avanzados:
  - `rr`: Round-robin
  - `lc`: Least connections
  - `sh`: Source hashing
  - `dh`: Destination hashing
- ✅ Health checks integrados
- ⚠️ Requiere módulos kernel IPVS

#### Verificar Modo Actual

```bash
# Ver configuración de kube-proxy
kubectl -n kube-system get configmap kube-proxy -o yaml | grep mode
```

**Output**:
```yaml
mode: "ipvs"  # o "iptables" o "userspace"
```

#### Configurar Modo IPVS

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-proxy
  namespace: kube-system
data:
  config.conf: |
    mode: "ipvs"
    ipvs:
      scheduler: "rr"  # round-robin
```

**Cargar módulos kernel** (en cada nodo):
```bash
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack
```

#### Ver también
- [Documentación oficial: kube-proxy](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/)

---

### 12. Session Affinity (Afinidad de Sesión)

#### Descripción

Por defecto, los Services balancean tráfico **aleatoriamente** entre Pods. Session Affinity permite mantener conexiones del **mismo cliente** al **mismo Pod**.

#### Configuración

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-service
spec:
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 8080
  sessionAffinity: ClientIP  # "None" (default) o "ClientIP"
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 horas (default: 10800)
```

#### ¿Cómo Funciona?

**Sin Session Affinity**:
```
Cliente (IP: 203.0.113.10)
  ├─> Request 1 → Pod-1
  ├─> Request 2 → Pod-3
  ├─> Request 3 → Pod-2
  └─> Request 4 → Pod-1
```

**Con Session Affinity (ClientIP)**:
```
Cliente (IP: 203.0.113.10)
  ├─> Request 1 → Pod-2
  ├─> Request 2 → Pod-2  ← Mismo Pod
  ├─> Request 3 → Pod-2  ← Mismo Pod
  └─> Request 4 → Pod-2  ← Mismo Pod (hasta timeout)
```

#### Casos de Uso

- ✅ **Aplicaciones con estado de sesión** (session storage local)
- ✅ **WebSockets** (conexiones persistentes)
- ✅ **Carritos de compra** (sin Redis/memcached)
- ❌ **No usar** si la app es stateless (mejor balanceo)

#### Limitaciones

- ⚠️ Basado en **IP origen** (no cookies/headers)
- ⚠️ NAT puede agrupar múltiples clientes en una IP
- ⚠️ No funciona bien detrás de proxies/load balancers

---

### 13. ExternalTrafficPolicy

#### Descripción

Controla cómo se enruta el tráfico **externo** (NodePort, LoadBalancer) a los Pods.

#### Valores

**1. Cluster (default)**:
```yaml
spec:
  type: NodePort
  externalTrafficPolicy: Cluster  # Default
```

**Comportamiento**:
- Tráfico puede ir a **cualquier nodo**
- Luego se redirige a **cualquier Pod** (incluso en otros nodos)
- ✅ Balanceo uniforme
- ❌ IP origen del cliente se pierde (SNAT)
- ❌ Hop adicional si Pod está en otro nodo

**2. Local**:
```yaml
spec:
  type: NodePort
  externalTrafficPolicy: Local
```

**Comportamiento**:
- Tráfico solo va a Pods **en el mismo nodo**
- ✅ Preserva IP origen del cliente
- ✅ Sin hop adicional (mejor latencia)
- ❌ Balanceo desigual si Pods no están distribuidos uniformemente
- ⚠️ Si un nodo no tiene Pods, el tráfico falla

#### Comparación Visual

**Cluster Policy**:
```
External LB (203.0.113.25)
    ↓
Node-1 (NodePort 30080)
    ├─> Pod en Node-1 ✅
    ├─> Pod en Node-2 ✅ (hop extra)
    └─> Pod en Node-3 ✅ (hop extra)

IP vista por Pod: IP del nodo (SNAT)
```

**Local Policy**:
```
External LB (203.0.113.25)
    ↓
Node-1 (NodePort 30080)
    └─> Pod en Node-1 SOLO ✅

Node-2 (NodePort 30080)
    └─> Pod en Node-2 SOLO ✅

IP vista por Pod: 203.0.113.25 (cliente real) ✅
```

#### Caso de Uso: Logging de IPs Reales

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local  # Preservar IP origen
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 8080
```

**Logs en Pod** (con `Local`):
```
2025-11-09 10:30:15 [INFO] Request from 203.0.113.45 - GET /api/users
```

**Logs en Pod** (con `Cluster`):
```
2025-11-09 10:30:15 [INFO] Request from 10.244.1.1 - GET /api/users
                                          ↑ IP del nodo, no del cliente
```

#### Ver también
- [Ejemplo: service-external-traffic-policy.yaml](ejemplos/07-produccion/service-external-traffic-policy.yaml)

---

### 14. Puertos Múltiples

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: webapp
  ports:
    - name: http      # ¡Nombres obligatorios con múltiples puertos!
      protocol: TCP
      port: 80
      targetPort: 8080
    - name: https
      protocol: TCP
      port: 443
      targetPort: 8443
    - name: metrics
      protocol: TCP
      port: 9090
      targetPort: 9090
```

**Regla importante**: Con múltiples puertos, **todos deben tener nombre**.

#### targetPort con Nombres

```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  template:
    spec:
      containers:
      - name: app
        ports:
        - name: http-port    # Nombre del puerto
          containerPort: 8080
        - name: https-port
          containerPort: 8443

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  selector:
    app: webapp
  ports:
    - name: http
      port: 80
      targetPort: http-port   # Referencia por nombre ✅
    - name: https
      port: 443
      targetPort: https-port  # Referencia por nombre ✅
```

**Ventaja**: Cambiar puerto del contenedor sin modificar Service.

---

### ✅ Checkpoint 4: Configuraciones Avanzadas

Verifica tu dominio de características avanzadas:

**Preguntas de Autoevaluación**:
1. ¿Qué es un Service headless y cuándo lo usarías?
2. Explica la diferencia entre Session Affinity "None" y "ClientIP"
3. ¿Cuál es el beneficio de usar `externalTrafficPolicy: Local`? ¿Qué desventaja tiene?
4. ¿Cómo afecta el modo de kube-proxy (iptables vs IPVS) al performance?
5. ¿Puedes tener múltiples Services apuntando a los mismos Pods?

**Respuestas esperadas**:
<details>
<summary>Ver respuestas</summary>

1. **Headless Service**: `clusterIP: None`. No tiene balanceo automático. DNS retorna **todas las IPs de Pods** directamente. Uso: StatefulSets (bases de datos), cuando la app necesita conectarse a Pods específicos.

2. **None** (default): Cada request se balancea aleatoriamente entre Pods. **ClientIP**: Requests de la misma IP origen van siempre al mismo Pod (hasta timeout). Útil para sesiones stateful.

3. **Beneficio de Local**: Preserva IP origen del cliente (logs reales), sin hop extra (mejor latencia). **Desventaja**: Balanceo desigual si Pods no están distribuidos uniformemente; si un nodo no tiene Pods, el tráfico falla.

4. **iptables**: Reglas lineales (lento con >5000 Services). **IPVS**: Hash table en kernel (muy rápido), algoritmos avanzados de balanceo (rr, lc, sh), soporta decenas de miles de Services.

5. **Sí**, múltiples Services pueden usar el mismo selector. Casos comunes:
   - Service interno (ClusterIP) + externo (LoadBalancer)
   - Diferentes puertos para diferentes propósitos
   - Servicios en múltiples namespaces
</details>

**Ejercicio Mental**:
```
Escenario: Base de datos MongoDB con 3 réplicas (primary + 2 secondary)
- ¿Qué tipo de Service usarías? ¿Por qué?
- ¿Necesitas un Service headless?
- ¿Usarías StatefulSet o Deployment?
```

<details>
<summary>Respuesta sugerida</summary>

- **Headless Service** para acceso directo a cada replica
- **StatefulSet** para identidad de Pod persistente (mongo-0, mongo-1, mongo-2)
- DNS: `mongo-0.mongo.default.svc.cluster.local` para conectarse al primary
- Possibly un segundo Service ClusterIP para reads balanceados
</details>

**Si dominas estos conceptos avanzados, ¡estás listo para best practices de producción!**

---

### 15. Mejores Prácticas

#### 15.1 Naming Conventions

```yaml
# ✅ BIEN: Nombres descriptivos
apiVersion: v1
kind: Service
metadata:
  name: backend-api-service  # Claro y específico
  labels:
    app: backend
    component: api
    tier: backend
    environment: production

# ❌ MAL: Nombres genéricos
metadata:
  name: service1  # ¿Qué hace?
  name: svc       # Demasiado corto
```

#### 15.2 Labels y Selectors

```yaml
# ✅ BIEN: Labels consistentes
spec:
  selector:
    app: webapp
    version: v1.2.0
    tier: frontend
    environment: production

# ❌ MAL: Selectores muy amplios
spec:
  selector:
    app: webapp  # Podría matchear múltiples versiones
```

#### 15.3 Health Checks

**SIEMPRE** usar readiness probes en Pods para que solo reciban tráfico cuando estén listos:

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        readinessProbe:  # ¡Crítico para Services!
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
```

**Sin readiness probe**: Service enviará tráfico a Pods no listos → errores 500.

#### 15.4 Tipo de Service Apropiado

| Escenario | Tipo Recomendado |
|-----------|------------------|
| Comunicación interna entre microservicios | `ClusterIP` |
| Testing local, desarrollo | `NodePort` |
| Producción en cloud (AWS, GCP, Azure) | `LoadBalancer` |
| Redirección a servicio externo | `ExternalName` |
| Base de datos stateful | `Headless` + `StatefulSet` |

#### 15.5 Production Checklist

```yaml
apiVersion: v1
kind: Service
metadata:
  name: production-api
  labels:
    app: api
    tier: backend
    environment: production
  annotations:
    # Prometheus monitoring
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
spec:
  type: LoadBalancer
  selector:
    app: api
    version: v2.1.0  # Version específica
  ports:
    - name: https
      protocol: TCP
      port: 443
      targetPort: 8443
  sessionAffinity: ClientIP  # Si se necesita
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  externalTrafficPolicy: Local  # Preservar IPs cliente
```

#### 15.6 Seguridad

**1. Network Policies**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: frontend  # Solo frontend puede acceder
      ports:
      - protocol: TCP
        port: 8080
```

**2. TLS/SSL**:
- No terminar TLS en Service (es Layer 4)
- Usar Ingress para TLS termination
- O configurar TLS en el Pod directamente

**3. LoadBalancer Source Ranges**:
```yaml
spec:
  type: LoadBalancer
  loadBalancerSourceRanges:
    - "203.0.113.0/24"  # Solo esta IP range puede acceder
```

---

### 16. Troubleshooting

#### 16.1 Service No Responde

**Síntoma**: `curl http://my-service` timeout o error de conexión.

**Diagnóstico**:

```bash
# 1. Verificar que el Service existe
kubectl get service my-service

# 2. Ver detalles
kubectl describe service my-service

# 3. Verificar Endpoints
kubectl get endpoints my-service

# Output esperado:
# NAME         ENDPOINTS                     AGE
# my-service   10.1.2.3:8080,10.1.2.4:8080   5m

# ❌ Si ENDPOINTS está vacío:
# NAME         ENDPOINTS   AGE
# my-service   <none>      5m
```

**Solución si Endpoints vacío**:

```bash
# Verificar selector del Service
kubectl get service my-service -o yaml | grep -A 5 selector

# Verificar labels de los Pods
kubectl get pods -l app=my-app --show-labels

# ¿Coinciden? Si no, corregir selector o labels
```

#### 16.2 DNS No Funciona

**Síntoma**: `nslookup my-service` falla.

**Diagnóstico**:

```bash
# 1. Verificar CoreDNS está corriendo
kubectl -n kube-system get pods -l k8s-app=kube-dns

# 2. Ver logs de CoreDNS
kubectl -n kube-system logs -l k8s-app=kube-dns

# 3. Test desde un Pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
/ # nslookup my-service
/ # nslookup my-service.default.svc.cluster.local
```

#### 16.3 LoadBalancer en `<pending>`

**Síntoma**:
```bash
kubectl get service
# EXTERNAL-IP en <pending>
```

**Causas**:
- ❌ Cluster local (minikube, kind) → No hay cloud provider
- ❌ Cloud provider mal configurado
- ❌ Cuotas de cloud excedidas

**Solución**:
```bash
# En clusters locales, usar minikube tunnel
minikube tunnel  # En otra terminal

# O usar MetalLB (bare-metal load balancer)
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
```

#### 16.4 Tráfico No Llega a Pods

**Síntoma**: Service existe, Endpoints OK, pero Pods no reciben tráfico.

**Diagnóstico**:

```bash
# 1. Verificar Pods están Ready
kubectl get pods -l app=my-app

# 2. Ver readiness probe
kubectl describe pod <pod-name> | grep -A 10 Readiness

# 3. Test directo al Pod (bypass Service)
kubectl port-forward pod/<pod-name> 8080:8080
curl http://localhost:8080

# 4. Ver reglas de kube-proxy
kubectl -n kube-system logs -l k8s-app=kube-proxy
```

**Comandos útiles**:

```bash
# Ver configuración de kube-proxy
kubectl -n kube-system get configmap kube-proxy -o yaml

# Restart kube-proxy
kubectl -n kube-system delete pod -l k8s-app=kube-proxy

# Ver iptables rules (en el nodo)
sudo iptables-save | grep my-service

# Ver IPVS rules (si usa IPVS)
sudo ipvsadm -Ln
```

---

### ✅ Checkpoint Final: Integración de Conceptos

**¡Felicitaciones!** Has completado todo el contenido teórico. Ahora integra lo aprendido:

**Desafío de Diseño**:

Imagina que debes diseñar la arquitectura de networking para una aplicación de e-commerce:
- **Frontend** (React SPA) - necesita acceso público
- **API Gateway** - enruta requests al backend
- **Auth Service** - autenticación de usuarios
- **Product Service** - gestión de productos
- **Order Service** - procesamiento de órdenes
- **PostgreSQL** - base de datos (StatefulSet, 3 replicas)
- **Redis** - cache

**Diseña**:
1. ¿Qué tipo de Service usarías para cada componente?
2. ¿Cuáles necesitan acceso externo vs interno?
3. ¿Cómo configurarías la base de datos?
4. ¿Qué configuraciones avanzadas aplicarías (session affinity, traffic policy, etc.)?

<details>
<summary>Solución Sugerida</summary>

```yaml
# Frontend - Acceso público
---
kind: Service
spec:
  type: LoadBalancer  # O Ingress en producción real
  sessionAffinity: ClientIP  # Mantener sesión del browser
  
# API Gateway - Interno + externo
---
kind: Service
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local  # Preservar IPs para logs
  
# Auth, Product, Order Services - Solo interno
---
kind: Service
spec:
  type: ClusterIP  # Default, comunicación interna
  
# PostgreSQL - Headless para identidad de Pods
---
kind: Service
spec:
  clusterIP: None  # Headless
  # Usado por StatefulSet
  # DNS: postgres-0.postgres, postgres-1.postgres, etc.

# Redis - ClusterIP simple
---
kind: Service
spec:
  type: ClusterIP
  # Cache distribuido
```

**Configuraciones adicionales**:
- NetworkPolicies para restringir tráfico
- Readiness/Liveness probes en todos los Pods
- Prometheus annotations para monitoring
- TLS en Ingress (no en Services)
</details>

**Checklist de Dominio del Módulo**:
- [ ] Puedo explicar los 4 tipos de Services y cuándo usar cada uno
- [ ] Entiendo la relación Service → Endpoints → Pods
- [ ] Sé configurar Services internos (ClusterIP) y externos (NodePort/LB)
- [ ] Puedo diagnosticar problemas comunes (Endpoints vacíos, DNS issues)
- [ ] Conozco configuraciones avanzadas (headless, session affinity, traffic policy)
- [ ] He completado los 3 laboratorios prácticos
- [ ] Puedo diseñar arquitecturas de Services para aplicaciones reales

**Si marcaste todo, ¡estás listo para el siguiente módulo!** 🎉

---

### 🎓 Evaluación de Conocimientos

### Preguntas de Repaso

1. **¿Cuál es la diferencia principal entre un Service ClusterIP y un NodePort?**
   <details><summary>Ver respuesta</summary>
   ClusterIP solo es accesible dentro del cluster (IP interna). NodePort expone el Service en cada nodo en un puerto estático (30000-32767), permitiendo acceso externo.
   </details>

2. **¿Qué pasa si elimino un Pod que está siendo usado por un Service?**
   <details><summary>Ver respuesta</summary>
   El controlador de Endpoints detecta el cambio y actualiza la lista de IPs. El Service automáticamente deja de enviar tráfico a ese Pod y balancea entre los Pods restantes. Si hay un ReplicaSet/Deployment, se creará un nuevo Pod que será agregado a los Endpoints.
   </details>

3. **¿Por qué un Service de tipo LoadBalancer queda en `<pending>` en minikube?**
   <details><summary>Ver respuesta</summary>
   Minikube no tiene un cloud provider que provisione balanceadores de carga externos. Soluciones: usar `minikube tunnel` o instalar MetalLB.
   </details>

4. **¿Cuándo usar un Service headless?**
   <details><summary>Ver respuesta</summary>
   Cuando necesitas conectarte a Pods específicos directamente (ej: StatefulSets con bases de datos), o cuando la aplicación necesita descubrir todas las IPs de los Pods para hacer su propio balanceo.
   </details>

5. **¿Qué es mejor para producción: externalTrafficPolicy Cluster o Local?**
   <details><summary>Ver respuesta</summary>
   Depende del caso. `Local` preserva la IP del cliente y evita hops extra (mejor latencia), pero puede causar balanceo desigual. `Cluster` tiene mejor balanceo pero pierde la IP origen. Para logging/security que requiere IP real, usa `Local`.
   </details>

### Ejercicios Prácticos

1. Crea un Deployment con 3 réplicas de nginx y expónlo con un Service ClusterIP
2. Modifica el Service anterior a NodePort y accede desde fuera del cluster
3. Crea un Service sin selector y Endpoints manuales apuntando a `8.8.8.8:53`
4. Implementa un StatefulSet de MongoDB con Service headless
5. Configura session affinity y verifica que funciona con múltiples requests

---

---

## Capítulo 11: Ingress y Acceso Externo

### ✅ Checkpoint 1: Conceptos Fundamentales de Ingress

Antes de continuar, verifica tu comprensión de los conceptos básicos:

### Preguntas de Autoevaluación

<details>
<summary>1. ¿Cuál es la principal ventaja de usar Ingress en lugar de múltiples Services de tipo LoadBalancer?</summary>

**Respuesta**:

**Ventaja principal: Reducción de costos y complejidad**

- **Sin Ingress** (N LoadBalancers):
  - Cada aplicación necesita su propio LoadBalancer Service
  - En cloud providers, cada LoadBalancer tiene un costo mensual (~$15-30/mes cada uno)
  - Con 10 aplicaciones = 10 LoadBalancers = $150-300/mes solo en balanceadores
  - Gestión distribuida: 10 IPs diferentes que administrar

- **Con Ingress** (1 LoadBalancer):
  - 1 solo LoadBalancer delante del Ingress Controller
  - Todas las aplicaciones comparten la misma IP pública
  - Routing inteligente basado en hostname o path
  - Ahorro: $135-270/mes con 10 aplicaciones
  - Gestión centralizada: configuración declarativa en recursos Ingress

**Otras ventajas**:
- Terminación TLS/HTTPS centralizada (certificados en un solo lugar)
- Configuraciones avanzadas (rate limiting, redirects, rewrite) en un punto
- Mejor observabilidad (logs y métricas centralizados)

</details>

<details>
<summary>2. ¿Cuál es la diferencia entre un "Ingress" (resource) y un "Ingress Controller"?</summary>

**Respuesta**:

Son dos componentes diferentes que trabajan juntos:

**Ingress (Resource)**:
- Es un objeto de la API de Kubernetes (tipo: `kind: Ingress`)
- Define **reglas de enrutamiento** declarativas (YAML)
- Especifica: qué hostnames, paths y servicios backend
- **No ejecuta nada por sí mismo** (es solo configuración)
- Ejemplo: "Envía tráfico de `app.example.com/api` al `api-service`"

**Ingress Controller**:
- Es un **Pod/Deployment** que corre en el cluster
- **Implementa** las reglas definidas en los recursos Ingress
- Es un reverse proxy real (nginx, Traefik, HAProxy, etc.)
- **Lee** todos los Ingress resources y configura el proxy
- **Recibe** el tráfico externo y lo enruta según las reglas

**Analogía**:
- **Ingress** = Receta de cocina (instrucciones)
- **Ingress Controller** = Cocinero (quien ejecuta la receta)

**En código**:
```yaml
# Ingress Resource (configuración)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

```bash
# Ingress Controller (Pod en ejecución)
kubectl get pods -n ingress-nginx
# NAME                                   READY   STATUS
# ingress-nginx-controller-xxx-xxx       1/1     Running
```

</details>

<details>
<summary>3. ¿Qué tipos de enrutamiento soporta Ingress?</summary>

**Respuesta**:

Ingress soporta **2 tipos principales** de enrutamiento:

**1. Host-based Routing (Enrutamiento por hostname)**:
- Enruta según el **dominio** en la petición HTTP
- Usa: Virtual hosting (múltiples apps en la misma IP)

```yaml
rules:
- host: app1.example.com    # → service1
- host: app2.example.com    # → service2
- host: api.example.com     # → api-service
```

**Caso de uso**: Diferentes aplicaciones con sus propios dominios.

**2. Path-based Routing (Enrutamiento por ruta/path)**:
- Enruta según la **ruta URL** en la petición
- Usa: Dividir funcionalidades de una app

```yaml
rules:
- http:
    paths:
    - path: /api      # → api-service
    - path: /web      # → web-service
    - path: /admin    # → admin-service
```

**Caso de uso**: Microservicios accesibles desde diferentes paths.

**Combinación** (host + path):
```yaml
rules:
- host: myapp.example.com
  http:
    paths:
    - path: /api          # → api-service
    - path: /frontend     # → web-service
```

**Tipos de PathType**:
- `Exact`: Coincidencia exacta (`/foo` ≠ `/foo/`)
- `Prefix`: Prefijo (`/foo` = `/foo`, `/foo/`, `/foo/bar`)
- `ImplementationSpecific`: Depende del controller

</details>

<details>
<summary>4. ¿Por qué necesitas un Service ClusterIP detrás de un Ingress si el Ingress ya enruta al Pod?</summary>

**Respuesta**:

**Ingress NO enruta directamente a Pods**, siempre enruta a **Services**.

**Razones arquitectónicas**:

1. **Abstracción y estabilidad**:
   - Pods son efímeros (sus IPs cambian)
   - Services proporcionan una IP estable
   - Ingress apunta a algo estable (Service), no a IPs cambiantes

2. **Balanceo de carga automático**:
   - Service balancea entre múltiples réplicas del Pod
   - Service mantiene Endpoints actualizados dinámicamente
   - Ingress delega el balanceo interno al Service

3. **Separación de responsabilidades**:
   - **Ingress**: Routing L7 (HTTP/HTTPS), virtual hosting, TLS
   - **Service**: Balanceo L4 (TCP/UDP), service discovery, health checks

**Flujo completo**:
```
Internet (HTTPS)
    ↓
LoadBalancer (IP pública)
    ↓
Ingress Controller Pod (nginx)
    ↓ (lee reglas de Ingress resource)
Service ClusterIP (IP interna estable: 10.96.0.50)
    ↓ (balancea entre Pods)
Pods backend (IPs efímeras: 10.1.2.3, 10.1.2.4, 10.1.2.5)
```

**YAML típico**:
```yaml
# Service (requerido)
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  type: ClusterIP  # Interno
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
---
# Ingress (apunta al Service, no a Pods)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service  # ← Service, NO Pods
            port:
              number: 80
```

**Sin Service**: Tendrías que actualizar manualmente el Ingress cada vez que cambian las IPs de los Pods → imposible de mantener.

</details>

### 🧪 Ejercicio Rápido

**Escenario**: Tienes 3 aplicaciones web que quieres exponer:
- Blog: `blog.mycompany.com`
- API: `api.mycompany.com`
- Admin: `admin.mycompany.com`

**Pregunta**: ¿Cuántos LoadBalancers de cloud necesitas?
- A) 3 LoadBalancers (1 por aplicación)
- B) 1 LoadBalancer (con Ingress)
- C) 0 LoadBalancers (uso NodePort)

<details>
<summary>Ver Respuesta</summary>

**Respuesta correcta: B) 1 LoadBalancer (con Ingress)**

**Arquitectura**:
```
                    Internet
                       ↓
    1 LoadBalancer (IP: 203.0.113.5)
                       ↓
          Ingress Controller
         /        |        \
blog.*.com   api.*.com   admin.*.com
    ↓            ↓            ↓
blog-svc     api-svc      admin-svc
    ↓            ↓            ↓
blog-pods    api-pods    admin-pods
```

**Ingress YAML**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: company-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: blog.mycompany.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
  - host: api.mycompany.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
  - host: admin.mycompany.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
```

**Ahorro de costos**:
- Sin Ingress: 3 LoadBalancers × $20/mes = $60/mes
- Con Ingress: 1 LoadBalancer × $20/mes = $20/mes
- **Ahorro: $40/mes (67%)**

</details>

### 🔗 Siguiente Paso

Si respondiste correctamente, estás listo para aprender cómo Ingress, Services e Ingress Controllers trabajan juntos. Continúa con la siguiente sección.

---

### ✅ Checkpoint 2: Ingress Controller e IngressClass

Verifica que comprendes cómo instalar y configurar Ingress Controllers:

### Preguntas de Autoevaluación

<details>
<summary>1. ¿Cuál es el comando para habilitar el addon de nginx ingress en minikube?</summary>

**Respuesta**:

```bash
# Habilitar el addon de ingress
minikube addons enable ingress

# Verificar que está habilitado
minikube addons list | grep ingress

# Ver los Pods del ingress controller
kubectl get pods -n ingress-nginx

# Debe mostrar:
# NAME                                   READY   STATUS
# ingress-nginx-controller-xxx-xxx       1/1     Running
```

**Proceso que ocurre**:
1. Minikube descarga e instala nginx ingress controller
2. Crea namespace `ingress-nginx`
3. Despliega:
   - Deployment: `ingress-nginx-controller`
   - Service: `ingress-nginx-controller` (tipo NodePort en minikube)
   - IngressClass: `nginx`
   - ConfigMaps y roles necesarios

**Verificación completa**:
```bash
# Ver todos los recursos creados
kubectl get all -n ingress-nginx

# Ver la IngressClass
kubectl get ingressclass
# NAME    CONTROLLER             PARAMETERS   AGE
# nginx   k8s.io/ingress-nginx   <none>       5m
```

**Para deshabilitarlo** (si necesitas):
```bash
minikube addons disable ingress
```

</details>

<details>
<summary>2. ¿Qué es una IngressClass y por qué es necesaria desde Kubernetes 1.18+?</summary>

**Respuesta**:

**IngressClass** es un recurso que actúa como **selector/identificador** para asociar recursos Ingress con Ingress Controllers específicos.

**¿Por qué existe?**

**Problema en Kubernetes < 1.18**:
- Solo podías tener 1 Ingress Controller en el cluster
- La selección era implícita (anotación `kubernetes.io/ingress.class`)
- Difícil tener múltiples controllers (nginx + Traefik + AWS ALB)

**Solución con IngressClass**:
- Recurso de API explícito (`kind: IngressClass`)
- Permite múltiples Ingress Controllers en el mismo cluster
- Cada Ingress especifica qué controller debe procesarlo
- Configuración centralizada del controller

**Componentes**:
```yaml
# 1. IngressClass (define el controller)
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx  # Identifica el controller

---
# 2. Ingress (usa la IngressClass)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  ingressClassName: nginx  # ← Especifica qué controller usar
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

**Casos de uso múltiples controllers**:
```bash
# Listar IngressClasses
kubectl get ingressclass

# Ejemplo con 3 controllers:
# NAME       CONTROLLER                     DEFAULT
# nginx      k8s.io/ingress-nginx           true
# traefik    traefik.io/ingress-controller  false
# alb        aws-alb-ingress-controller     false
```

**Ventaja**: Puedes tener:
- `nginx` para apps internas
- `traefik` para apps con requisitos especiales
- `alb` para integración con AWS

</details>

<details>
<summary>3. ¿Cómo verificar que el Ingress Controller está funcionando correctamente?</summary>

**Respuesta**:

**Verificación en 5 pasos**:

**1. Ver Pods del Ingress Controller**:
```bash
kubectl get pods -n ingress-nginx

# Debe estar en Running
# NAME                                   READY   STATUS    AGE
# ingress-nginx-controller-xxx-xxx       1/1     Running   5m
```

**2. Ver Service del Ingress Controller**:
```bash
kubectl get svc -n ingress-nginx

# En minikube (NodePort):
# NAME                       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
# ingress-nginx-controller   NodePort   10.96.123.45    <none>        80:32080/TCP,443:32443/TCP

# En cloud (LoadBalancer):
# NAME                       TYPE           EXTERNAL-IP     PORT(S)
# ingress-nginx-controller   LoadBalancer   203.0.113.5     80:32080/TCP,443:32443/TCP
```

**3. Verificar IngressClass**:
```bash
kubectl get ingressclass

# NAME    CONTROLLER             PARAMETERS   AGE
# nginx   k8s.io/ingress-nginx   <none>       5m
```

**4. Ver logs del controller** (si hay problemas):
```bash
# Logs en tiempo real
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --follow

# Buscar errores
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx | grep -i error
```

**5. Test de conectividad básico**:
```bash
# En minikube, obtener IP del nodo
minikube ip
# 192.168.49.2

# Hacer curl al puerto del controller
curl http://$(minikube ip):32080

# Si funciona, recibes respuesta (aunque sea 404)
# default backend - 404
```

**Troubleshooting común**:
```bash
# Si el Pod no está Running:
kubectl describe pod -n ingress-nginx <pod-name>

# Ver eventos del namespace
kubectl get events -n ingress-nginx --sort-by='.lastTimestamp'

# Verificar resources (CPU/RAM)
kubectl top pod -n ingress-nginx
```

**Señales de que funciona**:
✅ Pod en estado `Running` (1/1 READY)
✅ Service tiene `CLUSTER-IP` asignada
✅ Logs muestran "successfully acquired lease" o "watching for Ingress"
✅ curl al puerto del controller responde (aunque sea 404)

</details>

<details>
<summary>4. ¿Cuál es la diferencia entre instalar nginx ingress con Helm vs addon de minikube?</summary>

**Respuesta**:

Ambas opciones instalan el mismo nginx ingress controller, pero con diferentes niveles de control:

**Addon de Minikube** (`minikube addons enable ingress`):

✅ **Ventajas**:
- Setup inmediato (1 comando)
- Configuración optimizada para minikube
- Actualización automática con minikube
- Perfecto para desarrollo y aprendizaje
- Service tipo NodePort (accesible via `minikube ip`)

❌ **Desventajas**:
- Configuración limitada (defaults de minikube)
- No puedes personalizar valores fácilmente
- Versión específica atada a minikube
- No portable a otros clusters

```bash
# Instalación (1 comando)
minikube addons enable ingress

# No control sobre versión o configuración
```

**Helm Chart** (`helm install`):

✅ **Ventajas**:
- Control total sobre la configuración
- Puedes personalizar values.yaml (replicas, resources, etc.)
- Eliges la versión exacta del controller
- Portable (misma instalación en dev/staging/prod)
- Actualizaciones controladas

❌ **Desventajas**:
- Requires Helm instalado
- Más pasos de configuración
- Necesitas entender values.yaml
- En minikube, debes configurar Service correctamente

```bash
# Instalación con Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.watchIngressWithoutClass=true
```

**Comparación**:
| Aspecto | Minikube Addon | Helm Chart |
|---------|----------------|------------|
| Comandos | 1 | 3-4 |
| Configuración | Básica | Total |
| Para aprendizaje | ✅ Perfecto | ⚠️ Complejo |
| Para producción | ❌ No | ✅ Sí |
| Portabilidad | ❌ Solo minikube | ✅ Cualquier cluster |
| Versión control | ❌ Atada a minikube | ✅ Explícita |

**Recomendación**:
- **Aprendizaje/Dev**: Usa addon de minikube (más rápido)
- **Producción/Multi-env**: Usa Helm (más control)

</details>

### 🧪 Ejercicio Práctico

Verifica tu instalación de nginx ingress:

```bash
# 1. Verificar que el addon está habilitado
minikube addons list | grep ingress

# 2. Ver el Deployment
kubectl get deployment -n ingress-nginx

# 3. Ver los Pods (deben estar Running)
kubectl get pods -n ingress-nginx

# 4. Ver la IngressClass
kubectl get ingressclass

# 5. Test de conectividad
curl http://$(minikube ip):80

# Deberías ver:
# <html>
# <head><title>404 Not Found</title></head>
# ...
# (Respuesta 404 significa que el controller funciona)
```

**Si todo funciona**, estás listo para crear tu primer Ingress.

### 🔗 Siguiente Paso

Ahora que tienes el Ingress Controller funcionando, aprenderás a crear recursos Ingress con diferentes tipos de routing.

---

### ✅ Checkpoint 3: Routing y TLS

Verifica tu comprensión de routing y configuración HTTPS:

### Preguntas de Autoevaluación

<details>
<summary>1. ¿Cuál es la diferencia entre pathType: Prefix y pathType: Exact?</summary>

**Respuesta**:

**`Prefix`**: Coincide con el **prefijo** del path (más flexible):
```yaml
path: /api
pathType: Prefix
```

**Coincidencias**:
- ✅ `/api` → Sí
- ✅ `/api/` → Sí
- ✅ `/api/users` → Sí
- ✅ `/api/v1/products` → Sí
- ❌ `/application` → No

**`Exact`**: Coincide **exactamente** con el path (case-sensitive):
```yaml
path: /api
pathType: Exact
```

**Coincidencias**:
- ✅ `/api` → Sí
- ❌ `/api/` → No (barra extra)
- ❌ `/api/users` → No
- ❌ `/API` → No (case-sensitive)

**Tabla comparativa**:
| Path Configurado | pathType | Request | ¿Coincide? |
|------------------|----------|---------|------------|
| `/foo` | Prefix | `/foo` | ✅ |
| `/foo` | Prefix | `/foo/` | ✅ |
| `/foo` | Prefix | `/foo/bar` | ✅ |
| `/foo` | Exact | `/foo` | ✅ |
| `/foo` | Exact | `/foo/` | ❌ |
| `/foo` | Exact | `/foo/bar` | ❌ |

**Uso común**:
- **`Prefix`**: APIs y aplicaciones (mayoría de casos)
  - Ejemplo: `/api` captura todas las rutas de API
- **`Exact`**: Rutas específicas (health checks, webhooks)
  - Ejemplo: `/health` solo para el endpoint exacto

**Recomendación**: Usa `Prefix` por defecto, `Exact` solo para casos muy específicos.

</details>

<details>
<summary>2. ¿Cómo funciona el host-based routing cuando un Ingress tiene múltiples hosts?</summary>

**Respuesta**:

El Ingress Controller inspecciona el **header `Host:`** de la petición HTTP y enruta según la coincidencia.

**Flujo de enrutamiento**:
```
Cliente hace request → Ingress Controller lee header Host → Busca coincidencia en rules → Enruta a service correspondiente
```

**Ejemplo de Ingress**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: blog.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop-service
            port:
              number: 3000
```

**Peticiones**:
```bash
# Request 1
curl -H "Host: blog.example.com" http://<ingress-ip>/
# → Enruta a blog-service:80

# Request 2
curl -H "Host: api.example.com" http://<ingress-ip>/users
# → Enruta a api-service:8080

# Request 3
curl -H "Host: shop.example.com" http://<ingress-ip>/cart
# → Enruta a shop-service:3000

# Request 4 (host no configurado)
curl -H "Host: unknown.example.com" http://<ingress-ip>/
# → 404 Not Found (o default backend)
```

**Detrás de escena**:
1. DNS resuelve `blog.example.com` → IP del LoadBalancer (ej: 203.0.113.5)
2. Cliente envía:
   ```
   GET / HTTP/1.1
   Host: blog.example.com
   ```
3. Ingress Controller lee `Host: blog.example.com`
4. Busca en reglas: coincide con rule #1
5. Hace proxy_pass a `blog-service:80`
6. Service balancea a Pods backend

**Ventaja**: Mismo LoadBalancer (IP 203.0.113.5) sirve múltiples aplicaciones. Solo necesitas configurar DNS:
```
blog.example.com  → 203.0.113.5
api.example.com   → 203.0.113.5
shop.example.com  → 203.0.113.5
```

</details>

<details>
<summary>3. ¿Cómo se configura HTTPS/TLS en un Ingress?</summary>

**Respuesta**:

HTTPS/TLS requiere **2 pasos**: crear Secret con certificado + configurar Ingress.

**Paso 1: Crear Secret con certificado TLS**:
```bash
# Generar certificado self-signed (para testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.example.com/O=mycompany"

# Crear Secret tipo tls
kubectl create secret tls myapp-tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Verificar
kubectl get secret myapp-tls-secret
kubectl describe secret myapp-tls-secret
```

**Paso 2: Configurar Ingress con TLS**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
spec:
  ingressClassName: nginx
  tls:  # ← Configuración TLS
  - hosts:
    - myapp.example.com  # Host protegido
    secretName: myapp-tls-secret  # Secret con certificado
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

**Qué hace el Ingress Controller**:
1. Lee el Secret `myapp-tls-secret`
2. Extrae `tls.crt` y `tls.key`
3. Configura nginx para terminación TLS
4. Escucha en puerto 443 (HTTPS)
5. Desencripta tráfico HTTPS
6. Envía tráfico HTTP al Service backend

**Flujo completo**:
```
Cliente (HTTPS) 
    ↓ [TLS/443]
Ingress Controller (termina TLS)
    ↓ [HTTP/80 interno]
Service ClusterIP
    ↓
Pods backend
```

**Múltiples hosts con TLS**:
```yaml
spec:
  tls:
  - hosts:
    - app1.example.com
    - app2.example.com
    secretName: multi-host-tls  # Cert debe incluir ambos hosts en SAN
```

**Wildcard certificate**:
```bash
# Certificado para *.example.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=*.example.com/O=mycompany"

kubectl create secret tls wildcard-tls --cert=tls.crt --key=tls.key
```

```yaml
spec:
  tls:
  - hosts:
    - "*.example.com"  # Cubre app1.example.com, api.example.com, etc.
    secretName: wildcard-tls
```

**Verificar HTTPS**:
```bash
# Test con curl (acepta cert self-signed)
curl -k https://myapp.example.com

# Ver detalles del certificado
curl -vk https://myapp.example.com 2>&1 | grep "subject:"
```

**Producción**: Usa **cert-manager** para certificados automáticos de Let's Encrypt (gratuitos y válidos).

</details>

<details>
<summary>4. ¿Qué sucede si un cliente hace una petición HTTP (puerto 80) a un Ingress configurado con TLS?</summary>

**Respuesta**:

Depende de la configuración del Ingress Controller. Por defecto en nginx:

**Comportamiento por defecto**:
- El Ingress Controller **acepta** tanto HTTP (80) como HTTPS (443)
- Las peticiones HTTP **no se redirigen automáticamente** a HTTPS
- Ambos funcionan si el Ingress tiene `tls:` configurado

```bash
# Ambos funcionan
curl http://myapp.example.com     # ✅ HTTP OK
curl https://myapp.example.com    # ✅ HTTPS OK
```

**Para forzar HTTPS** (redirigir HTTP → HTTPS):

**Opción 1: Anotación en Ingress** (nginx):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"  # ← Redirección automática
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

**Comportamiento**:
```bash
curl -I http://myapp.example.com
# HTTP/1.1 308 Permanent Redirect
# Location: https://myapp.example.com

# El cliente automáticamente hace:
curl https://myapp.example.com
# HTTP/1.1 200 OK
```

**Opción 2: Bloquear HTTP completamente**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
```

**Opción 3: HSTS** (HTTP Strict Transport Security):
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/hsts: "true"
    nginx.ingress.kubernetes.io/hsts-max-age: "31536000"  # 1 año
```

HSTS le dice al navegador: "Solo usa HTTPS para este dominio durante 1 año".

**Recomendación de producción**:
```yaml
metadata:
  annotations:
    # Redirigir HTTP → HTTPS
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    # HSTS
    nginx.ingress.kubernetes.io/hsts: "true"
    nginx.ingress.kubernetes.io/hsts-max-age: "31536000"
    nginx.ingress.kubernetes.io/hsts-include-subdomains: "true"
```

**Sin configurar redirección**: Los usuarios podrían usar HTTP sin saberlo → inseguro.

</details>

<details>
<summary>5. ¿Cómo combinar path-based y host-based routing en un solo Ingress?</summary>

**Respuesta**:

Puedes combinar **host + path** para routing muy específico:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: combined-routing-ingress
spec:
  ingressClassName: nginx
  rules:
  # Host 1: app.example.com
  - host: app.example.com
    http:
      paths:
      - path: /api        # app.example.com/api → api-service
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web        # app.example.com/web → web-service
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
      - path: /admin      # app.example.com/admin → admin-service
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
  
  # Host 2: docs.example.com
  - host: docs.example.com
    http:
      paths:
      - path: /           # docs.example.com → docs-service
        pathType: Prefix
        backend:
          service:
            name: docs-service
            port:
              number: 80
  
  # Host 3: blog.example.com
  - host: blog.example.com
    http:
      paths:
      - path: /           # blog.example.com → blog-service
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
```

**Tabla de routing resultante**:
| Request | Service Destino |
|---------|----------------|
| `app.example.com/api/users` | api-service:8080 |
| `app.example.com/web/home` | web-service:80 |
| `app.example.com/admin/dashboard` | admin-service:3000 |
| `docs.example.com/` | docs-service:80 |
| `docs.example.com/guide` | docs-service:80 |
| `blog.example.com/` | blog-service:80 |
| `blog.example.com/posts/123` | blog-service:80 |

**Ventajas**:
- 1 LoadBalancer para 6 destinos diferentes
- Organización lógica por dominio y funcionalidad
- Fácil agregar más servicios

**Con TLS**:
```yaml
spec:
  tls:
  - hosts:
    - app.example.com
    - docs.example.com
    - blog.example.com
    secretName: wildcard-tls  # *.example.com cert
  rules:
  # ... (mismas reglas)
```

**Uso real**: Aplicación completa con:
- Frontend: `app.example.com/web`
- API: `app.example.com/api`
- Admin panel: `app.example.com/admin`
- Documentación: `docs.example.com`
- Blog corporativo: `blog.example.com`

Todo con 1 LoadBalancer, 1 certificado wildcard, 1 Ingress resource.

</details>

### 🧪 Ejercicio Práctico

**Diseña el routing** para esta aplicación:

**Requisitos**:
- Frontend React: `myapp.com` → frontend-service:80
- API REST: `myapp.com/api` → api-service:8080
- Admin panel: `myapp.com/admin` → admin-service:3000
- Docs: `docs.myapp.com` → docs-service:80
- Todo debe ser HTTPS

<details>
<summary>Ver Solución</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-complete-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /  # Para /api y /admin
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.com
    - docs.myapp.com
    secretName: myapp-tls-secret
  rules:
  # myapp.com con múltiples paths
  - host: myapp.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  
  # docs.myapp.com
  - host: docs.myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: docs-service
            port:
              number: 80
```

**Crear el Secret TLS**:
```bash
# Certificado para myapp.com + docs.myapp.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.com/O=mycompany" \
  -addext "subjectAltName=DNS:myapp.com,DNS:docs.myapp.com"

kubectl create secret tls myapp-tls-secret --cert=tls.crt --key=tls.key
```

**Resultado**:
- ✅ `https://myapp.com` → Frontend
- ✅ `https://myapp.com/api/users` → API
- ✅ `https://myapp.com/admin` → Admin
- ✅ `https://docs.myapp.com` → Docs
- ✅ HTTP automáticamente redirige a HTTPS
- ✅ 1 LoadBalancer para todo

</details>

### 🔗 Siguiente Paso

Si dominas routing y TLS, continúa con anotaciones avanzadas para personalizar el comportamiento del Ingress Controller.

---

### ✅ Checkpoint Final: Integración y Producción

Última verificación antes de aplicar tus conocimientos en laboratorios:

### Preguntas de Autoevaluación

<details>
<summary>1. ¿Qué componentes necesitas para tener un Ingress completamente funcional en producción?</summary>

**Respuesta**:

**7 componentes esenciales**:

**1. Ingress Controller** (implementación del proxy):
```bash
# Opción 1: nginx
helm install ingress-nginx ingress-nginx/ingress-nginx

# Opción 2: Traefik, HAProxy, etc.
```

**2. IngressClass** (identifica el controller):
```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
```

**3. LoadBalancer Service** (punto de entrada externo):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  type: LoadBalancer  # IP pública
  ports:
  - name: http
    port: 80
  - name: https
    port: 443
```

**4. Backend Services** (ClusterIP para apps):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
```

**5. Deployments** (Pods de la aplicación):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 8080
        readinessProbe:  # ← CRÍTICO
          httpGet:
            path: /health
            port: 8080
```

**6. TLS Secrets** (certificados):
```bash
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key
```

**7. Ingress Resources** (reglas de routing):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.com
    secretName: myapp-tls
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

**Componentes opcionales pero recomendados**:
- **cert-manager**: Certificados automáticos de Let's Encrypt
- **external-dns**: DNS automático en cloud providers
- **PodDisruptionBudget**: Alta disponibilidad del controller
- **HPA**: Autoscaling del controller
- **NetworkPolicies**: Seguridad adicional

**Flujo completo**:
```
Internet (https://myapp.com)
    ↓ DNS resolve
LoadBalancer Service (IP: 203.0.113.5)
    ↓
Ingress Controller Pods (nginx, 3 replicas)
    ↓ lee reglas de
Ingress Resource (myapp-ingress)
    ↓ termina TLS con
Secret (myapp-tls)
    ↓ enruta a
Service ClusterIP (myapp-service)
    ↓ balancea entre
Deployment Pods (myapp, 3 replicas)
```

</details>

<details>
<summary>2. ¿Cómo implementar un canary deployment con Ingress usando weights?</summary>

**Respuesta**:

**Canary deployment** = Enviar un % de tráfico a la nueva versión para testing gradual.

**Estrategia con nginx ingress**:

**Paso 1: Deployment stable (v1) + Service**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-stable
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: v1
  template:
    metadata:
      labels:
        app: myapp
        version: v1
    spec:
      containers:
      - name: myapp
        image: myapp:v1.0
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-stable
spec:
  selector:
    app: myapp
    version: v1
  ports:
  - port: 80
    targetPort: 8080
```

**Paso 2: Deployment canary (v2) + Service**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
spec:
  replicas: 1  # Menos réplicas
  selector:
    matchLabels:
      app: myapp
      version: v2
  template:
    metadata:
      labels:
        app: myapp
        version: v2
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0  # Nueva versión
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-canary
spec:
  selector:
    app: myapp
    version: v2
  ports:
  - port: 80
    targetPort: 8080
```

**Paso 3: Ingress principal (100% a stable)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-stable  # v1
            port:
              number: 80
```

**Paso 4: Ingress canary (10% de tráfico a v2)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"  # 10% tráfico
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-canary  # v2
            port:
              number: 80
```

**Resultado**:
- 90% de requests → myapp-stable (v1)
- 10% de requests → myapp-canary (v2)

**Progresión gradual**:
```bash
# 1. Empezar con 10%
kubectl apply -f ingress-canary.yaml  # weight: 10

# 2. Monitorear v2 (errores, latencia, métricas)
kubectl logs -l version=v2 --tail=100

# 3. Si v2 está OK, aumentar a 25%
kubectl patch ingress myapp-canary -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"25"}}}'

# 4. Luego 50%
kubectl patch ingress myapp-canary -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"50"}}}'

# 5. Finalmente 100% (promover v2)
kubectl delete ingress myapp-canary  # Eliminar canary
kubectl patch ingress myapp-ingress -p '{"spec":{"rules":[{"host":"myapp.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"myapp-canary","port":{"number":80}}}}]}}]}}'

# 6. Eliminar v1
kubectl delete deployment myapp-stable
kubectl delete service myapp-stable
```

**Otras estrategias de canary**:
```yaml
# Canary por header (usuarios beta)
annotations:
  nginx.ingress.kubernetes.io/canary: "true"
  nginx.ingress.kubernetes.io/canary-by-header: "X-Beta-User"

# Canary por cookie (A/B testing)
annotations:
  nginx.ingress.kubernetes.io/canary: "true"
  nginx.ingress.kubernetes.io/canary-by-cookie: "beta_user"
```

</details>

<details>
<summary>3. ¿Cómo diagnosticar un Ingress que no responde (404 o timeout)?</summary>

**Respuesta**:

**Proceso de troubleshooting en 8 pasos**:

**1. Verificar Ingress Controller funciona**:
```bash
# Pods del controller están Running
kubectl get pods -n ingress-nginx
# NAME                                   READY   STATUS
# ingress-nginx-controller-xxx-xxx       1/1     Running

# Logs en tiempo real
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --follow
```

**2. Verificar el recurso Ingress existe**:
```bash
# Listar Ingress
kubectl get ingress

# Ver detalles
kubectl describe ingress myapp-ingress

# Buscar:
# - Address: debe tener IP
# - Rules: deben estar correctas
# - Backend: debe apuntar al service correcto
# - Events: errores recientes
```

**3. Verificar IngressClass**:
```bash
# Listar IngressClasses
kubectl get ingressclass

# Verificar que el Ingress usa la correcta
kubectl get ingress myapp-ingress -o jsonpath='{.spec.ingressClassName}'
# Debe retornar: nginx (o la que uses)
```

**4. Verificar Service backend existe**:
```bash
# Service existe
kubectl get service myapp-service

# Tiene Endpoints
kubectl get endpoints myapp-service

# Si está vacío → problema con selector
kubectl get service myapp-service -o yaml | grep -A 3 selector
kubectl get pods -l <selector> --show-labels
```

**5. Verificar Pods backend están Ready**:
```bash
# Pods en Running y READY
kubectl get pods -l app=myapp

# Si no están Ready, ver readinessProbe
kubectl describe pod <pod-name> | grep -A 10 Readiness

# Ver logs de la app
kubectl logs <pod-name> --tail=50
```

**6. Test de conectividad desde dentro del cluster**:
```bash
# Crear Pod temporal
kubectl run debug --image=curlimages/curl -it --rm -- sh

# Test directo al Service
curl http://myapp-service

# Test al Ingress Controller
curl -H "Host: myapp.com" http://ingress-nginx-controller.ingress-nginx.svc.cluster.local
```

**7. Verificar DNS (si usas dominio real)**:
```bash
# Resolver DNS
nslookup myapp.com

# Debe apuntar a la IP del LoadBalancer
kubectl get svc -n ingress-nginx ingress-nginx-controller
# EXTERNAL-IP debe coincidir con DNS
```

**8. Revisar anotaciones del Ingress**:
```bash
# Ver anotaciones
kubectl get ingress myapp-ingress -o yaml | grep annotations -A 10

# Anotaciones comunes que causan problemas:
# - nginx.ingress.kubernetes.io/rewrite-target mal configurado
# - whitelist-source-range bloqueando tu IP
# - auth-url sin configurar correctamente
```

**Errores comunes y soluciones**:

| Error | Causa | Solución |
|-------|-------|----------|
| **404 Not Found** | Ingress no tiene regla matching | Verificar `host:` y `path:` en rules |
| **503 Service Unavailable** | Service sin Endpoints | Verificar selector del Service coincide con labels de Pods |
| **502 Bad Gateway** | Pods no están Ready | Verificar readinessProbe y logs de Pods |
| **Connection timeout** | Ingress Controller no accesible | Verificar LoadBalancer Service tiene EXTERNAL-IP |
| **Certificate error** | TLS Secret incorrecto | Verificar Secret existe y tiene `tls.crt` + `tls.key` |

**Comando de diagnóstico rápido**:
```bash
# Ver todo relacionado al Ingress
kubectl get ingress,svc,endpoints,pods -l app=myapp
```

</details>

<details>
<summary>4. ¿Qué consideraciones de seguridad debes tener en producción con Ingress?</summary>

**Respuesta**:

**10 mejores prácticas de seguridad**:

**1. Siempre usar TLS/HTTPS**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"  # Forzar HTTPS
    nginx.ingress.kubernetes.io/hsts: "true"                # HSTS
    nginx.ingress.kubernetes.io/hsts-max-age: "31536000"   # 1 año
spec:
  tls:
  - hosts:
    - myapp.com
    secretName: myapp-tls
```

**2. Rate limiting** (prevenir DDoS):
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"           # 10 req/s por IP
    nginx.ingress.kubernetes.io/limit-connections: "5"    # 5 conexiones simultáneas
    nginx.ingress.kubernetes.io/limit-rpm: "100"          # 100 req/min por IP
```

**3. Whitelist de IPs** (para endpoints sensibles):
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/whitelist-source-range: "192.168.1.0/24,10.0.0.0/8"
```

**4. Autenticación básica** (admin panels):
```bash
# Crear htpasswd
htpasswd -c auth admin
# Password: ******

kubectl create secret generic admin-auth --from-file=auth
```

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: admin-auth
    nginx.ingress.kubernetes.io/auth-realm: "Admin Area"
```

**5. CORS seguro** (APIs):
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://myapp.com"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST"
    nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
```

**6. Ocultar versión de nginx**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/server-snippet: |
      more_clear_headers Server;
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
```

**7. Tamaño máximo de request body**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"  # Max 10MB uploads
```

**8. NetworkPolicies** (restringir tráfico interno):
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-ingress
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx  # Solo desde ingress controller
    ports:
    - protocol: TCP
      port: 8080
```

**9. WAF (Web Application Firewall)** con ModSecurity:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    nginx.ingress.kubernetes.io/enable-owasp-core-rules: "true"
    nginx.ingress.kubernetes.io/modsecurity-snippet: |
      SecRuleEngine On
      SecRequestBodyAccess On
```

**10. Regular security scanning**:
```bash
# Escanear vulnerabilidades en la imagen del controller
trivy image registry.k8s.io/ingress-nginx/controller:latest

# Verificar secretos expuestos
kubectl get ingress -o yaml | grep -i password
```

**Checklist de producción**:
- [ ] TLS/HTTPS forzado
- [ ] Certificados de CA válida (Let's Encrypt)
- [ ] Rate limiting configurado
- [ ] HSTS habilitado
- [ ] Security headers (X-Frame-Options, CSP)
- [ ] WAF para endpoints públicos
- [ ] Whitelist IPs para admin/sensitive
- [ ] NetworkPolicies restrictivas
- [ ] Body size limits
- [ ] CORS configurado apropiadamente
- [ ] Autenticación en endpoints sensibles
- [ ] Logs de acceso centralizados
- [ ] Alertas de seguridad (Prometheus)
- [ ] Regular updates del controller

</details>

### 🎯 Desafío Final de Integración

Diseña una arquitectura completa de Ingress para:

**E-commerce Platform**:
- Frontend (React): `shop.example.com`
- API (Node.js): `shop.example.com/api`
- Admin Panel (React): `admin.example.com` (solo IPs internas)
- Docs (MkDocs): `docs.example.com`
- Blog (WordPress): `blog.example.com`
- v2 API en canary (5% tráfico): `shop.example.com/api/v2`

**Requisitos**:
- Todo en HTTPS
- Rate limiting en API (100 req/min)
- Admin requiere autenticación básica
- Canary deployment para API v2
- Alta disponibilidad (3 replicas controller)

<details>
<summary>Ver Solución Arquitectura</summary>

**Componentes**:

**1. Ingress Controller (3 replicas)**:
```yaml
# values.yaml para Helm
controller:
  replicaCount: 3
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: ingress-nginx
```

**2. Ingress Principal**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop-main-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/hsts: "true"
    nginx.ingress.kubernetes.io/limit-rpm: "100"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - shop.example.com
    - docs.example.com
    - blog.example.com
    secretName: shop-tls
  rules:
  # Frontend
  - host: shop.example.com
    http:
      paths:
      - path: /api/v2  # Canary
        pathType: Prefix
        backend:
          service:
            name: api-v1-service
            port:
              number: 8080
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-v1-service
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  # Docs
  - host: docs.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: docs-service
            port:
              number: 80
  # Blog
  - host: blog.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
```

**3. Ingress Admin (protegido)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: admin-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/whitelist-source-range: "192.168.1.0/24,10.0.0.0/8"
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: admin-auth
    nginx.ingress.kubernetes.io/auth-realm: "Admin Access"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - admin.example.com
    secretName: admin-tls
  rules:
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
```

**4. Ingress Canary (API v2 - 5% tráfico)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-v2-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "5"
spec:
  ingressClassName: nginx
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /api/v2
        pathType: Prefix
        backend:
          service:
            name: api-v2-service
            port:
              number: 8080
```

**Resultado**:
- ✅ 1 LoadBalancer para toda la plataforma
- ✅ HTTPS en todos los dominios
- ✅ API con rate limiting
- ✅ Admin protegido (IP + auth)
- ✅ Canary 5% en API v2
- ✅ Alta disponibilidad (3 replicas)

**Ahorro**: 5 dominios = 1 LoadBalancer vs 5 LoadBalancers sin Ingress = **ahorro de $80/mes**

</details>

### ✅ Checklist de Dominio del Módulo

Marca lo que ya dominas:

**Conceptos**:
- [ ] Diferencia entre Ingress, IngressController e IngressClass
- [ ] Ventajas vs múltiples LoadBalancers
- [ ] Flujo: Internet → LB → Controller → Service → Pods

**Instalación**:
- [ ] Habilitar nginx ingress en minikube
- [ ] Verificar controller funciona
- [ ] Entender IngressClass

**Routing**:
- [ ] Path-based routing (`/api`, `/web`)
- [ ] Host-based routing (`app1.com`, `app2.com`)
- [ ] Combinar host + path
- [ ] PathType: Prefix vs Exact

**TLS/HTTPS**:
- [ ] Crear TLS Secrets
- [ ] Configurar HTTPS en Ingress
- [ ] Forzar redirección HTTP → HTTPS
- [ ] Certificados wildcard

**Avanzado**:
- [ ] Anotaciones (rewrite, rate limit, auth)
- [ ] Canary deployments
- [ ] Múltiples Ingress Controllers
- [ ] Troubleshooting 404/502/503

**Producción**:
- [ ] Alta disponibilidad (replicas + anti-affinity)
- [ ] Seguridad (TLS, rate limit, whitelist, WAF)
- [ ] Monitoreo (logs, métricas, alertas)
- [ ] Cert-manager para certificados automáticos

### 🔗 Siguiente Paso

¡Has completado toda la teoría! Ahora aplica tus conocimientos en los 3 laboratorios prácticos guiados.

---

---

## Capítulo 22: Init Containers y Sidecar Patterns

### ✅ Auto-Evaluación

### Checklist de Conocimientos

- [ ] Entiendo qué son init containers y cuándo usarlos
- [ ] Puedo crear Pods con múltiples containers
- [ ] Sé cómo configurar shared volumes
- [ ] Entiendo localhost networking en Pods
- [ ] Puedo implementar sidecar pattern
- [ ] Sé troubleshootear containers que fallan
- [ ] Puedo ver logs de containers específicos
- [ ] Entiendo diferencias entre Ambassador/Adapter/Sidecar
- [ ] Sé configurar resource limits por container
- [ ] Estoy listo para preguntas CKAD sobre multi-container

---

---

