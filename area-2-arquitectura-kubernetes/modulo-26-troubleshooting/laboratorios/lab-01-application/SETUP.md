# SETUP - Lab 01: Application Troubleshooting

## Requisitos Previos

- Cluster Kubernetes funcional (Minikube, kind, k3s, o cloud)
- kubectl configurado y conectado al cluster
- Conocimientos basicos de Pods, Deployments, Services y ConfigMaps

> Este laboratorio funciona con la configuracion por defecto de Minikube.

## Verificacion del Entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar que puedes crear recursos
kubectl auth can-i create deployments
kubectl auth can-i create pods

# Verificar archivos YAML del laboratorio
ls *.yaml
```

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `scenario-01-crashloop-setup.yaml` | Deployment con error de configuracion nginx (CrashLoopBackOff) |
| `scenario-01-crashloop-fix.yaml` | Deployment corregido sin args incorrectos |
| `scenario-02-imagepull-setup.yaml` | Deployment con tag de imagen inexistente (ImagePullBackOff) |
| `scenario-03-oomkilled-setup.yaml` | Pod con memory limits insuficientes (OOMKilled) |
| `scenario-03-oomkilled-fix.yaml` | Pod con memory limits corregidos |
| `scenario-04-initcontainer-setup.yaml` | Pod con init container esperando servicio inexistente |
| `scenario-04-initcontainer-fix.yaml` | Pod sin init container bloqueante |
| `scenario-05-liveness-setup.yaml` | Pod con liveness probe apuntando a path invalido |
| `scenario-05-liveness-fix.yaml` | Pod con liveness probe corregido |
| `scenario-06-configmap-setup.yaml` | Deployment referenciando ConfigMap inexistente |
| `scenario-06-configmap-fix.yaml` | ConfigMap app-settings requerido |
| `scenario-07-readiness-setup.yaml` | Pod + Service con readiness probe en puerto incorrecto |
| `scenario-07-readiness-fix.yaml` | Pod con readiness probe corregido |
| `scenario-08-portmismatch-setup.yaml` | Pod + Service con targetPort incorrecto |
| `scenario-08-portmismatch-fix.yaml` | Service con targetPort corregido |
| `cleanup.sh` | Script de limpieza de todos los recursos |

## Modo de Uso

```bash
# Aplicar escenario con error
kubectl apply -f scenario-01-crashloop-setup.yaml

# Diagnosticar el problema (ver README.md)
# ...

# Aplicar la correccion (cuando sea necesario)
kubectl apply -f scenario-01-crashloop-fix.yaml

# Al finalizar, limpiar todo
./cleanup.sh
```
