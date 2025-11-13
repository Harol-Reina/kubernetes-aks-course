# 📋 Cheatsheet: Advanced Scheduling

**Referencia rápida para CKA** - Comandos y YAML esenciales de scheduling avanzado

---

## 🎮 Manual Scheduling

### nodeName (Bypass Scheduler)
```yaml
spec:
  nodeName: worker-01
```

### nodeSelector (Labels)
```bash
# Etiquetar nodo
kubectl label nodes worker-01 disktype=ssd

# Pod con selector
spec:
  nodeSelector:
    disktype: ssd
```

---

## 🗿 Static Pods

```bash
# Ver staticPodPath
grep staticPodPath /var/lib/kubelet/config.yaml

# Crear static pod
sudo vi /etc/kubernetes/manifests/static-nginx.yaml

# Eliminar static pod
sudo rm /etc/kubernetes/manifests/static-nginx.yaml

# Ver static pods
kubectl get pods | grep <nodename>
```

---

## 🚫 Taints & Tolerations

### Taints en Nodos
```bash
# Aplicar taint
kubectl taint nodes worker-01 gpu=true:NoSchedule

# Ver taints
kubectl describe node worker-01 | grep Taints

# Remover taint
kubectl taint nodes worker-01 gpu=true:NoSchedule-

# Effects disponibles:
# - NoSchedule
# - PreferNoSchedule
# - NoExecute
```

### Tolerations en Pods
```yaml
spec:
  tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  
  # Tolerar cualquier valor
  - key: "gpu"
    operator: "Exists"
    effect: "NoSchedule"
  
  # Tolerar todo
  - operator: "Exists"
```

---

## 🧲 Node Affinity

```yaml
spec:
  affinity:
    nodeAffinity:
      # REQUIRED (hard)
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values: [ssd, nvme]
      
      # PREFERRED (soft)
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: zone
            operator: In
            values: [us-east-1a]
```

**Operators:** `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt`, `Lt`

---

## 🤝 Pod Affinity & Anti-Affinity

### Pod Affinity (Co-location)
```yaml
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values: [cache]
        topologyKey: kubernetes.io/hostname
```

### Pod Anti-Affinity (Spreading)
```yaml
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values: [web]
        topologyKey: kubernetes.io/hostname
```

**Topology Keys:**
- `kubernetes.io/hostname` - Mismo nodo
- `topology.kubernetes.io/zone` - Misma zona
- `topology.kubernetes.io/region` - Misma región

---

## 📊 Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
    services: "10"
```

```bash
# Ver quotas
kubectl get resourcequota -n dev

# Describir usage
kubectl describe resourcequota compute-quota -n dev
```

---

## 📏 LimitRange

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: limits
  namespace: dev
spec:
  limits:
  - type: Container
    max:
      cpu: "2"
      memory: "4Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
    default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "200m"
      memory: "256Mi"
```

```bash
# Ver limit ranges
kubectl get limitrange -n dev

# Describir
kubectl describe limitrange limits -n dev
```

---

## ⚡ Priority Classes

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
preemptionPolicy: PreemptLowerPriority
description: "Critical workloads"
```

```bash
# Ver priority classes
kubectl get priorityclasses

# Usar en pod
spec:
  priorityClassName: high-priority
```

---

## 🐛 Troubleshooting

### Pod Pending
```bash
# Ver razón
kubectl describe pod <pod>

# Errores comunes:
# - Insufficient cpu/memory → Cluster sin recursos
# - node(s) had taint → Falta toleration
# - didn't match node affinity → Labels incorrectos
# - anti-affinity rules → No hay nodos disponibles
```

### Debug Scheduling
```bash
# Ver labels de nodos
kubectl get nodes --show-labels

# Ver taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Ver recursos disponibles
kubectl describe nodes | grep -A 5 "Allocated resources"

# Ver events
kubectl get events --sort-by='.lastTimestamp' | grep -i schedule
```

---

## 💡 Tips CKA

1. **nodeSelector vs Affinity:**
   - `nodeSelector`: Simple, solo equality
   - `affinity`: Potente, múltiples operators

2. **Taints vs Affinity:**
   - Taints: Nodo "repele" pods
   - Affinity: Pod "atrae" a nodos

3. **Required vs Preferred:**
   - `required`: HARD (pod Pending si no cumple)
   - `preferred`: SOFT (scheduler intenta, pero no garantiza)

4. **Memoriza:**
   - Taint: `kubectl taint nodes <node> key=value:Effect`
   - Remover: Añadir `-` al final
   - Toleration: `operator: Equal` o `Exists`

5. **Static Pods:**
   - Path: `/etc/kubernetes/manifests`
   - No se pueden eliminar con kubectl
   - Sufijo: `-<nodename>`

6. **Priority:**
   - Mayor número = mayor prioridad
   - System: 2000000000+
   - Puede causar preemption (eviction)

---

## 📖 YAML Templates

### Complete Scheduling Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: advanced-pod
spec:
  # Priority
  priorityClassName: high-priority
  
  # Node selection
  nodeSelector:
    disktype: ssd
  
  # Tolerations
  tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  
  # Affinity
  affinity:
    # Node affinity
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: zone
            operator: In
            values: [us-east-1a]
    
    # Pod anti-affinity (spreading)
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values: [myapp]
        topologyKey: kubernetes.io/hostname
  
  # Resources
  containers:
  - name: app
    image: myapp:latest
    resources:
      requests:
        cpu: "500m"
        memory: "1Gi"
      limits:
        cpu: "1"
        memory: "2Gi"
```

---

## ✅ Quick Reference

| Feature | Level | Can Fail Scheduling? | Use Case |
|---------|-------|---------------------|----------|
| nodeName | Pod | No | Debug, testing |
| nodeSelector | Pod | Yes | Simple node selection |
| Node Affinity (required) | Pod | Yes | Complex node rules |
| Node Affinity (preferred) | Pod | No | Best-effort placement |
| Taints | Node | Yes (without toleration) | Dedicated nodes |
| Tolerations | Pod | - | Tolerate taints |
| Pod Affinity | Pod | Yes | Co-location |
| Pod Anti-Affinity | Pod | Yes | Spreading |
| ResourceQuota | Namespace | Yes | Limit namespace |
| LimitRange | Namespace | Yes | Pod/Container limits |
| PriorityClass | Cluster | No (can preempt) | Critical workloads |

---

**🎯 Objetivo CKA:** ~15% del examen. Domina affinity, taints, y resource management.
