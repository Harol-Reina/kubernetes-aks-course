# Laboratorio 04: Troubleshooting de Networking y Services

## Objetivos

Al finalizar este laboratorio, seras capaz de:
- Diagnosticar problemas de conectividad en Services
- Debuggear issues de DNS resolution
- Analizar flujo de trafico en el cluster
- Resolver problemas comunes de networking
- Usar herramientas de debugging en produccion

## Duracion Estimada

90-120 minutos | Avanzado

## Pre-requisitos

- Cluster Kubernetes funcional
- Herramientas instaladas: `tcpdump`, `netcat`, `dig`, `curl`
- Acceso a crear/eliminar recursos
- Conocimientos basicos de networking

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| Service targetPort debugging | Comparar targetPort del Service con containerPort del Pod |
| Label selector matching | Verificar alineacion entre selector del Service y labels del Pod |
| Endpoint inspection | Usar `kubectl get endpoints` para detectar desconexion Pod-Service |
| tcpdump en Pod | Capturar trafico de red desde dentro de un contenedor |
| DNS troubleshooting | Diagnosticar CoreDNS con nslookup, dig y /etc/resolv.conf |
| Ephemeral debug containers | Agregar contenedor de debug a un Pod en ejecucion sin herramientas |
| iptables tracing | Rastrear el flujo de trafico a traves de las reglas de kube-proxy |
| NetworkPolicy analysis | Identificar politicas que bloquean trafico entre Pods |

## Archivos YAML del Laboratorio

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `broken-app-service.yaml` | Problema 1 | Deployment + Service con targetPort incorrecto (8080 vs 80) |
| `backend-label-mismatch.yaml` | Problema 2 | Deployment + Service con selector que no coincide con labels |
| `netshoot-pod.yaml` | Ejercicio 3.1 | Pod de diagnostico con nicolaka/netshoot |

---

## Parte 1: Troubleshooting de Services (35 minutos)

### Problema 1: Service No Responde

**Escenario:** Un usuario reporta que su aplicacion no responde.

**Paso 1:** Crea el escenario problematico

```bash
kubectl apply -f broken-app-service.yaml
```

**Paso 2:** Intenta conectar al Service

```bash
kubectl run test --rm -it --image=busybox -- wget -O- broken-service
```

**Deberia FALLAR con timeout**

---

**DEBUGGING:**

**Paso 3:** Verifica que el Service existe

```bash
kubectl get svc broken-service
```

Service existe

**Paso 4:** Verifica los endpoints

```bash
kubectl get endpoints broken-service
```

**Pregunta:** Hay IPs en los endpoints? Cuantas?

Deberias ver 3 IPs (una por cada pod)

**Paso 5:** Verifica que los pods estan corriendo

```bash
kubectl get pods -l app=broken-app
```

3 pods en estado Running

**Paso 6:** Intenta conectar directamente a un pod

```bash
POD_IP=$(kubectl get pod -l app=broken-app -o jsonpath='{.items[0].status.podIP}')
echo "Pod IP: $POD_IP"

kubectl run test --rm -it --image=busybox -- wget -O- http://$POD_IP:80
```

**Esto FUNCIONA** - el pod responde en puerto 80

**Paso 7:** Compara el Service

```bash
kubectl describe svc broken-service | grep -A 3 "Port:"
```

**ENCONTRADO EL PROBLEMA:** `targetPort: 8080` pero el pod escucha en `80`

---

**SOLUCION:**

```bash
kubectl patch svc broken-service -p '{"spec":{"ports":[{"port":80,"targetPort":80}]}}'

# Verifica
kubectl run test --rm -it --image=busybox -- wget -O- broken-service
```

Ahora funciona

---

### Problema 2: Service Sin Endpoints

**Escenario:** Service creado pero no tiene endpoints.

**Paso 1:** Crea el escenario

```bash
kubectl apply -f backend-label-mismatch.yaml
```

**Paso 2:** Verifica endpoints

```bash
kubectl get endpoints backend-service
```

**ENDPOINTS: none**

---

**DEBUGGING:**

**Paso 3:** Compara los labels

```bash
# Labels del Service selector
kubectl get svc backend-service -o jsonpath='{.spec.selector}'
echo

# Labels de los pods
kubectl get pods -l app=backend-app -o jsonpath='{.items[0].metadata.labels}'
echo
```

**PROBLEMA:** Selector no coincide con los labels de los pods

---

**SOLUCION:**

```bash
kubectl patch svc backend-service -p '{"spec":{"selector":{"app":"backend-app"}}}'

# Verifica
kubectl get endpoints backend-service
```

Ahora tiene endpoints

---

### Problema 3: NodePort Inaccesible

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

**DEBUGGING:**

**Paso 4:** Verifica desde DENTRO de un nodo

```bash
# SSH al nodo
ssh $NODE_IP

# Desde el nodo
curl localhost:$NODE_PORT
```

Funciona desde el nodo

**Paso 5:** Verifica firewall

```bash
# En el nodo
sudo iptables -L -n | grep $NODE_PORT
```

**Paso 6:** Verifica que kube-proxy creo las reglas

```bash
sudo iptables -t nat -L KUBE-NODEPORTS -n | grep $NODE_PORT
```

Reglas existen

---

**CAUSA COMUN:** Firewall externo bloquea el puerto

**SOLUCIONES:**
- Abrir puerto en firewall del cloud provider
- Usar LoadBalancer en lugar de NodePort
- Usar Ingress Controller

---

## Parte 2: Troubleshooting DNS (30 minutos)

### Problema 4: DNS No Resuelve

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

**Si falla, continua con el debugging...**

---

**DEBUGGING:**

**Paso 3:** Verifica que CoreDNS esta corriendo

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Si no hay pods o estan en CrashLoopBackOff - PROBLEMA ENCONTRADO

**Paso 4:** Verifica el Service de CoreDNS

```bash
kubectl get svc -n kube-system kube-dns
```

Deberia tener ClusterIP (tipicamente 10.96.0.10)

**Paso 5:** Verifica /etc/resolv.conf en el pod

```bash
kubectl run dns-debug --rm -it --image=busybox -- cat /etc/resolv.conf
```

Deberia tener:
```
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

Si no esta configurado correctamente - PROBLEMA EN KUBELET

**Paso 6:** Prueba DNS directamente

```bash
kubectl run dns-debug --rm -it --image=busybox -- nslookup kubernetes 10.96.0.10
```

Si esto funciona, el problema esta en la configuracion del pod, no en CoreDNS

---

**SOLUCIONES COMUNES:**

1. **CoreDNS no corre:**
```bash
kubectl rollout restart deployment coredns -n kube-system
```

2. **ConfigMap corrupto:**
```bash
kubectl get configmap coredns -n kube-system -o yaml
# Verifica que el Corefile esta correcto
```

3. **Pods de CoreDNS sin recursos:**
```bash
kubectl describe pod -n kube-system -l k8s-app=kube-dns
# Verifica eventos
```

---

### Problema 5: DNS Lento

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
# Port-forward a las metricas de CoreDNS
kubectl port-forward -n kube-system svc/kube-dns 9153:9153 &

# Ver metricas de cache
curl http://localhost:9153/metrics | grep coredns_cache
```

**Paso 3:** Verifica carga de CoreDNS

```bash
kubectl top pods -n kube-system -l k8s-app=kube-dns
```

---

**SOLUCIONES:**

1. **Aumentar cache TTL en CoreDNS:**
```bash
kubectl edit configmap coredns -n kube-system
# Cambiar: cache 30 a cache 300
```

2. **Escalar CoreDNS:**
```bash
kubectl scale deployment coredns -n kube-system --replicas=3
```

3. **Usar NodeLocal DNS Cache** (avanzado)

---

## Parte 3: Analisis de Flujo de Trafico (25 minutos)

### Ejercicio 3.1: tcpdump en un Pod

**Paso 1:** Crea un pod con herramientas de networking

```bash
kubectl apply -f netshoot-pod.yaml
```

**Paso 2:** Ejecuta tcpdump en el pod

```bash
kubectl exec -it netshoot -- tcpdump -i any -n port 80
```

**Deja esto corriendo...**

**Paso 3:** En otra terminal, genera trafico

```bash
kubectl exec netshoot -- curl http://google.com
```

**Observa el tcpdump** - deberias ver paquetes HTTP

---

### Ejercicio 3.2: Rastrear Request de Service

**Paso 1:** Crea un Service y pods

```bash
kubectl create deployment trace-test --image=nginx --replicas=2
kubectl expose deployment trace-test --port=80
```

**Paso 2:** Desde un pod de debug, captura trafico

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

**Observa:** Veras paquetes a diferentes pod IPs (balanceo de carga)

---

### Ejercicio 3.3: iptables Tracing

**Paso 1:** Desde un worker node, habilita tracing de iptables

```bash
# Solo en entorno de prueba
sudo modprobe ipt_LOG

# Agregar regla de log
SERVICE_IP=$(kubectl get svc trace-test -o jsonpath='{.spec.clusterIP}')
sudo iptables -t nat -I KUBE-SERVICES -d $SERVICE_IP -j LOG --log-prefix "KUBE-SERVICE: "
```

**Paso 2:** Genera trafico

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

### Ejercicio 4.1: Ephemeral Debug Container

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

### Ejercicio 4.2: Debug de Nodo

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

# Ahora estas en el nodo
ps aux | grep kubelet
journalctl -u kubelet -n 50
```

---

### Ejercicio 4.3: Service Mesh Debugging (si usas Istio/Linkerd)

**Paso 1:** Verifica sidecar injection

```bash
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].name}'
```

**Deberias ver:** `app-container istio-proxy` (o `linkerd-proxy`)

**Paso 2:** Ver logs del sidecar

```bash
kubectl logs <pod-name> -c istio-proxy
```

**Paso 3:** Verificar comunicacion

```bash
kubectl exec <pod-name> -c app-container -- curl localhost:15000/stats
```

---

## Parte 5: Escenarios Reales (10 minutos)

### Caso 1: "Intermittent Connection Failures"

**Sintomas:**
- Algunas requests funcionan, otras fallan
- No hay patron claro

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

**Causa comun:** Uno o mas pods estan en estado "Not Ready" pero no se quitaron de endpoints.

---

### Caso 2: "Service Works from Some Pods, Not Others"

**Sintomas:**
- Service funciona desde pod A
- Service NO funciona desde pod B

**Debugging:**
```bash
# 1. Verificar NetworkPolicies
kubectl get networkpolicies

# 2. Ver si hay politicas que afecten el trafico
kubectl describe networkpolicy <policy-name>

# 3. Probar desde pod con label diferente
kubectl run test-1 --rm -it --image=busybox --labels=role=frontend -- wget <service>
kubectl run test-2 --rm -it --image=busybox --labels=role=backend -- wget <service>
```

**Causa comun:** NetworkPolicy bloqueando trafico desde ciertos pods.

---

### Caso 3: "External Traffic Not Reaching Service"

**Sintomas:**
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
- [ ] Pods estan Running: `kubectl get pods -l <selector>`
- [ ] Labels coinciden: Comparar selector del Service vs labels de pods
- [ ] Puertos correctos: targetPort coincide con containerPort
- [ ] Pods responden directamente: `curl http://<pod-ip>:<port>`
- [ ] Firewall permite trafico (para NodePort/LoadBalancer)

### Para problemas de DNS:

- [ ] CoreDNS esta corriendo: `kubectl get pods -n kube-system -l k8s-app=kube-dns`
- [ ] Service kube-dns existe: `kubectl get svc -n kube-system kube-dns`
- [ ] /etc/resolv.conf correcto en pods
- [ ] Probar resolucion directa: `nslookup <service> <dns-ip>`
- [ ] Verificar logs de CoreDNS
- [ ] Verificar ConfigMap de CoreDNS

### Para problemas de conectividad:

- [ ] NetworkPolicies no bloquean: `kubectl get networkpolicies`
- [ ] CNI plugin funciona: `kubectl get pods -n kube-system -l <cni-label>`
- [ ] Routing entre nodos funciona
- [ ] iptables/IPVS rules correctas en nodos

---

## Herramientas Utiles

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
# y muchas mas...
```

---

## Limpieza

```bash
./cleanup.sh
```

---

## Verificacion Final

### Checklist de Conocimientos

- [ ] Puedo diagnosticar por que un Service no responde
- [ ] Se como verificar que selector y labels coinciden
- [ ] Puedo troubleshootear problemas de DNS
- [ ] Entiendo como usar tcpdump en pods
- [ ] Puedo crear ephemeral debug containers
- [ ] Se como verificar NetworkPolicies
- [ ] Puedo analizar iptables rules de kube-proxy
- [ ] Conozco las causas comunes de problemas de networking
- [ ] Tengo un proceso sistematico para debugging

---

## Recursos Adicionales

- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)
- [DNS Troubleshooting](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
- [Netshoot - Network Troubleshooting Tool](https://github.com/nicolaka/netshoot)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

---

**Felicitaciones!** Has completado todos los laboratorios del Modulo 02.

**Siguiente paso:** Revisa el resumen del modulo y preparate para el Modulo 03.
