# SETUP - Lab 04: Troubleshooting de Networking

## Requisitos Previos

- Cluster Kubernetes funcional (Minikube recomendado)
- kubectl configurado y conectado al cluster
- `curl` instalado en el sistema host para pruebas de conectividad
- Conocimientos basicos de networking (TCP/IP, DNS, puertos)

> Este laboratorio usa la configuracion por defecto de Minikube.
> No requiere CNI especifico ni herramientas adicionales instaladas en los nodos,
> ya que las herramientas de red se proveen a traves del Pod netshoot.

## Verificacion del Entorno

```bash
# Verificar que el cluster esta activo
kubectl cluster-info

# Verificar nodos disponibles
kubectl get nodes

# Verificar que CoreDNS esta corriendo (necesario para ejercicios de DNS)
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Verificar acceso a crear Pods
kubectl run verify-access --image=nginx --restart=Never && \
  kubectl delete pod verify-access --ignore-not-found
```

**Salida esperada de CoreDNS:**
```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-xxx-yyy            1/1     Running   0          Xd
```

## Recursos del Sistema Recomendados

| Recurso | Minimo | Recomendado |
|---------|--------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disco | 20 GB | 40 GB |

## Archivos del Laboratorio

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `broken-app-service.yaml` | Problema 1 | Deployment nginx + Service con targetPort: 8080 incorrecto |
| `backend-label-mismatch.yaml` | Problema 2 | Deployment backend-app + Service con selector incorrecto |
| `netshoot-pod.yaml` | Ejercicio 3.1 | Pod de diagnostico con nicolaka/netshoot |

## Limpieza

```bash
./cleanup.sh
```
