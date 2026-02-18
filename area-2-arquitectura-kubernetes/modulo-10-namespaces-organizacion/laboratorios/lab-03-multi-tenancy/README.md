# Laboratorio 03: Multi-Tenancy y Aislamiento

**Duración estimada**: 50-60 minutos  
**Nivel**: Avanzado  
**Requisitos**: Labs 01-02 completados, conocimiento básico de RBAC

---

## Objetivos

✅ Implementar arquitectura multi-tenant  
✅ Configurar RBAC por namespace  
✅ Implementar NetworkPolicies para aislamiento  
✅ Monitorear y auditar acceso  
✅ Best practices de producción

---

## Parte 1: Estructura Multi-Tenant (15 min)

### Paso 1: Crear Tenants

```bash
# Crear namespaces para 3 tenants
for tenant in company-a company-b company-c; do
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-$tenant
  labels:
    tenant: $tenant
    isolation: strict
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: tenant-$tenant
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
    services: "10"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: tenant-limits
  namespace: tenant-$tenant
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "200m"
      memory: "256Mi"
    max:
      cpu: "2"
      memory: "4Gi"
EOF
done

# Verificar
kubectl get ns -l isolation=strict
```

### Paso 2: Desplegar App por Tenant

```bash
# Deployment template
for tenant in company-a company-b company-c; do
  kubectl create deployment app --image=nginx -n tenant-$tenant
  kubectl scale deployment app --replicas=2 -n tenant-$tenant
  kubectl expose deployment app --port=80 -n tenant-$tenant
done

# Verificar
kubectl get deployments --all-namespaces -l tenant
```

---

## Parte 2: RBAC por Namespace (15 min)

### Paso 3: Crear ServiceAccounts

```bash
# ServiceAccount para cada tenant
for tenant in company-a company-b company-c; do
  kubectl create serviceaccount tenant-admin -n tenant-$tenant
done
```

### Paso 4: Configurar Roles y RoleBindings

```bash
# Role con permisos completos en el namespace
for tenant in company-a company-b company-c; do
  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tenant-admin-role
  namespace: tenant-$tenant
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tenant-admin-binding
  namespace: tenant-$tenant
subjects:
- kind: ServiceAccount
  name: tenant-admin
  namespace: tenant-$tenant
roleRef:
  kind: Role
  name: tenant-admin-role
  apiGroup: rbac.authorization.k8s.io
EOF
done
```

### Paso 5: Testing de Permisos

```bash
# Verificar que tenant-admin puede gestionar su namespace
kubectl auth can-i create pods \
  --as=system:serviceaccount:tenant-company-a:tenant-admin \
  -n tenant-company-a
# Resultado: yes

# Verificar que NO puede acceder a otro namespace
kubectl auth can-i create pods \
  --as=system:serviceaccount:tenant-company-a:tenant-admin \
  -n tenant-company-b
# Resultado: no
```

**✅ Checkpoint 1**: RBAC debe limitar acceso por namespace

---

## Parte 3: NetworkPolicies (Aislamiento de Red) (15 min)

### Paso 6: Denegar Todo el Tráfico (Default Deny)

```bash
# NetworkPolicy: denegar todo ingress
for tenant in company-a company-b company-c; do
  cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: tenant-$tenant
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
done
```

### Paso 7: Permitir Tráfico Intra-Namespace

```bash
# Permitir comunicación SOLO dentro del namespace
for tenant in company-a company-b company-c; do
  cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: tenant-$tenant
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}  # Todos los Pods del mismo namespace
EOF
done
```

### Paso 8: Testing de Aislamiento

```bash
# Crear Pod de prueba en company-a
kubectl run test-a --image=alpine -n tenant-company-a \
  --command -- sleep 3600

# Crear Pod de prueba en company-b
kubectl run test-b --image=alpine -n tenant-company-b \
  --command -- sleep 3600

# Instalar curl en ambos
kubectl exec -it test-a -n tenant-company-a -- \
  sh -c "apk add curl"
kubectl exec -it test-b -n tenant-company-b -- \
  sh -c "apk add curl"

# Testing: ✅ Mismo namespace (debe funcionar)
kubectl exec test-a -n tenant-company-a -- \
  curl -s http://app.tenant-company-a
# Resultado: HTML de nginx

# Testing: ❌ Cross-namespace (debe fallar)
kubectl exec test-a -n tenant-company-a -- \
  curl -s --connect-timeout 5 http://app.tenant-company-b
# Resultado: timeout (bloqueado por NetworkPolicy)
```

**✅ Checkpoint 2**: NetworkPolicy debe bloquear tráfico cross-namespace

---

## Parte 4: Monitoreo y Auditoría (10 min)

### Paso 9: Monitorear Uso de Recursos por Tenant

```bash
# Script de monitoreo
cat <<'EOF' > monitor-tenants.sh
# !/bin/bash
echo "=== Uso de Recursos por Tenant ==="
for tenant in company-a company-b company-c; do
  echo -e "\n--- Tenant: $tenant ---"
  kubectl top pods -n tenant-$tenant --no-headers | \
    awk '{cpu+=$2; mem+=$3} END {print "CPU: " cpu " | Memory: " mem}'
  kubectl describe ns tenant-$tenant | grep -A 5 "Resource Quotas"
done
EOF

chmod +x monitor-tenants.sh
./monitor-tenants.sh
```

### Paso 10: Auditar Eventos

```bash
# Ver eventos recientes por namespace
for tenant in company-a company-b company-c; do
  echo "=== Events: tenant-$tenant ==="
  kubectl get events -n tenant-$tenant --sort-by='.lastTimestamp' | tail -5
done
```

---

## Parte 5: Best Practices de Producción (5 min)

### Paso 11: Labels y Annotations Estándar

```bash
# Agregar labels de facturación
for tenant in company-a company-b company-c; do
  kubectl label namespace tenant-$tenant \
    cost-center=$tenant \
    billing-enabled=true \
    --overwrite
done

# Annotations para contacto
kubectl annotate namespace tenant-company-a \
  contact="admin@company-a.com" \
  slack="#company-a-support"
```

### Paso 12: PodSecurityStandards

```bash
# Aplicar Pod Security Admission (K8s 1.23+)
for tenant in company-a company-b company-c; do
  kubectl label namespace tenant-$tenant \
    pod-security.kubernetes.io/enforce=baseline \
    pod-security.kubernetes.io/warn=restricted
done

# Testing
kubectl run privileged-test --image=nginx -n tenant-company-a \
  --privileged=true
# Debe mostrar warning o fallar según la política
```

---

## Desafíos

### Desafío 1: Tenant con Requisitos Especiales

Crea `tenant-vip` con:
- Quota de CPU: 10 cores (mayor que otros tenants)
- Storage: 200Gi
- NetworkPolicy que permite tráfico desde namespace `monitoring`

<details>
<summary>Solución</summary>

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-vip
  labels:
    tier: premium
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: vip-quota
  namespace: tenant-vip
spec:
  hard:
    requests.cpu: "10"
    requests.storage: 200Gi
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: tenant-vip
spec:
  podSelector: {}
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
```
</details>

### Desafío 2: Facturación por Tenant

Escribe un script que calcule el costo mensual de cada tenant basado en CPU/RAM usado.

<details>
<summary>Solución</summary>

```bash
# !/bin/bash
COST_CPU_CORE_MONTH=30  # $30 por core/mes
COST_GB_RAM_MONTH=10    # $10 por GB/mes

for tenant in company-a company-b company-c; do
  cpu=$(kubectl describe ns tenant-$tenant | \
    grep "requests.cpu" | awk '{print $2}' | sed 's/m//')
  cpu_cores=$(echo "scale=2; $cpu / 1000" | bc)
  
  mem=$(kubectl describe ns tenant-$tenant | \
    grep "requests.memory" | awk '{print $2}' | sed 's/Gi//')
  
  cost=$(echo "scale=2; ($cpu_cores * $COST_CPU_CORE_MONTH) + \
    ($mem * $COST_GB_RAM_MONTH)" | bc)
  
  echo "Tenant: $tenant | CPU: ${cpu_cores} cores | RAM: ${mem}Gi | Cost: \$$cost/mo"
done
```
</details>

---

## Limpieza

```bash
# Eliminar todos los tenants
kubectl delete namespace tenant-company-a
kubectl delete namespace tenant-company-b
kubectl delete namespace tenant-company-c
kubectl delete namespace tenant-vip
```

---

## Resumen

✅ Multi-tenancy con namespaces aislados  
✅ RBAC para control de acceso granular  
✅ NetworkPolicies para aislamiento de red  
✅ Monitoreo y auditoría por tenant  
✅ Best practices de producción aplicadas

### Lecciones Clave

1. **Aislamiento por capas**: Namespaces + RBAC + NetworkPolicies + ResourceQuotas
2. **Default Deny**: Siempre empezar con NetworkPolicy deny-all
3. **Monitoreo**: Auditar uso de recursos y eventos por tenant
4. **Labels consistentes**: Facilitan automatización y facturación

---

**📚 Navegación**:
- ⬅️ [Lab 02: Quotas y Limits](lab-02-quotas-limits.md)
- 🏠 [Volver al README del módulo](../README.md)
