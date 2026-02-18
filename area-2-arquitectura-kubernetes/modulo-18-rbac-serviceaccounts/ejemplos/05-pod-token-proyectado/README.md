# Ejemplo 05: Pod con Token Proyectado

## 🎯 Objetivo
Usar token proyectado con expiración y audiencia específica (feature moderna de K8s).

## 🚀 Uso
```bash
kubectl apply -f 05-pod-token-proyectado.yaml
kubectl exec pod-token-proyectado -- cat /var/run/secrets/tokens/api-token
kubectl exec pod-token-proyectado -- ls -la /var/run/secrets/tokens/
```

## 📊 Qué demuestra
- Projected volumes con token ServiceAccount
- Expiración de token (3600s)
- Audiencia específica para el token
- Mayor seguridad vs token estático

## 🧹 Limpieza
```bash
./cleanup.sh
```

[Volver a ejemplos](../README.md)
