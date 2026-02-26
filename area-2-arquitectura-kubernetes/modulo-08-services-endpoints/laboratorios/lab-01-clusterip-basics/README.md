# Laboratorio 01: ClusterIP Basico - Fundamentos de Services

**Duracion estimada:** 40 minutos
**Nivel:** Basico
**Objetivo:** Comprender Services tipo ClusterIP, descubrimiento por DNS, y Endpoints

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **ClusterIP Service** | Tipo de Service por defecto. Asigna una IP virtual interna estable para acceder a un grupo de Pods. Solo accesible dentro del cluster |
| **Endpoints automaticos** | Kubernetes crea y mantiene automaticamente la lista de IPs de Pods que coinciden con el selector del Service. Se actualizan al escalar |
| **DNS Discovery** | CoreDNS crea registros automaticos para cada Service: `<service>.<namespace>.svc.cluster.local`. Metodo recomendado sobre variables de entorno |
| **Balanceo de carga** | kube-proxy distribuye el trafico entre todos los Endpoints del Service usando iptables/IPVS. Distribucion aproximadamente uniforme |
| **Downward API** | Mecanismo para inyectar metadata del Pod (nombre, IP, nodo) como variables de entorno usando `fieldRef` |
| **readinessProbe** | Health check que determina si un Pod esta listo para recibir trafico. Pods not-ready se excluyen de los Endpoints |
| **Port-Forward** | Herramienta de kubectl para acceder a Services/Pods desde la maquina local, util para debugging |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `backend-deployment.yaml` | 1 | Deployment con 3 replicas nginx:alpine que muestra info del Pod |
| `backend-service.yaml` | 2 | Service ClusterIP que expone el backend con selector app+tier |
| `pod-not-ready.yaml` | 6 | Pod con readinessProbe fallida para demostrar exclusion de Endpoints |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `test-loadbalancing.sh` | Script para verificar distribucion de trafico entre Pods |
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## 🔧 Requisitos Previos

- Cluster de Kubernetes funcional (minikube, kind, k3s, o cloud)
- kubectl configurado
- Conocimientos basicos de Pods y Deployments (modulos anteriores)

### Verificacion del entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar que puedes crear recursos
kubectl auth can-i create services

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Parte 1: Crear tu Primer Service ClusterIP

### Paso 1: Revisar y aplicar el Deployment

Revisa el archivo `backend-deployment.yaml` antes de aplicarlo:

```bash
cat backend-deployment.yaml
```

Puntos clave del manifiesto:
- **3 replicas** de nginx:alpine
- **Labels duales**: `app: backend` y `tier: api` (el Service necesita ambas)
- **Named port**: `http` en el container (permite referencia semantica)
- **Downward API**: inyecta `POD_NAME` y `POD_IP` como variables de entorno
- **Script de inicio**: genera HTML con info del Pod para verificar balanceo

```bash
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

**Observa:** Cada Pod tiene IP diferente y puede estar en nodo diferente.

---

### Paso 2: Revisar y crear el Service ClusterIP

Revisa el archivo `backend-service.yaml`:

```bash
cat backend-service.yaml
```

Puntos clave del manifiesto:
- **type: ClusterIP**: tipo por defecto (puede omitirse)
- **selector**: requiere AMBAS labels `app: backend` Y `tier: api`
- **targetPort: http**: referencia al named port del container

```bash
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

**Observa:** Se asigno una ClusterIP automaticamente (en este caso `10.96.15.123`).

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

**Observa:**
- ClusterIP: `10.96.15.123`
- Endpoints: Las 3 IPs de los Pods
- Coincide con las IPs que vimos en `kubectl get pods`

---

## Parte 2: Entender Endpoints

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

**Clave:** Los Endpoints se crearon AUTOMATICAMENTE porque:
1. Service tiene `selector: app=backend, tier=api`
2. Hay 3 Pods con esas labels
3. Kubernetes crea Endpoint por cada Pod que coincide

---

### Paso 5: Experimentar con Endpoints Dinamicos

Vamos a escalar el Deployment y ver como los Endpoints se actualizan automaticamente.

```bash
# Escalar a 5 replicas
kubectl scale deployment backend-deployment --replicas=5

# Ver Pods (ahora 5)
kubectl get pods -l app=backend

# Ver Endpoints (ahora 5 IPs)
kubectl get endpoints backend-service

# Escalar a 1 replica
kubectl scale deployment backend-deployment --replicas=1

# Ver Endpoints (ahora 1 IP)
kubectl get endpoints backend-service

# Volver a 3 replicas
kubectl scale deployment backend-deployment --replicas=3
```

**Observa:** Los Endpoints se actualizan AUTOMATICAMENTE conforme Pods se crean/eliminan.

---

## Parte 3: Descubrimiento por DNS

### Paso 6: Probar DNS desde otro Pod

Kubernetes crea automaticamente registros DNS para los Services.

```bash
# Crear Pod de prueba
kubectl run test-dns --rm -it --image=busybox --restart=Never -- sh
```

Dentro del Pod, ejecutar:

```sh
# Resolver DNS del Service (nombre corto)
nslookup backend-service

# FQDN completo
nslookup backend-service.default.svc.cluster.local

# Test HTTP
wget -O- http://backend-service

# Ver multiples requests (balanceo)
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

**Observa:**
- DNS resuelve a la ClusterIP (`10.96.15.123`)
- Cada request puede ir a diferente Pod (balanceo automatico)

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

**Clave:** Formato DNS completo:
```
<service-name>.<namespace>.svc.cluster.local
```

---

## Parte 4: Balanceo de Carga

### Paso 8: Verificar Balanceo Automatico

```bash
# Ejecutar script de balanceo
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

**Observa:** Distribucion aproximadamente uniforme (puede variar ligeramente).

---

## Parte 5: Port-Forward para Testing Local

### Paso 9: Acceder al Service desde tu Laptop

```bash
# Port-forward del Service
kubectl port-forward service/backend-service 8080:80

# En OTRA terminal:
curl http://localhost:8080

# Ver respuesta HTML
curl http://localhost:8080 | grep -E "Pod:|IP:"

# Hacer multiples requests
for i in {1..10}; do
  curl -s http://localhost:8080 | grep "Pod:"
done

# Ctrl+C en la terminal del port-forward para detener
```

**Util para:** Debugging, desarrollo local, testing rapido.

---

## Parte 6: Troubleshooting Basico

### Paso 10: Simular Problema - Pod Sin Label

Vamos a crear un Pod que NO tiene las labels correctas.

```bash
# Pod sin la label "tier: api"
kubectl run backend-wrong-label --image=nginx:alpine \
  --labels=app=backend

# Ver Pods (ahora hay 4)
kubectl get pods -l app=backend

# Ver Endpoints (sigue siendo 3!)
kubectl get endpoints backend-service

# Por que? Ver labels del Pod problematico
kubectl get pod backend-wrong-label --show-labels
```

**Observa:**
- Pod tiene `app=backend` pero NO `tier=api`
- Service selector requiere AMBAS labels: `app=backend` Y `tier=api`
- Por eso NO aparece en Endpoints

**Solucion:**
```bash
# Agregar la label faltante
kubectl label pod backend-wrong-label tier=api

# Ahora si aparece en Endpoints
kubectl get endpoints backend-service

# Cleanup
kubectl delete pod backend-wrong-label
```

---

### Paso 11: Simular Problema - Pod Not Ready

Revisa el archivo `pod-not-ready.yaml`:

```bash
cat pod-not-ready.yaml
```

Puntos clave del manifiesto:
- **Labels correctas**: `app: backend` y `tier: api` (coinciden con el selector)
- **readinessProbe fallida**: apunta a `/nonexistent` que no existe
- El Pod estara Running pero NOT Ready (0/1)

```bash
kubectl apply -f pod-not-ready.yaml

# Ver estado del Pod (READY sera 0/1)
kubectl get pod backend-not-ready

# Ver Endpoints (NO incluye este Pod)
kubectl get endpoints backend-service -o yaml

# Ver por que no esta ready
kubectl describe pod backend-not-ready | grep -A 10 Conditions
```

**Salida:**
```
NAME                 READY   STATUS    RESTARTS   AGE
backend-not-ready    0/1     Running   0          30s
```

**Clave:**
- Pod esta `Running` pero NOT `Ready` (0/1)
- **NO aparece en Endpoints** porque readiness probe falla
- kube-proxy NO envia trafico a Pods not ready

**Cleanup:**
```bash
kubectl delete pod backend-not-ready
```

---

## Parte 7: Variables de Entorno (Legacy)

### Paso 12: Ver Variables de Entorno

Kubernetes inyecta variables de entorno para Services (metodo legacy).

```bash
# Crear Pod DESPUES del Service
kubectl run env-test --rm -it --image=busybox --restart=Never -- sh
```

```sh
# Ver variables del backend-service
env | grep BACKEND_SERVICE

# Deberias ver:
# BACKEND_SERVICE_SERVICE_HOST=10.96.15.123
# BACKEND_SERVICE_SERVICE_PORT=80
# BACKEND_SERVICE_PORT=tcp://10.96.15.123:80
# ...

exit
```

**Nota:** DNS es el metodo RECOMENDADO. Variables de entorno solo para compatibilidad legacy.

---

## Desafios Adicionales

### Desafio 1: Service con Multiples Puertos

Modifica el Service para exponer puerto 8080 ademas de 80.

<details>
<summary>Pista</summary>

Usa la seccion `ports` con multiples entradas, cada una con `name` unico.
</details>

<details>
<summary>Solucion</summary>

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

### Desafio 2: Session Affinity

Configura el Service para que el mismo cliente siempre vaya al mismo Pod.

<details>
<summary>Pista</summary>

Usa `sessionAffinity: ClientIP` en el spec del Service.
</details>

<details>
<summary>Solucion</summary>

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
# Multiples requests desde el mismo Pod deben ir al mismo backend
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- sh
# for i in {1..10}; do curl http://backend-service-sticky | grep Pod; done
# Deberia ver siempre el MISMO Pod
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

### Aprendiste:

**Service ClusterIP:**
- IP interna estable para acceder a Pods efimeros
- Solo accesible dentro del cluster
- Tipo por defecto (`type: ClusterIP`)

**Endpoints:**
- Se crean AUTOMATICAMENTE
- Rastrea Pods con labels que coinciden con `selector`
- Se actualizan dinamicamente (scale up/down)
- Solo incluye Pods `Ready`

**DNS Discovery:**
- Mismo namespace: `<service-name>`
- Otro namespace: `<service-name>.<namespace>`
- FQDN completo: `<service-name>.<namespace>.svc.cluster.local`
- **Recomendado sobre variables de entorno**

**Balanceo de Carga:**
- Automatico entre todos los Endpoints
- kube-proxy maneja reglas de iptables/IPVS
- Distribucion aproximadamente uniforme

**Troubleshooting:**
- Verificar labels coinciden con selector
- Verificar Pods estan `Ready`
- Verificar Endpoints creados correctamente

---

## Siguientes Pasos

1. **[Laboratorio 02: NodePort y LoadBalancer](../lab-02-nodeport-loadbalancer/)**
   - Acceso externo con NodePort
   - LoadBalancer en cloud
   - ExternalTrafficPolicy

2. **[Ejemplos de Services](../../ejemplos/README.md)**
   - Revisar ejemplos avanzados
   - Session affinity
   - Multiples puertos

---

## Checklist de Verificacion

- [ ] Puedes crear un Service ClusterIP
- [ ] Entiendes como funcionan los Endpoints
- [ ] Sabes usar DNS para descubrir Services
- [ ] Puedes verificar balanceo de carga
- [ ] Sabes diagnosticar Pods not ready
- [ ] Entiendes diferencia entre DNS y variables de entorno

---

**Felicidades!** Has completado el Laboratorio 01.
Tienes las bases solidas para trabajar con Services en Kubernetes.
