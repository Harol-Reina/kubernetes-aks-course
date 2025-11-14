# Setup - Lab 01: Docker Install

## 📋 Prerequisitos

### Sistema Operativo
- ✅ Linux (Ubuntu 20.04+, Debian, CentOS)
- ✅ Windows 10/11 Pro/Enterprise (con WSL2)
- ✅ macOS 10.15+

### Conocimientos
- ✅ Uso básico de terminal/línea de comandos
- ✅ Permisos de administrador (sudo)
- ✅ Conceptos básicos de virtualización

## 🔍 Verificación Pre-instalación

```bash
# Verificar si Docker ya está instalado
docker --version

# Si ya está instalado, verificar funcionamiento
docker run hello-world

# Si ambos funcionan, puedes saltar la instalación
```

## 💻 Opciones de Instalación

### Linux (Ubuntu/Debian)
- Script de instalación oficial de Docker
- Paquetes desde repositorio de Docker

### Windows
- Docker Desktop para Windows
- Requiere WSL2 habilitado

### macOS
- Docker Desktop para Mac

## ✅ Post-instalación

```bash
# Verificar versión
docker --version

# Verificar daemon corriendo
docker ps

# Test básico
docker run hello-world

# Agregar usuario al grupo docker (Linux)
sudo usermod -aG docker $USER
# Logout/login para aplicar
```

[Iniciar instalación](./README.md)
