# 🚀 Laboratorios - Deployments y Rollouts

Este módulo contiene laboratorios prácticos para dominar Deployments y estrategias de rollout en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: Crear Deployments](./lab-01-crear-deployments/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐☆☆☆

Fundamentos de Deployments en Kubernetes.

**Objetivos:**
- Crear Deployments desde YAML
- Entender la relación Deployment → ReplicaSet → Pod
- Escalar Deployments
- Comandos esenciales

---

### [Lab 02: Rolling Updates](./lab-02-rolling-updates/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐☆☆

Actualizaciones graduales sin downtime.

**Objetivos:**
- Configurar RollingUpdate strategy
- Parámetros maxSurge y maxUnavailable
- Monitorear rollout progress
- Zero-downtime deployments

---

### [Lab 03: Rollback de Versiones](./lab-03-rollback/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

Reversión a versiones anteriores.

**Objetivos:**
- Ver historial de rollout
- Rollback a versión anterior
- Rollback a revisión específica
- Estrategias de rollback

---

### [Lab 04: Estrategia Recreate](./lab-04-recreate-strategy/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

Deployment con estrategia Recreate.

**Objetivos:**
- Configurar estrategia Recreate
- Comparar con RollingUpdate
- Casos de uso apropiados
- Trade-offs de downtime

---

### [Lab 05: Blue-Green Deployment](./lab-05-blue-green/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Implementación de Blue-Green deployments.

**Objetivos:**
- Crear entorno Blue y Green
- Switch de tráfico con Services
- Rollback instantáneo
- Estrategia para producción

---

### [Lab 06: Canary Deployments](./lab-06-canary/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Despliegues tipo canary para testing gradual.

**Objetivos:**
- Implementar canary releases
- Control de porcentaje de tráfico
- Métricas y monitoreo
- Promoción o rollback

---

### [Lab 07: Pausar y Reanudar](./lab-07-pausar-resume/)
**Duración:** 45-60 minutos | **Dificultad:** ⭐⭐⭐☆☆

Control fino de rollouts.

**Objetivos:**
- Pausar rollouts en progreso
- Realizar cambios múltiples
- Reanudar rollouts
- Casos de uso prácticos

---

### [Lab 08: Troubleshooting](./lab-08-troubleshooting/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐⭐

Diagnóstico y solución de problemas.

**Objetivos:**
- Diagnosticar rollouts fallidos
- ImagePullBackOff
- CrashLoopBackOff
- Problemas de resources
- Best practices de debugging

---

## 🎯 Ruta de Aprendizaje Recomendada

### Nivel 1: Fundamentos (Labs 01-04)
- Crear y gestionar Deployments básicos
- Rolling updates y rollbacks
- Estrategias básicas
**Tiempo:** 4-5 horas

### Nivel 2: Estrategias Avanzadas (Labs 05-07)
- Blue-Green deployments
- Canary releases
- Control avanzado de rollouts
**Tiempo:** 4-5 horas

### Nivel 3: Producción (Lab 08)
- Troubleshooting
- Debugging avanzado
- Production ready deployments
**Tiempo:** 1.5-2 horas

**Tiempo total estimado:** 10-12 horas

## 📚 Conceptos Clave

### Deployment
- Declarativo: defines el estado deseado
- Controlador: mantiene el estado actual = deseado
- Gestiona ReplicaSets automáticamente
- Historial de revisiones

### Estrategias de Deployment

**RollingUpdate (Default):**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # Pods extras durante update
    maxUnavailable: 0  # Pods que pueden estar down
```

**Recreate:**
```yaml
strategy:
  type: Recreate  # Termina todos, luego crea nuevos
```

### Rollout Commands

```bash
# Ver status
kubectl rollout status deployment/myapp

# Ver historial
kubectl rollout history deployment/myapp

# Rollback a versión anterior
kubectl rollout undo deployment/myapp

# Rollback a revisión específica
kubectl rollout undo deployment/myapp --to-revision=2

# Pausar rollout
kubectl rollout pause deployment/myapp

# Reanudar rollout
kubectl rollout resume deployment/myapp
```

## ⚠️ Antes de Comenzar

```bash
# Verificar cluster
kubectl cluster-info

# Ver deployments existentes
kubectl get deployments
kubectl get rs
kubectl get pods

# Habilitar metrics (útil para monitoreo)
minikube addons enable metrics-server
```

## 🧹 Limpieza

Cada lab incluye script de limpieza:
```bash
cd lab-XX-nombre
./cleanup.sh
```

## 💡 Best Practices

### Para Producción
- ✅ Siempre define readiness probes
- ✅ Usa RollingUpdate con maxUnavailable=0
- ✅ Define resource requests/limits
- ✅ Mantén historial de revisiones
- ✅ Prueba rollbacks en staging

### Estrategias por Escenario
- **Web apps 24/7**: RollingUpdate
- **Batch jobs**: Recreate
- **Critical services**: Blue-Green
- **A/B testing**: Canary
- **Microservices**: Canary + Progressive

### Monitoreo
- Observa logs durante rollout
- Monitorea métricas (latency, errors)
- Usa eventos de Kubernetes
- Configura alertas para rollouts fallidos
