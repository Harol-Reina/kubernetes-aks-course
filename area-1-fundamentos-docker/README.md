# Área 1 - Fundamentos de Virtualización, Contenerización y Docker

**Duración**: 6 horas  
**Modalidad**: Teórico – Práctico

## 🎯 Objetivos de Aprendizaje

Al completar esta área, serás capaz de:

- Comprender qué es la virtualización, cómo funciona y sus principales componentes
- Identificar las ventajas y desventajas de la virtualización tradicional
- Entender la evolución hacia la contenerización y Docker
- Crear y gestionar máquinas virtuales en Azure
- Instalar y configurar Docker correctamente
- Ejecutar y gestionar contenedores básicos
- Comprender las bases que llevaron al desarrollo de Kubernetes

---

## 📋 Estructura del Área

### 🧭 [Módulo 1: Virtualización Tradicional – Fundamentos de la Infraestructura Moderna](./modulo-1-virtualizacion/README.md)
- **Duración**: 3 horas
- **Enfoque**: Fundamentos de virtualización, hipervisores y VMs en Azure
- **Laboratorios**: Creación y gestión de VMs en Azure Portal

**Contenido:**
- Contexto histórico y evolución de la infraestructura
- Arquitectura de virtualización y tipos de hipervisores
- Ventajas y limitaciones de las máquinas virtuales
- Laboratorio práctico con Azure Virtual Machines
- Transición conceptual hacia la contenerización

### 🐳 [Módulo 2: Contenerización con Docker – La Evolución de la Virtualización](./modulo-2-docker/README.md)
- **Duración**: 3 horas
- **Enfoque**: Docker, contenedores y preparación para Kubernetes
- **Laboratorios**: Instalación Docker, contenedores básicos, comandos esenciales

**Contenido:**
- Fundamentos de contenerización y tecnologías Linux subyacentes
- Docker como plataforma de contenedores
- Instalación y configuración de Docker
- Comandos esenciales y gestión de contenedores
- Ventajas para microservicios y DevOps
- Limitaciones que llevan a la orquestación

---

## 🛣️ Ruta de Aprendizaje

```
📊 Servidores Físicos (Problemas históricos)
         ↓
🖥️  Virtualización Tradicional (Módulo 1)
         ↓
🐳 Contenerización con Docker (Módulo 2)
         ↓
☸️  Orquestación con Kubernetes (Área 2)
```

## 🎯 Resultados Esperados

Al completar esta área completa, el estudiante será capaz de:

### **Conocimientos Teóricos:**
- ✅ Explicar la evolución desde virtualización tradicional a contenedores
- ✅ Comparar VMs vs contenedores en diferentes escenarios
- ✅ Identificar cuándo usar cada tecnología
- ✅ Comprender las bases tecnológicas de Kubernetes

### **Habilidades Prácticas:**
- ✅ Crear y gestionar máquinas virtuales en Azure
- ✅ Instalar y configurar Docker en diferentes entornos
- ✅ Ejecutar y administrar contenedores Docker
- ✅ Utilizar comandos esenciales de Docker
- ✅ Preparar el entorno para aprender Kubernetes

### **Preparación para el Área 2:**
- ✅ Comprensión sólida de contenedores como building blocks
- ✅ Experiencia práctica con Docker CLI
- ✅ Entendimiento de las limitaciones que resuelve Kubernetes
- ✅ Contexto histórico y tecnológico completo

---

## 📚 Recursos Adicionales

### **Documentación Oficial:**
- [Azure Virtual Machines](https://docs.microsoft.com/es-es/azure/virtual-machines/)
- [Docker Documentation](https://docs.docker.com/)
- [VMware Virtualization Concepts](https://www.vmware.com/topics/glossary/content/virtualization.html)

### **Laboratorios y Ejemplos:**
- [Laboratorios Módulo 1](./modulo-1-virtualizacion/laboratorios/)
- [Laboratorios Módulo 2](./modulo-2-docker/laboratorios/)
- [Ejemplos Docker](./modulo-2-docker/ejemplos/)

### **Referencias Técnicas:**
- [Linux Containers (LXC)](https://linuxcontainers.org/)
- [Open Container Initiative (OCI)](https://opencontainers.org/)
- [Container Runtime Interface (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/)

---

## ⏱️ Cronograma Sugerido

| Sesión | Duración | Contenido | Actividades |
|--------|----------|-----------|-------------|
| **Sesión 1** | 1.5h | Módulo 1 - Teoría de Virtualización | Conceptos, arquitectura, tipos |
| **Sesión 2** | 1.5h | Módulo 1 - Laboratorio Azure | Crear y gestionar VMs |
| **Sesión 3** | 1.5h | Módulo 2 - Teoría de Contenedores | Contenerización, Docker, comparaciones |
| **Sesión 4** | 1.5h | Módulo 2 - Laboratorio Docker | Instalación, comandos, contenedores |

---

## 🔄 Evaluación y Progreso

### **Checkpoint Módulo 1:**
- [ ] Crear VM en Azure Portal
- [ ] Conectarse por SSH y verificar recursos
- [ ] Explicar diferencias entre hipervisores Tipo 1 y Tipo 2
- [ ] Identificar ventajas y limitaciones de VMs

### **Checkpoint Módulo 2:**
- [ ] Instalar Docker correctamente
- [ ] Ejecutar contenedores básicos
- [ ] Gestionar imágenes y contenedores
- [ ] Explicar ventajas de contenedores vs VMs

### **Evaluación Final del Área:**
- [ ] Proyecto práctico combinando ambos módulos
- [ ] Quiz teórico sobre conceptos fundamentales
- [ ] Preparación demostrada para el Área 2

---

## ▶️ Navegación

- **🏠 [Inicio del Curso](../README.md)**
- **📖 [Área 2 - Fundamentos y Arquitectura de Kubernetes](../area-2-arquitectura-kubernetes/README.md)**
- **🔧 [Laboratorios Generales](../laboratorios/)**
- **📋 [Proyecto Final](../proyecto-final/)**

---

## 💡 Consejos para el Estudio

1. **Secuencial**: Completa el Módulo 1 antes de avanzar al Módulo 2
2. **Práctico**: Realiza todos los laboratorios hands-on
3. **Reflexivo**: Comprende el "por qué" de cada evolución tecnológica
4. **Preparatorio**: Mantén en mente que esto es la base para Kubernetes
5. **Documentado**: Toma notas de comandos y conceptos clave

¡Buena suerte en tu viaje de aprendizaje hacia la maestría en Kubernetes! 🚀

## 🧭 Módulo 1: Virtualización Tradicional – Fundamentos de la Infraestructura Moderna

### 🎯 Objetivo del módulo

Comprender qué es la virtualización, cómo funciona, sus principales componentes, ventajas, desventajas y cómo sentó las bases para la contenerización y Kubernetes.

### 🧩 1. Contexto histórico

Antes de la virtualización, cada aplicación requería un servidor físico dedicado.
Esto generaba:

- **Alto costo de hardware**: Un servidor por aplicación
- **Espacio físico y consumo energético elevados**: Centros de datos enormes
- **Desperdicio de recursos**: CPU, RAM infrautilizados la mayor parte del tiempo
- **Dificultad de escalamiento**: Agregar nueva capacidad requería hardware físico

Con la virtualización surgió una solución: **compartir los recursos de un mismo servidor físico entre varios sistemas operativos**, aislados entre sí.

**👉 Ejemplo práctico:**
En un servidor con 64 GB de RAM y 16 núcleos, se pueden ejecutar 4 máquinas virtuales (VMs) con 16 GB y 4 núcleos cada una, compartiendo el mismo hardware.

### ⚙️ 2. ¿Qué es la virtualización?

La **virtualización** es una tecnología que permite ejecutar múltiples entornos operativos en un mismo equipo físico, aislados entre sí, como si fueran servidores independientes.
Cada entorno se denomina **máquina virtual (VM)**.

#### Componentes principales:

- **Servidor físico (Host)**: Equipo que provee los recursos físicos
- **Hipervisor**: Software que gestiona las VMs y reparte los recursos
- **Máquinas virtuales (Guests)**: Entornos virtuales con su propio SO, CPU, RAM, disco y red

#### 📘 Tipos de hipervisores:

| Tipo | Descripción | Ejemplos |
|------|-------------|----------|
| **Tipo 1 (Bare-metal)** | Se ejecuta directamente sobre hardware | VMware ESXi, Microsoft Hyper-V Server, KVM |
| **Tipo 2 (Hosted)** | Se ejecuta sobre un SO existente | VirtualBox, VMware Workstation |

### 🧱 3. Arquitectura de virtualización

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

### 🖥️ 4. Tipos de virtualización

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| **Virtualización de servidores** | Ejecutar varias VMs en un mismo servidor físico | VMware ESXi, KVM |
| **Virtualización de red** | Crear redes virtuales internas o aisladas | vSwitch, Hyper-V Network |
| **Virtualización de almacenamiento** | Abstraer discos físicos en volúmenes virtuales | vSAN, LVM |
| **Virtualización de escritorio (VDI)** | Entornos de escritorio remoto centralizados | Citrix, VMware Horizon |

### ⚖️ 5. Ventajas y desventajas

#### ✅ Ventajas

- **Mejor aprovechamiento de hardware**: Un servidor puede hospedar múltiples VMs
- **Reducción de costos y espacio físico**: Menos servidores físicos necesarios
- **Aislamiento entre entornos**: Fallos en una VM no afectan otras
- **Clonación y migración sencilla**: Copiar VMs entre servidores
- **Ideal para laboratorios y entornos de prueba**: Crear/destruir entornos rápidamente

#### ❌ Desventajas

- **Mayor consumo de recursos por VM**: Cada VM necesita un SO completo
- **Arranque más lento que los contenedores**: Tiempo de boot del SO guest
- **Dependencia de licencias**: Costos de licenciamiento según hipervisor
- **Complejidad en escalabilidad a gran escala**: Gestión de muchas VMs

### 🔬 6. Laboratorio práctico (Azure)

**Objetivo**: Crear una máquina virtual en Azure y comprender el funcionamiento básico de la virtualización.

#### 🔧 Pasos:

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

### 🔄 7. De la virtualización a los contenedores

La virtualización fue el **primer paso hacia la infraestructura ágil**.
Sin embargo, al crecer las necesidades de despliegue, surgieron nuevos desafíos:

- **Tiempo de arranque de VMs alto**: Arrancar un SO completo toma minutos
- **Uso excesivo de recursos**: Cada VM necesita recursos para el SO guest
- **Complejidad en actualizaciones y dependencias**: Gestionar múltiples SOs
- **Escalabilidad limitada**: Dificultad para escalar aplicaciones rápidamente

Para resolver esto nació la **contenerización**, representada por herramientas como Docker, donde los contenedores comparten el mismo kernel del sistema operativo y son mucho más livianos.

**👉 Este será el tema del próximo módulo:**
"Dockerización: la evolución de la virtualización."

### 📚 8. Fuentes y referencias técnicas

- [Microsoft Learn – Introducción a la Virtualización](https://docs.microsoft.com/es-es/learn/modules/intro-to-azure-virtual-machines/)
- [VMware Docs – What is Virtualization](https://www.vmware.com/topics/glossary/content/virtualization.html)
- [Red Hat – Virtualization Overview](https://www.redhat.com/es/topics/virtualization/what-is-virtualization)
- [Azure Virtual Machines Documentation](https://docs.microsoft.com/es-es/azure/virtual-machines/)
- [KVM Documentation](https://www.linux-kvm.org/page/Documents)

### 🧠 Resultado esperado

Al finalizar este módulo, el estudiante podrá:

- ✅ Comprender qué es la virtualización y cómo funciona
- ✅ Identificar los componentes clave: host, hipervisor y VM
- ✅ Diferenciar entre hipervisores tipo 1 y tipo 2
- ✅ Implementar una máquina virtual básica en Azure
- ✅ Entender las limitaciones que dieron origen a los contenedores

---

## 🐳 Módulo 2: Contenerización con Docker – La Evolución de la Virtualización

### 🎯 Objetivo del módulo

*[Este módulo se desarrollará en el siguiente paso, enfocándose en Docker, contenedores y preparando las bases para Kubernetes]*

---

## 🐳 Módulo 2: Contenerización con Docker – La Evolución de la Virtualización

### 🎯 Objetivo del módulo

Comprender los fundamentos de la contenerización, Docker como plataforma de contenedores, y cómo esta tecnología representa una evolución natural de la virtualización, preparando las bases conceptuales y técnicas para Kubernetes.

### 🧩 1. ¿Qué es la contenerización?

La **contenerización** es una forma de virtualización a nivel de sistema operativo que permite ejecutar aplicaciones y sus dependencias en procesos aislados que comparten el kernel del sistema operativo host.

#### Diferencias fundamentales con la virtualización tradicional:

| Aspecto | Máquina Virtual | Contenedor |
|---------|----------------|------------|
| **SO Guest** | Completo (GB) | Compartido (MB) |
| **Arranque** | Minutos | Segundos |
| **Recursos** | Alto overhead | Mínimo overhead |
| **Aislamiento** | Hardware virtual | Namespaces/cgroups |
| **Portabilidad** | Limitada al hipervisor | Alta entre hosts |
| **Densidad** | Baja (2-10 VMs) | Alta (100+ contenedores) |

#### Arquitectura de contenerización:

```
┌─────────────────────────────────────┐
│  App A  │  App B  │  App C  │ App D │
├─────────┼─────────┼─────────┼───────┤
│ Bins/   │ Bins/   │ Bins/   │ Bins/ │
│ Libs    │ Libs    │ Libs    │ Libs  │
├─────────┴─────────┴─────────┴───────┤
│      Container Runtime (Docker)     │
├─────────────────────────────────────┤
│           Host OS (Linux)           │
├─────────────────────────────────────┤
│         Hardware Físico             │
└─────────────────────────────────────┘
```

### ⚙️ 2. Tecnologías fundamentales de Linux

Los contenedores utilizan características nativas del kernel Linux:

#### **Linux Namespaces** (Aislamiento):
- **PID**: Aislamiento de procesos - cada contenedor ve solo sus procesos
- **NET**: Aislamiento de red - interfaces, routing, puertos independientes  
- **MNT**: Aislamiento del filesystem - cada contenedor tiene su propio árbol de directorios
- **UTS**: Aislamiento del hostname - nombre único por contenedor
- **IPC**: Aislamiento de IPC - comunicación entre procesos independiente
- **USER**: Aislamiento de usuarios - mapeo de UIDs independiente

#### **Control Groups (cgroups)** (Limitación de recursos):
- **CPU**: Límites y reservas de procesamiento
- **Memory**: Límites de memoria RAM y swap
- **I/O**: Límites de lectura/escritura de disco
- **Network**: Límites de ancho de banda

### 🐳 3. ¿Qué es Docker?

**Docker** es una plataforma de contenerización que simplifica la creación, distribución y ejecución de aplicaciones en contenedores.

#### Componentes principales de Docker:

- **Docker Engine**: Runtime que gestiona contenedores
- **Docker Images**: Plantillas inmutables para crear contenedores
- **Docker Containers**: Instancias ejecutables de imágenes
- **Docker Registry**: Repositorio para almacenar y distribuir imágenes
- **Dockerfile**: Archivo de texto con instrucciones para construir imágenes

#### Ciclo de vida Docker:

```
Código → Dockerfile → Image → Container → Running App
   ↓         ↓         ↓        ↓           ↓
(write)   (build)   (pull)   (run)     (execute)
```

### 🔧 4. Docker vs otras tecnologías de contenedores

| Tecnología | Descripción | Uso principal |
|------------|-------------|---------------|
| **Docker** | Plataforma completa de contenedores | Desarrollo, testing, producción |
| **Podman** | Alternativa a Docker sin daemon | Seguridad, rootless containers |
| **LXC/LXD** | Contenedores de sistema completo | Virtualización ligera de sistemas |
| **rkt** | Runtime de contenedores de CoreOS | Alta seguridad (discontinuado) |

### 🧪 5. Laboratorio práctico: Instalación y primeros pasos con Docker

**Objetivo**: Instalar Docker en la VM de Azure y ejecutar los primeros contenedores.

#### 🔧 Pasos:

1. **Conectarse a la VM creada en el Módulo 1**
   ```bash
   ssh azureuser@<IP_PUBLICA>
   ```

2. **Instalar Docker**
   ```bash
   # Actualizar el sistema
   sudo apt update
   
   # Instalar paquetes necesarios
   sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
   
   # Agregar clave GPG oficial de Docker
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   
   # Agregar repositorio Docker
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   
   # Instalar Docker Engine
   sudo apt update
   sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
   
   # Agregar usuario al grupo docker
   sudo usermod -aG docker $USER
   
   # Verificar instalación
   docker --version
   ```

3. **Primeros comandos Docker**
   ```bash
   # Reiniciar sesión SSH para aplicar cambios de grupo
   exit
   ssh azureuser@<IP_PUBLICA>
   
   # Hello World de Docker
   docker run hello-world
   
   # Ver qué pasó
   docker ps -a
   docker images
   
   # Ejecutar contenedor interactivo
   docker run -it ubuntu:22.04 bash
   # Dentro del contenedor:
   ls /
   cat /etc/os-release
   exit
   
   # Ejecutar servidor web nginx
   docker run -d -p 80:80 --name mi-nginx nginx
   
   # Verificar que funciona
   curl http://localhost
   
   # Ver contenedores en ejecución
   docker ps
   
   # Ver logs del contenedor
   docker logs mi-nginx
   
   # Ejecutar comando dentro del contenedor
   docker exec -it mi-nginx bash
   ls /usr/share/nginx/html/
   exit
   
   # Detener y eliminar contenedor
   docker stop mi-nginx
   docker rm mi-nginx
   ```

### 📊 6. Comandos esenciales de Docker

#### Gestión de imágenes:
```bash
# Buscar imágenes en Docker Hub
docker search nginx

# Descargar imagen
docker pull nginx:alpine

# Listar imágenes locales
docker images

# Eliminar imagen
docker rmi nginx:alpine

# Ver historial de una imagen
docker history nginx
```

#### Gestión de contenedores:
```bash
# Ejecutar contenedor (foreground)
docker run nginx

# Ejecutar contenedor (background/detached)
docker run -d nginx

# Ejecutar con nombre personalizado
docker run -d --name mi-servidor nginx

# Ejecutar con mapeo de puertos
docker run -d -p 8080:80 nginx

# Ejecutar con variables de entorno
docker run -d -e MYSQL_ROOT_PASSWORD=secreto mysql

# Ver contenedores en ejecución
docker ps

# Ver todos los contenedores (incluidos detenidos)
docker ps -a

# Inspeccionar contenedor
docker inspect mi-servidor

# Estadísticas de recursos
docker stats

# Detener contenedor
docker stop mi-servidor

# Iniciar contenedor detenido
docker start mi-servidor

# Reiniciar contenedor
docker restart mi-servidor

# Eliminar contenedor
docker rm mi-servidor

# Eliminar contenedor en ejecución (forzado)
docker rm -f mi-servidor
```

### 🔄 7. Ventajas de la contenerización para Kubernetes

La contenerización con Docker proporciona las bases perfectas para Kubernetes:

#### ✅ **Portabilidad**
- Las aplicaciones funcionan igual en desarrollo, testing y producción
- Eliminación del problema "funciona en mi máquina"

#### ✅ **Escalabilidad**
- Arranque rápido de contenedores (segundos vs minutos)
- Mayor densidad de aplicaciones por servidor

#### ✅ **Microservicios**
- Cada servicio en su propio contenedor
- Actualizaciones independientes por servicio

#### ✅ **DevOps y CI/CD**
- Imágenes inmutables facilitan deployments
- Pipelines de integración continua más eficientes

#### ✅ **Gestión de dependencias**
- Cada aplicación incluye sus dependencias
- Eliminación de conflictos entre versiones

### 🚀 8. Evolución hacia la orquestación

Aunque Docker resuelve muchos problemas, surgen nuevos desafíos en producción:

#### ❌ **Limitaciones de Docker standalone:**
- **Gestión manual**: Arrancar/parar contenedores individualmente
- **Sin alta disponibilidad**: Si el host falla, se pierden los contenedores
- **Networking complejo**: Comunicación entre hosts es manual
- **Sin auto-scaling**: No puede ajustar automáticamente la capacidad
- **Sin self-healing**: Contenedores fallidos no se reinician automáticamente
- **Configuración dispersa**: Difícil gestionar múltiples hosts

#### ✅ **Solución: Orquestadores de contenedores**
- **Kubernetes**: Orquestación empresarial completa
- **Docker Swarm**: Orquestación simple nativa de Docker  
- **Apache Mesos**: Orquestación para grandes clusters

**👉 Kubernetes emerge como el estándar de facto** para orquestación de contenedores, lo que nos lleva al siguiente área del curso.

### 📚 9. Fuentes y referencias técnicas

- [Docker Documentation](https://docs.docker.com/)
- [Container Runtime Interface (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/)
- [Open Container Initiative (OCI)](https://opencontainers.org/)
- [Linux Containers (LXC)](https://linuxcontainers.org/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### 🧠 Resultado esperado

Al finalizar este módulo, el estudiante podrá:

- ✅ Comprender qué es la contenerización y cómo difiere de la virtualización
- ✅ Identificar las tecnologías Linux subyacentes (namespaces, cgroups)
- ✅ Instalar y configurar Docker correctamente
- ✅ Ejecutar y gestionar contenedores básicos
- ✅ Entender las ventajas de los contenedores para aplicaciones modernas
- ✅ Reconocer las limitaciones que llevan a la necesidad de orquestación con Kubernetes

---

## 📝 Resumen del Área 1

### 🎯 Objetivos completados

Al finalizar esta área, has comprendido:

1. **Evolución tecnológica**: Desde servidores físicos → VMs → Contenedores → Orquestación
2. **Fundamentos sólidos**: Virtualización tradicional como base conceptual
3. **Contenerización práctica**: Docker como herramienta de contenerización líder
4. **Preparación para Kubernetes**: Bases técnicas y conceptuales necesarias

### 🛣️ Ruta de aprendizaje

```
Módulo 1: Virtualización Tradicional
    ↓
Entender limitaciones de VMs
    ↓
Módulo 2: Contenerización con Docker  
    ↓
Reconocer limitaciones de Docker standalone
    ↓
Área 2: Kubernetes como orquestador
```

### 🔗 Conectando con el siguiente área

Los contenedores Docker que has aprendido a crear y gestionar serán los bloques básicos que Kubernetes orquestará. En el **Área 2** aprenderás:

- Cómo Kubernetes gestiona contenedores a escala
- Arquitectura de clusters y componentes principales
- Objetos fundamentales: Pods, Services, Deployments
- Networking y comunicación entre contenedores
- Integración con Azure Kubernetes Service (AKS)

---

## 🔗 Enlaces útiles

- [Docker Hub](https://hub.docker.com/) - Registro público de imágenes
- [Azure Container Instances](https://azure.microsoft.com/services/container-instances/) - Contenedores sin servidor
- [Azure Container Registry](https://azure.microsoft.com/services/container-registry/) - Registro privado de imágenes
- [Docker Compose Documentation](https://docs.docker.com/compose/) - Orquestación básica

## ▶️ Siguiente: [Área 2 - Fundamentos y Arquitectura de Kubernetes](../area-2-arquitectura-kubernetes/README.md)