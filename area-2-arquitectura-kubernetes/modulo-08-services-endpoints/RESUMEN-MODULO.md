# 📚 RESUMEN - Módulo 08: Services y Endpoints

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre **Services y Endpoints** - la capa de networking que permite la comunicación entre componentes en Kubernetes. Services proporcionan IPs estables y DNS para acceder a Pods efímeros, resolviendo el problema de descubrimiento y balanceo de carga en entornos dinámicos.

**Duración**: 4-5 horas (teoría + labs)  
**Nivel**: Intermedio  
**Prerequisitos**: Pods, ReplicaSets, Deployments

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### Fundamentos
- ✅ Explicar qué son los Services y por qué son necesarios
- ✅ Entender la relación Service → Endpoints → Pods
- ✅ Diferenciar los 4 tipos de Services (ClusterIP, NodePort, LoadBalancer, ExternalName)

### Técnico
- ✅ Crear y configurar Services para comunicación interna y externa
- ✅ Gestionar Endpoints automáticos y manuales
- ✅ Usar DNS para descubrimiento de servicios
- ✅ Configurar session affinity y externalTrafficPolicy

### Avanzado
- ✅ Implementar Services headless para StatefulSets
- ✅ Optimizar performance con IPVS
- ✅ Diagnosticar y resolver problemas de networking
- ✅ Aplicar best practices de producción

---

## 🗺️ Estructura de Aprendizaje

### Fase 1: Fundamentos (1 hora)
**Teoría**: Secciones 1-3 del README
- ¿Qué son los Services?
- Anatomía de un Service
- Tipos de Services (comparativa)

**Conceptos Clave**:
- Pods son efímeros → IPs cambian
- Services proporcionan IP estable + DNS
- Endpoints mapean Services → Pods dinámicamente

**Ejemplo Básico**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP  # Default
```

**Comandos Esenciales**:
```bash
# Ver Services
kubectl get svc
kubectl get service my-service
kubectl describe svc my-service

# Ver Endpoints
kubectl get endpoints
kubectl get endpoints my-service -o yaml
```

**Checkpoint 1**: ¿Entiendes por qué Services son necesarios y qué son los Endpoints?

---

### Fase 2: ClusterIP y Comunicación Interna (45 min)
**Teoría**: Secciones 4-5 del README

**ClusterIP** (tipo por defecto):
- IP interna solo accesible dentro del cluster
- Uso: Comunicación entre microservicios
- DNS automático: `<service>.<namespace>.svc.cluster.local`

**Acceso al Service**:
```bash
# Mismo namespace
curl http://backend-service:80

# Otro namespace
curl http://backend-service.default:80

# FQDN completo
curl http://backend-service.default.svc.cluster.local:80
```

**Endpoints Automáticos**:
```yaml
# Service con selector → Endpoints automáticos
apiVersion: v1
kind: Service
metadata:
  name: auto-service
spec:
  selector:
    app: backend  # Busca Pods con este label
  ports:
    - port: 80
      targetPort: 8080
```

**Endpoints Manuales** (sin selector):
```yaml
# Para servicios externos
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
    - port: 3306
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db  # Mismo nombre que Service
subsets:
  - addresses:
      - ip: 192.168.1.100
    ports:
      - port: 3306
```

**Comandos de Diagnóstico**:
```bash
# Verificar Service → Endpoints mapping
kubectl get svc my-service
kubectl get endpoints my-service
kubectl describe svc my-service

# Ver IPs de Pods
kubectl get pods -o wide -l app=backend
```

**Checkpoint 2**: ¿Puedes explicar cómo un Service encuentra sus Pods backend?

**Lab 1**: [ClusterIP y Endpoints Básicos](laboratorios/lab-01-clusterip-basics.md) - 40 min

---

### Fase 3: Exposición Externa (1 hora)
**Teoría**: Secciones 6-7 del README

#### NodePort
Expone el Service en cada nodo del cluster en un puerto estático (30000-32767).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-nodeport
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080  # Opcional, auto-asignado si no se especifica
```

**Acceso**:
```bash
# Desde fuera del cluster
curl http://<NODE-IP>:30080

# En minikube
minikube service webapp-nodeport --url
curl $(minikube service webapp-nodeport --url)
```

**Cuándo usar**: Testing, desarrollo, demos.

#### LoadBalancer
Crea un balanceador de carga externo con IP pública (en cloud providers).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-lb
spec:
  type: LoadBalancer
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 8080
```

**Acceso**:
```bash
# Obtener IP pública
kubectl get svc webapp-lb
# EXTERNAL-IP: 203.0.113.25

curl http://203.0.113.25
```

**Cuándo usar**: Producción en AWS, GCP, Azure.

**En minikube** (LoadBalancer queda en `<pending>`):
```bash
# Solución 1: minikube tunnel
minikube tunnel  # En otra terminal

# Solución 2: Cambiar a NodePort
kubectl patch svc webapp-lb -p '{"spec":{"type":"NodePort"}}'
```

**Comparativa Rápida**:
| Tipo | Acceso | Uso |
|------|--------|-----|
| ClusterIP | Solo interno | Microservicios |
| NodePort | Interno + Externo (IP nodo) | Dev/Test |
| LoadBalancer | Interno + Externo (IP pública) | Producción cloud |

**Checkpoint 3**: ¿Entiendes cuándo usar NodePort vs LoadBalancer?

**Lab 2**: [NodePort y LoadBalancer](laboratorios/lab-02-nodeport-loadbalancer.md) - 50 min

---

### Fase 4: Tipos Especiales y Configuraciones Avanzadas (1 hora)
**Teoría**: Secciones 8-14 del README

#### ExternalName
Redirige a un nombre DNS externo (CNAME).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-api
spec:
  type: ExternalName
  externalName: api.example.com
```

**Uso**: Servicios externos, migración gradual a K8s.

#### Headless Services
Service sin ClusterIP (`clusterIP: None`). DNS retorna IPs de todos los Pods.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: database-headless
spec:
  clusterIP: None  # Headless!
  selector:
    app: postgres
  ports:
    - port: 5432
```

**Uso**: StatefulSets (bases de datos), cuando necesitas acceso directo a Pods específicos.

**DNS de StatefulSet**:
```
postgres-0.database-headless.default.svc.cluster.local → 10.1.2.3
postgres-1.database-headless.default.svc.cluster.local → 10.1.2.4
postgres-2.database-headless.default.svc.cluster.local → 10.1.2.5
```

#### Session Affinity
Mantiene conexiones del mismo cliente al mismo Pod.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-service
spec:
  sessionAffinity: ClientIP  # "None" (default) o "ClientIP"
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 horas
```

**Uso**: Aplicaciones con sesiones stateful, WebSockets.

#### ExternalTrafficPolicy
Controla cómo se enruta tráfico externo.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local  # "Cluster" (default) o "Local"
```

**Local**:
- ✅ Preserva IP origen del cliente
- ✅ Sin hop extra (mejor latencia)
- ❌ Balanceo desigual

**Cluster** (default):
- ✅ Balanceo uniforme
- ❌ Pierde IP origen (SNAT)
- ❌ Hop adicional

**Checkpoint 4**: ¿Sabes cuándo usar headless Services y session affinity?

**Lab 3**: [Services Avanzados](laboratorios/lab-03-advanced-services.md) - 60 min

---

### Fase 5: Best Practices y Production (45 min)
**Teoría**: Secciones 15-16 del README

#### Naming Conventions
```yaml
metadata:
  name: backend-api-service  # Descriptivo
  labels:
    app: backend
    component: api
    tier: backend
    environment: production
```

#### Health Checks (Crítico!)
```yaml
# En el Deployment (no Service)
spec:
  template:
    spec:
      containers:
      - name: app
        readinessProbe:  # ¡Esencial!
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
```

**Sin readiness probe**: Service envía tráfico a Pods no listos → errores 500.

#### Service Production-Ready
```yaml
apiVersion: v1
kind: Service
metadata:
  name: production-api
  labels:
    app: api
    environment: production
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
spec:
  type: LoadBalancer
  selector:
    app: api
    version: v2.1.0
  ports:
    - name: https
      port: 443
      targetPort: 8443
  sessionAffinity: ClientIP
  externalTrafficPolicy: Local
```

#### Seguridad
**NetworkPolicy** (restringir acceso):
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
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
            app: frontend  # Solo frontend puede acceder
      ports:
      - protocol: TCP
        port: 8080
```

**LoadBalancer Source Ranges**:
```yaml
spec:
  type: LoadBalancer
  loadBalancerSourceRanges:
    - "203.0.113.0/24"  # Solo esta IP range
```

---

### Fase 6: Troubleshooting (30 min)
**Teoría**: Sección 16 del README

#### Problema 1: Service No Responde
```bash
# 1. Verificar Service existe
kubectl get svc my-service

# 2. Ver Endpoints
kubectl get endpoints my-service

# Si ENDPOINTS vacío:
# - Verificar selector del Service
kubectl get svc my-service -o yaml | grep -A 5 selector

# - Verificar labels de Pods
kubectl get pods -l app=my-app --show-labels

# ¿Coinciden? Si no, corregir.
```

#### Problema 2: DNS No Funciona
```bash
# Verificar CoreDNS
kubectl -n kube-system get pods -l k8s-app=kube-dns

# Test desde un Pod
kubectl run debug --image=busybox -it --rm -- sh
/ # nslookup my-service
/ # nslookup my-service.default.svc.cluster.local
```

#### Problema 3: LoadBalancer en `<pending>`
```bash
# En minikube/kind
minikube tunnel  # En otra terminal

# O instalar MetalLB (bare-metal LB)
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
```

#### Problema 4: Tráfico No Llega a Pods
```bash
# Verificar Pods Ready
kubectl get pods -l app=my-app

# Ver readiness probe
kubectl describe pod <pod-name> | grep -A 10 Readiness

# Test directo al Pod (bypass Service)
kubectl port-forward pod/<pod-name> 8080:8080
curl http://localhost:8080
```

**Comandos de Diagnóstico Rápido**:
```bash
# Service + Endpoints + Pods
kubectl get svc,endpoints,pods -l app=my-app

# Eventos recientes
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Logs de kube-proxy
kubectl -n kube-system logs -l k8s-app=kube-proxy

# Test de conectividad
kubectl run test --image=busybox -it --rm -- wget -O- http://my-service
```

---

## 📝 Comandos Esenciales

### Crear Services

```bash
# Imperativo: Exponer Deployment
kubectl expose deployment nginx --port=80 --target-port=80 --name=nginx-service

# Imperativo: Con tipo específico
kubectl expose deployment webapp --type=NodePort --port=80

# Declarativo
kubectl apply -f service.yaml

# Desde archivo con dry-run
kubectl create service clusterip my-service --tcp=80:8080 --dry-run=client -o yaml > service.yaml
```

### Ver Services

```bash
# Listar Services
kubectl get services
kubectl get svc

# Ver detalles
kubectl describe service my-service

# Ver en formato YAML
kubectl get svc my-service -o yaml

# Ver con selector
kubectl get svc -l app=backend

# Ver IP y puertos
kubectl get svc my-service -o jsonpath='{.spec.clusterIP}'
kubectl get svc my-service -o jsonpath='{.spec.ports[0].nodePort}'
```

### Ver Endpoints

```bash
# Listar Endpoints
kubectl get endpoints
kubectl get ep

# Ver Endpoints de un Service
kubectl get endpoints my-service

# Ver en YAML
kubectl get endpoints my-service -o yaml
```

### Testing

```bash
# Port-forward a Service
kubectl port-forward service/my-service 8080:80
curl http://localhost:8080

# Desde un Pod temporal
kubectl run test --image=busybox -it --rm -- wget -O- http://my-service

# Con curl
kubectl run curl --image=curlimages/curl -it --rm -- curl http://my-service
```

### Modificar Services

```bash
# Editar interactivamente
kubectl edit service my-service

# Cambiar tipo
kubectl patch service my-service -p '{"spec":{"type":"LoadBalancer"}}'

# Cambiar selector
kubectl patch service my-service -p '{"spec":{"selector":{"app":"new-app"}}}'

# Scale (afecta Pods, no Service)
kubectl scale deployment my-app --replicas=5
kubectl get endpoints my-service  # Ver nuevos Endpoints
```

### Eliminar

```bash
# Eliminar Service
kubectl delete service my-service

# Eliminar múltiples
kubectl delete svc nginx-svc webapp-svc

# Eliminar por selector
kubectl delete svc -l app=backend
```

---

## 🎯 Conceptos Clave para Recordar

### Service → Endpoints → Pods
```
Service (IP estable: 10.96.0.10)
    ↓ selector: app=backend
Endpoints (lista dinámica)
    ├── 10.1.2.3:8080 (Pod-1)
    ├── 10.1.2.4:8080 (Pod-2)
    └── 10.1.2.5:8080 (Pod-3)
```

### Comparativa de Tipos
| Tipo | ClusterIP | NodePort | LoadBalancer | ExternalName |
|------|-----------|----------|--------------|--------------|
| IP interna | ✅ | ✅ | ✅ | ❌ |
| IP externa | ❌ | ❌ (usa IP nodo) | ✅ | ❌ |
| Acceso interno | ✅ | ✅ | ✅ | ✅ |
| Acceso externo | ❌ | ✅ | ✅ | ❌ |
| Uso común | Microservicios | Dev/Test | Producción cloud | Servicios externos |

### DNS de Services
```
<service>.<namespace>.svc.<cluster-domain>

Ejemplos:
- my-service                              (mismo namespace)
- my-service.default                      (namespace específico)
- my-service.default.svc.cluster.local    (FQDN completo)
```

### kube-proxy Modos
| Modo | Performance | Escalabilidad | Algoritmos |
|------|-------------|---------------|------------|
| userspace | ❌ Lento | ❌ Malo | Básico |
| iptables | ✅ Medio | ⚠️ <5000 svc | RoundRobin |
| IPVS | ✅✅ Rápido | ✅ >10k svc | rr, lc, sh, dh |

### Puertos en Service
```yaml
ports:
  - name: http
    protocol: TCP
    port: 80          # Puerto del Service (donde escucha)
    targetPort: 8080  # Puerto del Pod (donde redirige)
    nodePort: 30080   # Puerto en nodos (solo NodePort/LoadBalancer)
```

---

## ✅ Checklist de Dominio

Marca cuando domines cada concepto:

### Fundamentos
- [ ] Puedo explicar qué es un Service y por qué es necesario
- [ ] Entiendo la relación Service → Endpoints → Pods
- [ ] Sé cuándo usar cada tipo de Service
- [ ] Conozco cómo funciona el DNS interno de Kubernetes

### Configuración
- [ ] Puedo crear Services con selector automático
- [ ] Puedo crear Endpoints manuales para servicios externos
- [ ] Sé configurar múltiples puertos en un Service
- [ ] Entiendo port vs targetPort vs nodePort

### Avanzado
- [ ] Sé cuándo y cómo usar Services headless
- [ ] Puedo configurar session affinity apropiadamente
- [ ] Entiendo externalTrafficPolicy (Cluster vs Local)
- [ ] Conozco las diferencias entre modos de kube-proxy

### Troubleshooting
- [ ] Puedo diagnosticar Endpoints vacíos
- [ ] Sé resolver problemas de DNS
- [ ] Puedo debuggear Services que no responden
- [ ] Entiendo por qué un LoadBalancer queda en `<pending>`

### Producción
- [ ] Aplico best practices de naming y labels
- [ ] Configuro health checks en Pods
- [ ] Uso NetworkPolicies para seguridad
- [ ] Sé integrar con herramientas de monitoreo

### Práctica
- [ ] Completé Lab 01: ClusterIP y Endpoints
- [ ] Completé Lab 02: NodePort y LoadBalancer
- [ ] Completé Lab 03: Services Avanzados
- [ ] Puedo diseñar arquitecturas de Services para apps reales

---

## 🎓 Evaluación Final

### Preguntas Clave
1. ¿Por qué un Pod necesita un Service si ya tiene una IP?
2. ¿Qué sucede con los Endpoints cuando escalo un Deployment de 3 a 5 réplicas?
3. ¿Cuál es la diferencia principal entre NodePort y LoadBalancer?
4. ¿Cuándo usarías un Service headless en lugar de ClusterIP?
5. ¿Cómo diagnosticarías un Service que existe pero no tiene Endpoints?

<details>
<summary>Ver Respuestas</summary>

1. Las IPs de Pods son efímeras (cambian al recrearse). Services proporcionan una IP estable y DNS que persisten independientemente del ciclo de vida de los Pods.

2. Kubernetes actualiza automáticamente los Endpoints, agregando las IPs de los 2 nuevos Pods. El Service balancea tráfico entre los 5 Pods sin intervención manual.

3. **NodePort**: Expone en `<NodeIP>:<NodePort>` (30000-32767). **LoadBalancer**: Crea balanceador externo con IP pública (solo en cloud providers).

4. Headless cuando necesitas:
   - Acceso directo a Pods específicos (StatefulSets)
   - Tu app maneja balanceo de carga internamente
   - Descubrir todas las IPs de Pods vía DNS

5. Diagnóstico:
   ```bash
   kubectl get endpoints <service>          # Ver si está vacío
   kubectl get svc <service> -o yaml        # Ver selector
   kubectl get pods -l <selector> --show-labels  # Ver si hay Pods matching
   # Si no hay match, corregir selector o labels
   ```
</details>

### Escenario Práctico
Diseña la arquitectura de Services para:
- App web (React) - pública
- API (Node.js) - interna + externa
- Base de datos (PostgreSQL StatefulSet) - solo interna
- Cache (Redis) - solo interna

<details>
<summary>Solución Sugerida</summary>

```yaml
# React App - LoadBalancer
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 3000

# API - LoadBalancer + ClusterIP interno
apiVersion: v1
kind: Service
metadata:
  name: api-external
spec:
  type: LoadBalancer
  selector:
    app: api
  ports:
    - port: 443
      targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: api-internal  # Para llamadas internas
spec:
  type: ClusterIP
  selector:
    app: api
  ports:
    - port: 8080

# PostgreSQL - Headless (para StatefulSet)
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  clusterIP: None  # Headless
  selector:
    app: postgres
  ports:
    - port: 5432

# Redis - ClusterIP
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  type: ClusterIP
  selector:
    app: redis
  ports:
    - port: 6379
```
</details>

---

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Connecting Applications](https://kubernetes.io/docs/tutorials/services/connect-applications-service/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)

### Labs del Módulo
1. [Lab 01 - ClusterIP Basics](laboratorios/lab-01-clusterip-basics.md)
2. [Lab 02 - NodePort y LoadBalancer](laboratorios/lab-02-nodeport-loadbalancer.md)
3. [Lab 03 - Services Avanzados](laboratorios/lab-03-advanced-services.md)

### Ejemplos Prácticos
- [`ejemplos/01-clusterip/`](ejemplos/01-clusterip/) - Services internos
- [`ejemplos/02-nodeport/`](ejemplos/02-nodeport/) - Exposición con NodePort
- [`ejemplos/03-loadbalancer/`](ejemplos/03-loadbalancer/) - LoadBalancers
- [`ejemplos/04-externalname/`](ejemplos/04-externalname/) - Servicios externos
- [`ejemplos/05-endpoints/`](ejemplos/05-endpoints/) - Endpoints manuales
- [`ejemplos/06-headless/`](ejemplos/06-headless/) - Headless Services
- [`ejemplos/07-produccion/`](ejemplos/07-produccion/) - Configuraciones production-ready

### Siguiente Módulo
➡️ [Módulo 09 - Ingress Controllers](../modulo-09-ingress-external-access/)

---

## 🎉 ¡Felicitaciones!

Has completado el Módulo 08 de Services y Endpoints. Ahora tienes el conocimiento para:

- ✅ Diseñar arquitecturas de networking en Kubernetes
- ✅ Implementar comunicación interna y externa
- ✅ Diagnosticar y resolver problemas de Services
- ✅ Aplicar best practices de producción

**Próximos pasos**:
1. Revisar este resumen periódicamente
2. Practicar con los laboratorios
3. Aplicar estos conceptos en proyectos reales
4. Continuar con el Módulo 09: Ingress Controllers

¡Sigue adelante! 🚀
