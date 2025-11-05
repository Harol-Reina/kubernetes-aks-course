# Lab 3.1: Preparación de la VM para Minikube

**Duración**: 15 minutos  
**Objetivo**: Preparar la VM de Azure para la instalación de Minikube

## 🎯 Objetivos

- Verificar requisitos del sistema
- Actualizar el sistema operativo
- Configurar usuario con permisos sudo
- Instalar dependencias básicas

---

## 📋 Prerequisitos

- VM de Azure con Ubuntu 20.04+
- Conexión SSH configurada
- Acceso a internet

---

## 🚀 Paso 1: Conectar a la VM

```bash
# Conectar via SSH
ssh azureuser@<IP_PUBLICA_VM>

# Verificar información del sistema
uname -a
cat /etc/os-release
```

**Salida esperada:**
```
Linux minikube-vm 5.15.0-... x86_64 GNU/Linux
NAME="Ubuntu"
VERSION="20.04.6 LTS (Focal Fossa)"
```

---

## 🔧 Paso 2: Verificar recursos del sistema

```bash
# Verificar CPU
nproc
lscpu | grep "CPU(s):"

# Verificar RAM
free -h
grep MemTotal /proc/meminfo

# Verificar espacio en disco
df -h
lsblk
```

**Requisitos mínimos:**
- **CPU**: 2 cores mínimo
- **RAM**: 4GB mínimo (recomendado 8GB)
- **Disk**: 20GB libres mínimo

**Ejemplo de salida satisfactoria:**
```bash
$ nproc
2

$ free -h
              total        used        free
Mem:           7.6G        1.2G        6.4G

$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        30G  8.2G   20G  30% /
```

---

## 📦 Paso 3: Actualizar el sistema

```bash
# Actualizar lista de paquetes
sudo apt update

# Actualizar paquetes instalados
sudo apt upgrade -y

# Instalar herramientas básicas y dependencias de Kubernetes
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    vim \
    git \
    tree \
    htop

# Verificar instalación de herramientas básicas
which curl wget git

# Verificar iptables (requerido por Kubernetes networking)
sudo iptables --version

# Verificar iptables (requerido por Kubernetes networking)
sudo iptables --version
```

---

## 👤 Paso 4: Configurar usuario

```bash
```bash
# Verificar usuario actual
whoami
id

# Verificar permisos sudo
sudo whoami

# Agregar usuario al grupo docker (para más adelante)
sudo usermod -aG docker $USER

# Verificar que el usuario se agregó al grupo
groups $USER
```

---

## 🔧 Paso 5: Verificar dependencias de Kubernetes

```bash
# Crear script de verificación de dependencias de Kubernetes
cat << 'EOF' > ~/verificar-dependencias-k8s.sh
#!/bin/bash

echo "=== VERIFICACIÓN DE DEPENDENCIAS DE KUBERNETES ==="
echo ""

# Función para verificar comando
check_command() {
    if command -v $1 &> /dev/null; then
        echo "✅ $1 está instalado"
        $1 --version 2>/dev/null || echo "  Versión: $(dpkg -l | grep $1 | awk '{print $3}' | head -1)"
    else
        echo "❌ $1 NO está instalado"
        return 1
    fi
}

# Verificar herramientas básicas para Kubernetes
echo "🔍 Verificando herramientas básicas:"
check_command "curl"
check_command "wget"
check_command "git"
check_command "iptables"

echo ""
echo "🔍 Verificando módulos del kernel necesarios:"

# Verificar módulos del kernel
REQUIRED_MODULES=("br_netfilter" "overlay")
for module in "${REQUIRED_MODULES[@]}"; do
    if lsmod | grep -q "^$module"; then
        echo "✅ Módulo $module está cargado"
    else
        echo "⚠️ Módulo $module no está cargado, intentando cargar..."
        sudo modprobe $module
        if lsmod | grep -q "^$module"; then
            echo "✅ Módulo $module cargado exitosamente"
        else
            echo "❌ No se pudo cargar el módulo $module"
        fi
    fi
done

echo ""
echo "🔍 Verificando configuración de red:"

# Verificar IP forwarding
if sysctl net.ipv4.ip_forward | grep -q "= 1"; then
    echo "✅ IP forwarding está habilitado"
else
    echo "⚠️ IP forwarding no está habilitado, habilitando..."
    echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

# Verificar bridge netfilter
if sysctl net.bridge.bridge-nf-call-iptables | grep -q "= 1"; then
    echo "✅ Bridge netfilter está configurado"
else
    echo "⚠️ Configurando bridge netfilter..."
    echo 'net.bridge.bridge-nf-call-iptables = 1' | sudo tee -a /etc/sysctl.conf
    echo 'net.bridge.bridge-nf-call-ip6tables = 1' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

echo ""
echo "=== RESUMEN ==="
echo "✅ Sistema básico configurado para Docker"
echo "🎯 Listo para instalar Minikube con driver Docker"
EOF

chmod +x ~/verificar-dependencias-k8s.sh
~/verificar-dependencias-k8s.sh
```

---

## 🌐 Paso 6: Configurar red y conectividad

# Verificar grupos del usuario
groups $USER
```

**Nota**: Necesitarás cerrar sesión y volver a conectar para que los cambios de grupo tomen efecto.

---

## 🌐 Paso 5: Configurar red y conectividad

```bash
# Verificar conectividad a internet
ping -c 3 google.com

# Verificar resolución DNS
nslookup kubernetes.io

# Verificar puertos disponibles (importantes para Kubernetes)
sudo ss -tlnp | grep -E ":(8080|8443|10250|10251|10252|10255|2379|2380)"

# Si hay servicios usando estos puertos, detenerlos
# sudo systemctl stop <servicio>
```

**Puertos importantes para Kubernetes:**
- **8080**: API Server (insecure)
- **8443**: API Server (secure)
- **10250**: kubelet
- **10251**: kube-scheduler
- **10252**: kube-controller-manager
- **2379-2380**: etcd

---

## 🔥 Paso 6: Configurar firewall (si está habilitado)

```bash
# Verificar estado del firewall
sudo ufw status

# Si está activo, configurar reglas para Kubernetes
if sudo ufw status | grep -q "Status: active"; then
    echo "Configurando firewall para Kubernetes..."
    
    # Permitir tráfico de Kubernetes
    sudo ufw allow 8080/tcp
    sudo ufw allow 8443/tcp
    sudo ufw allow 10250/tcp
    sudo ufw allow 10251/tcp
    sudo ufw allow 10252/tcp
    sudo ufw allow 2379:2380/tcp
    
    # Permitir tráfico de Docker
    sudo ufw allow 2376/tcp
    sudo ufw allow 2377/tcp
    
    # Recargar reglas
    sudo ufw reload
    
    # Verificar reglas
    sudo ufw status numbered
else
    echo "Firewall no está activo"
fi
```

---

## 🧪 Paso 7: Verificar preparación

```bash
# Script de verificación
cat << 'EOF' > ~/verificar-preparacion.sh
#!/bin/bash

echo "=== VERIFICACIÓN DE PREPARACIÓN PARA MINIKUBE ==="
echo ""

# Verificar CPU
CPU_CORES=$(nproc)
echo "CPU Cores: $CPU_CORES"
if [ $CPU_CORES -ge 2 ]; then
    echo "✅ CPU: Suficiente ($CPU_CORES cores)"
else
    echo "❌ CPU: Insuficiente ($CPU_CORES cores, mínimo 2)"
fi

# Verificar RAM
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
echo "RAM: ${RAM_GB}GB"
if [ $RAM_GB -ge 3 ]; then
    echo "✅ RAM: Suficiente (${RAM_GB}GB)"
else
    echo "❌ RAM: Insuficiente (${RAM_GB}GB, mínimo 4GB)"
fi

# Verificar espacio en disco
DISK_AVAIL=$(df / | awk '/\//{print $(NF-2)}' | sed 's/G//')
echo "Disco disponible: ${DISK_AVAIL}GB"
if [ $DISK_AVAIL -ge 20 ]; then
    echo "✅ Disco: Suficiente (${DISK_AVAIL}GB)"
else
    echo "❌ Disco: Insuficiente (${DISK_AVAIL}GB, mínimo 20GB)"
fi

# Verificar conectividad
if ping -c 1 google.com &> /dev/null; then
    echo "✅ Conectividad: OK"
else
    echo "❌ Conectividad: Falló"
fi

# Verificar sudo
if sudo -n true 2>/dev/null; then
    echo "✅ Permisos sudo: OK"
else
    echo "❌ Permisos sudo: Falló"
fi

# Verificar herramientas básicas
TOOLS="curl wget git"
for tool in $TOOLS; do
    if which $tool &> /dev/null; then
        echo "✅ $tool: Instalado"
    else
        echo "❌ $tool: No encontrado"
    fi
done

echo ""
echo "=== RESUMEN ==="
if [ $CPU_CORES -ge 2 ] && [ $RAM_GB -ge 3 ] && [ $DISK_AVAIL -ge 20 ]; then
    echo "🎉 Sistema preparado para Minikube!"
else
    echo "⚠️  Sistema no cumple requisitos mínimos"
fi
EOF

# Ejecutar verificación
chmod +x ~/verificar-preparacion.sh
~/verificar-preparacion.sh
```

---

## ✅ Resultado esperado

Al completar este laboratorio deberías ver:

```
=== VERIFICACIÓN DE PREPARACIÓN PARA MINIKUBE ===

CPU Cores: 2
✅ CPU: Suficiente (2 cores)
RAM: 7GB
✅ RAM: Suficiente (7GB)
Disco disponible: 22GB
✅ Disco: Suficiente (22GB)
✅ Conectividad: OK
✅ Permisos sudo: OK
✅ curl: Instalado
✅ wget: Instalado
✅ git: Instalado

=== RESUMEN ===
🎉 Sistema preparado para Minikube!
```

---

## 🔧 Troubleshooting

### **Error: Módulos del kernel no disponibles**
```bash
# Error con módulos br_netfilter u overlay

# Cargar módulos manualmente
sudo modprobe br_netfilter
sudo modprobe overlay

# Hacer permanente
echo 'br_netfilter' | sudo tee -a /etc/modules-load.d/k8s.conf
echo 'overlay' | sudo tee -a /etc/modules-load.d/k8s.conf

# Verificar
lsmod | grep br_netfilter
lsmod | grep overlay
```

### **Error: Espacio insuficiente**
```bash
# Limpiar paquetes no necesarios
sudo apt autoremove -y
sudo apt autoclean

# Verificar archivos grandes
sudo du -sh /var/log/*
sudo du -sh /tmp/*

# Limpiar logs si es necesario
sudo journalctl --vacuum-time=1d
```

### **Error: Conectividad**
```bash
# Verificar DNS
cat /etc/resolv.conf

# Probar con DNS público
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Verificar interfaz de red
ip addr show
```

### **Error: Permisos sudo**
```bash
# Verificar configuración sudo
sudo visudo

# El usuario debe estar en grupo sudo
sudo usermod -aG sudo $USER

# Cerrar sesión y volver a conectar
exit
```

---

## 📝 Checklist de completado

- [ ] VM conectada via SSH
- [ ] Sistema actualizado
- [ ] Recursos verificados (CPU ≥2, RAM ≥4GB, Disk ≥20GB)
- [ ] Herramientas básicas instaladas
- [ ] Usuario con permisos sudo
- [ ] Conectividad a internet funcionando
- [ ] Firewall configurado (si aplica)
- [ ] Script de verificación exitoso

---

**Siguiente paso**: [Lab 3.2: Instalación de Docker](./instalacion-docker.md)