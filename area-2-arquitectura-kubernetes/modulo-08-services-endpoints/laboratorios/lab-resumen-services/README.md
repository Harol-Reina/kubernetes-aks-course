# Resumen Rapido: Los 4 Tipos de Service en Kubernetes

**Duracion:** 15 minutos | **Nivel:** Repaso | **Archivo:** `services-lab.yaml`

Un solo YAML despliega un backend + los 4 tipos de Service + pods de prueba para comparar todo de un vistazo.

---

## Conceptos Previos (si es tu primera vez con Services)

Antes de empezar, tres ideas fundamentales:

**1. Los Pods tienen IPs temporales**
Cada Pod que crea Kubernetes recibe una direccion IP. Pero esa IP desaparece cuando el Pod muere, se reinicia o Kubernetes lo reemplaza por un fallo. Es como si cada vez que reiniciaras tu computadora cambiara su numero de serie — no puedes confiar en ella para conectarte.

**2. Un Service es como un numero de telefono que nunca cambia**
Imagina que tienes 3 empleados (Pods) que atienden llamadas. Sus telefonos personales cambian cada vez que renuevan contrato (IP efimera). La empresa les asigna un numero central (Service) que siempre es el mismo. Llamas al numero central y la centralita (kube-proxy) te pasa con quien este disponible — sin que tu tengas que saber quien atiende.

**3. DNS es como una guia telefonica**
DNS (Domain Name System) convierte nombres legibles (`backend-clusterip`) en IPs numericas (`10.96.4.7`). En Kubernetes, CoreDNS hace ese trabajo automaticamente para cada Service que creas. Asi puedes escribir `curl backend-clusterip` en lugar de `curl 10.96.4.7`.

Como se conectan estas tres ideas:

```
Nombre del Service          DNS (CoreDNS)          IP del Service (o Pods)
"backend-clusterip"   →   guia telefonica   →   10.96.4.7 (centralita)
                                                       ↓
                                             Pod-1  Pod-2  Pod-3
                                          (empleados que atienden)
```

---

## Que es un Service

Un Pod en Kubernetes tiene IP efimera: se pierde cuando el Pod muere o se recrea. Un **Service** resuelve esto dando una **IP estable y un nombre DNS** para acceder a un grupo de Pods.

El flujo es siempre el mismo:

```
Cliente → Service (IP estable + DNS) → Endpoints (lista de IPs de Pods) → Pods
```

**Que son los Endpoints?** Kubernetes mantiene automaticamente una lista actualizada con las IPs reales de todos los Pods que coinciden con el selector del Service. Esa lista se llama Endpoints. Cada vez que un Pod se crea o muere, la lista se actualiza sola — tu no tienes que hacer nada.

El **selector** del Service busca Pods con labels que coincidan. kube-proxy configura reglas de red (iptables/IPVS) para distribuir el trafico.

---

## Los 4 Tipos de Service

### 1. ClusterIP (interno, por defecto)

> Analogia: como un telefono interno de oficina — solo funciona dentro del edificio. Nadie de fuera puede llamar a ese numero.

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

> Analogia: como el numero de telefono publico de la empresa — cualquier persona desde fuera puede llamar. Internamente la centralita sigue distribuyendo las llamadas entre empleados.

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

> Analogia: como tener el telefono directo de cada empleado en lugar de pasar por la centralista. Tu decides a quien llamar, y puedes llamar a todos si quieres. No hay intermediario que distribuya.

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

> Analogia: como redirigir llamadas a un numero externo. Cuando alguien llama al numero interno de la empresa, automaticamente se redirige a un numero de otra compania fuera del edificio. Nadie dentro necesita saber el numero real externo.

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
│ Tipo             │ ClusterIP  │ LoadBalancer │ Headless       │ ExternalName        │
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

> **Que aprendimos?** Con un solo `kubectl apply` Kubernetes creo todos los recursos declarados en el YAML: el Deployment (que a su vez creo 3 Pods), los 4 Services con sus distintos tipos, y los 2 Pods auxiliares para pruebas.

---

### Paso 2: Comparar DNS de cada Service (3 min)

**Que es nslookup y para que sirve?**
`nslookup` es una herramienta de linea de comandos que consulta el DNS. Le das un nombre (`backend-clusterip`) y te responde con la IP que corresponde a ese nombre — exactamente lo que hace tu navegador en segundo plano cuando escribes una URL. Aqui lo usamos para ver como cada tipo de Service responde de forma diferente a la misma pregunta: "cual es la IP de este nombre?"

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

> **Que aprendimos?** El tipo de Service cambia fundamentalmente lo que DNS devuelve. ClusterIP y LoadBalancer ocultan los Pods detras de una IP unica. Headless los expone todos. ExternalName ni siquiera apunta al cluster.

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

> **Que aprendimos?** El cliente (busybox-curl) siempre llama al mismo nombre (`backend-clusterip`) pero llega a Pods distintos. Esto es el balanceo de carga: el Service absorbe la complejidad de saber cuantos Pods hay y cual esta libre.

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

> **Que aprendimos?** Con Headless, DNS entrega las IPs crudas de los Pods. El cliente recibe varias IPs y decide cual usar. Esto es util para bases de datos donde el cliente necesita elegir el nodo maestro o conectarse a una replica especifica.

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

> **Que aprendimos?** Los Endpoints son la lista viva de IPs de Pods. Kubernetes la actualiza automaticamente. Si un Pod muere, desaparece de Endpoints y el Service deja de enviarle trafico — sin intervencion manual. ExternalName no tiene Endpoints porque no apunta a Pods del cluster.

---

## Resumen Visual

```
                         ┌─────────────────────────────────────┐
                         │           CLUSTER KUBERNETES        │
                         │                                     │
  ┌─────────────────┐    │  ┌─────────────┐    ┌──────────────┐│
  │  ExternalName   │────│──│ DNS CNAME   │    │  Pod-1       ││
  │ (solo DNS)      │    │  │ example.com │    │  10.244.0.5  ││
  └─────────────────┘    │  └─────────────┘    └──────┬───────┘│
                         │                            │        │
  ┌─────────────────┐    │  ┌─────────────┐           │        │
  │   ClusterIP     │────│──│ 10.96.X.X   │───────────┤        │
  │ (IP interna)    │    │  │  kube-proxy │    ┌──────┴───────┐│
  └─────────────────┘    │  │  balancea   │    │  Pod-2       ││
                         │  └─────────────┘    │  10.244.0.6  ││
  ┌─────────────────┐    │  ┌─────────────┐    └──────┬───────┘│
  │  LoadBalancer   │────│──│ IP publica  │───────────┤        │
  │ (IP externa)    │    │  │ + ClusterIP │    ┌──────┴───────┐│
  └─────────────────┘    │  └─────────────┘    │  Pod-3       ││
                         │                     │  10.244.0.7  ││
  ┌─────────────────┐    │  ┌─────────────┐    └──────────────┘│
  │   Headless      │────│──│ DNS → IPs   │────── Pod-1,2,3    │
  │ (sin ClusterIP) │    │  │ de cada Pod │    (cliente elige) │
  └─────────────────┘    │  └─────────────┘                    │
                         └─────────────────────────────────────┘
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

## Comandos de Diagnostico Esenciales

Estos cuatro comandos cubren el 90% de las preguntas que tendras sobre Services:

```bash
# Ver todos los Services en un namespace
kubectl get svc -n lab-services

# Ver detalles de un Service: selector, puertos, Endpoints activos
kubectl describe svc backend-clusterip -n lab-services

# Ver la lista de IPs de Pods que reciben trafico (Endpoints)
kubectl get endpoints -n lab-services

# Resolver el nombre DNS de un Service desde dentro del cluster
kubectl exec busybox-dns -n lab-services -- nslookup backend-clusterip
```

---

## Errores Comunes para Principiantes

**"Mi Service no llega a ningun Pod"**
El motivo mas frecuente es que el selector del Service no coincide con los labels del Pod. Verifica:
```bash
# Ver labels del Pod
kubectl get pod <nombre-pod> --show-labels -n lab-services

# Ver selector del Service
kubectl describe svc backend-clusterip -n lab-services | grep Selector
```
Ambos tienen que tener exactamente los mismos valores.

**"El Headless devuelve siempre el mismo Pod"**
Es comportamiento normal si el cliente cachea el resultado DNS. curl resuelve el nombre una vez y reutiliza la IP. Las aplicaciones reales (drivers de bases de datos) manejan esto ellas mismas.

**"El LoadBalancer sigue en estado pending"**
En Minikube sin `minikube tunnel`, la IP externa nunca se asigna. Eso es esperado — en un cluster de nube real si se asignaria automaticamente. Puedes seguir accediendo via ClusterIP desde dentro del cluster.

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
