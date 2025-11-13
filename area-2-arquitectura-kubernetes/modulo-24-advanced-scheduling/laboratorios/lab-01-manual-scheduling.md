# Lab 01: Manual Scheduling & Static Pods

**Duración:** 30-45 min | **Dificultad:** ⭐⭐ | **CKA:** ~5%

## Objectives
- Master manual pod scheduling with nodeName and nodeSelector
- Create and manage static pods
- Understand scheduler bypass mechanisms

## Exercises

### Exercise 1: Manual Scheduling with nodeName (10 min)

```bash
# Create pod with nodeName
kubectl run manual-pod --image=nginx --dry-run=client -o yaml > manual-pod.yaml

# Edit and add nodeName
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: manual-pod
spec:
  nodeName: worker-01
  containers:
  - name: nginx
    image: nginx
EOF

# Verify
kubectl get pod manual-pod -o wide
```

### Exercise 2: nodeSelector (10 min)

```bash
# Label node
kubectl label nodes worker-01 disktype=ssd

# Create pod with nodeSelector
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: selector-pod
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx
EOF

# Verify
kubectl get pod selector-pod -o wide
```

### Exercise 3: Static Pods (15 min)

```bash
# Find staticPodPath
ssh worker-01
grep staticPodPath /var/lib/kubelet/config.yaml

# Create static pod
sudo tee /etc/kubernetes/manifests/static-nginx.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: static-nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

# Verify (from master)
kubectl get pods | grep static-nginx

# Try to delete (won't work)
kubectl delete pod static-nginx-worker-01

# Really delete
sudo rm /etc/kubernetes/manifests/static-nginx.yaml
```

## Completion
- [ ] Pod scheduled with nodeName
- [ ] Pod scheduled with nodeSelector
- [ ] Static pod created and verified
