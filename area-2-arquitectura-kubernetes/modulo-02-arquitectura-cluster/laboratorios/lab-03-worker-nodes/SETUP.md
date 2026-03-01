# SETUP - Lab 03: Worker Nodes

## Requisitos Previos

- Cluster Kubernetes funcional (Minikube recomendado)
- kubectl configurado y conectado al cluster
- Plugin CNI compatible con NetworkPolicy (Calico recomendado)
- `crictl` instalado en los nodos para interactuar con el container runtime
- `kubectl top` requiere metrics-server instalado

> **IMPORTANTE:** Las NetworkPolicies (Parte 4) requieren un CNI que las soporte.
> Minikube con el addon CNI de Calico funciona correctamente.
> El CNI por defecto de Minikube NO soporta NetworkPolicies.

## Instalacion de Dependencias

```bash
# Habilitar Calico en Minikube (si se usa Minikube)
minikube start --cni=calico

# Habilitar metrics-server en Minikube (para kubectl top)
minikube addons enable metrics-server

# Verificar metrics-server
kubectl get pods -n kube-system -l k8s-app=metrics-server
```

## Verificacion del Entorno

```bash
# Verificar que el cluster esta activo
kubectl cluster-info

# Verificar nodos disponibles
kubectl get nodes

# Verificar que los componentes del sistema estan corriendo
kubectl get pods -n kube-system

# Verificar que NetworkPolicies estan soportadas (debe devolver resultado vacio, no error)
kubectl get networkpolicies

# Verificar metrics-server (puede tardar 1-2 minutos)
kubectl top nodes
```

**Salida esperada de `kubectl top nodes`:**
```
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   XXXm         XX%    XXXXMi          XX%
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
| `unhealthy-pod.yaml` | Ejercicio 1.2 | Pod con livenessProbe que falla (ruta inexistente) |
| `high-cpu-pod.yaml` | Ejercicio 1.3 | Pod con stress para consumo de CPU con resource limits |
| `memory-hog-pod.yaml` | Ejercicio 1.4 | Pod que consume memoria para demostrar eviction |
| `multi-container-pod.yaml` | Ejercicio 2.1 | Pod multi-contenedor para crictl inspection |
| `guaranteed-pod.yaml` | Ejercicio 2.2 | Pod con QoS Guaranteed (requests == limits) |
| `external-db-service.yaml` | Ejercicio 3.2 | Service + Endpoints para base de datos externa |
| `netpol-deny-all.yaml` | Ejercicio 4.1 | NetworkPolicy deny-all para el namespace default |
| `netpol-allow-frontend.yaml` | Ejercicio 4.2 | NetworkPolicy que permite trafico solo desde frontend |

## Limpieza

```bash
./cleanup.sh
```
