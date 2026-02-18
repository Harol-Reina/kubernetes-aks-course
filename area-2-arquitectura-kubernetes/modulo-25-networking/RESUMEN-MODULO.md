# Resumen - Networking Deep Dive

Cheatsheet rápido para el examen CKA - Networking (20% del examen)

---

## Comandos Esenciales de Networking

### Verificación de Conectividad

```bash
# Obtener IPs de pods
kubectl get pods -o wide

# Ver detalles de red de un pod
kubectl describe pod <pod-name> | grep -A 5 IP

# Ejecutar ping entre pods
kubectl exec -it <pod-a> -- ping <ip-pod-b>

# Test de conectividad a service
kubectl exec -it <pod-name> -- curl <service-name>:<port>

# Port-forward para testing local
kubectl port-forward pod/<pod-name> 8080:8080
kubectl port-forward svc/<service-name> 8080:80
```

### DNS

```bash
# Test DNS lookup
kubectl exec -it <pod-name> -- nslookup kubernetes.default
kubectl exec -it <pod-name> -- nslookup <service-name>
kubectl exec -it <pod-name> -- nslookup google.com

# Ver resolv.conf del pod
kubectl exec -it <pod-name> -- cat /etc/resolv.conf

# Verificar CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Ver ConfigMap de CoreDNS
kubectl get configmap coredns -n kube-system -o yaml
kubectl edit configmap coredns -n kube-system
```

### Services

```bash
# Listar services
kubectl get svc
kubectl get svc -A

# Ver endpoints de un service
kubectl get endpoints <service-name>
kubectl describe endpoints <service-name>

# Crear service ClusterIP
kubectl expose deployment <deployment-name> --port=80 --target-port=8080

# Crear service NodePort
kubectl expose deployment <deployment-name> --type=NodePort --port=80

# Ver detalles del service
kubectl describe svc <service-name>

# Editar service
kubectl edit svc <service-name>

# Eliminar service
kubectl delete svc <service-name>
```

### Network Policies

```bash
# Listar network policies
kubectl get networkpolicies
kubectl get netpol

# Ver detalles
kubectl describe networkpolicy <policy-name>

# Aplicar network policy
kubectl apply -f network-policy.yaml

# Eliminar network policy
kubectl delete networkpolicy <policy-name>

# Ver logs de CNI (Calico example)
kubectl logs -n kube-system -l k8s-app=calico-node

# Test conectividad (debe fallar si bloqueado)
kubectl exec -it <pod-name> -- curl <service-name>
```

### Ingress

```bash
# Listar ingress
kubectl get ingress
kubectl get ing

# Ver detalles
kubectl describe ingress <ingress-name>

# Aplicar ingress
kubectl apply -f ingress.yaml

# Ver logs del ingress controller
kubectl logs -n ingress-nginx <controller-pod>

# Verificar ingress controller
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Test ingress desde fuera
curl -H "Host: myapp.com" http://<external-ip>/path
```

### CNI Troubleshooting

```bash
# Ver configuración de CNI
ls -la /etc/cni/net.d/
cat /etc/cni/net.d/10-calico.conflist

# Ver pods de CNI
kubectl get pods -n kube-system | grep -E 'calico|flannel|cilium|weave'

# Ver logs de CNI (Calico)
kubectl logs -n kube-system -l k8s-app=calico-node

# Ver interfaces en el nodo
ip addr show
ip route

# Ver interfaces en pod
kubectl exec -it <pod-name> -- ip addr
kubectl exec -it <pod-name> -- ip route
```

---

## Formatos DNS en Kubernetes

### Services

```bash
# Formato completo
<service-name>.<namespace>.svc.cluster.local

# Ejemplos
backend.default.svc.cluster.local
api.production.svc.cluster.local
database.kube-system.svc.cluster.local

# Desde mismo namespace (abreviado)
backend
backend.default
```

### Pods

```bash
# Formato (IP con guiones)
<ip-con-guiones>.<namespace>.pod.cluster.local

# Ejemplo: Pod con IP 10.244.1.5
10-244-1-5.default.pod.cluster.local
```

### Headless Services (StatefulSet)

```bash
# Formato
<pod-name>.<service-name>.<namespace>.svc.cluster.local

# Ejemplo: StatefulSet "web" con 3 replicas
web-0.nginx.default.svc.cluster.local
web-1.nginx.default.svc.cluster.local
web-2.nginx.default.svc.cluster.local
```

---

## Templates YAML Rápidos

### Service ClusterIP

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP  # Default
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

### Service NodePort

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nodeport
spec:
  type: NodePort
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
    nodePort: 30080  # 30000-32767
```

### Service LoadBalancer

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-lb
spec:
  type: LoadBalancer
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

### Headless Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-headless
spec:
  clusterIP: None  # Headless!
  selector:
    app: myapp
  ports:
  - port: 80
```

### Network Policy - Deny All Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### Network Policy - Allow Specific

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### Network Policy - Allow DNS

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

### Ingress Simple

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

### Ingress con TLS

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - secure.example.com
    secretName: tls-secret
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

### Ingress - Multiple Hosts

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
  - host: web.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

---

## Troubleshooting Decision Tree

### Pod no puede comunicarse con otro pod

```
1. ¿El pod tiene IP?
   kubectl get pod <pod> -o wide
   └─ NO → Problema con CNI
   └─ SÍ → Continuar

2. ¿Puedes hacer ping a la IP del otro pod?
   kubectl exec -it <pod-a> -- ping <ip-pod-b>
   └─ NO → Verificar CNI, rutas de red
   └─ SÍ → Continuar

3. ¿Hay Network Policies bloqueando?
   kubectl get networkpolicies
   kubectl describe networkpolicy <name>
   └─ SÍ → Ajustar Network Policy
   └─ NO → Verificar firewall del pod/aplicación
```

### Service no funciona

```
1. ¿El service existe?
   kubectl get svc <service-name>
   └─ NO → Crear service
   └─ SÍ → Continuar

2. ¿El service tiene endpoints?
   kubectl get endpoints <service-name>
   └─ NO → Verificar selector coincide con pod labels
   └─ SÍ → Continuar

3. ¿Los pods están Ready?
   kubectl get pods -l <selector>
   └─ NO → Revisar readinessProbe
   └─ SÍ → Continuar

4. ¿Puedes acceder al pod directamente?
   kubectl exec -it <test-pod> -- curl <pod-ip>:<port>
   └─ NO → Problema en el pod
   └─ SÍ → Problema en kube-proxy/iptables

5. ¿Puedes acceder al service?
   kubectl exec -it <test-pod> -- curl <service-name>:<port>
   └─ NO → Verificar kube-proxy
```

### DNS no funciona

```
1. ¿CoreDNS está corriendo?
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   └─ NO → Revisar deployment de CoreDNS
   └─ SÍ → Continuar

2. ¿Service kube-dns existe?
   kubectl get svc -n kube-system kube-dns
   └─ NO → Recrear service
   └─ SÍ → Continuar

3. ¿/etc/resolv.conf correcto?
   kubectl exec -it <pod> -- cat /etc/resolv.conf
   └─ NO → Problema con kubelet
   └─ SÍ → Continuar

4. ¿DNS interno funciona?
   kubectl exec -it <pod> -- nslookup kubernetes.default
   └─ NO → Ver logs de CoreDNS
   └─ SÍ → Continuar

5. ¿DNS externo funciona?
   kubectl exec -it <pod> -- nslookup google.com
   └─ NO → Problema con upstream DNS
```

### Ingress no funciona

```
1. ¿Ingress controller corriendo?
   kubectl get pods -n ingress-nginx
   └─ NO → Instalar ingress controller
   └─ SÍ → Continuar

2. ¿Ingress resource existe?
   kubectl get ingress <name>
   └─ NO → Crear ingress
   └─ SÍ → Continuar

3. ¿Backend service existe?
   kubectl get svc <backend-service>
   └─ NO → Crear service
   └─ SÍ → Continuar

4. ¿Service funciona directamente?
   kubectl port-forward svc/<service> 8080:80
   curl localhost:8080
   └─ NO → Arreglar service primero
   └─ SÍ → Continuar

5. ¿Ingress tiene ADDRESS asignada?
   kubectl get ingress
   └─ NO → Esperar o verificar ingress controller
   └─ SÍ → Probar acceso externo
```

---

## Network Policy Patterns

### Default Deny All

```yaml
# Deny all ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
# Deny all egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
```

### Allow All

```yaml
# Allow all ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - {}

---
# Allow all egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - {}
```

### Three-Tier Application

```yaml
# Frontend: acepta de ingress-nginx
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-frontend
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx

---
# Backend: acepta de frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-backend
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend

---
# Database: acepta de backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-database
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
```

---

## Comandos de Debugging Avanzados

### Pod de Debug con Herramientas

```bash
# Crear pod con netshoot (todas las herramientas)
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# O con dnsutils
kubectl run dnsutils --rm -it \
  --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 -- bash

# Dentro del pod:
ping <ip>
curl <url>
nslookup <hostname>
dig <hostname>
traceroute <ip>
nc -zv <host> <port>  # Test port
tcpdump -i any port 80
```

### Análisis de Tráfico

```bash
# Ver conntrack (conexiones activas)
kubectl exec -n kube-system <kube-proxy-pod> -- \
  conntrack -L | grep <ip>

# Ver reglas iptables de un service
kubectl exec -n kube-system <kube-proxy-pod> -- \
  iptables-save | grep <service-name>

# Capturar tráfico en pod
kubectl exec -it <pod-name> -- tcpdump -i any -n port 8080

# Capturar y guardar
kubectl exec -it <pod-name> -- tcpdump -i any -w /tmp/capture.pcap
kubectl cp <pod-name>:/tmp/capture.pcap ./capture.pcap
```

### Métricas de Red

```bash
# Ver uso de CPU/memoria de componentes de red
kubectl top pods -n kube-system

# Ver número de servicios
kubectl get svc --all-namespaces --no-headers | wc -l

# Ver número de endpoints
kubectl get endpoints --all-namespaces --no-headers | wc -l

# Test de latencia (iperf3)
# En pod server:
kubectl exec -it <pod-a> -- iperf3 -s

# En pod client:
kubectl exec -it <pod-b> -- iperf3 -c <ip-pod-a> -t 10
```

---

## Tips para el Examen CKA

### Configuración rápida de kubectl

```bash
# Alias útiles
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kge='kubectl get endpoints'
alias kgn='kubectl get networkpolicies'
alias kgi='kubectl get ingress'

# Autocompletado
source <(kubectl completion bash)
complete -F __start_kubectl k
```

### Comandos imperativos

```bash
# Crear service ClusterIP
kubectl expose deployment nginx --port=80 --name=nginx-service

# Crear service NodePort
kubectl expose deployment nginx --type=NodePort --port=80 --name=nginx-np

# Crear deployment y service en un comando
kubectl create deployment nginx --image=nginx --replicas=3
kubectl expose deployment nginx --port=80

# Run y expose
kubectl run web --image=nginx --port=80 --expose

# Obtener YAML de recurso existente
kubectl get svc nginx-service -o yaml > service.yaml
kubectl get ingress myapp -o yaml > ingress.yaml
```

### Verificaciones rápidas

```bash
# ¿Service tiene endpoints?
kubectl get endpoints <service-name> | grep -v "<none>"

# ¿Pods están Ready?
kubectl get pods | grep -v "1/1"

# ¿DNS funciona?
kubectl run test --rm -it --image=busybox -- nslookup kubernetes.default

# ¿Network policy aplicada?
kubectl get networkpolicies --all-namespaces

# ¿Ingress tiene IP?
kubectl get ingress | grep -v "<none>"
```

### Troubleshooting en 30 segundos

```bash
# Script de diagnóstico rápido
cat <<'EOF' > /tmp/net-check.sh
#!/bin/bash
echo "=== Pods ==="
kubectl get pods -o wide
echo "=== Services ==="
kubectl get svc
echo "=== Endpoints ==="
kubectl get endpoints
echo "=== Network Policies ==="
kubectl get networkpolicies
echo "=== Ingress ==="
kubectl get ingress
echo "=== CoreDNS ==="
kubectl get pods -n kube-system -l k8s-app=kube-dns
EOF
chmod +x /tmp/net-check.sh
/tmp/net-check.sh
```

---

## Errores Comunes y Soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| `dial tcp: lookup <service> on <ip>:53: no such host` | DNS no funciona | Verificar CoreDNS |
| `No endpoints available for service` | Selector incorrecto o pods no Ready | Verificar labels y readiness |
| `Connection refused` | Puerto incorrecto o pod no escucha | Verificar targetPort |
| `default backend - 404` | Ingress no encuentra backend | Verificar service name en ingress |
| `CrashLoopBackOff` en CNI pod | Configuración incorrecta | Ver logs CNI, verificar CIDR |
| Service ClusterIP no responde | kube-proxy issues | Verificar kube-proxy pods |
| Network policy bloquea todo | Deny-all sin allow rules | Añadir reglas de allow |

---

## Checklist Pre-Examen

Networking (20% del examen CKA):

- [ ] Entiendo los 4 tipos de Services y cuándo usar cada uno
- [ ] Sé crear Services con kubectl expose
- [ ] Entiendo formato DNS de services y pods
- [ ] Puedo troubleshoot problemas de DNS (CoreDNS)
- [ ] Sé verificar endpoints de un service
- [ ] Entiendo Network Policies (ingress/egress)
- [ ] Puedo crear Network Policies para escenarios comunes
- [ ] Sé troubleshoot conectividad entre pods
- [ ] Entiendo Ingress y puedo crear reglas básicas
- [ ] Puedo diagnosticar por qué un pod no puede acceder a otro
- [ ] Sé usar kubectl exec para debugging de red
- [ ] Entiendo la diferencia entre ClusterIP y Headless
- [ ] Puedo identificar problemas de CNI
- [ ] Sé verificar logs de componentes de red

---

## Recursos Rápidos

### Documentación Oficial

```bash
# Buscar en docs durante examen (permitido)
https://kubernetes.io/docs/concepts/services-networking/
https://kubernetes.io/docs/concepts/services-networking/network-policies/
https://kubernetes.io/docs/concepts/services-networking/ingress/
```

### Comandos de emergencia

```bash
# CoreDNS no funciona
kubectl rollout restart deployment coredns -n kube-system

# Ingress controller no funciona
kubectl rollout restart deployment -n ingress-nginx

# Ver todos los componentes de red
kubectl get all -n kube-system
kubectl get all -n ingress-nginx

# Recrear pod problemático
kubectl delete pod <pod-name>

# Force update service
kubectl replace --force -f service.yaml
```

---

**Última actualización**: Noviembre 2025  
**Examen**: CKA - Networking representa ~20% del examen  
**Tiempo recomendado**: Dominar en 6-8 horas de práctica
