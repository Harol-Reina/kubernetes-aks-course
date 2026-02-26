# Laboratorio 08: Proyecto Integrador - Deployment Completo

**Duracion estimada**: 90 minutos
**Dificultad**: Avanzado
**Objetivo**: Disenar e implementar un deployment production-ready completo integrando todos los conceptos del modulo

---

## Descripcion del Proyecto

Este laboratorio integrador pone en practica todos los conceptos del modulo de Deployments y Rollouts
aplicandolos a una arquitectura de e-commerce realista. A lo largo de 8 partes progresivas desplegamos
una aplicacion completa con frontend (5 replicas, security hardened), dos servicios backend con
estrategias de update diferenciadas, escalado automatico via HPA, alta disponibilidad via PodDisruptionBudgets,
una estrategia Blue-Green con switch de Service, y un ciclo completo de rollback.

**Habilidades evaluadas del modulo**:
- Deployments production-ready (ConfigMaps, Secrets, probes, securityContext, anti-affinity)
- Estrategias de despliegue: RollingUpdate con parametros diferenciados por servicio
- HPA con metricas de CPU y Memory y politicas de comportamiento
- PodDisruptionBudgets para garantizar disponibilidad durante mantenimiento
- Blue-Green deployment con switch instantaneo de Service selector
- Rollback manual con `kubectl rollout undo` y auditoria de historial

**Archivos YAML del laboratorio**:

| Archivo | Recursos | Parte |
|---------|----------|-------|
| `frontend-configmap.yaml` | ConfigMap `frontend-config` | 2 |
| `frontend-deployment.yaml` | Deployment `frontend-web` (5 replicas) | 2 |
| `frontend-service.yaml` | Service `frontend-service` (ClusterIP) | 2 |
| `frontend-hpa.yaml` | HPA `frontend-hpa` (min:3, max:15) | 4 |
| `frontend-deployment-green.yaml` | Deployment `frontend-web-green` (Green v2.0.0) | 6 |
| `backend-product-service.yaml` | Deployment + Service `product-service` | 3 |
| `backend-order-service.yaml` | Deployment + Service `order-service` | 3 |
| `pdb.yaml` | 3 PodDisruptionBudgets | 5 |

---

## Parte 1: Arquitectura y Diseno (15 min)

### Paso 1: Crear namespace del proyecto

```bash
# Crear namespace dedicado para el proyecto
kubectl create namespace ecommerce-prod

# Establecer como namespace activo
kubectl config set-context --current --namespace=ecommerce-prod
```

**Output esperado**:
```
namespace/ecommerce-prod created
Context "minikube" modified.
```

### Paso 2: Verificar namespace activo

```bash
kubectl config view --minify | grep namespace
```

**Output esperado**:
```
    namespace: ecommerce-prod
```

**Componentes a desplegar**:
- **Frontend**: Deployment `frontend-web` con ConfigMap, Secret, Service, HPA y PDB
- **Backend**: `product-service` y `order-service` con estrategias diferenciadas
- **Alta Disponibilidad**: PodDisruptionBudgets para todos los componentes
- **Blue-Green**: Version Green del frontend lista para switch

---

## Parte 2: Frontend Deployment (20 min)

### Paso 1: Revisar y aplicar ConfigMap del frontend

```bash
# Revisar el contenido del ConfigMap antes de aplicar
cat frontend-configmap.yaml

# Aplicar ConfigMap
kubectl apply -f frontend-configmap.yaml
```

**Output esperado**:
```
configmap/frontend-config created
```

```bash
# Verificar que el ConfigMap fue creado correctamente
kubectl get configmap frontend-config -n ecommerce-prod
kubectl describe configmap frontend-config -n ecommerce-prod
```

**Output esperado de describe**:
```
Name:         frontend-config
Namespace:    ecommerce-prod
Data
====
app-config.json:  ...
nginx.conf:       ...
```

### Paso 2: Crear Secrets para el frontend

Los Secrets se crean de forma imperativa para evitar almacenar credenciales en YAML:

```bash
kubectl create secret generic frontend-secrets \
  --from-literal=api-key='prod-api-key-abc123' \
  --from-literal=analytics-token='GA-XXXXX-YY' \
  -n ecommerce-prod
```

**Output esperado**:
```
secret/frontend-secrets created
```

### Paso 3: Revisar y desplegar el frontend

```bash
# Revisar el Deployment antes de aplicar
cat frontend-deployment.yaml

# Aplicar Deployment
kubectl apply -f frontend-deployment.yaml
```

**Output esperado**:
```
deployment.apps/frontend-web created
```

```bash
# Monitorear el rollout
kubectl rollout status deployment/frontend-web -n ecommerce-prod
```

**Output esperado**:
```
Waiting for deployment "frontend-web" rollout to finish: 0 of 5 updated replicas are available...
deployment "frontend-web" successfully rolled out
```

```bash
# Verificar Pods distribuidos entre nodos
kubectl get pods -l app=frontend -o wide -n ecommerce-prod
```

**Output esperado**:
```
NAME                            READY   STATUS    RESTARTS   AGE   NODE
frontend-web-7d9f8c5b4-abcde   1/1     Running   0          30s   minikube
frontend-web-7d9f8c5b4-fghij   1/1     Running   0          30s   minikube
...
```

### Paso 4: Revisar y crear el Service del frontend

```bash
# Revisar el Service antes de aplicar
cat frontend-service.yaml

# Aplicar Service
kubectl apply -f frontend-service.yaml
```

**Output esperado**:
```
service/frontend-service created
```

```bash
# Verificar Service y endpoints
kubectl get svc frontend-service -n ecommerce-prod
kubectl get endpoints frontend-service -n ecommerce-prod
```

**Output esperado**:
```
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
frontend-service   ClusterIP   10.96.100.50    <none>        80/TCP,9113/TCP   15s
```

---

## Parte 3: Backend Services (20 min)

### Paso 1: Revisar y desplegar Product Service

```bash
# Revisar Deployment + Service antes de aplicar
cat backend-product-service.yaml

# Aplicar (crea tanto el Deployment como el Service)
kubectl apply -f backend-product-service.yaml
```

**Output esperado**:
```
deployment.apps/product-service created
service/product-service created
```

### Paso 2: Revisar y desplegar Order Service

```bash
# Revisar Deployment + Service antes de aplicar
cat backend-order-service.yaml

# Aplicar
kubectl apply -f backend-order-service.yaml
```

**Output esperado**:
```
deployment.apps/order-service created
service/order-service created
```

### Paso 3: Verificar backends

```bash
# Ver todos los Deployments del namespace
kubectl get deployments -n ecommerce-prod

# Ver Pods del backend con etiquetas
kubectl get pods -l tier=backend -n ecommerce-prod
```

**Output esperado**:
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
frontend-web       5/5     5            5           3m
order-service      4/4     4            4           30s
product-service    3/3     3            3           45s
```

> **Nota sobre estrategias diferenciadas**:
> - `product-service`: `maxSurge:1, maxUnavailable:0` — zero-downtime, update conservador
> - `order-service`: `maxSurge:2, maxUnavailable:1` — update mas rapido, acepta 1 Pod no disponible

---

## Parte 4: Escalado Automatico (10 min)

### Paso 1: Habilitar metrics-server

```bash
# En minikube
minikube addons enable metrics-server

# Esperar a que metrics-server este listo (puede tardar 1-2 min)
kubectl top nodes
```

**Output esperado**:
```
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   200m         10%    900Mi           36%
```

### Paso 2: Revisar y aplicar HPA

```bash
# Revisar el HPA antes de aplicar
cat frontend-hpa.yaml

# Aplicar HPA
kubectl apply -f frontend-hpa.yaml
```

**Output esperado**:
```
horizontalpodautoscaler.autoscaling/frontend-hpa created
```

```bash
# Verificar estado del HPA
kubectl get hpa -n ecommerce-prod
```

**Output esperado**:
```
NAME           REFERENCE                 TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
frontend-hpa   Deployment/frontend-web   5%/70%, 3%/80%  3         15        5          30s
```

> **Nota**: Si metrics-server no esta listo, TARGETS mostrara `<unknown>/70%`.
> Espera 2-3 minutos y vuelve a ejecutar `kubectl get hpa`.

---

## Parte 5: Alta Disponibilidad (10 min)

### Paso 1: Revisar y aplicar PodDisruptionBudgets

```bash
# Revisar los 3 PDBs antes de aplicar
cat pdb.yaml

# Aplicar (crea los 3 PDBs en un solo comando)
kubectl apply -f pdb.yaml
```

**Output esperado**:
```
poddisruptionbudget.policy/frontend-pdb created
poddisruptionbudget.policy/product-service-pdb created
poddisruptionbudget.policy/order-service-pdb created
```

```bash
# Verificar estado de los PDBs
kubectl get pdb -n ecommerce-prod
```

**Output esperado**:
```
NAME                  MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
frontend-pdb          3               N/A               2                     15s
order-service-pdb     2               N/A               2                     15s
product-service-pdb   N/A             1                 1                     15s
```

> **Interpretacion**:
> - `frontend-pdb`: Con 5 replicas, permite interrumpir hasta 2 Pods simultaneamente
> - `product-service-pdb`: Solo permite 1 Pod interrumpido a la vez
> - `order-service-pdb`: Con 4 replicas, permite interrumpir hasta 2 Pods

---

## Parte 6: Blue-Green Deployment (15 min)

### Paso 1: Confirmar version Blue activa

El Deployment `frontend-web` ya en ejecucion es la version Blue (nginx:1.21-alpine, v1.0.0).

```bash
# Verificar version Blue activa
kubectl get deployment frontend-web -o jsonpath='{.spec.template.spec.containers[0].image}' -n ecommerce-prod
```

**Output esperado**:
```
nginx:1.21-alpine
```

### Paso 2: Revisar y desplegar version Green

```bash
# Revisar Deployment Green antes de aplicar
cat frontend-deployment-green.yaml

# Desplegar Green (no afecta al trafico actual)
kubectl apply -f frontend-deployment-green.yaml
```

**Output esperado**:
```
deployment.apps/frontend-web-green created
```

```bash
# Verificar que ambas versiones coexisten
kubectl get pods -l app=frontend -L version -n ecommerce-prod
```

**Output esperado**:
```
NAME                                  READY   STATUS    VERSION
frontend-web-7d9f8c5b4-abcde         1/1     Running   1.0.0
...
frontend-web-green-6c8d9f3a2-vwxyz   1/1     Running   green
...
```

### Paso 3: Crear Service temporal para testing de Green

```bash
# Exponer Green con Service temporal para validacion
kubectl expose deployment frontend-web-green \
  --name=frontend-green-test \
  --port=80 \
  --target-port=http \
  -n ecommerce-prod
```

**Output esperado**:
```
service/frontend-green-test exposed
```

```bash
# Probar Green antes del switch (en background)
kubectl port-forward svc/frontend-green-test 8081:80 -n ecommerce-prod &

# Verificar que Green responde
curl -s localhost:8081/health
```

**Output esperado**:
```
healthy
```

### Paso 4: Switch de trafico a Green

```bash
# Ver selector actual del Service (apunta a version Blue)
kubectl get svc frontend-service -o jsonpath='{.spec.selector}' -n ecommerce-prod
```

**Output esperado**:
```
{"app":"frontend","component":"web"}
```

```bash
# Agregar selector version:green para redirigir trafico a Green
kubectl patch service frontend-service -n ecommerce-prod \
  -p '{"spec":{"selector":{"app":"frontend","component":"web","version":"green"}}}'
```

**Output esperado**:
```
service/frontend-service patched
```

```bash
# Verificar que endpoints ahora apuntan a Pods Green
kubectl get endpoints frontend-service -n ecommerce-prod
```

**Output esperado**:
```
NAME               ENDPOINTS                                            AGE
frontend-service   172.17.0.20:80,172.17.0.21:80,172.17.0.22:80,...    15m
```

> **Nota**: Los endpoints ahora muestran las IPs de los Pods Green en lugar de los Blue.

> **Rollback instantaneo si Green tiene problemas**:
> ```bash
> kubectl patch service frontend-service -n ecommerce-prod \
>   -p '{"spec":{"selector":{"app":"frontend","component":"web"}}}'
> ```

---

## Parte 7: Implementar Rollback (10 min)

### Paso 1: Simular deployment problematico en frontend-web

```bash
# Actualizar frontend-web con imagen invalida (simula error en produccion)
kubectl set image deployment/frontend-web \
  nginx=nginx:invalid-tag \
  -n ecommerce-prod

# Anotar el cambio para el historial
kubectl annotate deployment/frontend-web \
  kubernetes.io/change-cause="v2.1.0 - PROBLEMA DETECTADO" \
  --overwrite \
  -n ecommerce-prod
```

### Paso 2: Monitorear el problema (en segunda terminal)

```bash
# En terminal 2: observar como los Pods nuevos fallan
watch kubectl get pods -l app=frontend,component=web -n ecommerce-prod
```

**Output esperado en terminal 2** (Pods con imagen invalida en ErrImagePull):
```
NAME                             READY   STATUS             RESTARTS
frontend-web-5b9c7f4d3-aaaaa    0/1     ErrImagePull       0
frontend-web-7d9f8c5b4-bbbbb    1/1     Running            0
...
```

### Paso 3: Revisar historial y hacer rollback

```bash
# En terminal 1: ver historial de revisiones
kubectl rollout history deployment/frontend-web -n ecommerce-prod
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         Initial production release v1.0.0
2         v2.1.0 - PROBLEMA DETECTADO
```

```bash
# Ejecutar rollback a la ultima revision estable
kubectl rollout undo deployment/frontend-web -n ecommerce-prod
```

**Output esperado**:
```
deployment.apps/frontend-web rolled back
```

```bash
# Verificar recuperacion
kubectl rollout status deployment/frontend-web -n ecommerce-prod
```

**Output esperado**:
```
deployment "frontend-web" successfully rolled out
```

---

## Parte 8: Validacion Final (10 min)

### Paso 1: Verificar todos los componentes

```bash
# Resumen completo del namespace
kubectl get deployments -n ecommerce-prod
kubectl get pods -n ecommerce-prod -o wide
kubectl get svc -n ecommerce-prod
kubectl get hpa -n ecommerce-prod
kubectl get pdb -n ecommerce-prod
```

**Output esperado de get deployments**:
```
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
frontend-web         5/5     5            5           25m
frontend-web-green   5/5     5            5           10m
order-service        4/4     4            4           20m
product-service      3/3     3            3           20m
```

### Paso 2: Verificar historiales de rollout

```bash
kubectl rollout history deployment/frontend-web -n ecommerce-prod
kubectl rollout history deployment/product-service -n ecommerce-prod
kubectl rollout history deployment/order-service -n ecommerce-prod
```

### Paso 3: Generar reporte del proyecto

```bash
cat > proyecto-ecommerce-report.md << 'EOF'
# Reporte del Proyecto E-commerce

## Componentes Desplegados

### Frontend
- Deployment: frontend-web (5 replicas, nginx:1.21-alpine, v1.0.0)
- Service: frontend-service (ClusterIP, sessionAffinity ClientIP)
- HPA: frontend-hpa (min:3, max:15, CPU:70%, Memory:80%)
- PDB: frontend-pdb (minAvailable:3)

### Backend
- Product Service: 3 replicas (maxSurge:1, maxUnavailable:0)
- Order Service: 4 replicas (maxSurge:2, maxUnavailable:1)
- PDB product-service: maxUnavailable:1
- PDB order-service: minAvailable:2

## Caracteristicas Implementadas

- [x] Rolling Updates sin downtime
- [x] Health checks (readiness, liveness, startup)
- [x] Resource limits configurados
- [x] Escalado automatico (HPA)
- [x] Alta disponibilidad (PDB)
- [x] Blue-Green deployment implementado
- [x] Rollback strategy probada
- [x] ConfigMaps y Secrets
- [x] Security context hardened (runAsNonRoot, readOnlyRootFilesystem)
- [x] Anti-affinity para distribucion entre nodos

## Metricas del Despliegue

- Pods totales: ~17 (5 frontend-blue + 5 frontend-green + 3 product + 4 order)
- Uptime esperado: 99.9%
- Tiempo de rollback: < 30 segundos
- Tiempo de Blue-Green switch: < 1 segundo

## Seguridad

- runAsNonRoot: true (user 101)
- readOnlyRootFilesystem: true
- Capabilities dropped: ALL
- Secrets usados para datos sensibles (api-key, analytics-token)
EOF

cat proyecto-ecommerce-report.md
```

---

## Limpieza

```bash
# Ejecutar script de limpieza automatica
./cleanup.sh
```

El script elimina el namespace `ecommerce-prod` completo (todos los recursos),
termina procesos port-forward activos y restaura el contexto al namespace `default`.

---

## Checklist de Evaluacion

### Requisitos Funcionales
- [ ] Frontend Deployment con 5 replicas en estado Running
- [ ] Backend services (product-service + order-service) desplegados
- [ ] ConfigMap `frontend-config` aplicado con nginx.conf y app-config.json
- [ ] Secret `frontend-secrets` creado con las claves correctas
- [ ] Services expuestos con puertos nombrados

### Alta Disponibilidad
- [ ] Los 3 PodDisruptionBudgets configurados y mostrando ALLOWED DISRUPTIONS
- [ ] HPA en estado activo con metricas visibles
- [ ] Anti-affinity configurada en frontend-web
- [ ] Multiples replicas por cada servicio

### Deployments
- [ ] Rolling updates sin downtime (diferencia entre product y order service)
- [ ] Rollback ejecutado exitosamente con historial de revisiones
- [ ] Blue-Green: ambas versiones desplegadas simultaneamente
- [ ] Switch de Service hacia Green completado
- [ ] Change-cause annotations en todos los Deployments

### Health y Monitoring
- [ ] readinessProbe configurada en todos los contenedores
- [ ] livenessProbe configurada en todos los contenedores
- [ ] startupProbe configurada en frontend-web
- [ ] Resource requests y limits definidos en todos los contenedores

### Seguridad
- [ ] securityContext con runAsNonRoot:true en frontend-web
- [ ] readOnlyRootFilesystem:true con volumenes emptyDir para escritura
- [ ] capabilities drop ALL
- [ ] Secrets usados para datos sensibles (no variables de entorno literales)

---

## Criterios de Evaluacion

| Criterio | Peso | Puntos |
|----------|------|--------|
| Deployments funcionando (todas las replicas Ready) | 20% | /20 |
| Alta disponibilidad (HPA activo, PDBs configurados) | 20% | /20 |
| Rolling updates y rollback demostrados | 20% | /20 |
| Blue-Green con switch de Service completado | 15% | /15 |
| Health checks configurados en todos los componentes | 10% | /10 |
| Security best practices aplicadas | 10% | /10 |
| Documentacion (reporte generado) | 5% | /5 |
| **TOTAL** | **100%** | **/100** |

---

## Felicitaciones

Has completado el proyecto integrador del modulo de Deployments y Rollouts. Este proyecto demuestra:

- Dominio completo de Deployments production-ready
- Estrategias avanzadas de despliegue (Rolling, Blue-Green)
- Alta disponibilidad con HPA y PDB
- Rollback y recuperacion ante fallos
- Best practices de seguridad (securityContext, Secrets, probes)
- Configuracion lista para entornos de produccion

**Estas listo para gestionar deployments en produccion y para los examenes CKAD/CKA.**
