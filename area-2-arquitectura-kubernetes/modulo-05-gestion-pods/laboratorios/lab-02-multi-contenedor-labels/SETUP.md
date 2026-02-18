# Setup - Lab 02: Multi-contenedor y Labels

## 📋 Prerequisitos

### Conocimientos Requeridos
- ✅ Creación básica de pods (Lab 01 completado)
- ✅ Comprensión de múltiples contenedores por pod
- ✅ Concepto de labels y selectors
- ✅ Patrones sidecar y ambassador

### Herramientas Necesarias
- ✅ `kubectl` instalado y configurado
- ✅ Cluster de Kubernetes funcional
- ✅ Permisos para crear pods y services
- ✅ `curl` o similar para probar conectividad

### Verificación del Entorno

```bash
# Verificar conexión al cluster
kubectl cluster-info

# Verificar permisos
kubectl auth can-i create pods
kubectl auth can-i create services
kubectl auth can-i get pods --all-namespaces

# Verificar que no hay conflictos de nombres
kubectl get pods -l app=multi-pod 2>/dev/null && echo "⚠️ Pods existentes - ejecutar cleanup.sh" || echo "✅ Listo"
```

## 🎯 Estado Inicial del Cluster

- Cluster con al menos 1 nodo funcional
- Sin pods con labels `app=multi-pod` o `tier=frontend`
- Namespace `default` disponible

## 📦 Imágenes Requeridas

Este lab utiliza estas imágenes (serán descargadas automáticamente):

- `nginx:alpine` - Servidor web
- `busybox` - Utilidades Unix
- `redis:alpine` - Cache/base de datos
- `alpine/curl` - Cliente HTTP

**Tip**: Pre-descargar para acelerar el lab:

```bash
# Pre-pull de imágenes (opcional)
docker pull nginx:alpine
docker pull busybox
docker pull redis:alpine
docker pull alpine/curl
```

## ⚙️ Configuración Opcional

Namespace dedicado (recomendado):

```bash
# Crear namespace para el lab
kubectl create namespace lab-multi-container

# Configurar como namespace por defecto
kubectl config set-context --current --namespace=lab-multi-container
```

## ✅ Validación de Setup

```bash
# Test rápido de multi-contenedor
kubectl run test-multi \
  --image=nginx:alpine \
  --dry-run=client -o yaml | \
  kubectl set image pod/test-multi nginx=nginx:alpine \
  --dry-run=client -o yaml

# Si funciona:
echo "✅ Setup completo - puedes iniciar el lab"
```

## 🧹 Limpieza Previa

```bash
# Limpiar pods de labs anteriores
kubectl delete pod -l lab=gestion-pods
kubectl delete svc -l lab=gestion-pods

# O usar script de limpieza
./cleanup.sh
```

## 📚 Recursos de Referencia

- [Multi-container Pod Patterns](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

---

**¿Todo listo?** Procede con [README.md](./README.md) para comenzar el laboratorio.
