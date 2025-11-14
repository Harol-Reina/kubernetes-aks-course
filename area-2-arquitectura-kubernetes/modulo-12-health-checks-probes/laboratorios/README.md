# 🏥 Laboratorios - Health Checks y Probes

Este módulo contiene laboratorios prácticos para dominar health checks y probes en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: Probes Básico](./lab-01-liveness-probes/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐☆☆☆

Introducción a liveness y readiness probes.

**Objetivos:**
- Configurar liveness probes
- Configurar readiness probes
- Entender diferencias entre tipos
- Observar restart automático

---

### [Lab 02: Startup Avanzado](./lab-02-readiness-probes/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐☆☆

Startup probes y configuraciones avanzadas.

**Objetivos:**
- Implementar startup probes
- Configurar tiempos y umbrales
- HTTP, TCP, y Exec probes
- Best practices

---

### [Lab 03: Troubleshooting](./lab-03-startup-probes/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Diagnóstico de problemas con probes.

**Objetivos:**
- Diagnosticar fallas de probes
- Analizar logs y eventos
- Optimizar configuraciones
- Casos de uso complejos

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (Probes básico)
2. **Nivel Intermedio** → Lab 02 (Startup avanzado)
3. **Nivel Avanzado** → Lab 03 (Troubleshooting)

**Tiempo total estimado:** 4-4.5 horas

## 📚 Tipos de Probes

### Liveness Probe
- ¿El container está vivo?
- Si falla → restart del container
- Detecta deadlocks y crashes

### Readiness Probe
- ¿El container está listo para tráfico?
- Si falla → removido de endpoints
- No recibe tráfico hasta que pase

### Startup Probe
- ¿El container terminó de iniciar?
- Para apps con inicio lento
- Deshabilita liveness/readiness durante startup

## 📊 Métodos de Probe

### HTTP GET
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
```

### TCP Socket
```yaml
livenessProbe:
  tcpSocket:
    port: 8080
```

### Exec Command
```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
```

## ⚠️ Antes de Comenzar

```bash
# Verificar cluster
kubectl cluster-info

# Ver pods en ejecución
kubectl get pods

# Monitorear eventos
kubectl get events --watch
```

## 🧹 Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```

## 💡 Best Practices

- Siempre usa readiness probes en producción
- Liveness probes solo si detecta problemas irrecuperables
- Startup probes para apps con inicio lento (>30s)
- Evita probes muy agresivos (frecuentes)
