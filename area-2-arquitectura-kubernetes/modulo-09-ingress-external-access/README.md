# Módulo 09: Ingress y Acceso Externo

> **Gestión inteligente de tráfico HTTP/HTTPS externo hacia servicios internos de Kubernetes**

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

### 🎯 Fundamentos
- Explicar la diferencia entre Services (NodePort/LoadBalancer) e Ingress
- Comprender la arquitectura de 3 componentes: Ingress Resource, Ingress Controller e IngressClass
- Entender por qué Ingress reduce costos en cloud (1 LoadBalancer vs N LoadBalancers)
- Diferenciar entre path-based routing y host-based routing

### 🔧 Técnicos
- Instalar y configurar nginx ingress controller en minikube
- Crear recursos Ingress con reglas de enrutamiento por path y hostname
- Configurar terminación TLS/HTTPS con Secrets de Kubernetes
- Usar anotaciones para funcionalidades avanzadas (rewrite, rate limiting, sticky sessions)
- Diagnosticar y resolver problemas comunes de Ingress

### 🚀 Avanzados
- Implementar canary deployments con weights (división de tráfico)
- Configurar múltiples Ingress Controllers en el mismo cluster
- Diseñar arquitecturas de producción con alta disponibilidad
- Integrar con cert-manager para certificados automáticos
- Optimizar performance y seguridad con best practices

### 💼 Profesionales
- Aplicar patrones de producción para multi-tenancy
- Implementar estrategias de blue-green deployments
- Configurar monitoreo y alertas de Ingress
- Evaluar y seleccionar Ingress Controllers según casos de uso
- Migrar de Ingress a Gateway API

---

## ✅ Prerequisites

Antes de comenzar este módulo, debes:

- ✅ **Módulos completados**:
  - Módulo 08: Services y Endpoints (ClusterIP, NodePort, LoadBalancer)
  - Módulo 07: Deployments y Rollouts
  - Módulo 05: Gestión de Pods

- ✅ **Conocimientos**:
  - Cómo funcionan Services de tipo ClusterIP, NodePort y LoadBalancer
  - Conceptos de DNS y dominios
  - Básicos de HTTP/HTTPS y certificados TLS
  - Conceptos de reverse proxy y load balancing

- ✅ **Herramientas**:
  ```bash
  # Verificar que tienes kubectl
  kubectl version --client
  
  # Verificar minikube funcionando
  minikube status
  
  # Verificar Helm instalado (para instalar ingress controller)
  helm version
  
  # Si no tienes Helm:
  # curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  ```

- ✅ **Entorno**:
  - Minikube corriendo con driver docker
  - Cluster con al menos 2 CPUs y 4GB RAM
  - Addons: `ingress` (lo instalaremos en el módulo)

---

## 🗺️ Estructura del Módulo

| Sección | Tema | Duración | Tipo |
|---------|------|----------|------|
| **1-3** | Introducción y Conceptos Fundamentales | 30 min | Teoría |
| **4** | Ingress Controller (Instalación) | 20 min | Práctica |
| **5-7** | Recursos Ingress y Routing | 45 min | Teoría + Ejemplos |
| **Lab 1** | [Ingress Básico](laboratorios/lab-01-ingress-basico.md) | 40 min | 🧪 Laboratorio |
| **8** | TLS y Certificados | 30 min | Teoría + Ejemplos |
| **9-10** | Anotaciones y Patrones Avanzados | 40 min | Teoría + Ejemplos |
| **Lab 2** | [TLS y Configuraciones Avanzadas](laboratorios/lab-02-ingress-tls-avanzado.md) | 50 min | 🧪 Laboratorio |
| **11-12** | Arquitectura de Producción y Troubleshooting | 30 min | Teoría |
| **Lab 3** | [Ingress en Producción](laboratorios/lab-03-ingress-produccion.md) | 60 min | 🧪 Laboratorio |
| **Total** | | **5.5 horas** | |

---

## 📚 Guía de Estudio

### Para Principiantes (3 días)
**Día 1**: Conceptos fundamentales + Instalación de nginx ingress
- Secciones 1-4
- Entender por qué Ingress es necesario
- Instalar nginx ingress controller en minikube

**Día 2**: Routing y TLS
- Secciones 5-8
- Practicar path-based y host-based routing
- Configurar HTTPS con certificados
- Lab 1: Ingress Básico

**Día 3**: Avanzado y Producción
- Secciones 9-12
- Anotaciones y patrones avanzados
- Lab 2 y Lab 3

### Para Experimentados (1.5 días)
**Sesión 1**: Fundamentos y Routing (2 horas)
- Secciones 1-7 (lectura rápida)
- Enfoque en diferencias con Services
- Lab 1

**Sesión 2**: TLS, Anotaciones y Producción (3 horas)
- Secciones 8-12
- Foco en patrones avanzados
- Lab 2 y Lab 3

### Para Preparación de Certificación (enfoque CKA/CKAD)
- ⚡ Secciones 5, 7, 8 (creación de Ingress resources)
- ⚡ TLS con Secrets (sección 8)
- ⚡ Troubleshooting (sección 12)
- ⚡ Labs 1 y 2

---

## 📁 Organización de Recursos

```
modulo-09-ingress-external-access/
├── README.md                          # ← Estás aquí
├── RESUMEN-MODULO.md                  # Guía de estudio condensada
│
├── ejemplos/                          # Ejemplos por tema
│   ├── 01-basico/                    # Ingress básico
│   ├── 02-routing/                   # Path y host-based routing
│   ├── 03-tls/                       # HTTPS y certificados
│   ├── 04-annotations/               # Anotaciones avanzadas
│   ├── 05-avanzado/                  # Canary, blue-green
│   └── 06-produccion/                # Configuraciones de producción
│
└── laboratorios/                      # Labs prácticos guiados
    ├── lab-01-ingress-basico.md      # 40 min - Routing básico
    ├── lab-02-ingress-tls-avanzado.md # 50 min - TLS + anotaciones
    └── lab-03-ingress-produccion.md  # 60 min - HA + monitoreo
```

---

## 🎓 Metodología de Aprendizaje

Este módulo sigue el patrón **Teoría → Ejemplo Inline → Checkpoint → Laboratorio**:

1. **Teoría**: Conceptos explicados con diagramas ASCII
2. **Ejemplos inline**: YAMLs de ejemplo en `ejemplos/` referenciados inmediatamente
3. **Checkpoints**: Autoevaluaciones para verificar comprensión
4. **Laboratorios**: Ejercicios prácticos guiados paso a paso

**💡 Tip**: Crea los YAMLs de ejemplo a medida que avanzas. No copies-pegues todo al inicio.

---

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

## ✅ Checkpoint 1: Conceptos Fundamentales de Ingress

Antes de continuar, verifica tu comprensión de los conceptos básicos:

### Preguntas de Autoevaluación

<details>
<summary>1. ¿Cuál es la principal ventaja de usar Ingress en lugar de múltiples Services de tipo LoadBalancer?</summary>

**Respuesta**:

**Ventaja principal: Reducción de costos y complejidad**

- **Sin Ingress** (N LoadBalancers):
  - Cada aplicación necesita su propio LoadBalancer Service
  - En cloud providers, cada LoadBalancer tiene un costo mensual (~$15-30/mes cada uno)
  - Con 10 aplicaciones = 10 LoadBalancers = $150-300/mes solo en balanceadores
  - Gestión distribuida: 10 IPs diferentes que administrar

- **Con Ingress** (1 LoadBalancer):
  - 1 solo LoadBalancer delante del Ingress Controller
  - Todas las aplicaciones comparten la misma IP pública
  - Routing inteligente basado en hostname o path
  - Ahorro: $135-270/mes con 10 aplicaciones
  - Gestión centralizada: configuración declarativa en recursos Ingress

**Otras ventajas**:
- Terminación TLS/HTTPS centralizada (certificados en un solo lugar)
- Configuraciones avanzadas (rate limiting, redirects, rewrite) en un punto
- Mejor observabilidad (logs y métricas centralizados)

</details>

<details>
<summary>2. ¿Cuál es la diferencia entre un "Ingress" (resource) y un "Ingress Controller"?</summary>

**Respuesta**:

Son dos componentes diferentes que trabajan juntos:

**Ingress (Resource)**:
- Es un objeto de la API de Kubernetes (tipo: `kind: Ingress`)
- Define **reglas de enrutamiento** declarativas (YAML)
- Especifica: qué hostnames, paths y servicios backend
- **No ejecuta nada por sí mismo** (es solo configuración)
- Ejemplo: "Envía tráfico de `app.example.com/api` al `api-service`"

**Ingress Controller**:
- Es un **Pod/Deployment** que corre en el cluster
- **Implementa** las reglas definidas en los recursos Ingress
- Es un reverse proxy real (nginx, Traefik, HAProxy, etc.)
- **Lee** todos los Ingress resources y configura el proxy
- **Recibe** el tráfico externo y lo enruta según las reglas

**Analogía**:
- **Ingress** = Receta de cocina (instrucciones)
- **Ingress Controller** = Cocinero (quien ejecuta la receta)

**En código**:
```yaml
# Ingress Resource (configuración)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

```bash
# Ingress Controller (Pod en ejecución)
kubectl get pods -n ingress-nginx
# NAME                                   READY   STATUS
# ingress-nginx-controller-xxx-xxx       1/1     Running
```

</details>

<details>
<summary>3. ¿Qué tipos de enrutamiento soporta Ingress?</summary>

**Respuesta**:

Ingress soporta **2 tipos principales** de enrutamiento:

**1. Host-based Routing (Enrutamiento por hostname)**:
- Enruta según el **dominio** en la petición HTTP
- Usa: Virtual hosting (múltiples apps en la misma IP)

```yaml
rules:
- host: app1.example.com    # → service1
- host: app2.example.com    # → service2
- host: api.example.com     # → api-service
```

**Caso de uso**: Diferentes aplicaciones con sus propios dominios.

**2. Path-based Routing (Enrutamiento por ruta/path)**:
- Enruta según la **ruta URL** en la petición
- Usa: Dividir funcionalidades de una app

```yaml
rules:
- http:
    paths:
    - path: /api      # → api-service
    - path: /web      # → web-service
    - path: /admin    # → admin-service
```

**Caso de uso**: Microservicios accesibles desde diferentes paths.

**Combinación** (host + path):
```yaml
rules:
- host: myapp.example.com
  http:
    paths:
    - path: /api          # → api-service
    - path: /frontend     # → web-service
```

**Tipos de PathType**:
- `Exact`: Coincidencia exacta (`/foo` ≠ `/foo/`)
- `Prefix`: Prefijo (`/foo` = `/foo`, `/foo/`, `/foo/bar`)
- `ImplementationSpecific`: Depende del controller

</details>

<details>
<summary>4. ¿Por qué necesitas un Service ClusterIP detrás de un Ingress si el Ingress ya enruta al Pod?</summary>

**Respuesta**:

**Ingress NO enruta directamente a Pods**, siempre enruta a **Services**.

**Razones arquitectónicas**:

1. **Abstracción y estabilidad**:
   - Pods son efímeros (sus IPs cambian)
   - Services proporcionan una IP estable
   - Ingress apunta a algo estable (Service), no a IPs cambiantes

2. **Balanceo de carga automático**:
   - Service balancea entre múltiples réplicas del Pod
   - Service mantiene Endpoints actualizados dinámicamente
   - Ingress delega el balanceo interno al Service

3. **Separación de responsabilidades**:
   - **Ingress**: Routing L7 (HTTP/HTTPS), virtual hosting, TLS
   - **Service**: Balanceo L4 (TCP/UDP), service discovery, health checks

**Flujo completo**:
```
Internet (HTTPS)
    ↓
LoadBalancer (IP pública)
    ↓
Ingress Controller Pod (nginx)
    ↓ (lee reglas de Ingress resource)
Service ClusterIP (IP interna estable: 10.96.0.50)
    ↓ (balancea entre Pods)
Pods backend (IPs efímeras: 10.1.2.3, 10.1.2.4, 10.1.2.5)
```

**YAML típico**:
```yaml
# Service (requerido)
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  type: ClusterIP  # Interno
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
---
# Ingress (apunta al Service, no a Pods)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service  # ← Service, NO Pods
            port:
              number: 80
```

**Sin Service**: Tendrías que actualizar manualmente el Ingress cada vez que cambian las IPs de los Pods → imposible de mantener.

</details>

### 🧪 Ejercicio Rápido

**Escenario**: Tienes 3 aplicaciones web que quieres exponer:
- Blog: `blog.mycompany.com`
- API: `api.mycompany.com`
- Admin: `admin.mycompany.com`

**Pregunta**: ¿Cuántos LoadBalancers de cloud necesitas?
- A) 3 LoadBalancers (1 por aplicación)
- B) 1 LoadBalancer (con Ingress)
- C) 0 LoadBalancers (uso NodePort)

<details>
<summary>Ver Respuesta</summary>

**Respuesta correcta: B) 1 LoadBalancer (con Ingress)**

**Arquitectura**:
```
                    Internet
                       ↓
    1 LoadBalancer (IP: 203.0.113.5)
                       ↓
          Ingress Controller
         /        |        \
blog.*.com   api.*.com   admin.*.com
    ↓            ↓            ↓
blog-svc     api-svc      admin-svc
    ↓            ↓            ↓
blog-pods    api-pods    admin-pods
```

**Ingress YAML**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: company-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: blog.mycompany.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
  - host: api.mycompany.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
  - host: admin.mycompany.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
```

**Ahorro de costos**:
- Sin Ingress: 3 LoadBalancers × $20/mes = $60/mes
- Con Ingress: 1 LoadBalancer × $20/mes = $20/mes
- **Ahorro: $40/mes (67%)**

</details>

### 🔗 Siguiente Paso

Si respondiste correctamente, estás listo para aprender cómo Ingress, Services e Ingress Controllers trabajan juntos. Continúa con la siguiente sección.

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

## ✅ Checkpoint 2: Ingress Controller e IngressClass

Verifica que comprendes cómo instalar y configurar Ingress Controllers:

### Preguntas de Autoevaluación

<details>
<summary>1. ¿Cuál es el comando para habilitar el addon de nginx ingress en minikube?</summary>

**Respuesta**:

```bash
# Habilitar el addon de ingress
minikube addons enable ingress

# Verificar que está habilitado
minikube addons list | grep ingress

# Ver los Pods del ingress controller
kubectl get pods -n ingress-nginx

# Debe mostrar:
# NAME                                   READY   STATUS
# ingress-nginx-controller-xxx-xxx       1/1     Running
```

**Proceso que ocurre**:
1. Minikube descarga e instala nginx ingress controller
2. Crea namespace `ingress-nginx`
3. Despliega:
   - Deployment: `ingress-nginx-controller`
   - Service: `ingress-nginx-controller` (tipo NodePort en minikube)
   - IngressClass: `nginx`
   - ConfigMaps y roles necesarios

**Verificación completa**:
```bash
# Ver todos los recursos creados
kubectl get all -n ingress-nginx

# Ver la IngressClass
kubectl get ingressclass
# NAME    CONTROLLER             PARAMETERS   AGE
# nginx   k8s.io/ingress-nginx   <none>       5m
```

**Para deshabilitarlo** (si necesitas):
```bash
minikube addons disable ingress
```

</details>

<details>
<summary>2. ¿Qué es una IngressClass y por qué es necesaria desde Kubernetes 1.18+?</summary>

**Respuesta**:

**IngressClass** es un recurso que actúa como **selector/identificador** para asociar recursos Ingress con Ingress Controllers específicos.

**¿Por qué existe?**

**Problema en Kubernetes < 1.18**:
- Solo podías tener 1 Ingress Controller en el cluster
- La selección era implícita (anotación `kubernetes.io/ingress.class`)
- Difícil tener múltiples controllers (nginx + Traefik + AWS ALB)

**Solución con IngressClass**:
- Recurso de API explícito (`kind: IngressClass`)
- Permite múltiples Ingress Controllers en el mismo cluster
- Cada Ingress especifica qué controller debe procesarlo
- Configuración centralizada del controller

**Componentes**:
```yaml
# 1. IngressClass (define el controller)
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx  # Identifica el controller

---
# 2. Ingress (usa la IngressClass)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  ingressClassName: nginx  # ← Especifica qué controller usar
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

**Casos de uso múltiples controllers**:
```bash
# Listar IngressClasses
kubectl get ingressclass

# Ejemplo con 3 controllers:
# NAME       CONTROLLER                     DEFAULT
# nginx      k8s.io/ingress-nginx           true
# traefik    traefik.io/ingress-controller  false
# alb        aws-alb-ingress-controller     false
```

**Ventaja**: Puedes tener:
- `nginx` para apps internas
- `traefik` para apps con requisitos especiales
- `alb` para integración con AWS

</details>

<details>
<summary>3. ¿Cómo verificar que el Ingress Controller está funcionando correctamente?</summary>

**Respuesta**:

**Verificación en 5 pasos**:

**1. Ver Pods del Ingress Controller**:
```bash
kubectl get pods -n ingress-nginx

# Debe estar en Running
# NAME                                   READY   STATUS    AGE
# ingress-nginx-controller-xxx-xxx       1/1     Running   5m
```

**2. Ver Service del Ingress Controller**:
```bash
kubectl get svc -n ingress-nginx

# En minikube (NodePort):
# NAME                       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
# ingress-nginx-controller   NodePort   10.96.123.45    <none>        80:32080/TCP,443:32443/TCP

# En cloud (LoadBalancer):
# NAME                       TYPE           EXTERNAL-IP     PORT(S)
# ingress-nginx-controller   LoadBalancer   203.0.113.5     80:32080/TCP,443:32443/TCP
```

**3. Verificar IngressClass**:
```bash
kubectl get ingressclass

# NAME    CONTROLLER             PARAMETERS   AGE
# nginx   k8s.io/ingress-nginx   <none>       5m
```

**4. Ver logs del controller** (si hay problemas):
```bash
# Logs en tiempo real
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --follow

# Buscar errores
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx | grep -i error
```

**5. Test de conectividad básico**:
```bash
# En minikube, obtener IP del nodo
minikube ip
# 192.168.49.2

# Hacer curl al puerto del controller
curl http://$(minikube ip):32080

# Si funciona, recibes respuesta (aunque sea 404)
# default backend - 404
```

**Troubleshooting común**:
```bash
# Si el Pod no está Running:
kubectl describe pod -n ingress-nginx <pod-name>

# Ver eventos del namespace
kubectl get events -n ingress-nginx --sort-by='.lastTimestamp'

# Verificar resources (CPU/RAM)
kubectl top pod -n ingress-nginx
```

**Señales de que funciona**:
✅ Pod en estado `Running` (1/1 READY)
✅ Service tiene `CLUSTER-IP` asignada
✅ Logs muestran "successfully acquired lease" o "watching for Ingress"
✅ curl al puerto del controller responde (aunque sea 404)

</details>

<details>
<summary>4. ¿Cuál es la diferencia entre instalar nginx ingress con Helm vs addon de minikube?</summary>

**Respuesta**:

Ambas opciones instalan el mismo nginx ingress controller, pero con diferentes niveles de control:

**Addon de Minikube** (`minikube addons enable ingress`):

✅ **Ventajas**:
- Setup inmediato (1 comando)
- Configuración optimizada para minikube
- Actualización automática con minikube
- Perfecto para desarrollo y aprendizaje
- Service tipo NodePort (accesible via `minikube ip`)

❌ **Desventajas**:
- Configuración limitada (defaults de minikube)
- No puedes personalizar valores fácilmente
- Versión específica atada a minikube
- No portable a otros clusters

```bash
# Instalación (1 comando)
minikube addons enable ingress

# No control sobre versión o configuración
```

**Helm Chart** (`helm install`):

✅ **Ventajas**:
- Control total sobre la configuración
- Puedes personalizar values.yaml (replicas, resources, etc.)
- Eliges la versión exacta del controller
- Portable (misma instalación en dev/staging/prod)
- Actualizaciones controladas

❌ **Desventajas**:
- Requires Helm instalado
- Más pasos de configuración
- Necesitas entender values.yaml
- En minikube, debes configurar Service correctamente

```bash
# Instalación con Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.watchIngressWithoutClass=true
```

**Comparación**:
| Aspecto | Minikube Addon | Helm Chart |
|---------|----------------|------------|
| Comandos | 1 | 3-4 |
| Configuración | Básica | Total |
| Para aprendizaje | ✅ Perfecto | ⚠️ Complejo |
| Para producción | ❌ No | ✅ Sí |
| Portabilidad | ❌ Solo minikube | ✅ Cualquier cluster |
| Versión control | ❌ Atada a minikube | ✅ Explícita |

**Recomendación**:
- **Aprendizaje/Dev**: Usa addon de minikube (más rápido)
- **Producción/Multi-env**: Usa Helm (más control)

</details>

### 🧪 Ejercicio Práctico

Verifica tu instalación de nginx ingress:

```bash
# 1. Verificar que el addon está habilitado
minikube addons list | grep ingress

# 2. Ver el Deployment
kubectl get deployment -n ingress-nginx

# 3. Ver los Pods (deben estar Running)
kubectl get pods -n ingress-nginx

# 4. Ver la IngressClass
kubectl get ingressclass

# 5. Test de conectividad
curl http://$(minikube ip):80

# Deberías ver:
# <html>
# <head><title>404 Not Found</title></head>
# ...
# (Respuesta 404 significa que el controller funciona)
```

**Si todo funciona**, estás listo para crear tu primer Ingress.

### 🔗 Siguiente Paso

Ahora que tienes el Ingress Controller funcionando, aprenderás a crear recursos Ingress con diferentes tipos de routing.

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

## ✅ Checkpoint 3: Routing y TLS

Verifica tu comprensión de routing y configuración HTTPS:

### Preguntas de Autoevaluación

<details>
<summary>1. ¿Cuál es la diferencia entre pathType: Prefix y pathType: Exact?</summary>

**Respuesta**:

**`Prefix`**: Coincide con el **prefijo** del path (más flexible):
```yaml
path: /api
pathType: Prefix
```

**Coincidencias**:
- ✅ `/api` → Sí
- ✅ `/api/` → Sí
- ✅ `/api/users` → Sí
- ✅ `/api/v1/products` → Sí
- ❌ `/application` → No

**`Exact`**: Coincide **exactamente** con el path (case-sensitive):
```yaml
path: /api
pathType: Exact
```

**Coincidencias**:
- ✅ `/api` → Sí
- ❌ `/api/` → No (barra extra)
- ❌ `/api/users` → No
- ❌ `/API` → No (case-sensitive)

**Tabla comparativa**:
| Path Configurado | pathType | Request | ¿Coincide? |
|------------------|----------|---------|------------|
| `/foo` | Prefix | `/foo` | ✅ |
| `/foo` | Prefix | `/foo/` | ✅ |
| `/foo` | Prefix | `/foo/bar` | ✅ |
| `/foo` | Exact | `/foo` | ✅ |
| `/foo` | Exact | `/foo/` | ❌ |
| `/foo` | Exact | `/foo/bar` | ❌ |

**Uso común**:
- **`Prefix`**: APIs y aplicaciones (mayoría de casos)
  - Ejemplo: `/api` captura todas las rutas de API
- **`Exact`**: Rutas específicas (health checks, webhooks)
  - Ejemplo: `/health` solo para el endpoint exacto

**Recomendación**: Usa `Prefix` por defecto, `Exact` solo para casos muy específicos.

</details>

<details>
<summary>2. ¿Cómo funciona el host-based routing cuando un Ingress tiene múltiples hosts?</summary>

**Respuesta**:

El Ingress Controller inspecciona el **header `Host:`** de la petición HTTP y enruta según la coincidencia.

**Flujo de enrutamiento**:
```
Cliente hace request → Ingress Controller lee header Host → Busca coincidencia en rules → Enruta a service correspondiente
```

**Ejemplo de Ingress**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: blog.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
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
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop-service
            port:
              number: 3000
```

**Peticiones**:
```bash
# Request 1
curl -H "Host: blog.example.com" http://<ingress-ip>/
# → Enruta a blog-service:80

# Request 2
curl -H "Host: api.example.com" http://<ingress-ip>/users
# → Enruta a api-service:8080

# Request 3
curl -H "Host: shop.example.com" http://<ingress-ip>/cart
# → Enruta a shop-service:3000

# Request 4 (host no configurado)
curl -H "Host: unknown.example.com" http://<ingress-ip>/
# → 404 Not Found (o default backend)
```

**Detrás de escena**:
1. DNS resuelve `blog.example.com` → IP del LoadBalancer (ej: 203.0.113.5)
2. Cliente envía:
   ```
   GET / HTTP/1.1
   Host: blog.example.com
   ```
3. Ingress Controller lee `Host: blog.example.com`
4. Busca en reglas: coincide con rule #1
5. Hace proxy_pass a `blog-service:80`
6. Service balancea a Pods backend

**Ventaja**: Mismo LoadBalancer (IP 203.0.113.5) sirve múltiples aplicaciones. Solo necesitas configurar DNS:
```
blog.example.com  → 203.0.113.5
api.example.com   → 203.0.113.5
shop.example.com  → 203.0.113.5
```

</details>

<details>
<summary>3. ¿Cómo se configura HTTPS/TLS en un Ingress?</summary>

**Respuesta**:

HTTPS/TLS requiere **2 pasos**: crear Secret con certificado + configurar Ingress.

**Paso 1: Crear Secret con certificado TLS**:
```bash
# Generar certificado self-signed (para testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.example.com/O=mycompany"

# Crear Secret tipo tls
kubectl create secret tls myapp-tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Verificar
kubectl get secret myapp-tls-secret
kubectl describe secret myapp-tls-secret
```

**Paso 2: Configurar Ingress con TLS**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
spec:
  ingressClassName: nginx
  tls:  # ← Configuración TLS
  - hosts:
    - myapp.example.com  # Host protegido
    secretName: myapp-tls-secret  # Secret con certificado
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

**Qué hace el Ingress Controller**:
1. Lee el Secret `myapp-tls-secret`
2. Extrae `tls.crt` y `tls.key`
3. Configura nginx para terminación TLS
4. Escucha en puerto 443 (HTTPS)
5. Desencripta tráfico HTTPS
6. Envía tráfico HTTP al Service backend

**Flujo completo**:
```
Cliente (HTTPS) 
    ↓ [TLS/443]
Ingress Controller (termina TLS)
    ↓ [HTTP/80 interno]
Service ClusterIP
    ↓
Pods backend
```

**Múltiples hosts con TLS**:
```yaml
spec:
  tls:
  - hosts:
    - app1.example.com
    - app2.example.com
    secretName: multi-host-tls  # Cert debe incluir ambos hosts en SAN
```

**Wildcard certificate**:
```bash
# Certificado para *.example.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=*.example.com/O=mycompany"

kubectl create secret tls wildcard-tls --cert=tls.crt --key=tls.key
```

```yaml
spec:
  tls:
  - hosts:
    - "*.example.com"  # Cubre app1.example.com, api.example.com, etc.
    secretName: wildcard-tls
```

**Verificar HTTPS**:
```bash
# Test con curl (acepta cert self-signed)
curl -k https://myapp.example.com

# Ver detalles del certificado
curl -vk https://myapp.example.com 2>&1 | grep "subject:"
```

**Producción**: Usa **cert-manager** para certificados automáticos de Let's Encrypt (gratuitos y válidos).

</details>

<details>
<summary>4. ¿Qué sucede si un cliente hace una petición HTTP (puerto 80) a un Ingress configurado con TLS?</summary>

**Respuesta**:

Depende de la configuración del Ingress Controller. Por defecto en nginx:

**Comportamiento por defecto**:
- El Ingress Controller **acepta** tanto HTTP (80) como HTTPS (443)
- Las peticiones HTTP **no se redirigen automáticamente** a HTTPS
- Ambos funcionan si el Ingress tiene `tls:` configurado

```bash
# Ambos funcionan
curl http://myapp.example.com     # ✅ HTTP OK
curl https://myapp.example.com    # ✅ HTTPS OK
```

**Para forzar HTTPS** (redirigir HTTP → HTTPS):

**Opción 1: Anotación en Ingress** (nginx):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"  # ← Redirección automática
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

**Comportamiento**:
```bash
curl -I http://myapp.example.com
# HTTP/1.1 308 Permanent Redirect
# Location: https://myapp.example.com

# El cliente automáticamente hace:
curl https://myapp.example.com
# HTTP/1.1 200 OK
```

**Opción 2: Bloquear HTTP completamente**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
```

**Opción 3: HSTS** (HTTP Strict Transport Security):
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/hsts: "true"
    nginx.ingress.kubernetes.io/hsts-max-age: "31536000"  # 1 año
```

HSTS le dice al navegador: "Solo usa HTTPS para este dominio durante 1 año".

**Recomendación de producción**:
```yaml
metadata:
  annotations:
    # Redirigir HTTP → HTTPS
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    # HSTS
    nginx.ingress.kubernetes.io/hsts: "true"
    nginx.ingress.kubernetes.io/hsts-max-age: "31536000"
    nginx.ingress.kubernetes.io/hsts-include-subdomains: "true"
```

**Sin configurar redirección**: Los usuarios podrían usar HTTP sin saberlo → inseguro.

</details>

<details>
<summary>5. ¿Cómo combinar path-based y host-based routing en un solo Ingress?</summary>

**Respuesta**:

Puedes combinar **host + path** para routing muy específico:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: combined-routing-ingress
spec:
  ingressClassName: nginx
  rules:
  # Host 1: app.example.com
  - host: app.example.com
    http:
      paths:
      - path: /api        # app.example.com/api → api-service
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web        # app.example.com/web → web-service
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
      - path: /admin      # app.example.com/admin → admin-service
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
  
  # Host 2: docs.example.com
  - host: docs.example.com
    http:
      paths:
      - path: /           # docs.example.com → docs-service
        pathType: Prefix
        backend:
          service:
            name: docs-service
            port:
              number: 80
  
  # Host 3: blog.example.com
  - host: blog.example.com
    http:
      paths:
      - path: /           # blog.example.com → blog-service
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
```

**Tabla de routing resultante**:
| Request | Service Destino |
|---------|----------------|
| `app.example.com/api/users` | api-service:8080 |
| `app.example.com/web/home` | web-service:80 |
| `app.example.com/admin/dashboard` | admin-service:3000 |
| `docs.example.com/` | docs-service:80 |
| `docs.example.com/guide` | docs-service:80 |
| `blog.example.com/` | blog-service:80 |
| `blog.example.com/posts/123` | blog-service:80 |

**Ventajas**:
- 1 LoadBalancer para 6 destinos diferentes
- Organización lógica por dominio y funcionalidad
- Fácil agregar más servicios

**Con TLS**:
```yaml
spec:
  tls:
  - hosts:
    - app.example.com
    - docs.example.com
    - blog.example.com
    secretName: wildcard-tls  # *.example.com cert
  rules:
  # ... (mismas reglas)
```

**Uso real**: Aplicación completa con:
- Frontend: `app.example.com/web`
- API: `app.example.com/api`
- Admin panel: `app.example.com/admin`
- Documentación: `docs.example.com`
- Blog corporativo: `blog.example.com`

Todo con 1 LoadBalancer, 1 certificado wildcard, 1 Ingress resource.

</details>

### 🧪 Ejercicio Práctico

**Diseña el routing** para esta aplicación:

**Requisitos**:
- Frontend React: `myapp.com` → frontend-service:80
- API REST: `myapp.com/api` → api-service:8080
- Admin panel: `myapp.com/admin` → admin-service:3000
- Docs: `docs.myapp.com` → docs-service:80
- Todo debe ser HTTPS

<details>
<summary>Ver Solución</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-complete-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /  # Para /api y /admin
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.com
    - docs.myapp.com
    secretName: myapp-tls-secret
  rules:
  # myapp.com con múltiples paths
  - host: myapp.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  
  # docs.myapp.com
  - host: docs.myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: docs-service
            port:
              number: 80
```

**Crear el Secret TLS**:
```bash
# Certificado para myapp.com + docs.myapp.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.com/O=mycompany" \
  -addext "subjectAltName=DNS:myapp.com,DNS:docs.myapp.com"

kubectl create secret tls myapp-tls-secret --cert=tls.crt --key=tls.key
```

**Resultado**:
- ✅ `https://myapp.com` → Frontend
- ✅ `https://myapp.com/api/users` → API
- ✅ `https://myapp.com/admin` → Admin
- ✅ `https://docs.myapp.com` → Docs
- ✅ HTTP automáticamente redirige a HTTPS
- ✅ 1 LoadBalancer para todo

</details>

### 🔗 Siguiente Paso

Si dominas routing y TLS, continúa con anotaciones avanzadas para personalizar el comportamiento del Ingress Controller.

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

## ✅ Checkpoint Final: Integración y Producción

Última verificación antes de aplicar tus conocimientos en laboratorios:

### Preguntas de Autoevaluación

<details>
<summary>1. ¿Qué componentes necesitas para tener un Ingress completamente funcional en producción?</summary>

**Respuesta**:

**7 componentes esenciales**:

**1. Ingress Controller** (implementación del proxy):
```bash
# Opción 1: nginx
helm install ingress-nginx ingress-nginx/ingress-nginx

# Opción 2: Traefik, HAProxy, etc.
```

**2. IngressClass** (identifica el controller):
```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
```

**3. LoadBalancer Service** (punto de entrada externo):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  type: LoadBalancer  # IP pública
  ports:
  - name: http
    port: 80
  - name: https
    port: 443
```

**4. Backend Services** (ClusterIP para apps):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
```

**5. Deployments** (Pods de la aplicación):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 8080
        readinessProbe:  # ← CRÍTICO
          httpGet:
            path: /health
            port: 8080
```

**6. TLS Secrets** (certificados):
```bash
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key
```

**7. Ingress Resources** (reglas de routing):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.com
    secretName: myapp-tls
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

**Componentes opcionales pero recomendados**:
- **cert-manager**: Certificados automáticos de Let's Encrypt
- **external-dns**: DNS automático en cloud providers
- **PodDisruptionBudget**: Alta disponibilidad del controller
- **HPA**: Autoscaling del controller
- **NetworkPolicies**: Seguridad adicional

**Flujo completo**:
```
Internet (https://myapp.com)
    ↓ DNS resolve
LoadBalancer Service (IP: 203.0.113.5)
    ↓
Ingress Controller Pods (nginx, 3 replicas)
    ↓ lee reglas de
Ingress Resource (myapp-ingress)
    ↓ termina TLS con
Secret (myapp-tls)
    ↓ enruta a
Service ClusterIP (myapp-service)
    ↓ balancea entre
Deployment Pods (myapp, 3 replicas)
```

</details>

<details>
<summary>2. ¿Cómo implementar un canary deployment con Ingress usando weights?</summary>

**Respuesta**:

**Canary deployment** = Enviar un % de tráfico a la nueva versión para testing gradual.

**Estrategia con nginx ingress**:

**Paso 1: Deployment stable (v1) + Service**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-stable
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: v1
  template:
    metadata:
      labels:
        app: myapp
        version: v1
    spec:
      containers:
      - name: myapp
        image: myapp:v1.0
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-stable
spec:
  selector:
    app: myapp
    version: v1
  ports:
  - port: 80
    targetPort: 8080
```

**Paso 2: Deployment canary (v2) + Service**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
spec:
  replicas: 1  # Menos réplicas
  selector:
    matchLabels:
      app: myapp
      version: v2
  template:
    metadata:
      labels:
        app: myapp
        version: v2
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0  # Nueva versión
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-canary
spec:
  selector:
    app: myapp
    version: v2
  ports:
  - port: 80
    targetPort: 8080
```

**Paso 3: Ingress principal (100% a stable)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
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
            name: myapp-stable  # v1
            port:
              number: 80
```

**Paso 4: Ingress canary (10% de tráfico a v2)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"  # 10% tráfico
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
            name: myapp-canary  # v2
            port:
              number: 80
```

**Resultado**:
- 90% de requests → myapp-stable (v1)
- 10% de requests → myapp-canary (v2)

**Progresión gradual**:
```bash
# 1. Empezar con 10%
kubectl apply -f ingress-canary.yaml  # weight: 10

# 2. Monitorear v2 (errores, latencia, métricas)
kubectl logs -l version=v2 --tail=100

# 3. Si v2 está OK, aumentar a 25%
kubectl patch ingress myapp-canary -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"25"}}}'

# 4. Luego 50%
kubectl patch ingress myapp-canary -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"50"}}}'

# 5. Finalmente 100% (promover v2)
kubectl delete ingress myapp-canary  # Eliminar canary
kubectl patch ingress myapp-ingress -p '{"spec":{"rules":[{"host":"myapp.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"myapp-canary","port":{"number":80}}}}]}}]}}'

# 6. Eliminar v1
kubectl delete deployment myapp-stable
kubectl delete service myapp-stable
```

**Otras estrategias de canary**:
```yaml
# Canary por header (usuarios beta)
annotations:
  nginx.ingress.kubernetes.io/canary: "true"
  nginx.ingress.kubernetes.io/canary-by-header: "X-Beta-User"

# Canary por cookie (A/B testing)
annotations:
  nginx.ingress.kubernetes.io/canary: "true"
  nginx.ingress.kubernetes.io/canary-by-cookie: "beta_user"
```

</details>

<details>
<summary>3. ¿Cómo diagnosticar un Ingress que no responde (404 o timeout)?</summary>

**Respuesta**:

**Proceso de troubleshooting en 8 pasos**:

**1. Verificar Ingress Controller funciona**:
```bash
# Pods del controller están Running
kubectl get pods -n ingress-nginx
# NAME                                   READY   STATUS
# ingress-nginx-controller-xxx-xxx       1/1     Running

# Logs en tiempo real
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --follow
```

**2. Verificar el recurso Ingress existe**:
```bash
# Listar Ingress
kubectl get ingress

# Ver detalles
kubectl describe ingress myapp-ingress

# Buscar:
# - Address: debe tener IP
# - Rules: deben estar correctas
# - Backend: debe apuntar al service correcto
# - Events: errores recientes
```

**3. Verificar IngressClass**:
```bash
# Listar IngressClasses
kubectl get ingressclass

# Verificar que el Ingress usa la correcta
kubectl get ingress myapp-ingress -o jsonpath='{.spec.ingressClassName}'
# Debe retornar: nginx (o la que uses)
```

**4. Verificar Service backend existe**:
```bash
# Service existe
kubectl get service myapp-service

# Tiene Endpoints
kubectl get endpoints myapp-service

# Si está vacío → problema con selector
kubectl get service myapp-service -o yaml | grep -A 3 selector
kubectl get pods -l <selector> --show-labels
```

**5. Verificar Pods backend están Ready**:
```bash
# Pods en Running y READY
kubectl get pods -l app=myapp

# Si no están Ready, ver readinessProbe
kubectl describe pod <pod-name> | grep -A 10 Readiness

# Ver logs de la app
kubectl logs <pod-name> --tail=50
```

**6. Test de conectividad desde dentro del cluster**:
```bash
# Crear Pod temporal
kubectl run debug --image=curlimages/curl -it --rm -- sh

# Test directo al Service
curl http://myapp-service

# Test al Ingress Controller
curl -H "Host: myapp.com" http://ingress-nginx-controller.ingress-nginx.svc.cluster.local
```

**7. Verificar DNS (si usas dominio real)**:
```bash
# Resolver DNS
nslookup myapp.com

# Debe apuntar a la IP del LoadBalancer
kubectl get svc -n ingress-nginx ingress-nginx-controller
# EXTERNAL-IP debe coincidir con DNS
```

**8. Revisar anotaciones del Ingress**:
```bash
# Ver anotaciones
kubectl get ingress myapp-ingress -o yaml | grep annotations -A 10

# Anotaciones comunes que causan problemas:
# - nginx.ingress.kubernetes.io/rewrite-target mal configurado
# - whitelist-source-range bloqueando tu IP
# - auth-url sin configurar correctamente
```

**Errores comunes y soluciones**:

| Error | Causa | Solución |
|-------|-------|----------|
| **404 Not Found** | Ingress no tiene regla matching | Verificar `host:` y `path:` en rules |
| **503 Service Unavailable** | Service sin Endpoints | Verificar selector del Service coincide con labels de Pods |
| **502 Bad Gateway** | Pods no están Ready | Verificar readinessProbe y logs de Pods |
| **Connection timeout** | Ingress Controller no accesible | Verificar LoadBalancer Service tiene EXTERNAL-IP |
| **Certificate error** | TLS Secret incorrecto | Verificar Secret existe y tiene `tls.crt` + `tls.key` |

**Comando de diagnóstico rápido**:
```bash
# Ver todo relacionado al Ingress
kubectl get ingress,svc,endpoints,pods -l app=myapp
```

</details>

<details>
<summary>4. ¿Qué consideraciones de seguridad debes tener en producción con Ingress?</summary>

**Respuesta**:

**10 mejores prácticas de seguridad**:

**1. Siempre usar TLS/HTTPS**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"  # Forzar HTTPS
    nginx.ingress.kubernetes.io/hsts: "true"                # HSTS
    nginx.ingress.kubernetes.io/hsts-max-age: "31536000"   # 1 año
spec:
  tls:
  - hosts:
    - myapp.com
    secretName: myapp-tls
```

**2. Rate limiting** (prevenir DDoS):
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"           # 10 req/s por IP
    nginx.ingress.kubernetes.io/limit-connections: "5"    # 5 conexiones simultáneas
    nginx.ingress.kubernetes.io/limit-rpm: "100"          # 100 req/min por IP
```

**3. Whitelist de IPs** (para endpoints sensibles):
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/whitelist-source-range: "192.168.1.0/24,10.0.0.0/8"
```

**4. Autenticación básica** (admin panels):
```bash
# Crear htpasswd
htpasswd -c auth admin
# Password: ******

kubectl create secret generic admin-auth --from-file=auth
```

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: admin-auth
    nginx.ingress.kubernetes.io/auth-realm: "Admin Area"
```

**5. CORS seguro** (APIs):
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://myapp.com"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST"
    nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
```

**6. Ocultar versión de nginx**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/server-snippet: |
      more_clear_headers Server;
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
```

**7. Tamaño máximo de request body**:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"  # Max 10MB uploads
```

**8. NetworkPolicies** (restringir tráfico interno):
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-ingress
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx  # Solo desde ingress controller
    ports:
    - protocol: TCP
      port: 8080
```

**9. WAF (Web Application Firewall)** con ModSecurity:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    nginx.ingress.kubernetes.io/enable-owasp-core-rules: "true"
    nginx.ingress.kubernetes.io/modsecurity-snippet: |
      SecRuleEngine On
      SecRequestBodyAccess On
```

**10. Regular security scanning**:
```bash
# Escanear vulnerabilidades en la imagen del controller
trivy image registry.k8s.io/ingress-nginx/controller:latest

# Verificar secretos expuestos
kubectl get ingress -o yaml | grep -i password
```

**Checklist de producción**:
- [ ] TLS/HTTPS forzado
- [ ] Certificados de CA válida (Let's Encrypt)
- [ ] Rate limiting configurado
- [ ] HSTS habilitado
- [ ] Security headers (X-Frame-Options, CSP)
- [ ] WAF para endpoints públicos
- [ ] Whitelist IPs para admin/sensitive
- [ ] NetworkPolicies restrictivas
- [ ] Body size limits
- [ ] CORS configurado apropiadamente
- [ ] Autenticación en endpoints sensibles
- [ ] Logs de acceso centralizados
- [ ] Alertas de seguridad (Prometheus)
- [ ] Regular updates del controller

</details>

### 🎯 Desafío Final de Integración

Diseña una arquitectura completa de Ingress para:

**E-commerce Platform**:
- Frontend (React): `shop.example.com`
- API (Node.js): `shop.example.com/api`
- Admin Panel (React): `admin.example.com` (solo IPs internas)
- Docs (MkDocs): `docs.example.com`
- Blog (WordPress): `blog.example.com`
- v2 API en canary (5% tráfico): `shop.example.com/api/v2`

**Requisitos**:
- Todo en HTTPS
- Rate limiting en API (100 req/min)
- Admin requiere autenticación básica
- Canary deployment para API v2
- Alta disponibilidad (3 replicas controller)

<details>
<summary>Ver Solución Arquitectura</summary>

**Componentes**:

**1. Ingress Controller (3 replicas)**:
```yaml
# values.yaml para Helm
controller:
  replicaCount: 3
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: ingress-nginx
```

**2. Ingress Principal**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop-main-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/hsts: "true"
    nginx.ingress.kubernetes.io/limit-rpm: "100"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - shop.example.com
    - docs.example.com
    - blog.example.com
    secretName: shop-tls
  rules:
  # Frontend
  - host: shop.example.com
    http:
      paths:
      - path: /api/v2  # Canary
        pathType: Prefix
        backend:
          service:
            name: api-v1-service
            port:
              number: 8080
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-v1-service
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  # Docs
  - host: docs.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: docs-service
            port:
              number: 80
  # Blog
  - host: blog.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
```

**3. Ingress Admin (protegido)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: admin-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/whitelist-source-range: "192.168.1.0/24,10.0.0.0/8"
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: admin-auth
    nginx.ingress.kubernetes.io/auth-realm: "Admin Access"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - admin.example.com
    secretName: admin-tls
  rules:
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
```

**4. Ingress Canary (API v2 - 5% tráfico)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-v2-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "5"
spec:
  ingressClassName: nginx
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /api/v2
        pathType: Prefix
        backend:
          service:
            name: api-v2-service
            port:
              number: 8080
```

**Resultado**:
- ✅ 1 LoadBalancer para toda la plataforma
- ✅ HTTPS en todos los dominios
- ✅ API con rate limiting
- ✅ Admin protegido (IP + auth)
- ✅ Canary 5% en API v2
- ✅ Alta disponibilidad (3 replicas)

**Ahorro**: 5 dominios = 1 LoadBalancer vs 5 LoadBalancers sin Ingress = **ahorro de $80/mes**

</details>

### ✅ Checklist de Dominio del Módulo

Marca lo que ya dominas:

**Conceptos**:
- [ ] Diferencia entre Ingress, IngressController e IngressClass
- [ ] Ventajas vs múltiples LoadBalancers
- [ ] Flujo: Internet → LB → Controller → Service → Pods

**Instalación**:
- [ ] Habilitar nginx ingress en minikube
- [ ] Verificar controller funciona
- [ ] Entender IngressClass

**Routing**:
- [ ] Path-based routing (`/api`, `/web`)
- [ ] Host-based routing (`app1.com`, `app2.com`)
- [ ] Combinar host + path
- [ ] PathType: Prefix vs Exact

**TLS/HTTPS**:
- [ ] Crear TLS Secrets
- [ ] Configurar HTTPS en Ingress
- [ ] Forzar redirección HTTP → HTTPS
- [ ] Certificados wildcard

**Avanzado**:
- [ ] Anotaciones (rewrite, rate limit, auth)
- [ ] Canary deployments
- [ ] Múltiples Ingress Controllers
- [ ] Troubleshooting 404/502/503

**Producción**:
- [ ] Alta disponibilidad (replicas + anti-affinity)
- [ ] Seguridad (TLS, rate limit, whitelist, WAF)
- [ ] Monitoreo (logs, métricas, alertas)
- [ ] Cert-manager para certificados automáticos

### 🔗 Siguiente Paso

¡Has completado toda la teoría! Ahora aplica tus conocimientos en los 3 laboratorios prácticos guiados.

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
