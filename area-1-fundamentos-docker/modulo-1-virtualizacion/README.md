# 🧭 Módulo 1: Virtualización Tradicional – Fundamentos de la Infraestructura Moderna

> *"La virtualización revolucionó la infraestructura TI al permitir que múltiples sistemas operativos compartan el mismo hardware, sentando las bases para la computación en la nube y la contenerización moderna."*

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

### 🎓 Objetivos Conceptuales
- Comprender qué es la virtualización y cómo revolucionó la infraestructura TI tradicional
- Explicar el rol del hipervisor en la gestión de recursos físicos virtualizados
- Diferenciar entre hipervisores tipo 1 (bare-metal) y tipo 2 (hosted)
- Identificar los diferentes tipos de virtualización (servidores, red, almacenamiento, aplicaciones, NFV)
- Entender la evolución desde hardware dedicado hasta máquinas virtuales

### 🛠️ Objetivos Técnicos
- Crear y configurar máquinas virtuales en Azure Cloud
- Conectarse remotamente a VMs via SSH y gestionar recursos del sistema
- Monitorear uso de CPU, memoria y almacenamiento en entornos virtualizados
- Implementar laboratorios prácticos con VirtualBox, KVM o Hyper-V
- Realizar migraciones básicas de VMs entre hosts

### 🔍 Objetivos de Troubleshooting
- Diagnosticar problemas comunes de rendimiento en VMs (CPU steal time, memory ballooning)
- Identificar cuando el overhead de virtualización afecta el performance
- Resolver conflictos de recursos entre múltiples VMs en el mismo host
- Troubleshoot conectividad de red en entornos virtualizados
- Analizar métricas de hipervisor para optimizar asignación de recursos

### 🏢 Objetivos Profesionales
- Evaluar ventajas y desventajas de la virtualización vs. hardware dedicado
- Justificar decisiones arquitectónicas: VMs vs. Contenedores vs. Serverless
- Planificar estrategias de consolidación de servidores para reducir costos
- Comprender las bases conceptuales necesarias para trabajar con Kubernetes
- Prepararse para certificaciones como VMware VCP, Microsoft MCSA o Red Hat RHCVA

---

## ✅ Prerrequisitos

### 📚 Conocimientos Previos
- **Sistemas Operativos**: Conocimiento básico de Linux y Windows Server
- **Redes**: Comprensión de IP, DNS, y routing básico
- **Hardware**: Familiaridad con CPU, RAM, almacenamiento y arquitectura x86/x64
- **Línea de comandos**: Comodidad con Bash/PowerShell para administración remota

### 🛠️ Herramientas Necesarias
- **Cuenta Azure**: [Crear cuenta gratuita](https://azure.microsoft.com/free/) (incluye $200 créditos)
- **Cliente SSH**: Terminal nativo (Linux/Mac) o PuTTY (Windows)
- **Navegador web**: Para acceder al Portal de Azure
- **(Opcional) VirtualBox**: Para laboratorios locales sin costos de cloud

### ✔️ Verificación de Prerrequisitos

```bash
# Verificar cliente SSH instalado
ssh -V
# Debe mostrar: OpenSSH_X.X

# Verificar Azure CLI (opcional pero recomendado)
az --version
# Si no está instalado: https://docs.microsoft.com/cli/azure/install-azure-cli

# Verificar conectividad a Azure
ping portal.azure.com
```

**💡 Si no tienes experiencia previa con VMs, este módulo es perfecto para comenzar desde cero.**

---

## 🗺️ Estructura del Módulo

### 📖 Contenido Teórico (60%)
- **Sección 1**: Contexto histórico - Del hardware dedicado a la virtualización (20 min)
- **Sección 2**: ¿Qué es la virtualización? Definición técnica y componentes (25 min)
- **Sección 3**: Arquitectura de virtualización - Capas y funcionamiento (20 min)
- **Sección 4**: Tipos de virtualización - Servidores, red, storage, aplicaciones, NFV (30 min)
- **Sección 5**: Ventajas y desventajas - Análisis comparativo completo (20 min)
- **Sección 7**: De virtualización a contenedores - Limitaciones y evolución (25 min)
- **Sección 8**: Migración y modernización de VMs (20 min)

### 🔬 Contenido Práctico (40%)
- **Sección 6**: Laboratorio Azure - Crear y gestionar VMs en cloud (45 min)
- **Ejercicios guiados**: Conexión SSH, monitoreo de recursos, gestión de ciclo de vida
- **Retos opcionales**: Configurar red entre VMs, instalar servicios, snapshot y restore

### 📊 Distribución de Tiempo

| Actividad | Tiempo | Porcentaje |
|-----------|---------|------------|
| **Teoría y conceptos** | 2 horas 40 min | 60% |
| **Laboratorio práctico** | 1 hora 45 min | 40% |
| **Total módulo** | **4 horas 25 min** | 100% |

**Nota**: Tiempos aproximados. Ajusta según tu ritmo de aprendizaje.

---

## 📚 Rutas de Estudio

### 🟢 Ruta Principiante (4-5 horas)
**Perfil**: Primera vez trabajando con virtualización, sin experiencia previa en VMs.

**Recomendación de estudio**:
1. ✅ **Día 1 (2 horas)**: Leer secciones 1-4 completas (teoría fundamental)
2. ✅ **Día 2 (2 horas)**: Completar laboratorio de Azure guiado paso a paso
3. ✅ **Día 3 (1 hora)**: Revisar RESUMEN-MODULO.md y resolver preguntas de repaso

**🎯 Enfoque**: Entender conceptos sólidos antes de laboratorios. Toma notas mientras lees. No te preocupes si no entiendes todo al principio.

**📌 Tips**:
- Usa VirtualBox localmente si no quieres costos de Azure inicialmente
- Consulta el glosario en [recursos/glossario.md](../../recursos/glossario.md)
- Pide ayuda en foros de la comunidad si te atascas

### 🟡 Ruta Intermedia (3 horas)
**Perfil**: Ya has usado VMs antes (ej: VMware, VirtualBox), quieres formalizar conocimientos.

**Recomendación de estudio**:
1. ✅ **Sesión 1 (1.5 horas)**: Leer secciones 2, 3, 4, 7 (enfocado en arquitectura y tipos)
2. ✅ **Sesión 2 (1.5 horas)**: Laboratorio Azure + explorar Azure CLI para automatización

**🎯 Enfoque**: Profundizar en arquitecturas empresariales y comparativas con contenedores.

**📌 Tips**:
- Experimenta con diferentes tamaños de VM (B1s, B2s, D-series)
- Compara costos de VMs vs. alternativas serverless
- Investiga herramientas como Terraform para IaC

### 🔴 Ruta Certificación (2 horas)
**Perfil**: Preparándote para certificaciones (VCP, MCSA, RHCVA, CKA) o trabajas con infraestructura.

**Recomendación de estudio**:
1. ✅ **Sesión única (2 horas)**: 
   - Revisar sección 4 (Tipos de virtualización) y sección 8 (Migración)
   - Enfocarse en diferencias VMs vs. Contenedores (sección 7)
   - Completar laboratorio en <30 min usando Azure CLI
   - Resolver escenarios de troubleshooting del RESUMEN

**🎯 Enfoque**: Comparaciones técnicas, casos de uso empresariales, troubleshooting avanzado.

**📌 Tips CKA/CKAD**:
- La virtualización aparece en preguntas de contexto sobre Node components
- Entiende por qué Kubernetes usa contenedores sobre VMs
- Conoce cómo funciona KVM (usado en clouds públicos)

---

## 📁 Organización de Recursos

```
modulo-1-virtualizacion/
├── README.md                    # 📄 Este archivo (contenido teórico completo)
├── RESUMEN-MODULO.md            # 📝 Guía rápida de estudio (conceptos + comandos)
├── laboratorios/
│   ├── lab-azure-vm.md          # 🧪 Lab guiado: Crear VM en Azure Portal
│   ├── lab-azure-cli.md         # 🧪 Lab avanzado: Azure CLI automation
│   └── lab-virtualbox.md        # 🧪 Lab alternativo: VirtualBox local
├── ejemplos/
│   ├── azure-vm-template.json   # ⚙️ ARM template para deployment
│   ├── terraform-vm.tf          # ⚙️ Terraform IaC example
│   └── scripts/
│       ├── create-vm.sh         # 🔧 Script automatizado Azure CLI
│       └── monitor-vm.sh        # 🔧 Script para monitoreo de recursos
└── assets/
    └── diagrams/
        ├── architecture.svg     # 📊 Diagrama de arquitectura de virtualización
        └── vm-vs-container.svg  # 📊 Comparativa visual
```

### 📂 Descripción de Recursos

- **README.md**: Teoría completa, explicaciones detalladas, diagramas ASCII
- **RESUMEN-MODULO.md**: Cheat sheet, comandos esenciales, preguntas de repaso
- **laboratorios/**: Guías paso a paso para práctica hands-on
- **ejemplos/**: Code snippets, templates, scripts reusables
- **assets/**: Diagramas visuales complementarios

---

## 🎯 Metodología de Aprendizaje

### 📊 Distribución Teórico-Práctico
- **60% Teoría**: Fundamentos sólidos, arquitecturas, tipos, comparativas
- **40% Práctica**: Laboratorios Azure, ejercicios guiados, troubleshooting

### 🎓 Enfoque Pedagógico
Este módulo utiliza el método **"Fundamentos → Arquitectura → Práctica → Evolución"**:

1. **Contexto histórico** → Entender el "por qué" surgió la virtualización
2. **Definiciones técnicas** → Componentes, hipervisores, tipos
3. **Laboratorio práctico** → Aplicar conocimientos en entorno real
4. **Comparativa con contenedores** → Prepararte para Docker y Kubernetes

### 🔄 Flujo de Trabajo Sugerido

```
📖 Leer teoría → 💡 Tomar notas → 🧪 Laboratorio → 📝 RESUMEN → ❓ Preguntas
     ↓              ↓               ↓              ↓            ↓
  Conceptos    Entendimiento   Experiencia   Consolidación  Validación
```

**💡 Consejo**: No intentes memorizarlo todo. Enfócate en **entender conceptos clave** y **saber dónde buscar detalles**.

---

## 🔗 Conexión con Otros Módulos

### ➡️ Este módulo prepara para:
- **[Módulo 2: Docker y Contenerización](../modulo-2-docker/README.md)** - Evolución natural desde VMs a contenedores
- **[Área 2 - Módulo 1: Introducción a Kubernetes](../../area-2-arquitectura-kubernetes/modulo-01-introduccion-kubernetes/README.md)** - Orquestación de contenedores a escala

### ⬅️ Fundamentos requeridos previos:
- Conocimientos básicos de sistemas operativos (Linux, Windows)
- Comprensión de conceptos de redes (IP, DNS, puertos)
- Familiaridad con línea de comandos (Bash, PowerShell)

### 🌐 Contexto en el curso completo:

```
ÁREA 1: Fundamentos Docker
├── Módulo 1: Virtualización ← ESTÁS AQUÍ
│   └── Contexto histórico, bases de VMs, hipervisores
└── Módulo 2: Docker
    └── Contenedores como evolución de VMs

            ↓

ÁREA 2: Arquitectura Kubernetes
├── Módulo 01: Introducción a Kubernetes
├── Módulo 02: Arquitectura de Cluster
└── ... (18 módulos core)
```

**🎯 Objetivo del módulo**: Entender las bases de virtualización para apreciar las ventajas que Docker y Kubernetes ofrecen sobre las VMs tradicionales.

---

## 💡 Conceptos Clave Previos

Antes de iniciar el contenido principal, familiarízate con estos conceptos:

### 🖥️ Hardware vs. Virtual

```
┌─────────────────────────────────────────────────────────────┐
│            SERVIDOR TRADICIONAL (Dedicado)                  │
├─────────────────────────────────────────────────────────────┤
│  App 1       │                                              │
│  ├─ SO 1     │      DESPERDICIO DE RECURSOS                 │
│  └─ Hardware │      (70-80% CPU/RAM sin usar)               │
└──────────────┴──────────────────────────────────────────────┘

            ↓ VIRTUALIZACIÓN ↓

┌─────────────────────────────────────────────────────────────┐
│               SERVIDOR VIRTUALIZADO                         │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  VM 1    │  │  VM 2    │  │  VM 3    │  │  VM 4    │   │
│  │  App A   │  │  App B   │  │  App C   │  │  App D   │   │
│  │  SO      │  │  SO      │  │  SO      │  │  SO      │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       └─────────────┼─────────────┼─────────────┘          │
│                     │ HIPERVISOR │                          │
│  ┌──────────────────▼────────────▼─────────────────────┐   │
│  │         Hardware Físico Compartido                  │   │
│  │         (Uso eficiente 70-90%)                      │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 🔑 Términos Esenciales

| Término | Definición Rápida |
|---------|-------------------|
| **VM (Máquina Virtual)** | Sistema operativo completo corriendo sobre hardware virtualizado |
| **Hipervisor** | Software que gestiona y distribuye recursos físicos entre VMs |
| **Host** | Servidor físico que ejecuta el hipervisor y las VMs |
| **Guest** | Sistema operativo que corre dentro de una VM |
| **Overhead** | Recursos consumidos por virtualización (hipervisor + SO guest) |
| **Snapshot** | Captura del estado de una VM en un momento específico |
| **Live Migration** | Mover una VM entre hosts sin detenerla |

---

## 🎯 Objetivos Expandidos

### Al finalizar este módulo, dominarás:

#### 1. 🎓 Fundamentos Conceptuales
- ✅ Explicar qué es la virtualización y su impacto en la infraestructura TI moderna
- ✅ Describir el funcionamiento de hipervisores tipo 1 (bare-metal) y tipo 2 (hosted)
- ✅ Identificar 6 tipos de virtualización: servidores, escritorios, red, storage, datos, aplicaciones
- ✅ Comprender el rol de la virtualización en cloud computing (Azure, AWS, GCP)
- ✅ Contextualizar cómo las VMs sentaron las bases para Docker y Kubernetes

#### 2. 🛠️ Habilidades Técnicas
- ✅ Crear máquinas virtuales en Azure Portal con configuración personalizada
- ✅ Conectarse remotamente a VMs via SSH y administrar recursos
- ✅ Monitorear CPU, memoria y almacenamiento usando comandos del sistema
- ✅ Implementar laboratorios con VirtualBox, KVM o Hyper-V localmente
- ✅ Automatizar creación de VMs con Azure CLI o Terraform (nivel avanzado)

#### 3. 🔍 Capacidades de Troubleshooting
- ✅ Diagnosticar problemas de rendimiento: CPU steal time, memory ballooning
- ✅ Identificar cuándo el overhead de virtualización afecta performance
- ✅ Resolver conflictos de recursos entre VMs competiendo por el mismo hardware
- ✅ Troubleshoot conectividad de red en entornos virtualizados con vSwitches
- ✅ Analizar métricas del hipervisor para optimizar asignación de recursos

#### 4. 🏢 Visión Profesional y Estratégica
- ✅ Evaluar ventajas (consolidación, aislamiento) vs. desventajas (overhead, arranque lento)
- ✅ Justificar decisiones: ¿Cuándo usar VMs? ¿Cuándo contenedores? ¿Cuándo serverless?
- ✅ Planificar estrategias de consolidación para reducir costos de infraestructura
- ✅ Comprender por qué Kubernetes usa contenedores sobre VMs tradicionales
- ✅ Prepararte conceptualmente para certificaciones VMware VCP, MCSA, RHCVA, CKA

---

**Duración estimada**: 4-5 horas (principiante) | 3 horas (intermedio) | 2 horas (certificación)  
**Modalidad**: Teórico-Práctico (60/40)  
**Dificultad**: 🟢 Básico-Intermedio

---

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

Esta sección explora la **evolución natural desde la virtualización de aplicaciones hasta los contenedores modernos**, mostrando cómo cada tecnología resuelve problemas específicos de aislamiento y distribución de software.

---

#### **🧩 1. Virtualización de aplicaciones**

La **virtualización de aplicaciones** consiste en ejecutar una aplicación fuera del sistema operativo donde está instalada originalmente. Esto se logra **encapsulando la app junto con sus dependencias** (bibliotecas, configuraciones, registro, etc.) en un entorno virtual que se ejecuta en otro dispositivo o servidor.

**🏗️ Arquitectura:**
```
┌─────────────────────────────────────────┐
│         Usuario Final                   │
│  ┌───────────────────────────────────┐  │
│  │   SO Host (Windows 11, Linux)     │  │
│  │                                   │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  App Virtualizada           │  │  │
│  │  │  (Empaquetada con libs)     │  │  │
│  │  │                             │  │  │
│  │  │  ✅ Runtime incluido        │  │  │
│  │  │  ✅ Configuración aislada   │  │  │
│  │  │  ✅ Sin instalación real    │  │  │
│  │  └─────────────────────────────┘  │  │
│  │                                   │  │
│  │  Sistema Operativo Normal         │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**🔹 Ejemplo práctico:**

Imagina que tienes una aplicación antigua corporativa que **solo funciona en Windows 7** con ciertas versiones de .NET Framework y librerías específicas.

Con la virtualización de aplicaciones, puedes:
- **Encapsular** la aplicación con todas sus dependencias en un paquete
- **Ejecutarla** desde un servidor central o un repositorio de aplicaciones
- **Usarla** desde equipos con Windows 11, Windows 10 o incluso Linux (via Citrix/VMware)
- **Sin necesidad** de instalarla directamente en cada equipo

**🔹 Características clave:**

| Aspecto | Descripción |
|---------|-------------|
| **Qué se virtualiza** | Solo la aplicación y su entorno de ejecución |
| **SO del usuario** | Se ejecuta de manera tradicional (no virtualizado) |
| **Instalación** | No requiere instalación real en el dispositivo destino |
| **Aislamiento** | La app corre en una "burbuja" separada del SO host |
| **Portabilidad** | Ejecutable desde múltiples dispositivos sin cambios |

**🔹 Casos de uso comunes:**
- ✅ **Aplicaciones legacy**: Software antiguo que requiere versiones específicas de SO
- ✅ **Distribución corporativa**: Desplegar apps a miles de usuarios sin instalaciones manuales
- ✅ **Compatibilidad multi-versión**: Ejecutar múltiples versiones de la misma app en el mismo equipo
- ✅ **Pruebas de software**: Probar aplicaciones sin afectar el sistema base

**🔹 Herramientas principales:**
- **Microsoft App-V**: Virtualización de aplicaciones para Windows
- **Citrix Virtual Apps**: Streaming de aplicaciones desde servidores centralizados
- **VMware ThinApp**: Empaquetado de aplicaciones Windows portables

---

#### **🖥️ 2. Virtualización de escritorios (VDI)**

Para entender mejor la virtualización de aplicaciones, es útil compararla con la **virtualización de escritorios (VDI - Virtual Desktop Infrastructure)**, donde lo que se virtualiza es **todo el sistema operativo completo**, no solo la aplicación.

**🏗️ Arquitectura VDI:**
```
┌─────────────────────────────────────────┐
│      Usuario Final (Cliente)            │
│  ┌───────────────────────────────────┐  │
│  │   Dispositivo Ligero (Thin Client)│  │
│  │   Solo protocolo de visualización │  │
│  └────────────┬──────────────────────┘  │
└───────────────┼─────────────────────────┘
                │ Red/Internet
                ▼
┌─────────────────────────────────────────┐
│       Servidor VDI (Datacenter)         │
│  ┌───────────────────────────────────┐  │
│  │   Escritorio Virtual Completo     │  │
│  │   ┌───────────────────────────┐   │  │
│  │   │ Windows/Linux Completo    │   │  │
│  │   │ • Apps instaladas         │   │  │
│  │   │ • Configuración usuario   │   │  │
│  │   │ • SO completo funcionando │   │  │
│  │   └───────────────────────────┘   │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**💡 Diferencia fundamental:**

| Aspecto | Virtualización de Aplicaciones | Virtualización de Escritorios (VDI) |
|---------|-------------------------------|-----------------------------------|
| **Alcance** | Solo la aplicación específica | Sistema operativo completo |
| **Metáfora** | "Te presto solo la app que necesitas" | "Te presto una computadora virtual entera" |
| **SO del usuario** | Usa su SO local normal | Usa un SO remoto virtualizado completo |
| **Recursos consumidos** | Mínimos (solo la app) | Altos (SO completo + apps) |
| **Experiencia** | App se integra en escritorio local | Escritorio completo remoto |
| **Caso de uso típico** | Ejecutar app legacy específica | Trabajo remoto completo, call centers |

**🔹 Ejemplo comparativo:**

**Virtualización de Aplicaciones:**
```bash
# Usuario en Windows 11 ejecuta SAP legacy que requiere Windows 7
App-V Client → Lanza SAP virtualizado → Aparece como ventana normal
# La app corre "virtualizada" pero se ve como cualquier otra ventana
```

**Virtualización de Escritorios:**
```bash
# Usuario se conecta a un escritorio Windows 10 completo en servidor
VMware Horizon Client → Conecta al servidor → Escritorio completo remoto
# Todo el escritorio, todas las apps, todo remoto
```

**🔹 Herramientas VDI principales:**
- **Citrix XenDesktop**: Solución empresarial de VDI
- **VMware Horizon**: Plataforma de escritorios virtuales
- **Microsoft RDS (Remote Desktop Services)**: Escritorios remotos Windows
- **Amazon WorkSpaces**: VDI en AWS

---

#### **🐳 3. Contenedores (Docker, Podman, Kubernetes)**

Los **contenedores** representan la **evolución moderna del aislamiento de aplicaciones**, diseñados específicamente para el desarrollo, despliegue y escalabilidad de aplicaciones en la era del cloud computing y microservicios.

**🏗️ Arquitectura de contenedores:**
```
┌─────────────────────────────────────────────────────┐
│               Servidor / Host                       │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │Container1│  │Container2│  │Container3│           │
│  │          │  │          │  │          │           │
│  │  nginx   │  │  nodejs  │  │postgres  │           │
│  │  + libs  │  │  + libs  │  │ + libs   │           │
│  │          │  │          │  │          │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │             │             │                 │
│       └─────────────┼─────────────┘                 │
│                     │                               │
│  ┌──────────────────▼──────────────────────────┐    │
│  │     Container Engine (Docker/Podman)        │    │
│  └─────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────┐    │
│  │     Sistema Operativo Host (Linux)          │    │
│  │     • Kernel compartido por todos           │    │
│  │     • Namespaces para aislamiento           │    │
│  │     • Cgroups para límites de recursos      │    │
│  └─────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────┐    │
│  │         Hardware Físico / VM                │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

**🔹 Cómo funcionan los contenedores:**

Los contenedores utilizan **características del kernel de Linux** para crear aislamiento ligero:

1. **Namespaces**: Aíslan procesos, red, filesystem, usuarios
2. **Cgroups**: Limitan CPU, memoria, I/O por contenedor
3. **Union Filesystems**: Capas de solo-lectura + capa escribible
4. **Kernel compartido**: Todos los contenedores usan el mismo kernel del host

**🔹 Ejemplo práctico con Docker:**

```bash
# 1. Ejecutar servidor web nginx en segundos
docker run -d -p 8080:80 --name webserver nginx

# Resultado:
# ✅ Nginx corriendo en 2-3 segundos
# ✅ Accesible en http://localhost:8080
# ✅ Completamente aislado del sistema host
# ✅ Sin instalar nginx directamente en tu máquina

# 2. Verificar que está corriendo
docker ps
# CONTAINER ID   IMAGE   STATUS         PORTS
# abc123def456   nginx   Up 10 seconds  0.0.0.0:8080->80/tcp

# 3. Ver logs en tiempo real
docker logs -f webserver

# 4. Detener y eliminar (limpieza instantánea)
docker stop webserver
docker rm webserver
# ✅ Sistema completamente limpio, como si nunca hubiera existido
```

**🔹 Ejemplo multi-contenedor (stack completo):**

```bash
# Levantar aplicación completa: web + API + base de datos
docker network create myapp-network

# Base de datos PostgreSQL
docker run -d \
  --name database \
  --network myapp-network \
  -e POSTGRES_PASSWORD=secret \
  postgres:16

# API Backend (Node.js)
docker run -d \
  --name api \
  --network myapp-network \
  -e DATABASE_URL=postgres://database:5432/mydb \
  my-nodejs-api:latest

# Frontend Web (nginx)
docker run -d \
  --name web \
  --network myapp-network \
  -p 80:80 \
  my-frontend:latest

# ✅ Stack completo corriendo en minutos
# ✅ Todos los contenedores aislados pero comunicados
# ✅ Portable a cualquier servidor con Docker
```

**🔹 Ventajas clave de contenedores:**

- ✅ **Arranque instantáneo**: Segundos vs minutos de VMs
- ✅ **Portabilidad extrema**: "Funciona en mi máquina" = funciona en producción
- ✅ **Densidad alta**: Miles de contenedores en un solo servidor
- ✅ **Eficiencia de recursos**: Solo empaquetas lo necesario (50MB - 500MB típico)
- ✅ **Versionado**: Cada versión de la app es una imagen inmutable
- ✅ **CI/CD friendly**: Integración perfecta con pipelines DevOps
- ✅ **Escalabilidad**: Kubernetes puede escalar automáticamente

**🔹 Ecosistema de contenedores:**

| Tecnología | Propósito | Ejemplo de uso |
|-----------|----------|----------------|
| **Docker** | Runtime y herramientas de contenedores | Desarrollo local, builds, registries |
| **Podman** | Alternativa a Docker sin daemon | Contenedores sin root, más seguro |
| **Kubernetes** | Orquestación de contenedores | Producción, auto-scaling, self-healing |
| **Docker Compose** | Multi-contenedor local | Entornos de desarrollo complejos |
| **Harbor/Nexus** | Registry de imágenes | Almacenar y distribuir imágenes |

---

#### **📊 Comparación completa: Aplicaciones vs. Escritorios vs. Contenedores**

| Aspecto | Virtualización de Aplicaciones | Virtualización de Escritorios (VDI) | Contenedores |
|---------|-------------------------------|-------------------------------------|--------------|
| **Qué se virtualiza** | Solo la aplicación + runtime | Sistema operativo completo | Aplicación + dependencias + sistema base |
| **Kernel del SO** | Usa kernel del SO host | Kernel virtualizado completo | Comparte kernel del host |
| **Tamaño típico** | 100MB - 1GB | 20GB - 50GB | 50MB - 500MB |
| **Tiempo de arranque** | Segundos | 1-5 minutos | 1-3 segundos |
| **Aislamiento** | Parcial (depende del SO host) | Completo (VM completa) | Total (a nivel de proceso) |
| **Recursos consumidos** | Bajos | Altos (SO completo) | Muy bajos |
| **Portabilidad** | Limitada (depende de plataforma) | Baja (requiere hipervisor) | **Alta** (cualquier host con container runtime) |
| **Uso típico** | Apps legacy corporativas | Trabajo remoto, call centers | **DevOps, microservicios, cloud-native** |
| **Escalabilidad** | Manual, limitada | Manual, costosa | **Automática** (Kubernetes) |
| **Actualización** | Reempaquetar app | Actualizar imagen de VM | **Push de nueva imagen** |
| **Networking** | Complejo | Requiere VPN/RDP | Nativo, redes definidas por software |
| **Ejemplos** | Microsoft App-V, ThinApp | Citrix XenDesktop, VMware Horizon | **Docker, Kubernetes, Podman** |
| **Madurez** | Tecnología madura (2000s) | Tecnología madura (2000s) | **Tecnología moderna y en crecimiento** |

---

#### **🎯 Cuándo usar cada tecnología:**

**✅ Usa Virtualización de Aplicaciones cuando:**
- Necesitas ejecutar **apps legacy** en sistemas operativos modernos
- Requieres **distribución corporativa** centralizada sin instalaciones
- Quieres **múltiples versiones** de la misma app en un mismo equipo
- Trabajas en entornos **Windows corporativos** tradicionales

**✅ Usa Virtualización de Escritorios (VDI) cuando:**
- Necesitas proporcionar **entornos completos** de trabajo remoto
- Requieres **control centralizado** total sobre el entorno del usuario
- Trabajas con **call centers** o usuarios con dispositivos limitados
- Necesitas **seguridad máxima** (datos nunca salen del datacenter)

**✅ Usa Contenedores cuando:**
- Desarrollas **aplicaciones modernas** cloud-native
- Implementas **arquitecturas de microservicios**
- Necesitas **escalabilidad automática** y alta densidad
- Trabajas con **CI/CD** y necesitas despliegues rápidos
- Quieres **portabilidad completa** entre dev, staging y producción
- Buscas **eficiencia máxima** de recursos

---

#### **🔄 Evolución y complementariedad:**

Las tres tecnologías **no se excluyen mutuamente**, sino que se complementan:

```
┌─────────────────────────────────────────────────────┐
│           Estrategia Empresarial Moderna            │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📱 Apps Legacy corporativas                        │
│      → Virtualización de Aplicaciones (App-V)       │
│                                                     │
│  🖥️ Trabajo remoto de oficina                       │
│      → Virtualización de Escritorios (VDI)          │
│                                                     │
│  🐳 Aplicaciones nuevas y microservicios            │
│      → Contenedores (Docker + Kubernetes)           │
│                                                     │
│  ☁️ Infraestructura base                            │
│      → Virtualización de Servidores (VMs)           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**🔗 Integración moderna:**

Plataformas como **Red Hat OpenShift** y **Azure Kubernetes Service (AKS)** permiten:
- Ejecutar **VMs y contenedores** en la misma plataforma
- Migrar gradualmente de VMs a contenedores
- Mantener apps legacy en VMs mientras modernizas con containers
- Gestión unificada de toda la infraestructura

**👉 Para este curso, nos enfocaremos en contenedores (Docker) y su orquestación (Kubernetes), que representan el futuro de la infraestructura de aplicaciones.**

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