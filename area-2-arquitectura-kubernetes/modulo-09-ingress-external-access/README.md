# Módulo 09: Ingress y Acceso Externo

## Índice

1. [Introducción](#introducción)
2. [Conceptos Fundamentales](#conceptos-fundamentales)
3. [Relación Service, Ingress e Ingress Controller](#relación-service-ingress-e-ingress-controller)
4. [Ingress Controller](#ingress-controller)
5. [Recursos Ingress](#recursos-ingress)
6. [IngressClass](#ingressclass)
7. [Tipos de Routing](#tipos-de-routing)
8. [TLS y Certificados](#tls-y-certificados)
9. [Anotaciones de Ingress](#anotaciones-de-ingress)
10. [Patrones Avanzados](#patrones-avanzados)
11. [Arquitectura de Producción](#arquitectura-de-producción)
12. [Troubleshooting](#troubleshooting)
13. [Ejemplos Prácticos](#ejemplos-prácticos)
14. [Laboratorios](#laboratorios)
15. [Recursos Adicionales](#recursos-adicionales)

---

## Introducción

En Kubernetes, exponer aplicaciones al exterior puede hacerse de varias formas. Los **Services** permiten exponer Pods dentro o fuera del clúster, pero si necesitas **enrutar tráfico HTTP/HTTPS externo a diferentes servicios internos** según el dominio o la ruta, necesitas un recurso adicional: **Ingress**.

### ¿Qué es Ingress?

**Ingress** es un objeto de la API de Kubernetes que:
- Administra el **acceso externo HTTP/HTTPS** a los servicios en un clúster
- Proporciona **balanceo de carga**, **terminación SSL/TLS** y **hosting virtual basado en nombres**
- Define **reglas de enrutamiento** basadas en URIs, nombres de host y rutas
- Permite gestionar **múltiples aplicaciones** bajo una única IP pública

> **Nota sobre Gateway API**: A partir de Kubernetes 1.18+, el recurso Ingress está "congelado" (feature-frozen). Las nuevas características se añaden al **Gateway API** (sucesora de Ingress). Sin embargo, Ingress sigue siendo ampliamente usado y soportado.

### ¿Por qué usar Ingress?

**Antes de Ingress** (usando solo Services):
```
Internet → LoadBalancer Service → Pods (app1)
Internet → LoadBalancer Service → Pods (app2)
Internet → LoadBalancer Service → Pods (app3)
```
❌ Necesitas **múltiples LoadBalancers** (uno por aplicación)
❌ Costos elevados en cloud (cada LoadBalancer tiene costo)
❌ Configuración distribuida

**Con Ingress**:
```
Internet → Ingress Controller (1 LoadBalancer) 
    → Ingress Rules
        → Service app1 → Pods
        → Service app2 → Pods
        → Service app3 → Pods
```
✅ **Un solo punto de entrada** (1 LoadBalancer)
✅ Routing inteligente basado en host/path
✅ Terminación SSL/TLS centralizada
✅ Configuración declarativa

---

## Conceptos Fundamentales

### Terminología

| Concepto | Descripción |
|----------|-------------|
| **Ingress** | Recurso de Kubernetes que define reglas de enrutamiento HTTP/HTTPS |
| **Ingress Controller** | Componente (pod) que implementa las reglas de Ingress (ej: nginx, Traefik) |
| **IngressClass** | Recurso que identifica qué Ingress Controller debe procesar un Ingress |
| **Backend** | Servicio de Kubernetes al que se enruta el tráfico |
| **Default Backend** | Servicio que recibe tráfico cuando no coincide ninguna regla |
| **Path-based Routing** | Enrutamiento basado en la ruta URL (`/app1`, `/api`) |
| **Host-based Routing** | Enrutamiento basado en el hostname (`app1.example.com`) |
| **Terminación TLS** | Proceso de descifrar HTTPS en el Ingress Controller |

### Diagrama ASCII: Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS (443) / HTTP (80)
                         ▼
            ┌────────────────────────────┐
            │   Cloud LoadBalancer       │ ← Punto de entrada único
            │   (IP Pública: 203.0.113.5)│
            └────────────┬───────────────┘
                         │
                         │ HTTP/HTTPS
                         ▼
        ┌────────────────────────────────────┐
        │    Ingress Controller Pod          │
        │  (nginx/traefik/haproxy/etc.)      │
        │                                    │
        │  - Lee recursos Ingress            │
        │  - Aplica reglas de enrutamiento   │
        │  - Termina TLS/SSL                 │
        │  - Balancea carga                  │
        └──┬────────────┬────────────┬───────┘
           │            │            │
           │ Route 1    │ Route 2    │ Route 3
           │            │            │
  ┌────────▼────┐  ┌───▼─────┐  ┌──▼──────┐
  │ Service A   │  │Service B│  │Service C│
  │ ClusterIP   │  │ClusterIP│  │ClusterIP│
  └──┬──┬──┬───┘  └─┬──┬────┘  └─┬──┬────┘
     │  │  │        │  │          │  │
     ▼  ▼  ▼        ▼  ▼          ▼  ▼
  Pod Pod Pod    Pod Pod       Pod Pod
  (app1)         (app2)        (app3)
```

---

## Relación Service, Ingress e Ingress Controller

### Service

**Función**: Expone un conjunto de Pods con una IP estable (ClusterIP) y balancea tráfico entre ellos.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  selector:
    app: webapp
  ports:
    - port: 8080
      targetPort: 8080
  type: ClusterIP  # Accesible SOLO dentro del clúster
```

### Ingress

**Función**: Define **reglas de enrutamiento** (qué tráfico va a qué Service).

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
spec:
  rules:
  - host: webapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp  # Referencia al Service
            port:
              number: 8080
```

### Ingress Controller

**Función**: **Implementa** las reglas de Ingress. Es un pod que actúa como proxy inverso.

```bash
# Ejemplos populares de Ingress Controllers
- NGINX Ingress Controller (más usado)
- Traefik
- HAProxy Ingress
- Istio Ingress Gateway
- AWS ALB Ingress Controller
- GKE Ingress (GCE)
```

### Flujo de Tráfico Completo

```
1. Usuario hace petición: https://webapp.example.com/api

2. DNS resuelve: webapp.example.com → 203.0.113.5 (IP del LoadBalancer)

3. LoadBalancer enruta tráfico → Ingress Controller Pod

4. Ingress Controller:
   - Lee recurso Ingress
   - Coincide regla: host="webapp.example.com", path="/api"
   - Termina TLS (si HTTPS)
   - Enruta a Service "webapp" puerto 8080

5. Service "webapp":
   - Selecciona Pod con label app=webapp
   - Balancea entre Pods disponibles

6. Pod procesa petición y responde
```

---

## Ingress Controller

### Instalación con Helm (Nginx Ingress Controller)

El **Nginx Ingress Controller** es el más popular. Se instala como un Deployment en el clúster.

#### 1. Añadir repositorio Helm

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

#### 2. Instalar Ingress Controller

**Para entornos de desarrollo (Minikube, Kind, Docker Desktop)**:
```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClass=nginx
```

**Para entornos de producción (Cloud)**:
```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClass=nginx
```

#### 3. Verificar instalación

```bash
# Verificar pods del ingress controller
kubectl get pods -n ingress-nginx

# Verificar servicio (NodePort o LoadBalancer)
kubectl get svc -n ingress-nginx

# Verificar IngressClass creada
kubectl get ingressclass
```

### Componentes Instalados

```
ingress-nginx/
├── Deployment: ingress-nginx-controller
│   └── Pod: ejecuta nginx como proxy inverso
├── Service: ingress-nginx-controller
│   ├── Type: NodePort (desarrollo)
│   └── Type: LoadBalancer (producción)
└── IngressClass: nginx
    └── Identifica este controller
```

---

## Recursos Ingress

### Estructura Básica

Ver ejemplo completo: [`ejemplos/01-basico/ingress-minimal.yaml`](ejemplos/01-basico/ingress-minimal.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx  # Qué IngressController usar
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

### Campos Principales

| Campo | Descripción | Requerido |
|-------|-------------|-----------|
| `metadata.name` | Nombre único del Ingress | ✅ Sí |
| `metadata.annotations` | Configuración específica del controller | ❌ No |
| `spec.ingressClassName` | Qué IngressController procesa este Ingress | ⚠️ Recomendado |
| `spec.defaultBackend` | Service por defecto si no coincide ninguna regla | ❌ No |
| `spec.rules` | Reglas de enrutamiento (host, paths) | ✅ Sí |
| `spec.tls` | Configuración TLS/HTTPS | ❌ No |

### Reglas de Ingress

Una **regla** especifica:
1. **Host** (opcional): `foo.bar.com`, `*.example.com`
2. **Paths**: Lista de rutas con sus backends
   - `path`: Ruta URL (`/api`, `/app1`)
   - `pathType`: Tipo de coincidencia (Exact, Prefix, ImplementationSpecific)
   - `backend`: Service destino

#### Ejemplo de regla completa

Ver: [`ejemplos/02-routing/ingress-path-based.yaml`](ejemplos/02-routing/ingress-path-based.yaml)

```yaml
spec:
  rules:
  - host: myapp.example.com  # Host específico
    http:
      paths:
      - path: /api           # Ruta 1
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web           # Ruta 2
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

---

## IngressClass

### ¿Qué es IngressClass?

**IngressClass** es un recurso que identifica qué **Ingress Controller** debe procesar un recurso Ingress. Permite tener **múltiples controladores** en el mismo clúster.

### Ejemplo de IngressClass

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx
```

### Uso en Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  ingressClassName: nginx  # Usa el IngressClass "nginx"
  rules:
  - host: app.example.com
    # ...
```

### IngressClass por defecto

Puedes marcar una IngressClass como **predeterminada**:

```yaml
metadata:
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
```

Los Ingress **sin** `spec.ingressClassName` usarán el IngressClass predeterminado.

⚠️ **Precaución**: Si tienes **más de una** IngressClass marcada como predeterminada, la validación falla.

---

## Tipos de Routing

Kubernetes Ingress soporta dos tipos principales de enrutamiento:

### 1. Path-based Routing (Enrutamiento por Ruta)

Enruta tráfico basándose en la **ruta URL**.

#### Diagrama ASCII

```
https://myapp.com/
├── /api    → api-service:8080
├── /web    → web-service:80
└── /admin  → admin-service:9090
```

#### Ejemplo

Ver: [`ejemplos/02-routing/ingress-path-based.yaml`](ejemplos/02-routing/ingress-path-based.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

#### Tipos de PathType

| PathType | Comportamiento | Ejemplo |
|----------|----------------|---------|
| **Exact** | Coincidencia exacta (case-sensitive) | `/foo` ≠ `/foo/` |
| **Prefix** | Coincide con prefijo dividido por `/` | `/foo` = `/foo`, `/foo/`, `/foo/bar` |
| **ImplementationSpecific** | Depende del Ingress Controller | Varía según implementación |

#### Tabla de Coincidencias

| Tipo | Path Configurado | Request Path | ¿Coincide? |
|------|------------------|--------------|------------|
| Prefix | `/` | Cualquier path | ✅ Sí |
| Exact | `/foo` | `/foo` | ✅ Sí |
| Exact | `/foo` | `/bar` | ❌ No |
| Exact | `/foo` | `/foo/` | ❌ No |
| Prefix | `/foo` | `/foo`, `/foo/` | ✅ Sí |
| Prefix | `/foo` | `/foo/bar` | ✅ Sí |
| Prefix | `/aaa/bbb` | `/aaa/bbbxyz` | ❌ No |

### 2. Host-based Routing (Enrutamiento por Host)

Enruta tráfico basándose en el **hostname** (virtual hosting).

#### Diagrama ASCII

```
Internet
├── app1.example.com  → service1:80
├── app2.example.com  → service2:80
└── api.example.com   → api-service:8080
```

#### Ejemplo

Ver: [`ejemplos/02-routing/ingress-host-based.yaml`](ejemplos/02-routing/ingress-host-based.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

### 3. Routing Combinado (Host + Path)

Puedes combinar ambos tipos:

```yaml
rules:
- host: api.example.com
  http:
    paths:
    - path: /v1
      pathType: Prefix
      backend:
        service:
          name: api-v1
          port:
            number: 8080
    - path: /v2
      pathType: Prefix
      backend:
        service:
          name: api-v2
          port:
            number: 8080
```

### 4. Wildcard Hosts

Soporta **hosts comodín** (wildcards):

```yaml
rules:
- host: "*.foo.com"  # Coincide: bar.foo.com, test.foo.com
  http:
    paths:
    - path: /
      pathType: Prefix
      backend:
        service:
          name: wildcard-service
          port:
            number: 80
```

#### Tabla de Coincidencias de Wildcard

| Host Configurado | Request Host | ¿Coincide? | Razón |
|------------------|--------------|------------|-------|
| `*.foo.com` | `bar.foo.com` | ✅ Sí | Sufijo común |
| `*.foo.com` | `baz.bar.foo.com` | ❌ No | Wildcard cubre solo 1 etiqueta DNS |
| `*.foo.com` | `foo.com` | ❌ No | Wildcard requiere etiqueta adicional |

---

## TLS y Certificados

### Terminación TLS en Ingress

El **Ingress Controller** puede:
- **Terminar TLS** (descifrar HTTPS)
- **Servir certificados** almacenados en Secrets
- Enrutar tráfico **en texto plano** a los Services internos

#### Diagrama ASCII: Flujo TLS

```
Cliente (HTTPS)
    ↓
    │ TLS encriptado
    ▼
Ingress Controller
    │ Usa certificado del Secret
    │ Descifra TLS
    ▼
    │ HTTP texto plano
    ▼
Service → Pod
```

### Secret TLS

Los certificados se almacenan en **Secrets de tipo `kubernetes.io/tls`**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi...  # Certificado (base64)
  tls.key: LS0tLS1CRUdJTi...  # Clave privada (base64)
```

### Crear Secret TLS desde archivos

```bash
# Generar certificado autofirmado (desarrollo)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=app.example.com/O=MyOrg"

# Crear Secret en Kubernetes
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key
```

### Ingress con TLS

Ver: [`ejemplos/03-tls/ingress-tls-single-host.yaml`](ejemplos/03-tls/ingress-tls-single-host.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: tls-secret  # Referencia al Secret
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

### TLS con Múltiples Hosts

Ver: [`ejemplos/03-tls/ingress-tls-multi-host.yaml`](ejemplos/03-tls/ingress-tls-multi-host.yaml)

```yaml
spec:
  tls:
  - hosts:
    - app1.example.com
    - app2.example.com
    secretName: multi-host-tls  # Certificado wildcard o SAN
  rules:
  - host: app1.example.com
    # ...
  - host: app2.example.com
    # ...
```

⚠️ **Importante**: El certificado debe incluir todos los hosts en **Subject Alternative Names (SAN)** o usar un **wildcard** (`*.example.com`).

---

## Anotaciones de Ingress

Las **anotaciones** permiten configuración específica del Ingress Controller. Las anotaciones varían según el controller (nginx, traefik, etc.).

### Anotaciones Comunes (Nginx Ingress Controller)

Ver documentación completa: [Nginx Ingress Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)

| Anotación | Descripción | Ejemplo |
|-----------|-------------|---------|
| `nginx.ingress.kubernetes.io/rewrite-target` | Reescribe la URL antes de enviarla al backend | `rewrite-target: /` |
| `nginx.ingress.kubernetes.io/ssl-redirect` | Fuerza redirección HTTP → HTTPS | `ssl-redirect: "true"` |
| `nginx.ingress.kubernetes.io/affinity` | Sticky sessions (sesiones persistentes) | `affinity: "cookie"` |
| `nginx.ingress.kubernetes.io/rate-limit` | Límite de peticiones por IP | `limit-rps: "10"` |
| `nginx.ingress.kubernetes.io/whitelist-source-range` | Restricción por IP | `whitelist-source-range: "10.0.0.0/8"` |
| `nginx.ingress.kubernetes.io/canary` | Canary deployments | `canary: "true"` |
| `nginx.ingress.kubernetes.io/cors-allow-origin` | CORS headers | `cors-allow-origin: "*"` |

### Ejemplo: Rewrite Target

Ver: [`ejemplos/04-annotations/ingress-rewrite.yaml`](ejemplos/04-annotations/ingress-rewrite.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rewrite-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

**Comportamiento**:
- Request: `https://app.example.com/api/users`
- Reenviado al backend como: `http://api-service:8080/users`

### Ejemplo: Sticky Sessions

Ver: [`ejemplos/04-annotations/ingress-sticky-sessions.yaml`](ejemplos/04-annotations/ingress-sticky-sessions.yaml)

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "route"
    nginx.ingress.kubernetes.io/session-cookie-expires: "172800"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "172800"
```

### Ejemplo: Rate Limiting

Ver: [`ejemplos/04-annotations/ingress-rate-limit.yaml`](ejemplos/04-annotations/ingress-rate-limit.yaml)

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"
```

---

## Patrones Avanzados

### 1. Default Backend

Servicio que recibe tráfico cuando **no coincide ninguna regla**:

```yaml
spec:
  defaultBackend:
    service:
      name: default-http-backend
      port:
        number: 80
  rules:
  - host: app.example.com
    # ...
```

### 2. Canary Deployments

Enruta un **porcentaje del tráfico** a una versión canary:

Ver: [`ejemplos/05-avanzado/ingress-canary.yaml`](ejemplos/05-avanzado/ingress-canary.yaml)

```yaml
# Ingress principal (versión estable)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v1
            port:
              number: 80
---
# Ingress canary (versión nueva)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "20"  # 20% del tráfico
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v2
            port:
              number: 80
```

### 3. Blue-Green Deployments

Cambio instantáneo entre versiones modificando el Ingress:

```bash
# Estado actual: apuntando a "blue"
kubectl patch ingress myapp -p '{"spec":{"rules":[{"host":"app.example.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"app-blue","port":{"number":80}}}}]}}]}}'

# Cambio a "green"
kubectl patch ingress myapp -p '{"spec":{"rules":[{"host":"app.example.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"app-green","port":{"number":80}}}}]}}]}}'
```

### 4. Múltiples Ingress Controllers

Puedes tener varios controllers en el mismo clúster:

```yaml
# IngressClass para nginx
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
---
# IngressClass para traefik
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: traefik
spec:
  controller: traefik.io/ingress-controller
---
# Ingress usando nginx
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-nginx
spec:
  ingressClassName: nginx  # Usa nginx controller
  # ...
---
# Ingress usando traefik
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-traefik
spec:
  ingressClassName: traefik  # Usa traefik controller
  # ...
```

---

## Arquitectura de Producción

### Componentes en Producción

```
┌──────────────────────────────────────────────┐
│              INTERNET                        │
└────────────────┬─────────────────────────────┘
                 │
                 ▼
       ┌─────────────────────┐
       │  Cloud LoadBalancer │ ← Alta disponibilidad
       │  (AWS ALB/NLB)      │    IP pública estable
       └──────────┬──────────┘
                  │
    ┌─────────────┴─────────────┐
    │                           │
    ▼                           ▼
┌─────────────┐          ┌─────────────┐
│ Ingress     │          │ Ingress     │ ← Múltiples réplicas
│ Controller  │          │ Controller  │    (HA)
│ Pod 1       │          │ Pod 2       │
└──────┬──────┘          └──────┬──────┘
       │                        │
       │    ┌───────────────────┘
       │    │
       ▼    ▼
    ┌──────────────┐
    │   Services   │ ← ClusterIP
    │ (ClusterIP)  │
    └───────┬──────┘
            │
    ┌───────┴────────────┬──────────┐
    ▼                    ▼          ▼
┌────────┐          ┌────────┐  ┌────────┐
│ Pod    │          │ Pod    │  │ Pod    │ ← Application Pods
│ App 1  │          │ App 2  │  │ App 3  │
└────────┘          └────────┘  └────────┘
```

### Alta Disponibilidad (HA)

#### 1. Múltiples réplicas del Ingress Controller

```bash
helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.replicaCount=3 \  # Mínimo 3 réplicas
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=128Mi
```

#### 2. Pod Anti-affinity

Distribuir pods en diferentes nodos:

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app.kubernetes.io/name
          operator: In
          values:
          - ingress-nginx
      topologyKey: kubernetes.io/hostname
```

#### 3. PodDisruptionBudget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ingress-nginx-pdb
  namespace: ingress-nginx
spec:
  minAvailable: 2  # Siempre al menos 2 pods disponibles
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
```

### Monitoreo y Observabilidad

#### 1. Métricas de Prometheus

El nginx ingress controller expone métricas en formato Prometheus:

```bash
# Endpoint de métricas (dentro del pod)
curl http://localhost:10254/metrics
```

**Métricas clave**:
- `nginx_ingress_controller_requests`: Total de peticiones
- `nginx_ingress_controller_request_duration_seconds`: Latencia
- `nginx_ingress_controller_response_duration_seconds`: Duración de respuestas
- `nginx_ingress_controller_ssl_expire_time_seconds`: Expiración de certificados

#### 2. Logs

```bash
# Ver logs del ingress controller
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller -f

# Ver logs de peticiones específicas
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller | grep "app.example.com"
```

### Seguridad

#### 1. Restricción de IPs

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,192.168.1.0/24"
```

#### 2. Autenticación Básica

```bash
# Crear archivo htpasswd
htpasswd -c auth admin

# Crear Secret
kubectl create secret generic basic-auth --from-file=auth

# Usar en Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

#### 3. CORS Headers

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://example.com"
```

---

## Troubleshooting

### Problemas Comunes

#### 1. Ingress no funciona (404 Not Found)

**Síntomas**: Peticiones retornan 404

**Diagnóstico**:
```bash
# Verificar que el Ingress existe
kubectl get ingress

# Verificar eventos del Ingress
kubectl describe ingress <nombre>

# Verificar que el Service existe
kubectl get svc <service-name>

# Verificar endpoints del Service
kubectl get endpoints <service-name>

# Ver logs del ingress controller
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller
```

**Causas comunes**:
- ❌ IngressClass incorrecta o faltante
- ❌ Service no existe
- ❌ Service sin Pods (endpoints vacíos)
- ❌ Selector del Service no coincide con labels de Pods

#### 2. Error de certificado TLS

**Síntomas**: "ERR_CERT_AUTHORITY_INVALID" en navegador

**Diagnóstico**:
```bash
# Verificar Secret TLS
kubectl get secret tls-secret -o yaml

# Verificar certificado
kubectl get secret tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Verificar fecha de expiración
kubectl get secret tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -enddate -noout
```

**Soluciones**:
- ✅ Usar certificado válido de CA confiable (Let's Encrypt, cert-manager)
- ✅ Verificar que el CN/SAN coincide con el hostname
- ✅ Para desarrollo: usar `-k` en curl o aceptar certificado autofirmado

#### 3. Ingress no obtiene IP externa

**Síntomas**: `ADDRESS` vacío en `kubectl get ingress`

```bash
kubectl get ingress
# NAME       CLASS   HOSTS             ADDRESS   PORTS   AGE
# myingress  nginx   app.example.com             80      5m
```

**Diagnóstico**:
```bash
# Verificar servicio del ingress controller
kubectl get svc -n ingress-nginx

# Verificar si el LoadBalancer obtuvo IP externa
kubectl get svc -n ingress-nginx nginx-ingress-controller
```

**Causas comunes**:
- ❌ Cloud provider no soporta LoadBalancer (minikube, kind)
- ❌ Cuota de LoadBalancers excedida en cloud
- ❌ Permisos insuficientes para crear LoadBalancers

**Soluciones**:
- ✅ En desarrollo: usar `NodePort` y acceder via `<node-ip>:<nodeport>`
- ✅ En cloud: verificar permisos y cuotas

#### 4. Rewrite no funciona

**Síntomas**: Peticiones llegan al Pod con path incorrecto

**Solución**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2  # Captura grupo 2
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api(/|$)(.*)  # Regex con grupos de captura
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

### Comandos Útiles

```bash
# Listar todos los Ingress en el clúster
kubectl get ingress --all-namespaces

# Ver detalles de un Ingress
kubectl describe ingress <nombre>

# Ver configuración YAML del Ingress
kubectl get ingress <nombre> -o yaml

# Editar Ingress en tiempo real
kubectl edit ingress <nombre>

# Eliminar Ingress
kubectl delete ingress <nombre>

# Ver logs del ingress controller
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller -f

# Obtener configuración nginx generada (dentro del pod)
kubectl exec -n ingress-nginx deployment/nginx-ingress-controller -- cat /etc/nginx/nginx.conf

# Recargar configuración del ingress controller
kubectl rollout restart deployment -n ingress-nginx nginx-ingress-controller

# Ver métricas del ingress controller
kubectl port-forward -n ingress-nginx svc/nginx-ingress-controller-metrics 10254:10254
curl http://localhost:10254/metrics

# Verificar conectividad desde un pod temporal
kubectl run test-curl --image=curlimages/curl -it --rm -- sh
# Dentro del pod:
curl -H "Host: app.example.com" http://nginx-ingress-controller.ingress-nginx.svc.cluster.local
```

---

## Ejemplos Prácticos

### Estructura de Ejemplos

Los ejemplos están organizados en las siguientes categorías:

```
ejemplos/
├── 01-basico/
│   ├── ingress-minimal.yaml
│   └── deployment-apps-test.yaml
├── 02-routing/
│   ├── ingress-path-based.yaml
│   ├── ingress-host-based.yaml
│   └── ingress-wildcard-host.yaml
├── 03-tls/
│   ├── ingress-tls-single-host.yaml
│   ├── ingress-tls-multi-host.yaml
│   └── secret-tls-example.yaml
├── 04-annotations/
│   ├── ingress-rewrite.yaml
│   ├── ingress-sticky-sessions.yaml
│   ├── ingress-rate-limit.yaml
│   └── ingress-whitelist-ip.yaml
├── 05-avanzado/
│   ├── ingress-canary.yaml
│   ├── ingress-auth-basic.yaml
│   └── ingress-cors.yaml
├── 06-produccion/
│   ├── ingress-multi-app-production.yaml
│   └── ingress-monitoring.yaml
└── README.md
```

Ver índice completo: [`ejemplos/README.md`](ejemplos/README.md)

### Ejemplos Inline

#### Ejemplo 1: Ingress Básico

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

#### Ejemplo 2: Host-based Routing

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 8080
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 8080
```

#### Ejemplo 3: TLS con HTTPS

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
            name: secure-app
            port:
              number: 443
```

---

## Laboratorios

Los laboratorios prácticos están diseñados con **dificultad progresiva**:

### Lab 01: Fundamentos de Ingress (40-45 min)

**Nivel**: Básico

**Objetivos**:
- Instalar nginx ingress controller con Helm
- Crear deployments de prueba (app1, app2)
- Configurar Ingress con path-based routing
- Configurar Ingress con host-based routing
- Verificar funcionamiento con curl
- Configurar DNS local con `/etc/hosts`

📄 Ver laboratorio completo: [`laboratorios/lab-01-ingress-basico.md`](laboratorios/lab-01-ingress-basico.md)

### Lab 02: Ingress con TLS y Configuraciones Avanzadas (50-60 min)

**Nivel**: Intermedio

**Objetivos**:
- Generar certificados autofirmados con openssl
- Crear Secrets TLS en Kubernetes
- Configurar Ingress con HTTPS
- Implementar múltiples hosts con TLS
- Usar anotaciones de nginx (rewrite, CORS)
- Verificar TLS con curl y openssl
- Troubleshooting de certificados

📄 Ver laboratorio completo: [`laboratorios/lab-02-ingress-tls-avanzado.md`](laboratorios/lab-02-ingress-tls-avanzado.md)

### Lab 03: Ingress en Producción (60-70 min)

**Nivel**: Avanzado

**Objetivos**:
- Arquitectura multi-app con ingress
- Implementar canary deployments
- Configurar rate limiting y throttling
- Whitelist de IPs
- Sticky sessions (sesión persistente)
- Monitoreo con Prometheus/Grafana
- Alta disponibilidad del ingress controller
- Integración con LoadBalancer en cloud
- Best practices de producción

📄 Ver laboratorio completo: [`laboratorios/lab-03-ingress-produccion.md`](laboratorios/lab-03-ingress-produccion.md)

---

## Recursos Adicionales

### Documentación Oficial

- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Ingress Controllers List](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- [Gateway API (successor of Ingress)](https://kubernetes.io/docs/concepts/services-networking/gateway/)

### Tutoriales Recomendados

- [Curso Kubernetes by Pabpereza](https://pabpereza.dev/docs/cursos/kubernetes/ingress_controller_en_kubernetes)
- [Ingress Nginx Examples](https://github.com/kubernetes/ingress-nginx/tree/main/docs/examples)
- [TLS with cert-manager](https://cert-manager.io/docs/usage/ingress/)

### Herramientas

| Herramienta | Descripción | Uso |
|-------------|-------------|-----|
| **cert-manager** | Gestión automática de certificados TLS (Let's Encrypt) | Certificados en producción |
| **external-dns** | Actualización automática de DNS basado en Ingress | Sincronización DNS |
| **k9s** | CLI interactiva para Kubernetes | Gestión y troubleshooting |
| **kubectx/kubens** | Cambio rápido de contextos/namespaces | Productividad |

### Comparación de Ingress Controllers

| Controller | Ventajas | Desventajas | Mejor para |
|------------|----------|-------------|------------|
| **Nginx Ingress** | Más usado, documentación extensa, estable | Configuración compleja | General purpose |
| **Traefik** | Auto-discovery, dashboard UI, fácil setup | Menos maduro que nginx | Microservicios |
| **HAProxy Ingress** | Alto rendimiento, WAF integrado | Menor comunidad | Alta carga |
| **Istio Ingress** | Service mesh, observabilidad avanzada | Complejo, overhead | Microservicios enterprise |
| **Kong Ingress** | API Gateway features, plugins | Licencia comercial para features | APIs |
| **AWS ALB Ingress** | Integración nativa AWS | Solo AWS | AWS EKS |
| **GCE Ingress** | Integración nativa GCP | Solo GCP | GKE |

### Checklist de Producción

✅ **Seguridad**:
- [ ] Todos los Ingress usan HTTPS (TLS)
- [ ] Certificados de CA confiable (Let's Encrypt con cert-manager)
- [ ] Rate limiting configurado
- [ ] Whitelist de IPs para endpoints sensibles
- [ ] Autenticación básica o OAuth para admin

✅ **Alta Disponibilidad**:
- [ ] Mínimo 3 réplicas del ingress controller
- [ ] PodDisruptionBudget configurado
- [ ] Pod anti-affinity (distribución en nodos)
- [ ] Resource requests/limits definidos
- [ ] HPA (Horizontal Pod Autoscaler) si es necesario

✅ **Monitoreo**:
- [ ] Métricas de Prometheus habilitadas
- [ ] Dashboards de Grafana creados
- [ ] Alertas configuradas (certificados expirados, errores 5xx)
- [ ] Logs centralizados (ELK, Loki)

✅ **Rendimiento**:
- [ ] Connection pooling configurado
- [ ] Timeouts apropiados
- [ ] Buffer sizes optimizados
- [ ] Compresión gzip habilitada

✅ **Gestión**:
- [ ] IngressClass definida explícitamente
- [ ] Anotaciones documentadas
- [ ] Naming conventions consistentes
- [ ] GitOps para control de versiones

---

## Conclusión

En este módulo has aprendido:

✅ **Conceptos fundamentales** de Ingress, IngressController e IngressClass
✅ **Instalación** del nginx ingress controller con Helm
✅ **Routing** basado en path y host
✅ **TLS/HTTPS** con Secrets de Kubernetes
✅ **Anotaciones** para configuraciones avanzadas (rewrite, rate limiting, sticky sessions)
✅ **Patrones avanzados** (canary, blue-green, múltiples controllers)
✅ **Arquitectura de producción** con alta disponibilidad y monitoreo
✅ **Troubleshooting** de problemas comunes

### Próximos Pasos

1. **Práctica**: Completa los 3 laboratorios en orden de dificultad
2. **Certificados**: Explora **cert-manager** para certificados automáticos
3. **Gateway API**: Investiga la nueva [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/) (sucesora de Ingress)
4. **Service Mesh**: Aprende sobre **Istio** o **Linkerd** para casos avanzados
5. **Módulo 10**: Continúa con **Namespaces y Organización**

---

**📚 Navegación del Curso**:
- ⬅️ Anterior: [Módulo 08 - Services y Endpoints](../modulo-08-services-endpoints/README.md)
- ➡️ Siguiente: [Módulo 10 - Namespaces y Organización](../modulo-10-namespaces-organizacion/README.md)
- 🏠 [Volver al índice del curso](../../README.md)

---

**Autor**: Curso Kubernetes Avanzado  
**Última actualización**: Noviembre 2025  
**Versión**: Kubernetes 1.28+
