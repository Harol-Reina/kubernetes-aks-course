# Laboratorio: Crear y Gestionar VM en Azure

**Duración**: 45 minutos  
**Objetivo**: Crear una máquina virtual en Azure Portal y Azure CLI, conectarse y explorar el entorno virtualizado.

## 🎯 Objetivos de aprendizaje

- Crear una VM usando Azure Portal
- Configurar networking y seguridad básica
- Conectarse por SSH
- Explorar recursos del sistema virtualizado
- Entender conceptos de virtualización en la práctica

---

## 📋 Prerequisitos

- Cuenta de Azure activa
- Azure CLI instalado localmente (opcional)
- Cliente SSH (incluido en Linux/macOS, PuTTY en Windows)

---

## 🔧 Laboratorio 1: Crear VM desde Azure Portal

### Paso 1: Acceder al Portal de Azure

1. Navega a [portal.azure.com](https://portal.azure.com)
2. Inicia sesión con tu cuenta de Azure
3. En el dashboard, busca "Máquinas virtuales" o "Virtual machines"

### Paso 2: Crear la máquina virtual

1. **Hacer clic en "Crear" → "Máquina virtual de Azure"**

2. **Configuración básica:**
   - **Suscripción**: Selecciona tu suscripción
   - **Grupo de recursos**: Crear nuevo → `rg-curso-k8s-lab1`
   - **Nombre de la VM**: `vm-virtualizacion-lab`
   - **Región**: `East US` (o la más cercana)
   - **Opciones de disponibilidad**: No se requiere redundancia
   - **Tipo de seguridad**: Estándar

3. **Imagen y tamaño:**
   - **Imagen**: `Ubuntu Server 22.04 LTS - x64 Gen2`
   - **Tamaño**: `Standard_B1s (1 vcpu, 1 GiB memory)` - Cambiar tamaño si necesario

4. **Cuenta de administrador:**
   - **Tipo de autenticación**: Clave pública SSH
   - **Nombre de usuario**: `azureuser`
   - **Origen de clave pública SSH**: Generar nuevo par de claves
   - **Nombre del par de claves**: `vm-key-lab1`

5. **Reglas de puerto de entrada:**
   - **Puertos de entrada públicos**: Permitir los puertos seleccionados
   - **Seleccionar puertos de entrada**: SSH (22)

### Paso 3: Configuración de redes

1. **Ir a la pestaña "Redes"**
2. **Red virtual**: Crear nueva o usar la predeterminada
3. **Subred**: default (10.0.0.0/24)
4. **IP pública**: Crear nueva
5. **Grupo de seguridad de red de NIC**: Básico
6. **Puertos de entrada públicos**: SSH (22)

### Paso 4: Revisar y crear

1. **Ir a "Revisar y crear"**
2. **Validar configuración**
3. **Hacer clic en "Crear"**
4. **Descargar la clave privada** cuando se solicite (importante para SSH)

### Paso 5: Esperar el despliegue

- El proceso toma 2-5 minutos
- Verás el progreso en tiempo real
- Al completarse, ve a "Ir al recurso"

---

## 🔧 Laboratorio 2: Conectarse y explorar la VM

### Paso 1: Obtener información de conexión

1. **En la página de la VM, nota:**
   - **IP pública**: Aparece en la esquina superior derecha
   - **Estado**: Debe mostrar "En ejecución"

2. **Configurar permisos de la clave SSH (Linux/macOS):**
   ```bash
   chmod 600 ~/Downloads/vm-key-lab1.pem
   ```

### Paso 2: Conectarse por SSH

```bash
# Conectarse a la VM
ssh -i ~/Downloads/vm-key-lab1.pem azureuser@<IP_PUBLICA>

# Aceptar la huella digital cuando se solicite
```

### Paso 3: Explorar el sistema virtualizado

Una vez conectado, ejecuta los siguientes comandos:

```bash
# 1. Información del sistema operativo
cat /etc/os-release
uname -a

# 2. Información de hardware virtualizado
lscpu
cat /proc/cpuinfo | grep "model name" | head -1

# 3. Información de memoria
free -h
cat /proc/meminfo | head -5

# 4. Información de almacenamiento
df -h
lsblk

# 5. Información de red
ip addr show
ip route show

# 6. Procesos en ejecución
ps aux | head -10

# 7. Verificar si estamos en una VM
sudo dmidecode -s system-manufacturer
sudo dmidecode -s system-product-name

# 8. Información de hipervisor
lscpu | grep Hypervisor
dmesg | grep -i virtual | head -5
```

### Paso 4: Instalar herramientas útiles

```bash
# Actualizar el sistema
sudo apt update

# Instalar herramientas de monitoring
sudo apt install -y htop neofetch tree

# Ver información del sistema de forma visual
neofetch

# Monitor de recursos interactivo
htop
# Presiona 'q' para salir
```

---

## 🔧 Laboratorio 3: Azure CLI (Opcional)

Si tienes Azure CLI instalado, puedes crear otra VM usando comandos:

### Paso 1: Login y configuración

```bash
# Login a Azure
az login

# Verificar suscripción
az account show

# Crear grupo de recursos
az group create \
  --name rg-curso-k8s-cli \
  --location eastus
```

### Paso 2: Crear VM con CLI

```bash
# Crear VM con Azure CLI
az vm create \
  --resource-group rg-curso-k8s-cli \
  --name vm-cli-lab \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --size Standard_B1s \
  --public-ip-sku Standard

# Abrir puerto SSH
az vm open-port \
  --resource-group rg-curso-k8s-cli \
  --name vm-cli-lab \
  --port 22
```

### Paso 3: Obtener IP y conectarse

```bash
# Obtener IP pública
az vm show \
  --resource-group rg-curso-k8s-cli \
  --name vm-cli-lab \
  --show-details \
  --query publicIps \
  --output tsv

# Conectarse (usando las claves SSH generadas automáticamente)
ssh azureuser@<IP_PUBLICA>
```

---

## 🧪 Ejercicios de análisis

Una vez conectado a cualquiera de las VMs, responde:

### **Ejercicio 1: Recursos virtualizados**
```bash
# ¿Cuántos núcleos de CPU tienes asignados?
lscpu | grep "^CPU(s):"

# ¿Cuánta RAM tiene la VM?
free -h | grep "^Mem:"

# ¿Cuánto espacio en disco?
df -h | grep "/$"
```

### **Ejercicio 2: Identificación del hipervisor**
```bash
# ¿Qué hipervisor está usando Azure?
sudo dmidecode -s system-manufacturer
dmesg | grep -i hyperv
```

### **Ejercicio 3: Networking virtual**
```bash
# ¿Cuál es tu IP privada y pública?
curl ifconfig.me  # IP pública
ip addr show eth0 | grep inet  # IP privada
```

### **Ejercicio 4: Comparación de rendimiento**
```bash
# Test de velocidad de CPU
time echo "scale=1000; 4*a(1)" | bc -l

# Test de escritura en disco
dd if=/dev/zero of=tempfile bs=1M count=100 conv=fdatasync
rm tempfile
```

---

## 🔄 Gestión de la VM

### Operaciones básicas desde Azure Portal:

1. **Detener la VM:**
   - Azure Portal → VM → "Detener"
   - Nota el tiempo que toma

2. **Iniciar la VM:**
   - Azure Portal → VM → "Iniciar"  
   - Nota el tiempo de arranque

3. **Reiniciar la VM:**
   - Azure Portal → VM → "Reiniciar"

4. **Cambiar tamaño (opcional):**
   - Azure Portal → VM → "Tamaño" → Cambiar a Standard_B2s
   - Observa las diferencias

---

## 📊 Análisis y reflexión

### **Preguntas de reflexión:**

1. **¿Cómo se compara el tiempo de arranque de la VM con tu computadora física?**

2. **¿Qué ventajas observas de tener la VM en la nube vs local?**

3. **¿Cómo crees que Azure gestiona los recursos físicos subyacentes?**

4. **¿Qué limitaciones has observado en esta VM compared to bare metal?**

5. **¿Cómo se relaciona esto con los contenedores que veremos en el próximo módulo?**

---

## 🧹 Limpieza de recursos

### **Importante**: Para evitar costos

```bash
# Opción 1: Eliminar grupo de recursos completo (CLI)
az group delete --name rg-curso-k8s-lab1 --yes --no-wait
az group delete --name rg-curso-k8s-cli --yes --no-wait

# Opción 2: Desde Azure Portal
# 1. Ir a "Grupos de recursos"
# 2. Seleccionar el grupo creado
# 3. "Eliminar grupo de recursos"
# 4. Escribir el nombre para confirmar
```

---

## 📝 Entregables del laboratorio

1. **Screenshot** de la VM ejecutándose en Azure Portal
2. **Output** del comando `neofetch` desde la VM
3. **Respuestas** a las preguntas de reflexión
4. **Comparación** de recursos: local vs VM en Azure

---

## 🔗 Siguientes pasos

Una vez completado este laboratorio:

- ✅ Entiendes cómo funciona la virtualización en la práctica
- ✅ Has experimentado con VMs en la nube
- ✅ Comprendes el overhead de virtualización
- ✅ Estás listo para contrastar con contenedores en el Módulo 2

**Tiempo estimado**: 45-60 minutos  
**Dificultad**: Básico