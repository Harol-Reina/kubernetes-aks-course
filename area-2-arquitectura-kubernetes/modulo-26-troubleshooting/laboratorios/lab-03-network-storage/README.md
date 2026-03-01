# Laboratorio 03: Network & Storage Advanced Troubleshooting

**Duracion estimada:** 75-90 minutos
**Nivel:** Experto
**Objetivo:** Diagnosticar y resolver problemas avanzados de red y almacenamiento en Kubernetes

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **DNS / CoreDNS troubleshooting** | Diagnostico de fallos de resolucion DNS: verificacion de pods CoreDNS, ConfigMap de Corefile, endpoints del Service kube-dns, y configuracion de kubelet |
| **Service Endpoints y label matching** | Identificacion de desincronizacion entre el selector del Service y los labels del Pod. Reparacion mediante patch de selector o re-etiquetado de Pods |
| **Network Policies** | Diagnostico de trafico bloqueado por politicas restrictivas. Creacion de excepciones selectivas para Ingress y Egress conservando el aislamiento base |
| **PersistentVolumeClaim lifecycle** | Resolucion de PVCs en estado Pending por StorageClass inexistente, falta de PVs disponibles, incompatibilidad de accessModes, o tamano excesivo |
| **StatefulSet storage** | Troubleshooting de StatefulSets con volumeClaimTemplates que no pueden satisfacerse. Recreacion con StorageClass valida y provision manual de PVs |
| **Volume permissions y SecurityContext** | Diagnostico de errores Permission denied en volumenes. Uso de initContainer y emptyDir para resolver incompatibilidades de fsGroup y hostPath |
| **Ingress Controllers** | Verificacion del Ingress Controller, diagnostico de reglas con nombre de Service incorrecto, y correccion mediante patch o edicion del recurso Ingress |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Escenario | Descripcion |
|---------|-----------|-------------|
| `scenario-01-dns-fix-configmap.yaml` | 1 | ConfigMap coredns con Corefile correcto para restaurar DNS |
| `scenario-02-endpoints-setup.yaml` | 2 | Pod web-pod + Service web-service con label mismatch (setup del problema) |
| `scenario-02-endpoints-fix.yaml` | 2 | Service web-service con selector correcto (fix) |
| `scenario-03-netpol-setup.yaml` | 3 | NetworkPolicy deny-all que bloquea todo el trafico (setup) |
| `scenario-03-netpol-fix.yaml` | 3 | NetworkPolicies allow-frontend-to-backend + allow-frontend-egress (fix) |
| `scenario-04-pvc-setup.yaml` | 4 | PVC my-pvc con StorageClass inexistente (setup del problema) |
| `scenario-04-pvc-fix-storageclass.yaml` | 4 | PVC my-pvc con StorageClass "standard" valida (fix opcion 1) |
| `scenario-04-pvc-fix-manual-pv.yaml` | 4 | PersistentVolume my-pv manual para static provisioning (fix opcion 2) |
| `scenario-04-pvc-fix-accessmode.yaml` | 4 | PVC my-pvc con accessMode ReadWriteMany corregido (fix opcion 3) |
| `scenario-04-pvc-fix-size.yaml` | 4 | PVC my-pvc con solicitud de storage reducida a 1Gi (fix opcion 4) |
| `scenario-05-statefulset-setup.yaml` | 5 | StatefulSet web con StorageClass inexistente (setup del problema) |
| `scenario-05-statefulset-fix.yaml` | 5 | StatefulSet web con StorageClass "standard" valida (fix) |
| `scenario-06-volume-setup.yaml` | 6 | Pod writer-pod con hostPath y permisos restrictivos (setup del problema) |
| `scenario-06-volume-fix-initcontainer.yaml` | 6 | Pod writer-pod con initContainer que corrige permisos (fix opcion 1) |
| `scenario-06-volume-fix-emptydir.yaml` | 6 | Pod writer-pod con emptyDir que respeta fsGroup (fix opcion 2) |
| `scenario-07-ingress-setup.yaml` | 7 | Pod + Service + Ingress con nombre de Service incorrecto (setup del problema) |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Cluster de Kubernetes funcional (minikube, kind, k3s, o cloud)
- kubectl configurado y con permisos de administrador
- Conocimientos de Services, NetworkPolicies y almacenamiento persistente

### Verificacion del entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar que puedes crear recursos
kubectl auth can-i create networkpolicies

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Objetivos CKA

> **Distribucion CKA**: Services & Networking (20%), Storage (10%), Troubleshooting (25-30%)

Al completar este laboratorio, seras capaz de:
- Troubleshoot DNS (CoreDNS) issues
- Diagnosticar Services sin endpoints
- Resolver problemas de Network Policies
- Troubleshoot Ingress Controllers
- Diagnosticar PersistentVolumeClaims Pending
- Resolver problemas con StatefulSets y storage
- Troubleshoot volume mounts y permisos
- Diagnosticar problemas de conectividad entre pods

---

## Escenario 1: DNS Resolution Failure

**Situacion**: Los pods no pueden resolver nombres DNS.

**Setup del Problema**:
```bash
# Crear pod de prueba
kubectl run test-dns --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
# Output: Server misbehaving o timeout
```

<details>
<summary>Diagnostico Completo</summary>

```bash
# 1. Verificar CoreDNS esta corriendo
kubectl get pods -n kube-system -l k8s-app=kube-dns
# NAME                       READY   STATUS    RESTARTS   AGE
# coredns-xxxxxxxxxx-xxxxx   1/1     Running   0          10d

# 2. Si no esta running, ver logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# 3. Verificar Service de DNS
kubectl get svc -n kube-system kube-dns
# NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)         AGE
# kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP   10d

# 4. Verificar endpoints del DNS service
kubectl get endpoints -n kube-system kube-dns
# Debe tener IPs de los pods de CoreDNS

# 5. Verificar configuracion de CoreDNS
kubectl get configmap -n kube-system coredns -o yaml

# 6. Test manual desde un pod
kubectl run test-dns --image=busybox:1.28 -it --rm -- sh
# Dentro del pod:
cat /etc/resolv.conf
# Debe apuntar a la IP del kube-dns service (tipicamente 10.96.0.10)

nslookup kubernetes.default
nslookup google.com  # Test DNS externo
```

</details>

<details>
<summary>Soluciones por Problema</summary>

**Problema 1: CoreDNS pods no estan Running**
```bash
# Ver estado
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Si estan Pending, ver recursos
kubectl describe pod -n kube-system -l k8s-app=kube-dns

# Escalar deployment si es necesario
kubectl scale deployment coredns -n kube-system --replicas=2

# Ver logs de errores
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
```

**Problema 2: CoreDNS sin endpoints**
```bash
# Verificar
kubectl get endpoints -n kube-system kube-dns
# ENDPOINTS: <none>

# El problema es que los pods no son seleccionados
kubectl get pods -n kube-system -l k8s-app=kube-dns --show-labels

# Ver selector del servicio
kubectl get svc -n kube-system kube-dns -o yaml | grep -A 3 selector

# Si no coinciden, editar el servicio
kubectl edit svc -n kube-system kube-dns
# Ajustar selector para que coincida con labels de pods
```

**Problema 3: ConfigMap de CoreDNS corrupto**
```bash
# Backup del ConfigMap actual
kubectl get cm -n kube-system coredns -o yaml > /tmp/coredns-cm-backup.yaml

# Ver configuracion
kubectl get cm -n kube-system coredns -o yaml

# Restaurar ConfigMap correcto basico:
kubectl apply -f scenario-01-dns-fix-configmap.yaml

# Reiniciar CoreDNS pods
kubectl delete pod -n kube-system -l k8s-app=kube-dns
```

**Problema 4: kubelet no configura DNS en pods**
```bash
# En cada node, verificar kubelet config
sudo cat /var/lib/kubelet/config.yaml | grep -A 5 clusterDNS

# Debe tener:
# clusterDNS:
# - 10.96.0.10  # IP del kube-dns service

# Si no esta, agregar y reiniciar kubelet
sudo vi /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
```

**Verificacion Final**:
```bash
# Test resolucion
kubectl run test-dns --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
# Debe funcionar

# Test desde dentro del cluster
kubectl run nginx-test --image=nginx
kubectl expose pod nginx-test --port=80
kubectl run test --image=busybox:1.28 -it --rm -- nslookup nginx-test.default.svc.cluster.local
# Debe resolver
```

</details>

---

## Escenario 2: Service Without Endpoints

**Situacion**: Un Service existe pero no tiene endpoints, las requests fallan.

**Setup**:
```bash
kubectl apply -f scenario-02-endpoints-setup.yaml
```

<details>
<summary>Diagnostico</summary>

```bash
# 1. Verificar service
kubectl get svc web-service
# TYPE: ClusterIP, CLUSTER-IP: 10.x.x.x, PORT(S): 80/TCP

# 2. Verificar endpoints
kubectl get endpoints web-service
# ENDPOINTS: <none>  <- PROBLEMA!

# 3. Ver selector del service
kubectl describe svc web-service
# Selector: app=webapp,tier=frontend

# 4. Ver labels de los pods
kubectl get pods --show-labels | grep web-pod
# Labels: app=web,tier=frontend  <- Mismatch en 'app'

# 5. Comparar selectores
kubectl get svc web-service -o yaml | grep -A 3 selector
kubectl get pod web-pod -o yaml | grep -A 3 labels
```

</details>

<details>
<summary>Solucion</summary>

**Opcion 1: Corregir labels del pod**
```bash
kubectl label pod web-pod app=webapp --overwrite

# Verificar endpoints ahora existen
kubectl get endpoints web-service
# ENDPOINTS: 10.244.x.x:80
```

**Opcion 2: Corregir selector del service**
```bash
kubectl patch svc web-service -p '{"spec":{"selector":{"app":"web","tier":"frontend"}}}'

# Verificar
kubectl get endpoints web-service
```

**Opcion 3: Recrear el service**
```bash
kubectl delete svc web-service
kubectl apply -f scenario-02-endpoints-fix.yaml
```

**Verificacion**:
```bash
# Endpoints debe tener IP
kubectl get endpoints web-service

# Test conectividad
kubectl run test --image=busybox:1.28 -it --rm -- wget -O- http://web-service
```

</details>

---

## Escenario 3: Network Policy Blocking Traffic

**Situacion**: Despues de aplicar Network Policies, los pods no pueden comunicarse.

**Setup**:
```bash
# Crear dos pods
kubectl run frontend --image=nginx --labels=app=frontend
kubectl run backend --image=nginx --labels=app=backend

# Aplicar Network Policy muy restrictiva
kubectl apply -f scenario-03-netpol-setup.yaml

# Test - debe fallar
kubectl exec frontend -- curl -m 5 backend
# Timeout
```

<details>
<summary>Diagnostico</summary>

```bash
# 1. Listar Network Policies
kubectl get networkpolicies
kubectl describe networkpolicy deny-all

# 2. Ver que pods estan afectados
kubectl get pods --show-labels

# 3. Ver reglas de la policy
kubectl get networkpolicy deny-all -o yaml

# 4. Verificar que el CNI soporta Network Policies
kubectl get pods -n kube-system | grep -E "calico|cilium|weave"
# Si no hay CNI que soporte policies, no funcionaran

# 5. Test conectividad
kubectl exec frontend -- curl -m 5 backend
# connection timeout
```

</details>

<details>
<summary>Solucion</summary>

**Solucion 1: Crear policy permisiva**
```bash
# Permitir egress desde frontend a backend
kubectl apply -f scenario-03-netpol-fix.yaml
```

**Solucion 2: Eliminar policy restrictiva** (temporal):
```bash
kubectl delete networkpolicy deny-all
```

**Verificacion**:
```bash
# Test conectividad
kubectl exec frontend -- curl -m 5 backend
# Debe funcionar ahora

# Ver politicas aplicadas
kubectl get networkpolicies
kubectl describe networkpolicy allow-frontend-to-backend
```

</details>

---

## Escenario 4: PersistentVolumeClaim Pending

**Situacion**: Un PVC se queda en estado Pending indefinidamente.

**Setup**:
```bash
kubectl apply -f scenario-04-pvc-setup.yaml
```

<details>
<summary>Diagnostico</summary>

```bash
# 1. Ver estado del PVC
kubectl get pvc my-pvc
# STATUS: Pending

# 2. Describir para ver eventos
kubectl describe pvc my-pvc
# Events: no persistent volumes available for this claim and no storage class is set

# 3. Ver StorageClasses disponibles
kubectl get storageclass
kubectl get sc

# 4. Ver PersistentVolumes disponibles
kubectl get pv

# 5. Ver detalles del StorageClass solicitado
kubectl get sc nonexistent-storage-class
# Error: not found
```

</details>

<details>
<summary>Soluciones</summary>

**Problema 1: StorageClass no existe**
```bash
# Ver SC disponibles
kubectl get sc

# Recrear PVC con SC valido
kubectl delete pvc my-pvc
kubectl apply -f scenario-04-pvc-fix-storageclass.yaml

# Verificar
kubectl get pvc my-pvc
# STATUS: Bound
```

**Problema 2: No hay PV disponible (sin dynamic provisioning)**
```bash
# Crear PV manualmente
kubectl apply -f scenario-04-pvc-fix-manual-pv.yaml

# El PVC debe bind automaticamente si es compatible
kubectl get pvc my-pvc
```

**Problema 3: Access Mode incompatible**
```bash
# Si hay PVs pero con access modes diferentes
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,ACCESS:.spec.accessModes

# Ajustar PVC al access mode disponible
kubectl delete pvc my-pvc
kubectl apply -f scenario-04-pvc-fix-accessmode.yaml
```

**Problema 4: Tamano solicitado mayor al disponible**
```bash
# Ver capacidades disponibles
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,STATUS:.status.phase

# Ajustar size en PVC
kubectl delete pvc my-pvc
kubectl apply -f scenario-04-pvc-fix-size.yaml
```

</details>

---

## Escenario 5: StatefulSet Volume Mount Issues

**Situacion**: Un StatefulSet no puede iniciar porque falla el volume mount.

**Setup**:
```bash
kubectl apply -f scenario-05-statefulset-setup.yaml
```

<details>
<summary>Diagnostico</summary>

```bash
# 1. Ver estado del StatefulSet
kubectl get statefulset web
# READY: 0/2

# 2. Ver pods
kubectl get pods -l app=web
# STATUS: Pending

# 3. Describir pods
kubectl describe pod web-0
# Events: persistentvolumeclaim "data-web-0" not found

# 4. Ver PVCs creados
kubectl get pvc
# STATUS: Pending (para data-web-0, data-web-1)

# 5. Ver por que estan Pending
kubectl describe pvc data-web-0
# StorageClass not found
```

</details>

<details>
<summary>Solucion</summary>

```bash
# El problema es el StorageClass

# Opcion 1: Usar StorageClass valido
kubectl delete statefulset web
kubectl delete pvc data-web-0 data-web-1

kubectl apply -f scenario-05-statefulset-fix.yaml

# Verificar
kubectl get statefulset web
kubectl get pods -l app=web
kubectl get pvc
```

**Opcion 2: Crear PVs manualmente (sin dynamic provisioning)**
```bash
# Crear PVs para cada replica (usa variable de shell, se mantiene inline)
for i in 0 1; do
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-web-$i
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /mnt/data-$i
  persistentVolumeReclaimPolicy: Retain
EOF
done

# Los PVCs deben bind automaticamente
kubectl get pvc
kubectl get pods -l app=web
```

</details>

---

## Escenario 6: Volume Permission Issues

**Situacion**: Un pod esta Running pero la aplicacion no puede escribir en el volume.

**Setup**:
```bash
kubectl apply -f scenario-06-volume-setup.yaml
```

<details>
<summary>Diagnostico</summary>

```bash
# 1. Ver estado del pod
kubectl get pod writer-pod
# STATUS: Running pero logs mostraran errores

# 2. Ver logs
kubectl logs writer-pod
# sh: can't create /data/log.txt: Permission denied

# 3. Exec al pod y verificar permisos
kubectl exec writer-pod -- ls -la /data
# drwxr-xr-x root root ...

# 4. Verificar user/group del container
kubectl exec writer-pod -- id
# uid=1000 gid=2000

# 5. Verificar SecurityContext
kubectl get pod writer-pod -o yaml | grep -A 10 securityContext
```

</details>

<details>
<summary>Soluciones</summary>

**Solucion 1: Ajustar permisos en el node** (hostPath):
```bash
# SSH al node donde corre el pod
NODE=$(kubectl get pod writer-pod -o jsonpath='{.spec.nodeName}')
ssh $NODE

# Cambiar permisos del directorio
sudo chown -R 1000:2000 /mnt/readonly-dir
sudo chmod -R 775 /mnt/readonly-dir

# Verificar
ls -la /mnt/readonly-dir
```

**Solucion 2: Usar initContainer para arreglar permisos**:
```bash
kubectl delete pod writer-pod
kubectl apply -f scenario-06-volume-fix-initcontainer.yaml
```

**Solucion 3: Usar emptyDir (temporal)**:
```bash
kubectl delete pod writer-pod
kubectl apply -f scenario-06-volume-fix-emptydir.yaml
```

**Verificacion**:
```bash
# Ver logs - no debe haber errores de permisos
kubectl logs writer-pod

# Verificar archivo creado
kubectl exec writer-pod -- cat /data/log.txt
```

</details>

---

## Escenario 7: Ingress Not Working

**Situacion**: Ingress configurado pero no enruta trafico.

**Setup** (requiere Ingress Controller instalado):
```bash
kubectl apply -f scenario-07-ingress-setup.yaml
```

<details>
<summary>Diagnostico</summary>

```bash
# 1. Verificar Ingress Controller esta corriendo
kubectl get pods -n ingress-nginx  # o el namespace correcto
# O para minikube
minikube addons list | grep ingress

# 2. Ver Ingress
kubectl get ingress app-ingress
kubectl describe ingress app-ingress
# Buscar en Events: Service "app-service-wrong" does not exist

# 3. Verificar Service existe
kubectl get svc app-service
kubectl get svc app-service-wrong
# Error: not found

# 4. Ver endpoints del Ingress
kubectl get ingress app-ingress -o yaml | grep -A 10 status

# 5. Test con curl (si tienes LoadBalancer IP)
INGRESS_IP=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -H "Host: myapp.example.com" http://$INGRESS_IP
# 503 Service Temporarily Unavailable
```

</details>

<details>
<summary>Solucion</summary>

```bash
# Corregir nombre del service en Ingress
kubectl edit ingress app-ingress
# Cambiar:
#   backend:
#     service:
#       name: app-service-wrong
# Por:
#   backend:
#     service:
#       name: app-service

# O con patch
kubectl patch ingress app-ingress --type='json' -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/name", "value":"app-service"}]'

# Verificar
kubectl describe ingress app-ingress
# No debe haber errores en Events

# Test
INGRESS_IP=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -H "Host: myapp.example.com" http://$INGRESS_IP
# Debe mostrar pagina de nginx
```

**Troubleshooting adicional del Ingress Controller**:
```bash
# Ver logs del controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Verificar configuracion generada por el controller
kubectl exec -n ingress-nginx <ingress-controller-pod> -- cat /etc/nginx/nginx.conf | grep -A 20 myapp.example.com
```

</details>

---

## Escenario 8: Pod-to-Pod Communication Failure

**Situacion**: Pods no pueden comunicarse entre si por IP.

**Setup**:
```bash
kubectl run pod1 --image=nginx
kubectl run pod2 --image=busybox:1.28 -- sleep 3600

# Get IP de pod1
POD1_IP=$(kubectl get pod pod1 -o jsonpath='{.status.podIP}')

# Test desde pod2
kubectl exec pod2 -- wget -T 5 -O- http://$POD1_IP
# Timeout
```

<details>
<summary>Diagnostico</summary>

```bash
# 1. Verificar CNI plugin esta corriendo
kubectl get pods -n kube-system | grep -E "calico|flannel|weave|cilium"

# 2. Ver logs de CNI
kubectl logs -n kube-system -l k8s-app=calico-node  # o el CNI que uses

# 3. Verificar Network Policies
kubectl get networkpolicies --all-namespaces

# 4. Verificar routing en los nodes
# SSH a un node
ip route
# Debe haber rutas para los pod CIDR ranges

# 5. Verificar kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy | tail -50

# 6. Test basico de conectividad
kubectl exec pod2 -- ping -c 3 $POD1_IP
```

</details>

<details>
<summary>Solucion segun causa</summary>

**Causa 1: CNI plugin no esta corriendo**
```bash
# Reinstalar CNI (ejemplo: Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Esperar a que los pods esten Ready
kubectl get pods -n kube-system -l k8s-app=calico-node -w
```

**Causa 2: Network Policy bloqueando**
```bash
# Temporalmente eliminar todas las policies
kubectl delete networkpolicies --all

# Test
kubectl exec pod2 -- wget -T 5 -O- http://$POD1_IP
```

**Causa 3: kube-proxy con problemas**
```bash
# Recrear kube-proxy pods
kubectl delete pods -n kube-system -l k8s-app=kube-proxy

# Verificar logs despues de recrear
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

</details>

---

## Limpieza

```bash
bash cleanup.sh
```

O manualmente:
```bash
# Eliminar recursos de prueba
kubectl delete pod test-dns nginx-test test web-pod frontend backend app-pod pod1 pod2 writer-pod --ignore-not-found
kubectl delete svc web-service nginx-test app-service --ignore-not-found
kubectl delete networkpolicy deny-all allow-frontend-to-backend allow-frontend-egress --ignore-not-found
kubectl delete pvc my-pvc data-web-0 data-web-1 --ignore-not-found
kubectl delete statefulset web --ignore-not-found
kubectl delete ingress app-ingress --ignore-not-found
```

---

## Evaluacion

- [ ] Escenario 1: DNS troubleshooting completado
- [ ] Escenario 2: Service endpoints resuelto
- [ ] Escenario 3: Network Policy diagnosticado
- [ ] Escenario 4: PVC Pending resuelto
- [ ] Escenario 5: StatefulSet storage resuelto
- [ ] Escenario 6: Volume permissions corregido
- [ ] Escenario 7: Ingress reparado
- [ ] Escenario 8: Pod comunicacion resuelta

---

## Comandos Criticos para CKA

### DNS
```bash
# Test DNS
kubectl run test-dns --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
kubectl logs -n kube-system -l k8s-app=kube-dns
kubectl get cm -n kube-system coredns -o yaml
```

### Networking
```bash
# Services & Endpoints
kubectl get svc,endpoints
kubectl describe svc <name>

# Network Policies
kubectl get networkpolicies
kubectl describe networkpolicy <name>
```

### Storage
```bash
# PV/PVC
kubectl get pv,pvc
kubectl describe pvc <name>

# StorageClasses
kubectl get sc
```

---

## Tips para el Examen

1. **DNS siempre primero**: Si hay problemas de conectividad, verifica DNS
2. **Endpoints = conexion Service-Pod**: Si esta vacio, el selector esta mal
3. **Network Policies**: Recuerda que son whitelist, por defecto permiten todo
4. **PVC Pending**: Busca StorageClass, capacidad, access modes
5. **StatefulSets**: Los PVCs se crean automaticamente, uno por replica
6. **Permisos de volumes**: fsGroup y initContainers son tus amigos

---

**Tiempo objetivo**: 8-12 minutos por escenario
**Siguiente**: [Lab 04 - Complete Cluster](../lab-04-complete-cluster/README.md)
