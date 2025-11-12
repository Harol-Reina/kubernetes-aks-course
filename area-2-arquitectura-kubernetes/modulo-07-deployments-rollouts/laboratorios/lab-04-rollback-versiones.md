# 🧪 Laboratorio 04: Rollback Avanzado y Gestión de Versiones

**Duración estimada**: 45 minutos  
**Dificultad**: Intermedio-Avanzado  
**Objetivo**: Dominar técnicas avanzadas de rollback, historial de versiones y recuperación de fallos

---

## 📋 Prerequisitos

```bash
# Verificar cluster
minikube status

# Crear namespace
kubectl create namespace lab-rollback-avanzado
kubectl config set-context --current --namespace=lab-rollback-avanzado

# Verificar
kubectl get ns lab-rollback-avanzado
```

---

## 🎯 Ejercicio 1: Rollback con Historial Limitado

### **Paso 1: Deployment con historial limitado**

Crea `app-version-limit.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-version-limit
  annotations:
    kubernetes.io/change-cause: "Versión inicial 1.0.0"
spec:
  replicas: 3
  revisionHistoryLimit: 3  # Solo mantener 3 revisiones
  selector:
    matchLabels:
      app: version-app
  template:
    metadata:
      labels:
        app: version-app
        version: "1.0.0"
    spec:
      containers:
      - name: nginx
        image: nginx:1.19-alpine
        ports:
        - containerPort: 80
        env:
        - name: VERSION
          value: "1.0.0"
```

```bash
# Aplicar
kubectl apply -f app-version-limit.yaml

# Verificar
kubectl get deployment app-version-limit
kubectl rollout status deployment/app-version-limit
```

### **Paso 2: Crear múltiples versiones**

```bash
# Versión 2.0.0
kubectl set image deployment/app-version-limit nginx=nginx:1.20-alpine \
  --record=false
kubectl annotate deployment/app-version-limit \
  kubernetes.io/change-cause="Actualización a 2.0.0 - nginx 1.20"

# Esperar rollout
kubectl rollout status deployment/app-version-limit

# Versión 3.0.0
kubectl set image deployment/app-version-limit nginx=nginx:1.21-alpine
kubectl annotate deployment/app-version-limit \
  kubernetes.io/change-cause="Actualización a 3.0.0 - nginx 1.21"

# Versión 4.0.0
kubectl set image deployment/app-version-limit nginx=nginx:1.22-alpine
kubectl annotate deployment/app-version-limit \
  kubernetes.io/change-cause="Actualización a 4.0.0 - nginx 1.22"

# Versión 5.0.0
kubectl set image deployment/app-version-limit nginx=nginx:1.23-alpine
kubectl annotate deployment/app-version-limit \
  kubernetes.io/change-cause="Actualización a 5.0.0 - nginx 1.23"
```

### **Paso 3: Ver historial limitado**

```bash
# Ver historial (solo 3 revisiones)
kubectl rollout history deployment/app-version-limit

# Esperado (solo últimas 3):
# REVISION  CHANGE-CAUSE
# 3         Actualización a 3.0.0 - nginx 1.21
# 4         Actualización a 4.0.0 - nginx 1.22
# 5         Actualización a 5.0.0 - nginx 1.23

# Las revisiones 1 y 2 fueron eliminadas automáticamente
```

**❓ Pregunta**: ¿Por qué es importante `revisionHistoryLimit` en producción?

---

## 🎯 Ejercicio 2: Rollback a Revisión Específica

### **Paso 1: Deployment con múltiples cambios**

Crea `app-multi-version.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-multi-version
  annotations:
    kubernetes.io/change-cause: "Release 1.0 - Versión estable"
spec:
  replicas: 4
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: multi-app
  template:
    metadata:
      labels:
        app: multi-app
    spec:
      containers:
      - name: app
        image: nginx:1.19-alpine
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

```bash
# Aplicar
kubectl apply -f app-multi-version.yaml

# Verificar
kubectl get deployment app-multi-version -o wide
```

### **Paso 2: Hacer varios cambios**

```bash
# Cambio 1: Actualizar imagen (Release 2.0)
kubectl set image deployment/app-multi-version app=nginx:1.20-alpine
kubectl annotate deployment/app-multi-version \
  kubernetes.io/change-cause="Release 2.0 - Nueva funcionalidad"
kubectl rollout status deployment/app-multi-version

# Cambio 2: Aumentar recursos (Release 2.1)
kubectl set resources deployment/app-multi-version \
  -c=app --requests=memory=128Mi,cpu=200m --limits=memory=256Mi,cpu=400m
kubectl annotate deployment/app-multi-version \
  kubernetes.io/change-cause="Release 2.1 - Optimización de recursos"
kubectl rollout status deployment/app-multi-version

# Cambio 3: Cambiar replicas (Release 2.2)
kubectl scale deployment/app-multi-version --replicas=6
kubectl annotate deployment/app-multi-version \
  kubernetes.io/change-cause="Release 2.2 - Escalado para alta demanda"

# Cambio 4: Imagen problemática (Release 3.0 - FALLA)
kubectl set image deployment/app-multi-version app=nginx:invalid-tag
kubectl annotate deployment/app-multi-version \
  kubernetes.io/change-cause="Release 3.0 - PROBLEMA: Imagen inválida"
```

### **Paso 3: Ver historial completo**

```bash
# Ver todas las revisiones
kubectl rollout history deployment/app-multi-version

# Ver detalles de una revisión específica
kubectl rollout history deployment/app-multi-version --revision=2

# Ver detalles de la revisión actual (problemática)
kubectl rollout history deployment/app-multi-version --revision=5
```

### **Paso 4: Rollback a revisión específica**

```bash
# Ver estado actual (con fallas)
kubectl get pods -l app=multi-app

# Rollback a revisión 3 (Release 2.1 - versión estable)
kubectl rollout undo deployment/app-multi-version --to-revision=3

# Monitorear rollback
kubectl rollout status deployment/app-multi-version

# Verificar versión restaurada
kubectl get deployment app-multi-version -o jsonpath='{.spec.template.spec.containers[0].image}'
# Esperado: nginx:1.20-alpine

kubectl get deployment app-multi-version -o jsonpath='{.spec.template.spec.containers[0].resources}'
# Verificar recursos de la revisión 3
```

**❓ Pregunta**: ¿Qué sucede con el número de revisión después del rollback?

---

## 🎯 Ejercicio 3: Detección y Recuperación Automática

### **Paso 1: Deployment con readiness probe**

Crea `app-auto-recovery.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-auto-recovery
  annotations:
    kubernetes.io/change-cause: "Versión estable con health checks"
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: recovery-app
  template:
    metadata:
      labels:
        app: recovery-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
```

```bash
# Aplicar
kubectl apply -f app-auto-recovery.yaml

# Verificar estado healthy
kubectl get pods -l app=recovery-app
kubectl rollout status deployment/app-auto-recovery
```

### **Paso 2: Actualización fallida con health checks**

```bash
# Actualizar a imagen que falla health checks
kubectl set image deployment/app-auto-recovery nginx=busybox:latest
kubectl annotate deployment/app-auto-recovery \
  kubernetes.io/change-cause="FALLA: Imagen sin nginx (health check fail)"

# Observar el rollout (se detendrá automáticamente)
watch kubectl get pods -l app=recovery-app
```

**Observar**:
- Los nuevos pods quedan en estado `Running` pero NOT `Ready`
- Los pods antiguos se mantienen en ejecución (gracias a `maxUnavailable: 1`)
- El rollout se detiene automáticamente al detectar fallos

```bash
# Ver estado del rollout
kubectl rollout status deployment/app-auto-recovery
# Esperado: "Waiting for deployment spec update to be observed..."

# Ver pods - algunos antiguos, algunos nuevos (fallando)
kubectl get pods -l app=recovery-app -o wide
```

### **Paso 3: Rollback automático**

```bash
# Hacer rollback
kubectl rollout undo deployment/app-auto-recovery

# Monitorear recuperación
kubectl rollout status deployment/app-auto-recovery

# Verificar todos los pods healthy
kubectl get pods -l app=recovery-app

# Esperado: todos los pods en estado Ready 1/1
```

**✅ Verificación**:
```bash
# Ver historial
kubectl rollout history deployment/app-auto-recovery

# Verificar imagen actual
kubectl get deployment app-auto-recovery -o jsonpath='{.spec.template.spec.containers[0].image}'
# Esperado: nginx:1.21-alpine (versión estable restaurada)
```

---

## 🎯 Ejercicio 4: Rollback Progresivo con Pausa

### **Paso 1: Deployment para rollback controlado**

Crea `app-controlled-rollback.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-controlled-rollback
  annotations:
    kubernetes.io/change-cause: "Producción v1.0 - Estable"
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 2
      maxSurge: 2
  selector:
    matchLabels:
      app: controlled-app
  template:
    metadata:
      labels:
        app: controlled-app
        version: "1.0"
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
```

```bash
# Aplicar
kubectl apply -f app-controlled-rollback.yaml
kubectl rollout status deployment/app-controlled-rollback
```

### **Paso 2: Actualización con pausa inmediata**

```bash
# Actualizar y pausar inmediatamente
kubectl set image deployment/app-controlled-rollback app=nginx:1.22-alpine && \
  kubectl rollout pause deployment/app-controlled-rollback
kubectl annotate deployment/app-controlled-rollback \
  kubernetes.io/change-cause="v2.0 - Rollout pausado para validación"

# Ver estado - debería haber mix de versiones
kubectl get pods -l app=controlled-app -L version
```

### **Paso 3: Detectar problema y rollback pausado**

```bash
# Simular detección de problema
echo "⚠️ PROBLEMA DETECTADO: Latencia alta en v2.0"

# Ver estado actual
kubectl get deployment app-controlled-rollback

# Hacer rollback mientras está pausado
kubectl rollout undo deployment/app-controlled-rollback

# Reanudar para completar el rollback
kubectl rollout resume deployment/app-controlled-rollback

# Monitorear rollback completo
kubectl rollout status deployment/app-controlled-rollback
```

### **Paso 4: Verificar rollback exitoso**

```bash
# Ver todos los pods
kubectl get pods -l app=controlled-app -o wide

# Verificar imagen
kubectl get deployment app-controlled-rollback -o jsonpath='{.spec.template.spec.containers[0].image}'
# Esperado: nginx:1.21-alpine

# Ver historial
kubectl rollout history deployment/app-controlled-rollback
```

**❓ Pregunta**: ¿Cuál es la ventaja de hacer rollback con el deployment pausado?

---

## 🎯 Ejercicio 5: Estrategia de Rollback en Producción

### **Paso 1: Deployment production-ready**

Crea `app-production.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-production
  annotations:
    kubernetes.io/change-cause: "Production Release v1.0.0"
    deployment.kubernetes.io/revision-notes: "Versión estable inicial"
spec:
  replicas: 6
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 2
  selector:
    matchLabels:
      app: prod-app
      tier: frontend
  template:
    metadata:
      labels:
        app: prod-app
        tier: frontend
        version: "1.0.0"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "80"
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
          name: http
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 2
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 15
          periodSeconds: 10
        resources:
          requests:
            memory: "128Mi"
            cpu: "200m"
          limits:
            memory: "256Mi"
            cpu: "500m"
```

```bash
# Aplicar
kubectl apply -f app-production.yaml
kubectl rollout status deployment/app-production
```

### **Paso 2: Rollout fallido simulado**

```bash
# Release v2.0.0 con problema
kubectl set image deployment/app-production app=nginx:invalid-version
kubectl annotate deployment/app-production \
  kubernetes.io/change-cause="Production Release v2.0.0 - ROLLBACK REQUIRED"

# Observar fallo (en otra terminal)
watch kubectl get pods -l app=prod-app

# Ver eventos
kubectl get events --sort-by='.lastTimestamp' | grep app-production
```

### **Paso 3: Proceso de rollback documentado**

```bash
# 1. Confirmar problema
kubectl get deployment app-production
kubectl describe deployment app-production | tail -20

# 2. Ver historial y identificar última versión estable
kubectl rollout history deployment/app-production

# 3. Ejecutar rollback
echo "🚨 Iniciando rollback a última versión estable..."
kubectl rollout undo deployment/app-production

# 4. Monitorear recuperación
kubectl rollout status deployment/app-production

# 5. Verificar health de todos los pods
kubectl get pods -l app=prod-app
kubectl wait --for=condition=ready pod -l app=prod-app --timeout=120s

# 6. Verificar imagen restaurada
kubectl get deployment app-production -o jsonpath='{.spec.template.spec.containers[0].image}'

# 7. Documentar incidente
kubectl annotate deployment app-production \
  kubernetes.io/change-cause="Rollback completado - Restaurado a v1.0.0 estable" --overwrite
```

### **Paso 4: Crear script de rollback**

Crea `rollback-production.sh`:

```bash
#!/bin/bash
# Script de rollback de emergencia

DEPLOYMENT=$1
NAMESPACE=${2:-default}

echo "🚨 ROLLBACK DE EMERGENCIA"
echo "Deployment: $DEPLOYMENT"
echo "Namespace: $NAMESPACE"
echo ""

# Verificar estado actual
echo "📊 Estado actual:"
kubectl get deployment $DEPLOYMENT -n $NAMESPACE

# Mostrar historial
echo ""
echo "📜 Historial de revisiones:"
kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE

# Confirmar rollback
echo ""
read -p "¿Ejecutar rollback a revisión anterior? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "⏪ Ejecutando rollback..."
    kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
    
    echo "⏳ Esperando rollback completo..."
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
    
    echo "✅ Verificando pods..."
    kubectl get pods -l app=$DEPLOYMENT -n $NAMESPACE
    
    echo ""
    echo "✅ ROLLBACK COMPLETADO"
fi
```

```bash
# Hacer ejecutable
chmod +x rollback-production.sh

# Probar (no ejecutar, solo ver)
# ./rollback-production.sh app-production lab-rollback-avanzado
```

---

## 🎯 Ejercicio 6: Rollback con Estrategia Recreate

### **Paso 1: Deployment con estrategia Recreate**

Crea `app-recreate-rollback.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-recreate
  annotations:
    kubernetes.io/change-cause: "v1.0 - Estrategia Recreate"
spec:
  replicas: 3
  strategy:
    type: Recreate  # Termina todos los pods antes de crear nuevos
  selector:
    matchLabels:
      app: recreate-app
  template:
    metadata:
      labels:
        app: recreate-app
    spec:
      containers:
      - name: app
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
```

```bash
# Aplicar
kubectl apply -f app-recreate-rollback.yaml
kubectl get pods -l app=recreate-app -w
```

### **Paso 2: Actualización y rollback con Recreate**

```bash
# Actualizar (observar downtime)
kubectl set image deployment/app-recreate app=nginx:1.21-alpine
kubectl annotate deployment/app-recreate \
  kubernetes.io/change-cause="v2.0 - Actualización con downtime"

# En otra terminal, observar:
watch kubectl get pods -l app=recreate-app

# Rollback (también con downtime)
kubectl rollout undo deployment/app-recreate

# Monitorear
kubectl rollout status deployment/app-recreate
```

**❓ Pregunta**: ¿Cuándo es apropiado usar `Recreate` vs `RollingUpdate` para rollback?

---

## 🧹 Limpieza

```bash
# Eliminar todos los recursos
kubectl delete deployment --all -n lab-rollback-avanzado
kubectl delete namespace lab-rollback-avanzado

# Restaurar namespace
kubectl config set-context --current --namespace=default
```

---

## ✅ Checklist de Completitud

- [ ] Entender `revisionHistoryLimit` y su impacto
- [ ] Realizar rollback a revisión específica con `--to-revision`
- [ ] Usar health checks para detección automática de fallos
- [ ] Combinar pause/resume con rollback
- [ ] Implementar proceso documentado de rollback en producción
- [ ] Crear script de rollback automatizado
- [ ] Comparar rollback con Recreate vs RollingUpdate

---

## 🎓 Resumen

En este laboratorio aprendiste:

- ✅ Gestión avanzada del historial de revisiones
- ✅ Rollback a versiones específicas no solo la anterior
- ✅ Detección automática de fallos con health checks
- ✅ Rollback progresivo con pause/resume
- ✅ Proceso production-ready de rollback
- ✅ Automatización de rollback con scripts
- ✅ Diferencias en rollback con distintas estrategias

**Próximo**: Lab 05 - Estrategias Avanzadas de Deployment 🚀
