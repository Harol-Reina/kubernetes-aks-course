# 📦 Ejemplos de Pods - Casos de Uso Comunes

Esta carpeta contiene manifiestos YAML listos para usar que cubren los casos de uso más comunes de Pods en Kubernetes.

---

## 📁 Estructura de Ejemplos

```
ejemplos/
├── basicos/           # Pods simples y fundamentales
├── multi-contenedor/  # Pods con múltiples contenedores
├── patterns/          # Patrones de diseño (Sidecar, Ambassador, Adapter)
├── troubleshooting/   # Ejemplos para debugging
└── production-ready/  # Ejemplos con best practices
```

---

## 🚀 Uso Rápido

### **Aplicar un ejemplo**

```bash
# Navegar a la carpeta de ejemplos
cd ejemplos/

# Aplicar ejemplo específico
kubectl apply -f basicos/pod-nginx.yaml

# Aplicar todos los ejemplos de una carpeta
kubectl apply -f basicos/

# Aplicar recursivamente
kubectl apply -f . --recursive
```

### **Verificar**

```bash
# Ver Pods creados
kubectl get pods

# Ver con labels
kubectl get pods --show-labels

# Filtrar por ejemplo
kubectl get pods -l example=true
```

### **Limpiar**

```bash
# Eliminar ejemplo específico
kubectl delete -f basicos/pod-nginx.yaml

# Eliminar todos los ejemplos
kubectl delete -f . --recursive
```

---

## 📖 Índice de Ejemplos

### **Básicos** (`basicos/`)

| Archivo | Descripción | Labels |
|---------|-------------|--------|
| `pod-nginx.yaml` | Pod simple con NGINX | `app: nginx` |
| `pod-alpine.yaml` | Pod con Alpine para testing | `app: test` |
| `pod-python.yaml` | Pod con Python HTTP server | `app: python` |
| `pod-con-env.yaml` | Pod con variables de entorno | `app: env-demo` |
| `pod-con-recursos.yaml` | Pod con limits y requests | `app: resources` |

### **Multi-Contenedor** (`multi-contenedor/`)

| Archivo | Descripción | Contenedores |
|---------|-------------|--------------|
| `pod-dos-contenedores.yaml` | Nginx + Python | 2 |
| `pod-shared-volume.yaml` | Contenedores con volumen compartido | 2 |
| `pod-init-container.yaml` | Init container + main container | 1 init + 1 main |

### **Patterns** (`patterns/`)

| Archivo | Descripción | Patrón |
|---------|-------------|--------|
| `sidecar-logging.yaml` | App + Log processor | Sidecar |
| `ambassador-redis.yaml` | App + Redis proxy | Ambassador |
| `adapter-monitoring.yaml` | App + Metrics adapter | Adapter |

### **Troubleshooting** (`troubleshooting/`)

| Archivo | Descripción | Propósito |
|---------|-------------|-----------|
| `pod-error-image.yaml` | Imagen inexistente | Practicar debugging |
| `pod-crashloop.yaml` | Comando que falla | Ver CrashLoopBackOff |
| `pod-slow-start.yaml` | Startup lento | Probes y timeouts |

### **Production Ready** (`production-ready/`)

| Archivo | Descripción | Features |
|---------|-------------|----------|
| `pod-full-config.yaml` | Configuración completa | Probes, resources, security |
| `pod-security-context.yaml` | Security best practices | RunAsNonRoot, ReadOnly FS |
| `pod-with-probes.yaml` | Health checks completos | Liveness, Readiness, Startup |

---

## 🎯 Casos de Uso por Escenario

### **Escenario 1: Desarrollo Local**

```bash
# Testing rápido con Alpine
kubectl apply -f basicos/pod-alpine.yaml
kubectl exec -it alpine-test -- sh

# Servidor web de prueba
kubectl apply -f basicos/pod-python.yaml
kubectl port-forward pod/python-server 8080:8080
```

### **Escenario 2: Debugging de Aplicaciones**

```bash
# Pod con herramientas de debugging
kubectl apply -f troubleshooting/pod-debug-tools.yaml
kubectl exec -it debug-tools -- bash

# Simular errores comunes
kubectl apply -f troubleshooting/pod-error-image.yaml
kubectl describe pod error-image
```

### **Escenario 3: Aprendizaje de Patrones**

```bash
# Sidecar para logs
kubectl apply -f patterns/sidecar-logging.yaml
kubectl logs app-con-sidecar -c app -f
kubectl logs app-con-sidecar -c log-processor -f

# Ambassador para proxy
kubectl apply -f patterns/ambassador-redis.yaml
```

### **Escenario 4: Preparación para Producción**

```bash
# Pod con configuración completa
kubectl apply -f production-ready/pod-full-config.yaml
kubectl describe pod production-app

# Verificar security context
kubectl get pod production-app -o jsonpath='{.spec.securityContext}' | jq
```

---

## 🔧 Personalización

### **Plantilla Base**

Todos los ejemplos siguen esta estructura:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <nombre-descriptivo>
  labels:
    app: <app-name>
    example: "true"      # ← Marca como ejemplo
    category: <basico|pattern|troubleshoot>
  annotations:
    description: "Descripción del ejemplo"
spec:
  containers:
  - name: <container-name>
    image: <image:tag>
    # ... configuración
```

### **Variables de Entorno Comunes**

```yaml
env:
- name: ENV
  value: "development"
- name: LOG_LEVEL
  value: "debug"
- name: PORT
  value: "8080"
```

### **Resources Recomendados**

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

---

## 📚 Recursos Adicionales

- 📖 [Documentación principal del módulo](../README.md)
- 🧪 [Laboratorios prácticos](../laboratorios/)
- 🎓 [Kubernetes Pods - Oficial](https://kubernetes.io/docs/concepts/workloads/pods/)

---

## ⚠️ Notas Importantes

1. **Todos los ejemplos usan `example: "true"` label** - Facilita limpiar después:
   ```bash
   kubectl delete pods -l example=true
   ```

2. **No usar en producción directamente** - Estos son ejemplos educativos. Para producción, usa Deployments.

3. **Versiones de imágenes** - Los ejemplos usan versiones específicas (ej: `nginx:1.25-alpine`). Actualiza según necesites.

4. **Recursos asignados** - Los limits/requests son conservadores. Ajusta según tu workload.

---

**📅 Actualizado**: Noviembre 2025  
**🔖 Versión**: 1.0
