# Resumen Practico: Todos los Patrones de Ingress en Kubernetes

**Duracion:** 60 minutos | **Nivel:** Repaso integral | **Archivo:** `ingress-lab.yaml`

Un solo YAML despliega 4 backends + 4 Services + 6 Ingress resources + 1 pod de prueba para practicar todos los patrones de enrutamiento de un vistazo, usando Minikube.

---

## Conceptos Previos (para personas nuevas en el tema)

Antes de entrar en Kubernetes, conviene tener claros estos conceptos basicos de redes y web.

### HTTP y HTTPS: como habla tu navegador con un servidor

Cuando escribes `http://google.com` en tu navegador, este envia un mensaje al servidor de Google siguiendo el protocolo **HTTP** (HyperText Transfer Protocol). El servidor responde con el contenido de la pagina.

**HTTPS** es la version segura de HTTP: los datos viajan cifrados para que nadie en el camino (tu proveedor de internet, una red publica) pueda leerlos. La `S` significa "Secure".

```
Sin HTTPS (HTTP):    navegador ──texto claro──→ servidor
                              cualquiera puede leer los datos

Con HTTPS:           navegador ──cifrado──────→ servidor
                              los datos son ilegibles si se interceptan
```

### Que es un dominio o nombre de host

Un **dominio** es un nombre legible para los humanos que apunta a una direccion IP. Por ejemplo, `google.com` es mas facil de recordar que `142.250.80.46`.

Cuando tu navegador ve `http://google.com`, primero consulta a un servidor DNS (como una guia telefonica de internet) para traducir `google.com` a una IP, y luego envia la peticion a esa IP.

En este lab usaremos dominios de prueba como `demo.lab`, `api.lab`, etc. Como no son dominios reales en internet, los configuramos manualmente en `/etc/hosts` (ver Paso 0.3).

### Que es un path (ruta) en una URL

Una URL como `http://tienda.com/productos/zapatos` tiene tres partes:

```
http://tienda.com  /productos/zapatos
  |         |            |
protocolo  dominio      path (ruta)
```

El **path** es todo lo que viene despues del dominio. Los servidores usan el path para saber que contenido devolver. Por ejemplo:
- `/` → la pagina principal
- `/api` → el servicio de API
- `/imagenes/logo.png` → un archivo especifico

### Ingress es como la recepcion de un edificio

Imagina un edificio de oficinas con muchas empresas. La **recepcion** en la entrada recibe a todos los visitantes y, segun a quien buscan, los dirige al piso y oficina correctos.

**Ingress en Kubernetes funciona igual:**
- El edificio = el cluster de Kubernetes
- La recepcion = el Ingress Controller (NGINX)
- Las empresas = los Services (aplicaciones)
- El visitante = una peticion HTTP de un navegador o cliente

```
Visitante llega al edificio:  "Busco a la empresa API"
Recepcion consulta el directorio (reglas Ingress)
Recepcion indica: "Piso 3, oficina api-svc"

Peticion HTTP llega al cluster: GET http://demo.lab/api
Ingress Controller consulta las reglas Ingress
Ingress Controller envia al Service: api-svc:80
```

---

## Que es Ingress

Un **Service** expone Pods dentro del cluster, pero no sabe de HTTP, hosts, ni paths. Un **Ingress** resuelve esto: es una capa HTTP/HTTPS que enruta trafico externo a Services internos basandose en reglas de host y path.

El flujo es:

```
Cliente HTTP → Ingress Controller (NGINX) → Reglas Ingress → Service → Pods
                    ↑
              Lee los recursos Ingress
              y configura su proxy
```

El **Ingress Controller** es un pod (NGINX, Traefik, HAProxy) que observa los recursos Ingress del cluster y configura su proxy automaticamente. Sin controller, los recursos Ingress no hacen nada.

**Ingress vs LoadBalancer:** Un LoadBalancer crea un recurso en cloud por cada Service. Con Ingress, un solo punto de entrada (1 IP publica) enruta a multiples Services por host/path. En produccion, esto ahorra costos y simplifica la gestion.

---

## Patrones Cubiertos en Este Lab

| Patron | Ingress | Que demuestra |
|--------|---------|---------------|
| **Path-Based Routing** | `path-routing` | Enrutar `/frontend` y `/api` a backends diferentes usando un solo host |
| **Host-Based Routing** | `host-routing-*` | Virtual hosting: `frontend.lab` y `api.lab` en la misma IP |
| **Canary Deployment** | `canary-production` + `canary-new` | Enviar 20% del trafico a una version nueva para validacion gradual |
| **Rate Limiting** | `rate-limited` | Limitar peticiones por segundo para proteger el backend |
| **URL Rewriting** | `rewrite-demo` | Reescribir `/api/v1/users` a `/users` con expresiones regulares |
| **TLS Termination** | *(manual, paso 8)* | HTTPS con certificados autofirmados y redireccion HTTP→HTTPS |

---

## Anatomia de un Recurso Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-ingress
  annotations:                        # Configuracion especifica del controller
    nginx.ingress.kubernetes.io/...
spec:
  ingressClassName: nginx             # Que controller procesa este Ingress
  tls:                                # (opcional) Configuracion HTTPS
  - hosts: [mi-dominio.com]
    secretName: tls-secret            # Secret con certificado + clave
  rules:                              # Reglas de enrutamiento
  - host: mi-dominio.com             # (opcional) Filtrar por header Host
    http:
      paths:
      - path: /api                    # Path a matchear
        pathType: Prefix              # Prefix | Exact | ImplementationSpecific
        backend:
          service:
            name: mi-servicio         # Service destino
            port:
              number: 80
```

**Campos clave:**
- `ingressClassName`: selecciona el controller (puede haber varios en un cluster)
- `rules[].host`: si se omite, matchea cualquier host
- `pathType: Prefix`: `/api` matchea `/api`, `/api/`, `/api/users`
- `pathType: Exact`: solo matchea el path exacto
- `annotations`: donde se configura rewrite, rate limit, canary, CORS, etc.

---

## Diagrama Visual

```
                    ┌──────────────────────────────────────────────────┐
                    │              MINIKUBE CLUSTER                    │
  INTERNET          │                                                  │
  (navegador/curl)  │  ┌─────────────────────────────────┐             │
       │            │  │   NGINX Ingress Controller       │             │
       │            │  │   (namespace: ingress-nginx)     │             │
       ▼            │  │                                  │             │
  ┌─────────┐       │  │  Reglas que aplica:              │             │
  │ /etc/   │       │  │                                  │             │
  │ hosts   │       │  │  demo.lab/frontend → frontend-svc│   ┌──────┐ │
  │         │───────│──│  demo.lab/api      → api-svc     │──→│Pod 1 │ │
  │ demo.lab│       │  │  frontend.lab      → frontend-svc│   │Pod 2 │ │
  │ api.lab │       │  │  api.lab           → api-svc     │   │Pod 3 │ │
  │ canary. │       │  │  canary.lab        → api-svc(80%)│   │ ...  │ │
  │  lab    │       │  │                    → api-v2(20%) │   └──────┘ │
  │ limited.│       │  │  limited.lab       → api-svc(5rps│             │
  │  lab    │       │  │  rewrite.lab/api/v1→ admin-svc   │             │
  │ rewrite.│       │  │                                  │             │
  │  lab    │       │  └─────────────────────────────────┘             │
  └─────────┘       └──────────────────────────────────────────────────┘
```

---

## Paso 0: Preparar Minikube (5 min)

### 0.1: Iniciar Minikube (si no esta corriendo)

```bash
minikube start

# Verificar
minikube status
kubectl cluster-info
```

### 0.2: Habilitar el addon de Ingress

```bash
minikube addons enable ingress

# Esperar a que el controller este Ready (~1 minuto)
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

**Salida esperada:**
```
pod/ingress-nginx-controller-xxxxx condition met
```

### 0.3: Obtener IP de Minikube y configurar /etc/hosts

**Que es /etc/hosts y para que sirve aqui:**
El archivo `/etc/hosts` es una "guia telefonica local" que tu sistema operativo consulta ANTES de preguntar a un servidor DNS de internet. Cada linea dice: "este nombre de dominio → esta IP". En este lab, los dominios `demo.lab`, `api.lab`, etc. no existen en internet, asi que los registramos manualmente aqui apuntando a la IP de Minikube. Asi, cuando escribas `curl http://demo.lab/`, tu maquina sabe a que IP conectarse.

```bash
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Agregar todos los hosts del lab
echo "$MINIKUBE_IP demo.lab frontend.lab api.lab canary.lab limited.lab rewrite.lab secure.lab" \
  | sudo tee -a /etc/hosts

# Verificar
grep ".lab" /etc/hosts
```

---

## Paso 1: Desplegar Todo (2 min)

```bash
kubectl apply -f ingress-lab.yaml
```

Verificar que todo esta running:

```bash
kubectl get all -n lab-ingress
```

**Salida esperada:** 4 Deployments, 4 Services, 8 Pods (3+2+2+1), 6 Ingress, 1 Pod test.

```bash
# Ver Ingress creados
kubectl get ingress -n lab-ingress
```

**Salida esperada:**
```
NAME                    CLASS   HOSTS          ADDRESS        PORTS
path-routing            nginx   demo.lab       192.168.49.2   80
host-routing-frontend   nginx   frontend.lab   192.168.49.2   80
host-routing-api        nginx   api.lab        192.168.49.2   80
canary-production       nginx   canary.lab     192.168.49.2   80
canary-new              nginx   canary.lab     192.168.49.2   80
rate-limited            nginx   limited.lab    192.168.49.2   80
rewrite-demo            nginx   rewrite.lab    192.168.49.2   80
```

Todos los Ingress comparten la misma IP (la del Ingress Controller). El controller decide a que backend enviar segun host + path.

---

## Paso 2: Path-Based Routing (8 min)

Diferentes paths en el MISMO host van a backends diferentes.

```bash
# /frontend → frontend-svc → responde FRONTEND
curl -s http://demo.lab/frontend

# /api → api-svc → responde API v1
curl -s http://demo.lab/api

# / sin path especifico → 404 (no hay regla para /)
curl -s -o /dev/null -w "%{http_code}" http://demo.lab/
```

**Salida esperada:**
```
<h1>FRONTEND</h1><p>Pod: frontend-app-xxxxx</p>
<h1>API v1</h1><p>Pod: api-app-xxxxx</p>
404
```

### Verificar balanceo entre replicas

```bash
# La API tiene 3 replicas - cada request puede ir a un Pod diferente
for i in {1..6}; do
  curl -s http://demo.lab/api | grep Pod
done
```

**Clave:** El `rewrite-target: /` elimina el prefijo. Sin esto, el backend recibiria `/frontend` como path y retornaria 404 (no tiene esa ruta).

### Ver como se configuro

```bash
kubectl describe ingress path-routing -n lab-ingress
```

Observa la seccion `Rules` que muestra path → backend → puerto.

---

## Paso 3: Host-Based Routing (5 min)

Diferentes DOMINIOS van a backends diferentes (virtual hosting).

```bash
# frontend.lab → frontend-svc
curl -s http://frontend.lab/

# api.lab → api-svc
curl -s http://api.lab/
```

**Salida esperada:**
```
<h1>FRONTEND</h1><p>Pod: frontend-app-xxxxx</p>
<h1>API v1</h1><p>Pod: api-app-xxxxx</p>
```

### Diferencia con path-based

```
Path-based:  1 host, multiples paths    → demo.lab/frontend, demo.lab/api
Host-based:  multiples hosts, 1 path    → frontend.lab/, api.lab/
```

Ambos pueden combinarse: `api.lab/v1`, `api.lab/v2` en el mismo Ingress.

### Probar con header Host (sin /etc/hosts)

```bash
# Alternativa si no puedes editar /etc/hosts
curl -s -H "Host: frontend.lab" http://$(minikube ip)/
curl -s -H "Host: api.lab" http://$(minikube ip)/
```

---

## Paso 4: Canary Deployment (12 min)

**Que es un "canary deployment" y por que se llama asi:**
En las minas de carbon del siglo XIX, los mineros llevaban canarios a la mina. Si habia gases toxicos, el canario moría primero (antes que los humanos) y eso avisaba a los mineros para evacuar. En software, un **canary deployment** usa la misma logica: antes de actualizar el sistema para TODOS los usuarios, se envia la nueva version solo a un porcentaje pequeno (por ejemplo, el 5% o el 20%) del trafico real. Si algo falla, solo afecta a ese pequeno grupo — el "canario" ha avisado del problema antes de que llegue a todos.

```
Sin canary:   version nueva → 100% usuarios → si falla, TODOS se ven afectados

Con canary:   version nueva → 20% usuarios  → si falla, solo 20% afectados
              version vieja → 80% usuarios  → el resto sigue sin problemas
              (si va bien, se sube al 50%, luego 100%)
```

Enviar un porcentaje del trafico a una version nueva para validarla antes de un rollout completo.

### 4.1: Verificar distribucion inicial (20% canary)

```bash
# Enviar 50 requests y contar versiones
for i in $(seq 1 50); do
  curl -s http://canary.lab/ | grep -o "API v[12]"
done | sort | uniq -c
```

**Salida esperada (aproximada):**
```
  40 API v1
  10 API v2
```

~80% va a v1 (produccion), ~20% va a v2 (canary).

### 4.2: Aumentar canary a 50%

```bash
kubectl patch ingress canary-new -n lab-ingress \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"50"}}}'

# Verificar nueva distribucion
for i in $(seq 1 50); do
  curl -s http://canary.lab/ | grep -o "API v[12]"
done | sort | uniq -c
```

**Salida esperada (aproximada):**
```
  25 API v1
  25 API v2
```

### 4.3: Promover v2 a produccion (100%)

```bash
kubectl patch ingress canary-new -n lab-ingress \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"100"}}}'

# Todo el trafico va a v2
for i in $(seq 1 10); do
  curl -s http://canary.lab/ | grep -o "API v[12]"
done | sort | uniq -c
```

### 4.4: Rollback instantaneo a v1

```bash
kubectl patch ingress canary-new -n lab-ingress \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"0"}}}'

# Verificar: todo va a v1 de nuevo
curl -s http://canary.lab/
```

**Clave:** El canary deployment con Ingress es a nivel de trafico de red, no de Pods. Los Deployments no cambian — solo el porcentaje de trafico que llega a cada Service.

### Restaurar a 20% para los siguientes ejercicios

```bash
kubectl patch ingress canary-new -n lab-ingress \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"20"}}}'
```

**Que aprendimos en este paso:**
- Un canary deployment divide el trafico entre dos versiones sin cambiar los Pods ni los Services — solo se ajusta un numero en las anotaciones del Ingress.
- El rollback es instantaneo: basta con poner `canary-weight: 0` y todo el trafico vuelve a la version estable.
- Esta tecnica permite validar una nueva version con trafico real sin arriesgar a todos los usuarios a la vez.

---

## Paso 5: Rate Limiting (8 min)

**Por que limitar el numero de peticiones:**
Imagina que tienes un quiosco de cafe con un solo empleado. Si llegan 5 clientes por minuto, el empleado puede atenderlos bien. Pero si llegan 500 clientes en un minuto, el sistema colapsa y nadie es atendido.

En software pasa lo mismo: si un servidor recibe demasiadas peticiones en poco tiempo (ya sea por un ataque malicioso, un bot, o simplemente demasiados usuarios), puede quedarse sin memoria, CPU o conexiones y caer. El **rate limiting** pone un limite: "maximo N peticiones por segundo por cliente". Las peticiones que superan ese limite son rechazadas con un error `503` en lugar de colapsar el servidor.

```
Sin rate limiting:   1000 req/seg → servidor se satura → TODOS los usuarios sufren

Con rate limiting:   primeras 5 req/seg → pasan (HTTP 200)
                     resto              → rechazadas (HTTP 503)
                     servidor protegido → usuarios normales siguen funcionando
```

Proteger un endpoint limitando las peticiones por segundo.

### 5.1: Enviar rafaga de requests

```bash
# Enviar 30 requests lo mas rapido posible
for i in $(seq 1 30); do
  curl -s -o /dev/null -w "%{http_code} " http://limited.lab/
done
echo ""
```

**Salida esperada:**
```
200 200 200 200 200 503 503 503 503 503 503 200 503 503 ...
```

Los primeros pasan (200), los siguientes son rechazados (503) porque exceden 5 requests por segundo.

### 5.2: Verificar configuracion

```bash
kubectl describe ingress rate-limited -n lab-ingress | grep -A2 Annotations
```

**Salida:**
```
Annotations:
  nginx.ingress.kubernetes.io/limit-connections: 10
  nginx.ingress.kubernetes.io/limit-rps: 5
```

### 5.3: Comparar con endpoint sin limite

```bash
# api.lab no tiene rate limiting — todos retornan 200
for i in $(seq 1 30); do
  curl -s -o /dev/null -w "%{http_code} " http://api.lab/
done
echo ""
```

**Salida esperada:** todos `200 200 200 200 ...`

**Que aprendimos en este paso:**
- El rate limiting se configura con anotaciones en el recurso Ingress: no hay que modificar el codigo de la aplicacion.
- El Ingress Controller (NGINX) es quien cuenta las peticiones y rechaza las que superan el limite, antes de que lleguen al Pod.
- Los clientes que superan el limite reciben un `503 Service Unavailable`, no un error de conexion — la aplicacion sigue funcionando para los demas.

---

## Paso 6: URL Rewriting (8 min)

Reescribir el path antes de enviarlo al backend.

### 6.1: Probar rewrite

```bash
# /api/v1/users → /api/v1/users en admin-svc
curl -s http://rewrite.lab/api/v1/users

# /api/v1/health → /api/v1/health en admin-svc
curl -s http://rewrite.lab/api/v1/health

# /api/v1/ → / en admin-svc (pagina principal del admin)
curl -s http://rewrite.lab/api/v1/
```

**Salida esperada:**
```
{"users":["alice","bob"]}
{"status":"ok"}
<h1>ADMIN PANEL</h1>...
```

### 6.2: Entender la regex

```
Path del cliente:       /api/v1/users
Regex:                  /api/v1(/|$)(.*)
                               $1     $2
Grupo $1:               /
Grupo $2:               users
rewrite-target: /$2  →  /users   ← path que recibe el backend
```

Sin rewrite, el backend recibiria `/api/v1/users` y retornaria 404 (no tiene esa ruta definida asi).

### 6.3: Probar path que no matchea

```bash
# /other no matchea /api/v1(...) → 404
curl -s -o /dev/null -w "%{http_code}" http://rewrite.lab/other
```

---

## Paso 7: Verificar desde Dentro del Cluster (5 min)

Los Services son accesibles por DNS dentro del cluster, independientemente del Ingress.

```bash
# Entrar al pod de prueba
kubectl exec -it test-tools -n lab-ingress -- sh
```

Dentro del pod:

```sh
# Acceder a Services directamente (sin pasar por Ingress)
curl -s http://frontend-svc
curl -s http://api-svc
curl -s http://admin-svc

# Verificar DNS
nslookup frontend-svc.lab-ingress.svc.cluster.local

exit
```

**Clave:** Ingress es para trafico EXTERNO. Dentro del cluster, los Pods se comunican directamente via Service DNS sin pasar por el Ingress Controller.

---

## Paso 8: TLS Termination - HTTPS (10 min)

**Que es HTTPS y TLS, en palabras simples:**
Cuando envias datos por HTTP, viajan en texto claro — como enviar una postal: cualquiera que la intercepte en el camino puede leerla. **HTTPS** (con TLS) es como meter esa postal en un sobre cerrado y sellado: el contenido queda cifrado y solo el destinatario puede leerlo.

**TLS** (Transport Layer Security) es el mecanismo tecnico que hace ese "sellado". Usa un **certificado digital** (un documento electronico que prueba la identidad del servidor) para establecer la comunicacion cifrada. Cuando ves el candado en tu navegador, significa que TLS esta activo.

En Kubernetes, la **TLS Termination** (o "terminacion de TLS") significa que el Ingress Controller se encarga de todo el cifrado/descifrado: recibe las peticiones HTTPS del cliente, las descifra, y las envia en HTTP plano al backend. Los Pods no necesitan saber nada de TLS — esa complejidad queda centralizada en un solo punto.

```
Cliente                Ingress Controller         Backend (Pod)
   |                         |                         |
   |──HTTPS (cifrado)────────>|                         |
   |                         |──HTTP (plano)───────────>|
   |                         |<──HTTP (plano)───────────|
   |<──HTTPS (cifrado)────────|                         |
```

Agregar HTTPS con certificado autofirmado. Este paso es manual porque la generacion de certificados es un concepto importante.

### 8.1: Generar certificado autofirmado

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt \
  -subj "/CN=secure.lab/O=Lab"
```

### 8.2: Crear Secret TLS

```bash
kubectl create secret tls tls-lab-secret \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key \
  -n lab-ingress

# Verificar
kubectl get secret tls-lab-secret -n lab-ingress
```

### 8.3: Crear Ingress con TLS

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-demo
  namespace: lab-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - secure.lab
    secretName: tls-lab-secret
  rules:
  - host: secure.lab
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-svc
            port:
              number: 80
EOF
```

### 8.4: Probar HTTPS

```bash
# HTTPS (ignorar cert autofirmado con -k)
curl -k https://secure.lab/

# Verificar redireccion HTTP → HTTPS
curl -I http://secure.lab/ 2>/dev/null | head -3
# Debe retornar: 308 Permanent Redirect
# Location: https://secure.lab/

# Ver detalles del certificado
curl -vk https://secure.lab/ 2>&1 | grep -E "subject:|issuer:|expire"
```

**Clave:** El Ingress Controller descifra HTTPS y envia HTTP plano al backend. Los backends no necesitan saber de TLS — esa complejidad se centraliza en un solo punto.

**Que aprendimos en este paso:**
- Un certificado TLS se almacena como un Secret en Kubernetes: tiene dos partes, el certificado publico (`tls.crt`) y la clave privada (`tls.key`).
- La anotacion `ssl-redirect: "true"` hace que el Ingress rechace HTTP y redirija automaticamente a HTTPS con un codigo `308 Permanent Redirect`.
- La bandera `-k` en `curl` indica "ignorar errores de certificado". En produccion se usan certificados firmados por una autoridad confiable (Let's Encrypt, DigiCert), no autofirmados.

---

## Tabla Comparativa de Patrones

```
┌────────────────────┬──────────────────┬──────────────────┬────────────────────┐
│ Patron             │ Se configura con │ Resuelve         │ Ejemplo            │
├────────────────────┼──────────────────┼──────────────────┼────────────────────┤
│ Path-Based Routing │ rules[].paths[]  │ Multiples apps   │ /app1 → svc-a      │
│                    │                  │ en un dominio    │ /app2 → svc-b      │
├────────────────────┼──────────────────┼──────────────────┼────────────────────┤
│ Host-Based Routing │ rules[].host     │ Multiples apps   │ a.com → svc-a      │
│                    │                  │ con dominios     │ b.com → svc-b      │
├────────────────────┼──────────────────┼──────────────────┼────────────────────┤
│ Canary Deployment  │ annotations:     │ Rollout gradual  │ 80% → v1           │
│                    │ canary + weight  │ de versiones     │ 20% → v2           │
├────────────────────┼──────────────────┼──────────────────┼────────────────────┤
│ Rate Limiting      │ annotations:     │ Proteccion DDoS  │ Max 5 req/seg      │
│                    │ limit-rps        │ y abuso          │ por IP cliente     │
├────────────────────┼──────────────────┼──────────────────┼────────────────────┤
│ URL Rewriting      │ annotations:     │ Prefijos de API  │ /api/v1/x → /x    │
│                    │ rewrite-target   │ y versionado     │                    │
├────────────────────┼──────────────────┼──────────────────┼────────────────────┤
│ TLS Termination    │ spec.tls +       │ HTTPS sin tocar  │ HTTPS → HTTP       │
│                    │ Secret TLS       │ los backends     │ en el backend      │
└────────────────────┴──────────────────┴──────────────────┴────────────────────┘
```

---

## Cuando Usar Cada Patron

| Situacion | Patron recomendado | Por que |
|-----------|-------------------|---------|
| Multiples microservicios, un dominio | Path-Based Routing | `/api`, `/web`, `/admin` en la misma IP |
| Cada equipo tiene su dominio | Host-Based Routing | `team-a.company.com`, `team-b.company.com` |
| Lanzar version nueva con riesgo minimo | Canary Deployment | Validar con 5-20% del trafico real |
| API publica expuesta a Internet | Rate Limiting | Proteger contra abuso y sobrecarga |
| API con versionado en URL | URL Rewriting | Eliminar `/api/v1` antes del backend |
| Cualquier servicio en produccion | TLS Termination | HTTPS es obligatorio en produccion |
| Multiples servicios HTTP en cloud | Ingress (vs LoadBalancer) | 1 IP publica vs N Load Balancers ($) |

---

## Resumen Visual: Service vs Ingress vs LoadBalancer

```
SIN INGRESS (1 LB por servicio = $$$):

  Internet → LoadBalancer-1 ($) → svc-frontend → Pods
  Internet → LoadBalancer-2 ($) → svc-api      → Pods
  Internet → LoadBalancer-3 ($) → svc-admin    → Pods

CON INGRESS (1 punto de entrada, N servicios):

                    ┌──────────┐
  Internet ────────→│ Ingress  │───→ svc-frontend → Pods
  (1 IP publica)    │Controller│───→ svc-api      → Pods
                    │ (NGINX)  │───→ svc-admin    → Pods
                    └──────────┘
                    Decide por host + path
```

---

## Limpieza (2 min)

```bash
chmod +x cleanup.sh
./cleanup.sh
```

O manualmente:

```bash
# Eliminar namespace (borra TODOS los recursos del lab)
kubectl delete namespace lab-ingress

# Eliminar Ingress TLS si lo creaste
kubectl delete ingress tls-demo -n lab-ingress 2>/dev/null

# Limpiar certificados
rm -f /tmp/tls.key /tmp/tls.crt

# Limpiar /etc/hosts
sudo sed -i '/\.lab$/d' /etc/hosts

# Opcional: deshabilitar addon de Ingress
# minikube addons disable ingress
```

---

## Checklist de Verificacion

- [ ] Minikube con addon ingress habilitado
- [ ] Path-based routing funciona (/frontend, /api)
- [ ] Host-based routing funciona (frontend.lab, api.lab)
- [ ] Canary deployment: 20%, 50%, 100%, rollback
- [ ] Rate limiting: 503 al exceder 5 rps
- [ ] URL rewriting: /api/v1/users → /users
- [ ] TLS: HTTPS funciona, HTTP redirige a HTTPS
- [ ] Diferencia entre acceso via Ingress y via Service DNS
