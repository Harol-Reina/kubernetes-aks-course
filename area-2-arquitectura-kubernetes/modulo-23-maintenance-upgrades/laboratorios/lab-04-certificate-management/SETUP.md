# Lab 04: Certificate Management - Setup

## 📋 Prerequisitos

Este laboratorio requiere acceso al **control plane node** de un cluster de Kubernetes creado con **kubeadm**.

### ⚠️ Restricciones Importantes

1. **Solo funciona con clusters kubeadm**
   - Managed clusters (EKS, GKE, AKS) NO permiten acceso a certificados
   - Minikube puede usarse pero con limitaciones

2. **Acceso SSH al control plane**
   - Necesitas permisos `sudo` en el nodo control plane
   - Acceso al directorio `/etc/kubernetes/pki`

3. **NO ejecutar en producción**
   - Este lab es para aprendizaje
   - Siempre hacer backup antes de renovar certificados

---

## 🔧 Requisitos del Sistema

### Hardware Mínimo

| Componente | Requisito |
|------------|-----------|
| **CPU** | 2 cores |
| **RAM** | 2GB |
| **Disco** | 20GB libres (para backups de PKI) |
| **Red** | Conectividad a API Server |

### Software Requerido

| Software | Versión | Verificación |
|----------|---------|--------------|
| **Kubernetes** | v1.27+ o v1.28+ | `kubectl version` |
| **kubeadm** | v1.27+ o v1.28+ | `kubeadm version` |
| **kubectl** | Matching cluster | `kubectl version --client` |
| **openssl** | 1.1.1+ | `openssl version` |
| **jq** | 1.6+ (opcional) | `jq --version` |

---

## ✅ Verificación de Prerequisitos

### Paso 1: Verificar Tipo de Cluster

```bash
# 1. Verificar que es cluster kubeadm
kubectl get cm -n kube-system kubeadm-config -o yaml

# Si existe el ConfigMap, es cluster kubeadm ✓
# Si no existe, probablemente es managed cluster ✗
```

### Paso 2: Verificar Acceso a PKI

```bash
# 1. Verificar que existe el directorio PKI
ls -la /etc/kubernetes/pki/

# Deberías ver:
# ca.crt
# ca.key
# apiserver.crt
# apiserver.key
# ...

# 2. Verificar permisos (necesitas ser root o usar sudo)
sudo ls -la /etc/kubernetes/pki/

# 3. Verificar acceso a certificados de etcd
sudo ls -la /etc/kubernetes/pki/etcd/
```

### Paso 3: Verificar kubeadm Instalado

```bash
# 1. Verificar kubeadm presente
which kubeadm
# Output: /usr/bin/kubeadm

# 2. Verificar versión
kubeadm version
# Output: kubeadm version: &version.Info{Major:"1", Minor:"28", ...}

# 3. Probar comando de verificación de certs
sudo kubeadm certs check-expiration

# Debería mostrar tabla de certificados ✓
```

### Paso 4: Verificar openssl

```bash
# 1. Verificar openssl instalado
which openssl
# Output: /usr/bin/openssl

# 2. Verificar versión
openssl version
# Output: OpenSSL 1.1.1f  31 Mar 2020 (o superior)

# 3. Probar lectura de certificado
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -subject

# Debería mostrar:
# subject=CN = kube-apiserver
```

### Paso 5: Verificar Conectividad a Cluster

```bash
# 1. Verificar kubectl configurado
kubectl cluster-info

# Output esperado:
# Kubernetes control plane is running at https://...
# CoreDNS is running at https://...

# 2. Verificar acceso
kubectl get nodes

# 3. Verificar permisos admin
kubectl auth can-i "*" "*"
# yes
```

---

## 🛠️ Script de Validación Automática

Crea este script para validar todos los prerequisitos:

```bash
#!/bin/bash
# validate-lab04-setup.sh

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Validación de Prerequisitos - Lab 04 Certificates    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0

# 1. Verificar kubeadm
echo "✓ Verificando kubeadm..."
if command -v kubeadm &> /dev/null; then
    kubeadm version --output=short
else
    echo "✗ kubeadm NO encontrado"
    ((ERRORS++))
fi
echo ""

# 2. Verificar acceso a PKI
echo "✓ Verificando acceso a /etc/kubernetes/pki..."
if sudo test -d /etc/kubernetes/pki; then
    echo "  Directorio PKI existe ✓"
    sudo ls /etc/kubernetes/pki/ | head -5
else
    echo "✗ Directorio PKI NO accesible"
    ((ERRORS++))
fi
echo ""

# 3. Verificar certificados críticos
echo "✓ Verificando certificados críticos..."
for cert in ca.crt apiserver.crt apiserver-kubelet-client.crt; do
    if sudo test -f /etc/kubernetes/pki/$cert; then
        echo "  $cert ✓"
    else
        echo "  $cert ✗"
        ((ERRORS++))
    fi
done
echo ""

# 4. Verificar openssl
echo "✓ Verificando openssl..."
if command -v openssl &> /dev/null; then
    openssl version
else
    echo "✗ openssl NO encontrado"
    ((ERRORS++))
fi
echo ""

# 5. Verificar kubectl
echo "✓ Verificando kubectl..."
if kubectl get nodes &> /dev/null; then
    echo "  kubectl funcional ✓"
    kubectl get nodes --no-headers | wc -l | xargs echo "  Nodos disponibles:"
else
    echo "✗ kubectl NO puede conectar al cluster"
    ((ERRORS++))
fi
echo ""

# 6. Verificar permisos admin
echo "✓ Verificando permisos..."
if kubectl auth can-i "*" "*" &> /dev/null; then
    echo "  Permisos admin: ✓"
else
    echo "✗ Sin permisos admin"
    ((ERRORS++))
fi
echo ""

# 7. Verificar cluster kubeadm
echo "✓ Verificando tipo de cluster..."
if kubectl get cm -n kube-system kubeadm-config &> /dev/null; then
    echo "  Cluster kubeadm: ✓"
else
    echo "⚠ ConfigMap kubeadm-config no encontrado"
    echo "  Este puede NO ser un cluster kubeadm"
    ((ERRORS++))
fi
echo ""

# Resultado final
echo "═════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo "✅ TODOS LOS PREREQUISITOS CUMPLIDOS"
    echo "   Puedes proceder con el laboratorio"
else
    echo "❌ $ERRORS ERROR(ES) ENCONTRADO(S)"
    echo "   Corrige los errores antes de continuar"
fi
echo "═════════════════════════════════════════════════════════"

exit $ERRORS
```

**Uso**:
```bash
chmod +x validate-lab04-setup.sh
./validate-lab04-setup.sh
```

---

## 🔍 Troubleshooting de Setup

### Problema 1: "kubeadm not found"

**Síntoma**:
```bash
kubeadm version
# command not found: kubeadm
```

**Solución**:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y kubeadm

# CentOS/RHEL
sudo yum install -y kubeadm
```

### Problema 2: "Permission denied" en /etc/kubernetes/pki

**Síntoma**:
```bash
ls /etc/kubernetes/pki/
# Permission denied
```

**Solución**:
```bash
# Usar sudo
sudo ls /etc/kubernetes/pki/

# O cambiar al usuario root temporalmente
sudo -i
ls /etc/kubernetes/pki/
exit
```

### Problema 3: Cluster NO es kubeadm (Managed Cluster)

**Síntoma**:
```bash
kubectl get cm -n kube-system kubeadm-config
# Error from server (NotFound): configmaps "kubeadm-config" not found
```

**Diagnóstico**:
```bash
# Verificar provider del cluster
kubectl get nodes -o wide

# Si ves:
# - "eks" en nombres → EKS (AWS)
# - "gke" en nombres → GKE (Google)
# - "aks" en nombres → AKS (Azure)
```

**Solución**:

Este laboratorio **NO funciona en managed clusters**. Opciones:

1. **Opción A**: Crear cluster kubeadm local
   ```bash
   # Usar kubeadm para crear cluster desde cero
   # Ver: M22 Lab 01 - kubeadm init
   ```

2. **Opción B**: Usar minikube
   ```bash
   minikube start --kubernetes-version=v1.28.0
   minikube ssh
   # Dentro del nodo minikube:
   sudo kubeadm certs check-expiration
   ```

3. **Opción C**: Usar VM con kubeadm
   - Crear VM en Azure/AWS/GCP
   - Instalar Kubernetes con kubeadm
   - Ejecutar el lab en esa VM

### Problema 4: openssl NO Instalado

**Síntoma**:
```bash
openssl version
# command not found: openssl
```

**Solución**:
```bash
# Ubuntu/Debian
sudo apt-get install -y openssl

# CentOS/RHEL
sudo yum install -y openssl

# Alpine
apk add openssl
```

### Problema 5: Sin Espacio en Disco para Backups

**Síntoma**:
```bash
df -h /root
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda1        20G   19G  500M  98% /
```

**Solución**:
```bash
# 1. Limpiar logs viejos
sudo journalctl --vacuum-time=7d

# 2. Limpiar cache de apt/yum
sudo apt-get clean  # Ubuntu
sudo yum clean all  # CentOS

# 3. Usar ubicación alternativa para backups
export BACKUP_DIR="/mnt/external/backups"
sudo mkdir -p $BACKUP_DIR
sudo cp -r /etc/kubernetes/pki $BACKUP_DIR/

# 4. Verificar espacio liberado
df -h /
```

---

## 🎯 Configuración del Entorno

### Crear Directorio de Trabajo

```bash
# 1. Crear directorio para el lab
mkdir -p ~/k8s-labs/lab-04-certificates
cd ~/k8s-labs/lab-04-certificates

# 2. Crear subdirectorios
mkdir -p backups logs scripts

# 3. Verificar estructura
tree -L 1
# .
# ├── backups/
# ├── logs/
# └── scripts/
```

### Variables de Entorno Útiles

```bash
# Agregar a ~/.bashrc o ejecutar en la sesión

# Directorio PKI
export PKI_DIR="/etc/kubernetes/pki"

# Directorio de backups
export BACKUP_DIR="$HOME/k8s-labs/lab-04-certificates/backups"

# Alias útiles
alias check-certs='sudo kubeadm certs check-expiration'
alias list-certs='sudo find $PKI_DIR -name "*.crt" -exec echo {} \; -exec openssl x509 -in {} -noout -enddate \;'

# Aplicar cambios
source ~/.bashrc
```

### Verificar Configuración Final

```bash
# 1. Probar alias
check-certs

# Debería mostrar tabla de certificados

# 2. Verificar directorios
ls -la ~/k8s-labs/lab-04-certificates/

# 3. Verificar PKI_DIR
echo $PKI_DIR
sudo ls $PKI_DIR
```

---

## 📚 Información Adicional

### Estructura de /etc/kubernetes/pki

```
/etc/kubernetes/pki/
├── apiserver.crt                           # API Server certificate
├── apiserver.key                           # API Server private key
├── apiserver-kubelet-client.crt            # API Server → kubelet auth
├── apiserver-kubelet-client.key
├── ca.crt                                  # Kubernetes CA certificate
├── ca.key                                  # Kubernetes CA private key
├── front-proxy-ca.crt                      # Front proxy CA
├── front-proxy-ca.key
├── front-proxy-client.crt                  # Front proxy client
├── front-proxy-client.key
├── sa.key                                  # Service account signing key
├── sa.pub                                  # Service account public key
└── etcd/
    ├── ca.crt                              # etcd CA certificate
    ├── ca.key                              # etcd CA private key
    ├── healthcheck-client.crt              # etcd healthcheck
    ├── healthcheck-client.key
    ├── peer.crt                            # etcd peer communication
    ├── peer.key
    ├── server.crt                          # etcd server certificate
    └── server.key                          # etcd server private key
```

### Tamaño de Backup Esperado

```bash
# Verificar tamaño actual del directorio PKI
sudo du -sh /etc/kubernetes/pki/
# ~100-200KB (típico)

# Con todos los kubeconfigs:
sudo du -sh /etc/kubernetes/
# ~500KB - 1MB (típico)
```

### Herramientas Helper

```bash
# Script para verificar TODOS los certificados
cat > ~/check-all-certs.sh << 'EOF'
#!/bin/bash
find /etc/kubernetes/pki -name "*.crt" | while read cert; do
    echo "═══════════════════════════════════════"
    echo "Certificate: $cert"
    sudo openssl x509 -in "$cert" -noout -subject -issuer -dates
    echo ""
done
EOF

chmod +x ~/check-all-certs.sh

# Ejecutar
./check-all-certs.sh
```

---

## ✅ Checklist Pre-Lab

Antes de empezar el laboratorio, verifica:

- [ ] Cluster kubeadm verificado (existe `kubeadm-config` ConfigMap)
- [ ] Acceso SSH al control plane node
- [ ] Permisos sudo en el control plane
- [ ] kubeadm instalado y funcional
- [ ] openssl instalado
- [ ] kubectl conectado al cluster
- [ ] Permisos admin verificados (`kubectl auth can-i "*" "*"`)
- [ ] Al menos 20GB de espacio libre en disco
- [ ] Variables de entorno configuradas
- [ ] Scripts de validación ejecutados sin errores
- [ ] Directorio de backups creado

---

## 🎯 Próximos Pasos

Una vez completada la verificación de prerequisitos:

1. **Ejecutar script de validación**:
   ```bash
   ./validate-lab04-setup.sh
   ```

2. **Si todo está OK**, proceder con `README.md` del lab

3. **Si hay errores**, resolver según la sección de troubleshooting

---

**IMPORTANTE**: Este lab requiere acceso privilegiado al control plane. Si estás en un cluster de producción o managed (EKS/GKE/AKS), **NO EJECUTES ESTE LAB**. Usa un cluster de prueba creado con kubeadm.
