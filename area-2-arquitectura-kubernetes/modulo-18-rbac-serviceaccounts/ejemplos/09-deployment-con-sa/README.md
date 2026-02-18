# Ejemplo 09: Deployment con ServiceAccount

## 🎯 Objetivo
Deployment completo usando ServiceAccount con RBAC configurado.

## 🚀 Uso
```bash
kubectl apply -f 09-deployment-con-sa.yaml
kubectl get deployment app-deployment
kubectl get pods -l app=mi-app
kubectl logs -l app=mi-app
```

## 📊 Qué demuestra
- Deployment usando ServiceAccount
- Múltiples replicas con mismo SA
- Role y RoleBinding para permisos
- Configuración production-ready

## 🧹 Limpieza
```bash
./cleanup.sh
```

[Volver a ejemplos](../README.md)
