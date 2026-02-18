# Configuración y Prerequisitos - Lab 01: RBAC Básico

## Índice
1. [Requisitos de Hardware](#requisitos-de-hardware)
2. [Software Necesario](#software-necesario)
3. [Configuración del Cluster](#configuración-del-cluster)
4. [Validación de Prerequisites](#validación-de-prerequisites)

---

## 1. Requisitos de Hardware

### Cluster Kubernetes

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| **Tipo de Cluster** | Minikube local | Cluster multi-nodo |
| **CPU** | 2 cores | 4 cores |
| **RAM** | 2 GB | 4 GB |
| **Disco** | 10 GB | 20 GB |
| **Nodos** | 1 (all-in-one) | 1 control plane + 1 worker |

### Máquina Local (para gestión)

- **CPU**: 2 cores
- **RAM**: 2 GB disponible
- **Disco**: 5 GB para herramientas
- **SO**: Linux, macOS, o Windows (con WSL2)

---

## 2. Software Necesario

### 2.1 Kubernetes Cluster

Opciones válidas para este laboratorio:

**Opción A: Minikube (recomendado para práctica)**
```bash
# Instalar minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Iniciar cluster
minikube start --cpus=2 --memory=2048
```

**Opción B: AKS (Azure Kubernetes Service)**
```bash
# Crear cluster AKS
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 1 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Obtener credenciales
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

**Opción C: Cluster existente**
- Asegúrate de tener acceso como administrador
- Contexto kubectl configurado correctamente

### 2.2 kubectl

Versión mínima: **v1.24+**

```bash
# Instalar kubectl (Linux)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verificar instalación
kubectl version --client
```

### 2.3 OpenSSL

Necesario para generar certificados de usuario.

```bash
# Verificar si está instalado
openssl version

# Si no está instalado:
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y openssl

# CentOS/RHEL
sudo yum install -y openssl

# macOS (viene preinstalado)
brew install openssl  # Si necesitas actualizar
```

### 2.4 Herramientas Opcionales (recomendadas)

**kubectx/kubens** - Para cambiar contextos fácilmente
```bash
# Instalar kubectx
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

**jq** - Para procesar JSON
```bash
sudo apt-get install -y jq  # Ubuntu/Debian
sudo yum install -y jq      # CentOS/RHEL
```

---

## 3. Configuración del Cluster

### 3.1 Verificar Acceso Administrativo

Debes tener permisos completos en el cluster:

```bash
# Verificar contexto actual
kubectl config current-context

# Verificar permisos de administrador
kubectl auth can-i create clusterroles
# Debe devolver: yes

kubectl auth can-i create namespaces
# Debe devolver: yes

kubectl auth can-i '*' '*' --all-namespaces
# Debe devolver: yes
```

Si alguno devuelve `no`, necesitas configurar un contexto con privilegios administrativos.

### 3.2 Configurar Directorio de Trabajo

```bash
# Crear directorio para este laboratorio
mkdir -p ~/k8s-rbac-lab01
cd ~/k8s-rbac-lab01

# Crear subdirectorios
mkdir -p certs configs scripts
```

**Estructura esperada:**
```
~/k8s-rbac-lab01/
├── certs/          # Certificados de usuarios
├── configs/        # Archivos kubeconfig
└── scripts/        # Scripts de automatización
```

### 3.3 Variables de Entorno

Configura estas variables para facilitar el laboratorio:

```bash
# En ~/.bashrc o ~/.zshrc
export RBAC_LAB_DIR=~/k8s-rbac-lab01
export RBAC_USER=maria
export RBAC_NAMESPACE=development

# Aplicar cambios
source ~/.bashrc  # o source ~/.zshrc
```

---

## 4. Validación de Prerequisites

### Script de Validación Automática

Ejecuta este script para verificar que todo está configurado:

```bash
#!/bin/bash

echo "=========================================="
echo "  RBAC Lab 01 - Prerequisites Validator"
echo "=========================================="
echo

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

ERRORS=0

# 1. kubectl
echo -n "Verificando kubectl... "
if command -v kubectl &>/dev/null; then
    VERSION=$(kubectl version --client --short 2>/dev/null | grep -oE '[0-9]+\.[0-9]+')
    echo -e "${GREEN}✓ Instalado (v${VERSION})${NC}"
else
    echo -e "${RED}✗ No instalado${NC}"
    ((ERRORS++))
fi

# 2. openssl
echo -n "Verificando openssl... "
if command -v openssl &>/dev/null; then
    VERSION=$(openssl version | awk '{print $2}')
    echo -e "${GREEN}✓ Instalado (${VERSION})${NC}"
else
    echo -e "${RED}✗ No instalado${NC}"
    ((ERRORS++))
fi

# 3. Cluster connectivity
echo -n "Verificando cluster... "
if kubectl cluster-info &>/dev/null; then
    echo -e "${GREEN}✓ Conectado${NC}"
else
    echo -e "${RED}✗ No conectado${NC}"
    ((ERRORS++))
fi

# 4. Admin permissions
echo -n "Verificando permisos admin... "
if kubectl auth can-i create clusterroles &>/dev/null; then
    echo -e "${GREEN}✓ Permisos OK${NC}"
else
    echo -e "${RED}✗ Sin permisos administrativos${NC}"
    ((ERRORS++))
fi

# 5. jq (opcional)
echo -n "Verificando jq (opcional)... "
if command -v jq &>/dev/null; then
    echo -e "${GREEN}✓ Instalado${NC}"
else
    echo -e "${NC}⚠ No instalado (opcional)${NC}"
fi

echo
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Todos los prerequisites OK${NC}"
    echo "Puedes continuar con el laboratorio."
    exit 0
else
    echo -e "${RED}✗ $ERRORS errores encontrados${NC}"
    echo "Corrige los problemas antes de continuar."
    exit 1
fi
```

Guarda el script como `validate-prerequisites.sh` y ejecútalo:

```bash
chmod +x validate-prerequisites.sh
./validate-prerequisites.sh
```

**Salida esperada:**
```
==========================================
  RBAC Lab 01 - Prerequisites Validator
==========================================

Verificando kubectl... ✓ Instalado (v1.28)
Verificando openssl... ✓ Instalado (1.1.1)
Verificando cluster... ✓ Conectado
Verificando permisos admin... ✓ Permisos OK
Verificando jq (opcional)... ✓ Instalado

==========================================
✓ Todos los prerequisites OK
Puedes continuar con el laboratorio.
```

---

## 5. Troubleshooting Prerequisites

### Problema: kubectl no conecta al cluster

**Síntomas:**
```
The connection to the server localhost:8080 was refused
```

**Solución:**
```bash
# Verificar que KUBECONFIG está configurado
echo $KUBECONFIG

# Si está vacío, configurar
export KUBECONFIG=~/.kube/config

# Verificar contenido
kubectl config view

# Si no hay contextos, obtener credenciales del cluster
# Para minikube:
minikube update-context

# Para AKS:
az aks get-credentials --resource-group <RG> --name <CLUSTER>
```

### Problema: No tengo permisos administrativos

**Síntomas:**
```bash
kubectl auth can-i create clusterroles
# Devuelve: no
```

**Solución:**
```bash
# Verificar que estás usando el contexto correcto
kubectl config get-contexts

# Cambiar a contexto administrativo
kubectl config use-context <admin-context>

# Para minikube (siempre es admin):
kubectl config use-context minikube

# Para AKS, verificar que tu usuario Azure tiene rol "Owner" o "Contributor"
```

### Problema: OpenSSL no genera certificados correctamente

**Síntomas:**
```
unable to load certificate
```

**Solución:**
```bash
# Verificar versión de OpenSSL
openssl version

# Debe ser 1.1.1 o superior
# Si es muy antigua, actualizar:
sudo apt-get update && sudo apt-get upgrade openssl
```

---

## 6. Información Adicional

### Versiones de Software Validadas

Este laboratorio ha sido probado con:

| Software | Versión |
|----------|---------|
| Kubernetes | 1.24 - 1.28 |
| kubectl | 1.24+ |
| OpenSSL | 1.1.1+ |
| Minikube | 1.30+ |

### Tiempo Estimado por Sección

| Sección | Tiempo |
|---------|--------|
| Instalación de prerequisites | 10-15 min |
| Configuración del cluster | 5 min |
| Validación | 2-3 min |
| **TOTAL** | **17-23 min** |

### Recursos Adicionales

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [OpenSSL Certificate Authority](https://jamielinux.com/docs/openssl-certificate-authority/)

---

## ✅ Checklist Final de Prerequisites

Antes de comenzar el laboratorio, verifica:

- [ ] kubectl instalado y funcionando
- [ ] openssl instalado
- [ ] Cluster Kubernetes accesible
- [ ] Permisos administrativos verificados
- [ ] Directorio de trabajo creado (`~/k8s-rbac-lab01`)
- [ ] Script de validación ejecutado exitosamente

**Si todos los items están marcados, estás listo para comenzar el laboratorio principal.**

---

[⬅ Volver al README principal](./README.md)
