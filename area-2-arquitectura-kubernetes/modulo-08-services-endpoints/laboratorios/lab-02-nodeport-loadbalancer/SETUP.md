# Prerequisitos - Lab 02: NodePort y LoadBalancer

## Conocimientos Previos

- Laboratorio 01 (ClusterIP Basics) completado
- Conceptos de Services ClusterIP y Endpoints
- Familiaridad con `kubectl apply` y manifiestos YAML

## Herramientas Necesarias

- Minikube, kind, k3s o cluster Kubernetes funcional
- kubectl configurado y conectado al cluster
- (Opcional) Cluster en cloud (AWS EKS, GCP GKE, Azure AKS) para LoadBalancer
- Dos terminales disponibles (para monitoring simultaneo)

## Verificacion del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar nodos con IPs
kubectl get nodes -o wide

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 6 archivos YAML documentados.
Cada archivo incluye:

- Comentario de uso (`# Uso: kubectl apply -f ...`)
- Descripcion de lo que hace el manifiesto
- Explicacion de los conceptos clave

| Archivo | Descripcion |
|---------|-------------|
| `webapp-deployment.yaml` | Deployment con 3 replicas que muestra Pod + Node |
| `webapp-nodeport-auto.yaml` | NodePort con puerto auto-asignado |
| `webapp-nodeport-custom.yaml` | NodePort con puerto fijo 30080 |
| `webapp-cluster-policy.yaml` | NodePort con externalTrafficPolicy: Cluster |
| `webapp-local-policy.yaml` | NodePort con externalTrafficPolicy: Local |
| `webapp-loadbalancer.yaml` | LoadBalancer para cloud |
| `compare-policies.sh` | Script comparacion Cluster vs Local |
| `comparison-table.sh` | Tabla comparativa de tipos de Service |
| `cleanup.sh` | Script de limpieza |
