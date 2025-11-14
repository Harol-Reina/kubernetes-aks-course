# 🧪 Laboratorio 05: Estrategias Avanzadas de Deployment

**Duración estimada**: 60 minutos  
**Dificultad**: Avanzado  
**Objetivo**: Implementar estrategias Blue-Green y Canary para deployments sin downtime

---

## 📋 Prerequisitos

```bash
# Verificar cluster
minikube status

# Crear namespace
kubectl create namespace lab-estrategias
kubectl config set-context --current --namespace=lab-estrategias

# Verificar
kubectl get ns lab-estrategias
```

---

## 🎯 Ejercicio 1: Blue-Green Deployment Manual

### **Paso 1: Crear versión "Blue" (actual en producción)**

Crea `blue-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
  labels:
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        env:
        - name: VERSION
          value: "v1.0-blue"
        - name: COLOR
          value: "blue"
```

Crea `service-production.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-production
spec:
  type: NodePort
  selector:
    app: myapp
    version: blue  # Apunta a Blue inicialmente
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

```bash
# Aplicar
kubectl apply -f blue-deployment.yaml
kubectl apply -f service-production.yaml

# Verificar
kubectl get deployments -l version=blue
kubectl get pods -l version=blue
kubectl get svc app-production

# Probar acceso
minikube service app-production -n lab-estrategias --url
curl $(minikube service app-production -n lab-estrategias --url)
```

### **Paso 2: Crear versión "Green" (nueva versión)**

Crea `green-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
  labels:
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: nginx
        image: nginx:1.22-alpine
        ports:
        - containerPort: 80
        env:
        - name: VERSION
          value: "v2.0-green"
        - name: COLOR
          value: "green"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

```bash
# Aplicar Green (no recibe tráfico aún)
kubectl apply -f green-deployment.yaml

# Verificar ambas versiones corriendo
kubectl get deployments -l app=myapp
kubectl get pods -l app=myapp -L version

# Esperado:
# NAME                        READY   VERSION
# app-blue-xxxx               1/1     blue
# app-blue-xxxx               1/1     blue
# app-blue-xxxx               1/1     blue
# app-green-xxxx              1/1     green
# app-green-xxxx              1/1     green
# app-green-xxxx              1/1     green
```

### **Paso 3: Crear servicio de testing para Green**

Crea `service-green-test.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-green-test
spec:
  type: NodePort
  selector:
    app: myapp
    version: green  # Solo pods Green
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30081
```

```bash
# Aplicar
kubectl apply -f service-green-test.yaml

# Probar Green en aislamiento
curl $(minikube service app-green-test -n lab-estrategias --url)

# Verificar que producción sigue usando Blue
curl $(minikube service app-production -n lab-estrategias --url)
```

### **Paso 4: Switch de Blue a Green (cambio instantáneo)**

```bash
# Ver configuración actual del servicio
kubectl get svc app-production -o yaml | grep -A 2 selector

# Cambiar selector a Green
kubectl patch service app-production -p '{"spec":{"selector":{"version":"green"}}}'

# Verificar cambio
kubectl get svc app-production -o yaml | grep -A 2 selector

# Probar - ahora usa Green
curl $(minikube service app-production -n lab-estrategias --url)
```

**🎉 ¡Cambio instantáneo sin downtime!**

### **Paso 5: Rollback instantáneo a Blue**

```bash
# Si Green tiene problemas, rollback instantáneo
kubectl patch service app-production -p '{"spec":{"selector":{"version":"blue"}}}'

# Verificar rollback
curl $(minikube service app-production -n lab-estrategias --url)

# Ver pods activos (ambos deployments siguen corriendo)
kubectl get pods -l app=myapp -L version
```

### **Paso 6: Cleanup de versión antigua**

```bash
# Una vez confirmado que Green está estable
kubectl patch service app-production -p '{"spec":{"selector":{"version":"green"}}}'

# Eliminar Blue deployment (ya no necesario)
kubectl delete deployment app-blue

# Verificar solo Green
kubectl get deployments
kubectl get pods -l app=myapp
```

**❓ Pregunta**: ¿Cuáles son las ventajas y desventajas de Blue-Green deployment?

---

## 🎯 Ejercicio 2: Canary Deployment con Réplicas

### **Paso 1: Deployment estable (v1)**

Crea `app-stable-v1.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-stable
  labels:
    app: canary-app
    track: stable
spec:
  replicas: 9  # 90% del tráfico
  selector:
    matchLabels:
      app: canary-app
      track: stable
  template:
    metadata:
      labels:
        app: canary-app
        track: stable
        version: "1.0"
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        env:
        - name: VERSION
          value: "1.0-stable"
```

Crea `service-canary.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-canary-service
spec:
  type: NodePort
  selector:
    app: canary-app  # Selecciona tanto stable como canary
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30082
```

```bash
# Aplicar
kubectl apply -f app-stable-v1.yaml
kubectl apply -f service-canary.yaml

# Verificar
kubectl get pods -l app=canary-app -L version,track
kubectl get svc app-canary-service
```

### **Paso 2: Deploy Canary (v2) - 10% tráfico**

Crea `app-canary-v2.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
  labels:
    app: canary-app
    track: canary
spec:
  replicas: 1  # 10% del tráfico (1 de 10 pods totales)
  selector:
    matchLabels:
      app: canary-app
      track: canary
  template:
    metadata:
      labels:
        app: canary-app
        track: canary
        version: "2.0"
    spec:
      containers:
      - name: app
        image: nginx:1.22-alpine
        ports:
        - containerPort: 80
        env:
        - name: VERSION
          value: "2.0-canary"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
```

```bash
# Aplicar Canary
kubectl apply -f app-canary-v2.yaml

# Ver distribución de pods
kubectl get pods -l app=canary-app -L track,version

# Esperado:
# 9 pods con track=stable, version=1.0
# 1 pod con track=canary, version=2.0
```

### **Paso 3: Probar distribución de tráfico**

```bash
# Script para probar distribución
for i in {1..100}; do
  curl -s $(minikube service app-canary-service -n lab-estrategias --url) | grep VERSION || echo "Request $i"
  sleep 0.1
done | sort | uniq -c

# Esperado aproximadamente:
# ~90 requests a version 1.0-stable
# ~10 requests a version 2.0-canary
```

### **Paso 4: Incrementar tráfico Canary a 25%**

```bash
# Ajustar réplicas: 75% stable (6 pods) + 25% canary (2 pods)
kubectl scale deployment app-stable --replicas=6
kubectl scale deployment app-canary --replicas=2

# Verificar nueva distribución
kubectl get pods -l app=canary-app -L track

# Probar nueva distribución (25% canary)
for i in {1..100}; do
  curl -s $(minikube service app-canary-service -n lab-estrategias --url) | grep VERSION
  sleep 0.05
done | sort | uniq -c
```

### **Paso 5: Incrementar a 50% (A/B testing)**

```bash
# 50/50 split
kubectl scale deployment app-stable --replicas=5
kubectl scale deployment app-canary --replicas=5

# Verificar
kubectl get pods -l app=canary-app -L track

# Probar distribución 50/50
for i in {1..100}; do
  curl -s $(minikube service app-canary-service -n lab-estrategias --url) | grep VERSION
  sleep 0.05
done | sort | uniq -c
```

### **Paso 6: Promoción completa a v2 (100%)**

```bash
# Opción 1: Eliminar stable, aumentar canary
kubectl delete deployment app-stable
kubectl scale deployment app-canary --replicas=10

# Opción 2: Convertir canary en el nuevo stable
kubectl label deployment app-canary track=stable --overwrite
kubectl scale deployment app-canary --replicas=10

# Verificar todo el tráfico a v2
kubectl get pods -l app=canary-app -L version
```

**❓ Pregunta**: ¿Cómo calculas el número de réplicas para un porcentaje específico de tráfico?

---

## 🎯 Ejercicio 3: Canary con Peso de Tráfico (usando labels)

### **Paso 1: Deployment con múltiples versiones**

Crea `weighted-canary.yaml`:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
spec:
  replicas: 4
  selector:
    matchLabels:
      app: weighted-app
      version: v1
  template:
    metadata:
      labels:
        app: weighted-app
        version: v1
        weight: "80"  # 80% peso
    spec:
      containers:
      - name: app
        image: nginx:1.20-alpine
        env:
        - name: APP_VERSION
          value: "1.0"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: weighted-app
      version: v2
  template:
    metadata:
      labels:
        app: weighted-app
        version: v2
        weight: "20"  # 20% peso
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine
        env:
        - name: APP_VERSION
          value: "2.0"
---
apiVersion: v1
kind: Service
metadata:
  name: weighted-app-service
spec:
  selector:
    app: weighted-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

```bash
# Aplicar
kubectl apply -f weighted-canary.yaml

# Ver distribución
kubectl get pods -l app=weighted-app -L version,weight
```

### **Paso 2: Ajustar pesos dinámicamente**

```bash
# Cambiar a 50/50
kubectl scale deployment app-v1 --replicas=5
kubectl scale deployment app-v2 --replicas=5
kubectl label deployment app-v1 weight=50 --overwrite
kubectl label deployment app-v2 weight=50 --overwrite

# Cambiar a 30/70 (más tráfico a v2)
kubectl scale deployment app-v1 --replicas=3
kubectl scale deployment app-v2 --replicas=7
```

---

## 🎯 Ejercicio 4: Canary con Health Checks y Auto-rollback

### **Paso 1: Deployment con health checks estrictos**

Crea `canary-with-health.yaml`:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-stable-health
spec:
  replicas: 5
  selector:
    matchLabels:
      app: health-app
      track: stable
  template:
    metadata:
      labels:
        app: health-app
        track: stable
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
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 2
          failureThreshold: 2
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: health-app-service
spec:
  selector:
    app: health-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

```bash
# Aplicar
kubectl apply -f canary-with-health.yaml

# Verificar stable
kubectl get pods -l track=stable
kubectl wait --for=condition=ready pod -l track=stable --timeout=60s
```

### **Paso 2: Canary con imagen problemática**

Crea `canary-failing.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary-failing
spec:
  replicas: 2  # 2 de 7 total = ~28% canary
  selector:
    matchLabels:
      app: health-app
      track: canary
  template:
    metadata:
      labels:
        app: health-app
        track: canary
    spec:
      containers:
      - name: app
        image: busybox:latest  # No tiene nginx - fallará health checks
        command: ['sh', '-c', 'sleep 3600']
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2
```

```bash
# Aplicar canary problemático
kubectl apply -f canary-failing.yaml

# Observar - pods canary nunca serán Ready
watch kubectl get pods -l app=health-app -L track

# El servicio NO enviará tráfico a pods canary (no están Ready)
kubectl get endpoints health-app-service
```

### **Paso 3: Verificar auto-rollback (manual)**

```bash
# Verificar que solo pods stable reciben tráfico
kubectl get pods -l app=health-app -L track

# Los pods canary existen pero no están Ready
# El servicio automáticamente los excluye

# Rollback: eliminar canary fallido
kubectl delete deployment app-canary-failing

# Verificar solo stable en endpoints
kubectl get endpoints health-app-service
```

**✅ El health check previno que tráfico llegara a versión problemática**

---

## 🎯 Ejercicio 5: Blue-Green con Script Automatizado

### **Paso 1: Crear script de Blue-Green deployment**

Crea [`blue-green-deploy.sh`](./blue-green-deploy.sh):

```bash
# Hacer ejecutable
chmod +x blue-green-deploy.sh

# Probar (ejemplo de uso)
# ./blue-green-deploy.sh myapp green blue 3 nginx:1.22-alpine lab-estrategias
```

---

## 🎯 Ejercicio 6: Comparación de Estrategias

### **Crear tabla comparativa**

| Estrategia | Downtime | Rollback | Costo de Recursos | Complejidad | Uso Recomendado |
|------------|----------|----------|-------------------|-------------|-----------------|
| **RollingUpdate** | ❌ No | Medio (progresivo) | 1x + surge | Baja | Aplicaciones stateless estándar |
| **Recreate** | ✅ Sí | Rápido | 1x | Muy Baja | Apps con estado compartido |
| **Blue-Green** | ❌ No | Instantáneo | 2x (temporal) | Media | Releases críticos |
| **Canary** | ❌ No | Rápido | 1x + canary | Alta | Testing en producción |

---

## 🧹 Limpieza

```bash
# Eliminar todos los recursos
kubectl delete deployment --all -n lab-estrategias
kubectl delete service --all -n lab-estrategias
kubectl delete namespace lab-estrategias

# Restaurar namespace
kubectl config set-context --current --namespace=default
```

---

## ✅ Checklist de Completitud

- [ ] Implementar Blue-Green deployment manual
- [ ] Realizar switch instantáneo entre versiones
- [ ] Implementar Canary con réplicas (10%, 25%, 50%, 100%)
- [ ] Usar health checks para prevenir tráfico a versión problemática
- [ ] Crear script automatizado de Blue-Green
- [ ] Comparar estrategias y elegir apropiada por caso de uso

---

## 🎓 Resumen

En este laboratorio aprendiste:

- ✅ Blue-Green deployment para releases sin riesgo
- ✅ Canary deployment para testing progresivo en producción
- ✅ Distribución de tráfico con réplicas
- ✅ Health checks para auto-exclusión de versiones problemáticas
- ✅ Automatización de Blue-Green con scripts
- ✅ Comparación y selección de estrategias

**Próximo**: Lab 06 - Best Practices en Producción 🚀
