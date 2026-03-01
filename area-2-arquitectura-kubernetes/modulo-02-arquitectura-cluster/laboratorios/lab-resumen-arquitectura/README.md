# Lab Resumen: Arquitectura del Cluster

Revision guiada de 15 minutos sobre los componentes clave de la arquitectura de Kubernetes,
disenada para ejecutarse en Minikube. Ideal para repasar antes de un examen CKAD/CKA.

**Duracion:** 15 minutos | **Nivel:** Intermedio

## Conceptos Cubiertos

| Componente | Concepto demostrado |
|------------|---------------------|
| API Server | Punto de entrada de todos los manifests y peticiones kubectl |
| kube-scheduler | Asignacion de Pods a nodos segun recursos y nodeSelector |
| kubelet | Gestion de ciclo de vida del contenedor y ejecucion de probes |
| kube-proxy | Implementacion de Services con iptables/IPVS y NetworkPolicy |
| Container Runtime | Ejecucion real de contenedores (containerd/CRI-O) |

## Archivo del Lab

| Archivo | Descripcion |
|---------|-------------|
| `arquitectura-lab.yaml` | YAML unico con todos los recursos del lab |

---

## Paso 1: Desplegar todos los recursos (1 minuto)

```bash
kubectl apply -f arquitectura-lab.yaml
```

**Salida esperada:**
```
namespace/lab-arquitectura-test created
deployment.apps/web-app created
service/web-app-svc created
pod/scheduler-demo created
pod/kubelet-demo created
networkpolicy.networking.k8s.io/frontend-only created
pod/netshoot created
```

---

## Paso 2: Demostrar el API Server (2 minutos)

El API Server es el punto de entrada de todas las operaciones. Cuando ejecutas `kubectl apply`,
el cliente envia el manifest al API Server via HTTPS, que lo valida, lo guarda en etcd
y notifica a los controllers.

```bash
# Ver el endpoint del API Server
kubectl cluster-info

# Interactuar directamente con el API Server (sin kubectl)
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
echo "API Server: $API_SERVER"

# Verificar salud del API Server
kubectl get --raw /healthz
```

**Salida esperada de `/healthz`:**
```
ok
```

```bash
# Ver los recursos recien creados
kubectl get all -n lab-arquitectura-test
```

**Salida esperada:**
```
NAME                          READY   STATUS    RESTARTS   AGE
pod/kubelet-demo              1/1     Running   0          30s
pod/netshoot                  1/1     Running   0          30s
pod/scheduler-demo            1/1     Running   0          30s
pod/web-app-xxx-yyy           1/1     Running   0          30s
...
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web-app-svc   ClusterIP   10.xx.xx.xx     <none>        80/TCP    30s
```

---

## Paso 3: Demostrar el Scheduler (3 minutos)

El kube-scheduler asigna cada Pod pendiente al nodo mas adecuado, evaluando recursos
disponibles, taints/tolerations, nodeSelector y affinity rules.

```bash
# Ver en que nodo asigno el Scheduler cada pod
kubectl get pods -n lab-arquitectura-test -o wide

# Ver el evento de scheduling del scheduler-demo
kubectl get events -n lab-arquitectura-test \
  --field-selector involvedObject.name=scheduler-demo \
  --sort-by='.lastTimestamp'
```

**Salida esperada del evento:**
```
LAST SEEN   TYPE     REASON      OBJECT                MESSAGE
Xs          Normal   Scheduled   pod/scheduler-demo    Successfully assigned lab-arquitectura-test/scheduler-demo to minikube
```

```bash
# Ver el nodeSelector del pod
kubectl get pod scheduler-demo -n lab-arquitectura-test \
  -o jsonpath='{.spec.nodeSelector}' && echo
```

**Salida esperada:**
```
{"kubernetes.io/os":"linux"}
```

---

## Paso 4: Demostrar kubelet (3 minutos)

kubelet es el agente que corre en cada nodo. Recibe la especificacion del Pod del API Server,
ordena al container runtime que inicie el contenedor, y ejecuta las health probes periodicamente.

```bash
# Ver la livenessProbe del pod kubelet-demo
kubectl describe pod kubelet-demo -n lab-arquitectura-test | grep -A 8 "Liveness:"

# Ver los eventos generados por kubelet al iniciar el pod
kubectl get events -n lab-arquitectura-test \
  --field-selector involvedObject.name=kubelet-demo \
  --sort-by='.lastTimestamp'
```

**Salida esperada de describe:**
```
Liveness:   http-get http://:80/ delay=10s timeout=1s period=10s #success=1 #failure=3
```

```bash
# Ver cuantas veces ha reiniciado (debe ser 0 si la probe es exitosa)
kubectl get pod kubelet-demo -n lab-arquitectura-test \
  -o jsonpath='{.status.containerStatuses[0].restartCount}' && echo
```

**Salida esperada:**
```
0
```

---

## Paso 5: Demostrar kube-proxy y Services (3 minutos)

kube-proxy implementa el concepto de Service en cada nodo usando reglas iptables o IPVS.
Cuando un Pod accede a la ClusterIP de un Service, kube-proxy redirige el trafico
a uno de los Pods del Service mediante DNAT.

```bash
# Ver la ClusterIP del Service
kubectl get svc web-app-svc -n lab-arquitectura-test

# Ver los endpoints (IPs de los Pods detras del Service)
kubectl get endpoints web-app-svc -n lab-arquitectura-test

# Desde el pod netshoot, acceder al Service por su nombre DNS
kubectl exec -n lab-arquitectura-test netshoot -- curl -s http://web-app-svc | head -5
```

**Salida esperada de curl:**
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

```bash
# Verificar la NetworkPolicy (kube-proxy + CNI)
kubectl get networkpolicy -n lab-arquitectura-test

# El pod netshoot tiene label tier=frontend, por lo que puede acceder a web-app
# Un pod sin ese label seria bloqueado por la NetworkPolicy
kubectl exec -n lab-arquitectura-test netshoot -- curl -s --max-time 3 http://web-app-svc
```

---

## Paso 6: Demostrar el Container Runtime (2 minutos)

El container runtime (containerd o CRI-O) es el responsable de descargar imagenes,
crear contenedores y gestionarlos. kubelet se comunica con el runtime via CRI (Container Runtime Interface).

```bash
# Ver la imagen y el container runtime en uso
kubectl get nodes -o wide

# Ver los contenedores corriendo a nivel de Pod
kubectl get pods -n lab-arquitectura-test -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].image}{"\n"}{end}'

# Verificar estado detallado del contenedor
kubectl describe pod web-app -n lab-arquitectura-test 2>/dev/null || \
  kubectl get pods -n lab-arquitectura-test -l app=web-app -o name | head -1 | \
  xargs kubectl describe -n lab-arquitectura-test
```

**Salida esperada (columna CONTAINER-RUNTIME en `kubectl get nodes -o wide`):**
```
NAME       ...   CONTAINER-RUNTIME
minikube   ...   containerd://1.7.x
```

---

## Paso 7: Verificacion Final (1 minuto)

```bash
# Ver todos los recursos del lab en estado correcto
kubectl get all,networkpolicy -n lab-arquitectura-test

# Resumen de componentes observados
echo "=== Componentes verificados ==="
echo "API Server:       $(kubectl get --raw /healthz)"
echo "Scheduler:        $(kubectl get pod scheduler-demo -n lab-arquitectura-test -o jsonpath='{.spec.nodeName}')"
echo "kubelet probes:   $(kubectl get pod kubelet-demo -n lab-arquitectura-test -o jsonpath='{.status.containerStatuses[0].restartCount}') reinicios"
echo "kube-proxy svc:   $(kubectl get svc web-app-svc -n lab-arquitectura-test -o jsonpath='{.spec.clusterIP}')"
echo "Runtime:          $(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.containerRuntimeVersion}')"
```

---

## Limpieza

```bash
./cleanup.sh
```

---

## Checklist de Conocimientos

- [ ] El API Server valida y persiste todos los recursos en etcd
- [ ] El Scheduler asigna Pods a nodos evaluando recursos y restricciones
- [ ] kubelet ejecuta las health probes y reinicia contenedores que fallan
- [ ] kube-proxy implementa Services con reglas iptables/IPVS en cada nodo
- [ ] El container runtime gestiona el ciclo de vida del contenedor via CRI
- [ ] Una NetworkPolicy requiere un CNI compatible (Calico, Cilium, etc.)
