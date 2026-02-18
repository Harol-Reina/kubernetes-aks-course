# Ejemplo 02: ServiceAccount Básico

## 🎯 Objetivo
Crear un ServiceAccount mínimo con configuración por defecto.

## 🚀 Uso
```bash
kubectl apply -f 02-serviceaccount-basico.yaml
kubectl get sa mi-app-sa
kubectl describe sa mi-app-sa
```

## 📊 Qué demuestra
- ServiceAccount con configuración mínima
- Token automático generado por defecto
- Listo para usar en pods

## 🧹 Limpieza
```bash
./cleanup.sh
```

[Volver a ejemplos](../README.md)
