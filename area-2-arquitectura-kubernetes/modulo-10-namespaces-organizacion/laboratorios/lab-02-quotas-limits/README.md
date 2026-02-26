# Laboratorio 02: ResourceQuota y LimitRange

**Duracion estimada:** 45-50 minutos
**Nivel:** Intermedio
**Requisitos:** Completar Lab 01, cluster con al menos 4 CPU cores y 8Gi RAM

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **ResourceQuota** | Limita el total de recursos agregados en un namespace (CPU, memoria, cantidad de pods/services). Evita que un equipo o entorno consuma todos los recursos del cluster |
| **LimitRange** | Establece defaults, minimos, maximos y ratios para cada container/pod individual. Aplica defaults automaticamente a pods sin requests/limits |
| **QoS Classes** | Kubernetes clasifica pods en Guaranteed (req=limit), Burstable (req<limit) y BestEffort (sin req/limit). Determina prioridad de eviction |
| **Scoped Quota** | ResourceQuota con scope que solo aplica a pods de una QoS class especifica (BestEffort, Burstable, etc.) |
| **maxLimitRequestRatio** | Ratio maximo entre limit y request. Controla el overcommit: ratio=4 significa que limit puede ser hasta 4x el request |
| **Quota enforcement** | Cuando hay ResourceQuota, pods SIN requests/limits son rechazados. LimitRange resuelve esto aplicando defaults |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Las operaciones principales se realizan mediante archivos YAML:

| Archivo | Parte | Descripcion |
|---------|-------|-------------|
| `resourcequota-compute.yaml` | 1 | ResourceQuota: limita CPU, memoria, pods, services y PVCs en dev-limited |
| `limitrange-compute.yaml` | 2 | LimitRange: defaults, min, max y ratios para containers y pods |
| `resourcequota-besteffort.yaml` | 4 | ResourceQuota con scope BestEffort: limita pods sin requests/limits |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `monitor-quota.sh` | Script para monitorear uso de quota en dev-limited |
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Lab 01 completado
- kubectl configurado

### Verificacion del entorno

```bash
kubectl cluster-info
kubectl get nodes
ls -la *.yaml
```

---

## Parte 1: ResourceQuota Basico (15 min)

### Paso 1: Crear Namespace con Quota

```bash
# Crear namespace
kubectl create namespace dev-limited
```

Revisa el archivo `resourcequota-compute.yaml`:

```bash
cat resourcequota-compute.yaml
```

Puntos clave del manifiesto:
- **requests.cpu/memory**: suma de todos los requests de todos los pods
- **limits.cpu/memory**: suma de todos los limits de todos los pods
- **pods: "5"**: maximo 5 pods en el namespace
- **services: "3"**, **persistentvolumeclaims: "2"**: limites de objetos

```bash
kubectl apply -f resourcequota-compute.yaml

# Verificar
kubectl describe resourcequota compute-quota -n dev-limited
```

### Paso 2: Intentar Crear Pod SIN Recursos (Debe Fallar)

```bash
# Esto fallara porque el namespace tiene ResourceQuota
kubectl run test --image=nginx -n dev-limited

# Error esperado:
# must specify limits.cpu,limits.memory,requests.cpu,requests.memory
```

**Checkpoint**: El Pod debe fallar debido a que falta especificar requests/limits.

### Paso 3: Crear Pod CON Recursos (Debe Funcionar)

```bash
kubectl run pod1 --image=nginx -n dev-limited \
  --requests='cpu=200m,memory=256Mi' \
  --limits='cpu=500m,memory=512Mi'

# Ver uso de quota
kubectl describe resourcequota compute-quota -n dev-limited
```

**Salida esperada:**
```
Resource         Used   Hard
--------         ----   ----
limits.cpu       500m   4
limits.memory    512Mi  8Gi
pods             1      5
requests.cpu     200m   2
requests.memory  256Mi  4Gi
```

### Paso 4: Testing de Limite de Pods

```bash
# Crear pods hasta alcanzar el limite (5 total)
for i in {2..5}; do
  kubectl run pod$i --image=nginx -n dev-limited \
    --requests='cpu=200m,memory=256Mi' \
    --limits='cpu=500m,memory=512Mi'
done

# Verificar (debe haber 5 pods)
kubectl get pods -n dev-limited

# Intentar crear el 6o pod (debe fallar)
kubectl run pod6 --image=nginx -n dev-limited \
  --requests='cpu=200m,memory=256Mi' \
  --limits='cpu=500m,memory=512Mi'

# Error: exceeded quota: pods=1, used: pods=5, limited: pods=5
```

**Checkpoint**: Limite de 5 pods debe funcionar correctamente.

### Paso 5: Testing de Limite de CPU

```bash
# Eliminar algunos pods para tener espacio
kubectl delete pod pod4 pod5 -n dev-limited

# Intentar crear pod que excede CPU request total
kubectl run big-pod --image=nginx -n dev-limited \
  --requests='cpu=2,memory=256Mi' \
  --limits='cpu=4,memory=512Mi'

# Error: exceeded quota: requests.cpu
```

---

## Parte 2: LimitRange (15 min)

### Paso 6: Revisar y aplicar LimitRange

Revisa el archivo `limitrange-compute.yaml`:

```bash
cat limitrange-compute.yaml
```

Puntos clave del manifiesto:
- **default**: limits aplicados si el container no especifica (300m CPU, 256Mi)
- **defaultRequest**: requests aplicados si no se especifica (100m CPU, 128Mi)
- **max/min**: rango permitido para cada container
- **maxLimitRequestRatio: 4**: limit puede ser hasta 4x el request
- **type Pod**: limites para el pod completo (suma de containers)

```bash
kubectl apply -f limitrange-compute.yaml

# Verificar
kubectl describe limitrange compute-limits -n dev-limited
```

### Paso 7: Testing de Defaults

```bash
# Limpiar namespace
kubectl delete pods --all -n dev-limited

# Crear Pod SIN especificar recursos
kubectl run auto-default --image=nginx -n dev-limited

# Verificar recursos aplicados automaticamente
kubectl get pod auto-default -n dev-limited -o yaml | grep -A 10 resources:
```

**Salida esperada (defaults aplicados):**
```yaml
resources:
  limits:
    cpu: 300m        # default
    memory: 256Mi    # default
  requests:
    cpu: 100m        # defaultRequest
    memory: 128Mi    # defaultRequest
```

**Checkpoint**: LimitRange debe aplicar defaults automaticamente.

### Paso 8: Testing de Ratio Maximo

```bash
# Intentar crear pod con ratio CPU > 4 (debe fallar)
kubectl run ratio-test --image=nginx -n dev-limited \
  --requests='cpu=100m,memory=128Mi' \
  --limits='cpu=600m,memory=512Mi'

# Error: cpu max limit to request ratio per Container is 4,
# but provided ratio is 6 (600m / 100m)
```

### Paso 9: Testing de Maximos y Minimos

```bash
# Exceder maximo permitido
kubectl run too-big --image=nginx -n dev-limited \
  --requests='cpu=1500m,memory=1Gi'
# Error: must be less than or equal to cpu limit of 1

# Por debajo del minimo
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
```

### Paso 11: Script de Monitoreo

```bash
chmod +x monitor-quota.sh
./monitor-quota.sh
```

---

## Parte 4: Scopes Avanzados (10 min)

### Paso 12: Revisar y aplicar Quota con Scopes

Revisa el archivo `resourcequota-besteffort.yaml`:

```bash
cat resourcequota-besteffort.yaml
```

Puntos clave del manifiesto:
- **scopes: [BestEffort]**: solo aplica a pods sin requests/limits
- **pods: "2"**: maximo 2 pods BestEffort permitidos
- No puede limitar recursos de computo (solo conteo de objetos)

```bash
kubectl apply -f resourcequota-besteffort.yaml
```

---

## Desafios

### Desafio 1: Quota Personalizada

Crea un namespace `test-quota` con max 3 Pods, CPU request 1 core, memory 2Gi, max 1 LoadBalancer.

<details>
<summary>Solucion</summary>

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

### Desafio 2: Troubleshooting

Un desarrollador reporta: "No puedo crear Pods en `dev-limited`". Como diagnosticas?

<details>
<summary>Solucion</summary>

```bash
# 1. Verificar quota
kubectl describe resourcequota -n dev-limited

# 2. Ver si se alcanzo el limite
kubectl get resourcequota -n dev-limited

# 3. Si quota esta llena, eliminar pods innecesarios o aumentar quota
kubectl edit resourcequota compute-quota -n dev-limited
```
</details>

---

## Limpieza

```bash
chmod +x cleanup.sh
./cleanup.sh
```

---

## Resumen

- ResourceQuota limita recursos agregados (total del namespace)
- LimitRange establece defaults y rangos por objeto individual
- Scopes permiten quotas selectivas (BestEffort, Terminating, etc.)
- Monitoreo de quotas es critico para prevenir sorpresas

### Proximos Pasos

- **Lab 03**: Multi-Tenancy y Aislamiento

---

**Anterior:** [Lab 01: Fundamentos](../lab-01-namespaces-basico/)
**Siguiente:** [Lab 03: Multi-Tenancy](../lab-03-multi-tenancy/)
