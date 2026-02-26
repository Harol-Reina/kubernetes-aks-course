# Laboratorio 03: Services Avanzados - ExternalName, Headless y Produccion

**Duracion estimada:** 60 minutos
**Nivel:** Avanzado
**Objetivo:** Dominar ExternalName, Headless Services, Endpoints manuales y best practices de produccion

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **ExternalName Service** | Crea un alias DNS (CNAME) hacia un servicio externo. No tiene ClusterIP ni Endpoints. Util para abstraer servicios externos y facilitar migraciones |
| **Migracion gradual** | Patron que cambia un Service de ExternalName a ClusterIP manteniendo el mismo nombre. Las apps no necesitan cambios — zero downtime |
| **Headless Service** | Service con `clusterIP: None`. DNS retorna directamente las IPs de los Pods individuales. Requerido por StatefulSets para DNS estable por Pod |
| **StatefulSet + Headless** | Combinacion que da a cada Pod un DNS unico y predecible: `<pod>.<service>`. Ideal para bases de datos con master-slave replication |
| **Endpoints manuales** | Service sin selector + objeto Endpoints creado manualmente. Permite integrar servicios externos (databases, APIs legacy) con DNS de Kubernetes |
| **PodDisruptionBudget** | Garantiza disponibilidad minima durante disrupciones voluntarias (drain, upgrades). Kubernetes bloquea operaciones que violarian el PDB |
| **HorizontalPodAutoscaler** | Escala automaticamente el numero de replicas basado en metricas (CPU, memoria). Requiere metrics-server |
| **Security Context** | Restricciones de seguridad: non-root, read-only filesystem, drop ALL capabilities. Best practice para produccion |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `external-api-service.yaml` | 1 | ExternalName Service apuntando a api.github.com |
| `database-service-phase1.yaml` | 2 | ExternalName apuntando a RDS (fase migracion) |
| `database-service-phase2.yaml` | 2 | ClusterIP interno reemplazando ExternalName |
| `app-using-db.yaml` | 2 | App que consume el Service "database" |
| `mysql-headless-service.yaml` | 3 | Headless Service para MySQL (clusterIP: None) |
| `mysql-statefulset.yaml` | 3 | StatefulSet de MySQL 3 replicas con PVC |
| `external-database-service.yaml` | 4 | Service SIN selector para endpoints manuales |
| `external-database-endpoints.yaml` | 4 | Endpoints manuales apuntando a IPs externas |
| `app-using-external-db.yaml` | 4 | App que usa el Service con endpoints manuales |
| `production-service.yaml` | 5 | Service production-ready con annotations y multi-port |
| `production-deployment.yaml` | 5 | Deployment production-ready con security y probes |
| `webapp-pdb.yaml` | 6 | PodDisruptionBudget (minAvailable: 3) |
| `webapp-hpa.yaml` | 6 | HorizontalPodAutoscaler (CPU 70%, memoria 80%) |

---

## 🔧 Requisitos Previos

- Laboratorios 01 y 02 completados
- Conocimientos de StatefulSets (modulo anterior)
- Cluster con soporte para PersistentVolumes (para StatefulSet)

### Verificacion del entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar PersistentVolume provisioner (para StatefulSet)
kubectl get storageclass

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Parte 1: ExternalName Service

### Paso 1: Crear ExternalName Service

Revisa el archivo `external-api-service.yaml`:

```bash
cat external-api-service.yaml
```

Puntos clave:
- **type: ExternalName**: solo resolucion DNS, no proxy
- **externalName: api.github.com**: destino del CNAME
- **Sin selector**: no hay Pods asociados
- **Sin ClusterIP**: no se asigna IP virtual

```bash
kubectl apply -f external-api-service.yaml

# Verificar Service (NO tiene ClusterIP)
kubectl get service external-api

# Describir
kubectl describe service external-api
```

**Salida esperada:**
```
NAME           TYPE           CLUSTER-IP   EXTERNAL-IP      PORT(S)   AGE
external-api   ExternalName   <none>       api.github.com   <none>    10s
```

**Observa:**
- `CLUSTER-IP`: `<none>` (no se crea ClusterIP)
- `EXTERNAL-IP`: `api.github.com` (CNAME destino)

---

### Paso 2: Probar DNS Resolution

```bash
# Desde un Pod de debug
kubectl run test-external --rm -it --image=busybox --restart=Never -- sh
```

```sh
# DNS lookup del Service
nslookup external-api

# Deberia resolver a CNAME: api.github.com

# Test conexion HTTPS
wget --no-check-certificate -O- https://external-api 2>&1 | head -n 5

exit
```

**Observa:** DNS resuelve a `api.github.com`, no a IP directa.

---

### Paso 3: Caso de uso - Migracion Gradual

Simular migracion de servicio externo a interno.

**FASE 1: Servicio externo (ExternalName)**

Revisa `database-service-phase1.yaml` y `app-using-db.yaml`:

```bash
cat database-service-phase1.yaml
cat app-using-db.yaml
```

```bash
# Aplicar Fase 1
kubectl apply -f database-service-phase1.yaml
kubectl apply -f app-using-db.yaml

# Ver logs (resuelve a RDS)
kubectl logs -l app=backend --tail=5
```

**FASE 2: Migrar a ClusterIP interno**

Revisa `database-service-phase2.yaml`:

```bash
cat database-service-phase2.yaml
```

Punto clave: **MISMO nombre** "database" pero ahora type: ClusterIP con selector.

```bash
# Aplicar Fase 2 (reemplaza Fase 1)
kubectl apply -f database-service-phase2.yaml

# Ver logs de backend-app (ahora resuelve a ClusterIP)
kubectl logs -l app=backend --tail=5
```

**Ventaja:** Backend app NO cambia, solo el Service.

---

## Parte 2: Headless Service con StatefulSet

### Paso 4: Crear MySQL Cluster con Headless Service

Revisa el archivo `mysql-headless-service.yaml`:

```bash
cat mysql-headless-service.yaml
```

Puntos clave:
- **clusterIP: None**: Headless Service
- **publishNotReadyAddresses: true**: incluye Pods not-ready en DNS

```bash
kubectl apply -f mysql-headless-service.yaml

# Verificar (ClusterIP = None)
kubectl get service mysql-headless
```

---

### Paso 5: Crear StatefulSet de MySQL

Primero crear el Secret, luego revisar y aplicar el StatefulSet:

```bash
# Crear Secret para MySQL
kubectl create secret generic mysql-secret \
  --from-literal=root-password='MySecurePass123!'

# Revisar el StatefulSet
cat mysql-statefulset.yaml
```

Puntos clave:
- **serviceName: mysql-headless**: vincula con el Headless Service
- **replicas: 3**: mysql-0, mysql-1, mysql-2 (creados en orden)
- **volumeClaimTemplates**: cada Pod obtiene su propio PVC
- **Liveness/readiness probes**: health checks de MySQL

```bash
kubectl apply -f mysql-statefulset.yaml

# Ver Pods creandose en orden
kubectl get pods -l app=mysql -w
# Ctrl+C despues de ver los 3 Pods
```

**Observa:** Pods se crean en orden: mysql-0, luego mysql-1, luego mysql-2.

---

### Paso 6: Probar DNS de Headless Service

```bash
# Verificar Endpoints del Headless Service
kubectl get endpoints mysql-headless

# DNS test
kubectl run dns-test --rm -it --image=busybox --restart=Never -- sh
```

```sh
# DNS del Service (retorna TODAS las IPs de Pods)
nslookup mysql-headless

# Output esperado:
# Name:      mysql-headless
# Address 1: 10.1.2.10 mysql-0.mysql-headless.default.svc.cluster.local
# Address 2: 10.1.2.11 mysql-1.mysql-headless.default.svc.cluster.local
# Address 3: 10.1.2.12 mysql-2.mysql-headless.default.svc.cluster.local

# DNS de Pod INDIVIDUAL (mysql-0)
nslookup mysql-0.mysql-headless

# Output:
# Name:      mysql-0.mysql-headless
# Address 1: 10.1.2.10 mysql-0.mysql-headless.default.svc.cluster.local

# Conectar a Pod especifico
telnet mysql-0.mysql-headless 3306

exit
```

**Clave:**
- Headless Service retorna IPs de Pods directamente (NO ClusterIP)
- Cada Pod tiene DNS unico: `<pod-name>.<service-name>`

---

### Paso 7: Caso de uso - Master-Slave Replication

```bash
# Conectar a mysql-0 (master)
kubectl exec -it mysql-0 -- mysql -u root -p'MySecurePass123!' -e "
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;
CREATE TABLE IF NOT EXISTS users (id INT, name VARCHAR(50));
INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob');
SELECT * FROM users;
"

# Conectar a mysql-1 (slave, en configuracion real)
kubectl exec -it mysql-1 -- mysql -u root -p'MySecurePass123!' -e "
SHOW DATABASES;
"
```

Desde una app, conectar a master especifico:
- Master: `mysql://mysql-0.mysql-headless:3306/testdb`
- Lecturas: `mysql://mysql-1.mysql-headless:3306/testdb` o `mysql-2.mysql-headless`

---

## Parte 3: Endpoints Manuales

### Paso 8: Service con Endpoints Manuales

Revisa el archivo `external-database-service.yaml`:

```bash
cat external-database-service.yaml
```

Punto clave: **Sin selector** — Kubernetes NO crea Endpoints automaticamente.

```bash
kubectl apply -f external-database-service.yaml

# Verificar Endpoints (vacio)
kubectl get endpoints external-database
# NAME                 ENDPOINTS   AGE
# external-database    <none>      5s
```

---

### Paso 9: Crear Endpoints Manuales

Revisa el archivo `external-database-endpoints.yaml`:

```bash
cat external-database-endpoints.yaml
```

Puntos clave:
- **Nombre IDENTICO al Service**: `external-database`
- **addresses[].ip**: IPs de servidores externos
- **ports[].name**: debe coincidir con el nombre del puerto en el Service

```bash
kubectl apply -f external-database-endpoints.yaml

# Ver Endpoints (ahora poblados)
kubectl get endpoints external-database

# Describir
kubectl describe endpoints external-database
```

**Salida esperada:**
```
NAME                 ENDPOINTS                                   AGE
external-database    192.168.100.10:5432,192.168.100.11:5432     10s
```

---

### Paso 10: Usar desde Pods

Revisa el archivo `app-using-external-db.yaml`:

```bash
cat app-using-external-db.yaml
```

```bash
kubectl apply -f app-using-external-db.yaml

# Ver logs (intentos de conexion)
kubectl logs -l app=myapp --tail=10
```

**Ventaja:** App usa nombre de Service, no IPs hardcoded.

---

## Parte 4: Production-Ready Service

### Paso 11: Service con todas las Best Practices

```bash
# Crear namespace de produccion
kubectl create namespace production
```

Revisa los archivos `production-service.yaml` y `production-deployment.yaml`:

```bash
cat production-service.yaml
cat production-deployment.yaml
```

Puntos clave del Service:
- **Labels completas**: app, tier, environment, version
- **Annotations Prometheus**: auto-discovery de metricas
- **Multi-port**: http (80), https (443), metrics (9090)
- **sessionAffinity: ClientIP**: sticky sessions

Puntos clave del Deployment:
- **Pod anti-affinity**: distribuir en diferentes nodos
- **Security context**: non-root, read-only filesystem
- **Liveness + readiness probes**: health checks
- **Resource requests/limits**: control de recursos

```bash
kubectl apply -f production-service.yaml
kubectl apply -f production-deployment.yaml

# Ver distribucion en nodos
kubectl get pods -n production -o wide
```

---

### Paso 12: PodDisruptionBudget

Revisa el archivo `webapp-pdb.yaml`:

```bash
cat webapp-pdb.yaml
```

```bash
kubectl apply -f webapp-pdb.yaml

# Verificar PDB
kubectl get pdb -n production
kubectl describe pdb webapp-pdb -n production
```

---

### Paso 13: HorizontalPodAutoscaler

Revisa el archivo `webapp-hpa.yaml`:

```bash
cat webapp-hpa.yaml
```

```bash
kubectl apply -f webapp-hpa.yaml

# Ver HPA
kubectl get hpa -n production
kubectl describe hpa webapp-hpa -n production
```

---

## Desafios Finales

### Desafio 1: Migracion Completa

Migra un servicio de ExternalName a ClusterIP con Pods internos, asegurando zero downtime.

### Desafio 2: Multi-Region Database

Configura Endpoints manuales apuntando a bases de datos en multiples regiones (simula con diferentes IPs).

### Desafio 3: Production Checklist

Revisa el Service de produccion y asegurate que cumple TODAS las best practices del modulo.

---

## Limpieza

```bash
# Usar el script de limpieza
chmod +x cleanup.sh
./cleanup.sh
```

---

## Resumen Final del Modulo

### ExternalName

**Uso:**
- Integracion con servicios externos
- Migracion gradual (externo → interno)
- Abstraccion de endpoints

**Limitaciones:**
- Solo DNS CNAME (no IPs)
- Sin health checks
- Sin load balancing

---

### Headless Services

**Uso:**
- StatefulSets (MySQL, MongoDB, Cassandra)
- DNS por Pod individual
- Master-slave replication

**Caracteristicas:**
- `clusterIP: None`
- DNS retorna IPs de Pods
- Cliente responsable de balanceo

---

### Endpoints Manuales

**Uso:**
- Integrar servicios externos (databases, APIs)
- Legacy systems
- Multi-datacenter

**Responsabilidad:**
- Debes mantener IPs actualizadas
- Sin health checks automaticos
- Sin auto-scaling

---

### Production Best Practices

**Checklist completo:**
- [ ] Type apropiado (LoadBalancer en cloud)
- [ ] externalTrafficPolicy: Local (si necesitas IP)
- [ ] sessionAffinity configurado si aplica
- [ ] Labels y annotations completas
- [ ] Monitoring integrado (Prometheus)
- [ ] Multiples replicas (HA)
- [ ] PodDisruptionBudget
- [ ] HorizontalPodAutoscaler
- [ ] Resource requests/limits
- [ ] Health checks (liveness + readiness)
- [ ] Security context
- [ ] NetworkPolicy (si aplica)

---

## Has Completado el Modulo 08!

### Dominaste:

**Services:**
- ClusterIP (interno)
- NodePort (desarrollo)
- LoadBalancer (produccion cloud)
- ExternalName (integracion)
- Headless (stateful apps)

**Endpoints:**
- Automaticos (con selector)
- Manuales (sin selector)
- Troubleshooting

**DNS Discovery:**
- Nombres de Services
- Cross-namespace
- FQDN completo

**Conceptos Avanzados:**
- externalTrafficPolicy
- sessionAffinity
- kube-proxy modes
- Best practices de produccion

---

## Siguientes Pasos

- **[README del Modulo](../../README.md)** - Teoria completa
- **[Ejemplos](../../ejemplos/README.md)** - 13 ejemplos YAML
- **[Laboratorio 01](../lab-01-clusterip-basics/)** - ClusterIP basico
- **[Laboratorio 02](../lab-02-nodeport-loadbalancer/)** - NodePort y LoadBalancer

**Documentacion oficial:**
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

---

**Felicidades por completar el modulo!**
Ahora estas listo para implementar Services en produccion con confianza.
