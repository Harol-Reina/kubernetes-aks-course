# Capítulo 31: Network Policies y Seguridad de Red

En el capítulo anterior dominamos RBAC: ahora ningún usuario ni ServiceAccount puede llamar a la API de Kubernetes sin los permisos correctos. El plano de control está protegido — pero la red entre Pods sigue completamente abierta.

Imagina que un atacante compromete tu Pod de frontend a través de una vulnerabilidad en la aplicación web. Sin Network Policies, ese Pod comprometido puede abrir una conexión TCP directamente contra el Pod de la base de datos, contra el servicio de pagos, contra el almacén de secretos internos. No hay nada que lo impida. RBAC no protege el tráfico de red entre Pods: solo protege las llamadas a la API de Kubernetes.

Las Network Policies son el mecanismo de Kubernetes para definir reglas de firewall a nivel de Pod. Actuando como listas de control de acceso de red, permiten especificar exactamente qué Pods pueden hablar con qué otros Pods, en qué puertos y en qué dirección — tanto ingress (tráfico entrante) como egress (tráfico saliente).

Piensa en RBAC como el control de acceso al edificio: determina quién puede entrar. Las Network Policies son los controles de acceso dentro del edificio: una vez adentro, determinan a qué salas puede acceder cada persona. Un empleado de marketing puede entrar al edificio (RBAC), pero no puede entrar a la sala de servidores (Network Policy).

En este capítulo aprenderás a crear una política de denegación total por defecto (default deny), a escribir reglas de ingress y egress con selectores de Pods y namespaces, a aislar namespaces entre sí, a entender las diferencias entre Calico y Azure CNI con Network Policies habilitadas, y a aplicar los patrones más comunes de segmentación de red en producción.

---

## Sin Network Policies: El Riesgo

### La Red Plana por Defecto

Kubernetes fue diseñado con una premisa de red optimista: por defecto, **todo Pod puede comunicarse con todo Pod**, sin importar el namespace, el nodo en el que corren, ni el propósito de la aplicación. Esta arquitectura de "red plana" simplifica el despliegue inicial, pero introduce riesgos severos en entornos de producción.

Cuando no existe ninguna Network Policy en un namespace, el comportamiento es el siguiente:

- Un Pod en `namespace-a` puede hacer peticiones HTTP al Puerto 8080 de un Pod en `namespace-b`
- Un Pod de la capa frontend puede conectarse directamente al puerto 5432 del Pod de PostgreSQL
- Un Pod de testing puede alcanzar los endpoints de servicios de producción
- Cualquier Pod comprometido puede escanear y conectarse a cualquier otro servicio del cluster

Este comportamiento existe porque la especificación de Kubernetes garantiza conectividad entre Pods para facilitar la comunicación de microservicios. Es una decisión de diseño correcta para entornos de desarrollo, pero inaceptable en producción.

### Escenario de Ataque: Movimiento Lateral

El movimiento lateral es una técnica de ataque donde, una vez comprometido un sistema inicial, el atacante se mueve a otros sistemas dentro de la misma red. Sin Network Policies, Kubernetes facilita involuntariamente este patrón:

```
Paso 1: Atacante explota vulnerabilidad en la aplicación web (p.ej. SSRF, RCE)
Paso 2: El atacante obtiene ejecución de comandos en el Pod frontend
Paso 3: Desde el Pod comprometido, escanea la red interna:
        $ curl http://database-service.database.svc.cluster.local:5432
        $ curl http://payments-api.payments.svc.cluster.local:8080
        $ curl http://secrets-vault.vault.svc.cluster.local:8200
Paso 4: Extrae datos sensibles, credenciales, o compromete la base de datos
Paso 5: Pivota hacia otros servicios usando las credenciales obtenidas
```

Este escenario no es teórico: es el vector de ataque más común en clusters Kubernetes en producción que carecen de segmentación de red.

### Diagrama: El Problema y la Solución

```
SIN Network Policies:
┌─────────────────────────────────────────────┐
│                  Cluster                     │
│                                             │
│  ┌─────────┐   ┌─────────┐   ┌──────────┐  │
│  │   Web   │◀─▶│   API   │◀─▶│    DB    │  │
│  │ :80     │   │ :8080   │   │ :5432    │  │
│  └─────────┘   └─────────┘   └──────────┘  │
│       ▲               ▲            ▲         │
│       │               │            │         │
│       ▼               ▼            ▼         │
│  ┌───────────────────────────────────────┐  │
│  │         Attacker Pod                  │  │
│  │  (accede a TODOS los servicios)       │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘

CON Network Policies:
┌─────────────────────────────────────────────┐
│                  Cluster                     │
│                                             │
│  ┌─────────┐ ──▶ ┌─────────┐ ──▶ ┌──────┐  │
│  │   Web   │     │   API   │     │  DB  │  │
│  │ :80     │     │ :8080   │     │:5432 │  │
│  └─────────┘     └─────────┘     └──────┘  │
│       ▲                                      │
│       │              ✗ bloqueado  ✗ bloqueado│
│       ▼              ✗            ✗          │
│  ┌───────────────────────────────────────┐  │
│  │         Attacker Pod                  │  │
│  │  (solo puede alcanzar Web :80)        │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

Con Network Policies correctamente configuradas, incluso si el Pod de frontend es comprometido, el atacante no puede alcanzar la base de datos ni los servicios de backend. El radio de explosión (blast radius) queda contenido.

### Implicaciones de Compliance

Las regulaciones de seguridad modernas exigen segmentación de red como control obligatorio:

| Regulación | Requisito | Relevancia en K8s |
|-----------|-----------|------------------|
| **PCI-DSS** | Req. 1: Segmentación de red para datos de tarjetas | Network Policies entre namespaces de pago |
| **SOC 2** | Aislamiento lógico de sistemas | Default deny entre entornos (prod/staging) |
| **HIPAA** | Controles de acceso a datos de salud | Políticas estrictas en namespaces con PHI |
| **ISO 27001** | Control A.13.1: Segregación en redes | Microsegmentación por tier de aplicación |
| **GDPR** | Minimización de acceso a datos personales | Restricción de acceso a datastores con PII |

En un cluster sin Network Policies, es prácticamente imposible demostrar compliance con PCI-DSS para cargas de trabajo que procesan datos de tarjetas de pago.

---

## Default Deny vs Default Allow

### El Comportamiento por Defecto de Kubernetes

Cuando no existe ninguna NetworkPolicy en un namespace, Kubernetes aplica la política implícita de **permitir todo**: cualquier Pod puede enviar y recibir tráfico de cualquier fuente. Este comportamiento es el "default allow".

Sin embargo, en cuanto **cualquier** NetworkPolicy selecciona un Pod en un namespace, el comportamiento cambia fundamentalmente: **todo el tráfico no explícitamente permitido por alguna política queda bloqueado**. Esto se denomina el modelo "whitelist" o "default deny implícito".

La confusión surge aquí: Kubernetes no tiene un "modo default deny global". En cambio, la presencia de una NetworkPolicy que selecciona un Pod activa el deny implícito solo para ese Pod y solo para los tipos de tráfico (Ingress/Egress) que la política declara en `policyTypes`.

### Cómo Funciona el Modelo de Acumulación

Las NetworkPolicies son **aditivas** (no reemplazantes): cuando múltiples políticas seleccionan el mismo Pod, sus reglas se unen con lógica OR. Si alguna política permite el tráfico, el tráfico está permitido.

```
Pod A es seleccionado por:
  - NetworkPolicy "allow-from-frontend"  → permite ingress desde tier=frontend
  - NetworkPolicy "allow-monitoring"     → permite ingress desde namespace=monitoring

Resultado: Pod A acepta ingress desde tier=frontend OR namespace=monitoring.
           Rechaza todo lo demás (default deny implícito porque existe al menos una NP).
```

### Patrones de Denegación por Defecto

#### Patrón 1: Default Deny Solo Ingress

Bloquea todo el tráfico entrante al namespace. El tráfico saliente (egress) no se ve afectado.

```yaml
# Uso: kubectl apply -f default-deny-ingress.yaml
#
# Descripcion:
#   Bloquea todo el trafico entrante a todos los Pods del namespace.
#   Los Pods aun pueden iniciar conexiones salientes.
#   Aplicar como base y luego agregar politicas de allow especificas.
#
# Namespace: production
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}        # {} selecciona TODOS los Pods del namespace
  policyTypes:
  - Ingress              # Solo aplica a trafico entrante
  # Sin reglas de ingress = nada permitido en entrada
```

Verificar que aplica:
```bash
kubectl get networkpolicy default-deny-ingress -n production
# NAME                   POD-SELECTOR   AGE
# default-deny-ingress   <none>         5s

# Probar desde un Pod externo (debe fallar):
kubectl exec -n staging test-pod -- curl -s --max-time 3 http://my-service.production.svc.cluster.local
# curl: (28) Connection timed out after 3001 milliseconds
```

#### Patrón 2: Default Deny Solo Egress

Bloquea toda conexión saliente. Menos común pero útil para Pods que solo deben recibir conexiones (p.ej. bases de datos).

```yaml
# Uso: kubectl apply -f default-deny-egress.yaml
#
# Descripcion:
#   Bloquea todo el trafico saliente de todos los Pods del namespace.
#   Util para namespaces que alojan datos sensibles y no deben
#   iniciar conexiones hacia el exterior.
#
# ADVERTENCIA: Bloquea tambien DNS (puerto 53). Agregar regla de DNS explicitamente.
#
# Namespace: production
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  # Sin reglas de egress = nada permitido en salida (incluyendo DNS)
```

#### Patrón 3: Default Deny Total (Ingress + Egress)

El patrón más restrictivo. Todos los Pods del namespace quedan completamente aislados. Ideal como política base en namespaces de producción, complementada con políticas de allow específicas.

```yaml
# Uso: kubectl apply -f default-deny-all.yaml
#
# Descripcion:
#   Bloquea TODO el trafico (entrante y saliente) en el namespace.
#   Es el punto de partida recomendado para namespaces de produccion.
#
#   Flujo de trabajo:
#   1. Aplicar esta politica base
#   2. Agregar politicas allow-dns (SIEMPRE necesario)
#   3. Agregar politicas de ingress especificas para cada servicio
#   4. Agregar politicas de egress para dependencias externas
#
# Namespace: production
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}        # Selecciona TODOS los Pods del namespace
  policyTypes:
  - Ingress              # Bloquea todo trafico entrante
  - Egress               # Bloquea todo trafico saliente
  # Ausencia de reglas ingress/egress = nada permitido
```

### Arbol de Decisión: Qué Política Usar

```
¿El namespace aloja servicios que reciben tráfico externo?
     │
     ├── SÍ ──▶ ¿Los Pods también inician conexiones salientes?
     │               │
     │               ├── SÍ ──▶ Usa default-deny-all
     │               │          + políticas allow específicas para ingress y egress
     │               │          + SIEMPRE permite DNS (egress UDP/TCP :53)
     │               │
     │               └── NO ──▶ Usa default-deny-ingress
     │                          (los Pods solo reciben, no inician conexiones)
     │
     └── NO ──▶ ¿El namespace aloja bases de datos u otros datastores sensibles?
                    │
                    ├── SÍ ──▶ Usa default-deny-all
                    │          (máximo aislamiento para datos sensibles)
                    │
                    └── NO ──▶ Evalúa si el namespace requiere
                               aislamiento de otros namespaces
```

---

## Conceptos de Network Policies

Las **Network Policies** son un mecanismo para controlar el tráfico de red entre Pods usando reglas similares a firewalls.

### Tipos de Políticas

1. **Ingress**: Tráfico entrante al Pod
2. **Egress**: Tráfico saliente del Pod

### Requisitos

- **CNI Plugin** compatible (ej: Calico, Cilium)
- **Azure CNI** con Network Policies habilitadas

---

## Anatomía de una Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: example-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: allowed
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

---

## Deep Dive: Network Policy Spec

Entender cada campo del spec de NetworkPolicy es fundamental para escribir políticas correctas. Los errores más comunes provienen de malinterpretar la lógica AND/OR entre selectores.

### Campo: podSelector

`podSelector` determina **a qué Pods aplica esta política**. No determina quién puede conectarse — eso lo hacen las reglas de ingress/egress.

```yaml
spec:
  podSelector:
    matchLabels:
      app: api-server      # La politica aplica a Pods con label app=api-server
```

Cuando `podSelector` es vacío (`{}`), la política aplica a **todos los Pods** del namespace:

```yaml
spec:
  podSelector: {}          # Aplica a todos los Pods del namespace
```

### Campo: policyTypes

Declara qué tipos de tráfico regula esta política. Si no se especifica `policyTypes`, Kubernetes infiere:
- Si hay reglas `ingress` pero no `egress` → solo `Ingress`
- Si hay reglas `egress` → incluye `Egress`

Sin embargo, la práctica recomendada es **siempre declarar `policyTypes` explícitamente**:

```yaml
spec:
  policyTypes:
  - Ingress    # Esta politica controla trafico entrante
  - Egress     # Esta politica controla trafico saliente
```

### Campo: ingress — Fuentes Permitidas

Las reglas `ingress` definen qué tráfico puede **entrar** a los Pods seleccionados. Cada elemento en la lista `from` puede usar tres tipos de selectores:

#### podSelector: seleccionar por etiquetas de Pod

```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        role: frontend      # Solo Pods con role=frontend pueden conectarse
  ports:
  - protocol: TCP
    port: 8080
```

Por defecto, `podSelector` dentro de `ingress.from` selecciona Pods del **mismo namespace**. Para Pods en otros namespaces, combinar con `namespaceSelector`.

#### namespaceSelector: seleccionar por etiquetas de Namespace

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        environment: production   # Pods de cualquier NS con label env=production
```

Para que `namespaceSelector` funcione, el namespace debe tener la etiqueta declarada:
```bash
kubectl label namespace monitoring kubernetes.io/metadata.name=monitoring
kubectl label namespace monitoring environment=production
```

#### ipBlock: seleccionar por rangos CIDR

Útil para permitir tráfico desde IPs externas (p.ej. load balancer, VPN):

```yaml
ingress:
- from:
  - ipBlock:
      cidr: 192.168.1.0/24     # Permite toda la subred 192.168.1.x
      except:
      - 192.168.1.5/32         # Excepto esta IP específica
```

### La Trampa AND vs OR: El Error Más Común

Este es el error más frecuente y peligroso al escribir Network Policies.

#### Caso 1: OR — Elementos separados en la lista `from`

Cuando los selectores son **ítems separados** en la lista, la lógica es OR. El tráfico está permitido si coincide con **cualquiera** de los selectores:

```yaml
# LOGICA OR: permite si es frontend O si es del namespace monitoring
ingress:
- from:
  - podSelector:              # Opcion 1: Pod con role=frontend (cualquier namespace)
      matchLabels:
        role: frontend
  - namespaceSelector:        # Opcion 2: Cualquier Pod del namespace monitoring
      matchLabels:
        name: monitoring
```

Diagrama:
```
Trafico permitido si:
  ┌─────────────────────────────┐
  │  role=frontend (cualquier NS) │  ─── OR ───▶ PERMITIDO
  └─────────────────────────────┘
  ┌─────────────────────────────┐
  │  NS con name=monitoring     │  ─── OR ───▶ PERMITIDO
  └─────────────────────────────┘
```

#### Caso 2: AND — Selectores en el mismo ítem

Cuando `podSelector` y `namespaceSelector` están **en el mismo ítem** (sin separador `-`), la lógica es AND. El tráfico solo está permitido si coincide con **ambos** selectores simultáneamente:

```yaml
# LOGICA AND: solo permite si es frontend Y está en namespace production
ingress:
- from:
  - podSelector:              # El Pod DEBE tener role=frontend
      matchLabels:
        role: frontend
    namespaceSelector:        # Y ADEMAS el namespace DEBE ser production
      matchLabels:
        environment: production
```

Diagrama:
```
Trafico permitido solo si:
  ┌─────────────────────────────┐
  │  role=frontend              │  ─── AND ───▶ PERMITIDO
  │  AND environment=production │
  └─────────────────────────────┘

Pods con role=frontend en namespace staging → BLOQUEADO
Pods sin role=frontend en namespace production → BLOQUEADO
```

La diferencia visual entre AND y OR en YAML es un guión `-` adicional:

```yaml
# OR: dos guiones (dos items separados en la lista)
from:
- podSelector:         # item 1
    matchLabels:
      role: frontend
- namespaceSelector:   # item 2 (separado)
    matchLabels:
      environment: production

# AND: un solo guion (ambos selectores en el mismo item)
from:
- podSelector:         # item 1 con ambos selectores
    matchLabels:
      role: frontend
  namespaceSelector:   # mismo item (sin guion)
    matchLabels:
      environment: production
```

### Campo: egress — Destinos Permitidos

Las reglas `egress` definen a qué destinos pueden conectarse los Pods seleccionados. Usa los mismos selectores que ingress (`podSelector`, `namespaceSelector`, `ipBlock`) pero en un campo `to`:

```yaml
egress:
- to:
  - podSelector:
      matchLabels:
        app: database       # Solo puede conectarse a Pods con app=database
  ports:
  - protocol: TCP
    port: 5432              # Solo en puerto 5432

# Permitir DNS (SIEMPRE necesario con default-deny-egress)
- to:
  - namespaceSelector: {}   # Cualquier namespace (kube-system donde vive CoreDNS)
    podSelector:
      matchLabels:
        k8s-app: kube-dns   # Solo al Pod de CoreDNS
  ports:
  - protocol: UDP
    port: 53
  - protocol: TCP
    port: 53
```

---

## Comparación: Calico vs Azure Network Policy Provider

La elección del proveedor de Network Policies tiene implicaciones significativas en las capacidades disponibles y en cómo se gestiona la seguridad de red del cluster.

### Tabla Comparativa

| Característica | Azure NPP | Calico |
|---------------|-----------|--------|
| **Soporte de Ingress** | Si | Si |
| **Soporte de Egress** | Limitado | Si (completo) |
| **Reglas CIDR (ipBlock)** | No | Si |
| **GlobalNetworkPolicy** | No | Si (extensión Calico) |
| **Logs de trafico bloqueado** | No | Si (con eBPF/iptables) |
| **Performance** | Nativo (eBPF) | Bueno (iptables/eBPF) |
| **Integración AKS** | Nativa | Add-on |
| **Calico-specific CRDs** | No | Si (HostEndpoint, etc.) |
| **NetworkSet (CIDR groups)** | No | Si |
| **Soporte IPv6** | Parcial | Si |
| **Costo en AKS** | Incluido | Incluido (OSS) / De pago (Enterprise) |

### Azure Network Policy Provider (Azure NPP)

Azure NPP es el proveedor nativo de AKS. Implementa las especificaciones estándar de NetworkPolicy de Kubernetes usando las primitivas de red de Azure VNet. Es la opción más sencilla para clusters AKS que no requieren capacidades avanzadas.

**Limitaciones importantes:**
- El soporte de egress es incompleto: no soporta `ipBlock` en reglas de egress en todas las versiones
- No permite definir políticas globales que apliquen a todo el cluster (solo por namespace)
- No genera logs de tráfico bloqueado, lo que dificulta el debugging y el audit trail

**Cuándo usarlo:**
- Clusters AKS nuevos con requisitos estándar de NetworkPolicy
- Entornos donde la simplicidad operacional prima sobre las capacidades avanzadas
- Cuando se requiere integración nativa con Azure VNet

### Calico

Calico es el CNI plugin de red de código abierto más utilizado en producción con Kubernetes. Además de implementar las NetworkPolicies estándar de Kubernetes, ofrece sus propias CRDs (`GlobalNetworkPolicy`, `NetworkSet`, `HostEndpoint`) que extienden significativamente las capacidades.

**Capacidades adicionales de Calico:**
- `GlobalNetworkPolicy`: políticas que aplican a todo el cluster, sin estar limitadas a un namespace
- `NetworkSet`: grupos de CIDRs con nombre, reutilizables en múltiples políticas
- `HostEndpoint`: políticas para el tráfico que entra/sale del nodo (no solo Pods)
- Logs detallados de tráfico bloqueado para auditoría y troubleshooting

```bash
# Verificar qué proveedor de Network Policy está activo en AKS
az aks show \
  --resource-group rg-kubernetes-course \
  --name mi-cluster \
  --query networkProfile.networkPolicy
# Salida esperada: "azure" o "calico"

# En el cluster, verificar el CNI plugin activo
kubectl get pods -n kube-system | grep -E "calico|azure-npm"
# Si es Calico:
# calico-node-xxxxx          1/1     Running   0   10m
# calico-kube-controllers    1/1     Running   0   10m
# Si es Azure NPP:
# azure-npm-xxxxx            1/1     Running   0   10m
```

### Consideraciones de Migración

Migrar de Azure NPP a Calico (o viceversa) en un cluster en producción requiere planificación cuidadosa:

```bash
# La migracion requiere recrear el cluster en AKS
# No es posible cambiar el proveedor de Network Policy en un cluster existente
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-calico \
  --network-plugin azure \
  --network-policy calico \    # Especificar Calico en la creación
  --node-count 3

# Para Calico con VXLAN overlay (mas flexible):
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-calico-overlay \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --network-policy calico \
  --node-count 3
```

---

## Ejemplos de Network Policies

### Denegar Todo el Tráfico

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: secure-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Permitir Tráfico entre Tiers

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-to-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: web
    ports:
    - protocol: TCP
      port: 8080
```

### Permitir Tráfico desde Namespace Específico

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-monitoring
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090
```

---

## Patrones Comunes de Network Policies

Los siguientes patrones representan las soluciones más utilizadas en producción. Cada uno resuelve un problema recurrente de segmentación de red.

### Patrón 1: Aislamiento de Microservicios — Arquitectura 3-Tier

El patrón más común: una aplicación con capa web, capa API y base de datos. Solo se permite comunicación en la dirección correcta del flujo.

```
Internet ──▶ Web (namespace: frontend) ──▶ API (namespace: backend) ──▶ DB (namespace: database)
              :80                             :8080                         :5432
```

```yaml
# Politica 1: La API solo acepta trafico desde el namespace frontend
# Uso: kubectl apply -f policy-api-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-from-frontend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          tier: web              # AND: debe ser del NS frontend Y tener label tier=web
    ports:
    - protocol: TCP
      port: 8080
---
# Politica 2: La DB solo acepta trafico desde el namespace backend
# Uso: kubectl apply -f policy-db-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-from-backend
  namespace: database
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: backend
      podSelector:
        matchLabels:
          tier: api              # AND: debe ser del NS backend Y tener label tier=api
    ports:
    - protocol: TCP
      port: 5432
```

### Patrón 2: Protección de Base de Datos

Una variación enfocada en proteger al máximo el datastore: solo aplicaciones explícitamente autorizadas pueden conectarse, y la DB nunca inicia conexiones salientes.

```yaml
# Uso: kubectl apply -f policy-db-protection.yaml
#
# Descripcion:
#   Aislamiento completo para un Pod de base de datos.
#   Solo acepta conexiones de Pods con label authorized-db-client=true.
#   No puede iniciar ninguna conexion saliente.
#
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-protection
  namespace: production
spec:
  podSelector:
    matchLabels:
      role: database
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          authorized-db-client: "true"  # Solo clientes autorizados explicitamente
    ports:
    - protocol: TCP
      port: 5432
  egress: []    # Sin reglas de egress = ningun trafico saliente permitido
```

Para autorizar un nuevo cliente de DB, simplemente agregar la etiqueta:
```bash
kubectl label deployment api-server authorized-db-client=true -n production
```

### Patrón 3: Aislamiento de Namespace

Los namespaces en Kubernetes no proveen aislamiento de red por defecto. Este patrón asegura que los Pods de un namespace solo puedan comunicarse con otros Pods del mismo namespace.

```yaml
# Uso: kubectl apply -f policy-namespace-isolation.yaml
#
# Descripcion:
#   Aplica en el namespace "staging".
#   Los Pods de staging solo pueden hablar con otros Pods de staging.
#   Bloquea todo trafico cruzado entre namespaces.
#
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: namespace-isolation
  namespace: staging
spec:
  podSelector: {}            # Aplica a todos los Pods del namespace
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}        # Solo desde Pods del mismo namespace (sin namespaceSelector)
  egress:
  - to:
    - podSelector: {}        # Solo hacia Pods del mismo namespace
  # Nota: Agregar regla de DNS para que la resolucion de nombres funcione
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

### Patrón 4: Permitir Monitoreo (Prometheus)

Prometheus necesita hacer scraping de métricas de Pods en múltiples namespaces. Este patrón permite que el namespace de monitoreo alcance los endpoints de métricas sin romper el aislamiento general.

```yaml
# Uso: kubectl apply -f policy-allow-monitoring.yaml
#
# Descripcion:
#   Permite que Prometheus (namespace: monitoring) pueda hacer scraping
#   de metricas en el puerto 9090 de todos los Pods del namespace production.
#   Se aplica en el namespace production.
#
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prometheus-scraping
  namespace: production
spec:
  podSelector: {}            # Aplica a todos los Pods de production
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
      podSelector:
        matchLabels:
          app: prometheus    # Solo el Pod de Prometheus, no cualquier Pod de monitoring
    ports:
    - protocol: TCP
      port: 9090             # Puerto de metricas Prometheus
    - protocol: TCP
      port: 8080             # Puerto alternativo de metricas (si aplica)
```

### Patrón 5: Permitir DNS (CRITICO)

**Este es el patrón más importante cuando se usa default-deny-egress.** DNS usa el puerto UDP 53 (y TCP 53 para respuestas largas). Si se bloquea egress sin una regla de DNS, todos los pods pierden la capacidad de resolver nombres de host, lo que rompe prácticamente toda comunicación de servicio a servicio.

```yaml
# Uso: kubectl apply -f policy-allow-dns.yaml
#
# Descripcion:
#   SIEMPRE aplicar esta politica junto con default-deny-egress.
#   Sin esta regla, los Pods no pueden resolver nombres DNS y toda
#   comunicacion de servicio a servicio falla silenciosamente.
#
#   CoreDNS corre en kube-system con label k8s-app=kube-dns.
#
# Namespace: production
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: production
spec:
  podSelector: {}            # Aplica a todos los Pods del namespace
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns  # CoreDNS en kube-system
    ports:
    - protocol: UDP
      port: 53               # DNS sobre UDP (principal)
    - protocol: TCP
      port: 53               # DNS sobre TCP (respuestas grandes, fallback)
```

Verificar que DNS funciona después de aplicar la política:
```bash
# Lanzar pod de prueba en el namespace con default-deny-egress
kubectl run dns-test -n production --image=busybox:1.28 --rm -it -- \
  nslookup kubernetes.default.svc.cluster.local
# Salida esperada:
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
# Name:      kubernetes.default.svc.cluster.local
# Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

---

## Configurar Azure CNI con Network Policies

```bash
# Crear AKS con Azure CNI y Network Policies
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-network-policies \
  --network-plugin azure \
  --network-policy azure \
  --node-count 2
```

---

## Laboratorio 3.2: Implementar Network Policies

### Paso 1: Preparar Ambiente

```bash
# Crear namespaces
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database

# Label namespaces
kubectl label namespace frontend tier=frontend
kubectl label namespace backend tier=backend
kubectl label namespace database tier=database
```

Salida esperada:
```
namespace/frontend created
namespace/backend created
namespace/database created
namespace/frontend labeled
namespace/backend labeled
namespace/database labeled
```

### Paso 2: Desplegar Aplicaciones

```bash
# Frontend
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
EOF

# Backend
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        tier: backend
    spec:
      containers:
      - name: backend
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF

# Database
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
        tier: database
    spec:
      containers:
      - name: database
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: user
        - name: POSTGRES_PASSWORD
          value: password
        ports:
        - containerPort: 5432
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: database
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF
```

### Paso 3: Probar Conectividad Inicial

Antes de aplicar políticas, verificar que todo puede comunicarse (estado permisivo por defecto):

```bash
# Probar conectividad frontend → backend (debe funcionar)
kubectl exec -n frontend deployment/frontend -- curl -s --max-time 5 \
  backend-service.backend.svc.cluster.local
# Salida esperada: HTML de la página por defecto de nginx

# Probar conectividad backend → database
kubectl exec -n backend deployment/backend -- nc -zv \
  database-service.database.svc.cluster.local 5432
# Salida esperada:
# database-service.database.svc.cluster.local (10.x.x.x:5432) open

# Probar conectividad frontend → database (SIN politicas, esto FUNCIONA — problema!)
kubectl exec -n frontend deployment/frontend -- nc -zv \
  database-service.database.svc.cluster.local 5432
# Salida esperada (sin NP): open
# Esto demuestra el problema: frontend puede llegar a la DB directamente
```

### Paso 4: Implementar Network Policies

```bash
# Política: Solo frontend puede acceder a backend
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

# Política: Solo backend puede acceder a database
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
EOF

# Política: Frontend solo puede salir a backend
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 80
  # Permitir DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
EOF
```

### Paso 5: Verificar Políticas

```bash
# Verificar que frontend → backend funciona
kubectl exec -n frontend deployment/frontend -- curl -s backend-service.backend.svc.cluster.local
# Salida esperada: HTML de nginx (conexion exitosa)

# Verificar que frontend → database está bloqueado
kubectl exec -n frontend deployment/frontend -- nc -zv \
  -w 3 database-service.database.svc.cluster.local 5432
# Salida esperada: nc: database-service.database.svc.cluster.local: Connection timed out
# (timeout despues de 3 segundos — trafico bloqueado silenciosamente por la NP)

# Verificar que backend → database funciona
kubectl exec -n backend deployment/backend -- nc -zv \
  database-service.database.svc.cluster.local 5432
# Salida esperada: database-service.database.svc.cluster.local (10.x.x.x:5432) open
```

### Paso 6: Verificar las Políticas Aplicadas

```bash
# Listar todas las Network Policies en los namespaces del laboratorio
kubectl get networkpolicies -n frontend
kubectl get networkpolicies -n backend
kubectl get networkpolicies -n database

# Salida esperada para backend:
# NAME             POD-SELECTOR   AGE
# backend-policy   app=backend    2m

# Ver detalles de una política específica
kubectl describe networkpolicy backend-policy -n backend
# Name:         backend-policy
# Namespace:    backend
# Created on:   2026-03-01 ...
# Labels:       <none>
# Annotations:  <none>
# Spec:
#   PodSelector:     app=backend
#   Allowing ingress traffic:
#     To Port: 80/TCP
#     From:
#       NamespaceSelector: tier=frontend
#   Not affecting egress traffic
#   Policy Types: Ingress
```

---

## Testing de Network Policies

Verificar que las Network Policies funcionan correctamente es tan importante como escribirlas. Un error en la política puede dejar tráfico abierto que debería estar bloqueado, o bloquear tráfico legítimo silenciosamente.

### Herramientas para Testing

#### kubectl exec con curl

La forma más directa para probar conectividad HTTP:

```bash
# Crear Pod de prueba efimero (se elimina automaticamente al salir)
kubectl run test-client -n staging --image=curlimages/curl:latest \
  --rm -it --restart=Never -- \
  curl -v --max-time 5 http://backend-service.production.svc.cluster.local:8080

# Salida si PERMITIDO:
# * Connected to backend-service.production.svc.cluster.local (10.x.x.x) port 8080 (#0)
# ...
# HTTP/1.1 200 OK

# Salida si BLOQUEADO:
# * Trying 10.x.x.x:8080...
# * Connection timed out after 5001 milliseconds
# curl: (28) Connection timed out after 5001 milliseconds
```

#### netcat (nc) para testing TCP

Netcat es más directo para verificar conectividad TCP sin importar la capa de aplicación:

```bash
# Probar conectividad TCP al puerto 5432
kubectl run nc-test -n backend --image=busybox:1.28 \
  --rm -it --restart=Never -- \
  nc -zv -w 3 database-service.database.svc.cluster.local 5432

# Si ABIERTO (permitido):
# database-service.database.svc.cluster.local (10.x.x.x:5432) open

# Si CERRADO/BLOQUEADO:
# nc: database-service.database.svc.cluster.local: Connection timed out
```

#### Testing desde Pods en Namespaces Diferentes

Para probar políticas cruzadas entre namespaces:

```bash
# Crear Pod temporal en el namespace atacante para simular acceso no autorizado
kubectl run attacker -n staging --image=busybox:1.28 \
  --rm -it --restart=Never -- sh

# Dentro del Pod:
# Intentar alcanzar la base de datos de produccion (debe fallar):
nc -zv -w 3 database-service.production.svc.cluster.local 5432
# Esperado: Connection timed out

# Intentar alcanzar el frontend de produccion (puede estar permitido):
wget -q --timeout=3 -O - http://frontend-service.production.svc.cluster.local:80
```

### Script de Verificación Completa

Un script reutilizable para verificar el estado de las políticas en los tres namespaces del laboratorio:

```bash
#!/bin/bash
# Verificacion completa de Network Policies del laboratorio 3-tier

echo "=== Verificando conectividad PERMITIDA ==="
echo ""
echo "1. frontend → backend (debe FUNCIONAR):"
kubectl exec -n frontend deployment/frontend -- \
  curl -s --max-time 3 backend-service.backend.svc.cluster.local \
  && echo "  RESULTADO: OK - Conexion exitosa" \
  || echo "  RESULTADO: FALLO - No deberia fallar"

echo ""
echo "2. backend → database puerto 5432 (debe FUNCIONAR):"
kubectl exec -n backend deployment/backend -- \
  nc -zv -w 3 database-service.database.svc.cluster.local 5432 \
  && echo "  RESULTADO: OK - Puerto abierto" \
  || echo "  RESULTADO: FALLO - No deberia fallar"

echo ""
echo "=== Verificando trafico BLOQUEADO ==="
echo ""
echo "3. frontend → database (debe BLOQUEARSE):"
kubectl exec -n frontend deployment/frontend -- \
  nc -zv -w 3 database-service.database.svc.cluster.local 5432 2>&1 \
  | grep -q "timed out" \
  && echo "  RESULTADO: OK - Trafico correctamente bloqueado" \
  || echo "  RESULTADO: FALLO - Trafico deberia estar bloqueado"

echo ""
echo "Verificacion completada."
```

---

## Troubleshooting de Network Policies

Las Network Policies son una de las fuentes más frecuentes de problemas difíciles de diagnosticar en Kubernetes, porque los errores se manifiestan como timeouts silenciosos sin mensajes de error claros.

### Escenario 1: Política Aplicada pero el Tráfico Sigue Fluyendo

**Síntoma**: Se creó una NetworkPolicy pero el tráfico que debería estar bloqueado sigue pasando.

**Causa más común**: El CNI plugin no soporta Network Policies. Todos los CNIs implementan la conectividad básica entre Pods, pero no todos implementan el enforcement de Network Policies.

**Diagnóstico**:
```bash
# Verificar qué CNI está instalado en el cluster
kubectl get pods -n kube-system -o wide
# Buscar: calico-node, cilium, weave-net, azure-npm, etc.

# Si solo aparece kube-proxy o flannel sin un CNI de seguridad:
# CNIs que NO soportan Network Policies:
# - Flannel (solo conectividad, sin NP)
# - Simple kubenet (solo para clusters pequeños)

# CNIs que SÍ soportan Network Policies:
# - Calico
# - Cilium
# - WeaveNet
# - Azure CNI con --network-policy azure o calico

# Verificar en Minikube si el addon de Network Policies está habilitado
minikube addons list | grep network-policy
# Si aparece disabled, habilitar:
minikube start --network-plugin=cni --cni=calico
```

**Solución**:
```bash
# En Minikube, reiniciar con Calico como CNI:
minikube delete
minikube start --network-plugin=cni --cni=calico

# En un cluster con kubeadm, instalar Calico:
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml

# Verificar que Calico está corriendo:
kubectl get pods -n kube-system -l k8s-app=calico-node
# NAME                READY   STATUS    RESTARTS   AGE
# calico-node-xxxxx   1/1     Running   0          2m
```

### Escenario 2: DNS Dejó de Funcionar Después de Aplicar Default Deny

**Síntoma**: Después de aplicar una política de egress deny, los Pods no pueden resolver nombres de host. Comandos como `curl http://mi-servicio` fallan con "Name or service not known" aunque el servicio exista.

**Causa**: La política de egress deny bloquea todo el tráfico saliente, incluyendo las consultas DNS al puerto UDP 53 hacia CoreDNS en kube-system.

**Diagnóstico**:
```bash
# Probar resolucion DNS desde un Pod afectado
kubectl exec -n production mi-pod -- nslookup kubernetes.default
# Salida si DNS está bloqueado:
# ;; connection timed out; no servers could be reached

# Verificar que CoreDNS está corriendo
kubectl get pods -n kube-system -l k8s-app=kube-dns
# NAME                       READY   STATUS    RESTARTS   AGE
# coredns-xxxxx              1/1     Running   0          1h

# El problema es la política, no CoreDNS. Verificar políticas activas:
kubectl get networkpolicies -n production
kubectl describe networkpolicy default-deny-all -n production
```

**Solución**: Agregar regla de egress para DNS (ver Patrón 5 de la sección anterior):
```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF

# Verificar que DNS funciona de nuevo:
kubectl exec -n production mi-pod -- nslookup kubernetes.default
# Name:      kubernetes.default.svc.cluster.local
# Address 1: 10.96.0.1
```

### Escenario 3: Tráfico Cross-Namespace Bloqueado Inesperadamente

**Síntoma**: Un servicio en el namespace A no puede alcanzar un servicio en el namespace B, aunque haya una política que "debería" permitirlo.

**Causa**: Se usó solo `podSelector` en la regla `from`, que por defecto solo selecciona Pods del mismo namespace. Para Pods de otros namespaces, es necesario agregar `namespaceSelector`.

**Diagnóstico**:
```bash
# Política incorrecta: solo permite Pods del MISMO namespace con role=frontend
kubectl describe networkpolicy api-allow-frontend -n backend
# Spec:
#   Allowing ingress traffic:
#     From:
#       PodSelector: role=frontend   ← Solo del mismo namespace

# El Pod frontend está en el namespace 'frontend', no en 'backend'
# Por eso el tráfico está bloqueado aunque tenga el label correcto
```

**Solución**: Combinar `podSelector` con `namespaceSelector`:
```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-frontend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend   # namespace de origen
      podSelector:
        matchLabels:
          role: frontend                           # AND label del pod
    ports:
    - protocol: TCP
      port: 8080
EOF
```

### Escenario 4: La Política No Coincide con los Pods (Wrong Label Selector)

**Síntoma**: La política existe pero no tiene efecto: el tráfico que debería bloquear sigue pasando o el tráfico que debería permitir está bloqueado.

**Causa**: El selector de etiquetas en la NetworkPolicy no coincide con las etiquetas reales de los Pods.

**Diagnóstico**:
```bash
# Ver etiquetas reales de los Pods
kubectl get pods -n production --show-labels
# NAME                          LABELS
# api-deployment-abc-xyz        app=api-server,version=v2,env=prod

# Ver el selector en la NetworkPolicy
kubectl describe networkpolicy allow-api -n production
# Spec:
#   PodSelector: app=api   ← El pod tiene "app=api-server", no "app=api"

# El selector no coincide: "app=api" != "app=api-server"
# Herramienta util: verificar qué Pods selecciona un selector
kubectl get pods -n production -l app=api
# No resources found in production namespace.   ← Confirma el problema

kubectl get pods -n production -l app=api-server
# NAME                    READY   STATUS    RESTARTS   AGE
# api-deployment-abc-xyz  1/1     Running   0          1h
```

**Solución**:
```bash
# Opcion 1: Corregir el selector en la NetworkPolicy
kubectl edit networkpolicy allow-api -n production
# Cambiar: matchLabels: app: api
# Por:     matchLabels: app: api-server

# Opcion 2: Agregar la etiqueta que falta al Deployment
kubectl label deployment api-deployment app=api -n production --overwrite
```

### Escenario 5: Egress a Servicios Externos Bloqueado

**Síntoma**: Un Pod necesita hacer peticiones a una API externa (p.ej. `api.stripe.com`, `storage.googleapis.com`) pero las conexiones fallan con timeout. La política de egress deny está activa.

**Causa**: La política de egress solo permite conexiones a destinos internos (otros Pods/namespaces). Los rangos de IP externos están bloqueados.

**Diagnóstico**:
```bash
# Verificar conectividad a IP externa
kubectl exec -n production mi-pod -- curl -v --max-time 5 https://api.stripe.com
# curl: (28) Connection timed out after 5000 milliseconds

# Resolver la IP del servicio externo
nslookup api.stripe.com
# Address: 54.187.174.169

# Verificar politicas de egress activas
kubectl get networkpolicies -n production
kubectl describe networkpolicies -n production | grep -A 10 "Egress"
```

**Solución**: Agregar regla de egress con `ipBlock` para el rango de IPs del servicio externo:
```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-stripe-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      needs-payment-api: "true"     # Solo Pods que necesitan Stripe
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 54.187.0.0/16         # Rango de IPs de Stripe (verificar actualidad)
    ports:
    - protocol: TCP
      port: 443                     # HTTPS
EOF

# Etiquetar el Deployment que necesita acceso a Stripe:
kubectl label deployment payment-service needs-payment-api=true -n production
```

### Escenario 6: GlobalNetworkPolicy de Calico No Aplica

**Síntoma**: Se creó una `GlobalNetworkPolicy` de Calico pero no tiene efecto en el cluster. Las conexiones que debería bloquear siguen funcionando.

**Causa**: Los errores más comunes son: (1) el cluster usa Azure NPP en lugar de Calico, (2) la CRD de `GlobalNetworkPolicy` no está instalada, o (3) el selector `selector` de Calico tiene sintaxis diferente al `matchLabels` de Kubernetes estándar.

**Diagnóstico**:
```bash
# Verificar si Calico está instalado y soporta GlobalNetworkPolicy
kubectl get crd | grep calico
# globalnetworkpolicies.crd.projectcalico.org   2026-01-01T00:00:00Z
# Si no aparece GlobalNetworkPolicy, el cluster no usa Calico

# Verificar sintaxis de GlobalNetworkPolicy (Calico usa su propia sintaxis)
kubectl get globalnetworkpolicies
# Si da error "resource type not found", el cluster no tiene Calico

# Ver GlobalNetworkPolicies existentes (si Calico está instalado)
kubectl get globalnetworkpolicies -o yaml

# Verificar el estado del controlador de Calico
kubectl get pods -n kube-system -l k8s-app=calico-kube-controllers
# NAME                                      READY   STATUS    RESTARTS
# calico-kube-controllers-xxxxxxxxx-xxxxx   1/1     Running   0
```

**Solución**: Ejemplo de GlobalNetworkPolicy correcta con sintaxis de Calico:
```yaml
# NOTA: Este recurso es especifico de Calico (no es Kubernetes estandar)
# Requiere: kubectl get crd globalnetworkpolicies.crd.projectcalico.org
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: deny-all-namespaces-egress
spec:
  # Calico usa "selector" con su propia sintaxis (no matchLabels)
  selector: all()                  # Aplica a todos los endpoints del cluster
  types:
  - Egress
  egress:
  - action: Allow
    protocol: UDP
    destination:
      ports:
      - 53                         # Permitir DNS globalmente
  - action: Deny                   # Denegar todo lo demas
```

### Tabla de Diagnóstico Rápido

| Síntoma | Primera verificación | Comando de diagnóstico |
|---------|---------------------|----------------------|
| Tráfico fluye aunque hay NP | CNI soporta NP? | `kubectl get pods -n kube-system \| grep calico` |
| DNS no resuelve | Egress a kube-system bloqueado? | `kubectl exec pod -- nslookup kubernetes.default` |
| Cross-NS bloqueado | namespaceSelector agregado? | `kubectl describe netpol <name> -n <ns>` |
| NP no tiene efecto | Labels del pod coinciden? | `kubectl get pods --show-labels -n <ns>` |
| Timeout a IP externa | ipBlock en egress? | `kubectl describe netpol -n <ns>` |
| GlobalNetworkPolicy sin efecto | Calico instalado? | `kubectl get crd \| grep calico` |

---

## Resumen del Capítulo

Las Network Policies implementan segmentación de red dentro del cluster. Aprendimos a crear políticas de ingress y egress, aplicar el patrón "deny all + allow specific", y configurar una arquitectura 3-tier donde frontend solo habla con backend y backend solo habla con database. Requieren un CNI compatible (Calico, Cilium o Azure CNI).

Los conceptos clave de este capítulo son:

- **Red plana por defecto**: sin Network Policies, todo Pod puede alcanzar todo Pod — un riesgo inaceptable en producción
- **Default deny implícito**: cuando cualquier NetworkPolicy selecciona un Pod, el tráfico no cubierto por ninguna política queda bloqueado
- **AND vs OR en selectores**: los selectores en el mismo ítem usan lógica AND; los selectores en ítems separados de la lista usan lógica OR — este es el error más común
- **DNS es tráfico egress**: siempre permitir egress UDP/TCP al puerto 53 hacia kube-dns cuando se usa default-deny-egress
- **Calico vs Azure NPP**: Calico ofrece soporte completo de egress, CIDR rules y GlobalNetworkPolicy; Azure NPP es más simple pero limitado
- **Testing es obligatorio**: siempre verificar tanto el tráfico que debe estar permitido como el que debe estar bloqueado después de aplicar políticas
- **Compliance**: PCI-DSS, SOC 2 y HIPAA exigen segmentación de red — las Network Policies son el mecanismo para implementarla en Kubernetes
