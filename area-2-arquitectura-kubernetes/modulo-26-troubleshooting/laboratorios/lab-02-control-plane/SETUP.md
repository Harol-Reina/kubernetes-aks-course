# SETUP - Lab 02: Control Plane & Worker Nodes Troubleshooting

## Requisitos Previos

- Cluster con acceso a control plane (Minikube, kubeadm, o kind)
- Acceso SSH a los nodes (si aplica)
- Permisos sudo en los nodes
- Familiaridad con systemd (journalctl, systemctl)

> **Importante:** Este laboratorio requiere acceso al sistema operativo de los nodos.
> Para Minikube usa `minikube ssh`, para kind usa `docker exec -it <container> bash`.

## Verificacion del Entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar acceso a components del sistema
kubectl get pods -n kube-system

# Para Minikube: verificar acceso SSH
minikube ssh "sudo systemctl status kubelet"

# Verificar archivos YAML del laboratorio
ls *.yaml
```

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `scenario-08-staticpod-setup.yaml` | Static pod con tag de imagen invalido para diagnostico |
| `etcd-backup.sh` | Script para backup de etcd |
| `cleanup.sh` | Script de limpieza de recursos del lab |

## Modo de Uso

```bash
# Los escenarios 1-7 son diagnosticos interactivos (ver README.md)
# Solo el escenario 8 requiere copiar un archivo YAML:

# Escenario 8: Copiar static pod con error
sudo cp scenario-08-staticpod-setup.yaml /etc/kubernetes/manifests/static-web.yaml

# Al finalizar, limpiar todo
./cleanup.sh
```

## Advertencia

> **NO ejecutes estos escenarios en produccion.** Los escenarios de este lab
> simulan fallos de componentes criticos. Solo usalos en entornos de prueba.
