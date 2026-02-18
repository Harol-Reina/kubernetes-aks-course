# Ejemplo 03: ServiceAccounts por Ambiente

## 🎯 Objetivo
Crear ServiceAccounts separados para diferentes ambientes (dev, staging, prod).

## 🚀 Uso
```bash
kubectl apply -f 03-serviceaccounts-por-ambiente.yaml
kubectl get sa -l environment
kubectl get sa -l environment=production
```

## 📊 Qué demuestra
- Múltiples ServiceAccounts en un archivo
- Labels para organizar por ambiente
- Segregación de identidades

## 🧹 Limpieza
```bash
./cleanup.sh
```

[Volver a ejemplos](../README.md)
