# Ejemplos de Services y Endpoints

Esta carpeta contiene ejemplos prácticos de Services en Kubernetes, organizados por categoría de complejidad creciente.

## 📋 Índice de Ejemplos

### 01. ClusterIP (Básico)

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`service-clusterip-basic.yaml`](01-clusterip/service-clusterip-basic.yaml) | Service ClusterIP básico | ClusterIP, selector, DNS interno, balanceo automático |
| [`service-multi-port.yaml`](01-clusterip/service-multi-port.yaml) | Service con múltiples puertos | Nombres de puertos, targetPort por nombre, Prometheus annotations |
| [`service-session-affinity.yaml`](01-clusterip/service-session-affinity.yaml) | Session affinity (sticky sessions) | sessionAffinity: ClientIP, timeoutSeconds, casos de uso |

### 02. NodePort (Acceso Externo)

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`service-nodeport-basic.yaml`](02-nodeport/service-nodeport-basic.yaml) | NodePort básico (acceso externo) | NodePort range (30000-32767), acceso por cualquier nodo |
| [`service-nodeport-custom-port.yaml`](02-nodeport/service-nodeport-custom-port.yaml) | NodePort con puerto personalizado | Puerto fijo, externalTrafficPolicy, preservación de IP |

### 03. LoadBalancer (Cloud)

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`service-loadbalancer-basic.yaml`](03-loadbalancer/service-loadbalancer-basic.yaml) | LoadBalancer básico | IP pública, cloud provider integration, provisioning automático |
| [`service-loadbalancer-annotations.yaml`](03-loadbalancer/service-loadbalancer-annotations.yaml) | LoadBalancer con annotations | AWS ELB/NLB, GCP, Azure, SSL termination, internal LB |

### 04. ExternalName (DNS)

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`service-externalname-basic.yaml`](04-externalname/service-externalname-basic.yaml) | ExternalName (redirección DNS) | CNAME, servicios externos, migración gradual, abstracción |

### 05. Endpoints (Manuales)

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`service-manual-endpoints.yaml`](05-endpoints/service-manual-endpoints.yaml) | Service con Endpoints manuales | Service sin selector, IPs externas, control total de backends |

### 06. Headless (StatefulSets)

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`service-headless-statefulset.yaml`](06-headless/service-headless-statefulset.yaml) | Headless Service con StatefulSet | clusterIP: None, DNS por Pod, aplicaciones stateful (MySQL) |

### 07. Producción (Best Practices)

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`service-production-ready.yaml`](07-produccion/service-production-ready.yaml) | Service production-ready completo | HA, monitoring, security, HPA, PDB, NetworkPolicy |
| [`service-external-traffic-policy.yaml`](07-produccion/service-external-traffic-policy.yaml) | Comparación Cluster vs Local | externalTrafficPolicy, preservación IP, trade-offs |

---

## 🚀 Quick Start

### Aplicar un ejemplo individual

```bash
# ClusterIP básico
kubectl apply -f 01-clusterip/service-clusterip-basic.yaml

# NodePort
kubectl apply -f 02-nodeport/service-nodeport-basic.yaml

# LoadBalancer (requiere cloud provider)
kubectl apply -f 03-loadbalancer/service-loadbalancer-basic.yaml
```

### Aplicar todos los ejemplos de una categoría

```bash
# Todos los ClusterIP
kubectl apply -f 01-clusterip/

# Todos los NodePort
kubectl apply -f 02-nodeport/
```

### Verificar Services creados

```bash
# Listar todos los Services
kubectl get services

# Ver detalles
kubectl describe service <nombre-service>

# Ver Endpoints
kubectl get endpoints <nombre-service>
```

---

## 📚 Ruta de Aprendizaje

### Nivel Básico (Empezar aquí)

1. **ClusterIP básico** (`01-clusterip/service-clusterip-basic.yaml`)
   - Concepto fundamental de Services
   - DNS interno
   - Comunicación entre Pods

2. **Múltiples puertos** (`01-clusterip/service-multi-port.yaml`)
   - Naming de puertos
   - targetPort flexible
   - Annotations (Prometheus)

3. **NodePort básico** (`02-nodeport/service-nodeport-basic.yaml`)
   - Acceso desde fuera del cluster
   - Puerto en el nodo
   - Casos de uso

### Nivel Intermedio

4. **Session Affinity** (`01-clusterip/service-session-affinity.yaml`)
   - Sticky sessions
   - Casos de uso (WebSockets, uploads)
   - Limitaciones

5. **LoadBalancer** (`03-loadbalancer/service-loadbalancer-basic.yaml`)
   - IP pública
   - Cloud integration
   - Costos y consideraciones

6. **ExternalName** (`04-externalname/service-externalname-basic.yaml`)
   - Redirección DNS
   - Migración gradual
   - Abstracción de servicios

### Nivel Avanzado

7. **Endpoints Manuales** (`05-endpoints/service-manual-endpoints.yaml`)
   - Integración con servicios externos
   - Control total de backends
   - Bases de datos externas

8. **Headless Services** (`06-headless/service-headless-statefulset.yaml`)
   - StatefulSets
   - DNS por Pod individual
   - Aplicaciones stateful (MySQL, MongoDB)

9. **ExternalTrafficPolicy** (`07-produccion/service-external-traffic-policy.yaml`)
   - Cluster vs Local
   - Preservación de IP origen
   - Trade-offs de performance

10. **Production-Ready** (`07-produccion/service-production-ready.yaml`)
    - Todas las best practices
    - HA, monitoring, security
    - HPA, PDB, NetworkPolicy

---

## 🎯 Casos de Uso por Tipo de Service

### ClusterIP (Interno)

```yaml
# Comunicación interna entre microservicios
Frontend → Service (ClusterIP) → Backend API
```

**Ejemplos:**
- `service-clusterip-basic.yaml` - Comunicación básica
- `service-multi-port.yaml` - API con múltiples endpoints
- `service-session-affinity.yaml` - Mantener sesiones

### NodePort (Desarrollo/Testing)

```yaml
# Acceso rápido desde fuera sin LoadBalancer
Desarrollador → http://node-ip:30080 → Service → Pods
```

**Ejemplos:**
- `service-nodeport-basic.yaml` - Acceso básico
- `service-nodeport-custom-port.yaml` - Puerto estandarizado

### LoadBalancer (Producción Cloud)

```yaml
# IP pública para acceso desde Internet
Internet → LoadBalancer IP → Service → Pods
```

**Ejemplos:**
- `service-loadbalancer-basic.yaml` - Producción simple
- `service-loadbalancer-annotations.yaml` - Configuración avanzada (SSL, internal)

### ExternalName (Integración)

```yaml
# Redirección a servicios externos
Pod → Service (ExternalName) → DNS → api.example.com
```

**Ejemplos:**
- `service-externalname-basic.yaml` - Migración, abstracción

### Headless (Stateful)

```yaml
# Acceso directo a Pods individuales
App → mysql-0.mysql-headless → Pod específico
```

**Ejemplos:**
- `service-headless-statefulset.yaml` - MySQL cluster, replicación

---

## 🔧 Comandos Útiles

### Inspección de Services

```bash
# Ver todos los Services
kubectl get svc

# Ver con más detalles
kubectl get svc -o wide

# Describir Service específico
kubectl describe svc <nombre>

# Ver YAML completo
kubectl get svc <nombre> -o yaml

# Ver solo ClusterIP
kubectl get svc <nombre> -o jsonpath='{.spec.clusterIP}'

# Ver solo NodePort
kubectl get svc <nombre> -o jsonpath='{.spec.ports[0].nodePort}'

# Ver External IP (LoadBalancer)
kubectl get svc <nombre> -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Inspección de Endpoints

```bash
# Ver Endpoints
kubectl get endpoints

# Endpoints de un Service específico
kubectl get endpoints <nombre-service>

# Detalles completos
kubectl describe endpoints <nombre-service>

# IPs de Endpoints en formato lista
kubectl get endpoints <nombre-service> \
  -o jsonpath='{.subsets[*].addresses[*].ip}' | tr ' ' '\n'
```

### Testing desde Pods

```bash
# Crear Pod de debug
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# Dentro del Pod:
/ # nslookup <nombre-service>
/ # wget -O- http://<nombre-service>
/ # telnet <nombre-service> <puerto>

# Con curl
kubectl run -it --rm test --image=curlimages/curl --restart=Never -- sh
# curl http://<nombre-service>
```

### Port-Forward para Testing Local

```bash
# Exponer Service localmente
kubectl port-forward service/<nombre-service> 8080:80

# Luego en otra terminal:
curl http://localhost:8080
```

### Watch (Monitoreo en tiempo real)

```bash
# Ver cambios en Services
kubectl get svc -w

# Ver cambios en Endpoints
kubectl get endpoints -w

# Ver logs de Service específico
kubectl logs -f -l app=<label>
```

---

## 🧪 Laboratorios Relacionados

Los laboratorios prácticos que usan estos ejemplos:

1. **[Laboratorio 01: ClusterIP Básico](../laboratorios/lab-01-clusterip-basics.md)** (40 min)
   - Crear primer Service ClusterIP
   - DNS discovery
   - Endpoints automáticos
   - **Usa:** `01-clusterip/service-clusterip-basic.yaml`

2. **[Laboratorio 02: NodePort y LoadBalancer](../laboratorios/lab-02-nodeport-loadbalancer.md)** (50 min)
   - NodePort para acceso externo
   - LoadBalancer en cloud
   - Comparar tipos de Services
   - **Usa:** `02-nodeport/*.yaml`, `03-loadbalancer/*.yaml`

3. **[Laboratorio 03: Services Avanzados](../laboratorios/lab-03-advanced-services.md)** (60 min)
   - ExternalName
   - Headless Services
   - Endpoints manuales
   - Best practices de producción
   - **Usa:** `04-externalname/*.yaml`, `05-endpoints/*.yaml`, `06-headless/*.yaml`, `07-produccion/*.yaml`

---

## 📖 Documentación Principal

Volver a [README principal del módulo](../README.md) para:
- Teoría completa de Services
- Tipos de Services en detalle
- Endpoints y kube-proxy
- Mejores prácticas
- Troubleshooting

---

## 🔍 Comparación de Tipos de Service

| Tipo | ClusterIP | NodePort | LoadBalancer | ExternalName | Headless |
|------|-----------|----------|--------------|--------------|----------|
| **IP interna** | ✅ Sí | ✅ Sí | ✅ Sí | ❌ No | ❌ None |
| **Puerto en nodo** | ❌ No | ✅ Sí (30000-32767) | ✅ Sí (auto) | ❌ No | ❌ No |
| **IP pública** | ❌ No | ❌ No | ✅ Sí | ❌ No | ❌ No |
| **DNS retorna** | ClusterIP | ClusterIP | ClusterIP | CNAME externo | IPs de Pods |
| **Load balancing** | ✅ Sí | ✅ Sí | ✅ Sí | ❌ No (DNS) | ⚠️ Cliente decide |
| **Usa Endpoints** | ✅ Sí | ✅ Sí | ✅ Sí | ❌ No | ✅ Sí |
| **Caso de uso** | Interno | Dev/Testing | Producción cloud | Migración | StatefulSets |
| **Ejemplo** | `01-clusterip/` | `02-nodeport/` | `03-loadbalancer/` | `04-externalname/` | `06-headless/` |

---

## ⚠️ Consideraciones Importantes

### ClusterIP
- Solo accesible DENTRO del cluster
- No exponer servicios críticos sin NetworkPolicy
- Usar DNS names, no IPs hardcoded

### NodePort
- Rango limitado: 30000-32767 (solo 2768 Services)
- Puerto no estándar (confuso para usuarios)
- Abrir firewall en TODOS los nodos
- **NO recomendado para producción pública**

### LoadBalancer
- **Costo:** Cada Service = nuevo LoadBalancer ($20-30/mes)
- Requiere cloud provider (AWS, GCP, Azure)
- Timeout de provisioning: 1-3 minutos
- **Alternativa para múltiples services:** Ingress Controller

### ExternalName
- Solo DNS CNAME (no IPs directas)
- Sin health checks
- Depende de TTL del DNS externo
- Puede fallar con SNI/TLS

### Headless
- Sin ClusterIP (None)
- Requiere StatefulSet para DNS por Pod
- Cliente responsable de balanceo
- Ideal para bases de datos con replicación

---

## 🎓 Siguientes Pasos

Después de dominar estos ejemplos:

1. **Ingress Controllers**
   - Routing HTTP/HTTPS avanzado
   - 1 LoadBalancer para múltiples Services
   - TLS termination
   - Path-based routing

2. **Service Mesh (Istio, Linkerd)**
   - Traffic management avanzado
   - mTLS automático
   - Observability mejorada
   - Circuit breaking

3. **NetworkPolicies**
   - Seguridad de red
   - Ingress/Egress rules
   - Micro-segmentation

4. **External-DNS**
   - Sincronización automática con DNS externo
   - Route53, CloudDNS, etc.

5. **Cert-Manager**
   - Certificados SSL automáticos
   - Let's Encrypt integration
   - Renovación automática

---

## 📞 Soporte

- **Documentación oficial:** https://kubernetes.io/docs/concepts/services-networking/service/
- **Laboratorios prácticos:** Ver carpeta `../laboratorios/`
- **README principal:** [`../README.md`](../README.md)

---

**¡Feliz aprendizaje!** 🚀
