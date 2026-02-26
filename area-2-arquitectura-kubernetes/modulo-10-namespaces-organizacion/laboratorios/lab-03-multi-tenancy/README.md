# Laboratorio 03: Multi-Tenancy y Aislamiento

**Duracion estimada:** 50-60 minutos
**Nivel:** Avanzado
**Requisitos:** Labs 01-02 completados, conocimiento basico de RBAC

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Multi-tenancy** | Patron donde multiples equipos/clientes (tenants) comparten un cluster con aislamiento logico mediante namespaces, RBAC, quotas y network policies |
| **ResourceQuota por tenant** | Cada tenant recibe su propia cuota de recursos, evitando que un tenant consuma recursos de otro |
| **RBAC por namespace** | Role + RoleBinding limitan permisos a un namespace. ServiceAccount de un tenant NO puede acceder a namespaces de otros |
| **NetworkPolicy deny-all** | Base de zero-trust: bloquear todo el trafico de entrada y luego permitir explicitamente solo lo necesario |
| **NetworkPolicy allow-same-ns** | Permite comunicacion entre pods del mismo namespace mientras bloquea trafico cross-namespace |
| **Pod Security Admission** | Labels en namespace que definen politicas de seguridad (baseline, restricted) para los pods que se crean |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Las operaciones principales se realizan mediante archivos YAML:

| Archivo | Parte | Descripcion |
|---------|-------|-------------|
| `tenant-setup.yaml` | 1 | Crea 3 namespaces de tenant con ResourceQuota y LimitRange cada uno |
| `tenant-rbac.yaml` | 2 | ServiceAccount, Role y RoleBinding para admin de cada tenant |
| `networkpolicy-deny-all.yaml` | 3 | NetworkPolicy default deny (aplicar con `-n` a cada tenant) |
| `networkpolicy-allow-same-ns.yaml` | 3 | NetworkPolicy que permite trafico intra-namespace (aplicar con `-n`) |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `monitor-tenants.sh` | Script para monitorear recursos por tenant |
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Labs 01 y 02 completados
- kubectl configurado

### Verificacion del entorno

```bash
kubectl cluster-info
kubectl get nodes
ls -la *.yaml
```

---

## Parte 1: Estructura Multi-Tenant (15 min)

### Paso 1: Revisar y crear los 3 tenants

Revisa el archivo `tenant-setup.yaml`:

```bash
cat tenant-setup.yaml
```

Puntos clave del manifiesto:
- **3 namespaces**: tenant-company-a, tenant-company-b, tenant-company-c
- **Labels**: `tenant` e `isolation: strict` para filtrado
- **ResourceQuota** por tenant: 4 CPU req, 8Gi mem, 20 pods, 10 services
- **LimitRange** por tenant: defaults 500m/512Mi, max 2 CPU/4Gi

```bash
kubectl apply -f tenant-setup.yaml

# Verificar
kubectl get ns -l isolation=strict
kubectl describe resourcequota -n tenant-company-a
kubectl describe limitrange -n tenant-company-a
```

### Paso 2: Desplegar App por Tenant

```bash
# Deployment y Service en cada tenant
for tenant in company-a company-b company-c; do
  kubectl create deployment app --image=nginx -n tenant-$tenant
  kubectl scale deployment app --replicas=2 -n tenant-$tenant
  kubectl expose deployment app --port=80 -n tenant-$tenant
done

# Verificar
kubectl get deployments -l isolation=strict --all-namespaces
```

---

## Parte 2: RBAC por Namespace (15 min)

### Paso 3: Revisar y aplicar RBAC

Revisa el archivo `tenant-rbac.yaml`:

```bash
cat tenant-rbac.yaml
```

Puntos clave del manifiesto:
- **ServiceAccount** `tenant-admin` en cada namespace
- **Role** con permisos completos en su namespace (apiGroups: core, apps, batch)
- **RoleBinding** conecta ServiceAccount con Role
- Permisos son **locales al namespace** (Role, no ClusterRole)

```bash
kubectl apply -f tenant-rbac.yaml
```

### Paso 4: Testing de Permisos

```bash
# Puede gestionar su namespace
kubectl auth can-i create pods \
  --as=system:serviceaccount:tenant-company-a:tenant-admin \
  -n tenant-company-a
# Resultado: yes

# NO puede acceder a otro namespace
kubectl auth can-i create pods \
  --as=system:serviceaccount:tenant-company-a:tenant-admin \
  -n tenant-company-b
# Resultado: no

# NO puede acceder a recursos de cluster
kubectl auth can-i get nodes \
  --as=system:serviceaccount:tenant-company-a:tenant-admin
# Resultado: no
```

**Checkpoint**: RBAC debe limitar acceso por namespace.

---

## Parte 3: NetworkPolicies (Aislamiento de Red) (15 min)

### Paso 5: Aplicar Default Deny

Revisa el archivo `networkpolicy-deny-all.yaml`:

```bash
cat networkpolicy-deny-all.yaml
```

Puntos clave:
- **podSelector: {}** selecciona TODOS los pods
- **policyTypes: [Ingress]** controla trafico entrante
- **Sin reglas de ingress** = denegar todo

```bash
# Aplicar a cada tenant
for tenant in company-a company-b company-c; do
  kubectl apply -f networkpolicy-deny-all.yaml -n tenant-$tenant
done
```

### Paso 6: Permitir Trafico Intra-Namespace

Revisa el archivo `networkpolicy-allow-same-ns.yaml`:

```bash
cat networkpolicy-allow-same-ns.yaml
```

Puntos clave:
- **ingress.from.podSelector: {}** permite desde cualquier pod del MISMO namespace
- Las politicas son **aditivas**: esta se suma a deny-all

```bash
# Aplicar a cada tenant
for tenant in company-a company-b company-c; do
  kubectl apply -f networkpolicy-allow-same-ns.yaml -n tenant-$tenant
done
```

### Paso 7: Testing de Aislamiento

```bash
# Crear Pods de prueba
kubectl run test-a --image=alpine -n tenant-company-a \
  --command -- sleep 3600
kubectl run test-b --image=alpine -n tenant-company-b \
  --command -- sleep 3600

# Instalar curl
kubectl exec test-a -n tenant-company-a -- apk add --no-cache curl
kubectl exec test-b -n tenant-company-b -- apk add --no-cache curl

# Mismo namespace (debe funcionar)
kubectl exec test-a -n tenant-company-a -- \
  curl -s --max-time 5 http://app.tenant-company-a
# Resultado: HTML de nginx

# Cross-namespace (debe fallar por NetworkPolicy)
kubectl exec test-a -n tenant-company-a -- \
  curl -s --max-time 5 http://app.tenant-company-b
# Resultado: timeout (bloqueado)
```

**Checkpoint**: NetworkPolicy debe bloquear trafico cross-namespace.

---

## Parte 4: Monitoreo y Auditoria (10 min)

### Paso 8: Monitorear Uso de Recursos por Tenant

```bash
# Resumen rapido
for tenant in company-a company-b company-c; do
  echo "=== Tenant: $tenant ==="
  kubectl get pods -n tenant-$tenant --no-headers | wc -l
  kubectl describe resourcequota tenant-quota -n tenant-$tenant | grep -E "Used|Hard"
  echo
done
```

### Paso 9: Auditar Eventos

```bash
for tenant in company-a company-b company-c; do
  echo "=== Events: tenant-$tenant ==="
  kubectl get events -n tenant-$tenant --sort-by='.lastTimestamp' | tail -5
done
```

### Script de Monitoreo

```bash
chmod +x monitor-tenants.sh
./monitor-tenants.sh
```

---

## Parte 5: Best Practices de Produccion (5 min)

### Paso 10: Labels y Annotations Estandar

```bash
# Labels de facturacion
for tenant in company-a company-b company-c; do
  kubectl label namespace tenant-$tenant \
    cost-center=$tenant \
    billing-enabled=true \
    --overwrite
done

# Annotations de contacto
kubectl annotate namespace tenant-company-a \
  contact="admin@company-a.com" \
  slack="#company-a-support"
```

### Paso 11: PodSecurityStandards

```bash
# Aplicar Pod Security Admission (K8s 1.23+)
for tenant in company-a company-b company-c; do
  kubectl label namespace tenant-$tenant \
    pod-security.kubernetes.io/enforce=baseline \
    pod-security.kubernetes.io/warn=restricted
done
```

---

## Desafios

### Desafio 1: Tenant con Requisitos Especiales

Crea `tenant-vip` con quota de CPU 10 cores y NetworkPolicy que permite trafico desde namespace `monitoring`.

<details>
<summary>Solucion</summary>

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

---

## Limpieza

```bash
chmod +x cleanup.sh
./cleanup.sh
```

---

## Resumen

- Multi-tenancy con namespaces aislados
- RBAC para control de acceso granular por namespace
- NetworkPolicies para aislamiento de red (deny-all + allow-same-ns)
- Monitoreo y auditoria por tenant
- Best practices: labels, annotations, Pod Security Admission

### Lecciones Clave

1. **Aislamiento por capas**: Namespaces + RBAC + NetworkPolicies + ResourceQuotas
2. **Default Deny**: Siempre empezar con NetworkPolicy deny-all
3. **Monitoreo**: Auditar uso de recursos y eventos por tenant
4. **Labels consistentes**: Facilitan automatizacion y facturacion

---

**Anterior:** [Lab 02: Quotas y Limits](../lab-02-quotas-limits/)
**Inicio:** [Volver al README del modulo](../README.md)
