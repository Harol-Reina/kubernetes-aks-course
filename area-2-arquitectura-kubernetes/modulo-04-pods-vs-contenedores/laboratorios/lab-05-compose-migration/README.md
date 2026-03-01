# Lab 05: Migracion de Docker Compose a Kubernetes

**Duracion estimada:** 50 minutos | **Nivel:** Intermedio
**Objetivo:** Migrar una aplicacion multi-service de Docker Compose a Kubernetes, transformando
services en Deployments, networks en Services ClusterIP, y named volumes en PersistentVolumeClaims.

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Docker Compose service → Deployment** | Cada `service:` en docker-compose.yml se convierte en un Deployment + Service de Kubernetes |
| **Named volume → PersistentVolumeClaim** | `volumes: db-data` se reemplaza con un PVC de ReadWriteOnce para persistir datos de PostgreSQL |
| **environment vars → ConfigMap + Secret** | Variables no sensibles van a ConfigMap; passwords van a Secret de tipo Opaque |
| **app-network → ClusterIP Service** | La red bridge de Docker Compose no existe en K8s: los Services ClusterIP proveen DNS interno |
| **depends_on → Service DNS** | Kubernetes no tiene `depends_on`; el service discovery via DNS resuelve la dependencia en runtime |
| **ports: host:container → NodePort** | `ports: "8080:80"` en Compose se convierte en Service NodePort con `nodePort: 30080` |
| **nginx.conf → ConfigMap subPath** | El archivo de configuracion de nginx se inyecta como volumen usando `subPath` desde un ConfigMap |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `db-deployment.yaml` | 1 | PVC + ConfigMap + Secret + Deployment + Service para PostgreSQL |
| `api-deployment.yaml` | 2 | ConfigMap + Deployment (2 replicas) + Service para la API Node.js |
| `web-deployment.yaml` | 3 | ConfigMap (nginx.conf) + Deployment (2 replicas) + Service NodePort para Nginx |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Elimina todos los recursos Kubernetes creados en el laboratorio |

---

## Arquitectura de la Aplicacion

```
Docker Compose Stack (ANTES)             Kubernetes (DESPUES)
─────────────────────────────            ──────────────────────────────────
docker-compose.yml (1 archivo)           db-deployment.yaml
├── service: web                         ├── PersistentVolumeClaim: postgres-pvc
├── service: api                         ├── ConfigMap: postgres-config
├── service: db                          ├── Secret: postgres-secret
├── network: app-network                 ├── Deployment: db (1 replica)
└── volume: db-data                      └── Service: db (ClusterIP :5432)

                                         api-deployment.yaml
  ┌─────────┐   ┌─────────┐             ├── ConfigMap: api-config
  │   Web   │──►│   API   │──►[ DB ]    ├── Deployment: api (2 replicas)
  │  Nginx  │   │  Node.js│             └── Service: api (ClusterIP :3000)
  │ :30080  │   │  :3000  │
  └─────────┘   └─────────┘             web-deployment.yaml
                                         ├── ConfigMap: nginx-config
  NodePort 30080 ← acceso externo        ├── Deployment: web (2 replicas)
                                         └── Service: web (NodePort :30080)
```

---

## Paso 1: Preparacion del Entorno

```bash
mkdir -p ~/labs/modulo-04/compose-migration && cd ~/labs/modulo-04/compose-migration

# Copiar los archivos YAML del laboratorio
LABS_DIR=~/K8S/area-2-arquitectura-kubernetes/modulo-04-pods-vs-contenedores/laboratorios/lab-05-compose-migration
cp $LABS_DIR/db-deployment.yaml .
cp $LABS_DIR/api-deployment.yaml .
cp $LABS_DIR/web-deployment.yaml .

echo "Archivos preparados:"
ls *.yaml
```

**Salida esperada:**

```
Archivos preparados:
api-deployment.yaml  db-deployment.yaml  web-deployment.yaml
```

---

## Paso 2: Probar Aplicacion Original en Docker Compose (opcional)

Si tienes Docker Compose instalado, puedes comparar el comportamiento original:

```bash
# Copiar docker-compose.yml de los ejemplos
cp ~/K8S/area-2-arquitectura-kubernetes/modulo-04-pods-vs-contenedores/ejemplos/05-migracion-compose/docker-compose.yml .

# Levantar stack
docker-compose up -d

# Verificar servicios
docker-compose ps

# Probar conectividad
curl -s http://localhost:8080 || echo "Nginx responde"
curl -s http://localhost:3000 || echo "API responde"

# Ver logs
docker-compose logs --tail=5

# Detener stack antes de continuar con K8s
docker-compose down
```

**Caracteristicas de Docker Compose observadas:**
- Networking automatico: `app-network` conecta todos los servicios
- Service discovery: la API puede usar `db` como hostname
- Volumes: `db-data` persiste datos de PostgreSQL

---

## Paso 3: Analizar Componentes a Migrar

```bash
echo "COMPONENTES A MIGRAR:"
echo "├─ 3 Services: web, api, db"
echo "├─ 1 Network: app-network → Kubernetes ClusterIP Services"
echo "├─ 1 Volume: db-data → PersistentVolumeClaim"
echo "└─ Environment variables → ConfigMaps + Secrets"
```

---

## Paso 4: Desplegar Base de Datos (PostgreSQL)

```bash
kubectl apply -f db-deployment.yaml
```

**Salida esperada:**

```
persistentvolumeclaim/postgres-pvc created
configmap/postgres-config created
secret/postgres-secret created
deployment.apps/db created
service/db created
```

```bash
# Esperar a que el Pod este listo
kubectl wait --for=condition=Available deployment/db --timeout=90s

# Verificar recursos creados
kubectl get pvc postgres-pvc
kubectl get configmap postgres-config
kubectl get secret postgres-secret
kubectl get deployment db
kubectl get service db
```

**Salida esperada:**

```
NAME           STATUS   VOLUME                                     CAPACITY   STORAGECLASS
postgres-pvc   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   1Gi        standard

NAME              DATA   AGE
postgres-config   2      10s

NAME              TYPE     DATA   AGE
postgres-secret   Opaque   1      10s

NAME   READY   UP-TO-DATE   AVAILABLE
db     1/1     1            1

NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
db     ClusterIP   10.96.xxx.xxx   <none>        5432/TCP
```

**Cambios Docker Compose → Kubernetes:**
- `volumes: db-data` → `PersistentVolumeClaim` (ReadWriteOnce, 1Gi)
- `environment: POSTGRES_DB, POSTGRES_USER` → `ConfigMap` (datos no sensibles)
- `environment: POSTGRES_PASSWORD` → `Secret` tipo Opaque
- `image: postgres:alpine` con un `service: db` → `Deployment` + `Service`

---

## Paso 5: Desplegar API Backend (Node.js)

```bash
kubectl apply -f api-deployment.yaml
```

**Salida esperada:**

```
configmap/api-config created
deployment.apps/api created
service/api created
```

```bash
kubectl wait --for=condition=Available deployment/api --timeout=60s

# Verificar
kubectl get deployment api
kubectl get service api
```

**Salida esperada:**

```
NAME   READY   UP-TO-DATE   AVAILABLE
api    2/2     2            2

NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
api    ClusterIP   10.96.xxx.xxx   <none>        3000/TCP
```

**Cambios Docker Compose → Kubernetes:**
- `depends_on: db` → eliminado: el Service `db` provee DNS interno, la API se reconecta en runtime
- `networks: app-network` → Kubernetes networking automatico via kube-dns
- `replicas: 2` → escalabilidad built-in, sin configuracion adicional

---

## Paso 6: Desplegar Frontend Web (Nginx)

```bash
kubectl apply -f web-deployment.yaml
```

**Salida esperada:**

```
configmap/nginx-config created
deployment.apps/web created
service/web created
```

```bash
kubectl wait --for=condition=Available deployment/web --timeout=60s

# Verificar
kubectl get deployment web
kubectl get service web
```

**Salida esperada:**

```
NAME   READY   UP-TO-DATE   AVAILABLE
web    2/2     2            2

NAME   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
web    NodePort   10.96.xxx.xxx   <none>        80:30080/TCP   10s
```

**Cambios Docker Compose → Kubernetes:**
- `ports: "8080:80"` → `Service NodePort` con `nodePort: 30080`
- `depends_on: api` → Service discovery via DNS (nombre `api` resuelto por kube-dns)
- nginx.conf personalizado → `ConfigMap` montado con `subPath`

---

## Paso 7: Verificar Migracion Completa

```bash
echo "VERIFICACION DE MIGRACION"
echo "========================="

kubectl get all
echo ""
kubectl get pvc
echo ""
kubectl get configmap | grep -v kube-root
echo ""
kubectl get secret | grep -v service-account
```

**Salida esperada:**

```
NAME                       READY   STATUS    RESTARTS   AGE
pod/api-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
pod/api-xxxxxxxxxx-yyyyy   1/1     Running   0          2m
pod/db-xxxxxxxxxx-xxxxx    1/1     Running   0          3m
pod/web-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
pod/web-xxxxxxxxxx-yyyyy   1/1     Running   0          1m

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/api          ClusterIP   10.96.x.x      <none>        3000/TCP       2m
service/db           ClusterIP   10.96.x.x      <none>        5432/TCP       3m
service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        1d
service/web          NodePort    10.96.x.x      <none>        80:30080/TCP   1m

NAME                  READY   UP-TO-DATE   AVAILABLE
deployment.apps/api   2/2     2            2
deployment.apps/db    1/1     1            1
deployment.apps/web   2/2     2            2

NAME                                  STATUS   VOLUME                 CAPACITY
persistentvolumeclaim/postgres-pvc    Bound    pvc-xxxx               1Gi

NAME              DATA
api-config        3
nginx-config      1
postgres-config   2

NAME              TYPE
postgres-secret   Opaque
```

---

## Paso 8: Probar Aplicacion en Kubernetes

### Acceso via Minikube (recomendado)

```bash
# Obtener la URL del servicio web
minikube service web --url
```

**Salida esperada:**

```
http://192.168.49.2:30080
```

```bash
# Probar el endpoint web
curl -s http://$(minikube ip):30080 | head -5
```

### Acceso via port-forward (alternativa sin Minikube)

```bash
kubectl port-forward service/web 8080:80 &
sleep 2

curl -s http://localhost:8080 | head -5

# Detener port-forward al terminar
kill %1 2>/dev/null
```

---

## Paso 9: Verificar Networking (DNS interno)

```bash
# Desde un Pod temporal, probar DNS interno
kubectl run test-pod --image=busybox:1.35 --restart=Never --rm -it -- sh -c "
  echo 'Resolucion DNS interna de Kubernetes:'
  nslookup db
  echo ''
  nslookup api
  echo ''
  nslookup web
"
```

**Salida esperada:**

```
Resolucion DNS interna de Kubernetes:
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      db
Address 1: 10.96.x.x db.default.svc.cluster.local

Name:      api
Address 1: 10.96.x.x api.default.svc.cluster.local

Name:      web
Address 1: 10.96.x.x web.default.svc.cluster.local
```

**Observaciones:**
- Todos los services son accesibles por nombre corto dentro del mismo namespace
- kube-dns resuelve automaticamente `db`, `api`, `web` a su ClusterIP
- No se requiere configuracion de red manual (equivalente a `app-network` de Compose)

---

## Paso 10: Comparar Recursos

```bash
echo ""
echo "COMPARACION DOCKER COMPOSE vs KUBERNETES"
echo ""

cat << 'TABLE'
+-------------------+--------------------+----------------------+
|   Componente      |  Docker Compose    |  Kubernetes          |
+-------------------+--------------------+----------------------+
|  Services         |  3 services        |  3 Deployments       |
|  Networking       |  app-network       |  ClusterIP Services  |
|  Service Discovery|  DNS interno       |  kube-dns            |
|  Volumes          |  db-data           |  PersistentVolumeClaim|
|  Scaling          |  Manual            |  replicas: 2         |
|  Load Balancing   |  No                |  Service             |
|  Health Checks    |  No                |  Readiness/Liveness  |
|  Config           |  environment vars  |  ConfigMaps/Secrets  |
+-------------------+--------------------+----------------------+
TABLE
```

---

## Mejoras Obtenidas con Kubernetes

```
KUBERNETES BENEFITS:
├── Escalabilidad: web y api con 2 replicas
├── Load Balancing: automatico via Services
├── Self-healing: Pods reinician automaticamente
├── ConfigMaps/Secrets: gestion centralizada de configuracion
├── Resource Limits: CPU y memoria controlados (ver db-deployment.yaml, api-deployment.yaml, web-deployment.yaml)
├── Multi-host: puede desplegarse en cluster de varios nodos
└── Observability: logs, metricas, health checks integrados
```

### Mejora 1: Agregar Ingress (reemplaza NodePort)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```

### Mejora 2: Agregar Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 3
```

---

## Troubleshooting

### Pod de base de datos en estado Pending

```bash
# Verificar eventos del Pod
kubectl describe pod -l app=postgres

# Causa comun: PVC no puede ser provisionado
kubectl describe pvc postgres-pvc
# Buscar: "no persistent volumes available for this claim"
# Solucion en Minikube: el StorageClass "standard" provisiona automaticamente
```

### Pod web en CrashLoopBackOff

```bash
# Ver logs del contenedor nginx
kubectl logs -l app=web

# Causa comun: error de sintaxis en nginx.conf del ConfigMap
kubectl describe configmap nginx-config

# Verificar montaje del volumen
kubectl exec -it deployment/web -- cat /etc/nginx/nginx.conf
```

### DNS no resuelve nombres de Services

```bash
# Verificar que kube-dns esta funcionando
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Probar desde un Pod
kubectl run dns-test --image=busybox:1.35 --restart=Never --rm -it -- nslookup db
```

---

## Limpieza

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete deployment web api db
kubectl delete service web api db
kubectl delete configmap nginx-config api-config postgres-config
kubectl delete secret postgres-secret
kubectl delete pvc postgres-pvc

kubectl get all
kubectl get pvc
kubectl get configmap | grep -v kube-root
```

---

## Conceptos Clave Aprendidos

1. **Docker Compose service → Deployment + Service**: cada service de Compose se convierte en dos objetos K8s
2. **Networking**: Docker bridge → Kubernetes Services + kube-dns (mismo concepto, diferente implementacion)
3. **Volumes**: Named volumes → PersistentVolumeClaims con StorageClass
4. **Configuration**: Environment variables → ConfigMaps (no sensibles) + Secrets (sensibles)
5. **Scaling**: Docker no escala automaticamente → Kubernetes `replicas` + HPA
6. **Service Discovery**: ambos usan DNS interno, pero K8s es multi-host y mas robusto

---

## Referencias

- [Kubernetes vs Docker Compose](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/)
- [Migrating from Docker Compose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)
- [Kompose - Herramienta de Conversion Automatica](https://kompose.io/)

---

## Siguiente Paso

Has completado todos los laboratorios del modulo. Ahora puedes:
- **[Volver al README Principal](../README.md)** para revisar los conceptos del modulo
- **[Lab Resumen: Pods](../lab-resumen-pods/README.md)** para repasar todos los conceptos en 15 minutos
- **[Modulo 05: Gestion Avanzada de Pods](../../modulo-05-gestion-pods/README.md)** para profundizar
