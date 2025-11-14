# Ejemplo 01: Broken Applications - Aplicaciones con Errores Intencionales

> **Objetivo**: Practicar diagnóstico de los errores más comunes en aplicaciones Kubernetes  
> **Dificultad**: ⭐⭐⭐ (Intermedio-Avanzado)  
> **Tiempo estimado**: 30-45 minutos

## 📋 Descripción

Este ejemplo contiene 12 pods con errores intencionales que representan los problemas más comunes en producción. Cada pod tiene un error diferente que debes diagnosticar y corregir.

## 🎯 Objetivos de Aprendizaje

- ✅ Diagnosticar CrashLoopBackOff
- ✅ Resolver ImagePullBackOff
- ✅ Identificar OOMKilled (out of memory)
- ✅ Troubleshoot init containers
- ✅ Debuggear liveness/readiness probes
- ✅ Resolver ConfigMaps y Secrets faltantes
- ✅ Identificar errores en comandos y argumentos
- ✅ Diagnosticar problemas de CPU throttling
- ✅ Resolver errores de volume mounts
- ✅ Identificar port mismatches

## 📁 Archivos en este Ejemplo

```
01-broken-apps/
├── README.md                    # Este archivo
├── broken-apps.yaml             # 12 pods con errores intencionales
└── cleanup.sh                   # Script para limpiar recursos
```

## 🚀 Instrucciones de Uso

### 1. Aplicar los Pods con Errores

```bash
# Aplicar todos los pods
kubectl apply -f broken-apps.yaml

# Ver el estado (todos tendrán problemas)
kubectl get pods
```

### 2. Diagnosticar Cada Pod

Para cada pod, usa este workflow:

```bash
# 1. Ver estado general
kubectl get pod <pod-name>

# 2. Describir para ver eventos
kubectl describe pod <pod-name>

# 3. Ver logs actuales
kubectl logs <pod-name>

# 4. Ver logs del crash anterior (si aplica)
kubectl logs <pod-name> --previous

# 5. Ver spec completo
kubectl get pod <pod-name> -o yaml
```

### 3. Lista de Pods y Sus Errores

| # | Pod Name | Error Intencional | Estado Esperado | Comandos Clave |
|---|----------|-------------------|-----------------|----------------|
| 1 | `broken-crashloop` | Script inexistente | CrashLoopBackOff | `kubectl logs --previous` |
| 2 | `broken-imagepull` | Tag de imagen inválido | ImagePullBackOff | `kubectl describe` |
| 3 | `broken-oom` | Memory limit muy bajo | OOMKilled (Exit 137) | `kubectl describe` + check limits |
| 4 | `broken-init` | Init espera servicio inexistente | Init:0/1 | `kubectl logs -c <init-container>` |
| 5 | `broken-liveness` | Probe apunta a endpoint inexistente | Reinicia constantemente | `kubectl describe` + Events |
| 6 | `broken-readiness` | Readiness probe en puerto incorrecto | Running pero 0/1 Ready | `kubectl get endpoints` |
| 7 | `broken-configmap` | ConfigMap no existe | CreateContainerConfigError | `kubectl describe` |
| 8 | `broken-secret` | Secret no existe | CreateContainerConfigError | `kubectl describe` |
| 9 | `broken-command` | Comando mal escrito | CrashLoopBackOff | `kubectl logs` |
| 10 | `broken-cpu` | CPU limits demasiado bajos | Running pero throttled | `kubectl top pod` |
| 11 | `broken-volume` | Volume mount path incorrecto | CrashLoopBackOff | `kubectl describe` + volumeMounts |
| 12 | `broken-port` | containerPort incorrecto | Running pero no funciona | `kubectl exec` + test |

## 🔍 Ejemplos de Diagnóstico

### Ejemplo 1: CrashLoopBackOff

```bash
# Ver estado
kubectl get pod broken-crashloop
# STATUS: CrashLoopBackOff

# Ver logs del crash
kubectl logs broken-crashloop --previous
# Output: /app/nonexistent.sh: not found

# Causa: El script especificado no existe en la imagen
# Fix: Cambiar a un comando válido o crear el script
```

### Ejemplo 2: ImagePullBackOff

```bash
# Describir el pod
kubectl describe pod broken-imagepull | grep -A 5 Events
# Output: Failed to pull image "nginx:nonexistent-tag"

# Causa: El tag no existe en Docker Hub
# Fix: kubectl set image pod/broken-imagepull app=nginx:1.21
```

### Ejemplo 3: OOMKilled

```bash
# Ver último estado
kubectl describe pod broken-oom | grep "Last State" -A 5
# Output: Reason: OOMKilled, Exit Code: 137

# Ver limits
kubectl get pod broken-oom -o jsonpath='{.spec.containers[0].resources.limits.memory}'
# Output: 100Mi (muy bajo)

# Causa: App necesita más memoria que el límite
# Fix: Aumentar memory limits a 512Mi o más
```

## 🛠️ Soluciones Rápidas

<details>
<summary>🔧 Soluciones para cada Pod</summary>

### 1. broken-crashloop
```bash
kubectl delete pod broken-crashloop
# Recrear con comando válido
kubectl run broken-crashloop --image=nginx -- nginx -g "daemon off;"
```

### 2. broken-imagepull
```bash
kubectl set image pod/broken-imagepull app=nginx:1.21
```

### 3. broken-oom
```bash
kubectl delete pod broken-oom
# Recrear con más memoria (ver broken-apps.yaml, sección "Fixed")
```

### 4. broken-init
```bash
# Opción 1: Crear el servicio que espera
kubectl run postgres --image=postgres:13 --env="POSTGRES_PASSWORD=pass"
kubectl expose pod postgres --port=5432 --name=postgres-service

# Opción 2: Eliminar el init container
```

### 5. broken-liveness
```bash
kubectl delete pod broken-liveness
# Recrear con probe apuntando a / en lugar de /healthz
```

### 6. broken-readiness
```bash
kubectl delete pod broken-readiness
# Recrear con readiness probe en puerto correcto (80)
```

### 7. broken-configmap
```bash
kubectl create configmap app-config --from-literal=key1=value1
# El pod se autocorregirá
```

### 8. broken-secret
```bash
kubectl create secret generic app-secret --from-literal=password=secret123
# El pod se autocorregirá
```

### 9. broken-command
```bash
kubectl delete pod broken-command
kubectl run broken-command --image=busybox:1.28 -- sh -c "while true; do echo ok; sleep 10; done"
```

### 10. broken-cpu
```bash
# Observar throttling
kubectl top pod broken-cpu
# Fix: Aumentar CPU limits
```

### 11. broken-volume
```bash
kubectl delete pod broken-volume
# Recrear con mountPath correcto (/data en lugar de /wrong-path)
```

### 12. broken-port
```bash
kubectl delete pod broken-port
# Recrear con containerPort correcto
```

</details>

## 🧪 Práctica Guiada

### Ejercicio 1: Diagnosticar los 3 primeros pods
**Tiempo**: 10 minutos

1. Aplica `broken-apps.yaml`
2. Diagnostica `broken-crashloop`, `broken-imagepull`, `broken-oom`
3. Documenta tus hallazgos
4. Implementa las correcciones

### Ejercicio 2: Init Containers y Probes
**Tiempo**: 10 minutos

1. Diagnostica `broken-init`, `broken-liveness`, `broken-readiness`
2. Identifica las diferencias entre liveness y readiness
3. Corrige los problemas

### Ejercicio 3: Configuración y Recursos
**Tiempo**: 10 minutos

1. Diagnostica pods relacionados a ConfigMaps, Secrets, CPU
2. Crea los recursos faltantes
3. Verifica que los pods funcionen

## 🧹 Limpieza

```bash
# Usar el script de limpieza
chmod +x cleanup.sh
./cleanup.sh

# O manualmente
kubectl delete pod broken-crashloop broken-imagepull broken-oom \
  broken-init broken-liveness broken-readiness \
  broken-configmap broken-secret broken-command \
  broken-cpu broken-volume broken-port

# Limpiar recursos creados
kubectl delete configmap app-config
kubectl delete secret app-secret
kubectl delete pod postgres
kubectl delete svc postgres-service
```

## 📚 Comandos de Referencia Rápida

```bash
# Estado general
kubectl get pods
kubectl get pods -o wide

# Diagnóstico detallado
kubectl describe pod <name>
kubectl logs <name>
kubectl logs <name> --previous
kubectl logs <name> -c <container-name>

# Recursos
kubectl top pod <name>
kubectl get pod <name> -o yaml

# Eventos
kubectl get events --sort-by='.lastTimestamp'
kubectl get events --field-selector involvedObject.name=<pod-name>

# Ejecución interactiva
kubectl exec -it <name> -- sh
```

## 🎯 Checklist de Aprendizaje

- [ ] Puedo diagnosticar CrashLoopBackOff en <2 minutos
- [ ] Identifico ImagePullBackOff rápidamente con `describe`
- [ ] Reconozco OOMKilled por exit code 137
- [ ] Sé debuggear init containers con logs
- [ ] Entiendo diferencia entre liveness y readiness probes
- [ ] Puedo identificar recursos faltantes (ConfigMap/Secret)
- [ ] Diagnostico errores de comandos con logs
- [ ] Identifico CPU throttling con `top`
- [ ] Troubleshoot volume mount issues
- [ ] Resuelvo port mismatches

## 📖 Recursos Adicionales

- [Kubernetes Documentation - Debug Pods](https://kubernetes.io/docs/tasks/debug/debug-application/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Exit Codes Reference](https://komodor.com/learn/exit-codes-in-containers-and-kubernetes/)

---

**Siguiente**: [Ejemplo 02 - Troubleshooting Tools](../02-troubleshooting-tools/)
