# 📝 Resumen - Módulo 1: Virtualización Tradicional

> **Guía rápida de estudio**: Conceptos clave, comandos esenciales y troubleshooting para el módulo de virtualización.

---

## 🎯 Conceptos Clave en 5 Minutos

### ¿Qué es la Virtualización?

**Definición**: Tecnología que permite ejecutar **múltiples sistemas operativos** (VMs) en un solo servidor físico, compartiendo recursos de hardware.

**Analogía**: Es como dividir un edificio grande en apartamentos independientes. Cada apartamento (VM) tiene su propia cocina, baño y habitaciones (SO, apps), pero todos comparten la misma estructura física (hardware).

**Componente clave**: El **hipervisor** actúa como administrador que distribuye recursos (CPU, RAM, disco) entre las VMs.

### Diagrama Conceptual Básico

```
┌─────────────────────────────────────────┐
│  VM1: Ubuntu    VM2: Windows    VM3: CentOS  │
│  ├─ App Web     ├─ SQL Server   ├─ Jenkins   │
│  └─ SO Linux    └─ SO Windows   └─ SO Linux  │
├─────────────────────────────────────────┤
│       HIPERVISOR (ESXi / KVM / Hyper-V) │
├─────────────────────────────────────────┤
│       HARDWARE FÍSICO (CPU, RAM, Disco) │
└─────────────────────────────────────────┘
```

---

## 📊 1. Componentes de la Virtualización

### 🖥️ Servidor Físico (Host)
- Provee recursos físicos: CPU, RAM, almacenamiento, red
- Ejecuta el hipervisor
- Hardware típico: 64+ GB RAM, 16+ núcleos CPU, arrays de discos

### 🔧 Hipervisor (Virtual Machine Monitor)
Gestiona las VMs y distribuye recursos físicos.

**Tipo 1 (Bare-Metal)**: Instalado directamente sobre hardware
- ✅ Mayor rendimiento
- ✅ Menor latencia
- ✅ Ideal para producción
- Ejemplos: VMware ESXi, Microsoft Hyper-V Server, KVM, Citrix XenServer

**Tipo 2 (Hosted)**: Instalado sobre un SO existente
- ✅ Fácil instalación
- ✅ Ideal para desarrollo/testing
- ❌ Menor rendimiento
- Ejemplos: VirtualBox, VMware Workstation, Parallels Desktop

### 💻 Máquina Virtual (Guest)
- SO completo independiente
- Apps aisladas del host y otras VMs
- Recursos asignados virtualmente
- Tamaño típico: 2-8 GB RAM, 2-4 vCPUs

---

## 📊 2. Tipos de Virtualización

| Tipo | Qué Virtualiza | Casos de Uso | Ejemplos |
|------|----------------|--------------|----------|
| **Servidores** | Hardware completo | Consolidación, entornos dev/test | VMware, Hyper-V, KVM |
| **Escritorios (VDI)** | Escritorios completos | Trabajo remoto, call centers | Citrix, VMware Horizon, RDS |
| **Red (NFV)** | Switches, routers, firewalls | SDN, micro-segmentación | NSX, vSwitch, OVS |
| **Almacenamiento** | Discos físicos → volúmenes lógicos | Storage unificado | vSAN, LVM, Storage Spaces |
| **Aplicaciones** | Apps + runtime encapsulado | Apps legacy, compatibilidad | App-V, ThinApp |
| **Datos** | Federación de múltiples fuentes | Data lakes, integración | Denodo, JBoss Data Virt |

---

## 🛠️ 3. Comandos Esenciales de Gestión

### Azure CLI - Creación de VMs

```bash
# Login a Azure
az login

# Crear grupo de recursos
az group create \
  --name my-rg \
  --location eastus

# Crear VM Ubuntu
az vm create \
  --resource-group my-rg \
  --name my-ubuntu-vm \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# Abrir puerto 80 (HTTP)
az vm open-port \
  --resource-group my-rg \
  --name my-ubuntu-vm \
  --port 80 \
  --priority 1001

# Listar VMs
az vm list --output table

# Ver detalles de una VM
az vm show \
  --resource-group my-rg \
  --name my-ubuntu-vm

# Detener VM
az vm deallocate \
  --resource-group my-rg \
  --name my-ubuntu-vm

# Iniciar VM
az vm start \
  --resource-group my-rg \
  --name my-ubuntu-vm

# Eliminar VM
az vm delete \
  --resource-group my-rg \
  --name my-ubuntu-vm \
  --yes
```

### Comandos dentro de la VM (Linux)

```bash
# Conectarse por SSH
ssh azureuser@<IP_PUBLICA>

# Ver información de CPU
lscpu
nproc  # Número de procesadores

# Ver información de memoria
free -h
cat /proc/meminfo | grep MemTotal

# Ver información de disco
df -h
lsblk

# Ver procesos y recursos
top        # Vista interactiva
htop       # Mejor visualización (instalar: sudo apt install htop)
ps aux     # Lista de procesos

# Monitoreo continuo de recursos
vmstat 1   # Estadísticas cada 1 segundo
iostat 1   # I/O statistics

# Ver información del sistema
uname -a              # Kernel y arquitectura
cat /etc/os-release   # Versión de SO
uptime                # Tiempo de actividad y carga

# Ver red
ip addr               # Direcciones IP
ifconfig              # Interfases de red (legacy)
netstat -tulpn        # Puertos abiertos
ss -tulpn             # Sockets (reemplazo moderno de netstat)
```

### VirtualBox CLI (Opcional - Local)

```bash
# Listar VMs
VBoxManage list vms

# Iniciar VM
VBoxManage startvm "nombre-vm" --type headless

# Detener VM
VBoxManage controlvm "nombre-vm" poweroff

# Ver información
VBoxManage showvminfo "nombre-vm"

# Crear snapshot
VBoxManage snapshot "nombre-vm" take "snapshot-name"

# Restaurar snapshot
VBoxManage snapshot "nombre-vm" restore "snapshot-name"
```

---

## 📋 4. Cheat Sheet - Comparativas Clave

### VMs vs. Hardware Tradicional

| Aspecto | Hardware Dedicado | Virtualización (VMs) |
|---------|-------------------|---------------------|
| **Costo inicial** | Alto (servidores físicos) | Medio (licencias hipervisor) |
| **Aprovechamiento** | 10-20% (desperdicio) | 60-80% (eficiente) |
| **Densidad** | 1 app por servidor | 5-20 apps por servidor |
| **Tiempo de provisión** | Días/semanas | Minutos |
| **Escalabilidad** | Comprar más hardware | Ajustar recursos virtuales |
| **Aislamiento** | Completo (físico) | Completo (virtual) |
| **Recuperación** | Lenta, manual | Rápida, automatizada |

### VMs vs. Contenedores

| Aspecto | Máquinas Virtuales | Contenedores |
|---------|-------------------|--------------|
| **SO Guest** | SO completo (2-4 GB) | Comparte kernel del host |
| **Tamaño** | GB (2-20 GB típico) | MB (50-500 MB típico) |
| **Arranque** | Minutos | Segundos |
| **Recursos** | Alto overhead | Overhead mínimo |
| **Aislamiento** | Completo (hardware virtual) | Proceso-nivel (namespaces) |
| **Portabilidad** | Limitada (hipervisor específico) | Alta (cualquier host con runtime) |
| **Densidad** | 5-20 VMs por servidor | 100+ contenedores por servidor |
| **Uso típico** | Apps legacy, Windows, aislamiento total | Microservicios, apps cloud-native |

### Tipos de Hipervisores

| Característica | Tipo 1 (Bare-Metal) | Tipo 2 (Hosted) |
|----------------|---------------------|-----------------|
| **Instalación** | Directo sobre hardware | Sobre SO existente |
| **Rendimiento** | ⭐⭐⭐⭐⭐ Excelente | ⭐⭐⭐ Bueno |
| **Latencia** | Mínima | Moderada |
| **Uso típico** | Producción, datacenters | Desarrollo, testing local |
| **Ejemplos** | ESXi, Hyper-V, KVM | VirtualBox, VMware Workstation |
| **Costo** | Alto (licencias enterprise) | Bajo/Gratis |

---

## 🔍 5. Troubleshooting Común

### Problema 1: VM con rendimiento lento

**Síntomas**:
- Aplicaciones lentas dentro de la VM
- CPU o memoria al 100%
- Respuesta lenta del sistema

**Diagnóstico**:
```bash
# Dentro de la VM
top                    # Ver procesos consumiendo recursos
free -h                # Ver uso de memoria
iostat -x 1 5          # Ver uso de disco
vmstat 1               # Estadísticas generales

# Desde Azure Portal
# → Ir a la VM → Metrics → Ver CPU, Memory, Disk
```

**Soluciones**:
1. ✅ **Aumentar recursos asignados**: Cambiar a size de VM mayor (B2s → B4ms)
2. ✅ **Identificar procesos problemáticos**: `ps aux --sort=-%cpu | head` (top CPU consumers)
3. ✅ **Verificar swap excesivo**: Si hay swap alto, aumentar RAM
4. ✅ **Revisar I/O de disco**: Cambiar a discos premium (SSD) si hay bottleneck

**Comandos Azure CLI**:
```bash
# Cambiar tamaño de VM (requiere detenerla primero)
az vm deallocate --resource-group my-rg --name my-vm
az vm resize --resource-group my-rg --name my-vm --size Standard_B4ms
az vm start --resource-group my-rg --name my-vm
```

---

### Problema 2: No puedo conectarme por SSH a la VM

**Síntomas**:
- `ssh: connect to host X.X.X.X port 22: Connection timed out`
- `ssh: connect to host X.X.X.X port 22: Connection refused`

**Diagnóstico**:
```bash
# Verificar que la VM está corriendo
az vm get-instance-view \
  --resource-group my-rg \
  --name my-vm \
  --query instanceView.statuses[1] \
  --output table

# Verificar IP pública
az vm list-ip-addresses \
  --resource-group my-rg \
  --name my-vm \
  --output table

# Verificar reglas de firewall (NSG)
az network nsg rule list \
  --resource-group my-rg \
  --nsg-name my-vm-nsg \
  --output table
```

**Soluciones**:
1. ✅ **VM detenida**: Iniciarla con `az vm start`
2. ✅ **Firewall bloqueando puerto 22**:
   ```bash
   az vm open-port \
     --resource-group my-rg \
     --name my-vm \
     --port 22 \
     --priority 1000
   ```
3. ✅ **IP pública no asignada**: Crear y asociar IP pública
4. ✅ **Servicio SSH no corriendo**: Usar consola serial de Azure para iniciar `sshd`

---

### Problema 3: VM consume demasiados recursos del host (overcommit)

**Síntomas**:
- Múltiples VMs compitiendo por recursos
- "CPU steal time" alto
- Rendimiento degradado en todas las VMs

**Diagnóstico**:
```bash
# Dentro de una VM Linux, verificar "steal time"
top
# Buscar "%st" en la línea de CPU - valores >5% indican contención

# O con vmstat
vmstat 1
# Columna "st" (steal) indica tiempo que la VM espera por CPU del host
```

**Explicación técnica**:
- **CPU steal time**: Porcentaje de tiempo que una VM quiere usar CPU pero el hipervisor se la da a otra VM
- Indica sobresuscripción (overcommit) de recursos físicos

**Soluciones**:
1. ✅ **Escalar verticalmente**: Aumentar recursos del host físico
2. ✅ **Escalar horizontalmente**: Distribuir VMs en más hosts
3. ✅ **Límites de recursos**: Configurar CPU/RAM limits en el hipervisor
4. ✅ **Migración**: Mover VMs a hosts con más recursos disponibles

---

### Problema 4: Disco lleno en la VM

**Síntomas**:
- `No space left on device`
- Aplicaciones fallan al escribir archivos
- VM no arranca correctamente

**Diagnóstico**:
```bash
# Ver uso de disco
df -h

# Encontrar directorios grandes
du -sh /* | sort -h
du -sh /var/* | sort -h

# Encontrar archivos grandes
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# Ver inodos (a veces se agotan sin llenar el disco)
df -i
```

**Soluciones**:
1. ✅ **Limpiar logs antiguos**:
   ```bash
   sudo journalctl --vacuum-time=7d  # Mantener solo 7 días de logs
   sudo apt clean                     # Limpiar cache de paquetes (Ubuntu/Debian)
   ```

2. ✅ **Eliminar archivos temporales**:
   ```bash
   sudo rm -rf /tmp/*
   sudo rm -rf /var/tmp/*
   ```

3. ✅ **Aumentar tamaño del disco en Azure**:
   ```bash
   # Detener VM
   az vm deallocate --resource-group my-rg --name my-vm
   
   # Aumentar tamaño del disco OS (ej: 30GB → 64GB)
   az disk update \
     --resource-group my-rg \
     --name my-vm-os-disk \
     --size-gb 64
   
   # Iniciar VM
   az vm start --resource-group my-rg --name my-vm
   
   # Dentro de la VM, expandir partición
   sudo growpart /dev/sda 1    # Expandir partición
   sudo resize2fs /dev/sda1    # Expandir filesystem ext4
   # O para XFS: sudo xfs_growfs /
   ```

---

### Problema 5: VM no arranca después de snapshot/restore

**Síntomas**:
- VM queda en estado "Starting" indefinidamente
- Boot loop o kernel panic
- Errores en boot diagnostics

**Diagnóstico**:
```bash
# Ver boot diagnostics en Azure
az vm boot-diagnostics get-boot-log \
  --resource-group my-rg \
  --name my-vm

# Ver captura de pantalla del boot
az vm boot-diagnostics get-boot-log-uris \
  --resource-group my-rg \
  --name my-vm
```

**Causas comunes**:
1. Snapshot tomado con VM en estado inconsistente (sin detener servicios)
2. Corrupción de filesystem
3. Configuración de red que cambió (MAC address, IP estática)
4. Drivers faltantes después de migración entre tipos de VM

**Soluciones**:
1. ✅ **Usar consola serial**: Acceso directo sin SSH
2. ✅ **Modo single-user**: Arrancar en modo de recuperación
3. ✅ **Verificar /etc/fstab**: Comentar montajes problemáticos
4. ✅ **Recrear VM desde snapshot conocido bueno**

---

## 📋 6. Checklist de Conceptos Clave

### ✅ Fundamentos de Virtualización
- [ ] Puedo explicar qué es un hipervisor y su función
- [ ] Entiendo la diferencia entre hipervisor tipo 1 y tipo 2
- [ ] Conozco los componentes: Host, Guest, Hipervisor
- [ ] Comprendo cómo se distribuyen recursos físicos entre VMs
- [ ] Puedo describir el overhead de tener un SO guest completo

### ✅ Tipos de Virtualización
- [ ] Virtualización de servidores (VMs completas)
- [ ] Virtualización de escritorios (VDI)
- [ ] Virtualización de red (NFV, SDN)
- [ ] Virtualización de almacenamiento
- [ ] Virtualización de aplicaciones (App-V, ThinApp)
- [ ] Sé cuándo usar cada tipo según el caso de uso

### ✅ Práctica con Azure
- [ ] Puedo crear una VM en Azure Portal
- [ ] Sé conectarme por SSH a una VM Linux
- [ ] Puedo monitorear CPU, RAM y disco dentro de una VM
- [ ] Conozco comandos Azure CLI básicos (create, start, stop, delete)
- [ ] Entiendo cómo funcionan los Network Security Groups (NSG)

### ✅ Comparativas y Evolución
- [ ] Ventajas de virtualización: consolidación, aislamiento, snapshots
- [ ] Desventajas: overhead de SO, arranque lento, licencias
- [ ] Diferencias clave entre VMs y contenedores
- [ ] Por qué surgieron los contenedores como evolución
- [ ] Cuándo usar VMs vs. contenedores vs. serverless

---

## ❓ 7. Preguntas de Repaso

### Preguntas Conceptuales

<details>
<summary><strong>1. ¿Cuál es la principal diferencia entre un hipervisor tipo 1 y tipo 2?</strong></summary>

**Respuesta**:
- **Tipo 1 (Bare-Metal)**: Se instala **directamente sobre el hardware físico**, sin SO intermedio. Mayor rendimiento, usado en producción. Ejemplos: VMware ESXi, Hyper-V Server, KVM.
  
- **Tipo 2 (Hosted)**: Se instala **sobre un sistema operativo existente** (Windows, Linux, macOS). Más fácil de configurar, usado para desarrollo/testing. Ejemplos: VirtualBox, VMware Workstation.

**Analogía**: Tipo 1 es como construir un edificio desde cero (base sólida). Tipo 2 es como poner una casa prefabricada sobre un terreno ya urbanizado.
</details>

<details>
<summary><strong>2. ¿Por qué las VMs tienen mayor overhead que los contenedores?</strong></summary>

**Respuesta**:
Cada VM requiere:
- **SO guest completo** (2-4 GB de RAM solo para el sistema operativo)
- **Kernel independiente** (duplicación de funcionalidad del kernel)
- **Binarios y librerías del SO** (cientos de MB de espacio)
- **Bootloader y servicios del sistema** (tiempo de arranque de minutos)

Los contenedores:
- **Comparten el kernel del host** (no duplicación)
- **Solo empaquetan la aplicación + dependencias** (50-500 MB típico)
- **Sin SO completo** (arranque en segundos)
- **Namespaces para aislamiento** (sin virtualización de hardware)

**Resultado**: VMs consumen 5-10x más recursos que contenedores para la misma aplicación.
</details>

<details>
<summary><strong>3. ¿Qué es "CPU steal time" y qué indica?</strong></summary>

**Respuesta**:
**CPU steal time** es el porcentaje de tiempo que una VM **quiere usar la CPU pero el hipervisor se la asigna a otra VM**.

**Causa**: Sobresuscripción (overcommit) de CPUs físicas. Por ejemplo, 10 VMs con 4 vCPUs cada una (40 vCPUs totales) corriendo en un host con solo 16 CPUs físicas.

**Valores normales**:
- `< 5%`: Aceptable, buena distribución de recursos
- `5-10%`: Moderado, considerar optimización
- `> 10%`: Alto, problemas de rendimiento, requiere acción

**Cómo verificar en Linux**:
```bash
top  # Ver columna "%st"
vmstat 1  # Ver columna "st"
```

**Solución**: Reducir número de VMs en el host o aumentar CPUs físicas.
</details>

### Preguntas Técnicas

<details>
<summary><strong>4. ¿Cómo crearías una VM en Azure con Azure CLI que tenga 4 GB de RAM y exponga el puerto 80?</strong></summary>

**Respuesta**:
```bash
# 1. Crear grupo de recursos
az group create \
  --name my-web-rg \
  --location eastus

# 2. Crear VM con size que tenga ~4GB RAM (Standard_B2s = 2 vCPU, 4GB RAM)
az vm create \
  --resource-group my-web-rg \
  --name webserver-vm \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# 3. Abrir puerto 80 para HTTP
az vm open-port \
  --resource-group my-web-rg \
  --name webserver-vm \
  --port 80 \
  --priority 1001

# 4. Obtener IP pública
az vm list-ip-addresses \
  --resource-group my-web-rg \
  --name webserver-vm \
  --output table
```

**Nota**: Para exactamente 4GB de RAM, usar `--size Standard_B2s` (2 vCPU, 4GB) o `Standard_D2s_v3` (2 vCPU, 8GB).
</details>

<details>
<summary><strong>5. Una VM está usando 100% de memoria y empieza a hacer swap. ¿Qué comandos usarías para diagnosticar el problema?</strong></summary>

**Respuesta**:
```bash
# 1. Ver uso de memoria y swap
free -h
# Si "Swap used" es alto (>50%), hay problema

# 2. Ver qué procesos consumen más memoria
ps aux --sort=-%mem | head -20
# Top 20 procesos por uso de memoria

# 3. Ver memoria detallada
cat /proc/meminfo | grep -E 'MemTotal|MemAvailable|SwapTotal|SwapFree'

# 4. Monitoreo en tiempo real
htop  # Vista interactiva (instalar si no existe: sudo apt install htop)
# Ordenar por memoria: Presionar F6 → Seleccionar MEM%

# 5. Ver estadísticas de swap
vmstat 1 10  # Estadísticas cada 1 segundo, 10 veces
# Columna "si" (swap in) y "so" (swap out) - valores altos indican problema

# 6. Ver qué está causando el uso de swap
for file in /proc/*/status ; do 
  awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file
done | sort -k 2 -n -r | head -10
```

**Solución**: Aumentar RAM de la VM o identificar/terminar procesos problemáticos.
</details>

<details>
<summary><strong>6. ¿Cómo verificarías si una VM tiene acceso a Internet y puede resolver DNS?</strong></summary>

**Respuesta**:
```bash
# 1. Verificar conectividad básica (ICMP)
ping -c 4 8.8.8.8
# Si funciona: red física OK

# 2. Verificar resolución DNS
nslookup google.com
# O alternativamente:
dig google.com
host google.com

# 3. Verificar servidores DNS configurados
cat /etc/resolv.conf
# Debe mostrar nameservers

# 4. Probar conectividad HTTP
curl -I https://www.google.com
# Debe retornar "HTTP/2 200"

# 5. Ver rutas de red
ip route show
# Debe haber una ruta default via <gateway>

# 6. Ver tabla de enrutamiento
route -n

# 7. Verificar firewall local
sudo iptables -L -n
# O si usa ufw:
sudo ufw status

# 8. Traceroute para ver el path de red
traceroute google.com
# Ver en qué hop falla si hay problema
```

**Diagnóstico**:
- Ping funciona pero DNS no → Problema de DNS servers
- DNS funciona pero HTTP no → Problema de firewall/proxy
- Nada funciona → Problema de routing/gateway
</details>

### Preguntas de Troubleshooting

<details>
<summary><strong>7. Tienes 5 VMs en un host. Una de ellas empieza a consumir 100% CPU y las otras se vuelven lentas. ¿Por qué pasa esto y cómo lo solucionas?</strong></summary>

**Respuesta**:

**Por qué pasa**:
- La VM problemática está consumiendo toda la CPU física disponible
- El hipervisor distribuye CPU compartida entre todas las VMs (sin límites configurados)
- Las otras VMs experimentan "CPU steal time" alto esperando por recursos
- El hipervisor hace **sobresuscripción (overcommit)** de CPU

**Cómo diagnosticar**:
```bash
# En cada VM afectada
top
# Ver columna %st (steal time) - valores >10% indican problema

vmstat 1
# Columna "st" mostrará valores altos
```

**Soluciones**:

1. **Identificar proceso problemático en VM culpable**:
   ```bash
   top  # Ver qué proceso consume 100% CPU
   ps aux --sort=-%cpu | head
   ```

2. **Limitar CPU de la VM problemática** (nivel hipervisor):
   - ESXi: Configurar CPU limit/reservation
   - KVM: Usar cgroups para limitar CPU
   - Azure: No aplica (aislamiento garantizado por tamaño de VM)

3. **Balancear carga**: Migrar algunas VMs a otro host

4. **Escalar verticalmente**: Aumentar CPUs físicas del host

5. **Si es Azure**: Cada VM tiene recursos garantizados según su tamaño, este problema no debería ocurrir (VMs están aisladas)
</details>

<details>
<summary><strong>8. Creaste un snapshot de una VM mientras corría una base de datos. Al restaurarlo, la base de datos está corrupta. ¿Qué salió mal y cómo prevenirlo?</strong></summary>

**Respuesta**:

**Qué salió mal**:
- El snapshot se tomó con la base de datos **escribiendo activamente a disco**
- Datos en memoria (buffers) no se sincronizaron (flushed) a disco
- El snapshot capturó un estado **inconsistente** del filesystem
- Al restaurar, archivos de DB quedaron en estado intermedio → corrupción

**Analogía**: Es como tomar una foto de alguien en movimiento (imagen borrosa).

**Cómo prevenirlo - Método correcto**:

**Opción 1: Application-Consistent Snapshot** (MEJOR)
```bash
# 1. Poner la DB en modo backup/quiesce
mysql> FLUSH TABLES WITH READ LOCK;

# 2. Tomar el snapshot (en Azure CLI)
az snapshot create \
  --resource-group my-rg \
  --name db-snapshot-$(date +%Y%m%d) \
  --source db-vm-disk

# 3. Liberar lock
mysql> UNLOCK TABLES;
```

**Opción 2: Detener servicios antes del snapshot**
```bash
# 1. Detener base de datos
sudo systemctl stop mysql

# 2. Sync filesystem
sync

# 3. Tomar snapshot
az snapshot create ...

# 4. Reiniciar servicio
sudo systemctl start mysql
```

**Opción 3: VM Shutdown Snapshot** (MÁS SEGURO)
```bash
# 1. Apagar VM completamente
az vm deallocate --resource-group my-rg --name db-vm

# 2. Tomar snapshot
az snapshot create ...

# 3. Reiniciar VM
az vm start --resource-group my-rg --name db-vm
```

**Opción 4: Usar herramientas de backup nativas**
- MySQL: `mysqldump` o Percona XtraBackup
- PostgreSQL: `pg_dump` / `pg_basebackup`
- Snapshots de VM como último recurso
</details>

### Preguntas Profesionales

<details>
<summary><strong>9. Tu empresa tiene 50 servidores físicos con 10-20% de uso de CPU. ¿Cómo justificarías un proyecto de virtualización al CFO?</strong></summary>

**Respuesta - Argumento de negocio**:

**Situación actual (sin virtualización)**:
```
50 servidores físicos × $5,000/servidor = $250,000 en hardware
Consumo energético: 50 servidores × 500W × 24h × 365 días = 219,000 kWh/año
Costo energía: 219,000 kWh × $0.12/kWh = $26,280/año
Espacio datacenter: 50 racks × $500/mes = $300,000/año (5 años)
TOTAL: ~$576,280 en 5 años (sin contar mantenimiento, refrigeración)
```

**Con virtualización (10:1 ratio)**:
```
5 servidores físicos potentes × $15,000 = $75,000 en hardware
Licencias hipervisor: 5 × $3,000 = $15,000
Consumo energético: 5 servidores × 800W = 35,040 kWh/año = $4,205/año
Espacio: 5 racks × $500/mes = $30,000 en 5 años
TOTAL: ~$119,205 en 5 años
```

**ROI = $576,280 - $119,205 = $457,075 ahorrados en 5 años (79% reducción)**

**Beneficios adicionales**:
- ✅ Provisión de nuevos servidores en minutos vs. semanas
- ✅ Alta disponibilidad con vMotion/Live Migration
- ✅ Snapshots para recuperación ante desastres
- ✅ Consolidación de recursos subutilizados
- ✅ Reducción de complejidad operacional

**Riesgos mitigables**:
- Single point of failure → HA clustering de hipervisores
- Licenciamiento → Open source (KVM, Proxmox)
</details>

<details>
<summary><strong>10. ¿Cuándo recomendarías usar VMs en lugar de contenedores?</strong></summary>

**Respuesta - Casos de uso para VMs**:

**1. Aplicaciones Windows con GUI**
- Aplicaciones legacy que requieren escritorio Windows completo
- Apps que no tienen versión containerizada
- Ejemplo: Software empresarial antiguo, Citrix, RDS

**2. Aislamiento de seguridad extremo**
- Workloads de diferentes clientes (multi-tenancy)
- Regulaciones que exigen aislamiento a nivel de kernel
- Ejemplo: Entornos financieros, healthcare con HIPAA

**3. Diferentes sistemas operativos**
- Necesitas correr Linux, Windows, BSD en el mismo host
- Contenedores comparten el kernel del host (solo Linux en Linux)

**4. Aplicaciones con kernels personalizados**
- Apps que necesitan módulos de kernel específicos
- Software que modifica parámetros del kernel
- Ejemplo: Firewalls, VPNs, appliances de red

**5. Lift-and-shift de on-premises a cloud**
- Migración rápida sin refactorizar aplicación
- Mantener configuraciones exactas del entorno actual
- Ejemplo: Migración de VMware on-prem a Azure

**6. Workloads con licenciamiento por núcleo**
- Oracle Database, SQL Server Enterprise
- Licencias se basan en vCPUs físicos de la VM
- Contenedores complican el conteo de licencias

**Casos donde los contenedores son mejores**:
- ✅ Microservicios cloud-native
- ✅ Aplicaciones stateless
- ✅ CI/CD con despliegues frecuentes
- ✅ Auto-scaling horizontal
- ✅ Desarrollo local + producción idéntica

**Enfoque moderno**: Muchas empresas usan **ambos** en paralelo:
- VMs para workloads legacy y bases de datos
- Contenedores + Kubernetes para apps nuevas
</details>

---

## 🎓 8. Para Certificaciones

### Relevancia en CKA (Certified Kubernetes Administrator)

**Cobertura en el examen**: ~5-10%

**Temas relacionados**:
- **Node Components**: Los Workers de Kubernetes corren frecuentemente como VMs (EC2, Azure VMs, GCE)
- **KVM**: Entender que KVM es el hipervisor usado en la mayoría de clouds públicos
- **Networking**: Conceptos de red virtual se aplican a Kubernetes (CNI, vSwitches)
- **Resource Management**: CPU/Memory limits en Pods vs. VMs

**Preguntas típicas**:
> "¿Por qué Kubernetes usa contenedores en lugar de VMs para cada Pod?"

**Respuesta esperada**: 
- Overhead mínimo (sin SO guest completo)
- Arranque instantáneo (segundos vs. minutos)
- Alta densidad (100+ Pods por Node)
- Portabilidad y consistencia (mismo contenedor dev → prod)

### Relevancia en VMware VCP / Microsoft MCSA

**Cobertura**: ~80-90% del contenido de este módulo

**Enfoque adicional para estas certificaciones**:
- Gestión avanzada de recursos (reservations, limits, shares)
- Alta disponibilidad (vMotion, Live Migration, clustering)
- Storage avanzado (vSAN, Storage Spaces, RAID)
- Networking avanzado (VLANs, distributed switches)

### Comandos críticos para memorizar

```bash
# Azure VM management (CKA context)
az vm create / start / stop / delete / resize

# Linux system monitoring (ambas certificaciones)
top / htop / free / df / du / vmstat / iostat

# Networking (CKA principalmente)
ip addr / netstat / ss / nslookup / traceroute

# Resource verification
lscpu / nproc / cat /proc/meminfo / lsblk
```

---

## 📚 9. Recursos Adicionales

### Documentación Oficial

- **[Red Hat - ¿Qué es la virtualización?](https://www.redhat.com/es/topics/virtualization/what-is-virtualization)**
- **[Red Hat - ¿Qué es KVM?](https://www.redhat.com/es/topics/virtualization/what-is-KVM)**
- **[Azure Virtual Machines Docs](https://docs.microsoft.com/en-us/azure/virtual-machines/)**
- **[VMware vSphere Documentation](https://docs.vmware.com/en/VMware-vSphere/)**
- **[Microsoft Hyper-V Docs](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/)**

### Herramientas y Plataformas

- **[VirtualBox](https://www.virtualbox.org/)** - Hipervisor tipo 2 gratuito (ideal para prácticas locales)
- **[Proxmox VE](https://www.proxmox.com/en/proxmox-ve)** - Plataforma open source de virtualización
- **[Red Hat OpenShift Virtualization](https://www.redhat.com/es/technologies/cloud-computing/openshift/virtualization)** - VMs en Kubernetes
- **[Azure Migrate](https://azure.microsoft.com/services/azure-migrate/)** - Herramienta de migración a cloud

### Tutoriales y Labs

- **[Microsoft Learn - Azure VMs](https://docs.microsoft.com/learn/modules/intro-to-azure-virtual-machines/)**
- **[KVM Tutorials](https://www.linux-kvm.org/page/HOWTO)**
- **[Azure Free Account](https://azure.microsoft.com/free/)** - $200 créditos para practicar

---

## 🎯 10. Siguiente Paso

**¿Terminaste este módulo?** ¡Excelente! Ahora estás listo para:

➡️ **[Módulo 2: Docker y Contenerización](../modulo-2-docker/README.md)**

**Lo que aprenderás en el Módulo 2**:
- Por qué los contenedores son la evolución de las VMs
- Cómo Docker empaqueta aplicaciones de manera portable
- Diferencias técnicas: namespaces, cgroups, union filesystems
- Dockerfiles, imágenes, registries
- Laboratorios prácticos con Docker

**Estadísticas del Módulo 1**:
- ⏱️ **Duración típica**: 4-5 horas (principiante) | 3 horas (intermedio)
- 📄 **Páginas de teoría**: ~30 páginas
- 🧪 **Laboratorios**: 3 labs (Azure Portal, Azure CLI, VirtualBox)
- 📊 **Conceptos clave**: 25+ términos técnicos
- ❓ **Preguntas de repaso**: 10 preguntas con respuestas detalladas

---

**✅ Has completado el módulo de Virtualización - ¡Bien hecho!**

*Prepárate para aprender cómo Docker revolucionó el despliegue de aplicaciones con contenedores ligeros.*
