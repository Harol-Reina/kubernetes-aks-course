# Ejemplo 08: Pod con ServiceAccount Personalizado

## 🎯 Objetivo
Pod usando SA custom con permisos específicos via Role/RoleBinding.

## 🚀 Uso
```bash
kubectl apply -f 08-pod-custom-sa.yaml
kubectl exec pod-custom-sa -- wget -qO- http://kubernetes.default.svc/api/v1/namespaces/default/pods
```

## 📊 Qué demuestra
- ServiceAccount custom
- Role con permisos limitados (pods en namespace)
- RoleBinding vinculando SA con Role
- Pod usando el SA custom

## 🧹 Limpieza
```bash
./cleanup.sh
```

[Volver a ejemplos](../README.md)
