# Ejemplos de Servicios en Kubernetes

Este directorio contiene ejemplos completos de diferentes tipos de Services en Kubernetes.

## Archivos Disponibles

1. **services-examples.yaml** - Todos los tipos de services
2. **network-policies.yaml** - Políticas de red
3. **ingress-examples.yaml** - Configuraciones de Ingress
4. **dns-config.yaml** - Configuración de DNS personalizado
5. **complete-app.yaml** - Aplicación completa con networking

## Quick Start

```bash
# Aplicar ejemplos de services
kubectl apply -f services-examples.yaml

# Aplicar network policies
kubectl apply -f network-policies.yaml

# Aplicar ingress
kubectl apply -f ingress-examples.yaml

# Ver todos los recursos creados
kubectl get svc,pods,networkpolicies,ingress
```

## Testing

```bash
# Test ClusterIP service
kubectl run test --rm -it --image=busybox -- wget -O- http://backend-clusterip:8080

# Test NodePort service (desde fuera del cluster)
curl http://<node-ip>:30080

# Test DNS
kubectl run dnsutils --rm -it \
  --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 \
  -- nslookup backend-clusterip

# Test Network Policy
kubectl exec -it frontend-pod -- curl backend-service:8080
```

## Limpieza

```bash
# Eliminar todos los ejemplos
kubectl delete -f services-examples.yaml
kubectl delete -f network-policies.yaml
kubectl delete -f ingress-examples.yaml
```
