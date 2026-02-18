# Lab 02: Node Maintenance Operations

**Duración:** 45-60 min | **Dificultad:** ⭐⭐ (Intermedio) | **CKA Coverage:** ~5%

## 🎯 Objetivos

- Usar `kubectl drain`, `cordon`, `uncordon` correctamente
- Gestionar mantenimiento de nodos sin downtime
- Trabajar con PodDisruptionBudgets
- Simular escenarios de mantenimiento reales

## 📋 Escenarios

### Scenario 1: Node Reboot (15 min)

```bash
# 1. Drain nodo worker-01
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data

# 2. SSH y reboot
ssh worker-01 'sudo reboot'

# 3. Esperar a que vuelva
kubectl get nodes -w

# 4. Verificar kubelet
ssh worker-01 'sudo systemctl status kubelet'

# 5. Uncordon
kubectl uncordon worker-01
```

### Scenario 2: Cordon (No Evacuar) (10 min)

```bash
# Marcar unschedulable sin evacuar
kubectl cordon worker-02

# Crear deployment
kubectl create deployment test-cordon --image=nginx --replicas=5

# Verificar: Ningún pod va a worker-02
kubectl get pods -o wide -l app=test-cordon

# Cleanup
kubectl delete deployment test-cordon
kubectl uncordon worker-02
```

### Scenario 3: PodDisruptionBudgets (20 min)

```bash
# Crear app con PDB
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: critical
  template:
    metadata:
      labels:
        app: critical
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: critical
EOF

# Verificar distribución
kubectl get pods -o wide -l app=critical

# Drain con PDB
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data
# Observar: Respeta minAvailable

# Verificar que quedan 2+ pods
kubectl get pods -l app=critical

# Uncordon y cleanup
kubectl uncordon worker-01
kubectl delete deployment critical-app
kubectl delete pdb critical-pdb
```

**✅ Completitud:**
- [ ] Reboot exitoso sin downtime
- [ ] Cordon previene scheduling
- [ ] PDB respetado durante drain
