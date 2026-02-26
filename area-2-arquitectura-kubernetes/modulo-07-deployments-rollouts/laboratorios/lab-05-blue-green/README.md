# Laboratorio 05: Estrategias Avanzadas de Deployment

**Duracion estimada**: 60 minutos
**Dificultad**: Avanzado
**Objetivo**: Implementar estrategias Blue-Green y Canary para deployments sin downtime

---

## Estrategias de Deployment Avanzadas

### Blue-Green Deployment

Blue-Green es una estrategia en la que se mantienen **dos entornos identicos** en produccion (llamados "Blue" y "Green") pero solo uno recibe trafico en cada momento. La version activa es Blue; la nueva version se despliega en Green. Una vez validada, el Service conmuta el trafico de Blue a Green en **un solo cambio de selector**, lo que produce un cambio instantaneo y sin downtime. Si la nueva version falla, el rollback es igualmente instantaneo: se revierte el selector al entorno anterior.

**Cuando usarla**: Releases criticos donde el rollback debe ser inmediato, aplicaciones donde la coexistencia de dos versiones activas no es viable y el costo de duplicar recursos es aceptable temporalmente.

**Costo**: El doble de recursos durante la transicion (ambos entornos deben estar completamente provisionados).

### Canary Deployment

Canary es una estrategia de despliegue **progresivo**: la nueva version se despliega en un subconjunto pequeno de Pods (el "canario") mientras el resto sigue en la version estable. El trafico se distribuye proporcionalmente al numero de replicas. Si la version canary no muestra errores, se incrementan sus replicas gradualmente hasta reemplazar por completo a la version estable.

**Cuando usarla**: Testing de nuevas funcionalidades en produccion real con impacto limitado, A/B testing, validacion de rendimiento con trafico real.

**Costo**: Recursos adicionales proporcionales al porcentaje de trafico canary (normalmente muy bajo al inicio: 5-10%).

### Diferencias Clave

| Aspecto | Blue-Green | Canary |
|---------|-----------|--------|
| Velocidad del switch | Instantanea | Progresiva |
| Rollback | Instantaneo (1 comando) | Rapido (scale a 0) |
| Costo de recursos | 2x durante transicion | 1x + porcentaje canary |
| Exposicion al riesgo | Todo o nada | Limitada (% de usuarios) |
| Complejidad | Media | Alta |

---

## Prerequisitos

Revisar [SETUP.md](./SETUP.md) para verificar el entorno antes de comenzar.

```bash
# Crear namespace
kubectl create namespace lab-estrategias
kubectl config set-context --current --namespace=lab-estrategias
```

---

## Archivos YAML del Laboratorio

| Archivo | Estrategia | Descripcion |
|---------|-----------|-------------|
| `blue-deployment.yaml` | Blue-Green | Version Blue: 3 replicas nginx:1.21-alpine |
| `green-deployment.yaml` | Blue-Green | Version Green: 3 replicas nginx:1.22-alpine con readinessProbe |
| `service-production.yaml` | Blue-Green | NodePort 30080, selector inicial version=blue |
| `service-green-test.yaml` | Blue-Green | NodePort 30081, solo Pods Green para testing aislado |
| `app-stable-v1.yaml` | Canary | Stable: 9 replicas (90% trafico) nginx:1.21-alpine |
| `app-canary-v2.yaml` | Canary | Canary: 1 replica (10% trafico) nginx:1.22-alpine |
| `service-canary.yaml` | Canary | NodePort 30082, selecciona stable + canary |
| `weighted-canary.yaml` | Canary ponderado | Multi-doc: app-v1 (4r) + app-v2 (1r) + service |
| `canary-with-health.yaml` | Canary + health | Multi-doc: stable con probes + service |
| `canary-failing.yaml` | Canary fallido | Demostracion de auto-exclusion por health checks |

---

## Ejercicio 1: Blue-Green Deployment Manual

### Paso 1: Desplegar version Blue (produccion actual)

```bash
# Revisar el archivo antes de aplicar
cat blue-deployment.yaml

# Aplicar version Blue
kubectl apply -f blue-deployment.yaml

# Aplicar Service de produccion (apunta a Blue)
cat service-production.yaml
kubectl apply -f service-production.yaml

# Verificar
kubectl get deployments -l version=blue
kubectl get pods -l version=blue
kubectl get svc app-production
```

**Output esperado**:
```
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
app-blue   3/3     3            3           30s

NAME                            READY   STATUS    RESTARTS   AGE
app-blue-6d5f9b8c4-2xkpj        1/1     Running   0          30s
app-blue-6d5f9b8c4-7mnqr        1/1     Running   0          30s
app-blue-6d5f9b8c4-9vzlt        1/1     Running   0          30s

NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
app-production   NodePort   10.96.44.21     <none>        80:30080/TCP   15s
```

```bash
# Probar acceso a produccion (Blue)
minikube service app-production -n lab-estrategias --url
curl $(minikube service app-production -n lab-estrategias --url)
```

### Paso 2: Desplegar version Green (nueva version)

```bash
# Revisar el archivo - notar readinessProbe y imagen nginx:1.22
cat green-deployment.yaml

# Aplicar Green (no recibe trafico de produccion aun)
kubectl apply -f green-deployment.yaml

# Verificar ambas versiones corriendo en paralelo
kubectl get deployments -l app=myapp
kubectl get pods -l app=myapp -L version
```

**Output esperado**:
```
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
app-blue     3/3     3            3           2m
app-green    3/3     3            3           30s

NAME                            READY   STATUS    RESTARTS   AGE     VERSION
app-blue-6d5f9b8c4-2xkpj        1/1     Running   0          2m      blue
app-blue-6d5f9b8c4-7mnqr        1/1     Running   0          2m      blue
app-blue-6d5f9b8c4-9vzlt        1/1     Running   0          2m      blue
app-green-7c8b9f5d2-4rpks       1/1     Running   0          30s     green
app-green-7c8b9f5d2-8xwmn       1/1     Running   0          30s     green
app-green-7c8b9f5d2-kjtpl       1/1     Running   0          30s     green
```

### Paso 3: Probar Green en aislamiento

```bash
# Crear Service de testing para Green
cat service-green-test.yaml
kubectl apply -f service-green-test.yaml

# Probar Green directamente (sin afectar produccion)
curl $(minikube service app-green-test -n lab-estrategias --url)

# Confirmar que produccion sigue usando Blue
curl $(minikube service app-production -n lab-estrategias --url)
```

### Paso 4: Switch instantaneo de Blue a Green

```bash
# Ver selector actual del Service de produccion
kubectl get svc app-production -o yaml | grep -A 3 selector

# Output esperado:
#   selector:
#     app: myapp
#     version: blue

# Cambiar selector a Green (cambio instantaneo)
kubectl patch service app-production -p '{"spec":{"selector":{"version":"green"}}}'

# Verificar cambio de selector
kubectl get svc app-production -o yaml | grep -A 3 selector

# Output esperado:
#   selector:
#     app: myapp
#     version: green

# Probar - ahora produccion usa Green
curl $(minikube service app-production -n lab-estrategias --url)
```

**Resultado**: Cambio instantaneo sin downtime. Todos los requests nuevos van a Green.

### Paso 5: Rollback instantaneo a Blue

```bash
# Si Green tiene problemas, rollback con un solo comando
kubectl patch service app-production -p '{"spec":{"selector":{"version":"blue"}}}'

# Verificar rollback inmediato
curl $(minikube service app-production -n lab-estrategias --url)

# Ambos Deployments siguen corriendo (Blue y Green)
kubectl get pods -l app=myapp -L version
```

### Paso 6: Confirmar Green y limpiar Blue

```bash
# Confirmar Green como produccion definitiva
kubectl patch service app-production -p '{"spec":{"selector":{"version":"green"}}}'

# Eliminar Blue (ya no necesario)
kubectl delete deployment app-blue

# Verificar solo Green activo
kubectl get deployments
kubectl get pods -l app=myapp
```

**Pregunta**: ?Cuales son las ventajas y desventajas de Blue-Green deployment frente a RollingUpdate?

---

## Ejercicio 2: Canary Deployment con Replicas

### Paso 1: Desplegar version estable (v1, 90% del trafico)

```bash
# Revisar archivo: 9 replicas, track=stable
cat app-stable-v1.yaml
kubectl apply -f app-stable-v1.yaml

# Revisar Service: selector solo por app=canary-app (incluye stable Y canary)
cat service-canary.yaml
kubectl apply -f service-canary.yaml

# Verificar
kubectl get pods -l app=canary-app -L version,track
kubectl get svc app-canary-service
```

**Output esperado**:
```
NAME                          READY   STATUS    VERSION   TRACK
app-stable-xxxxx-xxxxx        1/1     Running   1.0       stable
app-stable-xxxxx-yyyyy        1/1     Running   1.0       stable
... (9 pods stable en total)

NAME                TYPE       CLUSTER-IP      PORT(S)
app-canary-service  NodePort   10.96.55.12     80:30082/TCP
```

### Paso 2: Desplegar Canary (v2, 10% del trafico)

```bash
# Revisar archivo: 1 replica, track=canary, con readinessProbe
cat app-canary-v2.yaml
kubectl apply -f app-canary-v2.yaml

# Ver distribucion: 9 stable + 1 canary = 90/10
kubectl get pods -l app=canary-app -L track,version
```

**Output esperado**:
```
NAME                          READY   STATUS    TRACK    VERSION
app-stable-xxxxx-xxxxx        1/1     Running   stable   1.0
... (9 pods stable)
app-canary-yyyyy-yyyyy        1/1     Running   canary   2.0
```

### Paso 3: Probar distribucion de trafico

```bash
# Script para verificar distribucion aproximada
for i in {1..20}; do
  curl -s $(minikube service app-canary-service -n lab-estrategias --url) -o /dev/null -w "%{http_code}\n"
  sleep 0.2
done
```

### Paso 4: Aumentar trafico Canary a 25%

```bash
# 6 stable + 2 canary = 75% / 25%
kubectl scale deployment app-stable --replicas=6
kubectl scale deployment app-canary --replicas=2

# Verificar nueva distribucion
kubectl get pods -l app=canary-app -L track
```

**Output esperado**:
```
NAME                    READY   STATUS    TRACK
app-stable-... (x6)     1/1     Running   stable
app-canary-... (x2)     1/1     Running   canary
```

### Paso 5: A/B Testing al 50%

```bash
# 5 stable + 5 canary = 50% / 50%
kubectl scale deployment app-stable --replicas=5
kubectl scale deployment app-canary --replicas=5

# Verificar
kubectl get pods -l app=canary-app -L track
```

### Paso 6: Promocion completa a v2 (100%)

```bash
# Opcion A: Eliminar stable y escalar canary
kubectl delete deployment app-stable
kubectl scale deployment app-canary --replicas=10

# Verificar todo el trafico en v2
kubectl get pods -l app=canary-app -L version
```

**Output esperado**:
```
NAME                          READY   STATUS    VERSION
app-canary-yyyyy-aaaaa        1/1     Running   2.0
app-canary-yyyyy-bbbbb        1/1     Running   2.0
... (10 pods version 2.0)
```

**Pregunta**: ?Como calculas el numero de replicas necesario para un porcentaje exacto de trafico?

---

## Ejercicio 3: Canary con Peso de Trafico

### Paso 1: Desplegar dos versiones con distribucion 80/20

```bash
# Revisar archivo multi-documento: app-v1 (4r) + app-v2 (1r) + service
cat weighted-canary.yaml

# Aplicar todos los recursos a la vez
kubectl apply -f weighted-canary.yaml

# Ver distribucion
kubectl get pods -l app=weighted-app -L version,weight
```

**Output esperado**:
```
NAME                    READY   STATUS    VERSION   WEIGHT
app-v1-xxxxx-aaaaa      1/1     Running   v1        80
app-v1-xxxxx-bbbbb      1/1     Running   v1        80
app-v1-xxxxx-ccccc      1/1     Running   v1        80
app-v1-xxxxx-ddddd      1/1     Running   v1        80
app-v2-yyyyy-aaaaa      1/1     Running   v2        20
```

### Paso 2: Ajustar pesos dinamicamente

```bash
# Cambiar a 50/50
kubectl scale deployment app-v1 --replicas=5
kubectl scale deployment app-v2 --replicas=5
kubectl label deployment app-v1 weight=50 --overwrite
kubectl label deployment app-v2 weight=50 --overwrite

# Verificar
kubectl get pods -l app=weighted-app -L version

# Cambiar a 30/70 (mayoria a v2)
kubectl scale deployment app-v1 --replicas=3
kubectl scale deployment app-v2 --replicas=7

# Verificar distribucion final
kubectl get pods -l app=weighted-app -L version
```

**Output esperado** (distribucion 30/70):
```
NAME                      READY   STATUS    RESTARTS   AGE   VERSION
app-v1-xxxx-abc           1/1     Running   0          2m    v1
app-v1-xxxx-def           1/1     Running   0          2m    v1
app-v1-xxxx-ghi           1/1     Running   0          2m    v1
app-v2-xxxx-jkl           1/1     Running   0          2m    v2
app-v2-xxxx-mno           1/1     Running   0          2m    v2
app-v2-xxxx-pqr           1/1     Running   0          2m    v2
app-v2-xxxx-stu           1/1     Running   0          2m    v2
app-v2-xxxx-vwx           1/1     Running   0          2m    v2
app-v2-xxxx-yza           1/1     Running   0          2m    v2
app-v2-xxxx-bcd           1/1     Running   0          2m    v2
```

---

## Ejercicio 4: Canary con Health Checks y Auto-exclusion

### Paso 1: Desplegar Deployment estable con health checks estrictos

```bash
# Revisar archivo: stable con readiness + liveness + service
cat canary-with-health.yaml

# Aplicar
kubectl apply -f canary-with-health.yaml

# Esperar que todos los Pods esten Ready (readinessProbe requiere 2 checks OK)
kubectl wait --for=condition=ready pod -l track=stable --timeout=60s

# Verificar
kubectl get pods -l app=health-app -L track
kubectl get endpoints health-app-service
```

**Output esperado**:
```
NAME                               READY   STATUS    TRACK
app-stable-health-xxxxx-aaaaa      1/1     Running   stable
app-stable-health-xxxxx-bbbbb      1/1     Running   stable
... (5 pods stable, todos Ready)

NAME                 ENDPOINTS
health-app-service   10.244.0.5:80,10.244.0.6:80,...  (5 IPs)
```

### Paso 2: Desplegar Canary con imagen que falla health checks

```bash
# Revisar archivo: busybox sin servidor HTTP - los health checks HTTP fallan
cat canary-failing.yaml

# Aplicar canary problematico
kubectl apply -f canary-failing.yaml

# Observar: los Pods canary nunca llegan a Ready
watch kubectl get pods -l app=health-app -L track
```

**Output esperado tras ~30 segundos**:
```
NAME                               READY   STATUS    TRACK
app-stable-health-xxxxx-aaaaa      1/1     Running   stable
... (5 pods stable - Ready)
app-canary-failing-zzzzz-aaaaa     0/1     Running   canary
app-canary-failing-zzzzz-bbbbb     0/1     Running   canary
```

Los Pods canary aparecen como `0/1` (no Ready). Kubernetes los excluye automaticamente del Service.

### Paso 3: Verificar auto-exclusion del Service

```bash
# El Service solo incluye en Endpoints los Pods Ready
kubectl get endpoints health-app-service

# Output esperado: solo las IPs de los 5 Pods stable (sin los 2 canary)
# NAME                 ENDPOINTS
# health-app-service   10.244.0.5:80,10.244.0.6:80,...  (5 IPs, no 7)

# Describir Deployment canary para ver eventos de health check
kubectl describe deployment app-canary-failing | grep -A 5 Conditions

# Rollback: eliminar canary fallido
kubectl delete deployment app-canary-failing

# Confirmar que los Endpoints son solo los Pods stable
kubectl get endpoints health-app-service
```

**El health check previno que trafico llegara a la version problematica.**

---

## Ejercicio 5: Blue-Green con Script Automatizado

El script `blue-green-deploy.sh` automatiza el proceso completo de Blue-Green:

```bash
# Hacer ejecutable
chmod +x blue-green-deploy.sh

# Ver parametros disponibles
cat blue-green-deploy.sh | head -15

# Uso: ./blue-green-deploy.sh APP_NAME NEW_VERSION OLD_VERSION REPLICAS IMAGE NAMESPACE
# Ejemplo:
./blue-green-deploy.sh myapp green blue 3 nginx:1.22-alpine lab-estrategias
```

El script realiza automaticamente:
1. Despliega la nueva version (Green)
2. Espera que este lista (`kubectl wait --for=condition=available`)
3. Crea un Service de testing
4. Solicita confirmacion interactiva antes del switch
5. Cambia el selector del Service de produccion
6. Solicita confirmacion para eliminar la version antigua

---

## Ejercicio 6: Comparacion de Estrategias

| Estrategia | Downtime | Rollback | Costo de Recursos | Complejidad | Uso Recomendado |
|------------|----------|----------|-------------------|-------------|-----------------|
| **RollingUpdate** | No | Medio (progresivo) | 1x + surge | Baja | Aplicaciones stateless estandar |
| **Recreate** | Si | Rapido | 1x | Muy Baja | Apps con estado compartido |
| **Blue-Green** | No | Instantaneo | 2x (temporal) | Media | Releases criticos |
| **Canary** | No | Rapido | 1x + canary | Alta | Testing en produccion |

### Criterios de Seleccion

- **Usar Blue-Green cuando**: El rollback instantaneo es un requisito no negociable y el costo de duplicar recursos es aceptable.
- **Usar Canary cuando**: Se necesita validar con trafico real antes de un despliegue completo y el impacto de errores debe ser limitado.
- **Usar RollingUpdate cuando**: La aplicacion puede manejar multiples versiones activas y el proceso de actualizacion gradual es suficiente.
- **Usar Recreate cuando**: La aplicacion no puede tener dos versiones corriendo en paralelo (por ejemplo, migraciones de base de datos destructivas).

---

## Limpieza

```bash
# Ejecutar el script de limpieza (recomendado)
./cleanup.sh

# O limpiar manualmente
kubectl delete namespace lab-estrategias
kubectl config set-context --current --namespace=default
```

---

## Checklist de Completitud

- [ ] Implementar Blue-Green deployment manual (Pasos 1-6)
- [ ] Realizar switch instantaneo entre versiones
- [ ] Verificar rollback instantaneo a Blue
- [ ] Implementar Canary con replicas (10%, 25%, 50%, 100%)
- [ ] Verificar distribucion de trafico por numero de replicas
- [ ] Demostrar auto-exclusion de Pods por health checks fallidos
- [ ] Usar script automatizado de Blue-Green
- [ ] Comparar estrategias y elegir apropiada por caso de uso

---

## Resumen

En este laboratorio aprendiste:

- Blue-Green deployment: switch instantaneo mediante cambio de selector en el Service
- Canary deployment: distribucion progresiva de trafico con control por replicas
- Canary ponderado: ajuste dinamico de porcentajes escalando Deployments
- Health checks como mecanismo de auto-exclusion de versiones problematicas
- Script automatizado para Blue-Green con confirmacion interactiva
- Criterios objetivos para elegir entre estrategias segun el caso de uso

**Proximo**: Lab 06 - Best Practices en Produccion
