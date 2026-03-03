# Resumen Rapido: Cluster Setup con kubeadm

**Duracion:** 60 minutos | **Nivel:** Principiante | **Archivo:** `kubeadm-lab.yaml`

Este laboratorio resume los conceptos clave del Modulo 22: setup de clusters Kubernetes con kubeadm. Cubre las tres topologias principales (basico, HA stacked, HA external etcd) y proporciona una verificacion rapida del cluster.

Si nunca has configurado un cluster Kubernetes, esta guia explica cada paso desde cero, incluyendo por que existe cada concepto y que significa cada comando.

---

## Conceptos Previos: Antes de Empezar

### ¿Que es Kubernetes y por que necesitas instalarlo?

Imagina que tienes una aplicacion web que necesita ejecutarse en varios servidores al mismo tiempo para no caerse si uno falla. Kubernetes es el sistema que coordina todos esos servidores: decide en cual maquina corre cada contenedor, reinicia los que se caen, y balancea el trafico entre ellos.

Pero Kubernetes no viene preinstalado en tus servidores. Alguien tiene que configurar el software de coordinacion, los certificados de seguridad, la red interna, y la base de datos donde Kubernetes guarda su estado. Ese proceso se llama **cluster setup**.

### ¿Que es un cluster?

Un **cluster** en Kubernetes es un grupo de maquinas (fisicas o virtuales) que trabajan juntas como si fueran una sola unidad. Estas maquinas se llaman **Nodes** (nodos). Hay dos tipos:

- **Control Plane Node**: El "cerebro" del cluster. Toma decisiones: donde correr cada contenedor, como responder a las solicitudes de los usuarios, como gestionar el estado deseado.
- **Worker Node**: Los "musculos" del cluster. Aqui realmente corren los contenedores con tu aplicacion.

```
          ┌─────────────────────────────────┐
          │         CLUSTER KUBERNETES       │
          │                                  │
          │  ┌──────────────┐               │
          │  │ Control Plane │  ← El cerebro │
          │  │  (el "jefe") │               │
          │  └──────┬───────┘               │
          │         │  ordenes              │
          │   ┌─────┴──────┐               │
          │   │   Workers   │  ← Los que    │
          │   │ Worker-1    │    ejecutan    │
          │   │ Worker-2    │    tu app      │
          │   └─────────────┘               │
          └─────────────────────────────────┘
```

### ¿Que es kubeadm?

**kubeadm** es una herramienta oficial de Kubernetes que automatiza la instalacion y configuracion de un cluster. Piensalo como el "asistente de instalacion" de Kubernetes: en lugar de configurar manualmente decenas de certificados, archivos de configuracion y servicios del sistema operativo, kubeadm lo hace por ti con un solo comando.

Sin kubeadm, configurar un cluster Kubernetes desde cero (lo que se llama "the hard way") toma horas y requiere conocimiento profundo de criptografia, redes y sistemas distribuidos. kubeadm reduce ese tiempo a minutos.

### ¿Que es etcd?

**etcd** es la base de datos del cluster. Guarda TODO el estado de Kubernetes: cuantos Pods existen, que Deployments estan definidos, que Secrets hay, en que Node corre cada Pod. Si etcd se pierde, el cluster pierde su memoria completamente.

Por eso, en produccion, etcd debe ser altamente disponible y tener backups frecuentes.

---

## Resumen Conceptual

### Topologias de Cluster

Una **topologia** describe como estan organizadas y conectadas las maquinas del cluster. Hay tres topologias principales, cada una con diferente nivel de complejidad y resistencia a fallos.

| Topologia | Control Planes | etcd | Nodos Minimos | Uso |
|-----------|---------------|------|---------------|-----|
| **Single Master** | 1 | Stacked (local) | 1 + workers | Dev/Test |
| **HA Stacked** | 3+ | En cada CP | 3 + LB + workers | Produccion |
| **HA External** | 3+ | Cluster dedicado | 3 CP + 3 etcd + LB | Enterprise |

**¿Que significa "Stacked"?** Que etcd vive dentro del mismo Control Plane Node. Es mas simple pero si ese nodo falla, pierdes tanto el Control Plane como la base de datos al mismo tiempo.

**¿Que significa "External etcd"?** Que etcd corre en maquinas separadas y dedicadas. Si un Control Plane falla, la base de datos sigue viva. Es la topologia mas robusta pero tambien la mas cara y compleja.

**¿Que significa "HA" (High Availability)?** Alta disponibilidad. Significa que el cluster puede sobrevivir la falla de uno o mas nodos sin dejar de funcionar. Se logra teniendo multiples copias del Control Plane.

### ¿Que hace kubeadm init paso a paso?

Cuando ejecutas `kubeadm init`, ocurren 6 fases en orden. Entender esto ayuda a diagnosticar problemas:

```
1. Pre-flight checks
   ├── Swap deshabilitado
   │     (Kubernetes requiere que el swap este apagado para
   │      predecir cuanta memoria real tiene disponible)
   ├── Puertos disponibles (6443, 2379-2380, 10250)
   │     (Si un programa ya usa esos puertos, kubeadm falla)
   ├── Container runtime (containerd)
   │     (Kubernetes necesita un motor de contenedores instalado)
   └── Modulos kernel (overlay, br_netfilter)
         (Modulos de red que Kubernetes necesita para funcionar)

2. Generacion de certificados
   ├── CA del cluster
   │     (El certificado "raiz" que firma todo lo demas.
   │      Como el notario que valida todos los documentos)
   ├── API Server certs
   │     (Para que los clientes confien en el API Server)
   ├── etcd certs
   │     (Para comunicacion segura entre componentes y etcd)
   └── Service Account keys
         (Para que los Pods se autentiquen contra el API Server)

3. Static Pod manifests
   ├── kube-apiserver     ← La "puerta de entrada" al cluster
   ├── kube-controller-manager  ← El que reconcilia estado deseado vs real
   ├── kube-scheduler     ← El que decide en que Node corre cada Pod
   └── etcd (solo en stacked)  ← La base de datos

4. kubeconfig files
   ├── admin.conf         ← Tu archivo de acceso como administrador
   ├── kubelet.conf       ← Para que el agente local se autentique
   ├── controller-manager.conf
   └── scheduler.conf

5. Bootstrap tokens → Para que los Workers puedan unirse al cluster
6. Addons → CoreDNS (DNS interno) + kube-proxy (reglas de red)
```

### Comparativa de Configuraciones kubeadm

```
CLUSTER BASICO (Lab 01):
├── controlPlaneEndpoint: "<NODE_IP>:6443"
├── etcd: local (stacked, en el mismo nodo)
└── Calico CNI (podSubnet: 192.168.0.0/16)
    ↑ CNI = Container Network Interface, el plugin de red
      que permite que los Pods se comuniquen entre si

CLUSTER HA STACKED (Lab 03):
├── controlPlaneEndpoint: "<LB_IP>:6443"  ← Load Balancer!
│     El Load Balancer reparte el trafico entre los 3 Control Planes.
│     Si uno falla, el LB envia el trafico a los otros dos.
├── etcd: local (en cada control plane)
├── --upload-certs (compartir certificados entre Control Planes)
└── HAProxy como Load Balancer

CLUSTER HA EXTERNAL ETCD (Lab 04):
├── controlPlaneEndpoint: "<LB_IP>:6443"
├── etcd: external
│   ├── endpoints: [etcd-01:2379, etcd-02:2379, etcd-03:2379]
│   │     Los Control Planes se conectan a etcd por red, no localmente
│   ├── caFile, certFile, keyFile (TLS mutuo)
│   │     Comunicacion encriptada y autenticada en ambos sentidos
│   └── Cluster etcd dedicado con systemd
└── cfssl para generar certificados
      (cfssl es una herramienta de criptografia de Cloudflare)
```

---

## Tabla Comparativa: Comandos Clave

| Operacion | Comando |
|-----------|---------|
| Inicializar cluster | `sudo kubeadm init --config kubeadm-config.yaml` |
| Inicializar HA | `sudo kubeadm init --config config.yaml --upload-certs` |
| Configurar kubectl | `mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config` |
| Instalar CNI | `kubectl apply -f calico.yaml` |
| Generar join command | `kubeadm token create --print-join-command` |
| Join worker | `sudo kubeadm join <IP>:6443 --token <T> --discovery-token-ca-cert-hash sha256:<H>` |
| Join control plane | `sudo kubeadm join <LB>:6443 --token <T> --discovery-token-ca-cert-hash sha256:<H> --control-plane --certificate-key <K>` |
| Verificar cluster | `kubectl get nodes -o wide` |
| Verificar etcd | `etcdctl --endpoints=... member list` |
| Verificar certs | `sudo kubeadm certs check-expiration` |
| Reset cluster | `sudo kubeadm reset -f` |

---

## Ejercicio Practico (60 min)

### Paso 1: Verificar que el Cluster esta Funcionando (5 min)

**¿Que vamos a hacer aqui?**

Antes de desplegar cualquier cosa, necesitamos confirmar que el cluster existe y esta sano. Un cluster "sano" significa que todos sus Nodes estan en estado `Ready` y que los componentes del sistema (que corren en el Namespace `kube-system`) estan funcionando.

Un **Namespace** en Kubernetes es como una carpeta logica que agrupa recursos relacionados. `kube-system` es el Namespace reservado para los componentes internos de Kubernetes.

```bash
# Verificar nodos del cluster
kubectl get nodes -o wide
```

Salida esperada:
```
NAME           STATUS   ROLES           AGE   VERSION
control-plane  Ready    control-plane   10m   v1.28.0
worker-1       Ready    <none>          8m    v1.28.0
```

**¿Que significa esta salida?**
- `STATUS: Ready` significa que el nodo esta sano y puede recibir Pods.
- `ROLES: control-plane` identifica al nodo que tiene el cerebro del cluster.
- Si ves `NotReady`, el nodo tiene algun problema (red, disco, memoria, etc.).

```bash
# Verificar componentes del sistema
kubectl get pods -n kube-system
```

Salida esperada:
```
NAME                                   READY   STATUS    RESTARTS
coredns-5d78c9869d-abc12               1/1     Running   0
etcd-control-plane                     1/1     Running   0
kube-apiserver-control-plane           1/1     Running   0
kube-controller-manager-control-plane  1/1     Running   0
kube-scheduler-control-plane           1/1     Running   0
```

**¿Que significa esta salida?**
- `etcd-*`: La base de datos del cluster. Si no esta Running, el cluster no puede guardar estado.
- `kube-apiserver-*`: La API. Si no esta Running, ningun comando kubectl funcionara.
- `coredns-*`: El DNS interno. Si no esta Running, los Pods no podran encontrarse entre si por nombre.

```bash
# Verificar que el API Server responde correctamente
kubectl get --raw /healthz
```

Salida esperada:
```
ok
```

**¿Que significa esta salida?**
El endpoint `/healthz` es un chequeo de salud del API Server. Si responde `ok`, el servidor esta activo y aceptando solicitudes. Si no responde o da error, hay un problema grave con el Control Plane.

**Que acabamos de aprender:** El estado de un cluster se puede verificar en segundos con tres comandos. Los Nodes deben estar `Ready` y los Pods del sistema deben estar `Running`. Estos son los primeros comandos que debes ejecutar cuando algo falla.

---

### Paso 2: Desplegar Recursos de Verificacion (5 min)

**¿Que vamos a hacer aqui?**

Vamos a aplicar un archivo YAML (`kubeadm-lab.yaml`) que crea varios recursos de prueba: un Namespace dedicado, un Deployment con nginx, un Service para exponer nginx, y un Pod auxiliar para hacer pruebas de DNS y conectividad.

Un **Deployment** le dice a Kubernetes "quiero que siempre haya 3 copias de este contenedor corriendo". Kubernetes se encarga de que siempre sean exactamente 3, aunque un Node falle.

Un **Service** es la forma de dar una direccion IP estable y un nombre DNS a un grupo de Pods. Como los Pods pueden cambiar de IP cuando se reinician, el Service actua de intermediario con una IP fija.

```bash
# Aplicar todos los recursos de prueba de una vez
kubectl apply -f kubeadm-lab.yaml
```

Salida esperada:
```
namespace/lab-kubeadm-test created
deployment.apps/nginx-verify created
service/nginx-verify-svc created
pod/busybox-dns-test created
pod/curl-test created
```

**¿Que significa esta salida?**
Cada linea confirma que ese recurso fue creado exitosamente en el cluster. El verbo `created` (vs `configured` o `unchanged`) indica que era nuevo.

```bash
# Verificar que el Namespace existe
kubectl get namespace lab-kubeadm-test
```

Salida esperada:
```
NAME               STATUS   AGE
lab-kubeadm-test   Active   15s
```

**¿Que significa esta salida?**
`STATUS: Active` indica que el Namespace existe y esta en uso. Un Namespace en estado `Terminating` significaria que esta siendo eliminado.

**Que acabamos de aprender:** `kubectl apply -f` es el comando principal para crear o actualizar recursos en Kubernetes a partir de un archivo YAML. Es declarativo: le dices a Kubernetes "quiero esto" y el se encarga de hacerlo realidad.

---

### Paso 3: Verificar Deployment y Service (5 min)

**¿Que vamos a hacer aqui?**

Vamos a confirmar que los Pods del Deployment se distribuyeron entre los Nodes disponibles y que el Service esta activo. La distribucion entre Nodes es importante: si todos los Pods caen en el mismo Node y ese Node falla, la aplicacion se cae.

```bash
# Ver los Pods y en que Node esta corriendo cada uno
kubectl get pods -n lab-kubeadm-test -o wide
```

Salida esperada:
```
NAME                            READY   STATUS    NODE
nginx-verify-7d8c9f-abc12       1/1     Running   worker-1
nginx-verify-7d8c9f-def34       1/1     Running   worker-2
nginx-verify-7d8c9f-ghi56       1/1     Running   worker-1
busybox-dns-test                1/1     Running   worker-1
curl-test                       1/1     Running   worker-2
```

**¿Que significa esta salida?**
La columna `NODE` muestra en que maquina corre cada Pod. Si tienes 3 replicas y todas estan en el mismo Node, la distribucion no es optima. Si un Pod esta en `Pending`, significa que el Scheduler no encontro un Node con suficientes recursos disponibles.

```bash
# Ver el estado general del Deployment
kubectl get deployment -n lab-kubeadm-test
```

Salida esperada:
```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
nginx-verify   3/3     3            3           2m
```

**¿Que significa esta salida?**
- `READY 3/3`: Los 3 Pods pedidos estan corriendo.
- `UP-TO-DATE 3`: Los 3 Pods tienen la version mas reciente de la configuracion.
- `AVAILABLE 3`: Los 3 Pods pueden recibir trafico.
Si ves `1/3`, significa que solo 1 de los 3 Pods solicitados esta listo.

```bash
# Ver el Service creado
kubectl get svc -n lab-kubeadm-test
```

Salida esperada:
```
NAME               TYPE        CLUSTER-IP      PORT(S)   AGE
nginx-verify-svc   ClusterIP   10.96.100.50    80/TCP    2m
```

**¿Que significa esta salida?**
- `TYPE: ClusterIP` significa que el Service solo es accesible desde dentro del cluster, no desde fuera.
- `CLUSTER-IP`: La IP interna estable asignada al Service. Los Pods dentro del cluster pueden usar esta IP o el nombre DNS del Service para comunicarse con nginx.

**Que acabamos de aprender:** Un Deployment gestiona automaticamente el ciclo de vida de multiples Pods. El Scheduler distribuye los Pods entre Nodes. Un Service da una IP y nombre DNS estables a un grupo de Pods que pueden cambiar con el tiempo.

---

### Paso 4: Test de DNS Interno (10 min)

**¿Que vamos a hacer aqui?**

Vamos a verificar que el DNS interno del cluster funciona. En Kubernetes, cada Service recibe automaticamente un nombre DNS con el formato:

`<nombre-service>.<namespace>.svc.cluster.local`

Este sistema de nombres lo gestiona **CoreDNS**, que corre como Pod en `kube-system`. Si CoreDNS falla, los Pods no pueden encontrarse entre si por nombre y la mayoria de las aplicaciones dejan de funcionar.

Vamos a ejecutar comandos dentro del Pod `busybox-dns-test` usando `kubectl exec`. Esto es equivalente a hacer SSH dentro del Pod.

```bash
# Resolver el nombre DNS del Service de nginx que creamos
kubectl exec -n lab-kubeadm-test busybox-dns-test -- \
  nslookup nginx-verify-svc.lab-kubeadm-test.svc.cluster.local
```

Salida esperada:
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      nginx-verify-svc.lab-kubeadm-test.svc.cluster.local
Address 1: 10.96.100.50 nginx-verify-svc.lab-kubeadm-test.svc.cluster.local
```

**¿Que significa esta salida?**
- `Server: 10.96.0.10` es la IP de CoreDNS. Si el DNS no estuviera funcionando, este servidor no responderia.
- La segunda parte muestra que el nombre `nginx-verify-svc.lab-kubeadm-test.svc.cluster.local` se resolvio correctamente a la IP `10.96.100.50` (la IP del Service que vimos en el Paso 3).
- Si ves `nslookup: can't resolve`, CoreDNS tiene un problema.

```bash
# Tambien verificar que se puede resolver el Service de Kubernetes mismo
kubectl exec -n lab-kubeadm-test busybox-dns-test -- \
  nslookup kubernetes.default.svc.cluster.local
```

Salida esperada:
```
Name:      kubernetes.default.svc.cluster.local
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

**¿Que significa esta salida?**
`kubernetes.default` es el Service que representa al propio API Server dentro del cluster. Que se resuelva correctamente confirma que CoreDNS tiene configuracion base correcta.

**Que acabamos de aprender:** El DNS interno de Kubernetes es fundamental para que los microservicios se encuentren entre si. Los nombres siguen el patron `<service>.<namespace>.svc.cluster.local`. CoreDNS es el componente que resuelve estos nombres.

---

### Paso 5: Test de Conectividad de Red (10 min)

**¿Que vamos a hacer aqui?**

Ahora vamos a verificar que un Pod puede realmente conectarse a otro Pod a traves de un Service. Esto valida que el CNI (plugin de red) esta instalado y funcionando. Sin un CNI, los Pods no pueden comunicarse entre Nodes.

```bash
# Hacer una peticion HTTP a nginx a traves del Service
kubectl exec -n lab-kubeadm-test curl-test -- \
  curl -s http://nginx-verify-svc.lab-kubeadm-test/
```

Salida esperada:
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
</head>
...
```

**¿Que significa esta salida?**
Si ves el HTML de la pagina de bienvenida de nginx, significa que:
1. El Pod `curl-test` pudo resolver el nombre DNS del Service (DNS funciona).
2. La peticion llego al Service (kube-proxy funciona).
3. El Service redireccciono la peticion a uno de los Pods de nginx (balanceo de carga funciona).
4. El Pod de nginx respondio correctamente (la aplicacion funciona).

Si el comando se cuelga o da `connection refused`, hay un problema de red: revisa que el CNI este instalado con `kubectl get pods -n kube-system`.

**Que acabamos de aprender:** La cadena de conectividad en Kubernetes es: Pod cliente -> DNS (CoreDNS) -> Service (kube-proxy) -> Pod servidor. Si cualquier eslabon de esta cadena falla, la comunicacion falla. Los comandos `kubectl exec` y `curl` son herramientas basicas de diagnostico.

---

### Paso 6: Verificar Certificados del Cluster (10 min)

**¿Que vamos a hacer aqui?**

Kubernetes usa TLS (certificados digitales) para asegurar toda la comunicacion interna. Los certificados tienen fecha de vencimiento: por defecto, kubeadm genera certificados que vencen en 1 año. Si los certificados vencen, el cluster deja de funcionar completamente.

Este paso verifica cuanto tiempo les queda a los certificados.

```bash
# Ver el estado de todos los certificados del cluster
sudo kubeadm certs check-expiration
```

Salida esperada:
```
CERTIFICATE                EXPIRES                  RESIDUAL TIME
admin.conf                 Mar 01, 2027 10:00 UTC   364d
apiserver                  Mar 01, 2027 10:00 UTC   364d
apiserver-etcd-client      Mar 01, 2027 10:00 UTC   364d
apiserver-kubelet-client   Mar 01, 2027 10:00 UTC   364d
controller-manager.conf    Mar 01, 2027 10:00 UTC   364d
etcd-healthcheck-client    Mar 01, 2027 10:00 UTC   364d
etcd-peer                  Mar 01, 2027 10:00 UTC   364d
etcd-server                Mar 01, 2027 10:00 UTC   364d
front-proxy-client         Mar 01, 2027 10:00 UTC   364d
scheduler.conf             Mar 01, 2027 10:00 UTC   364d
```

**¿Que significa esta salida?**
- `RESIDUAL TIME: 364d` significa que los certificados vencen en 364 dias. Si ves un numero bajo (menos de 30 dias), debes renovarlos urgentemente.
- Para renovar todos los certificados: `sudo kubeadm certs renew all`
- La CA del cluster (el certificado raiz) tiene validez de 10 años y no se renueva con este comando.

```bash
# Ver los detalles tecnicos del certificado del API Server
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | \
  grep -E 'Subject:|Not After'
```

Salida esperada:
```
        Subject: CN = kube-apiserver
            Not After : Mar  1 10:00:00 2027 GMT
```

**¿Que significa esta salida?**
- `CN = kube-apiserver`: El nombre del certificado (Common Name). Identifica para que componente fue emitido.
- `Not After`: La fecha exacta de vencimiento. Si hoy es posterior a esa fecha, el cluster esta caido por certificados vencidos.

**Que acabamos de aprender:** Los certificados son criticos para la seguridad y el funcionamiento del cluster. Deben renovarse anualmente. En produccion, se suele configurar un proceso automatico de renovacion o una alarma que avise 60 dias antes del vencimiento.

---

### Paso 7: Verificar etcd (10 min)

**¿Que vamos a hacer aqui?**

etcd es la base de datos de Kubernetes. Si etcd no esta sano, el cluster puede fallar silenciosamente (acepta lecturas pero rechaza escrituras) o colapsar completamente. Esta verificacion es especialmente importante en clusters de produccion.

**Nota:** Estos comandos solo funcionan si tienes acceso directo al Control Plane Node. En clusters gestionados (AKS, GKE, EKS) no tienes acceso a etcd.

```bash
# Verificar que etcd esta sano y respondiendo
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

Salida esperada:
```
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.5ms
```

**¿Que significa esta salida?**
- `is healthy`: etcd puede leer y escribir datos correctamente.
- `took = 2.5ms`: La latencia para confirmar una escritura. Si supera 100ms, etcd esta bajo mucha carga o el disco es lento.
- Si ves `unhealthy`, etcd tiene problemas. Revisa los logs con: `kubectl logs -n kube-system etcd-<nombre-nodo>`

```bash
# Listar todos los miembros del cluster etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

Salida esperada (cluster de un solo nodo):
```
8e9e05c52164694d, started, control-plane, https://192.168.1.100:2380, https://192.168.1.100:2379, false
```

Salida esperada (cluster HA con 3 Control Planes):
```
8e9e05c52164694d, started, cp-1, https://192.168.1.100:2380, https://192.168.1.100:2379, false
91bc3c398fb3c146, started, cp-2, https://192.168.1.101:2380, https://192.168.1.101:2379, false
fd422379fda50e48, started, cp-3, https://192.168.1.102:2380, https://192.168.1.102:2379, false
```

**¿Que significa esta salida?**
- El primer campo es el ID unico de cada miembro etcd.
- `started` vs `unstarted`: `started` significa que el miembro esta activo.
- En HA, necesitas ver al menos 2 de 3 miembros `started` para que el cluster funcione (quorum).

**Que acabamos de aprender:** etcd es el componente mas critico del cluster. Su salud se verifica con `etcdctl endpoint health`. En clusters HA, necesitas mayoria de miembros (quorum) para que etcd funcione. La lentitud de etcd suele deberse a disco lento, no a CPU o RAM.

---

### Paso 8: Limpieza de Recursos (5 min)

**¿Que vamos a hacer aqui?**

Eliminar los recursos de prueba que creamos para que no consuman recursos del cluster. En Kubernetes, eliminar un Namespace elimina automaticamente todos los recursos dentro de el.

```bash
# Ejecutar el script de limpieza incluido en el laboratorio
./cleanup.sh
```

Salida esperada:
```
Iniciando limpieza del Lab Resumen: kubeadm...
  - Eliminando namespace lab-kubeadm-test...
  namespace "lab-kubeadm-test" deleted
Limpieza completada exitosamente.
```

```bash
# Alternativamente, eliminar directamente el Namespace
kubectl delete namespace lab-kubeadm-test
```

```bash
# Verificar que el Namespace fue eliminado
kubectl get namespace lab-kubeadm-test
```

Salida esperada:
```
Error from server (NotFound): namespaces "lab-kubeadm-test" not found
```

**¿Que significa esta salida?**
El mensaje `NotFound` confirma que el Namespace ya no existe. Esto es el comportamiento correcto despues de la limpieza.

**Que acabamos de aprender:** En Kubernetes, los Namespaces son la unidad de aislamiento y limpieza. Eliminar un Namespace es la forma mas rapida de limpiar todos los recursos de un ejercicio o entorno de prueba.

---

## Resumen Visual: Arquitecturas

```
SINGLE MASTER (Lab 01)        HA STACKED (Lab 03)          HA EXTERNAL ETCD (Lab 04)

   ┌──────────┐                ┌──────────┐                ┌──────────────────┐
   │ Control  │                │   Load   │                │ etcd-01 etcd-02  │
   │  Plane   │                │ Balancer │                │     etcd-03      │
   │ + etcd   │                │ (HAProxy)│                │  (cluster TLS)   │
   └────┬─────┘                └────┬─────┘                └────────┬─────────┘
        │                           │                               │
   ┌────┴────┐           ┌─────────┼─────────┐             ┌──────┴──────┐
   │         │           │         │         │             │  Load       │
Worker-1  Worker-2    CP-1      CP-2      CP-3          Balancer     │
                      +etcd     +etcd     +etcd            │          │
                         │         │         │      ┌──────┼──────┐  │
                      Worker-1  Worker-2  Worker-3  CP-1  CP-2  CP-3 │
                                                   (sin etcd local)  │
                                                      Worker-1 Worker-2
```

**¿Que ventaja tiene cada topologia?**

- **Single Master**: Un solo nodo de control. Si ese nodo falla, no puedes gestionar el cluster (no crear Pods nuevos, no escalar). Los Pods existentes siguen corriendo en los Workers. Ideal para desarrollo y aprendizaje.
- **HA Stacked**: Tres Control Planes con etcd colocado en cada uno. Si un Control Plane falla, los otros dos siguen funcionando. El cluster puede perder hasta 1 de 3 Control Planes y sobrevivir.
- **HA External**: Lo mismo que HA Stacked pero etcd en maquinas separadas. El beneficio es que puedes escalar o actualizar etcd independientemente del Control Plane. Es la topologia mas cara pero la mas resiliente.

---

## Decision: Que Topologia Usar

| Criterio | Single Master | HA Stacked | HA External |
|----------|:---:|:---:|:---:|
| **Complejidad** | Baja | Media | Alta |
| **Tolerancia a fallos** | Ninguna | 1 CP | Independiente |
| **Nodos minimos** | 1 | 4 (3 CP + 1 LB) | 7 (3 CP + 3 etcd + 1 LB) |
| **Costo** | Bajo | Medio | Alto |
| **Dev/Test** | Si | Overkill | No |
| **Produccion** | No | Si | Si (critico) |
| **CKA Exam** | Si | Si | Conocer conceptos |

---

## Preparacion CKA: Comandos Rapidos

En el examen CKA tendras que inicializar clusters y agregar Workers en tiempo limitado. Estos son los comandos que debes poder ejecutar de memoria:

```bash
# INIT BASICO (3 min)
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# AGREGAR WORKER (1 min)
kubeadm token create --print-join-command  # Ejecutar en el Control Plane
sudo kubeadm join <IP>:6443 --token <T> --discovery-token-ca-cert-hash sha256:<H>  # Ejecutar en el Worker

# VERIFICAR (30 seg)
kubectl get nodes
kubectl get pods -n kube-system

# RESET COMPLETO (si algo salio mal y necesitas empezar de nuevo)
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd ~/.kube
sudo iptables -F && sudo iptables -t nat -F
```

**Consejo para el examen:** El paso mas comun que se olvida despues de `kubeadm init` es copiar el `admin.conf` a `~/.kube/config`. Sin ese paso, `kubectl` no puede conectarse al cluster aunque el init haya exitoso.
