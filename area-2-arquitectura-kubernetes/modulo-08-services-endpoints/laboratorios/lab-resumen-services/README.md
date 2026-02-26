# Resumen Rapido: Los 4 Tipos de Service en Kubernetes

**Duracion:** 15 minutos | **Nivel:** Repaso | **Archivo:** `services-lab.yaml`

Un solo YAML despliega un backend + los 4 tipos de Service + pods de prueba para comparar todo de un vistazo.

---

## Que es un Service

Un Pod en Kubernetes tiene IP efimera: se pierde cuando el Pod muere o se recrea. Un **Service** resuelve esto dando una **IP estable y un nombre DNS** para acceder a un grupo de Pods.

El flujo es siempre el mismo:

```
Cliente → Service (IP estable + DNS) → Endpoints (lista de IPs de Pods) → Pods
```

El **selector** del Service busca Pods con labels que coincidan. kube-proxy configura reglas de red (iptables/IPVS) para distribuir el trafico.

---

## Los 4 Tipos de Service

### 1. ClusterIP (interno, por defecto)

```yaml
spec:
  type: ClusterIP       # Se puede omitir, es el default
  selector:
    app: backend
```

- Asigna una **IP virtual interna** solo accesible desde dentro del cluster
- CoreDNS crea registro: `backend-clusterip.lab-services.svc.cluster.local`
- Balancea automaticamente entre todos los Pods que matchean el selector
- **Usar cuando:** comunicacion entre microservicios internos (frontend→backend, app→database)

### 2. LoadBalancer (acceso externo via cloud)

```yaml
spec:
  type: LoadBalancer
  selector:
    app: backend
```

- En cloud (AWS/Azure/GCP) crea un **Load Balancer real** con IP publica
- En Minikube requiere `minikube tunnel` en otra terminal
- Internamente crea tambien un ClusterIP + NodePort
- **Usar cuando:** necesitas exponer un servicio a Internet en produccion
- **Costo:** cada LoadBalancer = 1 recurso en cloud. Para multiples servicios HTTP, usar Ingress

### 3. Headless (clusterIP: None)

```yaml
spec:
  clusterIP: None        # La clave del Headless
  selector:
    app: backend
```

- **No asigna IP virtual**. DNS devuelve directamente las IPs de CADA Pod
- El cliente elige a que Pod conectarse (no hay balanceo automatico)
- Requerido por **StatefulSets** para dar DNS individual a cada Pod (`pod-0.svc`, `pod-1.svc`)
- **Usar cuando:** bases de datos (MySQL master/slave), caches (Redis Cluster), apps que necesitan saber la IP de cada instancia

### 4. ExternalName (alias DNS externo)

```yaml
spec:
  type: ExternalName
  externalName: example.com
```

- **No selecciona Pods**, no crea Endpoints, no balancea trafico
- Solo crea un registro **CNAME** en DNS del cluster
- Pods acceden al dominio externo usando el nombre del Service
- **Usar cuando:** integrar APIs externas, migracion gradual (externo→interno sin cambiar codigo), abstraer URLs

---

## Tabla Comparativa

```
┌──────────────────┬────────────┬──────────────┬────────────────┬─────────────────────┐
│ Tipo             │ ClusterIP  │ LoadBalancer  │ Headless       │ ExternalName        │
├──────────────────┼────────────┼──────────────┼────────────────┼─────────────────────┤
│ IP Virtual       │ Si         │ Si + publica │ No (None)      │ No                  │
│ DNS devuelve     │ ClusterIP  │ ClusterIP    │ IPs de Pods    │ CNAME externo       │
│ Selector         │ Si         │ Si           │ Si             │ No                  │
│ Endpoints        │ Automatico │ Automatico   │ Automatico     │ No crea             │
│ Balanceo         │ kube-proxy │ LB + kube-p  │ Cliente decide │ No aplica           │
│ Acceso externo   │ No         │ Si           │ No             │ Solo DNS            │
│ Caso de uso      │ Internal   │ Produccion   │ StatefulSet/DB │ APIs externas       │
└──────────────────┴────────────┴──────────────┴────────────────┴─────────────────────┘
```

---

## Ejercicio Practico (15 min)

### Paso 1: Desplegar todo (1 min)

```bash
kubectl apply -f services-lab.yaml
```

Verificar que todo esta running:

```bash
kubectl get all -n lab-services
```

**Salida esperada:** 3 Pods del deployment + 2 Pods de prueba + 4 Services.

---

### Paso 2: Comparar DNS de cada Service (3 min)

Entrar al pod busybox-dns:

```bash
kubectl exec -it busybox-dns -n lab-services -- sh
```

Dentro del pod, resolver DNS de cada Service:

```sh
# 1) ClusterIP → devuelve UNA IP virtual
nslookup backend-clusterip
# Name:   backend-clusterip.lab-services.svc.cluster.local
# Address: 10.96.X.X    ← IP virtual estable

# 2) LoadBalancer → devuelve UNA IP virtual (la misma mecanica interna)
nslookup backend-lb
# Address: 10.96.Y.Y    ← Otra IP virtual

# 3) Headless → devuelve TRES IPs (una por Pod)
nslookup backend-headless
# Address: 10.244.0.5   ← IP del Pod 1
# Address: 10.244.0.6   ← IP del Pod 2
# Address: 10.244.0.7   ← IP del Pod 3

# 4) ExternalName → devuelve CNAME al dominio externo
nslookup backend-external
# backend-external.lab-services.svc.cluster.local
#   canonical name = example.com

exit
```

**Diferencia clave:**
- ClusterIP/LB: DNS → 1 IP virtual (kube-proxy balancea)
- Headless: DNS → N IPs reales de Pods (cliente elige)
- ExternalName: DNS → CNAME a dominio externo

---

### Paso 3: Probar balanceo de ClusterIP (3 min)

```bash
kubectl exec busybox-curl -n lab-services -- \
  sh -c 'for i in 1 2 3 4 5 6; do curl -s backend-clusterip | grep Pod; done'
```

**Salida esperada** (Pods diferentes en cada request):
```
<p>Pod: backend-deployment-xxxxx</p>
<p>Pod: backend-deployment-yyyyy</p>
<p>Pod: backend-deployment-zzzzz</p>
<p>Pod: backend-deployment-xxxxx</p>
...
```

kube-proxy distribuye automaticamente entre los 3 Pods.

---

### Paso 4: Probar Headless - sin balanceo (3 min)

```bash
# Headless: cada request puede ir al mismo Pod (depende de DNS cache)
kubectl exec busybox-curl -n lab-services -- \
  sh -c 'for i in 1 2 3 4 5 6; do curl -s backend-headless | grep Pod; done'
```

Observa que puede repetir el mismo Pod. Con Headless el cliente recibe las IPs directamente y curl se conecta a la primera que resuelve DNS.

Para ver todas las IPs que devuelve:

```bash
kubectl exec busybox-dns -n lab-services -- nslookup backend-headless
```

---

### Paso 5: Probar acceso externo con LoadBalancer (2 min)

```bash
# Ver EXTERNAL-IP (en Minikube sera <pending> sin tunnel)
kubectl get svc backend-lb -n lab-services

# Si usas Minikube, en OTRA terminal:
# minikube tunnel

# Obtener IP y probar
LB_IP=$(kubectl get svc backend-lb -n lab-services -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "LoadBalancer IP: $LB_IP"

# Si tienes IP asignada:
curl http://$LB_IP
```

Sin cloud/tunnel, puedes verificar que internamente funciona igual que ClusterIP:

```bash
kubectl exec busybox-curl -n lab-services -- curl -s backend-lb | grep Pod
```

---

### Paso 6: Verificar ExternalName (1 min)

```bash
kubectl exec busybox-dns -n lab-services -- nslookup backend-external
```

**Salida esperada:**
```
backend-external.lab-services.svc.cluster.local
  canonical name = example.com
```

No hay IP del cluster. Solo un CNAME al dominio externo.

---

### Paso 7: Comparar Endpoints de cada Service (2 min)

```bash
kubectl get endpoints -n lab-services
```

**Salida esperada:**
```
NAME                ENDPOINTS                                    AGE
backend-clusterip   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80   5m
backend-headless    10.244.0.5:80,10.244.0.6:80,10.244.0.7:80   5m
backend-lb          10.244.0.5:80,10.244.0.6:80,10.244.0.7:80   5m
```

Nota: `backend-external` NO aparece — ExternalName no crea Endpoints.

ClusterIP, LoadBalancer y Headless comparten los mismos Endpoints porque usan el mismo selector (`app: backend, tier: api`).

---

## Resumen Visual

```
                         ┌───────────────────────────────────────┐
                         │           CLUSTER KUBERNETES          │
                         │                                       │
  ┌─────────────────┐    │  ┌─────────────┐    ┌──────────────┐ │
  │  ExternalName   │────│──│ DNS CNAME   │    │  Pod-1       │ │
  │ (solo DNS)      │    │  │ example.com │    │  10.244.0.5  │ │
  └─────────────────┘    │  └─────────────┘    └──────┬───────┘ │
                         │                            │         │
  ┌─────────────────┐    │  ┌─────────────┐          │         │
  │   ClusterIP     │────│──│ 10.96.X.X   │──────────┤         │
  │ (IP interna)    │    │  │  kube-proxy  │    ┌─────┴────────┐│
  └─────────────────┘    │  │  balancea    │    │  Pod-2       ││
                         │  └─────────────┘    │  10.244.0.6  ││
  ┌─────────────────┐    │  ┌─────────────┐    └──────┬───────┘│
  │  LoadBalancer   │────│──│ IP publica  │──────────┤         │
  │ (IP externa)    │    │  │ + ClusterIP │    ┌─────┴────────┐│
  └─────────────────┘    │  └─────────────┘    │  Pod-3       ││
                         │                      │  10.244.0.7  ││
  ┌─────────────────┐    │  ┌─────────────┐    └──────────────┘│
  │   Headless      │────│──│ DNS → IPs   │────── Pod-1,2,3    │
  │ (sin ClusterIP) │    │  │ de cada Pod │    (cliente elige)  │
  └─────────────────┘    │  └─────────────┘                     │
                         └───────────────────────────────────────┘
```

---

## Cuando Usar Cada Tipo

| Situacion | Tipo recomendado | Por que |
|-----------|-----------------|---------|
| App frontend → backend API | ClusterIP | Comunicacion interna, no necesita acceso externo |
| App → base de datos interna | ClusterIP | DB solo accesible dentro del cluster |
| Exponer web app a Internet | LoadBalancer | Necesita IP publica (o Ingress para multiples) |
| MySQL master-slave | Headless | Cada replica necesita DNS individual |
| Redis Cluster / Cassandra | Headless | Nodos necesitan conocerse entre si |
| Integrar API externa (Stripe, S3) | ExternalName | Abstrae URL externa con nombre de Service |
| Migracion de DB externa → interna | ExternalName → ClusterIP | Cambias el Service, no el codigo |

---

## Limpieza

```bash
chmod +x cleanup.sh
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-services
```
