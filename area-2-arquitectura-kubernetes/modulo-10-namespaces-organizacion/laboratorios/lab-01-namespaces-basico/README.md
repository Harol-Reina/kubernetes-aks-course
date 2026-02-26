# Laboratorio 01: Fundamentos de Namespaces

**Duracion estimada:** 35-40 minutos
**Nivel:** Basico
**Requisitos:** Cluster Kubernetes funcional (minikube, kind, o cloud)

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Namespace** | Aislamiento logico de recursos en Kubernetes. Permite separar entornos (dev, staging, prod), equipos o proyectos en el mismo cluster sin interferencia |
| **Creacion declarativa** | Definir namespaces en archivos YAML versionables en Git. Mas reproducible que comandos imperativos |
| **Labels y Annotations** | Labels permiten filtrar y seleccionar namespaces (`kubectl get ns -l env=prod`). Annotations almacenan metadata informativa (SLA, contacto) |
| **kubectl context** | Configuracion que define cluster + namespace por defecto. Permite cambiar entre namespaces sin usar `-n` en cada comando |
| **DNS cross-namespace** | Formato `<service>.<namespace>.svc.cluster.local`. Nombre corto solo funciona en el mismo namespace |
| **Despliegue multi-namespace** | Mismo manifiesto YAML aplicado con `-n` a diferentes namespaces. Recursos son independientes entre si |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Las operaciones principales se realizan mediante archivos YAML:

| Archivo | Parte | Descripcion |
|---------|-------|-------------|
| `namespace-production.yaml` | 1 | Namespace de produccion con labels (environment, team, critical) y annotations (SLA, descripcion) |
| `webapp.yaml` | 3 | Deployment (2 replicas nginx) + Service ClusterIP. Sin namespace: se aplica con `-n` |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Cluster de Kubernetes funcional (minikube, kind, k3s o cloud)
- kubectl configurado

### Verificacion del entorno

```bash
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
ls -la *.yaml
```

---

## Parte 1: Creacion y Gestion de Namespaces (10 min)

### Paso 1: Listar Namespaces del Sistema

```bash
kubectl get namespaces
```

**Salida esperada:**
```
NAME              STATUS   AGE
default           Active   5d
kube-node-lease   Active   5d
kube-public       Active   5d
kube-system       Active   5d
```

**Pregunta**: Cual es el proposito de cada namespace del sistema?

<details>
<summary>Respuesta</summary>

- **default**: Namespace predeterminado para objetos sin namespace especificado
- **kube-system**: Componentes del sistema de Kubernetes (API server, etcd, etc.)
- **kube-public**: Recursos publicamente accesibles
- **kube-node-lease**: Heartbeat de nodos (mecanismo de deteccion de fallos)
</details>

### Paso 2: Crear Namespaces (Imperativo)

```bash
# Crear namespace 'development'
kubectl create namespace development

# Crear con labels
kubectl create namespace staging \
  --labels=environment=staging,team=platform

# Verificar
kubectl get ns --show-labels
```

### Paso 3: Crear Namespace (Declarativo)

Revisa el archivo `namespace-production.yaml`:

```bash
cat namespace-production.yaml
```

Puntos clave del manifiesto:
- **Labels**: `environment: prod`, `team: platform`, `critical: "true"`
- **Annotations**: metadata informativa (SLA, descripcion)
- **Declarativo**: reproducible y versionable en Git

```bash
kubectl apply -f namespace-production.yaml

# Verificar
kubectl describe namespace production
```

**Checkpoint**: Deberias tener 3 namespaces nuevos (development, staging, production).

---

## Parte 2: Gestion de Contextos kubectl (10 min)

### Paso 4: Ver Contexto Actual

```bash
# Ver contexto activo
kubectl config current-context

# Ver namespace por defecto del contexto actual
kubectl config view --minify | grep namespace:
```

### Paso 5: Cambiar Namespace del Contexto

```bash
# Establecer namespace 'development' como default
kubectl config set-context --current --namespace=development

# Verificar
kubectl config view --minify | grep namespace:

# Ahora 'kubectl get pods' listara pods de 'development'
kubectl get pods
```

### Paso 6: Crear Contextos Personalizados

```bash
# Crear contexto para staging
kubectl config set-context staging-context \
  --cluster=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}') \
  --namespace=staging

# Crear contexto para production
kubectl config set-context prod-context \
  --cluster=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}') \
  --namespace=production

# Listar contextos
kubectl config get-contexts

# Cambiar entre contextos
kubectl config use-context staging-context
kubectl config use-context prod-context
```

**Tip**: Instala `kubens` para cambiar de namespace rapidamente: `kubens development`

**Checkpoint**: Debes poder cambiar entre contextos y ver el namespace correcto.

---

## Parte 3: Despliegue Multi-Namespace (10 min)

### Paso 7: Revisar y desplegar webapp en multiples namespaces

Revisa el archivo `webapp.yaml`:

```bash
cat webapp.yaml
```

Puntos clave del manifiesto:
- **Sin namespace en metadata**: se aplica al namespace del flag `-n`
- **Deployment con 2 replicas** + Service ClusterIP
- **Resource requests/limits** definidos (buena practica)

```bash
# Desplegar en development
kubectl apply -f webapp.yaml -n development

# Desplegar en staging (luego escalar)
kubectl apply -f webapp.yaml -n staging
kubectl scale deployment webapp --replicas=3 -n staging

# Desplegar en production (5 replicas)
kubectl apply -f webapp.yaml -n production
kubectl scale deployment webapp --replicas=5 -n production

# Verificar despliegues
kubectl get deployments --all-namespaces -l app=webapp
```

**Salida esperada:**
```
NAMESPACE     NAME     READY   UP-TO-DATE   AVAILABLE
development   webapp   2/2     2            2
staging       webapp   3/3     3            3
production    webapp   5/5     5            5
```

**Checkpoint**: Debes ver webapp desplegada en los 3 namespaces con diferentes replicas.

---

## Parte 4: DNS Cross-Namespace (10 min)

### Paso 8: Verificar Servicios

```bash
kubectl get svc --all-namespaces -l app=webapp
```

**DNS de cada servicio:**
- Development: `webapp.development.svc.cluster.local`
- Staging: `webapp.staging.svc.cluster.local`
- Production: `webapp.production.svc.cluster.local`

### Paso 9: Testing DNS desde Mismo Namespace

```bash
# Crear Pod de prueba en development
kubectl run test-pod --image=alpine -n development \
  --restart=Never -- sleep 3600

kubectl exec -it test-pod -n development -- sh
```

Dentro del Pod:
```sh
apk add curl bind-tools

# Mismo namespace - short name funciona
nslookup webapp
curl http://webapp

exit
```

### Paso 10: Testing DNS Cross-Namespace

```bash
kubectl exec -it test-pod -n development -- sh
```

Dentro del Pod:
```sh
# Short name → webapp de 'development'
curl -s http://webapp | head -1

# Con namespace → webapp de 'production'
curl -s http://webapp.production | head -1

# FQDN completo
curl -s http://webapp.production.svc.cluster.local | head -1

exit
```

**Checkpoint**: Debes poder acceder a servicios cross-namespace usando `<service>.<namespace>`.

---

## Parte 5: Gestion de Recursos Multi-Namespace (5 min)

### Paso 11: Comandos Utiles

```bash
# Ver TODOS los pods en TODOS los namespaces
kubectl get pods --all-namespaces -l app=webapp

# Contar pods por namespace
kubectl get pods --all-namespaces -l app=webapp --no-headers | \
  awk '{print $1}' | sort | uniq -c

# Ver logs de una app en multiples namespaces
for ns in development staging production; do
  echo "=== Logs from $ns ==="
  kubectl logs -n $ns -l app=webapp --tail=3
done
```

---

## Desafios Adicionales

### Desafio 1: Comunicacion Cross-Namespace

Crea un Pod en `development` que llame a un servicio en `production`.

<details>
<summary>Solucion</summary>

```bash
kubectl create job test-cross-ns --image=curlimages/curl -n development \
  -- curl -s http://webapp.production

kubectl logs -n development jobs/test-cross-ns
```
</details>

### Desafio 2: Comparar Configuraciones

Escribe un script que compare el numero de replicas de 'webapp' en los 3 namespaces.

<details>
<summary>Solucion</summary>

```bash
for ns in development staging production; do
  replicas=$(kubectl get deployment webapp -n $ns -o jsonpath='{.spec.replicas}')
  echo "$ns: $replicas replicas"
done
```
</details>

---

## Limpieza

```bash
chmod +x cleanup.sh
./cleanup.sh
```

---

## Resumen

En este laboratorio has aprendido:

- Crear namespaces con kubectl y archivos YAML
- Configurar y cambiar contextos
- Desplegar aplicaciones en multiples namespaces con el mismo manifiesto
- Usar DNS cross-namespace
- Gestionar recursos multi-namespace

### Proximos Pasos

- **Lab 02**: ResourceQuota y LimitRange
- **Lab 03**: Multi-Tenancy y Aislamiento

---

**Anterior:** [Volver al README del modulo](../README.md)
**Siguiente:** [Lab 02: ResourceQuota y LimitRange](../lab-02-quotas-limits/)
