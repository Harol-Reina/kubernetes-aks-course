# Setup - Lab 01: Helm Basics

## 📋 Prerequisitos

### Conocimientos Requeridos
- ✅ Conceptos de Kubernetes (Pods, Deployments, Services)
- ✅ Manifiesto YAML de Kubernetes
- ✅ Conceptos básicos de package managers
- ✅ Línea de comandos

### Herramientas Necesarias
- ✅ `kubectl` instalado y configurado
- ✅ `helm` v3.x instalado
- ✅ Cluster de Kubernetes funcional
- ✅ Conexión a internet (para descargar charts)

### Verificación del Entorno

```bash
# Verificar Helm instalado
helm version

# Verificar conexión a cluster
kubectl cluster-info

# Verificar permisos
kubectl auth can-i create deployments
kubectl auth can-i create services

# Agregar repositorio Helm (si no existe)
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

**Salida esperada de helm version**:
```
version.BuildInfo{Version:"v3.x.x", ...}
```

## 🎯 Instalación de Helm

Si Helm no está instalado:

### Linux/macOS
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Windows (PowerShell)
```powershell
choco install kubernetes-helm
```

### Verificar instalación
```bash
helm version --short
helm repo list
```

## 🧹 Limpieza Previa

```bash
# Eliminar releases anteriores del lab
helm list
helm uninstall mi-nginx 2>/dev/null || echo "No releases previos"

# Limpiar namespace
kubectl delete namespace helm-lab 2>/dev/null || echo "Namespace no existe"
```

## ✅ Validación de Setup

```bash
# Test de repositorios
helm search repo nginx | head -5

# Test de dry-run
helm install test-release bitnami/nginx --dry-run

# Si ambos funcionan:
echo "✅ Setup completo - puedes iniciar el lab"
```

## 📦 Repositorios Recomendados

```bash
# Repositorios oficiales
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami

# Actualizar
helm repo update

# Listar charts disponibles
helm search repo bitnami | head -10
```

---

**¿Todo listo?** Procede con [README.md](./README.md) para comenzar el laboratorio.
