# Ejemplo 10: Pod con Acceso a API

## 🎯 Objetivo
Pod que accede a la API de Kubernetes usando su ServiceAccount.

## 🚀 Uso
```bash
kubectl apply -f 10-pod-api-access.yaml
kubectl logs api-access-pod
kubectl exec api-access-pod -- env | grep KUBERNETES
```

## 📊 Qué demuestra
- ServiceAccount con permisos de API
- Variables de entorno de Kubernetes en pod
- Acceso programático a API desde pod
- Token montado y usado automáticamente

## 🧹 Limpieza
```bash
./cleanup.sh
```

[Volver a ejemplos](../README.md)
