# Capítulo 1: Virtualización Tradicional

Este curso comienza aquí porque toda la historia de los contenedores y Kubernetes tiene sus raíces en un problema muy concreto que surgió en los centros de datos de los años 90 y 2000. Para entender por qué Docker existe, y por qué Kubernetes es necesario, primero hay que entender qué se hacía antes y qué salió mal.

**El problema real**: En la era del "bare metal", cada aplicación vivía en su propio servidor físico. Una empresa con 50 aplicaciones tenía 50 servidores, la mayoría ejecutando su CPU al 5-10% de capacidad. El costo era astronómico: hardware dedicado, espacio físico en el data center, climatización, energía eléctrica y personal para mantenerlo todo. Si necesitabas más capacidad para una aplicación, esperabas semanas mientras se compraba, rackeba y configuraba un servidor nuevo.

**La solución**: Los hipervisores llegaron para permitir que un solo servidor físico albergue múltiples sistemas operativos completos ejecutándose en paralelo, aislados entre sí. En lugar de un servidor por aplicación, podías tener 10, 20 o 30 máquinas virtuales en el mismo hardware, cada una con su propio OS, sin que se interfirieran entre ellas.

**La analogía**: Piensa en un edificio de oficinas. Antes, cada empresa necesitaba su propio edificio (servidor físico). La virtualización es como dividir ese edificio en oficinas independientes: cada inquilino tiene su propio espacio, su propia llave, sus propias paredes, pero todos comparten la estructura, la electricidad y la plomería del edificio.

**En este capítulo** explorarás los dos tipos de hipervisores (Type 1 bare-metal como KVM y VMware ESXi, y Type 2 hosted como VirtualBox), cómo funciona la virtualización a nivel del kernel de Linux, y -muy importante- cuáles son las limitaciones de las VMs que eventualmente llevaron al mundo a inventar los contenedores. Al terminar, entenderás exactamente por qué Docker fue una revolución y no solo una mejora incremental.

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

### 📅 Línea de tiempo: evolución de la infraestructura de cómputo

```
Década    Paradigma                    Característica clave
──────────────────────────────────────────────────────────────────────────
1960s     MAINFRAMES                   Un ordenador central, muchos
                                       terminales de acceso compartido.
                                       Acceso por turnos o time-sharing.

1970s     MINICOMPUTADORES             Máquinas de tamaño departamental.
                                       Una máquina por empresa o área.
                                       Primer acceso multiusuario real.

1980s     CLIENTE-SERVIDOR             PCs de escritorio + servidores
                                       dedicados por aplicación.
                                       Proliferación de hardware físico.

1990s     INTERNET + SERVIDORES WEB    Servidores dedicados por servicio
                                       (web, mail, DNS, FTP...).
                                       Uso real del servidor: 5-15%.

2000s     VIRTUALIZACIÓN               Múltiples SO en un servidor físico.
                                       Un servidor → 4 a 10 VMs.
                                       Uso del servidor: 60-80%.

2010s     CONTENEDORES                 Procesos aislados sin SO completo.
                                       Arranque en millisegundos.
                                       Docker (2013) cambia la industria.

2020s     ORQUESTACIÓN                 Kubernetes gestiona miles de
                                       contenedores distribuidos.
                                       Autoescalado, autorreparación.
```

### 💸 El problema del servidor dedicado por aplicación

Antes de la virtualización, la norma era **"una aplicación = un servidor"**. Esto generaba costos e ineficiencias estructurales muy concretos:

| Problema | Magnitud real |
|----------|---------------|
| **Utilización media del servidor** | 5-15% de CPU y RAM |
| **Costo por servidor físico** | USD 3,000 - 10,000 (hardware) + hosting + cooling + energía |
| **Tiempo para escalar** | Semanas o meses (compra, envío, instalación, configuración) |
| **Servidores por aplicación** | 1 servidor dedicado = 1 app, aunque solo se use de madrugada |
| **Espacio en el datacenter** | Racks completos para servidores al 10% de carga |

El resultado era derrochador: un servidor costoso, ocupando espacio y consumiendo electricidad, cuya única tarea era correr un proceso de negocio que solo estaba activo a ratos. La virtualización cambió esta ecuación radicalmente: **un servidor físico podía alojar 4 a 10 VMs**, elevando la utilización real al 60-80% y amortizando el hardware sobre muchas cargas de trabajo simultáneas.

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

### 🏗️ Arquitectura detallada: Tipo 1 vs Tipo 2

Los dos modelos de hipervisor difieren fundamentalmente en dónde se sitúa la capa de virtualización dentro de la pila de software:

```
Tipo 1 (Bare-metal):              Tipo 2 (Hosted):

┌─────┐ ┌─────┐ ┌─────┐          ┌─────┐ ┌─────┐
│ VM1 │ │ VM2 │ │ VM3 │          │ VM1 │ │ VM2 │
│ OS  │ │ OS  │ │ OS  │          │ OS  │ │ OS  │
└──┬──┘ └──┬──┘ └──┬──┘          └──┬──┘ └──┬──┘
   └───────┼───────┘                └───┬───┘
     ┌─────┴─────┐               ┌─────┴──────┐
     │ Hipervisor│               │ Hipervisor  │
     │ (Tipo 1)  │               │ (Tipo 2)    │
     └─────┬─────┘               └──────┬──────┘
     ┌─────┴─────┐               ┌──────┴──────┐
     │ Hardware  │               │ SO Host     │
     │ Físico    │               │ (Windows /  │
     └───────────┘               │  Linux/Mac) │
                                 └──────┬──────┘
                                 ┌──────┴──────┐
                                 │  Hardware   │
                                 │  Físico     │
                                 └─────────────┘
```

En el **Tipo 1**, el hipervisor es el sistema operativo de la máquina: accede directamente al hardware sin intermediarios, lo que le permite controlar drivers, interrupciones y planificación de CPU con la máxima eficiencia. En el **Tipo 2**, el hipervisor es una aplicación más dentro de un SO convencional: cada llamada al hardware debe pasar primero por el kernel del host, añadiendo latencia.

### 📊 Comparación de rendimiento aproximada

| Metrica | Tipo 1 (Bare-metal) | Tipo 2 (Hosted) | Bare metal (sin VM) |
|---------|---------------------|-----------------|----------------------|
| **Overhead de CPU** | 2-5% | 5-15% | 0% |
| **Overhead de RAM por VM** | ~200 MB/VM | ~500 MB/VM | 0 |
| **Tiempo de arranque de VM** | 30-60 s | 60-120 s | 3-5 min (SO completo) |
| **Uso tipico** | Produccion empresarial | Desarrollo y pruebas | Sistemas legacy |
| **Gestion remota** | API dedicada (vCenter, etc.) | Limitada | Acceso directo |
| **Densidad de VMs** | Alta (20-50 VMs/host) | Media (4-10 VMs/host) | N/A |

El overhead del Tipo 2 se explica por la doble capa de planificacion: el scheduler del SO host compite con las necesidades del hipervisor, que a su vez intenta repartir el tiempo de CPU entre sus VMs. En produccion, ese coste adicional puede significar latencias perceptibles en cargas de trabajo de base de datos o procesamiento en tiempo real.

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

## 📈 7. Evolución de la infraestructura: de bare metal a orquestación

Para comprender la posicion que ocupa la virtualización en la historia de la infraestructura, conviene verla dentro del arco completo que va desde los servidores dedicados hasta los sistemas de orquestacion modernos:

```
EVOLUCIÓN DE LA INFRAESTRUCTURA:

┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  BARE METAL │    │    VMs      │    │ CONTAINERS  │    │ ORQUESTACION│
│             │    │             │    │             │    │             │
│ 1 app =     │───▶│ N apps =    │───▶│ N apps =    │───▶│ N×M apps =  │
│ 1 servidor  │    │ 1 servidor  │    │ 1 proceso   │    │ gestionadas │
│             │    │ (aisladas)  │    │ (ligero)    │    │ autom.      │
│ Uso: 10-15% │    │ Uso: 60-80% │    │ Uso: 80-95% │    │             │
│ Boot: 5 min │    │ Boot: 30s-  │    │ Boot: <1 s  │    │ Auto-heal   │
│ Tamaño: N/A │    │       2 min │    │ MB/contendr │    │ Auto-scale  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
     1990s               2000s              2010s              2020s
```

Cada salto en esta evolución responde a un cuello de botella concreto del modelo anterior:

- **Bare metal → VMs**: el desperdicio de hardware al 10% de utilizacion era insostenible. Los hipervisores permitieron consolidar cargas de trabajo en menos maquinas fisicas.
- **VMs → Contenedores**: el overhead del SO guest por VM (2-4 GB RAM, minutos de boot) era incompatible con arquitecturas de microservicios que exigen cientos de procesos ligeros. Los contenedores eliminan ese OS invitado compartiendo el kernel del host.
- **Contenedores → Orquestacion**: manejar cientos o miles de contenedores manualmente resulta inviable. Kubernetes automatiza el despliegue, el escalado, la recuperacion ante fallos y la gestion de la red entre contenedores.

Esta progresion es la razon por la que este curso comienza aqui: para entender Kubernetes hay que entender por que los contenedores existen, y para entender por que existen los contenedores hay que entender las limitaciones de las VMs.

---

## 🔄 8. De la virtualización a los contenedores

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

### 🧱 Limitaciones de las VMs en detalle

Cada VM es, a todos los efectos, un ordenador completo ejecutandose dentro de otro ordenador. Eso implica un coste estructural que no desaparece por mucho que se optimice el hipervisor.

#### Overhead por OS guest

La parte mas costosa de una VM es el sistema operativo invitado que se ejecuta dentro de ella. Ese SO necesita memoria, CPU y disco independientemente de si la aplicacion que aloja esta haciendo algo util o no:

| Componente de la VM | Consumo tipico de RAM | Proposito |
|---------------------|----------------------|-----------|
| Kernel del SO guest | 200-400 MB | Gestion de memoria, I/O, scheduling |
| Servicios del SO (systemd, sshd, etc.) | 300-600 MB | Infraestructura del sistema operativo |
| Runtime de la aplicacion (JVM, Node...) | 200-500 MB | Ejecutar el codigo de negocio |
| **Total minimo por VM** | **~700 MB - 1.5 GB** | Solo para tener la VM "encendida" |

En una arquitectura de microservicios con 50 servicios, esto puede significar 35-75 GB de RAM dedicada solo a mantener sistemas operativos invitados, antes de correr ni una linea de logica de negocio.

#### Comparacion de tamanyo: VMs vs contenedores

```
Imagen de VM (disco):
┌───────────────────────────────────────────────┐
│  SO base (Ubuntu/Windows)    2 GB - 8 GB       │
│  Librerias del sistema       500 MB - 1.5 GB   │
│  Runtime (JDK, Node...)      200 MB - 500 MB   │
│  Codigo de la aplicacion     10 MB - 100 MB    │
│  ─────────────────────────────────────────     │
│  TOTAL:                      2.7 GB - 10 GB    │
└───────────────────────────────────────────────┘

Imagen de contenedor (Docker):
┌───────────────────────────────────────────────┐
│  SO base minimo (alpine/slim) 5 MB - 80 MB    │
│  Librerias necesarias         20 MB - 150 MB   │
│  Runtime (JDK, Node...)       80 MB - 300 MB   │
│  Codigo de la aplicacion      10 MB - 100 MB   │
│  ─────────────────────────────────────────     │
│  TOTAL:                       50 MB - 500 MB   │
└───────────────────────────────────────────────┘
```

La diferencia puede ser de **10 a 20 veces** en terminos de tamanyo de imagen y consumo de RAM. En un servidor con 256 GB de RAM, eso es la diferencia entre ejecutar ~25 VMs o ~500 contenedores.

#### Tiempos de arranque comparados

El tiempo que tarda un sistema en estar disponible es critico en escenarios de escalado automatico y recuperacion ante fallos:

| Tecnologia | Tiempo de arranque tipico | Causa principal del tiempo |
|------------|--------------------------|---------------------------|
| Servidor fisico (boot completo) | 3-5 minutos | POST, BIOS, kernel, servicios |
| VM Tipo 1 (ESXi/KVM) | 30-60 segundos | Boot del SO guest completo |
| VM Tipo 2 (VirtualBox) | 60-120 segundos | SO host + SO guest en serie |
| Contenedor Docker | 1-3 segundos | Solo iniciar el proceso |
| Contenedor (imagen ya cacheada) | < 500 ms | Fork de proceso + namespaces |

En Kubernetes, cuando un nodo falla y hay que reprogramar las cargas de trabajo en otro nodo, la diferencia entre arrancar VMs (minutos) y contenedores (segundos) determina directamente el tiempo de recuperacion del servicio.

#### Otros costes operacionales de las VMs

- **Snapshot y migracion**: Crear un snapshot de una VM de 8 GB es una operacion de disco intensiva que puede durar varios minutos y consumir ancho de banda significativo.
- **Parches del SO guest**: Con 50 VMs corriendo Ubuntu, hay que gestionar 50 sistemas operativos independientes, cada uno con sus propios ciclos de actualizaciones, vulnerabilidades y reiniciar cada vez que se parchea el kernel.
- **Licenciamiento**: Los SO guest con licencia (Windows Server, RHEL) se cobran por instancia. 50 VMs = 50 licencias.

Estas limitaciones, mas que defectos de diseno, son consecuencias inevitables del modelo de VMs. Hacen que las VMs sean excelentes para consolidar servidores y aislar cargas de trabajo a nivel de SO, pero inadecuadas como unidad de despliegue para arquitecturas modernas de cientos o miles de servicios.

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

## 🚀 9. Migración y modernización de VMs

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

## Conceptos Clave para Recordar

Antes de pasar al siguiente capítulo, asegúrate de que puedes responder estas preguntas:

### Checklist de comprensión

- [ ] **¿Qué problema resolvió la virtualización?** — La subutilización masiva de servidores físicos (10-15% de uso) y el costo de tener un servidor por aplicación
- [ ] **¿Qué es un hipervisor?** — Software que crea y gestiona máquinas virtuales, distribuyendo los recursos físicos entre múltiples OS aislados
- [ ] **¿Cuál es la diferencia entre Tipo 1 y Tipo 2?** — Tipo 1 corre directamente sobre hardware (ESXi, KVM), Tipo 2 corre sobre un OS host (VirtualBox, VMware Workstation)
- [ ] **¿Por qué Tipo 1 tiene mejor rendimiento?** — No hay capa intermedia de OS host, el hipervisor accede directamente al hardware
- [ ] **¿Qué es KVM?** — Hipervisor Tipo 1 integrado en el kernel de Linux, base de muchas soluciones cloud
- [ ] **¿Cuánta RAM consume una VM solo para existir?** — 700 MB - 1.5 GB mínimo (kernel + servicios del OS guest)
- [ ] **¿Cuánto tarda en arrancar una VM vs un contenedor?** — VM: 30-120 segundos, Contenedor: < 3 segundos
- [ ] **¿Cuáles son las principales limitaciones de las VMs?** — Overhead de OS guest, tamaño de imagen (GB), tiempo de arranque, dificultad para microservicios

### Tabla resumen: Virtualización en números

| Concepto | Valor típico |
|----------|-------------|
| Utilización sin virtualización | 10-15% |
| Utilización con virtualización | 60-80% |
| VMs por servidor físico | 10-20 |
| RAM mínima por VM | 700 MB - 1.5 GB |
| Tamaño imagen VM | 2-10 GB |
| Tiempo arranque VM (Tipo 1) | 30-60 segundos |
| Tiempo arranque VM (Tipo 2) | 60-120 segundos |
| Contenedores por servidor | 100-500+ |
| RAM por contenedor | 50-500 MB |
| Tamaño imagen contenedor | 50-500 MB |
| Tiempo arranque contenedor | < 3 segundos |

### Diagrama de decisión: ¿VM o Contenedor?

```
¿Necesitas un OS diferente al host (ej: Windows en Linux)?
├── SÍ → VM (cada VM tiene su propio kernel)
└── NO →
    ¿Necesitas aislamiento completo a nivel de kernel?
    ├── SÍ → VM (mayor seguridad entre tenants)
    └── NO →
        ¿Necesitas arranque rápido y alta densidad?
        ├── SÍ → Contenedor
        └── NO →
            ¿Es una aplicación legacy que no se puede contenerizar?
            ├── SÍ → VM (lift & shift)
            └── NO → Contenedor (opción por defecto en 2024+)
```

> **Nota importante**: En la práctica moderna, VMs y contenedores coexisten. Kubernetes típicamente corre dentro de VMs en la nube (cada nodo de AKS es una VM de Azure), y los contenedores corren dentro de esas VMs. Entender ambas tecnologías es esencial.

---

## Resumen del capítulo

En este capítulo cubrimos los fundamentos de la virtualización: desde el contexto histórico de servidores dedicados hasta los hipervisores Tipo 1 y Tipo 2, pasando por los distintos tipos de virtualización (servidores, escritorios, red, almacenamiento, aplicaciones y NFV).

**Lo que aprendimos:**
- La evolución de la infraestructura: mainframes → cliente-servidor → virtualización → contenedores → orquestación
- Cómo los hipervisores permiten compartir hardware físico entre múltiples sistemas operativos
- Las diferencias entre hipervisores bare-metal (Tipo 1) y hosted (Tipo 2)
- KVM como el hipervisor open-source integrado en Linux
- Las ventajas de consolidación, aislamiento y eficiencia
- Las limitaciones de overhead (RAM, disco, arranque) que motivaron la aparición de los contenedores

**Conexión con el siguiente capítulo:** Ahora que entiendes por qué las VMs son pesadas para arquitecturas de microservicios, en el Capítulo 2 exploraremos Docker y la contenerización — la tecnología que resolvió estas limitaciones compartiendo el kernel del host en lugar de cargar un OS completo por cada instancia.