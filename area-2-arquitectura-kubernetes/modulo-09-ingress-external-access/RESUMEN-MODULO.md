# 📚 RESUMEN - Módulo 09: Ingress y Acceso Externo

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre **Ingress y Acceso Externo** - la gestión inteligente de tráfico HTTP/HTTPS hacia servicios internos. Ingress permite exponer múltiples aplicaciones bajo una única IP pública con routing basado en hostnames y paths, reduciendo costos y complejidad vs múltiples LoadBalancers.

**Duración**: 5-6 horas (teoría + labs)  
**Nivel**: Intermedio-Avanzado  
**Prerequisitos**: Services (ClusterIP, NodePort, LoadBalancer), Deployments

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### Fundamentos
- ✅ Diferenciar Ingress Resource, Ingress Controller e IngressClass
- ✅ Entender por qué Ingress ahorra costos (1 LB vs N LBs)
- ✅ Explicar path-based vs host-based routing
- ✅ Comprender el flujo: Internet → LB → Controller → Service → Pods

### Técnico
- ✅ Instalar nginx ingress controller en minikube
- ✅ Crear Ingress resources con reglas de routing
- ✅ Configurar TLS/HTTPS con Secrets
- ✅ Usar anotaciones para funcionalidades avanzadas
- ✅ Diagnosticar problemas comunes (404, 502, 503)

### Avanzado
- ✅ Implementar canary deployments con weights
- ✅ Configurar múltiples Ingress Controllers
- ✅ Diseñar arquitecturas de alta disponibilidad
- ✅ Aplicar seguridad (rate limiting, whitelist, WAF)
- ✅ Integrar cert-manager para certificados automáticos

---

## 🗺️ Estructura de Aprendizaje

### Fase 1: Conceptos Fundamentales (45 min)
**Teoría**: Secciones 1-3 del README
- ¿Qué es Ingress y por qué usarlo?
- Arquitectura de 3 componentes
- Comparativa: Services vs Ingress

**Conceptos Clave**:
- **Ingress Resource**: YAML con reglas de routing (configuración)
- **Ingress Controller**: Pod que implementa las reglas (nginx, Traefik)
- **IngressClass**: Selector para asociar Ingress → Controller

**Diagrama Mental**:
```
Internet
    ↓
1 LoadBalancer (IP pública)
    ↓
Ingress Controller (nginx pod)
    ↓ lee reglas de
Ingress Resources
    ↓ enruta a
Services (ClusterIP)
    ↓
Pods backend
```

**Checkpoint 1**: ¿Entiendes la diferencia entre Resource y Controller?

---

### Fase 2: Instalación de Ingress Controller (30 min)
**Teoría**: Sección 4 del README

**Instalar nginx ingress en minikube**:
```bash
# Habilitar addon
minikube addons enable ingress

# Verificar instalación
kubectl get pods -n ingress-nginx
kubectl get ingressclass

# Test básico
curl http://$(minikube ip):80
# Debe responder (aunque sea 404)
```

**Componentes instalados**:
- Namespace: `ingress-nginx`
- Deployment: `ingress-nginx-controller`
- Service: tipo NodePort (minikube) o LoadBalancer (cloud)
- IngressClass: `nginx`

**Checkpoint 2**: ¿Puedes verificar que el controller funciona?

**Lab recomendado**: No es necesario lab aquí, verificación con comandos.

---

### Fase 3: Routing Básico (60 min)
**Teoría**: Secciones 5-7 del README

#### Path-based Routing
Enruta según la **ruta URL**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-ingress
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

**Resultado**:
- `http://<ingress-ip>/api` → api-service
- `http://<ingress-ip>/web` → web-service

#### Host-based Routing
Enruta según el **hostname**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-ingress
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

**PathType**:
- `Prefix`: Coincide con prefijo (`/api` = `/api`, `/api/`, `/api/users`)
- `Exact`: Coincidencia exacta (`/api` ≠ `/api/`)

**Comandos**:
```bash
# Crear Ingress
kubectl apply -f ingress.yaml

# Ver Ingress
kubectl get ingress
kubectl describe ingress <name>

# Test (sin DNS)
curl -H "Host: app1.example.com" http://$(minikube ip)
```

**Checkpoint 3 (parte 1)**: ¿Entiendes Prefix vs Exact?

**Lab 1**: [Ingress Básico](laboratorios/lab-01-ingress-basico.md) - 40 min

---

### Fase 4: TLS/HTTPS (45 min)
**Teoría**: Sección 8 del README

**Configurar HTTPS**:

**Paso 1: Crear certificado** (self-signed para testing):
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.example.com/O=mycompany"
```

**Paso 2: Crear Secret TLS**:
```bash
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key

# Verificar
kubectl get secret myapp-tls
kubectl describe secret myapp-tls
```

**Paso 3: Configurar Ingress con TLS**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"  # Forzar HTTPS
spec:
  ingressClassName: nginx
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

**Comandos de verificación**:
```bash
# Test HTTPS (acepta cert self-signed)
curl -k https://myapp.example.com

# Ver certificado
curl -vk https://myapp.example.com 2>&1 | grep "subject:"
```

**Producción**: Usa **cert-manager** + Let's Encrypt para certificados válidos automáticos.

**Checkpoint 3 (parte 2)**: ¿Sabes configurar TLS?

---

### Fase 5: Anotaciones Avanzadas (60 min)
**Teoría**: Sección 9 del README

**Anotaciones comunes de nginx ingress**:

#### 1. URL Rewrite
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
```

**Uso**: `/api/users` → `/users` en el backend

#### 2. Rate Limiting
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"           # 10 req/s
    nginx.ingress.kubernetes.io/limit-connections: "5"    # 5 conex simultáneas
    nginx.ingress.kubernetes.io/limit-rpm: "100"          # 100 req/min
```

#### 3. Session Affinity (Sticky Sessions)
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "route"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "172800"  # 48h
```

#### 4. Autenticación Básica
```bash
# Crear htpasswd
htpasswd -c auth admin
kubectl create secret generic admin-auth --from-file=auth
```

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: admin-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

#### 5. Whitelist de IPs
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/whitelist-source-range: "192.168.1.0/24,10.0.0.0/8"
```

#### 6. CORS
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://myapp.com"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT"
```

**Lab 2**: [TLS y Configuraciones Avanzadas](laboratorios/lab-02-ingress-tls-avanzado.md) - 50 min

---

### Fase 6: Patrones Avanzados (60 min)
**Teoría**: Sección 10 del README

#### Canary Deployment (división de tráfico)

**Setup**:
1. Deployment stable (v1) + service
2. Deployment canary (v2) + service
3. Ingress principal → stable
4. Ingress canary con annotation

**Ingress Canary**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"  # 10% tráfico a v2
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
            name: myapp-v2-service
            port:
              number: 80
```

**Progresión gradual**:
```bash
# 10% → 25% → 50% → 100%
kubectl patch ingress myapp-canary -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"25"}}}'
```

#### Blue-Green Deployment

**Estrategia**: Cambiar el backend del Ingress de azul → verde:
```bash
# Switch instantáneo
kubectl patch ingress myapp-ingress -p '{"spec":{"rules":[{"host":"myapp.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"myapp-green","port":{"number":80}}}}]}}]}}'
```

#### Múltiples Ingress Controllers
```bash
# Listar controllers
kubectl get ingressclass

# NAME       CONTROLLER
# nginx      k8s.io/ingress-nginx
# traefik    traefik.io/ingress-controller

# Usar controller específico
spec:
  ingressClassName: nginx  # o traefik
```

**Checkpoint Final**: ¿Entiendes canary vs blue-green?

---

### Fase 7: Producción y Troubleshooting (45 min)
**Teoría**: Secciones 11-12 del README

#### Alta Disponibilidad

**3 réplicas del controller**:
```yaml
# values.yaml para Helm
controller:
  replicaCount: 3
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
```

**PodDisruptionBudget**:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
```

#### Troubleshooting

**Diagnóstico en 5 pasos**:
```bash
# 1. Controller funciona
kubectl get pods -n ingress-nginx

# 2. Ingress existe
kubectl get ingress
kubectl describe ingress <name>

# 3. Service tiene Endpoints
kubectl get endpoints <service>

# 4. Pods están Ready
kubectl get pods -l app=myapp

# 5. Test interno
kubectl run debug --image=curlimages/curl -it --rm -- sh
curl -H "Host: myapp.com" http://ingress-nginx-controller.ingress-nginx.svc.cluster.local
```

**Errores comunes**:
| Error | Causa | Solución |
|-------|-------|----------|
| 404 | Regla no coincide | Verificar `host:` y `path:` |
| 503 | Sin Endpoints | Verificar selector Service |
| 502 | Pods no Ready | Ver readinessProbe |
| Timeout | Controller inaccesible | Verificar LoadBalancer Service |

**Lab 3**: [Ingress en Producción](laboratorios/lab-03-ingress-produccion.md) - 60 min

---

## 📝 Comandos Esenciales

### Instalación

```bash
# Minikube addon
minikube addons enable ingress

# Helm (más control)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# Verificar
kubectl get pods -n ingress-nginx
kubectl get ingressclass
```

### Crear Ingress

```bash
# Desde YAML
kubectl apply -f ingress.yaml

# Ver template
kubectl create ingress demo --class=nginx \
  --rule="myapp.com/=myapp-service:80" \
  --dry-run=client -o yaml
```

### Ver Ingress

```bash
# Listar Ingress
kubectl get ingress
kubectl get ing

# Detalles
kubectl describe ingress <name>

# Ver YAML
kubectl get ingress <name> -o yaml

# Con labels
kubectl get ingress -l app=myapp
```

### TLS/Secrets

```bash
# Crear certificado self-signed
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.com/O=mycompany"

# Crear Secret TLS
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key

# Ver Secret
kubectl get secret myapp-tls
kubectl describe secret myapp-tls
```

### Testing

```bash
# Test con curl (sin DNS)
curl -H "Host: myapp.com" http://$(minikube ip)

# Test HTTPS (acepta cert self-signed)
curl -k https://myapp.com

# Ver headers de respuesta
curl -I http://myapp.com

# Seguir redirects
curl -L http://myapp.com
```

### Modificar Ingress

```bash
# Editar interactivamente
kubectl edit ingress <name>

# Patch (cambiar backend)
kubectl patch ingress myapp-ingress -p '{"spec":{"rules":[{"host":"myapp.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"new-service","port":{"number":80}}}}]}}]}}'

# Añadir anotación
kubectl annotate ingress myapp-ingress nginx.ingress.kubernetes.io/force-ssl-redirect="true"
```

### Troubleshooting

```bash
# Logs del controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --follow

# Buscar errores
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx | grep -i error

# Eventos
kubectl get events --sort-by='.lastTimestamp' | grep Ingress

# Verificar routing
kubectl get ingress,svc,endpoints,pods -l app=myapp

# Config de nginx (dentro del controller)
kubectl exec -n ingress-nginx <controller-pod> -- cat /etc/nginx/nginx.conf | grep -A 20 "server_name myapp.com"
```

---

## 🎯 Conceptos Clave para Recordar

### Arquitectura de 3 Componentes

```
1. Ingress Resource (YAML)
   ↓ define reglas
2. Ingress Controller (Pod: nginx/traefik)
   ↓ implementa
3. IngressClass (selector)
   ↓ asocia Resource → Controller
```

### Ahorro de Costos

**Sin Ingress**:
```
App1 → LoadBalancer 1 ($20/mes)
App2 → LoadBalancer 2 ($20/mes)
App3 → LoadBalancer 3 ($20/mes)
Total: $60/mes
```

**Con Ingress**:
```
Internet → 1 LoadBalancer ($20/mes)
    ↓
Ingress Controller
    ↓ routing
App1, App2, App3
Total: $20/mes
Ahorro: 67%
```

### Tipos de Routing

| Tipo | Basado en | Ejemplo | Uso |
|------|-----------|---------|-----|
| Path-based | URL path | `/api`, `/web` | Microservicios en mismo dominio |
| Host-based | Hostname | `app1.com`, `app2.com` | Apps diferentes |
| Combinado | Host + Path | `api.myapp.com/v1` | Arquitecturas complejas |

### PathType

| PathType | Comportamiento | Ejemplo |
|----------|----------------|---------|
| **Prefix** | Prefijo | `/api` = `/api`, `/api/`, `/api/users` |
| **Exact** | Exacto | `/api` ≠ `/api/` |
| **ImplementationSpecific** | Depende del controller | Varía |

### TLS/HTTPS

**3 pasos**:
1. Crear certificado → Secret TLS
2. Configurar `spec.tls` en Ingress
3. (Opcional) Forzar HTTPS con annotation

```yaml
spec:
  tls:
  - hosts:
    - myapp.com
    secretName: myapp-tls
```

### Anotaciones Críticas

```yaml
metadata:
  annotations:
    # TLS
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # Rate Limiting
    nginx.ingress.kubernetes.io/limit-rps: "10"
    
    # Rewrite
    nginx.ingress.kubernetes.io/rewrite-target: /
    
    # Autenticación
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: auth-secret
    
    # Whitelist IPs
    nginx.ingress.kubernetes.io/whitelist-source-range: "192.168.1.0/24"
    
    # Canary
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
```

---

## ✅ Checklist de Dominio

Marca cuando domines cada concepto:

### Fundamentos
- [ ] Puedo explicar qué es un Ingress y por qué es necesario
- [ ] Entiendo la diferencia entre Resource, Controller e IngressClass
- [ ] Sé cuándo usar Ingress vs LoadBalancer Service
- [ ] Comprendo el flujo: Internet → LB → Controller → Service → Pods

### Instalación
- [ ] Puedo instalar nginx ingress en minikube
- [ ] Sé verificar que el controller funciona
- [ ] Entiendo qué es una IngressClass
- [ ] Puedo ver logs del controller para debugging

### Routing
- [ ] Puedo crear Ingress con path-based routing
- [ ] Puedo crear Ingress con host-based routing
- [ ] Entiendo la diferencia entre Prefix y Exact
- [ ] Sé combinar host + path routing

### TLS/HTTPS
- [ ] Puedo crear certificados self-signed
- [ ] Sé crear Secrets TLS
- [ ] Puedo configurar HTTPS en Ingress
- [ ] Sé forzar redirección HTTP → HTTPS

### Anotaciones
- [ ] Puedo usar rewrite-target
- [ ] Sé configurar rate limiting
- [ ] Puedo implementar autenticación básica
- [ ] Entiendo sticky sessions (affinity)
- [ ] Sé usar whitelist de IPs

### Avanzado
- [ ] Puedo implementar canary deployments
- [ ] Entiendo blue-green deployments
- [ ] Sé configurar múltiples controllers
- [ ] Puedo diseñar arquitecturas de producción

### Troubleshooting
- [ ] Sé diagnosticar 404 (regla no coincide)
- [ ] Puedo resolver 503 (sin Endpoints)
- [ ] Entiendo 502 (Pods no Ready)
- [ ] Sé usar kubectl logs del controller
- [ ] Puedo hacer test interno con curl

### Producción
- [ ] Sé configurar alta disponibilidad (3 replicas)
- [ ] Puedo implementar PodDisruptionBudget
- [ ] Entiendo NetworkPolicies para Ingress
- [ ] Sé configurar monitoreo (Prometheus)
- [ ] Conozco cert-manager para certificados automáticos

### Práctica
- [ ] Completé Lab 01: Ingress Básico
- [ ] Completé Lab 02: TLS y Avanzado
- [ ] Completé Lab 03: Producción
- [ ] Puedo diseñar arquitecturas completas de Ingress

---

## 🎓 Evaluación Final

### Preguntas Clave
1. ¿Cuál es la principal ventaja de Ingress vs múltiples LoadBalancers?
2. ¿Qué componente lee los Ingress resources y configura el proxy?
3. ¿Cómo enruta un Ingress entre `app1.com` y `app2.com`?
4. ¿Qué se necesita para configurar HTTPS en Ingress?
5. ¿Cómo implementar canary deployment con 10% de tráfico?

<details>
<summary>Ver Respuestas</summary>

1. **Ventaja**: 1 LoadBalancer para todas las apps vs 1 LB por app. Ahorro de costos (67% con 3 apps), gestión centralizada, configuración declarativa.

2. **Ingress Controller** (Pod ejecutando nginx/Traefik/etc) lee los Ingress resources y configura el proxy para implementar las reglas.

3. Via **Host-based routing**: El controller inspecciona el header `Host:` HTTP y enruta según el hostname configurado en `spec.rules[].host`.

4. **3 pasos**:
   - Certificado TLS (crt + key)
   - Secret tipo tls: `kubectl create secret tls name --cert=... --key=...`
   - Configurar `spec.tls` en Ingress apuntando al Secret

5. **Canary con annotation**:
   ```yaml
   metadata:
     annotations:
       nginx.ingress.kubernetes.io/canary: "true"
       nginx.ingress.kubernetes.io/canary-weight: "10"
   ```
   90% va a Ingress principal, 10% a Ingress canary.

</details>

### Escenario Práctico
Diseña Ingress para:
- Frontend: `myapp.com` → frontend-svc:80
- API: `myapp.com/api` → api-svc:8080
- Admin: `admin.myapp.com` (auth básica, whitelist 192.168.1.0/24)
- Docs: `docs.myapp.com`
- Todo HTTPS

<details>
<summary>Ver Solución</summary>

**Ingress Principal**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-main
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.com
    - docs.myapp.com
    secretName: main-tls
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-svc
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-svc
            port:
              number: 80
  - host: docs.myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: docs-svc
            port:
              number: 80
```

**Ingress Admin (protegido)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-admin
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/whitelist-source-range: "192.168.1.0/24"
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: admin-auth
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - admin.myapp.com
    secretName: admin-tls
  rules:
  - host: admin.myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-svc
            port:
              number: 3000
```

**Secret de auth**:
```bash
htpasswd -c auth admin
kubectl create secret generic admin-auth --from-file=auth
```

</details>

---

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Gateway API](https://gateway-api.sigs.k8s.io/) (sucesor de Ingress)

### Labs del Módulo
1. [Lab 01 - Ingress Básico](laboratorios/lab-01-ingress-basico.md) - 40 min
2. [Lab 02 - TLS y Avanzado](laboratorios/lab-02-ingress-tls-avanzado.md) - 50 min
3. [Lab 03 - Producción](laboratorios/lab-03-ingress-produccion.md) - 60 min

### Ejemplos Prácticos
- [`ejemplos/01-basico/`](ejemplos/01-basico/) - Ingress básico
- [`ejemplos/02-routing/`](ejemplos/02-routing/) - Path y host routing
- [`ejemplos/03-tls/`](ejemplos/03-tls/) - HTTPS y certificados
- [`ejemplos/04-annotations/`](ejemplos/04-annotations/) - Anotaciones avanzadas
- [`ejemplos/05-avanzado/`](ejemplos/05-avanzado/) - Canary y blue-green
- [`ejemplos/06-produccion/`](ejemplos/06-produccion/) - Configuraciones de producción

### Herramientas Complementarias
- [cert-manager](https://cert-manager.io/) - Certificados automáticos (Let's Encrypt)
- [external-dns](https://github.com/kubernetes-sigs/external-dns) - DNS automático en cloud
- [Traefik](https://traefik.io/) - Ingress Controller alternativo
- [Kong](https://konghq.com/) - API Gateway con Ingress

### Siguiente Módulo
➡️ [Módulo 10 - Namespaces y Organización](../modulo-10-namespaces-organizacion/)

---

## 🎉 ¡Felicitaciones!

Has completado el Módulo 09 de Ingress y Acceso Externo. Ahora puedes:

- ✅ Exponer múltiples aplicaciones con 1 LoadBalancer
- ✅ Implementar routing inteligente (host + path)
- ✅ Configurar HTTPS/TLS con certificados
- ✅ Usar anotaciones para funcionalidades avanzadas
- ✅ Aplicar patrones de producción (canary, HA, seguridad)
- ✅ Diagnosticar y resolver problemas comunes

**Próximos pasos**:
1. Revisar este resumen periódicamente
2. Practicar con los 3 laboratorios
3. Explorar cert-manager para certificados automáticos
4. Investigar Gateway API (futuro de Ingress)
5. Continuar con Módulo 10: Namespaces

¡Sigue adelante! 🚀
