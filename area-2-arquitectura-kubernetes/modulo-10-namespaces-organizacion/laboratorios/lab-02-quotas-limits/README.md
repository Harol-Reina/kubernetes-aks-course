# Laboratorio 02: ResourceQuota y LimitRange

**Duración estimada**: 45-50 minutos  
**Nivel**: Intermedio  
**Requisitos**: Completar Lab 01, cluster con al menos 4 CPU cores y 8Gi RAM

---

## Objetivos

✅ Configurar ResourceQuota para limitar recursos agregados  
✅ Implementar LimitRange para defaults y rangos  
✅ Testing de límites de CPU, memoria y objetos  
✅ Monitorear uso de recursos y quotas  
✅ Troubleshooting de errores de quota

---

## Parte 1: ResourceQuota Básico (15 min)

### Paso 1: Crear Namespace con Quota

```bash
# Crear namespace
kubectl create namespace dev-limited

# Crear ResourceQuota
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev-limited
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "5"
    services: "3"
    persistentvolumeclaims: "2"
EOF

# Verificar
kubectl describe resourcequota compute-quota -n dev-limited
```

### Paso 2: Intentar Crear Pod SIN Recursos (Debe Fallar)

```bash
# ❌ Esto fallará porque el namespace tiene ResourceQuota
kubectl run test --image=nginx -n dev-limited

# Error esperado:
# Error: pods "test" is forbidden: failed quota: compute-quota:
# must specify limits.cpu,limits.memory,requests.cpu,requests.memory
```

**✅ Checkpoint 1**: El Pod debe fallar debido a que falta especificar requests/limits

### Paso 3: Crear Pod CON Recursos (Debe Funcionar)

```bash
kubectl run pod1 --image=nginx -n dev-limited \
  --requests='cpu=200m,memory=256Mi' \
  --limits='cpu=500m,memory=512Mi'

# Verificar
kubectl get pod pod1 -n dev-limited

# Ver uso de quota
kubectl describe ns dev-limited | grep -A 15 "Resource Quotas"
```

**Salida esperada**:
```
Resource         Used   Hard
--------         ----   ----
limits.cpu       500m   4
limits.memory    512Mi  8Gi
pods             1      5
requests.cpu     200m   2
requests.memory  256Mi  4Gi
```

### Paso 4: Testing de Límite de Pods

```bash
# Crear pods hasta alcanzar el límite (5 total)
for i in {2..5}; do
  kubectl run pod$i --image=nginx -n dev-limited \
    --requests='cpu=200m,memory=256Mi' \
    --limits='cpu=500m,memory=512Mi'
done

# Verificar (debe haber 5 pods)
kubectl get pods -n dev-limited

# Intentar crear el 6º pod (debe fallar)
kubectl run pod6 --image=nginx -n dev-limited \
  --requests='cpu=200m,memory=256Mi' \
  --limits='cpu=500m,memory=512Mi'

# Error esperado:
# Error: exceeded quota: compute-quota, requested: pods=1, used: pods=5, limited: pods=5
```

**✅ Checkpoint 2**: Límite de 5 pods debe funcionar correctamente

### Paso 5: Testing de Límite de CPU

```bash
# Eliminar algunos pods para tener espacio
kubectl delete pod pod4 pod5 -n dev-limited

# Intentar crear pod que excede CPU request total
kubectl run big-pod --image=nginx -n dev-limited \
  --requests='cpu=2,memory=256Mi' \
  --limits='cpu=4,memory=512Mi'

# Error esperado:
# Error: exceeded quota: compute-quota, requested: requests.cpu=2,
# used: requests.cpu=600m (3 pods × 200m), limited: requests.cpu=2
```

---

## Parte 2: LimitRange (15 min)

### Paso 6: Aplicar LimitRange

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: compute-limits
  namespace: dev-limited
spec:
  limits:
  - type: Container
    max:
      cpu: "1"
      memory: "1Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    default:
      cpu: "300m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    maxLimitRequestRatio:
      cpu: "4"
      memory: "4"
  - type: Pod
    max:
      cpu: "2"
      memory: "2Gi"
EOF

# Verificar
kubectl describe limitrange compute-limits -n dev-limited
```

### Paso 7: Testing de Defaults

```bash
# Limpiar namespace
kubectl delete pods --all -n dev-limited

# Crear Pod SIN especificar recursos
kubectl run auto-default --image=nginx -n dev-limited

# Verificar recursos aplicados automáticamente
kubectl get pod auto-default -n dev-limited -o yaml | grep -A 10 resources:
```

**Salida esperada** (defaults aplicados):
```yaml
resources:
  limits:
    cpu: 300m      # ← default
    memory: 256Mi  # ← default
  requests:
    cpu: 100m      # ← defaultRequest
    memory: 128Mi  # ← defaultRequest
```

**✅ Checkpoint 3**: LimitRange debe aplicar defaults automáticamente

### Paso 8: Testing de Ratio Máximo

```bash
# Intentar crear pod con ratio CPU > 4 (debe fallar)
kubectl run ratio-test --image=nginx -n dev-limited \
  --requests='cpu=100m,memory=128Mi' \
  --limits='cpu=600m,memory=512Mi'

# Error esperado:
# Error: cpu max limit to request ratio per Container is 4,
# but provided ratio is 6 (600m / 100m)
```

### Paso 9: Testing de Máximos y Mínimos

```bash
# ❌ Exceder máximo permitido
kubectl run too-big --image=nginx -n dev-limited \
  --requests='cpu=1500m,memory=1Gi'
# Error: must be less than or equal to cpu limit of 1

# ❌ Por debajo del mínimo
kubectl run too-small --image=nginx -n dev-limited \
  --requests='cpu=10m,memory=32Mi'
# Error: minimum memory usage per Container is 64Mi
```

---

## Parte 3: Monitoreo y Troubleshooting (10 min)

### Paso 10: Monitorear Uso de Recursos

```bash
# Ver quota detallada
kubectl describe ns dev-limited

# Ver solo quotas
kubectl get resourcequota -n dev-limited

# JSON output para scripting
kubectl get resourcequota compute-quota -n dev-limited -o json | \
  jq '.status.used, .status.hard'

# Calcular % de uso
kubectl describe resourcequota compute-quota -n dev-limited | \
  grep -E "requests.cpu|requests.memory"
```

### Paso 11: Script de Monitoreo

📄 Ver script: [`monitor-quota.sh`](./monitor-quota.sh)

```bash
chmod +x monitor-quota.sh
./monitor-quota.sh
```

---

## Parte 4: Scopes Avanzados (10 min)

### Paso 12: Quota con Scopes

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: besteffort-quota
  namespace: dev-limited
spec:
  hard:
    pods: "2"
  scopes:
  - BestEffort  # Solo Pods sin requests/limits
EOF

# Ahora puedes crear 2 Pods BestEffort (sin recursos)
kubectl run besteffort-1 --image=nginx -n dev-limited --dry-run=client -o yaml | \
  kubectl apply -f -

kubectl run besteffort-2 --image=alpine -n dev-limited \
  --command -- sleep 3600
```

---

## Desafíos

### Desafío 1: Quota Personalizada

Crea un namespace `test-quota` con:
- Max 3 Pods
- CPU request total: 1 core
- Memory request total: 2Gi
- Max 1 LoadBalancer Service

<details>
<summary>Solución</summary>

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test-quota
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: custom-quota
  namespace: test-quota
spec:
  hard:
    pods: "3"
    requests.cpu: "1"
    requests.memory: 2Gi
    services.loadbalancers: "1"
```
</details>

### Desafío 2: Troubleshooting

Un desarrollador reporta: "No puedo crear Pods en `dev-limited`". 
¿Cómo diagnosticas y resuelves?

<details>
<summary>Solución</summary>

```bash
# 1. Verificar quota
kubectl describe ns dev-limited

# 2. Ver si se alcanzó el límite
kubectl get resourcequota -n dev-limited

# 3. Si quota está llena, eliminar pods innecesarios
kubectl delete pod <nombre> -n dev-limited

# 4. O aumentar quota
kubectl edit resourcequota compute-quota -n dev-limited
```
</details>

---

## Limpieza

```bash
kubectl delete namespace dev-limited
kubectl delete namespace test-quota
```

---

## Resumen

✅ ResourceQuota limita recursos agregados (total del namespace)  
✅ LimitRange establece defaults y rangos por objeto  
✅ Scopes permiten quotas selectivas (BestEffort, Terminating, etc.)  
✅ Monitoreo de quotas es crítico para prevenir sorpresas

### Próximos Pasos

- **Lab 03**: Multi-Tenancy y Aislamiento

---

**📚 Navegación**:
- ⬅️ [Lab 01: Fundamentos](lab-01-namespaces-basico.md)
- ➡️ [Lab 03: Multi-Tenancy](lab-03-multi-tenancy.md)
