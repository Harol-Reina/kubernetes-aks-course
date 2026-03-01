# Resumen Rapido: Troubleshooting Kubernetes

**Duracion:** 15 minutos | **Nivel:** Repaso | **Archivo:** `troubleshooting-lab.yaml`

Este laboratorio resume los conceptos clave del Modulo 26: Troubleshooting de clusters Kubernetes. Despliega recursos con errores intencionales para practicar diagnostico rapido de problemas comunes en aplicaciones, networking y probes.

---

## Resumen Conceptual

### Metodologia de Troubleshooting

```
1. IDENTIFICAR el problema
   ├── kubectl get pods/nodes/svc
   ├── Estado: CrashLoopBackOff, Pending, NotReady, ImagePullBackOff
   └── READY: 0/1 vs 1/1

2. DIAGNOSTICAR la causa raiz
   ├── kubectl describe <recurso>
   ├── kubectl logs <pod> [--previous]
   ├── kubectl get events --sort-by='.lastTimestamp'
   └── sudo journalctl -u kubelet (para nodos)

3. CORREGIR el problema
   ├── kubectl edit / kubectl patch
   ├── kubectl set image
   ├── kubectl delete + recrear
   └── Modificar manifests en /etc/kubernetes/manifests/

4. VERIFICAR la solucion
   ├── kubectl get pods (STATUS: Running, READY: 1/1)
   ├── kubectl logs <pod>
   └── Tests de conectividad
```

### Errores Comunes por Estado

| Estado | Causa Tipica | Comando Diagnostico |
|--------|-------------|---------------------|
| **CrashLoopBackOff** | Comando/args incorrectos, config faltante | `kubectl logs <pod> --previous` |
| **ImagePullBackOff** | Tag de imagen inexistente | `kubectl describe pod` → Events |
| **OOMKilled** | Memory limits insuficientes | `kubectl describe pod` → Last State (exit 137) |
| **Pending** | Sin recursos, scheduler down, PVC Pending | `kubectl describe pod` → Events |
| **Init:0/1** | Init container esperando dependencia | `kubectl logs <pod> -c <init-container>` |
| **Running 0/1** | Readiness probe fallando | `kubectl describe pod` → Readiness |
| **CreateContainerConfigError** | ConfigMap/Secret faltante | `kubectl describe pod` → Events |

### Errores de Networking

| Problema | Causa Tipica | Diagnostico |
|----------|-------------|-------------|
| **Service sin Endpoints** | Label mismatch entre Pod y Service selector | `kubectl get endpoints <svc>` |
| **DNS no resuelve** | CoreDNS pods no running | `kubectl get pods -n kube-system -l k8s-app=kube-dns` |
| **Port mismatch** | targetPort != containerPort | `kubectl get svc -o yaml` vs `kubectl get pod -o yaml` |
| **NetworkPolicy bloqueando** | Policy deny-all sin allow rules | `kubectl get networkpolicies` |

---

## Tabla Comparativa: Herramientas de Diagnostico

| Herramienta | Uso | Ejemplo |
|-------------|-----|---------|
| `kubectl describe` | Ver eventos y config detallada | `kubectl describe pod webapp-crash` |
| `kubectl logs` | Ver stdout/stderr del container | `kubectl logs <pod> --previous` |
| `kubectl get events` | Ver eventos ordenados | `kubectl get events --sort-by='.lastTimestamp'` |
| `kubectl exec` | Ejecutar comandos dentro del pod | `kubectl exec <pod> -- nslookup kubernetes` |
| `kubectl top` | Ver uso de CPU/memoria | `kubectl top pods --sort-by=memory` |
| `journalctl` | Logs de kubelet y systemd | `sudo journalctl -u kubelet -n 100` |
| `crictl` | Debug del container runtime | `sudo crictl ps -a`, `sudo crictl logs <id>` |

---

## Ejercicio Practico (15 min)

### Paso 1: Desplegar Recursos con Errores (1 min)

```bash
# Aplicar todos los recursos (incluye errores intencionales)
kubectl apply -f troubleshooting-lab.yaml

# Verificar namespace creado
kubectl get namespace lab-troubleshooting-test
```

### Paso 2: Diagnosticar Application Issues (3 min)

```bash
# Ver estado de todos los pods
kubectl get pods -n lab-troubleshooting-test

# Output esperado: algunos pods en CrashLoopBackOff, ImagePullBackOff

# Diagnosticar CrashLoopBackOff
kubectl logs -n lab-troubleshooting-test -l scenario=crashloop --previous 2>/dev/null
kubectl describe pod -n lab-troubleshooting-test -l scenario=crashloop | grep -A 5 "Events"

# Diagnosticar ImagePullBackOff
kubectl describe pod -n lab-troubleshooting-test -l scenario=imagepull | grep -A 5 "Events"
```

### Paso 3: Diagnosticar Service sin Endpoints (2 min)

```bash
# Ver Services
kubectl get svc -n lab-troubleshooting-test

# Comparar endpoints: uno funciona, otro no
kubectl get endpoints -n lab-troubleshooting-test backend-broken-svc
# Output: ENDPOINTS: <none>

kubectl get endpoints -n lab-troubleshooting-test backend-ok-svc
# Output: ENDPOINTS: 10.x.x.x:80,10.x.x.x:80

# Diagnosticar: comparar selectors
kubectl get svc -n lab-troubleshooting-test backend-broken-svc -o jsonpath='{.spec.selector}'
# Output: {"app":"backend-wrong","tier":"api"} ← "backend-wrong" no existe

kubectl get pods -n lab-troubleshooting-test --show-labels | grep backend
# Labels reales: app=backend,tier=api
```

### Paso 4: Diagnosticar Probes (2 min)

```bash
# Ver pods con problemas de probes
kubectl get pods -n lab-troubleshooting-test -l scenario=probe-failure
# Output: RESTARTS incrementando constantemente

kubectl get pods -n lab-troubleshooting-test -l scenario=not-ready
# Output: READY 0/1

# Diagnosticar liveness
kubectl describe pod -n lab-troubleshooting-test web-liveness-broken | grep -A 5 "Liveness"
# Output: Liveness probe failed: HTTP probe failed with statuscode: 404

# Diagnosticar readiness
kubectl describe pod -n lab-troubleshooting-test web-readiness-broken | grep -A 5 "Readiness"
# Output: Readiness probe failed: connection refused (port 8080)
```

### Paso 5: Aplicar Correcciones (3 min)

```bash
# Fix 1: CrashLoopBackOff - corregir comando
kubectl patch deployment webapp-crash -n lab-troubleshooting-test \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","command":["nginx"],"args":["-g","daemon off;"]}]}}}}'

# Fix 2: ImagePullBackOff - corregir imagen
kubectl set image deployment/api-broken api=nginx:1.21 -n lab-troubleshooting-test

# Fix 3: Service sin endpoints - corregir selector
kubectl patch svc backend-broken-svc -n lab-troubleshooting-test \
  -p '{"spec":{"selector":{"app":"backend","tier":"api"}}}'

# Fix 4: Liveness probe - corregir path
kubectl delete pod web-liveness-broken -n lab-troubleshooting-test
# (Nota: el pod no tiene controller, asi que no se recrea automaticamente)
```

### Paso 6: Verificar DNS y Conectividad (2 min)

```bash
# Test DNS desde busybox
kubectl exec -n lab-troubleshooting-test busybox-dns-test -- \
  nslookup backend-ok-svc.lab-troubleshooting-test.svc.cluster.local

# Test conectividad al service funcional
kubectl exec -n lab-troubleshooting-test curl-test -- \
  curl -s http://backend-ok-svc.lab-troubleshooting-test/

# Verificar endpoints del service corregido
kubectl get endpoints -n lab-troubleshooting-test backend-broken-svc
# Ahora debe tener endpoints
```

### Paso 7: Verificar Estado Final (1 min)

```bash
# Todos los deployments deben estar Ready
kubectl get deployments -n lab-troubleshooting-test

# Verificar que los fixes funcionaron
kubectl get pods -n lab-troubleshooting-test
# Deployments: Running, pods individuales pueden haber terminado
```

### Paso 8: Limpieza (1 min)

```bash
# Eliminar todos los recursos
./cleanup.sh

# O manualmente:
kubectl delete namespace lab-troubleshooting-test
```

---

## Resumen Visual: Flujo de Troubleshooting

```
PROBLEMA DETECTADO
       |
       v
kubectl get pods/nodes/svc
       |
       v
  +----+----+
  |  Estado  |
  +----+----+
       |
       +-- CrashLoopBackOff --> kubectl logs --previous --> Fix args/config
       |
       +-- ImagePullBackOff --> kubectl describe pod --> Fix image tag
       |
       +-- Pending ----------> kubectl describe pod --> Resources/PVC/Scheduler
       |
       +-- Running 0/1 ------> kubectl describe pod --> Fix readiness probe
       |
       +-- NotReady (node) --> journalctl -u kubelet --> Fix kubelet/CNI
       |
       +-- Service no funciona --> kubectl get endpoints --> Fix selectors/ports
```

---

## Decision: Donde Buscar por Tipo de Problema

| Problema | Donde Buscar |
|----------|-------------|
| **Pod no inicia** | `kubectl describe pod` → Events |
| **Pod crashea** | `kubectl logs --previous` |
| **Service no funciona** | `kubectl get endpoints`, comparar selectors |
| **DNS no resuelve** | CoreDNS pods, `kubectl get svc kube-dns -n kube-system` |
| **Node NotReady** | `kubectl describe node`, `journalctl -u kubelet` |
| **API Server down** | `crictl ps`, `/etc/kubernetes/manifests/` |
| **etcd issues** | `etcdctl endpoint health`, certificados |
| **Storage issues** | `kubectl get pv,pvc`, StorageClass |

---

## Preparacion CKA: Comandos Rapidos

```bash
# DIAGNOSTICO RAPIDO (30 seg)
kubectl get pods -A | grep -v Running
kubectl get nodes
kubectl get events --sort-by='.lastTimestamp' | head -20

# LOGS (1 min)
kubectl logs <pod> --previous
kubectl logs <pod> -c <container>
sudo journalctl -u kubelet -n 50 --no-pager

# NETWORKING (1 min)
kubectl get svc,endpoints
kubectl run test --image=busybox:1.28 --rm -it -- nslookup kubernetes.default
kubectl get networkpolicies

# STORAGE (30 seg)
kubectl get pv,pvc
kubectl get sc
kubectl describe pvc <name>

# ETCD BACKUP (2 min)
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /backup/snapshot.db
```
