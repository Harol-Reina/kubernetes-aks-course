# Lab 3.7: Cluster Multi-Nodo con Minikube

**Duracion**: 30-40 minutos | **Nivel**: Intermedio

**Objetivo**: Crear un cluster Minikube con multiples nodos para simular un entorno realista de Kubernetes, configurar el control plane para que no ejecute pods de usuario, y aprender a identificar en que nodo se ejecuta cada pod.

---

## Objetivos

- Comprender la diferencia entre clusters de un solo nodo y multi-nodo
- Crear un cluster con 4 nodos usando perfiles de Minikube
- Aplicar taints al control plane para que solo ejecute componentes del sistema
- Verificar la distribucion de pods entre los nodos workers
- Usar comandos para identificar donde se ejecuta cada pod

---

## Prerequisitos

- Minikube instalado y funcionando (Lab 3.4)
- kubectl instalado y configurado (Lab 3.3)
- Docker funcionando como driver
- **Recursos minimos**: 8 CPUs y 16 GB de RAM disponibles (4 nodos x 2 CPUs x 4 GB)

### Verificacion de recursos

```bash
# Verificar CPUs disponibles (necesitas al menos 8)
nproc

# Verificar RAM disponible (necesitas al menos 16 GB)
free -h | grep Mem

# Verificar espacio en disco (necesitas al menos 40 GB libres)
df -h /
```

---

## Contexto: Perfiles en Minikube

Minikube permite crear **multiples clusters** usando perfiles (`-p` o `--profile`). Cada perfil es un cluster independiente con su propia configuracion.

En este curso usamos dos perfiles:

| Perfil | Nodos | Proposito |
|--------|-------|-----------|
| `k8s-curso` | 1 | Cluster simple para labs basicos (modulos 4-21) |
| `k8s-lab` | 4 | Cluster multi-nodo para labs de scheduling, taints, afinidad |

---

## Paso 1: Verificar el cluster existente (k8s-curso)

Si ya creaste el cluster de un solo nodo en la sesion anterior, verifica que este funcionando:

```bash
# Ver perfiles existentes
minikube profile list

# Verificar estado del cluster k8s-curso
minikube status -p k8s-curso
```

**Salida esperada:**
```
|-----------|-----------|---------|--------------|------|---------|---------|-------|--------|
|  Profile  | VM Driver | Runtime |      IP      | Port | Status  | Nodes   | Active |
|-----------|-----------|---------|--------------|------|---------|---------|-------|--------|
| k8s-curso | docker    | docker  | 192.168.49.2 | 8443 | Running |       1 | *      |
|-----------|-----------|---------|--------------|------|---------|---------|-------|--------|
```

> **Nota**: Si el cluster `k8s-curso` no existe, crealo con:
> ```bash
> minikube start -p k8s-curso
> ```

---

## Paso 2: Crear cluster multi-nodo (k8s-lab)

Ahora crearemos un cluster con **4 nodos**: 1 control plane + 3 workers.

```bash
# Crear cluster multi-nodo con perfil k8s-lab
minikube start -p k8s-lab --nodes=4 --cpus=2 --memory=4096mb
```

### Explicacion de parametros

| Parametro | Valor | Descripcion |
|-----------|-------|-------------|
| `-p k8s-lab` | k8s-lab | Nombre del perfil (cluster independiente) |
| `--nodes=4` | 4 | Numero total de nodos (1 control plane + 3 workers) |
| `--cpus=2` | 2 | CPUs asignadas a cada nodo |
| `--memory=4096mb` | 4 GB | Memoria RAM asignada a cada nodo |

**Salida esperada:**
```
😄  [k8s-lab] minikube v1.32.0 on Ubuntu 22.04
✨  Using the docker driver based on user configuration
📌  Using Docker driver with root privileges
👍  Starting control plane node k8s-lab in cluster k8s-lab
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=4096MB, Disk=20000MB) ...
🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass

👍  Starting worker node k8s-lab-m02 in cluster k8s-lab
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=4096MB, Disk=20000MB) ...
🌐  Found network options:
    ▪ NO_PROXY=192.168.49.2
🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
    ▪ env NO_PROXY=192.168.49.2
🔎  Verifying Kubernetes components...

👍  Starting worker node k8s-lab-m03 in cluster k8s-lab
...

👍  Starting worker node k8s-lab-m04 in cluster k8s-lab
...

🏄  Done! kubectl is now configured to use "k8s-lab" cluster and "default" namespace by default
```

> **Tiempo estimado**: La creacion tarda entre 3-8 minutos dependiendo de tu conexion y recursos.

---

## Paso 3: Verificar los nodos del cluster

```bash
# Cambiar al contexto del cluster k8s-lab
kubectl config use-context k8s-lab

# Ver todos los nodos
kubectl get nodes
```

**Salida esperada:**
```
NAME          STATUS   ROLES           AGE     VERSION
k8s-lab       Ready    control-plane   5m      v1.28.3
k8s-lab-m02   Ready    <none>          3m      v1.28.3
k8s-lab-m03   Ready    <none>          2m      v1.28.3
k8s-lab-m04   Ready    <none>          1m      v1.28.3
```

### Ver informacion detallada de los nodos

```bash
# Ver nodos con informacion extendida (IP, OS, Runtime)
kubectl get nodes -o wide
```

**Salida esperada:**
```
NAME          STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
k8s-lab       Ready    control-plane   5m    v1.28.3   192.168.49.2   <none>        Ubuntu 22.04.3 LTS   5.15.0-88-generic docker://24.0.7
k8s-lab-m02   Ready    <none>          3m    v1.28.3   192.168.49.3   <none>        Ubuntu 22.04.3 LTS   5.15.0-88-generic docker://24.0.7
k8s-lab-m03   Ready    <none>          2m    v1.28.3   192.168.49.4   <none>        Ubuntu 22.04.3 LTS   5.15.0-88-generic docker://24.0.7
k8s-lab-m04   Ready    <none>          1m    v1.28.3   192.168.49.5   <none>        Ubuntu 22.04.3 LTS   5.15.0-88-generic docker://24.0.7
```

### Etiquetar los workers (opcional pero recomendado)

Por defecto, los workers no tienen el rol asignado. Puedes etiquetarlos:

```bash
# Asignar rol "worker" a los nodos
kubectl label node k8s-lab-m02 node-role.kubernetes.io/worker=
kubectl label node k8s-lab-m03 node-role.kubernetes.io/worker=
kubectl label node k8s-lab-m04 node-role.kubernetes.io/worker=

# Verificar que los roles se asignaron
kubectl get nodes
```

**Salida esperada:**
```
NAME          STATUS   ROLES           AGE   VERSION
k8s-lab       Ready    control-plane   6m    v1.28.3
k8s-lab-m02   Ready    worker          4m    v1.28.3
k8s-lab-m03   Ready    worker          3m    v1.28.3
k8s-lab-m04   Ready    worker          2m    v1.28.3
```

---

## Paso 4: Taint del Control Plane (NoSchedule)

Por defecto, Minikube permite que el control plane ejecute pods de usuario. En un cluster real de produccion, el control plane esta dedicado exclusivamente a los componentes del sistema (API Server, etcd, scheduler, controller-manager).

Vamos a aplicar un **taint** para que el control plane **no acepte pods de usuario**:

```bash
# Aplicar taint NoSchedule al control plane
kubectl taint nodes k8s-lab node-role.kubernetes.io/control-plane=:NoSchedule
```

**Salida esperada:**
```
node/k8s-lab tainted
```

### Verificar el taint aplicado

```bash
# Ver los taints del nodo control plane
kubectl describe node k8s-lab | grep -A 3 "Taints:"
```

**Salida esperada:**
```
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
```

### Que significa este taint?

```
┌─────────────────────────────────────────────────────────────┐
│                    EFECTO DEL TAINT                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Control Plane (k8s-lab)                                    │
│  ┌─────────────────────────────────────────┐                │
│  │  Taint: NoSchedule                      │                │
│  │                                         │                │
│  │  ✅ kube-apiserver (tiene toleration)   │                │
│  │  ✅ etcd (tiene toleration)             │                │
│  │  ✅ kube-scheduler (tiene toleration)   │                │
│  │  ✅ kube-controller-manager             │                │
│  │  ❌ Pods de usuario → RECHAZADOS        │                │
│  └─────────────────────────────────────────┘                │
│                                                             │
│  Workers (k8s-lab-m02, m03, m04)                            │
│  ┌─────────────────────────────────────────┐                │
│  │  Sin taints                             │                │
│  │                                         │                │
│  │  ✅ Pods de usuario → ACEPTADOS         │                │
│  │  ✅ nginx, apps, servicios, etc.        │                │
│  └─────────────────────────────────────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

> **Concepto clave**: Los componentes del sistema (kube-apiserver, etcd, etc.) tienen **tolerations** que les permiten ejecutarse en nodos con este taint. Los pods de usuario no tienen estas tolerations, por lo que el scheduler no los asignara al control plane.

---

## Paso 5: Verificar la distribucion de pods

### 5.1 Ver pods del sistema y su ubicacion

```bash
# Ver TODOS los pods con la columna NODE (donde se ejecutan)
kubectl get pods --all-namespaces -o wide
```

**Salida esperada:**
```
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE          ...
kube-system   coredns-5dd5756b68-abc12          1/1     Running   0          8m    10.244.0.2     k8s-lab       ...
kube-system   etcd-k8s-lab                      1/1     Running   0          8m    192.168.49.2   k8s-lab       ...
kube-system   kube-apiserver-k8s-lab            1/1     Running   0          8m    192.168.49.2   k8s-lab       ...
kube-system   kube-controller-manager-k8s-lab   1/1     Running   0          8m    192.168.49.2   k8s-lab       ...
kube-system   kube-proxy-xxxxx                  1/1     Running   0          8m    192.168.49.2   k8s-lab       ...
kube-system   kube-proxy-yyyyy                  1/1     Running   0          6m    192.168.49.3   k8s-lab-m02   ...
kube-system   kube-proxy-zzzzz                  1/1     Running   0          5m    192.168.49.4   k8s-lab-m03   ...
kube-system   kube-proxy-wwwww                  1/1     Running   0          4m    192.168.49.5   k8s-lab-m04   ...
kube-system   kube-scheduler-k8s-lab            1/1     Running   0          8m    192.168.49.2   k8s-lab       ...
kube-system   storage-provisioner               1/1     Running   0          8m    192.168.49.2   k8s-lab       ...
```

> **Observa**: Los componentes del sistema (`etcd`, `kube-apiserver`, `kube-scheduler`, `kube-controller-manager`) estan en el nodo `k8s-lab` (control plane). El `kube-proxy` se ejecuta en **todos** los nodos porque es un DaemonSet.

### 5.2 Desplegar pods de prueba y ver donde se asignan

```bash
# Crear un Deployment con 6 replicas para ver la distribucion
kubectl create deployment nginx-test --image=nginx:alpine --replicas=6

# Esperar a que los pods esten Running
kubectl rollout status deployment/nginx-test

# Ver donde se ejecuta CADA pod
kubectl get pods -o wide
```

**Salida esperada:**
```
NAME                          READY   STATUS    RESTARTS   AGE   IP            NODE          ...
nginx-test-7c5b8d6c9-abc12   1/1     Running   0          30s   10.244.1.2    k8s-lab-m02   ...
nginx-test-7c5b8d6c9-def34   1/1     Running   0          30s   10.244.2.2    k8s-lab-m03   ...
nginx-test-7c5b8d6c9-ghi56   1/1     Running   0          30s   10.244.3.2    k8s-lab-m04   ...
nginx-test-7c5b8d6c9-jkl78   1/1     Running   0          30s   10.244.1.3    k8s-lab-m02   ...
nginx-test-7c5b8d6c9-mno90   1/1     Running   0          30s   10.244.2.3    k8s-lab-m03   ...
nginx-test-7c5b8d6c9-pqr12   1/1     Running   0          30s   10.244.3.3    k8s-lab-m04   ...
```

> **Resultado clave**: Ningun pod se asigno al nodo `k8s-lab` (control plane) gracias al taint que aplicamos. Los 6 pods se distribuyeron entre los 3 workers.

### 5.3 Comandos utiles para ver la distribucion de pods por nodo

```bash
# Opcion 1: Ver pods agrupados por nodo usando sort
kubectl get pods -o wide --sort-by='.spec.nodeName'

# Opcion 2: Ver cuantos pods hay en cada nodo
kubectl get pods -o wide --no-headers | awk '{print $7}' | sort | uniq -c | sort -rn

# Opcion 3: Ver todos los pods de un nodo especifico
kubectl get pods --all-namespaces --field-selector spec.nodeName=k8s-lab-m02

# Opcion 4: Usar formato personalizado para ver solo nombre y nodo
kubectl get pods -o custom-columns='POD:metadata.name,NODO:spec.nodeName,IP:status.podIP,ESTADO:status.phase'

# Opcion 5: Describir un nodo para ver todos sus pods
kubectl describe node k8s-lab-m02 | grep -A 50 "Non-terminated Pods"
```

**Ejemplo de salida de la Opcion 2:**
```
  2 k8s-lab-m02
  2 k8s-lab-m03
  2 k8s-lab-m04
```

**Ejemplo de salida de la Opcion 4:**
```
POD                           NODO          IP           ESTADO
nginx-test-7c5b8d6c9-abc12   k8s-lab-m02   10.244.1.2   Running
nginx-test-7c5b8d6c9-def34   k8s-lab-m03   10.244.2.2   Running
nginx-test-7c5b8d6c9-ghi56   k8s-lab-m04   10.244.3.2   Running
nginx-test-7c5b8d6c9-jkl78   k8s-lab-m02   10.244.1.3   Running
nginx-test-7c5b8d6c9-mno90   k8s-lab-m03   10.244.2.3   Running
nginx-test-7c5b8d6c9-pqr12   k8s-lab-m04   10.244.3.3   Running
```

### 5.4 Verificar que el control plane rechaza pods

```bash
# Intentar forzar un pod en el control plane (va a fallar por el taint)
kubectl run test-cp --image=nginx:alpine --overrides='{"spec":{"nodeName":"k8s-lab"}}'

# Verificar el estado del pod
kubectl get pod test-cp
```

**Salida esperada:**
```
NAME      READY   STATUS    RESTARTS   AGE
test-cp   0/1     Pending   0          10s
```

```bash
# Ver por que esta en Pending
kubectl describe pod test-cp | grep -A 5 "Events"
```

> **Nota**: El pod queda en `Pending` porque el nodo tiene un taint que el pod no tolera. Sin embargo, al usar `nodeName` directamente se salta el scheduler, por lo que dependiendo de la version de Kubernetes puede que se ejecute de todas formas. El taint funciona principalmente con el scheduler.

```bash
# Limpiar el pod de prueba
kubectl delete pod test-cp --ignore-not-found=true
```

---

## Paso 6: Cambiar entre clusters

Ahora tienes dos clusters. Asi es como cambias entre ellos:

```bash
# Ver todos los contextos disponibles
kubectl config get-contexts

# Cambiar al cluster k8s-curso (un solo nodo)
kubectl config use-context k8s-curso
kubectl get nodes   # Solo 1 nodo

# Cambiar al cluster k8s-lab (multi-nodo)
kubectl config use-context k8s-lab
kubectl get nodes   # 4 nodos

# Ver el contexto actual
kubectl config current-context
```

**Salida esperada de `get-contexts`:**
```
CURRENT   NAME        CLUSTER     AUTHINFO    NAMESPACE
          k8s-curso   k8s-curso   k8s-curso   default
*         k8s-lab     k8s-lab     k8s-lab     default
```

> **Tip**: El asterisco (`*`) indica el contexto activo. Tambien puedes usar `minikube profile list` para ver ambos clusters.

---

## Paso 7: Limpieza de recursos de prueba

```bash
# Eliminar el deployment de prueba
kubectl delete deployment nginx-test

# Verificar que no quedan pods de prueba
kubectl get pods
```

**Salida esperada:**
```
No resources found in default namespace.
```

> **Importante**: No elimines el cluster `k8s-lab` ni el taint. Los usaremos en laboratorios posteriores sobre scheduling, afinidad y tolerations.

---

## Resumen de comandos clave

| Comando | Descripcion |
|---------|-------------|
| `minikube start -p k8s-lab --nodes=4 --cpus=2 --memory=4096mb` | Crear cluster multi-nodo |
| `kubectl taint nodes k8s-lab node-role.kubernetes.io/control-plane=:NoSchedule` | Evitar pods de usuario en control plane |
| `kubectl get pods -o wide` | Ver pods con columna NODE |
| `kubectl get pods -o wide --sort-by='.spec.nodeName'` | Pods ordenados por nodo |
| `kubectl get pods --field-selector spec.nodeName=NODO` | Pods de un nodo especifico |
| `kubectl get pods -o custom-columns='POD:metadata.name,NODO:spec.nodeName'` | Formato personalizado |
| `kubectl describe node NODO \| grep -A 50 "Non-terminated Pods"` | Pods asignados a un nodo |
| `kubectl label node NODO node-role.kubernetes.io/worker=` | Asignar rol worker |
| `kubectl config use-context NOMBRE` | Cambiar entre clusters |

---

## Troubleshooting

### Error: "Exiting due to RSRC_INSUFFICIENT_CORES"
```bash
# No hay suficientes CPUs para 4 nodos x 2 CPUs
# Solucion 1: Reducir CPUs por nodo
minikube start -p k8s-lab --nodes=4 --cpus=1 --memory=2048mb

# Solucion 2: Reducir numero de nodos
minikube start -p k8s-lab --nodes=3 --cpus=2 --memory=4096mb
```

### Error: "Exiting due to RSRC_INSUFFICIENT_SYS_MEMORY"
```bash
# No hay suficiente RAM para 4 nodos x 4 GB
# Solucion: Reducir memoria por nodo
minikube start -p k8s-lab --nodes=4 --cpus=2 --memory=2048mb
```

### Un nodo aparece como NotReady
```bash
# Ver estado detallado del nodo
kubectl describe node k8s-lab-m04 | grep -A 10 "Conditions"

# Reiniciar el nodo especifico
minikube node stop k8s-lab-m04 -p k8s-lab
minikube node start k8s-lab-m04 -p k8s-lab

# Verificar de nuevo
kubectl get nodes
```

### Quitar el taint si ya no lo necesitas
```bash
# El signo menos (-) al final ELIMINA el taint
kubectl taint nodes k8s-lab node-role.kubernetes.io/control-plane=:NoSchedule-
```

---

## Checklist de completado

- [ ] Cluster `k8s-curso` verificado (1 nodo)
- [ ] Cluster `k8s-lab` creado con 4 nodos
- [ ] Nodos workers etiquetados con rol `worker`
- [ ] Taint aplicado al control plane
- [ ] Deployment de prueba desplegado y verificado en workers
- [ ] Distribucion de pods verificada con `-o wide`
- [ ] Cambio entre contextos probado
- [ ] Recursos de prueba limpiados

---

**Siguiente paso**: [Modulo 04: Pods vs Contenedores](../../../modulo-04-pods-containers/) - Donde desplegaras pods en tu cluster multi-nodo.
