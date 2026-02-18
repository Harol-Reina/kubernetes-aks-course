# Lab 02: Taints & Tolerations

**Duración:** 45-60 min | **Dificultad:** ⭐⭐⭐ | **CKA:** ~5%

## Objectives
- Apply and manage taints on nodes
- Configure tolerations in pods
- Understand taint effects (NoSchedule, NoExecute, PreferNoSchedule)

## Exercises

### Exercise 1: NoSchedule Taint (15 min)

```bash
# Apply taint
kubectl taint nodes worker-01 gpu=true:NoSchedule

# Try to schedule pod without toleration
kubectl run no-toleration --image=nginx

# Check status (should be Pending)
kubectl get pods

# Create pod with toleration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: with-toleration
spec:
  tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx
EOF

# Verify scheduling
kubectl get pods -o wide

# Cleanup taint
kubectl taint nodes worker-01 gpu=true:NoSchedule-
```

### Exercise 2: NoExecute (Eviction) (20 min)

```bash
# Create deployment on worker-01
kubectl run evict-test --image=nginx --replicas=3

# Wait for pods
kubectl get pods -o wide

# Apply NoExecute taint
kubectl taint nodes worker-01 maintenance=true:NoExecute

# Watch eviction
kubectl get pods -o wide -w

# Pods on worker-01 are evicted
```

### Exercise 3: Dedicated Node Pattern (20 min)

```bash
# Dedicate worker-02 for team=frontend
kubectl taint nodes worker-02 team=frontend:NoSchedule
kubectl label nodes worker-02 team=frontend

# Create frontend deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      nodeSelector:
        team: frontend
      tolerations:
      - key: "team"
        operator: "Equal"
        value: "frontend"
        effect: "NoSchedule"
      containers:
      - name: nginx
        image: nginx
EOF

# Verify all pods on worker-02
kubectl get pods -o wide -l app=frontend
```

## Completion
- [ ] NoSchedule taint blocks pods
- [ ] NoExecute evicts existing pods
- [ ] Dedicated node configured with taint + label
