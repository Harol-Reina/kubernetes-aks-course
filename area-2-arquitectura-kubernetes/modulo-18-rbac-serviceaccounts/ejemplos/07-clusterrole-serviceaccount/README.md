# Ejemplo 07: ClusterRole con ServiceAccount

## 🎯 Objetivo
Vincular un ServiceAccount con un ClusterRole para permisos a nivel cluster.

## 🚀 Uso
```bash
kubectl apply -f 07-clusterrole-serviceaccount.yaml
kubectl get clusterrole pod-reader
kubectl get clusterrolebinding read-pods-global
kubectl auth can-i list pods --as=system:serviceaccount:default:pod-reader-sa
```

## 📊 Qué demuestra
- ClusterRole con permisos de lectura de pods
- ClusterRoleBinding vinculando SA con ClusterRole
- Permisos a nivel cluster (todos los namespaces)

## 🧹 Limpieza
```bash
./cleanup.sh
```

[Volver a ejemplos](../README.md)
