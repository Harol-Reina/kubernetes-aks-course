# Ejemplo 04: Pod con ServiceAccount

## 🎯 Objetivo
Demostrar cómo asignar un ServiceAccount específico a un pod.

## 🚀 Uso
```bash
kubectl apply -f 04-pod-con-serviceaccount.yaml
kubectl get pod nginx-with-sa
kubectl exec nginx-with-sa -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

## 📊 Qué demuestra
- Campo `serviceAccountName` en spec de pod
- Token montado automáticamente en /var/run/secrets
- Identidad del pod controlada por SA

## 🧹 Limpieza
```bash
./cleanup.sh
```

[Volver a ejemplos](../README.md)
