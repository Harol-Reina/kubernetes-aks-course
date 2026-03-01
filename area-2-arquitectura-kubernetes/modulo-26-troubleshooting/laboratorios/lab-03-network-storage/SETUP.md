# SETUP - Lab 03: Network & Storage Troubleshooting

## Requisitos Previos

- Cluster Kubernetes funcional (Minikube recomendado)
- kubectl configurado y conectado al cluster
- Conocimientos de Services, DNS, Network Policies y PersistentVolumes

## Requisitos Minikube

> **Importante:** Este laboratorio requiere la siguiente configuracion en Minikube.

### Addons necesarios

```bash
# Verificar addons activos
minikube addons list

# Habilitar Ingress Controller (para Escenario 7)
minikube addons enable ingress

# Habilitar storage-provisioner (habilitado por defecto)
minikube addons enable storage-provisioner
```

> **Minikube:** Para que las Network Policies funcionen, necesitas un CNI compatible:
> ```bash
> # Opcion 1: Iniciar Minikube con Calico
> minikube start --cni=calico
>
> # Opcion 2: Si ya tienes Minikube, instalar Calico
> kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
> ```

## Verificacion del Entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar CNI plugin
kubectl get pods -n kube-system | grep -E "calico|flannel|weave|cilium"

# Verificar Ingress Controller
kubectl get pods -n ingress-nginx

# Verificar StorageClass
kubectl get sc

# Verificar archivos YAML del laboratorio
ls *.yaml
```

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `scenario-01-dns-fix-configmap.yaml` | ConfigMap CoreDNS con Corefile correcto |
| `scenario-02-endpoints-setup.yaml` | Pod + Service con label mismatch |
| `scenario-02-endpoints-fix.yaml` | Service con selector corregido |
| `scenario-03-netpol-setup.yaml` | NetworkPolicy deny-all |
| `scenario-03-netpol-fix.yaml` | NetworkPolicies que permiten trafico frontend-backend + DNS |
| `scenario-04-pvc-setup.yaml` | PVC con StorageClass inexistente |
| `scenario-04-pvc-fix-storageclass.yaml` | PVC con StorageClass valido |
| `scenario-04-pvc-fix-manual-pv.yaml` | PV para provisioning manual |
| `scenario-04-pvc-fix-accessmode.yaml` | PVC con access mode corregido |
| `scenario-04-pvc-fix-size.yaml` | PVC con tamano reducido |
| `scenario-05-statefulset-setup.yaml` | StatefulSet con StorageClass invalido |
| `scenario-05-statefulset-fix.yaml` | StatefulSet con StorageClass corregido |
| `scenario-06-volume-setup.yaml` | Pod con permisos de volumen restrictivos |
| `scenario-06-volume-fix-initcontainer.yaml` | Pod con initContainer para fix de permisos |
| `scenario-06-volume-fix-emptydir.yaml` | Pod usando emptyDir (respeta fsGroup) |
| `scenario-07-ingress-setup.yaml` | Pod + Service + Ingress con nombre de service incorrecto |
| `cleanup.sh` | Script de limpieza de todos los recursos |
