# 🔍 Módulo 04 vs Módulo 05: Separación Clara de Responsabilidades

> **Guía para entender qué aprenderás en cada módulo**

---

## 📊 Comparación Rápida

| Aspecto | Módulo 04 (Pods vs Contenedores) | Módulo 05 (Gestión de Pods) |
|---------|-----------------------------------|------------------------------|
| **Enfoque** | ¿Qué es un Pod? | ¿Cómo gestionarlo? |
| **Nivel** | Fundamentos | Gestión avanzada |
| **Pregunta clave** | ¿Por qué existen los Pods? | ¿Cómo usarlos en producción? |
| **Objetivo** | Comprender la arquitectura | Dominar la configuración |
| **Abstracción** | Conceptual | Práctica operacional |

---

## 🎯 Módulo 04: Pods vs Contenedores (Este Módulo)

### ¿Qué Aprenderás?

#### 1. Fundamentos Conceptuales
- 📚 **Historia**: Evolución de LXC → Docker → Kubernetes
- 🧬 **Arquitectura interna**: ¿Cómo funciona un Pod por dentro?
- 🔬 **Contenedor pause**: ¿Qué es y por qué existe?
- 🌐 **Namespaces compartidos**: ¿Qué se comparte y qué no?

#### 2. Namespaces Linux en Detalle
- 🌐 **Network namespace**: Comunicación localhost
- 💬 **IPC namespace**: Shared memory, semaphores
- 🏷️ **UTS namespace**: Hostname compartido
- 🔄 **PID namespace**: Visibilidad de procesos
- 📁 **Mount namespace**: Filesystems independientes
- 👤 **User namespace**: UIDs/GIDs
- ⚙️ **Cgroup namespace**: Control de recursos

#### 3. Patrones de Diseño Multi-Contenedor
- 🔄 **Sidecar Pattern**: Extender funcionalidad (logging, monitoring, service mesh)
- 🚀 **Init Container Pattern**: Tareas de preparación (migrations, wait-for, setup)
- 🔗 **Ambassador Pattern**: Proxy e intermediarios (load balancing, SSL, pooling)

#### 4. Decisiones Arquitectónicas
- 🤔 **Cuándo usar**: Un Pod multi-contenedor vs múltiples Pods
- 🐳 **Migración**: De Docker Compose a Kubernetes
- ❌ **Antipatrones**: Fat Pods, Singleton Services, Volume Abuse

### Temas que NO Cubre Este Módulo
- ❌ Configuración detallada de resource requests/limits
- ❌ Health checks (liveness, readiness, startup probes)
- ❌ Security contexts y policies
- ❌ Pod affinity/anti-affinity
- ❌ Tolerations y taints
- ❌ Pod priority y preemption
- ❌ Deployment strategies
- ❌ Horizontal Pod Autoscaling

> **Estos temas se cubren en el Módulo 05**

---

## 🎯 Módulo 05: Gestión de Pods (Próximo Módulo)

### ¿Qué Aprenderás?

#### 1. Manifiestos YAML Avanzados
- 📝 **Estructura completa**: Spec detallada de Pods
- ⚙️ **Resource management**: Requests vs Limits
- 📊 **Quality of Service**: Guaranteed, Burstable, BestEffort
- 🎨 **Labels y Selectors**: Organización y selección de Pods

#### 2. Health Checks y Lifecycle
- 💓 **Liveness probes**: ¿Está vivo el contenedor?
- ✅ **Readiness probes**: ¿Está listo para recibir tráfico?
- 🚀 **Startup probes**: Aplicaciones con inicio lento
- 🔄 **Lifecycle hooks**: postStart, preStop

#### 3. Seguridad y Aislamiento
- 🔐 **Security contexts**: runAsUser, fsGroup, capabilities
- 🛡️ **Pod Security Policies**: Restricciones de seguridad
- 🔒 **Service Accounts**: Identidad de Pods
- 🚫 **Network Policies**: Aislamiento de red

#### 4. Scheduling Avanzado
- 📍 **Node selectors**: Elegir nodos específicos
- 🧲 **Affinity/Anti-affinity**: Atraer o repeler Pods
- 🏷️ **Taints y Tolerations**: Reservar nodos
- ⚖️ **Priority Classes**: Prioridad de Pods

#### 5. Escalado y Performance
- 📈 **Horizontal Pod Autoscaler (HPA)**: Escalar automáticamente
- 📊 **Vertical Pod Autoscaler (VPA)**: Ajustar recursos
- 🎯 **Resource quotas**: Límites por namespace
- ⚡ **Performance tuning**: Optimización de recursos

#### 6. Debugging Avanzado
- 🔍 **Troubleshooting**: Técnicas avanzadas de debugging
- 📋 **Events y logs**: Análisis profundo
- 🧪 **Ephemeral containers**: Debug de Pods en producción
- 🔧 **kubectl debug**: Herramienta de debugging

### Temas que NO Cubre el Módulo 05
- ❌ Qué es un Pod (cubierto en Módulo 04)
- ❌ Patrones multi-contenedor básicos (cubierto en Módulo 04)
- ❌ Namespaces Linux internos (cubierto en Módulo 04)

---

## 🎓 Progresión de Aprendizaje

```
┌─────────────────────────────────────────────────────────────┐
│                     TU VIAJE DE APRENDIZAJE                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📘 MÓDULO 04: Pods vs Contenedores                         │
│  ├─ ¿Qué es un Pod?                                         │
│  ├─ ¿Por qué existe?                                        │
│  ├─ ¿Cómo funciona internamente?                            │
│  └─ ¿Cuándo usar multi-contenedor?                          │
│                                                             │
│  ↓                                                          │
│  Entiendes la ARQUITECTURA y CONCEPTOS                      │
│  ↓                                                          │
│                                                             │
│  📗 MÓDULO 05: Gestión de Pods                              │
│  ├─ ¿Cómo configurar recursos?                              │
│  ├─ ¿Cómo asegurar disponibilidad?                          │
│  ├─ ¿Cómo implementar seguridad?                            │
│  └─ ¿Cómo escalar y optimizar?                              │
│                                                             │
│  ↓                                                          │
│  Dominas la GESTIÓN y OPERACIÓN                             │
│  ↓                                                          │
│                                                             │
│  🎯 RESULTADO: Listo para producción                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 Preguntas Que Responde Cada Módulo

### Módulo 04: Pods vs Contenedores

**Preguntas arquitectónicas:**
- ❓ ¿Por qué Kubernetes usa Pods en lugar de contenedores individuales?
- ❓ ¿Qué namespaces se comparten entre contenedores de un Pod?
- ❓ ¿Cuál es la diferencia entre un Sidecar y un Init Container?
- ❓ ¿Cuándo debo agrupar contenedores en un Pod vs usar Pods separados?
- ❓ ¿Cómo migro mi docker-compose.yml a Kubernetes?

**Ejemplos de respuestas:**
- ✅ "Los Pods permiten cohesión automática de contenedores relacionados"
- ✅ "Network, IPC y UTS se comparten; Mount, User y Cgroup no"
- ✅ "Sidecar corre simultáneamente; Init Container corre antes"
- ✅ "Agrupa en un Pod solo si hay tight coupling y necesitas shared memory"
- ✅ "Generalmente usas Deployments separados, no un Pod multi-contenedor"

---

### Módulo 05: Gestión de Pods

**Preguntas operacionales:**
- ❓ ¿Cómo configuro resource requests y limits correctamente?
- ❓ ¿Qué diferencia hay entre liveness y readiness probes?
- ❓ ¿Cómo evito que un Pod consuma todos los recursos del nodo?
- ❓ ¿Cómo aseguro que mis Pods se distribuyan entre nodos?
- ❓ ¿Cómo escalo automáticamente según la carga?

**Ejemplos de respuestas:**
- ✅ "Requests = garantizado; Limits = máximo permitido"
- ✅ "Liveness = restart si falla; Readiness = no enviar tráfico si falla"
- ✅ "Usa limits en spec.containers[].resources.limits"
- ✅ "Usa podAntiAffinity para distribuir entre nodos"
- ✅ "Usa Horizontal Pod Autoscaler (HPA) con métricas CPU/memoria"

---

## 📚 Ejemplos de Contenido

### Ejemplo: Módulo 04 (Conceptual)

**Pregunta**: ¿Qué es un Sidecar?

**Respuesta en Módulo 04**:
```
Un Sidecar es un contenedor auxiliar que:
- Corre simultáneamente con el main container
- Extiende funcionalidad sin modificar código
- Casos de uso: logging, monitoring, service mesh
- Comparte volumes y networking
```

**YAML básico** (Módulo 04):
```yaml
containers:
- name: app
  image: myapp
- name: log-processor  # ← Sidecar
  image: fluentbit
```

---

### Ejemplo: Módulo 05 (Operacional)

**Pregunta**: ¿Cómo configuro un Sidecar con resource limits y health checks?

**Respuesta en Módulo 05**:
```
Configuración completa en producción:
- Resources: requests y limits
- Liveness probe: verificar que funciona
- Readiness probe: verificar que está listo
- Startup probe: dar tiempo para iniciar
```

**YAML completo** (Módulo 05):
```yaml
containers:
- name: app
  image: myapp
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
  livenessProbe:
    httpGet:
      path: /healthz
      port: 8080
    initialDelaySeconds: 30
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /ready
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 5

- name: log-processor
  image: fluentbit
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"
  livenessProbe:
    exec:
      command: ["pgrep", "fluent-bit"]
    periodSeconds: 30
```

---

## 🎯 Cómo Usar Esta Separación

### Al estudiar Módulo 04:
1. ✅ Enfócate en **conceptos** y **arquitectura**
2. ✅ Entiende **por qué** existen los Pods
3. ✅ Aprende los **patrones de diseño** (Sidecar, Init, Ambassador)
4. ✅ Practica con **ejemplos básicos** funcionales
5. ❌ **NO te preocupes aún** por resource limits, health checks, scheduling

### Al estudiar Módulo 05:
1. ✅ Enfócate en **configuración** y **operación**
2. ✅ Aprende **cómo** configurar Pods para producción
3. ✅ Domina **resource management** y **health checks**
4. ✅ Practica con **manifiestos completos** de producción
5. ✅ Asume que ya entiendes **qué es un Pod** (del Módulo 04)

---

## ✅ Checklist de Transición

**¿Listo para pasar al Módulo 05?** Verifica que puedes:

### Del Módulo 04 (Prerequisitos)
- [ ] Explicar qué es un Pod y por qué existe
- [ ] Distinguir los 7 tipos de namespaces Linux
- [ ] Identificar cuáles namespaces se comparten en un Pod
- [ ] Describir los 3 patrones multi-contenedor (Sidecar, Init, Ambassador)
- [ ] Decidir cuándo usar un Pod multi-contenedor vs múltiples Pods
- [ ] Crear manifiestos YAML básicos de Pods

### Para el Módulo 05 (Lo Que Aprenderás)
- [ ] Configurar resource requests y limits
- [ ] Implementar liveness, readiness y startup probes
- [ ] Aplicar security contexts
- [ ] Usar selectors, affinity y taints
- [ ] Configurar autoscaling
- [ ] Debugear Pods en producción

---

## 🏗️ Analogía de Construcción

```
🏗️ Construcción de una Casa:

MÓDULO 04 = ARQUITECTURA
├─ ¿Qué es una casa?
├─ ¿Por qué construir una casa?
├─ Materiales básicos (ladrillos, cemento, madera)
├─ Estructura básica (paredes, techo, puertas)
└─ Patrones de diseño (cocina, baño, sala)

MÓDULO 05 = CONSTRUCCIÓN Y ACABADOS
├─ Instalación eléctrica avanzada
├─ Plomería y heating
├─ Aislamiento térmico
├─ Sistema de seguridad
├─ Eficiencia energética
└─ Mantenimiento y reparaciones

RESULTADO = Casa habitable y optimizada
```

---

## 📖 Resumen

| | Módulo 04 | Módulo 05 |
|-|-----------|-----------|
| **Enfoque** | Conceptual/Arquitectónico | Operacional/Práctico |
| **Pregunta** | ¿Qué? ¿Por qué? | ¿Cómo? ¿Cuándo? |
| **Nivel** | Fundamentos | Avanzado |
| **YAML** | Básico funcional | Completo production-ready |
| **Objetivo** | Entender arquitectura | Dominar gestión |
| **Resultado** | Sabes diseñar Pods | Sabes operarlos |

---

**Recomendación**: Completa el Módulo 04 **antes** de pasar al 05. Los conceptos de namespaces y patrones multi-contenedor son fundamentales para entender las configuraciones avanzadas del Módulo 05.

---

**[⬅️ Volver al Módulo 04](./README.md)** | **[➡️ Ir al Módulo 05](../modulo-05-gestion-pods/README.md)**
