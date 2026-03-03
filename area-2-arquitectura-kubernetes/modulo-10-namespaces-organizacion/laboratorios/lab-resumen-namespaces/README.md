# Resumen Practico: Namespaces y Organizacion en Kubernetes

**Duracion:** 60 minutos | **Nivel:** Repaso integral | **Archivo:** `namespaces-lab.yaml`

Un solo YAML despliega 3 namespaces con deployments, quotas, limits, RBAC y NetworkPolicies para practicar todos los conceptos de organizacion de un vistazo, usando Minikube.

---

## Conceptos Previos (para personas nuevas en Kubernetes)

Si recien empiezas con Kubernetes, estos conceptos te ayudaran a entender el lab antes de ejecutar cualquier comando.

**Que es un cluster**

Un cluster es un grupo de computadoras (llamadas nodos) que trabajan juntas y que Kubernetes administra como si fueran una sola maquina. Todos los recursos que creas en Kubernetes (Pods, Services, Deployments, etc.) viven dentro de ese cluster.

**Que son los recursos**

Kubernetes llama "recursos" a todo lo que puedes crear y administrar: un Pod es un recurso, un Service es un recurso, un Deployment es un recurso. Piensalos como objetos que el cluster conoce y mantiene funcionando.

**Que son los Namespaces**

Un Namespace es como una carpeta dentro del cluster. Organiza los recursos para que no se mezclen entre si y evita conflictos de nombres. Puedes tener un Pod llamado `webapp` en el namespace `dev` y otro Pod tambien llamado `webapp` en el namespace `prod` sin ningun conflicto, porque cada uno vive en su propia carpeta.

**La analogia del edificio de oficinas**

Imagina el cluster como un edificio de oficinas:

```
Cluster Kubernetes  =  Edificio de oficinas
Namespace dev       =  Piso 1 (equipo de desarrollo)
Namespace staging   =  Piso 2 (equipo de QA)
Namespace prod      =  Piso 3 (produccion, acceso restringido)
```

Cada piso tiene:
- Sus propios recursos (escritorios, impresoras = Pods, Services)
- Su propio presupuesto (ResourceQuota)
- Sus propias reglas de gasto individual (LimitRange)
- Su propio sistema de control de acceso (RBAC)
- Sus propios guardias de seguridad en la puerta (NetworkPolicy)

Este lab crea exactamente ese escenario con 3 namespaces y te permite ver como funciona cada mecanismo.

---

## Que es un Namespace

Un **Namespace** es una division logica dentro de un cluster Kubernetes. Permite aislar recursos, aplicar politicas y organizar cargas de trabajo sin necesitar multiples clusters.

```
Cluster Kubernetes
├── lab-ns-dev      → equipo de desarrollo (quota limitada, RBAC)
├── lab-ns-staging  → QA y testing (sin restricciones extra)
└── lab-ns-prod     → produccion (quota estricta, NetworkPolicy, aislamiento)
```

**Namespace NO aisla red ni storage por defecto.** Para aislamiento de red se necesitan NetworkPolicies. Para aislamiento de recursos se necesitan ResourceQuotas.

---

## Conceptos Cubiertos en Este Lab

| Concepto | Que demuestra |
|----------|---------------|
| **Namespaces con labels** | Organizar y filtrar namespaces por entorno, equipo, criticidad |
| **DNS cross-namespace** | Acceder a `webapp.lab-ns-prod` desde `lab-ns-dev` |
| **ResourceQuota** | Limitar CPU, memoria y cantidad de pods totales en un namespace |
| **LimitRange** | Defaults automaticos y rangos min/max por container |
| **RBAC por namespace** | ServiceAccount con permisos solo en su namespace |
| **NetworkPolicy** | Deny-all + allow-same-ns para aislamiento de red en prod |

---

## Diagrama Visual

```
                    ┌──────────────────────────────────────────────────┐
                    │              CLUSTER MINIKUBE                    │
                    │                                                  │
  ┌─────────────────│──────────────────────────────────────────────────│
  │ lab-ns-dev      │                                                  │
  │                 │  webapp (2 replicas)     ResourceQuota (1 CPU)   │
  │                 │  Service webapp          LimitRange (defaults)   │
  │                 │  dev-admin (RBAC)        test-tools (Pod)        │
  │                 │  DNS: webapp.lab-ns-dev                          │
  ├─────────────────│──────────────────────────────────────────────────│
  │ lab-ns-staging  │                                                  │
  │                 │  webapp (2 replicas)     Sin restricciones extra │
  │                 │  Service webapp                                  │
  │                 │  DNS: webapp.lab-ns-staging                      │
  ├─────────────────│──────────────────────────────────────────────────│
  │ lab-ns-prod     │                                                  │
  │                 │  webapp (3 replicas)     ResourceQuota (2 CPU)   │
  │                 │  Service webapp          LimitRange (defaults)   │
  │                 │  NetworkPolicy deny-all  NetworkPolicy allow-ns  │
  │                 │  DNS: webapp.lab-ns-prod                         │
  └─────────────────│──────────────────────────────────────────────────│
                    └──────────────────────────────────────────────────┘
```

---

## Paso 0: Preparar Minikube (2 min)

```bash
minikube start

# Verificar
minikube status
kubectl cluster-info
```

---

## Paso 1: Desplegar Todo (2 min)

```bash
kubectl apply -f namespaces-lab.yaml
```

Verificar:

```bash
# Ver los 3 namespaces creados
kubectl get ns -l lab=namespaces-resumen

# Ver todos los recursos
kubectl get all -n lab-ns-dev
kubectl get all -n lab-ns-staging
kubectl get all -n lab-ns-prod
```

**Salida esperada:** 3 namespaces, cada uno con webapp Deployment + Service. Dev tiene quota, limits, RBAC y pod de prueba. Prod tiene quota, limits y NetworkPolicies.

---

## Paso 2: Explorar Namespaces y Labels (5 min)

### 2.1: Filtrar por labels

```bash
# Todos los namespaces del lab
kubectl get ns -l lab=namespaces-resumen

# Solo produccion
kubectl get ns -l env=prod

# Namespaces criticos
kubectl get ns -l critical=true

# Ver labels completos
kubectl get ns -l lab=namespaces-resumen --show-labels
```

### 2.2: Ver annotations

```bash
kubectl describe ns lab-ns-prod | grep -A 5 Annotations
```

**Salida esperada:**
```
Annotations:  sla: 99.9% uptime
              contact: platform@company.com
```

### 2.3: Comparar replicas entre namespaces

```bash
kubectl get deployments -l app=webapp --all-namespaces
```

**Salida esperada:**
```
NAMESPACE        NAME     READY   REPLICAS
lab-ns-dev       webapp   2/2     2
lab-ns-staging   webapp   2/2     2
lab-ns-prod      webapp   3/3     3
```

Mismo nombre `webapp` en 3 namespaces — recursos completamente independientes.

---

## Paso 3: DNS Cross-Namespace (8 min)

### 3.1: Entrar al pod de prueba

```bash
kubectl exec -it test-tools -n lab-ns-dev -- sh
```

Dentro del pod, instalar herramientas:

```sh
apk add --no-cache curl bind-tools
```

### 3.2: DNS en el mismo namespace

```sh
# Short name funciona (mismo namespace)
nslookup webapp
# Resuelve: webapp.lab-ns-dev.svc.cluster.local

curl -s http://webapp | grep Namespace
# Namespace: lab-ns-dev
```

### 3.3: DNS cross-namespace

```sh
# Acceder a staging
curl -s http://webapp.lab-ns-staging | grep Namespace
# Namespace: lab-ns-staging

# Acceder a produccion
curl -s http://webapp.lab-ns-prod | grep Namespace
# Namespace: lab-ns-prod

# FQDN completo
nslookup webapp.lab-ns-prod.svc.cluster.local

exit
```

**Formato DNS:**
```
<service>                              → mismo namespace
<service>.<namespace>                  → cross-namespace
<service>.<namespace>.svc.cluster.local → FQDN completo
```

---

## Que es ResourceQuota (concepto)

Imagina que cada piso del edificio tiene un presupuesto mensual de electricidad y agua. Si el equipo de desarrollo gasta demasiado, los demas pisos quedan sin recursos. ResourceQuota es ese presupuesto: un limite que define cuanto CPU, cuanta memoria y cuantos Pods puede usar el namespace completo, en total, sumando todos sus contenedores.

Sin ResourceQuota, un solo namespace podria consumir todos los recursos del cluster y dejar sin CPU o memoria a los demas.

---

## Paso 4: ResourceQuota (10 min)

### 4.1: Ver quotas configuradas

```bash
# Quota de dev
kubectl describe resourcequota dev-quota -n lab-ns-dev

# Quota de prod
kubectl describe resourcequota prod-quota -n lab-ns-prod
```

**Salida esperada (dev):**
```
Resource         Used    Hard
--------         ----    ----
limits.cpu       225m    2
limits.memory    320Mi   2Gi
pods             3       10
requests.cpu     125m    1
requests.memory  160Mi   1Gi
services         1       5
```

### 4.2: Intentar exceder la quota

```bash
# Crear pods hasta acercarse al limite de CPU
kubectl run quota-test-1 --image=nginx -n lab-ns-dev \
  --requests='cpu=300m,memory=256Mi' \
  --limits='cpu=500m,memory=512Mi'

kubectl run quota-test-2 --image=nginx -n lab-ns-dev \
  --requests='cpu=300m,memory=256Mi' \
  --limits='cpu=500m,memory=512Mi'

# Este debe fallar (excede requests.cpu=1)
kubectl run quota-test-3 --image=nginx -n lab-ns-dev \
  --requests='cpu=300m,memory=256Mi' \
  --limits='cpu=500m,memory=512Mi'
# Error: exceeded quota

# Ver estado de la quota
kubectl describe resourcequota dev-quota -n lab-ns-dev
```

### 4.3: Staging no tiene quota (sin limites)

```bash
# En staging se pueden crear pods sin restriccion de quota
kubectl run no-limit-1 --image=nginx -n lab-ns-staging
kubectl run no-limit-2 --image=nginx -n lab-ns-staging
kubectl run no-limit-3 --image=nginx -n lab-ns-staging

# Todos funcionan — no hay ResourceQuota en staging
kubectl get pods -n lab-ns-staging
```

---

**Que aprendimos en este paso:**
- ResourceQuota es un limite agregado: aplica a la suma de todos los Pods del namespace
- Si el total de CPU o memoria supera el limite, Kubernetes rechaza los nuevos Pods
- Un namespace sin ResourceQuota puede consumir recursos sin restriccion (como staging en este lab)

---

## Que es LimitRange (concepto)

Si ResourceQuota es el presupuesto del piso, LimitRange es la regla de cuanto puede gastar cada persona individual dentro de ese piso.

ResourceQuota dice: "el piso entero no puede gastar mas de 2 CPU en total".
LimitRange dice: "cada persona no puede pedir mas de 500m CPU, y si no pide nada, le asignamos 100m por defecto".

LimitRange resuelve un problema practico: cuando alguien crea un Pod sin especificar cuantos recursos necesita, Kubernetes no sabe como contarlo contra la ResourceQuota. LimitRange define valores por defecto automaticos para que eso nunca sea un problema.

---

## Paso 5: LimitRange - Defaults Automaticos (8 min)

### 5.1: Ver LimitRange configurado

```bash
kubectl describe limitrange dev-limits -n lab-ns-dev
```

**Salida esperada:**
```
Type        Resource  Min   Max    Default  DefaultRequest
----        --------  ---   ---    -------  --------------
Container   cpu       25m   500m   100m     50m
Container   memory    32Mi  512Mi  128Mi    64Mi
```

### 5.2: Crear pod sin especificar recursos

```bash
# Eliminar pods de prueba de quota
kubectl delete pod quota-test-1 quota-test-2 -n lab-ns-dev

# Crear pod SIN requests/limits
kubectl run default-test --image=nginx -n lab-ns-dev

# Ver que se aplicaron defaults automaticamente
kubectl get pod default-test -n lab-ns-dev -o yaml | grep -A 8 resources:
```

**Salida esperada:**
```yaml
resources:
  limits:
    cpu: 100m        # default del LimitRange
    memory: 128Mi
  requests:
    cpu: 50m         # defaultRequest del LimitRange
    memory: 64Mi
```

### 5.3: Intentar exceder el maximo

```bash
kubectl run too-big --image=nginx -n lab-ns-dev \
  --requests='cpu=600m,memory=256Mi' \
  --limits='cpu=1,memory=512Mi'
# Error: max cpu is 500m
```

### 5.4: Comparar con staging (sin LimitRange)

```bash
# Los pods en staging no tienen defaults aplicados
kubectl get pod no-limit-1 -n lab-ns-staging -o yaml | grep -A 4 resources:
# resources: {} (vacio)
```

---

## Que es RBAC (concepto)

RBAC (Role-Based Access Control) es como la tarjeta de acceso del edificio. Determina que puertas puede abrir cada persona.

En Kubernetes, "personas" son ServiceAccounts (cuentas de servicio que usan las aplicaciones y los operadores). RBAC define:
- Que acciones puede realizar una cuenta (leer, crear, borrar recursos)
- En que namespace puede realizar esas acciones

Un Role define los permisos dentro de un namespace. Un RoleBinding asigna ese Role a una cuenta especifica. La combinacion Role + RoleBinding hace que los permisos sean estrictamente locales: el dev-admin de este lab puede crear Pods en `lab-ns-dev` pero no puede ni siquiera ver los Pods de `lab-ns-prod`.

---

## Paso 6: RBAC - Control de Acceso (8 min)

### 6.1: Verificar permisos del dev-admin

```bash
# Puede crear pods en su namespace
kubectl auth can-i create pods \
  --as=system:serviceaccount:lab-ns-dev:dev-admin \
  -n lab-ns-dev
# yes

# Puede crear deployments en su namespace
kubectl auth can-i create deployments \
  --as=system:serviceaccount:lab-ns-dev:dev-admin \
  -n lab-ns-dev
# yes
```

### 6.2: Verificar aislamiento RBAC

```bash
# NO puede acceder a staging
kubectl auth can-i get pods \
  --as=system:serviceaccount:lab-ns-dev:dev-admin \
  -n lab-ns-staging
# no

# NO puede acceder a produccion
kubectl auth can-i get pods \
  --as=system:serviceaccount:lab-ns-dev:dev-admin \
  -n lab-ns-prod
# no

# NO puede ver nodos del cluster
kubectl auth can-i get nodes \
  --as=system:serviceaccount:lab-ns-dev:dev-admin
# no
```

**Clave:** Role (no ClusterRole) + RoleBinding = permisos SOLO en un namespace.

**Que aprendimos en este paso:**
- RBAC controla quien puede hacer que, no quienes pueden hablar entre si (eso es NetworkPolicy)
- Un Role define permisos dentro de un unico namespace
- `kubectl auth can-i` es la forma rapida de verificar permisos sin tener que ejecutar el comando real

---

## Que es NetworkPolicy (concepto)

Por defecto, cualquier Pod en cualquier namespace puede comunicarse con cualquier otro Pod del cluster. Es como si todas las personas del edificio pudieran entrar a cualquier piso sin restricciones.

NetworkPolicy pone guardias de seguridad en la puerta de cada piso. Puedes definir reglas exactas: quien puede entrar, desde donde puede entrar y a traves de que puerta (puerto).

El patron mas comun en produccion es:
1. `deny-all`: bloquea todo el trafico entrante por defecto (el guarda bloquea a todos)
2. `allow-same-namespace`: permite trafico entre Pods del mismo namespace (los companeros del piso pueden visitarse)

Con ese patron, nadie desde fuera del namespace puede acceder a los Pods de produccion, pero los Pods dentro de produccion si pueden comunicarse entre si.

---

## Paso 7: NetworkPolicy - Aislamiento de Red (10 min)

### 7.1: Ver NetworkPolicies en prod

```bash
kubectl get networkpolicies -n lab-ns-prod
```

**Salida esperada:**
```
NAME                   POD-SELECTOR   AGE
deny-all-ingress       <none>         5m
allow-same-namespace   <none>         5m
```

### 7.2: Probar acceso intra-namespace (debe funcionar)

```bash
# Crear pod de prueba en prod
kubectl run test-prod --image=alpine -n lab-ns-prod \
  --command -- sleep 3600

# Esperar que este Running
kubectl wait --for=condition=Ready pod/test-prod -n lab-ns-prod --timeout=30s

# Instalar curl
kubectl exec test-prod -n lab-ns-prod -- apk add --no-cache curl

# Acceso dentro de prod (debe funcionar)
kubectl exec test-prod -n lab-ns-prod -- \
  curl -s --max-time 5 http://webapp.lab-ns-prod | grep Namespace
# Namespace: lab-ns-prod
```

### 7.3: Probar acceso cross-namespace (debe fallar en prod)

```bash
# Desde dev intentar acceder a prod
kubectl exec test-tools -n lab-ns-dev -- \
  curl -s --max-time 5 http://webapp.lab-ns-prod
# Timeout — bloqueado por NetworkPolicy deny-all en prod

# Desde dev acceder a staging (funciona, staging no tiene NetworkPolicy)
kubectl exec test-tools -n lab-ns-dev -- \
  curl -s --max-time 5 http://webapp.lab-ns-staging | grep Namespace
# Namespace: lab-ns-staging
```

**Resultado:**
```
dev → staging:  PERMITIDO (sin NetworkPolicy)
dev → prod:     BLOQUEADO (deny-all + allow-same-ns)
prod → prod:    PERMITIDO (allow-same-namespace)
```

**Que aprendimos en este paso:**
- Los Namespaces NO aislan la red por si solos: sin NetworkPolicy todo el trafico esta permitido
- El patron deny-all + allow-same-namespace es el estandar para aislar produccion
- staging no tiene NetworkPolicy, por eso dev puede acceder a el libremente
- NetworkPolicy actua sobre el trafico de red (paquetes TCP/UDP), no sobre permisos de Kubernetes API

---

## Paso 8: Gestion Multi-Namespace (5 min)

### 8.1: Comandos utiles

```bash
# Todos los pods del lab en todos los namespaces
kubectl get pods -l app=webapp --all-namespaces

# Contar pods por namespace
kubectl get pods --all-namespaces -l lab=namespaces-resumen --no-headers 2>/dev/null
kubectl get pods -n lab-ns-dev --no-headers | wc -l
kubectl get pods -n lab-ns-staging --no-headers | wc -l
kubectl get pods -n lab-ns-prod --no-headers | wc -l

# Ver quotas de todos los namespaces del lab
for ns in lab-ns-dev lab-ns-staging lab-ns-prod; do
  echo "=== $ns ==="
  kubectl get resourcequota -n $ns 2>/dev/null || echo "  (sin quota)"
done
```

### 8.2: Cambiar namespace por defecto

```bash
# Cambiar a dev
kubectl config set-context --current --namespace=lab-ns-dev
kubectl get pods  # muestra pods de dev

# Cambiar a prod
kubectl config set-context --current --namespace=lab-ns-prod
kubectl get pods  # muestra pods de prod

# Restaurar a default
kubectl config set-context --current --namespace=default
```

---

## Tabla Comparativa

```
┌─────────────────┬──────────────┬──────────────┬──────────────────┐
│ Concepto        │ lab-ns-dev   │ lab-ns-staging│ lab-ns-prod     │
├─────────────────┼──────────────┼──────────────┼──────────────────┤
│ Replicas webapp │ 2            │ 2            │ 3                │
│ ResourceQuota   │ Si (1 CPU)   │ No           │ Si (2 CPU)       │
│ LimitRange      │ Si           │ No           │ Si               │
│ RBAC            │ Si (dev-admin│ No           │ No               │
│ NetworkPolicy   │ No           │ No           │ Si (deny+allow)  │
│ Labels env      │ dev          │ staging      │ prod             │
│ Annotations SLA │ No           │ No           │ 99.9%            │
└─────────────────┴──────────────┴──────────────┴──────────────────┘
```

---

## Cuando Usar Cada Concepto

| Situacion | Concepto | Por que |
|-----------|----------|---------|
| Separar entornos (dev/staging/prod) | Namespaces + Labels | Aislamiento logico, filtrado por label |
| Evitar que dev consuma todo el cluster | ResourceQuota | Limita recursos agregados |
| Pods sin requests fallan por quota | LimitRange | Aplica defaults automaticamente |
| Equipo solo accede a su namespace | RBAC (Role+RoleBinding) | Permisos locales al namespace |
| Aislar red entre namespaces | NetworkPolicy | deny-all + allow expliciTo |
| Acceder a service de otro namespace | DNS cross-namespace | `<svc>.<ns>.svc.cluster.local` |

---

## Limpieza (2 min)

```bash
chmod +x cleanup.sh
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-ns-dev lab-ns-staging lab-ns-prod
kubectl config set-context --current --namespace=default
```

---

## Checklist de Verificacion

- [ ] 3 namespaces creados con labels y annotations
- [ ] Webapp desplegada en los 3 namespaces
- [ ] DNS cross-namespace funciona (dev → staging, dev → prod)
- [ ] ResourceQuota bloquea pods al exceder limite
- [ ] LimitRange aplica defaults automaticamente
- [ ] RBAC: dev-admin tiene permisos solo en lab-ns-dev
- [ ] NetworkPolicy: prod aislado (deny-all + allow-same-ns)
- [ ] Sabe cambiar namespace con `kubectl config set-context`
