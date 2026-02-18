# Ejemplo 02: Troubleshooting Tools - Herramientas de Debugging

> **Objetivo**: Tener un arsenal de pods de debugging listo para usar  
> **Dificultad**: ⭐⭐ (Básico-Intermedio)  
> **Tiempo estimado**: 20-30 minutos

## 📋 Descripción

Este ejemplo proporciona 10 tipos diferentes de pods de debugging que puedes desplegar rápidamente para diagnosticar problemas de red, DNS, conectividad, y aplicaciones en tu cluster.

## 🎯 Objetivos de Aprendizaje

- ✅ Conocer las herramientas esenciales de debugging
- ✅ Usar netshoot para troubleshooting de red
- ✅ Debuggear DNS con dnsutils
- ✅ Test de conectividad HTTP con curl
- ✅ Usar pods con privilegios elevados cuando sea necesario
- ✅ Mantener pods de debug permanentes

## 📁 Archivos en este Ejemplo

```
02-troubleshooting-tools/
├── README.md                           # Este archivo
├── troubleshooting-tools.yaml          # Pods de debugging
├── deploy-all.sh                       # Deploy todos los tools
└── cleanup.sh                          # Limpiar recursos
```

## 🛠️ Herramientas Incluidas

### 1. **netshoot** - Swiss Army Knife de Networking
Imagen completa con todas las herramientas de red.

**Herramientas incluidas**:
- `tcpdump`, `nmap`, `iperf`, `netstat`
- `curl`, `wget`, `telnet`, `nc`
- `dig`, `nslookup`, `host`
- `ping`, `traceroute`, `mtr`

**Uso**:
```bash
kubectl run netshoot --image=nicolaka/netshoot -it --rm -- bash
```

### 2. **busybox** - Lightweight Testing
Imagen minimalista para tests rápidos.

**Uso**:
```bash
kubectl run busybox --image=busybox:1.28 -it --rm -- sh
```

### 3. **dnsutils** - DNS Troubleshooting
Especializado en diagnóstico DNS.

**Herramientas**:
- `nslookup`, `dig`, `host`

**Uso**:
```bash
kubectl run dnsutils --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 -it --rm -- sh
```

### 4. **curl** - HTTP Testing
Para tests de conectividad HTTP/HTTPS.

**Uso**:
```bash
kubectl run curl --image=curlimages/curl:latest -it --rm -- sh
```

### 5. **alpine** - Minimal with Package Manager
Alpine Linux con apk para instalar herramientas adicionales.

**Uso**:
```bash
kubectl run alpine --image=alpine:latest -it --rm -- sh
# Dentro del pod:
apk add --no-cache curl wget tcpdump
```

### 6. **ubuntu** - Full Linux Environment
Ubuntu completo para troubleshooting avanzado.

**Uso**:
```bash
kubectl run ubuntu --image=ubuntu:22.04 -it --rm -- bash
# Dentro del pod:
apt-get update && apt-get install -y curl iputils-ping dnsutils
```

### 7. **netshoot-hostnet** - Con Host Networking
netshoot con acceso a la red del host.

**Uso**: Ya definido en YAML, usar `kubectl exec`

### 8. **privileged-debug** - Modo Privilegiado
Para debugging que requiere permisos elevados.

**Uso**: Ya definido en YAML, usar `kubectl exec`

### 9. **python-debug** - Para Apps Python
Python con herramientas de debugging.

**Uso**:
```bash
kubectl exec -it python-debug -- python3
```

### 10. **nodejs-debug** - Para Apps Node.js
Node.js con npm y herramientas.

**Uso**:
```bash
kubectl exec -it nodejs-debug -- node
```

### 11. **debug-netshoot Deployment** - Permanente
Deployment de netshoot siempre disponible.

## 🚀 Instrucciones de Uso

### Quick Start

```bash
# Opción 1: Deploy todos los tools
chmod +x deploy-all.sh
./deploy-all.sh

# Opción 2: Deploy solo lo necesario
kubectl apply -f troubleshooting-tools.yaml
```

### Casos de Uso Comunes

#### Caso 1: Test DNS

```bash
# Usar dnsutils
kubectl run dnsutils --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 -it --rm -- sh

# Dentro del pod:
nslookup kubernetes.default
nslookup google.com
dig kubernetes.default.svc.cluster.local
```

#### Caso 2: Test Conectividad a Service

```bash
# Usar netshoot
kubectl run netshoot --image=nicolaka/netshoot -it --rm -- bash

# Dentro del pod:
curl http://my-service.default.svc.cluster.local
telnet my-service 80
nc -zv my-service 80
```

#### Caso 3: Capturar Tráfico de Red

```bash
# Usar netshoot con hostNetwork
kubectl exec -it netshoot-hostnet -- bash

# Capturar tráfico
tcpdump -i any port 80 -w /tmp/capture.pcap
tcpdump -i any host 10.244.1.5 -n
```

#### Caso 4: Test de Performance de Red

```bash
# Terminal 1: Server
kubectl run iperf-server --image=nicolaka/netshoot -- iperf -s

# Terminal 2: Client
POD_IP=$(kubectl get pod iperf-server -o jsonpath='{.status.podIP}')
kubectl run iperf-client --image=nicolaka/netshoot -it --rm -- iperf -c $POD_IP
```

#### Caso 5: Debugging de Aplicación Python

```bash
# Ejecutar dentro del pod
kubectl exec -it python-debug -- bash

# Probar imports
python3 -c "import requests; print(requests.get('http://google.com').status_code)"

# Instalar paquetes adicionales
pip install redis
python3 -c "import redis; print('Redis OK')"
```

## 📊 Comparación de Herramientas

| Tool | Tamaño | Casos de Uso | Herramientas Clave |
|------|--------|--------------|-------------------|
| **netshoot** | ~300MB | Networking completo | tcpdump, nmap, curl, dig |
| **busybox** | ~5MB | Tests rápidos | wget, ping, nslookup |
| **dnsutils** | ~10MB | Solo DNS | dig, nslookup, host |
| **curl** | ~5MB | HTTP only | curl |
| **alpine** | ~7MB | Base + customización | apk package manager |
| **ubuntu** | ~100MB | Full environment | apt package manager |
| **python-debug** | ~150MB | Python apps | python3, pip |
| **nodejs-debug** | ~200MB | Node.js apps | node, npm |

## 🎓 Escenarios de Práctica

### Escenario 1: Servicio no responde

```bash
# Deploy un servicio de prueba
kubectl run nginx --image=nginx
kubectl expose pod nginx --port=80

# Test con netshoot
kubectl run test --image=nicolaka/netshoot -it --rm -- bash
# Dentro:
curl http://nginx.default.svc.cluster.local
nslookup nginx.default.svc.cluster.local
telnet nginx 80
```

### Escenario 2: DNS no funciona

```bash
# Test DNS
kubectl run dnstest --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 -it --rm -- sh

# Checks:
nslookup kubernetes.default
# Si falla, verificar:
cat /etc/resolv.conf
# Debe apuntar a 10.96.0.10 o la IP del kube-dns service
```

### Escenario 3: Problemas de conectividad entre namespaces

```bash
# Crear namespace y pod
kubectl create namespace test-ns
kubectl run pod-in-ns --image=nginx -n test-ns
kubectl expose pod pod-in-ns --port=80 -n test-ns

# Test desde default namespace
kubectl run test --image=nicolaka/netshoot -it --rm -- bash
curl http://pod-in-ns.test-ns.svc.cluster.local

# Si falla, verificar Network Policies
kubectl get networkpolicies -n test-ns
```

## 🔍 Tips y Trucos

### Tip 1: Mantener pod de debug permanente

```bash
# Deploy el deployment de netshoot
kubectl apply -f troubleshooting-tools.yaml
# Buscar: kind: Deployment, name: debug-netshoot

# Usar siempre disponible
kubectl exec -it deployment/debug-netshoot -- bash
```

### Tip 2: Crear alias útiles

```bash
# Agregar a ~/.bashrc o ~/.zshrc
alias kdebug='kubectl run debug-$RANDOM --image=nicolaka/netshoot -it --rm -- bash'
alias kdns='kubectl run dns-$RANDOM --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 -it --rm -- sh'
alias kcurl='kubectl run curl-$RANDOM --image=curlimages/curl -it --rm -- sh'
```

### Tip 3: Test rápido de conectividad

```bash
# One-liner para test HTTP
kubectl run test-$RANDOM --image=curlimages/curl --rm -it -- curl -v http://my-service

# One-liner para test DNS
kubectl run test-$RANDOM --image=busybox:1.28 --rm -it -- nslookup my-service
```

### Tip 4: Debugging con permisos elevados

```bash
# Cuando necesites acceso al host
kubectl run privileged-debug --image=nicolaka/netshoot --rm -it \
  --overrides='{"spec":{"hostNetwork":true,"hostPID":true,"securityContext":{"privileged":true}}}' \
  -- bash

# Dentro puedes acceder a:
# - Host network interfaces
# - Host processes (ps aux)
# - Host filesystem (/host si montas)
```

## 🧹 Limpieza

```bash
# Usar script
chmod +x cleanup.sh
./cleanup.sh

# O manualmente
kubectl delete pod netshoot busybox dnsutils curl-pod alpine-pod ubuntu-pod \
  netshoot-hostnet privileged-debug python-debug nodejs-debug --ignore-not-found
kubectl delete deployment debug-netshoot --ignore-not-found
```

## 📚 Comandos de Referencia

### Networking
```bash
# Test conectividad
curl -v http://service:port
telnet service port
nc -zv service port

# DNS
nslookup service.namespace.svc.cluster.local
dig service.namespace.svc.cluster.local
host service

# Captura de tráfico
tcpdump -i any port 80
tcpdump -i any host <IP>

# Network info
ip addr
ip route
netstat -tulpn
ss -tulpn
```

### Debugging
```bash
# Procesos
ps aux
top
htop

# Filesystem
ls -la /
df -h
du -sh /*

# Variables de entorno
env
printenv

# Conectividad
ping <host>
traceroute <host>
mtr <host>
```

## 🎯 Checklist

- [ ] Puedo desplegar netshoot rápidamente
- [ ] Sé usar dnsutils para troubleshoot DNS
- [ ] Puedo hacer tests de conectividad HTTP
- [ ] Entiendo cuándo usar host networking
- [ ] Sé cuándo necesito pods privilegiados
- [ ] Puedo capturar tráfico de red con tcpdump
- [ ] Conozco las limitaciones de cada herramienta

---

**Siguiente**: [Ejemplo 03 - Common Errors](../03-common-errors/)
