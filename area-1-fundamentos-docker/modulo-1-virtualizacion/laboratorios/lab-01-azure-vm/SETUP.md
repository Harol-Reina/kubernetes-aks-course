# Setup - Lab 01: Azure VM Setup

## 📋 Prerequisitos

### Conocimientos Requeridos
- ✅ Conceptos básicos de virtualización
- ✅ Conocimiento de Azure Portal (básico)
- ✅ Manejo de SSH y línea de comandos
- ✅ Conceptos de redes (IP, puertos, firewall)

### Herramientas Necesarias
- ✅ Cuenta de Azure (free tier o subscription)
- ✅ Cliente SSH instalado (OpenSSH, PuTTY)
- ✅ Navegador web para Azure Portal
- ✅ Generador de claves SSH (ssh-keygen)

### Verificación del Entorno

```bash
# Verificar SSH instalado
ssh -V

# Verificar ssh-keygen disponible
ssh-keygen --help

# Si estás en Windows, verifica:
# - Windows Terminal instalado
# - OpenSSH Client habilitado
```

## 🎯 Acceso a Azure

### Opción 1: Azure Free Tier
1. Ir a [azure.microsoft.com/free](https://azure.microsoft.com/free)
2. Crear cuenta gratuita (requiere tarjeta de crédito, NO se cobra)
3. Acceder a [portal.azure.com](https://portal.azure.com)

### Opción 2: Azure for Students
1. Ir a [azure.microsoft.com/students](https://azure.microsoft.com/students)
2. Verificar con email educativo
3. $100 USD de crédito sin tarjeta

### Opción 3: Subscription Existente
1. Acceder a [portal.azure.com](https://portal.azure.com)
2. Verificar subscription activa
3. Permisos para crear VMs

## 🔑 Preparar Claves SSH

```bash
# Generar par de claves SSH
ssh-keygen -t rsa -b 4096 -C "tu-email@ejemplo.com"

# Ubicación default: ~/.ssh/id_rsa
# Dejar passphrase vacío para este lab (no recomendado en prod)

# Verificar claves creadas
ls -la ~/.ssh/
# Deberías ver: id_rsa (privada) e id_rsa.pub (pública)

# Ver clave pública (la necesitarás en el lab)
cat ~/.ssh/id_rsa.pub
```

## 💰 Costos Esperados

**VM Tamaño B1s (recomendado para lab):**
- **Free Tier**: 750 horas/mes gratis (primer mes)
- **Después**: ~$8-10 USD/mes si se deja corriendo 24/7
- **Lab duration**: 1-2 horas = costo insignificante

**⚠️ IMPORTANTE**: Eliminar la VM al terminar el lab para evitar cargos.

## 🧹 Preparación

```bash
# Crear directorio de trabajo
mkdir -p ~/azure-labs
cd ~/azure-labs

# (Opcional) Tener Azure CLI instalado
# https://docs.microsoft.com/cli/azure/install-azure-cli

# Test de Azure CLI (opcional)
az --version
az login
```

## ✅ Checklist Pre-Lab

- [ ] Cuenta de Azure creada y activa
- [ ] Acceso a Azure Portal
- [ ] Par de claves SSH generado
- [ ] Clave pública (.pub) copiada/disponible
- [ ] Cliente SSH funcional
- [ ] Directorio de trabajo creado

---

**¿Todo listo?** Procede con [README.md](./README.md) para crear tu primera VM en Azure.
