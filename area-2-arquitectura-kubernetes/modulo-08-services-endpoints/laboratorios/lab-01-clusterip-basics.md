# Laboratorio 01: ClusterIP Básico - Fundamentos de Services

**Duración estimada:** 40 minutos  
**Nivel:** Básico  
**Objetivo:** Comprender Services tipo ClusterIP, descubrimiento por DNS, y Endpoints

---

## 📋 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

- ✅ Crear Services tipo ClusterIP
- ✅ Entender cómo funcionan los Endpoints automáticos
- ✅ Usar descubrimiento por DNS para conectar Pods
- ✅ Verificar balanceo de carga automático
- ✅ Diagnosticar problemas básicos de Services

---

## 🔧 Requisitos Previos

- Cluster de Kubernetes funcional (minikube, kind, k3s, o cloud)
- kubectl configurado
- Conocimientos básicos de Pods y Deployments (módulos anteriores)

### Verificación del entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar que puedes crear recursos
kubectl auth can-i create services
```

---

## 📚 Parte 1: Crear tu Primer Service ClusterIP

### Paso 1: Crear un Deployment

Primero necesitamos Pods para exponer vía Service.

```bash
# Crear archivo backend-deployment.yaml
cat > backend-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  labels:
    app: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
      tier: api
  template:
    metadata:
      labels:
        app: backend
        tier: api
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - name: http
          containerPort: 80
        
        # Configurar para identificar cada Pod
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        
        # Script para mostrar info del Pod
        command:
        - /bin/sh
        - -c
        - |
          echo "<h1>Backend API</h1>" > /usr/share/nginx/html/index.html
          echo "<p>Pod: $POD_NAME</p>" >> /usr/share/nginx/html/index.html
          echo "<p>IP: $POD_IP</p>" >> /usr/share/nginx/html/index.html
          exec nginx -g 'daemon off;'
EOF

# Aplicar
kubectl apply -f backend-deployment.yaml

# Verificar Pods creados
kubectl get pods -l app=backend -o wide
```

**Salida esperada:**
```
NAME                                  READY   STATUS    IP           NODE
backend-deployment-abc123             1/1     Running   10.1.2.3     node1
backend-deployment-def456             1/1     Running   10.1.2.4     node2
backend-deployment-ghi789             1/1     Running   10.1.2.5     node3
```

**🎯 Observa:** Cada Pod tiene IP diferente y puede estar en nodo diferente.

---

### Paso 2: Crear el Service ClusterIP

```bash
# Crear archivo backend-service.yaml
cat > backend-service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  labels:
    app: backend
spec:
  type: ClusterIP  # Puede omitirse (es el default)
  selector:
    app: backend
    tier: api
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: http
EOF

# Aplicar
kubectl apply -f backend-service.yaml

# Verificar Service creado
kubectl get service backend-service
```

**Salida esperada:**
```
NAME              TYPE        CLUSTER-IP     PORT(S)   AGE
backend-service   ClusterIP   10.96.15.123   80/TCP    5s
```

**🎯 Observa:** Se asignó una ClusterIP automáticamente (en este caso `10.96.15.123`).

---

### Paso 3: Inspeccionar el Service

```bash
# Ver detalles completos
kubectl describe service backend-service

# Ver solo la ClusterIP
kubectl get service backend-service -o jsonpath='{.spec.clusterIP}'
echo

# Ver el selector
kubectl get service backend-service -o jsonpath='{.spec.selector}'
echo
```

**Salida de `describe`:**
```
Name:              backend-service
Type:              ClusterIP
IP Family Policy:  SingleStack
IP:                10.96.15.123
Port:              http  80/TCP
TargetPort:        http/TCP
Endpoints:         10.1.2.3:80,10.1.2.4:80,10.1.2.5:80
Session Affinity:  None
```

**🎯 Observa:**
- ClusterIP: `10.96.15.123`
- Endpoints: Las 3 IPs de los Pods
- Coincide con las IPs que vimos en `kubectl get pods`

---

## 📚 Parte 2: Entender Endpoints

### Paso 4: Explorar Endpoints

Los Endpoints conectan el Service con los Pods.

```bash
# Ver Endpoints del Service
kubectl get endpoints backend-service

# Detalles completos
kubectl describe endpoints backend-service

# Ver en formato YAML
kubectl get endpoints backend-service -o yaml
```

**Salida esperada:**
```
NAME              ENDPOINTS                                   AGE
backend-service   10.1.2.3:80,10.1.2.4:80,10.1.2.5:80         2m
```

**🎯 Clave:** Los Endpoints se crearon AUTOMÁTICAMENTE porque:
1. Service tiene `selector: app=backend, tier=api`
2. Hay 3 Pods con esas labels
3. Kubernetes crea Endpoint por cada Pod que coincide

---

### Paso 5: Experimentar con Endpoints Dinámicos

Vamos a escalar el Deployment y ver cómo los Endpoints se actualizan automáticamente.

```bash
# Escalar a 5 réplicas
kubectl scale deployment backend-deployment --replicas=5

# Ver Pods (ahora 5)
kubectl get pods -l app=backend

# Ver Endpoints (ahora 5 IPs)
kubectl get endpoints backend-service

# Escalar a 1 réplica
kubectl scale deployment backend-deployment --replicas=1

# Ver Endpoints (ahora 1 IP)
kubectl get endpoints backend-service

# Volver a 3 réplicas
kubectl scale deployment backend-deployment --replicas=3
```

**🎯 Observa:** Los Endpoints se actualizan AUTOMÁTICAMENTE conforme Pods se crean/eliminan.

---

## 📚 Parte 3: Descubrimiento por DNS

### Paso 6: Probar DNS desde otro Pod

Kubernetes crea automáticamente registros DNS para los Services.

```bash
# Crear Pod de prueba
kubectl run test-dns --rm -it --image=busybox --restart=Never -- sh

# Dentro del Pod, ejecutar:
```

```sh
# Resolver DNS del Service (nombre corto)
nslookup backend-service

# FQDN completo
nslookup backend-service.default.svc.cluster.local

# Test HTTP
wget -O- http://backend-service

# Ver múltiples requests (balanceo)
for i in 1 2 3 4 5; do
  echo "Request $i:"
  wget -qO- http://backend-service | grep "Pod:"
  echo ""
  sleep 1
done

# Salir
exit
```

**Salida esperada de `nslookup`:**
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      backend-service
Address 1: 10.96.15.123 backend-service.default.svc.cluster.local
```

**Salida esperada del `for` loop:**
```
Request 1:
<p>Pod: backend-deployment-abc123</p>

Request 2:
<p>Pod: backend-deployment-def456</p>

Request 3:
<p>Pod: backend-deployment-ghi789</p>
...
```

**🎯 Observa:**
- DNS resuelve a la ClusterIP (`10.96.15.123`)
- Cada request puede ir a diferente Pod (balanceo automático)

---

### Paso 7: Probar desde otro Namespace

El DNS funciona cross-namespace usando FQDN.

```bash
# Crear namespace de testing
kubectl create namespace testing

# Crear Pod en el nuevo namespace
kubectl run test-cross-ns --rm -it --image=busybox --restart=Never \
  -n testing -- sh
```

```sh
# Desde el Pod en namespace "testing":

# Nombre corto NO funciona (diferente namespace)
nslookup backend-service
# → Error: server can't find backend-service

# Con namespace funciona
nslookup backend-service.default

# FQDN completo siempre funciona
nslookup backend-service.default.svc.cluster.local

# Test HTTP cross-namespace
wget -O- http://backend-service.default

exit
```

**🎯 Clave:** Formato DNS completo:
```
<service-name>.<namespace>.svc.cluster.local
```

---

## 📚 Parte 4: Balanceo de Carga

### Paso 8: Verificar Balanceo Automático

```bash
# Script para ver balanceo en acción
cat > test-loadbalancing.sh <<'EOF'
#!/bin/bash
echo "Testing load balancing (20 requests):"
for i in {1..20}; do
  kubectl run test-lb-$i --rm --image=curlimages/curl --restart=Never -- \
    curl -s http://backend-service | grep "Pod:" &
done
wait
echo -e "\nCounting requests per Pod:"
kubectl logs -l job-name --tail=-1 2>/dev/null | grep "Pod:" | sort | uniq -c
EOF

chmod +x test-loadbalancing.sh
./test-loadbalancing.sh
```

**Salida esperada:**
```
Testing load balancing (20 requests):
<p>Pod: backend-deployment-abc123</p>
<p>Pod: backend-deployment-def456</p>
<p>Pod: backend-deployment-ghi789</p>
...

Counting requests per Pod:
  7 <p>Pod: backend-deployment-abc123</p>
  6 <p>Pod: backend-deployment-def456</p>
  7 <p>Pod: backend-deployment-ghi789</p>
```

**🎯 Observa:** Distribución aproximadamente uniforme (puede variar ligeramente).

---

## 📚 Parte 5: Port-Forward para Testing Local

### Paso 9: Acceder al Service desde tu Laptop

```bash
# Port-forward del Service
kubectl port-forward service/backend-service 8080:80

# En OTRA terminal:
curl http://localhost:8080

# Ver respuesta HTML
curl http://localhost:8080 | grep -E "Pod:|IP:"

# Hacer múltiples requests
for i in {1..10}; do
  curl -s http://localhost:8080 | grep "Pod:"
done

# Ctrl+C en la terminal del port-forward para detener
```

**🎯 Útil para:** Debugging, desarrollo local, testing rápido.

---

## 📚 Parte 6: Troubleshooting Básico

### Paso 10: Simular Problema - Pod Sin Label

Vamos a crear un Pod que NO tiene las labels correctas.

```bash
# Pod sin la label "tier: api"
kubectl run backend-wrong-label --image=nginx:alpine \
  --labels=app=backend

# Ver Pods (ahora hay 4)
kubectl get pods -l app=backend

# Ver Endpoints (¡sigue siendo 3!)
kubectl get endpoints backend-service

# ¿Por qué? Ver labels del Pod problemático
kubectl get pod backend-wrong-label --show-labels
```

**🎯 Observa:**
- Pod tiene `app=backend` pero NO `tier=api`
- Service selector requiere AMBAS labels: `app=backend` Y `tier=api`
- Por eso NO aparece en Endpoints

**Solución:**
```bash
# Agregar la label faltante
kubectl label pod backend-wrong-label tier=api

# Ahora sí aparece en Endpoints
kubectl get endpoints backend-service

# Cleanup
kubectl delete pod backend-wrong-label
```

---

### Paso 11: Simular Problema - Pod Not Ready

```bash
# Crear Pod con readiness probe que falla
cat > pod-not-ready.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: backend-not-ready
  labels:
    app: backend
    tier: api
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    readinessProbe:
      httpGet:
        path: /nonexistent  # ← Path que NO existe
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
EOF

kubectl apply -f pod-not-ready.yaml

# Ver estado del Pod (READY será 0/1)
kubectl get pod backend-not-ready

# Ver Endpoints (NO incluye este Pod)
kubectl get endpoints backend-service -o yaml

# Ver por qué no está ready
kubectl describe pod backend-not-ready | grep -A 10 Conditions
```

**Salida:**
```
NAME                 READY   STATUS    RESTARTS   AGE
backend-not-ready    0/1     Running   0          30s
```

**🎯 Clave:**
- Pod está `Running` pero NOT `Ready` (0/1)
- **NO aparece en Endpoints** porque readiness probe falla
- kube-proxy NO envía tráfico a Pods not ready

**Cleanup:**
```bash
kubectl delete pod backend-not-ready
```

---

## 📚 Parte 7: Variables de Entorno (Legacy)

### Paso 12: Ver Variables de Entorno

Kubernetes inyecta variables de entorno para Services (método legacy).

```bash
# Crear Pod DESPUÉS del Service
kubectl run env-test --rm -it --image=busybox --restart=Never -- sh
```

```sh
# Ver variables del backend-service
env | grep BACKEND_SERVICE

# Deberías ver:
# BACKEND_SERVICE_SERVICE_HOST=10.96.15.123
# BACKEND_SERVICE_SERVICE_PORT=80
# BACKEND_SERVICE_PORT=tcp://10.96.15.123:80
# ...

exit
```

**🎯 Nota:** DNS es el método RECOMENDADO. Variables de entorno solo para compatibilidad legacy.

---

## 🎓 Desafíos Adicionales

### Desafío 1: Service con Múltiples Puertos

Modifica el Service para exponer puerto 8080 además de 80.

<details>
<summary>💡 Pista</summary>

Usa la sección `ports` con múltiples entradas, cada una con `name` único.
</details>

<details>
<summary>✅ Solución</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service-multi
spec:
  selector:
    app: backend
    tier: api
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: http-alt
    port: 8080
    targetPort: 80
```
</details>

---

### Desafío 2: Session Affinity

Configura el Service para que el mismo cliente siempre vaya al mismo Pod.

<details>
<summary>💡 Pista</summary>

Usa `sessionAffinity: ClientIP` en el spec del Service.
</details>

<details>
<summary>✅ Solución</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service-sticky
spec:
  selector:
    app: backend
    tier: api
  ports:
  - port: 80
    targetPort: 80
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
```

Test:
```bash
# Múltiples requests desde el mismo Pod deben ir al mismo backend
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- sh
# for i in {1..10}; do curl http://backend-service-sticky | grep Pod; done
# Debería ver siempre el MISMO Pod
```
</details>

---

## 🧹 Limpieza

```bash
# Eliminar recursos creados
kubectl delete deployment backend-deployment
kubectl delete service backend-service
kubectl delete namespace testing

# Eliminar archivos
rm -f backend-deployment.yaml backend-service.yaml test-loadbalancing.sh pod-not-ready.yaml
```

---

## 📝 Resumen y Conceptos Clave

### Aprendiste:

✅ **Service ClusterIP:**
- IP interna estable para acceder a Pods efímeros
- Solo accesible dentro del cluster
- Tipo por defecto (`type: ClusterIP`)

✅ **Endpoints:**
- Se crean AUTOMÁTICAMENTE
- Rastrea Pods con labels que coinciden con `selector`
- Se actualizan dinámicamente (scale up/down)
- Solo incluye Pods `Ready`

✅ **DNS Discovery:**
- Mismo namespace: `<service-name>`
- Otro namespace: `<service-name>.<namespace>`
- FQDN completo: `<service-name>.<namespace>.svc.cluster.local`
- **Recomendado sobre variables de entorno**

✅ **Balanceo de Carga:**
- Automático entre todos los Endpoints
- kube-proxy maneja reglas de iptables/IPVS
- Distribución aproximadamente uniforme

✅ **Troubleshooting:**
- Verificar labels coinciden con selector
- Verificar Pods están `Ready`
- Verificar Endpoints creados correctamente

---

## 🔗 Siguientes Pasos

Ahora que dominas ClusterIP, continúa con:

1. **[Laboratorio 02: NodePort y LoadBalancer](lab-02-nodeport-loadbalancer.md)**
   - Acceso externo con NodePort
   - LoadBalancer en cloud
   - ExternalTrafficPolicy

2. **[Ejemplos de Services](../ejemplos/README.md)**
   - Revisar ejemplos avanzados
   - Session affinity
   - Múltiples puertos

3. **[README del Módulo](../README.md)**
   - Teoría completa de Services
   - kube-proxy en detalle
   - Mejores prácticas

---

## ✅ Checklist de Verificación

Antes de continuar, asegúrate de:

- [ ] Puedes crear un Service ClusterIP
- [ ] Entiendes cómo funcionan los Endpoints
- [ ] Sabes usar DNS para descubrir Services
- [ ] Puedes verificar balanceo de carga
- [ ] Sabes diagnosticar Pods not ready
- [ ] Entiendes diferencia entre DNS y variables de entorno

---

**¡Felicidades!** Has completado el Laboratorio 01. 🎉

Tienes las bases sólidas para trabajar con Services en Kubernetes.
