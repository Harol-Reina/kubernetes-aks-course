# Laboratorio 04: Troubleshooting de Networking y Services

## Objetivos

Al finalizar este laboratorio, serás capaz de:
- ✓ Diagnosticar problemas de conectividad en Services
- ✓ Debuggear issues de DNS resolution
- ✓ Analizar flujo de tráfico en el cluster
- ✓ Resolver problemas comunes de networking
- ✓ Usar herramientas de debugging en producción

## Duración Estimada

⏱️ 90-120 minutos

## Pre-requisitos

- Cluster Kubernetes funcional
- Herramientas instaladas: `tcpdump`, `netcat`, `dig`, `curl`
- Acceso a crear/eliminar recursos
- Conocimientos básicos de networking

---

## Parte 1: Troubleshooting de Services (35 minutos)

### 🔴 Problema 1: Service No Responde

**Escenario:** Un usuario reporta que su aplicación no responde.

**Paso 1:** Crea el escenario problemático

```bash
# Deployment con PUERTO INCORRECTO
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: broken-service
spec:
  selector:
    app: broken-app
  ports:
  - port: 80
    targetPort: 8080  # ❌ INCORRECTO - nginx escucha en 80
EOF
```

**Paso 2:** Intenta conectar al Service

```bash
kubectl run test --rm -it --image=busybox -- wget -O- broken-service
```

**Debería FALLAR con timeout**

---

**🔍 DEBUGGING:**

**Paso 3:** Verifica que el Service existe

```bash
kubectl get svc broken-service
```

✅ Service existe

**Paso 4:** Verifica los endpoints

```bash
kubectl get endpoints broken-service
```

**Pregunta:** ¿Hay IPs en los endpoints? ¿Cuántas?

✅ Deberías ver 3 IPs (una por cada pod)

**Paso 5:** Verifica que los pods están corriendo

```bash
kubectl get pods -l app=broken-app
```

✅ 3 pods en estado Running

**Paso 6:** Intenta conectar directamente a un pod

```bash
POD_IP=$(kubectl get pod -l app=broken-app -o jsonpath='{.items[0].status.podIP}')
echo "Pod IP: $POD_IP"

kubectl run test --rm -it --image=busybox -- wget -O- http://$POD_IP:80
```

✅ **Esto FUNCIONA** - el pod responde en puerto 80

**Paso 7:** Compara el Service

```bash
kubectl describe svc broken-service | grep -A 3 "Port:"
```

❌ **ENCONTRADO EL PROBLEMA:** `targetPort: 8080` pero el pod escucha en `80`

---

**✅ SOLUCIÓN:**

```bash
kubectl patch svc broken-service -p '{"spec":{"ports":[{"port":80,"targetPort":80}]}}'

# Verifica
kubectl run test --rm -it --image=busybox -- wget -O- broken-service
```

✅ Ahora funciona

---

### 🔴 Problema 2: Service Sin Endpoints

**Escenario:** Service creado pero no tiene endpoints.

**Paso 1:** Crea el escenario

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend-app  # Label: backend-app
  template:
    metadata:
      labels:
        app: backend-app
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend  # ❌ INCORRECTO - busca "backend" no "backend-app"
  ports:
  - port: 80
EOF
```

**Paso 2:** Verifica endpoints

```bash
kubectl get endpoints backend-service
```

❌ **ENDPOINTS: <none>**

---

**🔍 DEBUGGING:**

**Paso 3:** Compara los labels

```bash
# Labels del Service selector
kubectl get svc backend-service -o jsonpath='{.spec.selector}'
echo

# Labels de los pods
kubectl get pods -l app=backend-app -o jsonpath='{.items[0].metadata.labels}'
echo
```

❌ **PROBLEMA:** Selector no coincide con los labels de los pods

---

**✅ SOLUCIÓN:**

```bash
kubectl patch svc backend-service -p '{"spec":{"selector":{"app":"backend-app"}}}'

# Verifica
kubectl get endpoints backend-service
```

✅ Ahora tiene endpoints

---

### 🔴 Problema 3: NodePort Inaccesible

**Escenario:** NodePort configurado pero no se puede acceder desde fuera.

**Paso 1:** Crea un NodePort Service

```bash
kubectl create deployment web --image=nginx
kubectl expose deployment web --type=NodePort --port=80
```

**Paso 2:** Obtén el NodePort

```bash
NODE_PORT=$(kubectl get svc web -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "URL: http://$NODE_IP:$NODE_PORT"
```

**Paso 3:** Intenta acceder (puede fallar dependiendo de firewall)

```bash
curl http://$NODE_IP:$NODE_PORT
```

---

**🔍 DEBUGGING:**

**Paso 4:** Verifica desde DENTRO de un nodo

```bash
# SSH al nodo
ssh $NODE_IP

# Desde el nodo
curl localhost:$NODE_PORT
```

✅ Funciona desde el nodo

**Paso 5:** Verifica firewall

```bash
# En el nodo
sudo iptables -L -n | grep $NODE_PORT
```

**Paso 6:** Verifica que kube-proxy creó las reglas

```bash
sudo iptables -t nat -L KUBE-NODEPORTS -n | grep $NODE_PORT
```

✅ Reglas existen

---

**💡 CAUSA COMÚN:** Firewall externo bloquea el puerto

**✅ SOLUCIONES:**
- Abrir puerto en firewall del cloud provider
- Usar LoadBalancer en lugar de NodePort
- Usar Ingress Controller

---

## Parte 2: Troubleshooting DNS (30 minutos)

### 🔴 Problema 4: DNS No Resuelve

**Escenario:** Pods no pueden resolver nombres de Services.

**Paso 1:** Crea un Service

```bash
kubectl create deployment myapp --image=nginx
kubectl expose deployment myapp --port=80
```

**Paso 2:** Intenta resolver desde un pod

```bash
kubectl run dns-debug --rm -it --image=busybox -- sh

# Dentro del pod:
nslookup myapp
```

**Si falla, continúa con el debugging...**

---

**🔍 DEBUGGING:**

**Paso 3:** Verifica que CoreDNS está corriendo

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

❌ Si no hay pods o están en CrashLoopBackOff → **PROBLEMA ENCONTRADO**

**Paso 4:** Verifica el Service de CoreDNS

```bash
kubectl get svc -n kube-system kube-dns
```

✅ Debería tener ClusterIP (típicamente 10.96.0.10)

**Paso 5:** Verifica /etc/resolv.conf en el pod

```bash
kubectl run dns-debug --rm -it --image=busybox -- cat /etc/resolv.conf
```

Debería tener:
```
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

❌ Si no está configurado correctamente → **PROBLEMA EN KUBELET**

**Paso 6:** Prueba DNS directamente

```bash
kubectl run dns-debug --rm -it --image=busybox -- nslookup kubernetes 10.96.0.10
```

✅ Si esto funciona, el problema está en la configuración del pod, no en CoreDNS

---

**✅ SOLUCIONES COMUNES:**

1. **CoreDNS no corre:**
```bash
kubectl rollout restart deployment coredns -n kube-system
```

2. **ConfigMap corrupto:**
```bash
kubectl get configmap coredns -n kube-system -o yaml
# Verifica que el Corefile está correcto
```

3. **Pods de CoreDNS sin recursos:**
```bash
kubectl describe pod -n kube-system -l k8s-app=kube-dns
# Verifica eventos
```

---

### 🔴 Problema 5: DNS Lento

**Escenario:** DNS funciona pero es muy lento.

**Paso 1:** Mide la latencia

```bash
kubectl run perf-test --rm -it --image=busybox -- sh

# Dentro del pod:
time nslookup kubernetes
time nslookup google.com
```

**Paso 2:** Verifica cache hits en CoreDNS

```bash
# Port-forward a las métricas de CoreDNS
kubectl port-forward -n kube-system svc/kube-dns 9153:9153 &

# Ver métricas de cache
curl http://localhost:9153/metrics | grep coredns_cache
```

**Paso 3:** Verifica carga de CoreDNS

```bash
kubectl top pods -n kube-system -l k8s-app=kube-dns
```

---

**✅ SOLUCIONES:**

1. **Aumentar cache TTL en CoreDNS:**
```bash
kubectl edit configmap coredns -n kube-system
# Cambiar: cache 30 → cache 300
```

2. **Escalar CoreDNS:**
```bash
kubectl scale deployment coredns -n kube-system --replicas=3
```

3. **Usar NodeLocal DNS Cache** (avanzado)

---

## Parte 3: Análisis de Flujo de Tráfico (25 minutos)

### 📝 Ejercicio 3.1: tcpdump en un Pod

**Paso 1:** Crea un pod con herramientas de networking

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: netshoot
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
EOF
```

**Paso 2:** Ejecuta tcpdump en el pod

```bash
kubectl exec -it netshoot -- tcpdump -i any -n port 80
```

**Deja esto corriendo...**

**Paso 3:** En otra terminal, genera tráfico

```bash
kubectl exec netshoot -- curl http://google.com
```

**Observa el tcpdump** - deberías ver paquetes HTTP

---

### 📝 Ejercicio 3.2: Rastrear Request de Service

**Paso 1:** Crea un Service y pods

```bash
kubectl create deployment trace-test --image=nginx --replicas=2
kubectl expose deployment trace-test --port=80
```

**Paso 2:** Desde un pod de debug, captura tráfico

```bash
# En netshoot pod
kubectl exec -it netshoot -- tcpdump -i any -n host $(kubectl get svc trace-test -o jsonpath='{.spec.clusterIP}')
```

**Paso 3:** En otra terminal, haz requests

```bash
kubectl exec netshoot -- curl trace-test
kubectl exec netshoot -- curl trace-test
kubectl exec netshoot -- curl trace-test
```

**Observa:** Verás paquetes a diferentes pod IPs (balanceo de carga)

---

### 📝 Ejercicio 3.3: iptables Tracing

**Paso 1:** Desde un worker node, habilita tracing de iptables

```bash
# ⚠️ Solo en entorno de prueba
sudo modprobe ipt_LOG

# Agregar regla de log
SERVICE_IP=$(kubectl get svc trace-test -o jsonpath='{.spec.clusterIP}')
sudo iptables -t nat -I KUBE-SERVICES -d $SERVICE_IP -j LOG --log-prefix "KUBE-SERVICE: "
```

**Paso 2:** Genera tráfico

```bash
kubectl exec netshoot -- curl trace-test
```

**Paso 3:** Ver logs de iptables

```bash
# En el nodo
sudo dmesg | grep "KUBE-SERVICE"
```

**Paso 4:** Limpieza

```bash
sudo iptables -t nat -D KUBE-SERVICES -d $SERVICE_IP -j LOG --log-prefix "KUBE-SERVICE: "
```

---

## Parte 4: Debugging Avanzado (20 minutos)

### 📝 Ejercicio 4.1: Ephemeral Debug Container

**Paso 1:** Crea un pod sin herramientas de debug

```bash
kubectl run minimal --image=nginx
```

**Paso 2:** Agrega un ephemeral container para debugging

```bash
kubectl debug minimal -it --image=busybox --target=minimal
```

**Ahora tienes un shell en el namespace del pod original**

**Paso 3:** Debugging

```bash
# Dentro del debug container
ps aux  # Ver procesos del pod minimal
netstat -tulpn  # Ver puertos
ls -la /proc/1/root  # Ver filesystem del contenedor target
```

---

### 📝 Ejercicio 4.2: Debug de Nodo

**Paso 1:** Crea un pod de debug en un nodo

```bash
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl debug node/$NODE -it --image=ubuntu
```

**Esto crea un pod privilegiado con acceso al filesystem del nodo**

**Paso 2:** Explora el nodo

```bash
# Dentro del debug pod
chroot /host

# Ahora estás en el nodo
ps aux | grep kubelet
journalctl -u kubelet -n 50
```

---

### 📝 Ejercicio 4.3: Service Mesh Debugging (si usas Istio/Linkerd)

**Paso 1:** Verifica sidecar injection

```bash
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].name}'
```

**Deberías ver:** `app-container istio-proxy` (o `linkerd-proxy`)

**Paso 2:** Ver logs del sidecar

```bash
kubectl logs <pod-name> -c istio-proxy
```

**Paso 3:** Verificar comunicación

```bash
kubectl exec <pod-name> -c app-container -- curl localhost:15000/stats
```

---

## Parte 5: Escenarios Reales (10 minutos)

### 🚨 Caso 1: "Intermittent Connection Failures"

**Síntomas:**
- Algunas requests funcionan, otras fallan
- No hay patrón claro

**Debugging:**
```bash
# 1. Verificar health de todos los endpoints
kubectl get endpoints <service-name> -o yaml

# 2. Probar conectividad a cada endpoint
for ip in $(kubectl get endpoints <service-name> -o jsonpath='{.subsets[*].addresses[*].ip}'); do
  echo "Testing $ip..."
  kubectl exec netshoot -- curl -m 2 http://$ip || echo "FAILED"
done

# 3. Ver readiness probes
kubectl describe pod -l app=<app>
```

**Causa común:** Uno o más pods están en estado "Not Ready" pero no se quitaron de endpoints.

---

### 🚨 Caso 2: "Service Works from Some Pods, Not Others"

**Síntomas:**
- Service funciona desde pod A
- Service NO funciona desde pod B

**Debugging:**
```bash
# 1. Verificar NetworkPolicies
kubectl get networkpolicies

# 2. Ver si hay políticas que afecten el tráfico
kubectl describe networkpolicy <policy-name>

# 3. Probar desde pod con label diferente
kubectl run test-1 --rm -it --image=busybox --labels=role=frontend -- wget <service>
kubectl run test-2 --rm -it --image=busybox --labels=role=backend -- wget <service>
```

**Causa común:** NetworkPolicy bloqueando tráfico desde ciertos pods.

---

### 🚨 Caso 3: "External Traffic Not Reaching Service"

**Síntomas:**
- Interno funciona (ClusterIP)
- LoadBalancer/Ingress no responde

**Debugging:**
```bash
# 1. Verificar el Load Balancer
kubectl get svc <service-name>
# EXTERNAL-IP debe tener una IP (no <pending>)

# 2. Verificar Ingress
kubectl get ingress
kubectl describe ingress <ingress-name>

# 3. Ver logs del Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# 4. Verificar que el Service tiene endpoints
kubectl get endpoints <service-name>
```

---

## Checklist de Troubleshooting

Usa esta checklist cuando debuggees problemas de networking:

### Para Services que no responden:

- [ ] Service existe: `kubectl get svc <name>`
- [ ] Service tiene endpoints: `kubectl get endpoints <name>`
- [ ] Pods están Running: `kubectl get pods -l <selector>`
- [ ] Labels coinciden: Comparar selector del Service vs labels de pods
- [ ] Puertos correctos: targetPort coincide con containerPort
- [ ] Pods responden directamente: `curl http://<pod-ip>:<port>`
- [ ] Firewall permite tráfico (para NodePort/LoadBalancer)

### Para problemas de DNS:

- [ ] CoreDNS está corriendo: `kubectl get pods -n kube-system -l k8s-app=kube-dns`
- [ ] Service kube-dns existe: `kubectl get svc -n kube-system kube-dns`
- [ ] /etc/resolv.conf correcto en pods
- [ ] Probar resolución directa: `nslookup <service> <dns-ip>`
- [ ] Verificar logs de CoreDNS
- [ ] Verificar ConfigMap de CoreDNS

### Para problemas de conectividad:

- [ ] NetworkPolicies no bloquean: `kubectl get networkpolicies`
- [ ] CNI plugin funciona: `kubectl get pods -n kube-system -l <cni-label>`
- [ ] Routing entre nodos funciona
- [ ] iptables/IPVS rules correctas en nodos

---

## Herramientas Útiles

```bash
# Debug pod todo-en-uno
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# Dentro de netshoot tienes:
# - curl, wget
# - dig, nslookup, host
# - tcpdump
# - netstat, ss
# - iperf3
# - traceroute
# - nmap
# y muchas más...
```

---

## Limpieza

```bash
kubectl delete deployment broken-app backend web trace-test myapp --ignore-not-found
kubectl delete service broken-service backend-service web trace-test myapp --ignore-not-found
kubectl delete pod netshoot minimal --ignore-not-found
```

---

## Verificación Final

### ✅ Checklist de Conocimientos

- [ ] Puedo diagnosticar por qué un Service no responde
- [ ] Sé cómo verificar que selector y labels coinciden
- [ ] Puedo troubleshootear problemas de DNS
- [ ] Entiendo cómo usar tcpdump en pods
- [ ] Puedo crear ephemeral debug containers
- [ ] Sé cómo verificar NetworkPolicies
- [ ] Puedo analizar iptables rules de kube-proxy
- [ ] Conozco las causas comunes de problemas de networking
- [ ] Tengo un proceso sistemático para debugging

---

## Recursos Adicionales

- 📖 [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)
- 📖 [DNS Troubleshooting](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
- 🛠️ [Netshoot - Network Troubleshooting Tool](https://github.com/nicolaka/netshoot)
- 📖 [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

---

**¡Felicitaciones!** Has completado todos los laboratorios del Módulo 02 ✅

**Siguiente paso:** Revisa el resumen del módulo y prepárate para el Módulo 03.
