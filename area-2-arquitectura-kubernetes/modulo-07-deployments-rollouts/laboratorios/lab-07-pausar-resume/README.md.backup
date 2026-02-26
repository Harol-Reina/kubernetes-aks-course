# 🧪 Laboratorio 07: Troubleshooting de Deployments

**Duración estimada**: 55 minutos  
**Dificultad**: Avanzado  
**Objetivo**: Diagnosticar y resolver problemas comunes en deployments

---

## 📋 Prerequisitos

```bash
# Verificar cluster
minikube status

# Crear namespace
kubectl create namespace lab-troubleshooting
kubectl config set-context --current --namespace=lab-troubleshooting

# Verificar
kubectl get ns lab-troubleshooting
```

---

## 🎯 Ejercicio 1: Deployment Stuck - Pods No Inician

### **Paso 1: Crear deployment con imagen inexistente**

Crea `broken-image.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-image-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
      - name: app
        image: nginx:nonexistent-tag-12345
        ports:
        - containerPort: 80
```

```bash
# Aplicar
kubectl apply -f broken-image.yaml

# Ver estado - pods en ImagePullBackOff/ErrImagePull
watch kubectl get pods -l app=broken-app
```

### **Paso 2: Diagnosticar el problema**

```bash
# Ver deployment status
kubectl get deployment broken-image-app
kubectl rollout status deployment/broken-image-app

# Ver detalles del deployment
kubectl describe deployment broken-image-app

# Ver pods
kubectl get pods -l app=broken-app

# Describir un pod específico
POD_NAME=$(kubectl get pods -l app=broken-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME

# Ver eventos del pod
kubectl get events --field-selector involvedObject.name=$POD_NAME --sort-by='.lastTimestamp'

# Buscar eventos de error
kubectl get events --sort-by='.lastTimestamp' | grep -i "error\|failed\|pull"
```

**🔍 Síntomas**:
- Pods en estado `ImagePullBackOff` o `ErrImagePull`
- Evento: `Failed to pull image "nginx:nonexistent-tag-12345"`
- Mensaje: `manifest for nginx:nonexistent-tag-12345 not found`

### **Paso 3: Solucionar el problema**

```bash
# Opción 1: Actualizar a imagen válida
kubectl set image deployment/broken-image-app app=nginx:1.21-alpine

# Opción 2: Editar el deployment
kubectl edit deployment broken-image-app
# Cambiar: image: nginx:1.21-alpine

# Verificar solución
kubectl rollout status deployment/broken-image-app
kubectl get pods -l app=broken-app
```

---

## 🎯 Ejercicio 2: Fallo en Readiness Probe

### **Paso 1: Deployment con readiness probe incorrecta**

Crea `broken-readiness.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-readiness-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: readiness-app
  template:
    metadata:
      labels:
        app: readiness-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /nonexistent-path  # Path que no existe
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
```

```bash
# Aplicar
kubectl apply -f broken-readiness.yaml

# Ver pods - Running pero NOT Ready
watch kubectl get pods -l app=readiness-app
```

### **Paso 2: Diagnosticar readiness probe failure**

```bash
# Ver estado de pods
kubectl get pods -l app=readiness-app

# Ver detalles - buscar Readiness
POD_NAME=$(kubectl get pods -l app=readiness-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME | grep -A 10 Readiness

# Ver logs del pod (puede no tener errores)
kubectl logs $POD_NAME

# Ver eventos del pod
kubectl get events --field-selector involvedObject.name=$POD_NAME

# Probar el readiness endpoint manualmente
kubectl exec $POD_NAME -- wget -O- http://localhost/nonexistent-path
# Esperado: 404 Not Found
```

**🔍 Síntomas**:
- Pods en `Running` pero `0/1 Ready`
- Evento: `Readiness probe failed: HTTP probe failed with statuscode: 404`
- Deployment no progresa

### **Paso 3: Solucionar readiness probe**

```bash
# Actualizar el path de readiness
kubectl patch deployment broken-readiness-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","readinessProbe":{"httpGet":{"path":"/"}}}]}}}}'

# O editar manualmente
kubectl edit deployment broken-readiness-app
# Cambiar: path: /

# Verificar solución
kubectl rollout status deployment/broken-readiness-app
kubectl get pods -l app=readiness-app
```

---

## 🎯 Ejercicio 3: Recursos Insuficientes (OOMKilled / CrashLoopBackOff)

### **Paso 1: Deployment con límites muy bajos**

Crea `oom-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oom-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: oom-app
  template:
    metadata:
      labels:
        app: oom-app
    spec:
      containers:
      - name: memory-hog
        image: polinux/stress
        command: ["stress"]
        args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
        resources:
          requests:
            memory: "50Mi"
          limits:
            memory: "100Mi"  # Muy bajo para la carga
```

```bash
# Aplicar
kubectl apply -f oom-deployment.yaml

# Ver pods - CrashLoopBackOff
watch kubectl get pods -l app=oom-app
```

### **Paso 2: Diagnosticar OOMKilled**

```bash
# Ver estado de pods
kubectl get pods -l app=oom-app

# Describir pod - buscar "OOMKilled"
POD_NAME=$(kubectl get pods -l app=oom-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME

# Ver razón del último estado
kubectl get pod $POD_NAME -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
# Esperado: OOMKilled

# Ver logs (puede estar vacío)
kubectl logs $POD_NAME
kubectl logs $POD_NAME --previous  # Logs del contenedor anterior

# Ver eventos
kubectl get events --field-selector involvedObject.name=$POD_NAME --sort-by='.lastTimestamp'

# Ver uso de recursos (si el pod está corriendo)
kubectl top pod $POD_NAME
```

**🔍 Síntomas**:
- Pods en `CrashLoopBackOff`
- `Last State: Terminated, Reason: OOMKilled`
- Exit Code: 137
- Mensaje: "Container exceeded its memory limit"

### **Paso 3: Solucionar límites de recursos**

```bash
# Aumentar límites de memoria
kubectl set resources deployment oom-app --limits=memory=200Mi --requests=memory=100Mi

# O editar
kubectl edit deployment oom-app

# Verificar solución
kubectl rollout status deployment/oom-app
kubectl get pods -l app=oom-app

# Verificar uso de recursos
kubectl top pods -l app=oom-app
```

---

## 🎯 Ejercicio 4: Rollout Stuck - Deployment No Progresa

### **Paso 1: Deployment con minReadySeconds y probe lento**

Crea `stuck-rollout.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stuck-rollout-app
spec:
  replicas: 5
  minReadySeconds: 30
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # No tolera downtime
  selector:
    matchLabels:
      app: stuck-app
  template:
    metadata:
      labels:
        app: stuck-app
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 60  # Muy lento
          periodSeconds: 10
```

```bash
# Aplicar versión inicial
kubectl apply -f stuck-rollout.yaml
kubectl rollout status deployment/stuck-rollout-app

# Actualizar imagen para activar rollout
kubectl set image deployment/stuck-rollout-app app=nginx:1.22-alpine

# Observar rollout lento
watch kubectl get pods -l app=stuck-app
```

### **Paso 2: Diagnosticar rollout stuck**

```bash
# Ver estado del rollout
kubectl rollout status deployment/stuck-rollout-app

# Ver progreso del deployment
kubectl get deployment stuck-rollout-app

# Ver replicasets - debería haber 2 (viejo y nuevo)
kubectl get rs -l app=stuck-app

# Ver detalles del deployment
kubectl describe deployment stuck-rollout-app

# Ver eventos del deployment
kubectl get events --sort-by='.lastTimestamp' | grep stuck-rollout-app

# Ver condiciones del deployment
kubectl get deployment stuck-rollout-app -o jsonpath='{.status.conditions[*]}'
```

**🔍 Síntomas**:
- Rollout toma mucho tiempo
- Pods nuevos demoran en estar Ready
- `Waiting for deployment spec update to be observed...`

### **Paso 3: Soluciones**

```bash
# Opción 1: Reducir minReadySeconds y initialDelaySeconds
kubectl patch deployment stuck-rollout-app -p '{"spec":{"minReadySeconds":5,"template":{"spec":{"containers":[{"name":"app","readinessProbe":{"initialDelaySeconds":10}}]}}}}'

# Opción 2: Pausar, ajustar, y reanudar
kubectl rollout pause deployment/stuck-rollout-app
kubectl edit deployment stuck-rollout-app  # Ajustar configuración
kubectl rollout resume deployment/stuck-rollout-app

# Opción 3: Rollback si hay problemas
kubectl rollout undo deployment/stuck-rollout-app

# Verificar
kubectl rollout status deployment/stuck-rollout-app
```

---

## 🎯 Ejercicio 5: Selector Mismatch

### **Paso 1: Deployment con selector incorrecto**

Crea `selector-mismatch.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: selector-mismatch-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
      version: v1  # Selector extra
  template:
    metadata:
      labels:
        app: my-app
        # Falta label 'version: v1'
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
```

```bash
# Intentar aplicar - debería fallar
kubectl apply -f selector-mismatch.yaml
```

**🔍 Error esperado**:
```
The Deployment "selector-mismatch-app" is invalid: 
spec.template.metadata.labels: Invalid value: 
  map[string]string{"app":"my-app"}: 
  `selector` does not match template `labels`
```

### **Paso 2: Solucionar selector mismatch**

```bash
# Corregir el YAML
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: selector-mismatch-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
      version: v1
  template:
    metadata:
      labels:
        app: my-app
        version: v1  # Agregar label faltante
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
EOF

# Verificar
kubectl get deployment selector-mismatch-app
```

---

## 🎯 Ejercicio 6: Problema de Permisos (SecurityContext)

### **Paso 1: Deployment con permisos insuficientes**

Crea `permission-issue.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: permission-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: permission-app
  template:
    metadata:
      labels:
        app: permission-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        securityContext:
          readOnlyRootFilesystem: true  # Problema: nginx necesita escribir
```

```bash
# Aplicar
kubectl apply -f permission-issue.yaml

# Ver pods - pueden estar en CrashLoopBackOff
watch kubectl get pods -l app=permission-app
```

### **Paso 2: Diagnosticar problema de permisos**

```bash
# Ver logs del pod
POD_NAME=$(kubectl get pods -l app=permission-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME

# Esperado: errores de permisos al escribir en /var/run, /var/cache

# Describir pod
kubectl describe pod $POD_NAME

# Verificar security context
kubectl get pod $POD_NAME -o jsonpath='{.spec.securityContext}'
kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].securityContext}'
```

**🔍 Síntomas**:
- Logs muestran "Permission denied" al escribir archivos
- Contenedor termina inmediatamente
- CrashLoopBackOff

### **Paso 3: Solucionar con volumes para escribir**

```bash
# Agregar volumes para paths que necesita escribir
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: permission-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: permission-app
  template:
    metadata:
      labels:
        app: permission-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        securityContext:
          readOnlyRootFilesystem: true
        volumeMounts:
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
      - name: tmp
        emptyDir: {}
EOF

# Verificar
kubectl rollout status deployment/permission-app
kubectl get pods -l app=permission-app
```

---

## 🎯 Ejercicio 7: Script de Troubleshooting Automatizado

### **Crear script de diagnóstico**

Crea `diagnose-deployment.sh`:

📄 Script de diagnóstico: [`diagnose-deployment.sh`](./diagnose-deployment.sh)

```bash
# Hacer ejecutable
chmod +x diagnose-deployment.sh

# Probar con deployments problemáticos
./diagnose-deployment.sh broken-image-app lab-troubleshooting
./diagnose-deployment.sh broken-readiness-app lab-troubleshooting
```

---

## 🎯 Ejercicio 8: Troubleshooting Checklist

### **Crear checklist de troubleshooting**

```bash
cat > troubleshooting-checklist.md << 'EOF'
# 🔍 Troubleshooting Checklist para Deployments

## 1. Verificación Básica
- [ ] `kubectl get deployment <name>` - Ver estado general
- [ ] `kubectl get pods -l app=<name>` - Ver pods del deployment
- [ ] `kubectl get events --sort-by='.lastTimestamp'` - Ver eventos recientes

## 2. Pods No Inician (Pending/ImagePullBackOff)
- [ ] Verificar imagen existe: `kubectl describe pod <pod-name> | grep Image`
- [ ] Verificar pull secrets si imagen es privada
- [ ] Verificar recursos suficientes en nodos: `kubectl top nodes`
- [ ] Verificar node selectors/affinity: `kubectl get pod <pod-name> -o yaml | grep -A 5 nodeSelector`

## 3. Pods en CrashLoopBackOff
- [ ] Ver logs: `kubectl logs <pod-name>`
- [ ] Ver logs previos: `kubectl logs <pod-name> --previous`
- [ ] Verificar exit code: `kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'`
- [ ] Verificar OOMKilled: `kubectl describe pod <pod-name> | grep OOMKilled`
- [ ] Verificar recursos: `kubectl top pod <pod-name>`

## 4. Pods Running pero NOT Ready
- [ ] Verificar readiness probe: `kubectl describe pod <pod-name> | grep -A 10 Readiness`
- [ ] Probar endpoint manualmente: `kubectl exec <pod-name> -- wget http://localhost:<port><path>`
- [ ] Ver eventos de readiness: `kubectl get events --field-selector involvedObject.name=<pod-name>`

## 5. Rollout Stuck/Slow
- [ ] Ver progreso: `kubectl rollout status deployment/<name>`
- [ ] Ver replicasets: `kubectl get rs -l app=<name>`
- [ ] Verificar minReadySeconds: `kubectl get deployment <name> -o jsonpath='{.spec.minReadySeconds}'`
- [ ] Verificar strategy: `kubectl get deployment <name> -o jsonpath='{.spec.strategy}'`
- [ ] Pausar si es necesario: `kubectl rollout pause deployment/<name>`

## 6. Problemas de Configuración
- [ ] Verificar labels coinciden: selector vs template
- [ ] Verificar variables de entorno: `kubectl exec <pod-name> -- env`
- [ ] Verificar configmaps montados: `kubectl describe pod <pod-name> | grep -A 5 Mounts`
- [ ] Verificar secrets: `kubectl get secrets`

## 7. Problemas de Red
- [ ] Verificar service endpoints: `kubectl get endpoints <service-name>`
- [ ] Probar conectividad: `kubectl exec <pod-name> -- wget <service-name>`
- [ ] Verificar NetworkPolicies: `kubectl get networkpolicies`

## 8. Problemas de Recursos
- [ ] Ver uso actual: `kubectl top pods -l app=<name>`
- [ ] Ver límites: `kubectl describe deployment <name> | grep -A 5 Limits`
- [ ] Ver HPA: `kubectl get hpa`

## 9. Comandos de Emergencia
- [ ] Rollback: `kubectl rollout undo deployment/<name>`
- [ ] Escalar a 0 (emergencia): `kubectl scale deployment <name> --replicas=0`
- [ ] Reiniciar: `kubectl rollout restart deployment/<name>`
- [ ] Eliminar y recrear: `kubectl delete deployment <name>` → `kubectl apply -f <file>`
EOF

cat troubleshooting-checklist.md
```

---

## 🧹 Limpieza

```bash
# Eliminar todos los recursos problemáticos
kubectl delete deployment --all -n lab-troubleshooting
kubectl delete namespace lab-troubleshooting

# Restaurar namespace
kubectl config set-context --current --namespace=default
```

---

## ✅ Checklist de Completitud

- [ ] Diagnosticar y resolver ImagePullBackOff
- [ ] Diagnosticar y resolver Readiness probe failures
- [ ] Diagnosticar y resolver OOMKilled/CrashLoopBackOff
- [ ] Diagnosticar y resolver rollout stuck
- [ ] Identificar y resolver selector mismatch
- [ ] Diagnosticar y resolver problemas de permisos
- [ ] Usar script automatizado de diagnóstico
- [ ] Seguir checklist de troubleshooting

---

## 🎓 Resumen

En este laboratorio aprendiste:

- ✅ Diagnosticar pods que no inician (ImagePullBackOff)
- ✅ Resolver fallos de readiness/liveness probes
- ✅ Identificar y resolver OOMKilled
- ✅ Diagnosticar rollouts stuck
- ✅ Resolver problemas de selector mismatch
- ✅ Solucionar problemas de permisos y security context
- ✅ Crear scripts de diagnóstico automatizado
- ✅ Usar checklist sistemático de troubleshooting

**Próximo**: Lab 08 - Proyecto Integrador 🚀
