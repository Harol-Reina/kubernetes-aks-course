# Laboratorio 06: Best Practices en Production

**Duracion estimada**: 50 minutos
**Dificultad**: Avanzado
**Objetivo**: Implementar un Deployment production-ready aplicando todas las best practices de Kubernetes

---

## Que hace un Deployment "production-ready"

Un Deployment de desarrollo funciona. Un Deployment de produccion es resiliente, observable, seguro y eficiente con los recursos del cluster. La diferencia no es un solo ajuste sino un conjunto de areas que trabajan en conjunto.

### Las seis areas clave

**Gestion de recursos**: Cada contenedor debe declarar `requests` (garantia de scheduling) y `limits` (techo de consumo). Sin `requests`, el scheduler no puede tomar decisiones de colocacion optimas. Sin `limits`, un Pod con fuga de memoria puede agotar el nodo entero.

**Health checks**: Tres probes con propositos distintos. La `startupProbe` protege las aplicaciones lentas en el arranque. La `readinessProbe` controla cuando un Pod recibe trafico. La `livenessProbe` reinicia contenedores atascados. Usarlas mal (por ejemplo, un liveness probe muy agresivo) genera reinicios innecesarios en produccion.

**Seguridad**: `securityContext` establece que el proceso no corra como root, que no pueda escalar privilegios, y que el filesystem del contenedor sea de solo lectura. Los volumes `emptyDir` proveen los paths temporales que la aplicacion necesita escribir.

**Alta disponibilidad**: El `HorizontalPodAutoscaler` escala segun carga. El `PodDisruptionBudget` protege durante operaciones de mantenimiento del cluster. La `podAntiAffinity` distribuye los Pods entre nodos para que un fallo de nodo no elimine todas las replicas.

**Gestion de configuracion**: La configuracion debe vivir en ConfigMaps, no en la imagen. Los datos sensibles (contrasenas, tokens) deben vivir en Secrets. Esta separacion permite actualizar configuracion sin reconstruir imagenes y rotar secretos sin redesplegar.

**Networking y seguridad de red**: Un Service con puertos nombrados facilita el mantenimiento. Un Ingress centraliza el acceso externo con TLS. Una NetworkPolicy implementa el principio de minimo privilegio a nivel de red: solo se permite el trafico explicitamente declarado.

---

## Archivos YAML de este Laboratorio

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `production-deployment.yaml` | 1 | Deployment completo con anti-affinity, probes, securityContext y lifecycle |
| `webapp-configmap.yaml` | 2 | ConfigMap con configuracion nginx y variables de entorno |
| `webapp-with-config.yaml` | 2 | Deployment que consume ConfigMap y Secrets |
| `webapp-service.yaml` | 3 | Service ClusterIP con sticky sessions y puertos nombrados |
| `webapp-ingress.yaml` | 3 | Ingress con TLS y rate limiting (referencia) |
| `webapp-hpa.yaml` | 4 | HPA v2 con metricas de CPU y memoria |
| `webapp-pdb.yaml` | 5 | Dos PodDisruptionBudgets con minAvailable y maxUnavailable |
| `webapp-servicemonitor.yaml` | 6 | ServiceMonitor para Prometheus Operator |
| `webapp-networkpolicy.yaml` | 7 | NetworkPolicy con reglas de ingress y egress |

---

## Prerequisitos

```bash
# Verificar cluster activo
minikube status

# Crear namespace del laboratorio
kubectl create namespace lab-production
kubectl config set-context --current --namespace=lab-production

# Verificar namespace
kubectl get ns lab-production
```

**Output esperado**:
```
NAME             STATUS   AGE
lab-production   Active   3s
```

---

## Ejercicio 1: Deployment Production-Ready Completo

### Paso 1: Revisar el manifiesto antes de aplicar

```bash
cat production-deployment.yaml
```

El archivo incluye comentarios que explican cada seccion: anti-affinity, tolerations, securityContext, probes, lifecycle preStop y los volumenes emptyDir necesarios porque `readOnlyRootFilesystem: true` impide escribir en el filesystem del contenedor.

### Paso 2: Aplicar el Deployment

```bash
kubectl apply -f production-deployment.yaml

# Esperar a que el rollout complete
kubectl rollout status deployment/webapp-prod
```

**Output esperado**:
```
deployment.apps/webapp-prod created
Waiting for deployment "webapp-prod" rollout to finish: 0 of 5 updated replicas are available...
deployment "webapp-prod" successfully rolled out
```

### Paso 3: Verificar distribucion de pods

```bash
# Ver pods con nodo asignado
kubectl get pods -l app=webapp -o wide
```

**Output esperado** (en minikube de un solo nodo todos estaran en el mismo nodo):
```
NAME                           READY   STATUS    RESTARTS   AGE   NODE
webapp-prod-7d9f8b6c4-2jkx9   1/1     Running   0          45s   minikube
webapp-prod-7d9f8b6c4-4nwqp   1/1     Running   0          45s   minikube
webapp-prod-7d9f8b6c4-6trmz   1/1     Running   0          45s   minikube
webapp-prod-7d9f8b6c4-8vplk   1/1     Running   0          45s   minikube
webapp-prod-7d9f8b6c4-b9xft   1/1     Running   0          45s   minikube
```

En un cluster multi-nodo, la `podAntiAffinity` distribuiria los pods entre diferentes nodos.

### Paso 4: Verificar health checks en detalle

```bash
# Obtener nombre de un pod
POD_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')

# Ver configuracion de probes
kubectl describe pod $POD_NAME | grep -A 10 "Liveness\|Readiness\|Startup"
```

**Output esperado**:
```
    Liveness:       http-get http://:http/ delay=30s timeout=5s period=15s #success=1 #failure=3
    Readiness:      http-get http://:http/ delay=10s timeout=5s period=10s #success=1 #failure=3
    Startup:        http-get http://:http/ delay=0s timeout=3s period=5s #success=1 #failure=30
```

### Paso 5: Verificar resource limits

```bash
# Ver recursos asignados a los pods
kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{.spec.containers[*].resources}{"\n\n"}{end}'
```

---

## Ejercicio 2: ConfigMap y Secrets

### Paso 1: Revisar y aplicar el ConfigMap

```bash
cat webapp-configmap.yaml

kubectl apply -f webapp-configmap.yaml

# Verificar contenido
kubectl describe configmap webapp-config
```

**Output esperado**:
```
Name:         webapp-config
Namespace:    lab-production
Data
====
LOG_FORMAT:       7 bytes
MAX_CONNECTIONS:  4 bytes
TIMEOUT:          3 bytes
app.conf:         ...
```

### Paso 2: Crear Secret para datos sensibles

Los Secrets se crean con `kubectl create secret` para evitar que los valores en texto plano queden en el historial de Git:

```bash
kubectl create secret generic webapp-secrets \
  --from-literal=database-password='P@ssw0rd123' \
  --from-literal=api-key='secret-api-key-12345' \
  --from-literal=jwt-secret='jwt-secret-token'

# Verificar (valores en base64, no en texto plano)
kubectl get secret webapp-secrets -o yaml

# Decodificar un valor especifico
kubectl get secret webapp-secrets -o jsonpath='{.data.database-password}' | base64 -d
echo
```

**Output esperado de la decodificacion**:
```
P@ssw0rd123
```

### Paso 3: Aplicar Deployment con ConfigMap y Secrets

```bash
cat webapp-with-config.yaml

kubectl apply -f webapp-with-config.yaml

# Verificar pods
kubectl get pods -l app=webapp-config
```

**Output esperado**:
```
NAME                                  READY   STATUS    RESTARTS   AGE
webapp-with-config-6d8b9f7c5-4kxpl   1/1     Running   0          20s
webapp-with-config-6d8b9f7c5-7npqr   1/1     Running   0          20s
webapp-with-config-6d8b9f7c5-9wtmv   1/1     Running   0          20s
```

### Paso 4: Verificar que la configuracion llego al pod

```bash
POD_NAME=$(kubectl get pods -l app=webapp-config -o jsonpath='{.items[0].metadata.name}')

# Verificar variables de entorno desde ConfigMap y Secret
kubectl exec $POD_NAME -- env | grep -E 'LOG_FORMAT|MAX_CONNECTIONS|DATABASE_PASSWORD'

# Verificar archivo de configuracion montado desde ConfigMap
kubectl exec $POD_NAME -- cat /etc/nginx/conf.d/default.conf
```

**Output esperado**:
```
LOG_FORMAT=json
MAX_CONNECTIONS=1000
DATABASE_PASSWORD=P@ssw0rd123
```

---

## Ejercicio 3: Service e Ingress

### Paso 1: Aplicar el Service

```bash
cat webapp-service.yaml

kubectl apply -f webapp-service.yaml

# Verificar Service y Endpoints
kubectl get svc webapp-service
kubectl get endpoints webapp-service
```

**Output esperado**:
```
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
webapp-service   ClusterIP   10.96.142.87    <none>        80/TCP,8080/TCP   10s
```

Los Endpoints listaran las IPs de los pods con label `app=webapp, tier=frontend`:
```
NAME             ENDPOINTS                                                  AGE
webapp-service   10.244.0.10:80,10.244.0.11:80,... + 5 more...            10s
```

### Paso 2: Revisar el Ingress (referencia)

El archivo `webapp-ingress.yaml` requiere un Ingress Controller y cert-manager instalados. En minikube:

```bash
# Habilitar Ingress Controller (si no esta habilitado)
minikube addons enable ingress

# Verificar Ingress Controller
kubectl get pods -n ingress-nginx

# El Ingress es opcional en este laboratorio — revisar como referencia:
cat webapp-ingress.yaml
```

---

## Ejercicio 4: HorizontalPodAutoscaler

### Paso 1: Habilitar metrics-server

```bash
# En minikube
minikube addons enable metrics-server

# Esperar a que este disponible (puede tardar hasta 60 segundos)
kubectl get apiservice v1beta1.metrics.k8s.io

# Verificar metricas
kubectl top nodes
kubectl top pods -n lab-production
```

### Paso 2: Aplicar el HPA

```bash
cat webapp-hpa.yaml

kubectl apply -f webapp-hpa.yaml

# Verificar estado del HPA
kubectl get hpa webapp-hpa
kubectl describe hpa webapp-hpa
```

**Output esperado** (puede mostrar `<unknown>` hasta que metrics-server tenga datos):
```
NAME         REFERENCE               TARGETS          MINPODS   MAXPODS   REPLICAS   AGE
webapp-hpa   Deployment/webapp-prod   5%/70%, 8%/80%   3         10        5          30s
```

### Paso 3: Generar carga para ver el HPA en accion

```bash
# Crear pod que genera carga continua (en background)
kubectl run load-generator \
  --image=busybox \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://webapp-service.lab-production.svc.cluster.local; done"

# Monitorear el HPA en tiempo real (en otra terminal)
watch kubectl get hpa webapp-hpa

# Ver pods escalando
watch kubectl get pods -l app=webapp
```

Cuando la carga supere el 70% de CPU, el HPA escalara las replicas. Para detener la prueba:

```bash
kubectl delete pod load-generator
```

---

## Ejercicio 5: PodDisruptionBudget

### Paso 1: Aplicar los PDBs

```bash
cat webapp-pdb.yaml

kubectl apply -f webapp-pdb.yaml

# Verificar PDBs
kubectl get pdb -n lab-production
```

**Output esperado**:
```
NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
webapp-pdb              2               N/A               3                     10s
webapp-pdb-percentage   N/A             25%               N/A                   10s
```

La columna `ALLOWED DISRUPTIONS` muestra cuantos pods se pueden interrumpir en este momento sin violar el PDB. Con 5 replicas y `minAvailable: 2`, se permiten 3 disrupciones.

### Paso 2: Entender el impacto del PDB

```bash
# Ver en que nodos estan los pods
kubectl get pods -l app=webapp -o wide

# En cluster multi-nodo, al hacer drain de un nodo:
# kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
# El PDB impide que el drain elimine mas pods de los permitidos simultaneamente
```

---

## Ejercicio 6: Monitoring y Observability

### Paso 1: Verificar labels en todos los recursos

```bash
# Ver todos los recursos con sus labels
kubectl get all -n lab-production --show-labels
```

Los labels consistentes (`app`, `tier`, `environment`) son fundamentales para:
- Seleccion de pods por Services y HPA
- Filtrado en herramientas de observabilidad (Grafana, Lens)
- Agrupacion de metricas en Prometheus

### Paso 2: Revisar el ServiceMonitor (referencia)

```bash
# Ver el manifiesto del ServiceMonitor
cat webapp-servicemonitor.yaml
```

El ServiceMonitor requiere el Prometheus Operator instalado. Es un recurso de tipo CRD (Custom Resource Definition) que le indica a Prometheus donde hacer scraping de metricas:

```bash
# Si tienes Prometheus Operator instalado:
# kubectl apply -f webapp-servicemonitor.yaml
# kubectl get servicemonitor -n lab-production
```

---

## Ejercicio 7: NetworkPolicy para Seguridad

### Paso 1: Revisar y aplicar la NetworkPolicy

```bash
cat webapp-networkpolicy.yaml

kubectl apply -f webapp-networkpolicy.yaml

# Verificar
kubectl get networkpolicy -n lab-production
kubectl describe networkpolicy webapp-network-policy
```

**Output esperado**:
```
Name:         webapp-network-policy
Namespace:    lab-production
Pod Selector: app=webapp
Policy Types: Ingress, Egress
Ingress:
  From:
    NamespaceSelector: name=ingress-nginx   Port: 80/TCP
    NamespaceSelector: name=monitoring      Port: 8080/TCP
Egress:
  To:
    NamespaceSelector + PodSelector: k8s-app=kube-dns   Port: 53/UDP
    PodSelector: tier=backend               Port: 8080/TCP
```

Nota: En minikube con el CNI por defecto (kindnet), las NetworkPolicies se crean pero no se aplican. Se necesita un CNI compatible como Calico o Cilium para que sean efectivas.

---

## Limpieza

```bash
# Ejecutar script de limpieza
./cleanup.sh
```

O manualmente:

```bash
# Eliminar todos los recursos
kubectl delete namespace lab-production

# Restaurar namespace por defecto
kubectl config set-context --current --namespace=default
```

---

## Checklist Production-Ready

Usa esta lista para verificar que tu Deployment cumple las best practices:

**Deployment**
- [ ] Labels y annotations completas (`app`, `tier`, `environment`, `version`)
- [ ] `revisionHistoryLimit` configurado (recomendado: 10)
- [ ] `requests` y `limits` declarados en todos los contenedores
- [ ] `readinessProbe`, `livenessProbe` y `startupProbe` configuradas
- [ ] `podAntiAffinity` para distribucion entre nodos
- [ ] `securityContext`: `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`
- [ ] Lifecycle `preStop` para graceful shutdown
- [ ] `terminationGracePeriodSeconds` ajustado al tiempo de shutdown de la aplicacion

**ConfigMap y Secrets**
- [ ] Configuracion externalizada en ConfigMap (no hardcodeada en la imagen)
- [ ] Datos sensibles en Secrets (nunca en ConfigMap ni en variables de entorno directas del Deployment)
- [ ] Secrets creados via CLI o herramienta externa (no en archivos YAML commiteados)

**Alta Disponibilidad**
- [ ] Minimo 3 replicas en produccion
- [ ] `PodDisruptionBudget` configurado
- [ ] `HorizontalPodAutoscaler` para escalado automatico

**Networking**
- [ ] Service con puertos nombrados
- [ ] Ingress con TLS (no HTTP plano en produccion)
- [ ] `NetworkPolicy` con principio de minimo privilegio

**Observabilidad**
- [ ] Annotations de Prometheus en el Pod template
- [ ] Endpoint `/health` o `/healthz` sin logging de acceso
- [ ] Logs estructurados (formato JSON)
- [ ] `ServiceMonitor` o anotaciones para scraping de metricas

---

## Resumen

En este laboratorio implementaste las seis areas clave de un Deployment production-ready:

- Deployment completo con anti-affinity, probes, securityContext y lifecycle hooks
- Gestion de configuracion con ConfigMap y Secrets
- Service con sticky sessions e Ingress con TLS
- HorizontalPodAutoscaler v2 con metricas de CPU y memoria
- PodDisruptionBudgets para proteccion durante mantenimiento
- Networking seguro con NetworkPolicy
- Observabilidad con labels, annotations y ServiceMonitor

**Proximo**: Lab 07 - Troubleshooting de Deployments
