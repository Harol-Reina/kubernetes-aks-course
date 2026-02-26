# Laboratorio 02: NodePort y LoadBalancer - Acceso Externo

**Duracion estimada:** 50 minutos
**Nivel:** Intermedio
**Objetivo:** Dominar acceso externo con NodePort y LoadBalancer, comparar tipos de Services

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **NodePort Service** | Expone el Service en un puerto estatico (30000-32767) en TODOS los nodos del cluster. Accesible via `<node-ip>:<nodePort>`. Ideal para desarrollo y testing |
| **NodePort auto-asignado** | Kubernetes elige un puerto libre del rango automaticamente. Evita conflictos entre Services |
| **NodePort personalizado** | Se especifica un puerto fijo (`nodePort: 30080`). Util cuando firewalls o DNS necesitan un puerto predecible |
| **LoadBalancer Service** | Provisiona automaticamente un balanceador externo en cloud (AWS ELB, Azure LB, GCP LB). Asigna IP publica. Cada Service = 1 LB |
| **externalTrafficPolicy: Cluster** | Politica por defecto. Balancea a TODOS los Pods del cluster. Pierde IP origen del cliente (SNAT). Distribucion uniforme |
| **externalTrafficPolicy: Local** | Solo envia trafico a Pods en el MISMO nodo. Preserva IP origen del cliente. Puede causar balanceo desigual |
| **healthCheckNodePort** | Puerto especial creado automaticamente con policy Local para que LBs externos detecten nodos sin Pods |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `webapp-deployment.yaml` | 1 | Deployment con 3 replicas que muestra Pod name, IP y Node |
| `webapp-nodeport-auto.yaml` | 1 | NodePort con puerto auto-asignado por Kubernetes |
| `webapp-nodeport-custom.yaml` | 2 | NodePort con puerto fijo 30080 |
| `webapp-cluster-policy.yaml` | 3 | NodePort con externalTrafficPolicy: Cluster |
| `webapp-local-policy.yaml` | 3 | NodePort con externalTrafficPolicy: Local |
| `webapp-loadbalancer.yaml` | 4 | LoadBalancer para cloud (AWS/GCP/Azure) |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `compare-policies.sh` | Compara externalTrafficPolicy Cluster vs Local |
| `comparison-table.sh` | Tabla comparativa de los 4 tipos de Service |
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## 🔧 Requisitos Previos

- Laboratorio 01 completado
- Cluster de Kubernetes con acceso a nodos
- (Opcional) Cluster en cloud (AWS EKS, GCP GKE, Azure AKS) para LoadBalancer
- kubectl configurado

### Verificacion del entorno

```bash
# Verificar acceso a nodos
kubectl get nodes -o wide

# Anotar EXTERNAL-IP de los nodos (usaremos esto mas tarde)
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'
echo

# Si no hay EXTERNAL-IP, usar INTERNAL-IP
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
echo

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Parte 1: Service NodePort Basico

### Paso 1: Revisar y aplicar el Deployment

Revisa el archivo `webapp-deployment.yaml`:

```bash
cat webapp-deployment.yaml
```

Puntos clave del manifiesto:
- **3 replicas** de nginx:alpine con info de Pod + Node
- **Downward API**: inyecta `POD_NAME`, `POD_IP` y `NODE_NAME`
- **Resource requests/limits**: best practice para produccion
- **Named port http**: referencia semantica para Services

```bash
kubectl apply -f webapp-deployment.yaml

# Verificar Pods en diferentes nodos
kubectl get pods -l app=webapp -o wide
```

---

### Paso 2: Crear NodePort con puerto auto-asignado

Revisa el archivo `webapp-nodeport-auto.yaml`:

```bash
cat webapp-nodeport-auto.yaml
```

Puntos clave:
- **type: NodePort**: expone en todos los nodos
- **Sin nodePort especificado**: Kubernetes asigna automaticamente del rango 30000-32767

```bash
kubectl apply -f webapp-nodeport-auto.yaml

# Ver Service
kubectl get service webapp-nodeport-auto

# Obtener NodePort asignado
NODEPORT=$(kubectl get service webapp-nodeport-auto -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort asignado: $NODEPORT"
```

**Salida esperada:**
```
NAME                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
webapp-nodeport-auto    NodePort   10.96.123.45    <none>        80:31234/TCP   10s

NodePort asignado: 31234
```

**Observa:**
- `PORT(S)`: `80:31234/TCP` → puerto 80 del Service mapeado a puerto 31234 del nodo
- `EXTERNAL-IP`: `<none>` → NodePort no crea IP externa (usa IP del nodo)

---

### Paso 3: Acceder via NodePort

```bash
# Obtener IP de un nodo
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Node IP: $NODE_IP"
echo "Accede en: http://$NODE_IP:$NODEPORT"

# Test desde un Pod
kubectl run test-nodeport --rm -it --image=curlimages/curl --restart=Never -- \
  curl http://$NODE_IP:$NODEPORT

# Multiples requests para ver balanceo
for i in {1..5}; do
  echo "Request $i:"
  kubectl run test-np-$i --rm --image=curlimages/curl --restart=Never -- \
    curl -s http://$NODE_IP:$NODEPORT | grep -E "Pod:|Node:" &
done
wait
```

**Observa:**
- Puedes acceder usando IP de CUALQUIER nodo (incluso si el Pod no esta en ese nodo)
- Balanceo funciona igual que ClusterIP

---

### Paso 4: NodePort con puerto personalizado

Revisa el archivo `webapp-nodeport-custom.yaml`:

```bash
cat webapp-nodeport-custom.yaml
```

Punto clave: `nodePort: 30080` — puerto fijo y predecible.

```bash
kubectl apply -f webapp-nodeport-custom.yaml

# Verificar
kubectl get service webapp-nodeport-custom
```

**Salida:**
```
NAME                      TYPE       CLUSTER-IP      PORT(S)        AGE
webapp-nodeport-custom    NodePort   10.96.234.56    80:30080/TCP   5s
```

**Ventaja:** Puerto conocido y predecible (`30080`)
**Desventaja:** Puede conflictuar si ya esta en uso

---

## Parte 2: ExternalTrafficPolicy

### Paso 5: Cluster Policy (Default)

Revisa el archivo `webapp-cluster-policy.yaml`:

```bash
cat webapp-cluster-policy.yaml
```

Punto clave: `externalTrafficPolicy: Cluster` — balancea a TODOS los Pods.

```bash
kubectl apply -f webapp-cluster-policy.yaml
```

**Test:**
```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Ver si preserva IP origen
kubectl run test-cluster --rm -it --image=curlimages/curl --restart=Never -- \
  curl -s http://$NODE_IP:30081 | grep -E "Pod:|Node:"
```

**Cluster Policy:**
- Balancea a TODOS los Pods (incluso en otros nodos)
- Pierde IP origen del cliente (SNAT)
- Funciona siempre (incluso si nodo no tiene Pods)

---

### Paso 6: Local Policy

Revisa el archivo `webapp-local-policy.yaml`:

```bash
cat webapp-local-policy.yaml
```

Punto clave: `externalTrafficPolicy: Local` — solo Pods locales, preserva IP origen.

```bash
kubectl apply -f webapp-local-policy.yaml

# Verificar health check port (solo con Local)
kubectl get service webapp-local-policy -o yaml | grep healthCheckNodePort
```

**Test desde DIFERENTES nodos:**
```bash
# Listar nodos con Pods
echo "Pods distribution:"
kubectl get pods -l app=webapp -o wide

# Guardar IPs de nodos
NODES=($(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'))

# Test en cada nodo
for NODE in "${NODES[@]}"; do
  echo "Testing node: $NODE"
  kubectl run test-node-$RANDOM --rm --image=curlimages/curl --restart=Never -- \
    curl -s -m 2 http://$NODE:30082 2>&1 | head -n 3 &
done
wait
```

**Local Policy:**
- Preserva IP origen del cliente
- Sin hop extra (siempre local)
- Solo balancea a Pods en el MISMO nodo
- Si nodo no tiene Pods, conexion falla

---

### Paso 7: Comparar ambas policies

```bash
# Ejecutar script de comparacion
chmod +x compare-policies.sh
./compare-policies.sh
```

---

## Parte 3: LoadBalancer Service (Cloud)

**Esta seccion requiere cluster en cloud (AWS, GCP, Azure).
Si usas minikube/kind, salta a Parte 4.**

### Paso 8: Crear LoadBalancer Service

Revisa el archivo `webapp-loadbalancer.yaml`:

```bash
cat webapp-loadbalancer.yaml
```

Puntos clave:
- **type: LoadBalancer**: provisiona LB externo automaticamente
- **externalTrafficPolicy: Local**: preserva IP del cliente
- **loadBalancerSourceRanges**: (comentado) para restringir acceso por IP

```bash
kubectl apply -f webapp-loadbalancer.yaml

# Ver Service (EXTERNAL-IP en <pending> inicialmente)
kubectl get service webapp-lb -w
```

**Salida esperada:**
```
NAME        TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
webapp-lb   LoadBalancer   10.96.45.67    <pending>       80:31456/TCP   10s
webapp-lb   LoadBalancer   10.96.45.67    203.0.113.50    80:31456/TCP   90s
                                          ^ IP publica asignada
```

**Observa:**
- Toma ~1-3 minutos en asignar IP publica
- Cloud provider crea balanceador automaticamente
- Tambien crea NodePort (31456) automaticamente

---

### Paso 9: Acceder via LoadBalancer

```bash
# Obtener IP publica
LB_IP=$(kubectl get service webapp-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "LoadBalancer IP: $LB_IP"

# Test desde tu laptop
curl http://$LB_IP

# Multiples requests
for i in {1..10}; do
  curl -s http://$LB_IP | grep "Pod:"
done
```

**Acceso publico:** Cualquiera en Internet puede acceder (si firewall lo permite).

---

### Paso 10: Ver LoadBalancer en Cloud Console

**AWS:**
```bash
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(LoadBalancerName, 'webapp')]"
```

**GCP:**
```bash
gcloud compute forwarding-rules list
```

**Azure:**
```bash
az network lb list --output table
```

---

## Parte 4: Comparacion de Tipos de Service

### Paso 11: Comparar los 3 tipos simultaneamente

```bash
# Ejecutar tabla comparativa
chmod +x comparison-table.sh
./comparison-table.sh
```

**Salida esperada:**
```
==========================================
Service Types Comparison
==========================================
TIPO                 ALCANCE         PUERTO               USO TIPICO
==================================================================================
ClusterIP            Interno         Cluster IP           Backend, DBs internas
NodePort             Externo         30000-32767          Testing, desarrollo
LoadBalancer         Externo         Asignado por Cloud   Apps publicas, produccion
ExternalName         Externo         DNS CNAME            Migracion, servicios externos
```

---

## Parte 5: Troubleshooting

### Paso 12: Problema - NodePort No Accesible

```bash
# Verificar NodePort asignado
kubectl get service webapp-nodeport-auto

# Verificar Pods running
kubectl get pods -l app=webapp

# Verificar Endpoints
kubectl get endpoints webapp-nodeport-auto

# Test conectividad desde dentro del cluster
kubectl run test-internal --rm -it --image=curlimages/curl --restart=Never -- \
  curl http://webapp-nodeport-auto
```

**Checklist de diagnostico:**
- [ ] Service existe y tiene tipo NodePort
- [ ] Endpoints no vacios (hay Pods ready)
- [ ] Firewall permite puerto NodePort (30000-32767)
- [ ] kube-proxy running en nodos

---

### Paso 13: Problema - LoadBalancer en \<pending\>

```bash
# Ver si esta stuck en pending
kubectl get service webapp-lb

# Ver eventos
kubectl describe service webapp-lb | grep -A 10 Events

# Posibles causas:
# 1. Cloud provider no configurado
kubectl get nodes -o yaml | grep providerID

# 2. Quotas excedidas (verificar en consola del cloud)
# 3. Permisos IAM insuficientes
# 4. No es cluster de cloud (minikube, kind) → Usar NodePort o MetalLB
```

---

## Desafios Adicionales

### Desafio 1: Multi-Port NodePort

Crea un NodePort Service con puertos HTTP (80) y HTTPS (443).

<details>
<summary>Solucion</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-multi-port
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30080
  - name: https
    port: 443
    targetPort: 443
    nodePort: 30443
```
</details>

---

### Desafio 2: LoadBalancer Interno (Cloud)

Crea un LoadBalancer que solo sea accesible dentro de la VPC (no publico).

<details>
<summary>Pista</summary>

Usa annotations especificas del cloud provider.
</details>

<details>
<summary>Solucion AWS</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-internal-lb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 80
```
</details>

---

## Limpieza

```bash
# Usar el script de limpieza
chmod +x cleanup.sh
./cleanup.sh
```

---

## Resumen y Conceptos Clave

### NodePort

**Caracteristicas:**
- Expone puerto en TODOS los nodos (range 30000-32767)
- Accesible via `<node-ip>:<nodePort>`
- Crea ClusterIP tambien (acceso interno)

**Cuando usar:**
- Desarrollo/testing
- Bare-metal clusters sin LoadBalancer
- Detras de LB externo (HAProxy, nginx)

**NO usar para:**
- Produccion publica directa
- Multiples servicios (range limitado)

---

### LoadBalancer

**Caracteristicas:**
- Crea balanceador externo automaticamente
- IP publica asignada
- Integracion con cloud provider

**Cuando usar:**
- Produccion en cloud (AWS, GCP, Azure)
- Necesitas IP publica estable

**NO usar para:**
- Multiples servicios HTTP (costoso, usar Ingress)
- Desarrollo local (sin cloud provider)

---

### externalTrafficPolicy

**Cluster (default):**
- Balancea a TODOS los Pods
- Pierde IP origen (SNAT)
- Hop extra posible

**Local:**
- Solo Pods locales (mismo nodo)
- Preserva IP origen
- Balanceo desigual

---

## Siguientes Pasos

1. **[Laboratorio 03: Services Avanzados](../lab-03-advanced-services/)**
   - ExternalName
   - Headless Services
   - Endpoints manuales
   - Best practices de produccion

2. **[Ejemplos Avanzados](../../ejemplos/README.md)**
   - LoadBalancer con annotations
   - ExternalTrafficPolicy en detalle

---

## Checklist de Verificacion

- [ ] Puedes crear NodePort Services
- [ ] Entiendes el range de puertos (30000-32767)
- [ ] Sabes la diferencia entre Cluster y Local policy
- [ ] (Opcional) Creaste LoadBalancer en cloud
- [ ] Puedes diagnosticar problemas de acceso externo
- [ ] Sabes cuando usar cada tipo de Service

---

**Excelente trabajo!** Dominas acceso externo en Kubernetes.
