# Lab 3.2: Instalación de Docker

**Duración**: 20 minutos  
**Objetivo**: Instalar y configurar Docker como prerequisito para Minikube

## 🎯 Objetivos

- Instalar Docker Engine en Ubuntu
- Configurar Docker para ejecutar sin sudo
- Verificar la instalación y funcionamiento
- Configurar Docker para Minikube

---

## 📋 Prerequisitos

- VM preparada del Lab 3.1
- Conexión SSH activa
- Usuario con permisos sudo

---

## 🗑️ Paso 1: Remover versiones antiguas (si existen)

```bash
# Remover instalaciones previas de Docker
sudo apt remove -y docker docker-engine docker.io containerd runc

# Verificar que no hay instalaciones previas
which docker || echo "Docker no está instalado"
```

---

## 🔑 Paso 2: Configurar repositorio de Docker

```bash
# Actualizar índice de paquetes
sudo apt update

# Instalar paquetes para usar repositorio HTTPS
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Agregar clave GPG oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Verificar la clave (opcional)
sudo gpg --keyring /usr/share/keyrings/docker-archive-keyring.gpg --fingerprint

# Configurar repositorio estable
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualizar índice de paquetes
sudo apt update
```

---

## 📦 Paso 3: Instalar Docker Engine

```bash
# Instalar la última versión de Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verificar que Docker se instaló correctamente
docker --version
sudo systemctl status docker

# Habilitar Docker para que inicie con el sistema
sudo systemctl enable docker
```

**Salida esperada:**
```
Docker version 24.0.7, build afdd53b
● docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled)
     Active: active (running)
```

---

## 👤 Paso 4: Configurar permisos para usuario no-root

```bash
# Agregar usuario actual al grupo docker
sudo usermod -aG docker $USER

# Verificar que el usuario se agregó al grupo
groups $USER

# Aplicar cambios de grupo (alternativas)
# Opción 1: Usar newgrp (temporal para la sesión actual)
newgrp docker

# Opción 2: Cerrar sesión y volver a conectar (recomendado)
# exit
# ssh azureuser@<IP_VM>

# Verificar que Docker funciona sin sudo
docker run hello-world
```

**Salida esperada:**
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

---

## ⚙️ Paso 5: Configurar Docker para Minikube

```bash
# Crear directorio de configuración de Docker si no existe
sudo mkdir -p /etc/docker

# Configurar daemon de Docker para Minikube
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "insecure-registries": ["192.168.0.0/16"]
}
EOF

# Reiniciar Docker para aplicar configuración
sudo systemctl restart docker

# Verificar que Docker inició correctamente
sudo systemctl status docker

# Verificar configuración
docker info | grep -A 5 "Cgroup Driver"
docker info | grep "Storage Driver"
```

**Salida esperada:**
```
Cgroup Driver: systemd
Storage Driver: overlay2
```

---

## 🧪 Paso 6: Probar funcionalidad de Docker

```bash
# Ejecutar contenedor de prueba
docker run --rm hello-world

# Probar con imagen más completa
docker run --rm -it ubuntu:20.04 bash -c "echo 'Docker funciona correctamente!'"

# Verificar que el contenedor se ejecutó y terminó
docker ps -a | head -5

# Verificar imágenes descargadas
docker images

# Limpiar imágenes de prueba (opcional)
docker rmi hello-world ubuntu:20.04
```

---

## 🔍 Paso 7: Verificar configuración del sistema

```bash
# Crear script de verificación completa
cat << 'EOF' > ~/verificar-docker.sh
#!/bin/bash

echo "=== VERIFICACIÓN DE INSTALACIÓN DE DOCKER ==="
echo ""

# Verificar versión de Docker
echo "🐳 Versión de Docker:"
docker --version

# Verificar estado del servicio
echo ""
echo "🔧 Estado del servicio:"
sudo systemctl is-active docker
sudo systemctl is-enabled docker

# Verificar permisos del usuario
echo ""
echo "👤 Permisos del usuario:"
if groups $USER | grep -q docker; then
    echo "✅ Usuario en grupo docker"
else
    echo "❌ Usuario NO está en grupo docker"
fi

# Probar ejecución sin sudo
echo ""
echo "🧪 Prueba de ejecución:"
if docker run --rm hello-world &> /tmp/docker-test.log; then
    echo "✅ Docker funciona sin sudo"
else
    echo "❌ Docker falló sin sudo"
    echo "Log de error:"
    cat /tmp/docker-test.log
fi

# Verificar configuración del daemon
echo ""
echo "⚙️ Configuración del daemon:"
if [ -f /etc/docker/daemon.json ]; then
    echo "✅ Archivo de configuración existe"
    echo "Contenido:"
    cat /etc/docker/daemon.json
else
    echo "❌ Archivo de configuración no existe"
fi

# Verificar cgroup driver
echo ""
echo "🔄 Cgroup Driver:"
CGROUP_DRIVER=$(docker info 2>/dev/null | grep "Cgroup Driver" | awk '{print $3}')
if [ "$CGROUP_DRIVER" = "systemd" ]; then
    echo "✅ Cgroup Driver: systemd"
else
    echo "❌ Cgroup Driver: $CGROUP_DRIVER (debería ser systemd)"
fi

# Verificar storage driver
echo ""
echo "💾 Storage Driver:"
STORAGE_DRIVER=$(docker info 2>/dev/null | grep "Storage Driver" | awk '{print $3}')
if [ "$STORAGE_DRIVER" = "overlay2" ]; then
    echo "✅ Storage Driver: overlay2"
else
    echo "⚠️ Storage Driver: $STORAGE_DRIVER (recomendado: overlay2)"
fi

echo ""
echo "=== RESUMEN ==="
if docker run --rm hello-world &> /dev/null && [ "$CGROUP_DRIVER" = "systemd" ]; then
    echo "🎉 Docker está correctamente instalado y configurado para Minikube!"
else
    echo "⚠️ Docker requiere configuración adicional"
fi

# Limpiar
rm -f /tmp/docker-test.log
EOF

# Ejecutar verificación
chmod +x ~/verificar-docker.sh
~/verificar-docker.sh
```

---

## ✅ Resultado esperado

```
=== VERIFICACIÓN DE INSTALACIÓN DE DOCKER ===

🐳 Versión de Docker:
Docker version 24.0.7, build afdd53b

🔧 Estado del servicio:
active
enabled

👤 Permisos del usuario:
✅ Usuario en grupo docker

🧪 Prueba de ejecución:
✅ Docker funciona sin sudo

⚙️ Configuración del daemon:
✅ Archivo de configuración existe
Contenido:
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "insecure-registries": ["192.168.0.0/16"]
}

🔄 Cgroup Driver:
✅ Cgroup Driver: systemd

💾 Storage Driver:
✅ Storage Driver: overlay2

=== RESUMEN ===
🎉 Docker está correctamente instalado y configurado para Minikube!
```

---

## 🔧 Troubleshooting

### **Error: Permission denied**
```bash
# Si docker run falla con permission denied
sudo chmod 666 /var/run/docker.sock

# O reiniciar sesión
exit
ssh azureuser@<IP_VM>

# Verificar grupos
groups $USER
```

### **Error: Docker daemon not running**
```bash
# Iniciar Docker
sudo systemctl start docker

# Verificar logs
sudo journalctl -u docker.service -f

# Verificar configuración
sudo dockerd --config-file /etc/docker/daemon.json --debug
```

### **Error: Cgroup driver incorrecto**
```bash
# Editar configuración
sudo nano /etc/docker/daemon.json

# Asegurar que contiene:
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}

# Reiniciar Docker
sudo systemctl restart docker
```

### **Error: Storage driver**
```bash
# Verificar filesystems soportados
cat /proc/filesystems

# Verificar módulos del kernel
lsmod | grep overlay

# Cargar módulo si es necesario
sudo modprobe overlay
```

---

## 🧹 Limpieza (opcional)

```bash
# Remover imágenes de prueba
docker rmi $(docker images -q) 2>/dev/null || echo "No hay imágenes para remover"

# Limpiar contenedores detenidos
docker container prune -f

# Verificar limpieza
docker images
docker ps -a
```

---

## 📝 Checklist de completado

- [ ] Docker Engine instalado
- [ ] Servicio Docker habilitado y ejecutándose
- [ ] Usuario agregado al grupo docker
- [ ] Docker funciona sin sudo
- [ ] Configuración daemon.json creada
- [ ] Cgroup driver configurado como systemd
- [ ] Storage driver configurado como overlay2
- [ ] Pruebas de funcionamiento exitosas

---

**Siguiente paso**: [Lab 3.3: Instalación de kubectl](./instalacion-kubectl.md)