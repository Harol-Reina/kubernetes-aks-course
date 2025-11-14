# Setup - Lab 01: Crear Pods

## 📋 Prerequisitos

### Conocimientos Requeridos
- ✅ Conceptos básicos de Kubernetes (Módulo 01)
- ✅ Comprensión de contenedores Docker
- ✅ Sintaxis básica de YAML
- ✅ Conceptos de pods del Módulo 04

### Herramientas Necesarias
- ✅ `kubectl` instalado y configurado
- ✅ Cluster de Kubernetes funcional (Minikube, Kind, o AKS)
- ✅ Acceso al namespace `default` o permisos para crear namespaces

### Verificación del Entorno

```bash
# Verificar conexión al cluster
kubectl cluster-info

# Verificar versión de kubectl
kubectl version --client

# Verificar nodos disponibles
kubectl get nodes

# Verificar que puedes crear pods
kubectl auth can-i create pods
```

**Salida esperada**: Todos los comandos deben ejecutarse sin errores.

## 🎯 Estado Inicial del Cluster

- Cluster limpio sin pods de prueba anteriores
- Namespace `default` disponible
- Sin límites de recursos que bloqueen creación de pods

## ⚙️ Configuración Opcional

Si quieres trabajar en un namespace dedicado:

```bash
# Crear namespace para el lab
kubectl create namespace lab-pods

# Configurar como namespace por defecto
kubectl config set-context --current --namespace=lab-pods
```

## ✅ Validación de Setup

Ejecuta este comando para verificar que todo está listo:

```bash
# Crear pod de prueba
kubectl run test-setup --image=nginx:alpine --dry-run=client -o yaml

# Si el comando anterior funciona, estás listo
echo "✅ Setup completo - puedes iniciar el lab"
```

## 🧹 Limpieza Previa

Si has ejecutado este lab anteriormente:

```bash
# Limpiar pods previos
kubectl delete pod --all -n default

# O usar el script de limpieza
cd /path/to/lab-01-crear-pods
./cleanup.sh
```

---

**¿Todo listo?** Procede con [README.md](./README.md) para comenzar el laboratorio.
