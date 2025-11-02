# 🧭 Módulo 1: Virtualización Tradicional – Fundamentos de la Infraestructura Moderna

**Duración**: 3 horas  
**Modalidad**: Teórico – Práctico

## 🎯 Objetivo del módulo

Comprender qué es la virtualización, cómo funciona, sus principales componentes, ventajas, desventajas y cómo sentó las bases para la contenerización y Kubernetes.

---

## 🧩 1. Contexto histórico

Antes de la virtualización, cada aplicación requería un servidor físico dedicado.
Esto generaba:

- **Alto costo de hardware**: Un servidor por aplicación
- **Espacio físico y consumo energético elevados**: Centros de datos enormes
- **Desperdicio de recursos**: CPU, RAM infrautilizados la mayor parte del tiempo
- **Dificultad de escalamiento**: Agregar nueva capacidad requería hardware físico

Con la virtualización surgió una solución: **compartir los recursos de un mismo servidor físico entre varios sistemas operativos**, aislados entre sí.

**👉 Ejemplo práctico:**
En un servidor con 64 GB de RAM y 16 núcleos, se pueden ejecutar 4 máquinas virtuales (VMs) con 16 GB y 4 núcleos cada una, compartiendo el mismo hardware.

---

## ⚙️ 2. ¿Qué es la virtualización?

La **virtualización** es una tecnología que permite ejecutar múltiples entornos operativos en un mismo equipo físico, aislados entre sí, como si fueran servidores independientes.
Cada entorno se denomina **máquina virtual (VM)**.

### Componentes principales:

- **Servidor físico (Host)**: Equipo que provee los recursos físicos
- **Hipervisor**: Software que gestiona las VMs y reparte los recursos
- **Máquinas virtuales (Guests)**: Entornos virtuales con su propio SO, CPU, RAM, disco y red

### 📘 Tipos de hipervisores:

| Tipo | Descripción | Ejemplos |
|------|-------------|----------|
| **Tipo 1 (Bare-metal)** | Se ejecuta directamente sobre hardware | VMware ESXi, Microsoft Hyper-V Server, KVM |
| **Tipo 2 (Hosted)** | Se ejecuta sobre un SO existente | VirtualBox, VMware Workstation |

---

## 🧱 3. Arquitectura de virtualización

```
┌────────────────────────────┐
│ Aplicaciones (VM1, VM2...) │
├────────────────────────────┤
│ Sistemas Operativos Guest  │
├────────────────────────────┤
│ Hipervisor (ESXi / KVM)    │
├────────────────────────────┤
│ Hardware Físico (CPU, RAM) │
└────────────────────────────┘
```

**Explicación:**
- El **hipervisor** crea y gestiona las VMs, asignando recursos físicos de manera virtual
- Cada VM se comporta como un servidor independiente, aunque comparta el mismo hardware
- Las VMs están completamente aisladas entre sí

---

## 🖥️ 4. Tipos de virtualización

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| **Virtualización de servidores** | Ejecutar varias VMs en un mismo servidor físico | VMware ESXi, KVM |
| **Virtualización de red** | Crear redes virtuales internas o aisladas | vSwitch, Hyper-V Network |
| **Virtualización de almacenamiento** | Abstraer discos físicos en volúmenes virtuales | vSAN, LVM |
| **Virtualización de escritorio (VDI)** | Entornos de escritorio remoto centralizados | Citrix, VMware Horizon |

---

## ⚖️ 5. Ventajas y desventajas

### ✅ Ventajas

- **Mejor aprovechamiento de hardware**: Un servidor puede hospedar múltiples VMs
- **Reducción de costos y espacio físico**: Menos servidores físicos necesarios
- **Aislamiento entre entornos**: Fallos en una VM no afectan otras
- **Clonación y migración sencilla**: Copiar VMs entre servidores
- **Ideal para laboratorios y entornos de prueba**: Crear/destruir entornos rápidamente

### ❌ Desventajas

- **Mayor consumo de recursos por VM**: Cada VM necesita un SO completo
- **Arranque más lento que los contenedores**: Tiempo de boot del SO guest
- **Dependencia de licencias**: Costos de licenciamiento según hipervisor
- **Complejidad en escalabilidad a gran escala**: Gestión de muchas VMs

---

## 🔬 6. Laboratorio práctico (Azure)

**Objetivo**: Crear una máquina virtual en Azure y comprender el funcionamiento básico de la virtualización.

### 🔧 Pasos:

1. **Inicia sesión en el Portal de Azure** 
   - Navega a [portal.azure.com](https://portal.azure.com)

2. **Crear la máquina virtual**
   - En el buscador, selecciona "Máquinas Virtuales" → "Crear"
   - Configura:
     - **Imagen**: Ubuntu Server 22.04 LTS
     - **Tamaño**: Standard_B1s (1 vCPU, 1 GB RAM)
     - **Usuario y clave**: Crear usuario con autenticación por clave SSH
     - **Red virtual**: Automática

3. **Conectarse a la VM**
   ```bash
   ssh usuario@<IP Pública>
   ```

4. **Verificar recursos del sistema**
   ```bash
   # Ver información de CPU
   lscpu
   
   # Ver información de memoria
   free -h
   
   # Ver información de disco
   df -h
   
   # Ver procesos en ejecución
   top
   ```

5. **Gestión de la VM**
   - Detén y reinicia la VM para observar cómo se gestionan los recursos virtuales
   - Observa los tiempos de arranque y parada

**📘 Reflexión**: ¿Qué diferencias encuentras con tu sistema local? ¿Cómo se comporta el hardware virtual?

### 📋 [Ver laboratorio completo con comandos Azure CLI](./laboratorios/lab-azure-vm.md)

---

## 🔄 7. De la virtualización a los contenedores

La virtualización fue el **primer paso hacia la infraestructura ágil**.
Sin embargo, al crecer las necesidades de despliegue, surgieron nuevos desafíos:

- **Tiempo de arranque de VMs alto**: Arrancar un SO completo toma minutos
- **Uso excesivo de recursos**: Cada VM necesita recursos para el SO guest
- **Complejidad en actualizaciones y dependencias**: Gestionar múltiples SOs
- **Escalabilidad limitada**: Dificultad para escalar aplicaciones rápidamente

Para resolver esto nació la **contenerización**, representada por herramientas como Docker, donde los contenedores comparten el mismo kernel del sistema operativo y son mucho más livianos.

**👉 Este será el tema del próximo módulo:**
[Módulo 2: Contenerización con Docker](../modulo-2-docker/README.md)

---

## 📚 8. Fuentes y referencias técnicas

- [Microsoft Learn – Introducción a la Virtualización](https://docs.microsoft.com/es-es/learn/modules/intro-to-azure-virtual-machines/)
- [VMware Docs – What is Virtualization](https://www.vmware.com/topics/glossary/content/virtualization.html)
- [Red Hat – Virtualization Overview](https://www.redhat.com/es/topics/virtualization/what-is-virtualization)
- [Azure Virtual Machines Documentation](https://docs.microsoft.com/es-es/azure/virtual-machines/)
- [KVM Documentation](https://www.linux-kvm.org/page/Documents)

---

## 🧠 Resultado esperado

Al finalizar este módulo, el estudiante podrá:

- ✅ Comprender qué es la virtualización y cómo funciona
- ✅ Identificar los componentes clave: host, hipervisor y VM
- ✅ Diferenciar entre hipervisores tipo 1 y tipo 2
- ✅ Implementar una máquina virtual básica en Azure
- ✅ Entender las limitaciones que dieron origen a los contenedores

---

## 📋 Checkpoint del Módulo

Antes de continuar al Módulo 2, asegúrate de poder:

- [ ] Explicar qué es la virtualización y sus componentes
- [ ] Crear una VM en Azure Portal
- [ ] Conectarte por SSH y verificar recursos del sistema
- [ ] Describir 3 ventajas y 3 desventajas de la virtualización
- [ ] Justificar por qué surgieron los contenedores

---

## ⏭️ Navegación

- **⬅️ [Área 1 - Inicio](../README.md)**
- **➡️ [Módulo 2 - Docker](../modulo-2-docker/README.md)**
- **🔧 [Laboratorios](./laboratorios/)**

---

**Tiempo estimado de completado**: 3 horas  
**Nivel de dificultad**: Básico  
**Prerequisitos**: Conocimientos básicos de sistemas operativos