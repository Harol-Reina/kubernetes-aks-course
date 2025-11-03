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

La **virtualización** es una tecnología que permite crear distintos entornos virtuales simulados desde una sola máquina física. A través de este proceso, los especialistas en TI pueden utilizar sus inversiones anteriores y optimizar la capacidad total de la máquina física con la distribución de los recursos que tradicionalmente están vinculados al hardware en muchos entornos diferentes.

La virtualización permite que **múltiples sistemas operativos compartan el mismo hardware físico**, mejora el uso de los recursos, reduce los costos asociados al mantenimiento físico y aumenta la seguridad a través de sistemas aislados.

### **🔍 Definición técnica:**
Una **máquina virtual (VM)** es un entorno informático que funciona como sistema aislado con su propia CPU, sistema operativo, memoria, interfaz de red y almacenamiento, y que se crea a partir de un grupo de recursos de hardware. 

### **📦 Componentes principales:**

- **Servidor físico (Host)**: Equipo que provee los recursos físicos (CPU, RAM, almacenamiento, red)
- **Hipervisor (VMM)**: Software que gestiona las VMs y distribuye los recursos físicos
- **Máquinas virtuales (Guests)**: Entornos virtuales con su propio SO independiente

### **🔄 Funcionamiento:**
Cuando el entorno virtual está en ejecución y un usuario o un programa emiten una instrucción que requiere recursos adicionales del entorno físico, el hipervisor transmite la solicitud al sistema físico y almacena los cambios en la memoria caché. Todo esto sucede prácticamente a la misma velocidad que habría si este proceso se realizara dentro de la máquina física.

### 📘 Tipos de hipervisores:

| Tipo | Descripción | Características | Ejemplos |
|------|-------------|----------------|----------|
| **Tipo 1 (Bare-metal)** | Se ejecuta directamente sobre hardware físico | • Mayor rendimiento<br>• Menor latencia<br>• Ideal para servidores empresariales | VMware ESXi<br>Microsoft Hyper-V Server<br>KVM<br>Citrix XenServer |
| **Tipo 2 (Hosted)** | Se ejecuta sobre un SO existente como aplicación | • Fácil instalación<br>• Ideal para desarrollo<br>• Menor rendimiento | VirtualBox<br>VMware Workstation<br>Parallels Desktop |

### **🔐 KVM (Kernel-based Virtual Machine):**
La **máquina virtual basada en el kernel (KVM)** es un hipervisor open source de tipo 1 que forma parte de las distribuciones de Linux modernas. Las máquinas virtuales que se ejecutan con la KVM obtienen los beneficios de las funciones de rendimiento de Linux, y los usuarios pueden aprovechar el control detallado que brinda el sistema operativo.

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

### **🔀 Clasificación por recursos virtualizados:**

| Tipo | Descripción | Casos de uso | Ejemplos |
|------|-------------|--------------|----------|
| **Virtualización de servidores** | Partición de un servidor físico para ejecutar múltiples VMs | Consolidación de servidores<br>Entornos de desarrollo/pruebas | VMware ESXi<br>KVM<br>Hyper-V |
| **Virtualización de escritorios (VDI)** | Entornos de escritorio remoto centralizados | Trabajo remoto seguro<br>Gestión centralizada | Citrix XenDesktop<br>VMware Horizon<br>Microsoft RDS |
| **Virtualización de red** | Crear redes virtuales independientes del hardware físico | Segmentación de redes<br>Micro-segmentación | vSwitch<br>Hyper-V Network<br>NSX |
| **Virtualización de almacenamiento** | Abstracción de discos físicos en volúmenes lógicos | Gestión unificada de storage<br>Optimización de capacidad | vSAN<br>LVM<br>Storage Spaces |
| **Virtualización de datos** | Federación de datos desde múltiples fuentes | Integración de datos empresariales<br>Data lakes virtuales | Red Hat JBoss Data Virtualization<br>Denodo |
| **Virtualización de aplicaciones** | Aplicaciones ejecutándose fuera de su SO original | Compatibilidad legacy<br>Distribución de software | VMware ThinApp<br>Microsoft App-V |

### **🌐 Virtualización de Funciones de Red (NFV):**
La **virtualización de las funciones de red (NFV)** que utilizan los proveedores de servicios de telecomunicación separa las funciones clave de una red (como los servicios de directorio, el uso compartido de archivos y la configuración de IP) para distribuirlas entre los entornos. 

**Beneficios de NFV:**
- Reduce la cantidad de elementos físicos (switches, routers, cables)
- Permite crear múltiples redes independientes por software
- Mayor flexibilidad en la gestión de servicios de red
- Reduce costos operacionales y de infraestructura

### **📱 Virtualización de aplicaciones vs. contenedores:**
La virtualización de aplicaciones brinda una manera de implementarlas y utilizarlas poniéndolas a disposición fuera del sistema operativo en el que se instalaron originalmente. Se diferencia de la virtualización de escritorios porque las aplicaciones se ejecutan virtualmente, mientras que el sistema operativo del dispositivo del usuario se ejecuta de manera tradicional.

---

## ⚖️ 5. Ventajas y desventajas

### ✅ **Ventajas de la virtualización**

#### **🏢 Consolidación de servidores:**
Al virtualizar los servidores, se pueden colocar muchos servidores virtuales en cada servidor físico para mejorar el uso del hardware. La consolidación permite mejorar el uso de los recursos cuando estos se asignan donde son necesarios, ya que una máquina host se puede dividir en varias máquinas virtuales.

#### **💰 Ahorro de costos:**
Un mejor uso del hardware puede implicar ahorros en los recursos físicos adicionales, como las unidades de disco duro, así como una reducción en el uso de energía, espacio y sistema de enfriamiento en el centro de datos.

#### **🔐 Entornos aislados:**
Como las máquinas virtuales están separadas del resto del sistema, no interfieren en los procesos que se ejecutan en el hardware host, por lo que representan una buena opción para probar nuevas aplicaciones o configurar un entorno de producción.

#### **🚀 Migración de aplicaciones más rápida:**
Los administradores ya no tienen que esperar a que cada aplicación se certifique en un hardware nuevo. Como las configuraciones de las máquinas virtuales se definen por software, estas se pueden crear, eliminar, clonar y migrar rápidamente. Además, es posible controlarlas de forma remota y automatizar sus procesos de gestión.

#### **⚡ Entornos eficientes:**
Durante las pruebas de regresión, los equipos pueden crear o copiar un entorno de pruebas, por lo cual no se requiere utilizar hardware de prueba específico ni servidores de desarrollo innecesarios. Si el personal cuenta con la capacitación y los conocimientos adecuados, podrá optimizar estos entornos para obtener más funciones y densidad.

#### **🛡️ Recuperación ante desastres:**
Las máquinas virtuales ofrecen más opciones de recuperación ante desastres, ya que permiten la tolerancia a fallos que antes solo se podía lograr con un sistema de hardware adicional. Las opciones de recuperación ante desastres reducen el tiempo de reparación y configuración del servidor afectado, lo que permite lograr una mayor capacidad de adaptación.

### ❌ **Desventajas y limitaciones**

#### **📈 Mayor consumo de recursos por VM:**
Cada VM necesita un SO completo (2+ GB RAM, espacio en disco), lo que genera overhead significativo comparado con aplicaciones nativas.

#### **⏱️ Arranque más lento:**
Tiempo de boot del SO guest (minutos) versus aplicaciones nativas o contenedores (segundos).

#### **💳 Dependencia de licencias:**
Costos de licenciamiento según hipervisor y sistemas operativos guest (Windows, Red Hat Enterprise Linux, etc.).

#### **🔧 Complejidad en escalabilidad:**
Gestión de muchas VMs se vuelve compleja sin herramientas de automatización y orquestación apropiadas.

#### **🔌 Dependencia del hipervisor:**
Fallas en el hipervisor pueden afectar todas las VMs que ejecuta, creando un punto único de falla.

### **📊 Comparación de eficiencia:**

| Métrica | Físico Tradicional | Virtualización | Contenedores |
|---------|-------------------|----------------|--------------|
| **Densidad** | 1 app/servidor | 3-10 apps/servidor | 100+ apps/servidor |
| **Tiempo de arranque** | Minutos | Minutos | Segundos |
| **Uso de memoria** | 100% dedicado | 70-80% efectivo | 90-95% efectivo |
| **Aislamiento** | Completo | Completo | Proceso-nivel |
| **Overhead de SO** | Ninguno | Alto | Mínimo |

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

La virtualización fue el **primer paso hacia la infraestructura ágil** y sentó las bases para la computación en la nube moderna. Sin embargo, al crecer las necesidades de despliegue y escalabilidad, surgieron nuevos desafíos que llevaron al desarrollo de tecnologías complementarias.

### **💡 Virtualización vs. Organización en contenedores:**

La virtualización y la **organización en contenedores** son dos enfoques para los entornos informáticos que aíslan los elementos de la TI del resto del sistema físico. Sin embargo, cada uno funciona de manera distinta:

#### **🖥️ Virtualización tradicional:**
- Las máquinas virtuales ejecutan su **propio sistema operativo** completo
- Cada VM funciona como un servidor independiente con recursos dedicados
- **Aislamiento completo** a nivel de hardware virtualizado
- **Overhead significativo** por cada SO guest (2-4 GB RAM mínimo)

#### **📦 Organización en contenedores:**
- Los contenedores **comparten el sistema operativo host** y su kernel
- Las aplicaciones se empaquetan con sus dependencias en un contenedor portable
- **Aislamiento a nivel de proceso** usando namespaces y cgroups de Linux
- **Overhead mínimo** - solo las librerías y binarios necesarios

### **🔧 Problemas que llevaron a los contenedores:**

#### **❌ Limitaciones persistentes de las VMs:**
- **Tiempo de arranque alto**: Arrancar un SO completo toma 1-5 minutos
- **Uso excesivo de recursos**: Cada VM necesita 2+ GB solo para el SO guest
- **Complejidad en actualizaciones**: Gestionar múltiples SOs con parches y actualizaciones
- **Escalabilidad limitada**: Difícil escalar aplicaciones rápidamente (microservicios)
- **Densidad baja**: Máximo 10-20 VMs por servidor físico típico

#### **✅ Soluciones que ofrecen los contenedores:**
- **Arranque instantáneo**: Segundos versus minutos
- **Granularidad**: Desde 50MB hasta lo que necesites
- **Escalabilidad masiva**: Miles de contenedores por servidor
- **DevOps optimizado**: Pipelines CI/CD más eficientes
- **Microservicios**: Cada servicio en su propio contenedor

### **🌐 Relación con Cloud Computing:**

Tanto la virtualización como la organización en contenedores son tecnologías que **posibilitan el cloud computing**. Las nubes públicas y privadas virtualizan los recursos en grupos compartidos, agregan una capa de control administrativo y distribuyen esos recursos con funciones de autoservicio automatizadas.

### **🔗 Integración moderna:**
Plataformas como **Red Hat OpenShift** incluyen funciones que permiten migrar las máquinas virtuales y gestionarlas junto con los contenedores para lograr un control máximo, ofreciendo lo mejor de ambos mundos.

**👉 Los contenedores representan la evolución natural de la virtualización:**
[Módulo 2: Contenerización con Docker](../modulo-2-docker/README.md)

---

## 🚀 8. Migración y modernización de VMs

### **📦 ¿En qué consiste la migración de máquinas virtuales?**

La migración de máquinas virtuales implica la transferencia de una máquina virtual desde un host o una plataforma hacia otra. El objetivo de este proceso es mejorar el uso de los recursos, optimizar el rendimiento, aumentar la flexibilidad y mejorar la capacidad de ajuste.

### **🔄 Tipos de migración:**

#### **🔴 Migración en frío:**
- La máquina virtual se **apaga completamente** durante el proceso
- Se transfiere desde el host de origen al host de destino
- Suele utilizarse cuando se traslada **entre plataformas diferentes** o regiones
- **Downtime**: Varios minutos a horas dependiendo del tamaño

#### **🟢 Migración en vivo:**
- La máquina virtual **continúa ejecutándose** en el host de origen
- Las páginas de memoria se transfieren al host de destino progresivamente
- Un evento de interrupción programado permite que la VM aparente funcionar **sin interrupciones**
- **Downtime**: Segundos (imperceptible para usuarios)

### **🌐 Estrategias de modernización:**

#### **💼 Migración tradicional (Lift & Shift):**
- Mover VMs existentes a **plataformas en la nube** (Azure, AWS, Google Cloud)
- Mantener la misma arquitectura de aplicación
- **Beneficios inmediatos**: Reducción de costos de hardware, mayor disponibilidad

#### **🔄 Refactorización (Cloudify):**
- Optimizar aplicaciones para **aprovechar servicios nativos de nube**
- Implementar auto-escalado, load balancing, servicios gestionados
- **Mayor beneficio a largo plazo**: Elasticidad, reducción de costos operacionales

#### **📦 Contenerización (Modernize):**
- Migrar aplicaciones de VMs a **contenedores y Kubernetes**
- Descomponer monolitos en microservicios
- **Máximo beneficio**: Agilidad, escalabilidad, eficiencia de recursos

### **🛠️ Herramientas de migración empresarial:**

| Herramienta | Origen | Destino | Características |
|-------------|--------|---------|----------------|
| **Azure Migrate** | On-premises VMs | Azure | Assessment, dependency mapping, cost estimation |
| **AWS Migration Hub** | VMware, Hyper-V | AWS | Server discovery, migration tracking |
| **Red Hat Migration Toolkit** | VMware | OpenShift | Automated VM-to-container migration |
| **VMware HCX** | vSphere | Cloud providers | Live migration, network extension |

### **📈 Modernización gradual:**

```
Tradicional → Virtualización → Cloud VMs → Containers → Serverless
    ↓              ↓              ↓           ↓          ↓
  Hardware    Consolidación   Elasticidad   Agilidad   Zero-ops
```

La clave está en **modernizar gradualmente** según las necesidades del negocio, no en una migración masiva que pueda generar riesgos operacionales.

---

## 📚 9. Fuentes y referencias técnicas

### **📖 Fuentes principales:**
- **[Red Hat - ¿Qué es la virtualización?](https://www.redhat.com/es/topics/virtualization/what-is-virtualization)** - Documentación oficial y completa
- **[Red Hat - ¿Qué es KVM?](https://www.redhat.com/es/topics/virtualization/what-is-KVM)** - Tecnología open source de virtualización
- **[Red Hat - Hipervisores](https://www.redhat.com/es/topics/virtualization/what-is-a-hypervisor)** - Tipos y funcionamiento detallado

### **🌐 Documentación técnica oficial:**
- [Microsoft Learn – Introducción a la Virtualización](https://docs.microsoft.com/es-es/learn/modules/intro-to-azure-virtual-machines/)
- [VMware Docs – What is Virtualization](https://www.vmware.com/topics/glossary/content/virtualization.html)
- [Azure Virtual Machines Documentation](https://docs.microsoft.com/es-es/azure/virtual-machines/)
- [KVM Documentation](https://www.linux-kvm.org/page/Documents)

### **🔧 Plataformas y herramientas:**
- **[Red Hat OpenShift Virtualization](https://www.redhat.com/es/technologies/cloud-computing/openshift/virtualization)** - Virtualización en Kubernetes
- **[VMware vSphere](https://www.vmware.com/products/vsphere.html)** - Plataforma empresarial de virtualización
- **[Microsoft Hyper-V](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/)** - Hipervisor de Windows Server
- **[Proxmox VE](https://www.proxmox.com/en/proxmox-ve)** - Plataforma open source de virtualización

### **📊 Comparaciones y estudios:**
- [Red Hat - Contenedores vs VMs](https://www.redhat.com/es/topics/containers/containers-vs-vms)
- [Red Hat - Migración de VMware](https://www.redhat.com/es/technologies/cloud-computing/openshift/migrate-vmware-to-openshift-virtualization)
- [Red Hat - NFV (Network Function Virtualization)](https://www.redhat.com/es/topics/virtualization/what-is-nfv)

### **🎓 Recursos de aprendizaje:**
- [Red Hat Training - Virtualización](https://www.redhat.com/es/services/training/rh018-virtualization-and-infrastructure-migration-technical-overview)
- [Microsoft Learn - Azure Virtual Machines](https://docs.microsoft.com/en-us/learn/paths/administer-infrastructure-resources-in-azure/)
- [VMware Learning - vSphere Fundamentals](https://www.vmware.com/education-services/certification/vsphere.html)

---

## 🧠 Resultado esperado

Al finalizar este módulo, el estudiante podrá:

### **🎯 Conceptos fundamentales:**
- ✅ Comprender qué es la virtualización y cómo funciona a nivel técnico
- ✅ Explicar el rol del hipervisor en la gestión de recursos
- ✅ Diferenciar entre hipervisores tipo 1 (bare-metal) y tipo 2 (hosted)
- ✅ Identificar los diferentes tipos de virtualización (servidores, red, almacenamiento, aplicaciones)

### **💼 Habilidades prácticas:**
- ✅ Implementar una máquina virtual básica en Azure
- ✅ Conectarse y gestionar VMs remotamente via SSH
- ✅ Monitorear recursos y rendimiento de máquinas virtuales
- ✅ Realizar migración básica de VMs entre hosts

### **📊 Análisis comparativo:**
- ✅ Evaluar ventajas y desventajas de la virtualización vs. hardware dedicado
- ✅ Comparar eficiencia de recursos entre VMs y contenedores
- ✅ Identificar casos de uso apropiados para cada tecnología
- ✅ Justificar por qué surgieron los contenedores como evolución natural

### **🔮 Visión estratégica:**
- ✅ Entender el rol de la virtualización en la evolución hacia cloud computing
- ✅ Planificar estrategias de migración y modernización
- ✅ Reconocer cuándo usar VMs vs. contenedores vs. serverless
- ✅ Prepararse conceptualmente para Kubernetes y orquestación de contenedores

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