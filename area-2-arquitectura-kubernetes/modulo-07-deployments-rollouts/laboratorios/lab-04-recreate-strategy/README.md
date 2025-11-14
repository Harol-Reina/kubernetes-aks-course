# Lab 04: Estrategia Recreate

## Objetivo
Aprender a utilizar la estrategia de deployment `Recreate` en Kubernetes y comprender cuándo es apropiada.

## Duración Estimada
60-75 minutos

## Dificultad
⭐⭐⭐☆☆

## Prerequisitos
- Minikube instalado y funcionando
- kubectl configurado
- Conocimientos de Deployments
- Haber completado Labs 01-03

## Conceptos Clave

### Estrategia Recreate
- Termina todos los pods existentes antes de crear nuevos
- Downtime durante el update
- Más simple que RollingUpdate
- Útil para aplicaciones que no soportan múltiples versiones

### Cuándo Usar Recreate
- Aplicaciones que no pueden correr múltiples versiones simultáneamente
- Cuando el downtime es aceptable
- Recursos limitados (no hay capacidad para ambas versiones)
- Migraciones de base de datos que requieren downtime

## Actividades

### 1. Crear Deployment con Estrategia Recreate

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-recreate
spec:
  replicas: 3
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
```

### 2. Aplicar y Verificar

```bash
# Crear deployment
kubectl apply -f deployment-recreate.yaml

# Ver rollout status
kubectl rollout status deployment/nginx-recreate

# Verificar pods
kubectl get pods -w
```

### 3. Realizar Update con Recreate

```bash
# Actualizar imagen
kubectl set image deployment/nginx-recreate nginx=nginx:1.20

# Observar el proceso (todos los pods se terminan primero)
kubectl get pods -w

# Ver eventos
kubectl describe deployment nginx-recreate
```

### 4. Comparar con RollingUpdate

Crear un deployment similar con RollingUpdate y comparar:
- Tiempo de downtime
- Comportamiento de pods
- Uso de recursos

## Verificación

```bash
# Verificar estrategia configurada
kubectl get deployment nginx-recreate -o yaml | grep -A 2 strategy

# Ver historial de rollout
kubectl rollout history deployment/nginx-recreate

# Verificar versión actual
kubectl get deployment nginx-recreate -o jsonpath='{.spec.template.spec.containers[0].image}'
```

## Limpieza

```bash
./cleanup.sh
```

## Conclusiones

La estrategia `Recreate`:
- ✅ Simple y predecible
- ✅ Garantiza solo una versión corriendo
- ✅ Usa menos recursos durante update
- ❌ Causa downtime
- ❌ No apta para aplicaciones críticas 24/7

## Recursos Adicionales

- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)
- [Recreate vs RollingUpdate](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
