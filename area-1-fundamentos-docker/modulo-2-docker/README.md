# 🐳 Módulo 2: Contenerización con Docker – La Evolución de la Virtualización

**Duración**: 3 horas  
**Modalidad**: Teórico – Práctico

## 🎯 Objetivo del módulo

Comprender los fundamentos de la contenerización, Docker como plataforma de contenedores, y cómo esta tecnología representa una evolución natural de la virtualización, preparando las bases conceptuales y técnicas para Kubernetes.

---

## 🧩 1. Evolución de los modelos de despliegue

**Función**: Comprende la evolución desde deployment tradicional hasta contenedores modernos

[![Evolución de Deployment](../assets/diagrams/modulo-2-docker/deployment-evolution.svg)](../assets/diagrams/modulo-2-docker/deployment-evolution.drawio)

**🎯 Evolución Completa de Despliegue:**

> 🔗 **[Editar Diagrama en Draw.io](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-1-fundamentos-docker/assets/diagrams/modulo-2-docker/deployment-evolution.drawio)**

**📋 Fases de la Evolución:**

### **🏢 Deployment Tradicional - El modelo inicial**
Anteriormente, la manera de desplegar aplicaciones era en **servidores físicos**:

**Problemas del modelo tradicional:**
- **Muy costoso**: Cada aplicación requería hardware dedicado
- **Escalabilidad limitada**: Más carga = más máquinas físicas
- **Desperdicio de recursos**: Hardware infrautilizado
- **Baja densidad**: Una aplicación por servidor

### **💻 Máquinas Virtuales - Primera evolución**
Las VMs permitieron virtualizar sistemas operativos completos dentro del mismo hardware:

**Mejoras de las VMs:**
- Mejor aprovechamiento del hardware
- Múltiples aplicaciones en un servidor físico
- Escalamiento más económico

**Limitaciones persistentes:**
- Cada VM necesita SO completo (2+ GB RAM, espacio en disco)
- Alto overhead de recursos del sistema operativo
- Arranque lento (minutos)

### **🐳 Contenedores - La evolución actual**
Los contenedores resuelven las limitaciones anteriores:

**Ventajas de los contenedores:**
- **Granularidad**: Asignación precisa de recursos (100MB RAM vs 2GB)
- **Aislamiento**: Procesos completamente separados
- **Eficiencia**: Comparten el kernel del SO host
- **Velocidad**: Arranque en segundos
- **Densidad**: 100+ contenedores por servidor

---

## 🧩 2. ¿Qué es la contenerización?

Un **contenedor** es básicamente un **proceso aislado** que:
- Corre en su propio namespace
- Contiene todas las librerías y binarios necesarios
- Utiliza solo los recursos que necesita
- Está completamente aislado de otros contenedores

### **Concepto fundamental:**
```
Contenedor = Proceso Aislado + Librerías + Binarios + Recursos Controlados
```

### Diferencias fundamentales con la virtualización tradicional:

| Aspecto | Máquina Virtual | Contenedor |
|---------|----------------|------------|
| **SO Guest** | Completo (GB) | Compartido (MB) |
| **Arranque** | Minutos | Segundos |
| **Recursos** | Alto overhead | Mínimo overhead |
| **Aislamiento** | Hardware virtual | Namespaces/cgroups |
| **Portabilidad** | Limitada al hipervisor | Alta entre hosts |
| **Densidad** | Baja (2-10 VMs) | Alta (100+ contenedores) |
| **Asignación RAM** | Mínimo 2GB | Desde 50MB |

---

## ⚙️ 3. Tecnologías fundamentales: Namespaces y Cgroups

### **Linux Namespaces** - El corazón del aislamiento

Cuando creamos un contenedor, este hereda **todos estos namespaces** que lo mantienen completamente aislado:

#### **1. IPC (Inter-Process Communication) Namespace**
```
┌─────────────────┐    ┌─────────────────┐
│   Contenedor A  │    │   Contenedor B  │
│                 │    │                 │
│  Proceso A  ──► │    │ ◄──  Proceso C  │
│             ▲   │    │   ▲             │
│             │   │    │   │             │
│  Proceso B ──┘  │    │   └── Proceso D │
│                 │    │                 │
└─────────────────┘    └─────────────────┘
     ✅ Se comunican       ❌ NO se comunican
```

- **Dentro del contenedor**: Los procesos A y B pueden comunicarse
- **Entre contenedores**: Proceso A NO puede comunicarse con Proceso C
- **Método de comunicación**: Memoria compartida, semáforos, colas de mensajes

#### **2. PID (Process ID) Namespace**
```
Host OS:
├── PID 1001: Contenedor A
│   ├── PID 1: Proceso Principal
│   └── PID 2: Proceso Secundario
└── PID 1002: Contenedor B
    ├── PID 1: Proceso Principal  
    └── PID 2: Proceso Secundario
```

- Cada contenedor ve solo sus propios procesos
- Los PIDs son independientes entre contenedores
- Un contenedor NO puede ver los procesos de otro

#### **3. Network Namespace**
```
┌─────────────────────┐  ┌─────────────────────┐
│   Contenedor A      │  │   Contenedor B      │
│                     │  │                     │
│   IP: 172.17.0.2    │  │   IP: 172.17.0.3    │
│   Red: eth0         │  │   Red: eth0         │
│                     │  │                     │
└─────────────────────┘  └─────────────────────┘
```

- Cada contenedor tiene su propia IP única
- Redes completamente independientes
- Un contenedor NO puede ver los servicios de red de otro

#### **4. Mount (MNT) Namespace**
```
┌─────────────────────┐  ┌─────────────────────┐
│   Contenedor A      │  │   Contenedor B      │
│                     │  │                     │
│   /app/folder-A     │  │   /app/folder-B     │
│   /data/config-A    │  │   /data/config-B    │
│                     │  │                     │
└─────────────────────┘  └─────────────────────┘
```

- Sistemas de archivos independientes
- Montajes específicos por contenedor
- folder-A NO está disponible en Contenedor B

#### **5. USER Namespace**
```
Contenedor A:        Contenedor B:
├── user: admin      ├── user: developer
├── user: app        ├── user: nginx
└── user: guest      └── user: postgres
```

- Usuarios completamente independientes
- No hay conflictos de nombres de usuario
- Mapeo de UIDs independiente

#### **6. UTS (Unix Timesharing System) Namespace**
```
Contenedor A: hostname = web-server-01
Contenedor B: hostname = database-primary
```

- Cada contenedor tiene su hostname único
- Identificación independiente del sistema

### **Control Groups (cgroups)** - Control de recursos

Los **cgroups** permiten controlar y limitar los recursos que cada contenedor puede usar:

#### **Ejemplos prácticos de asignación:**
```bash
# Asignar recursos específicos a contenedores
docker run -d --name contenedor-web \
  --memory="200m" \           # Solo 200MB de RAM
  --cpus="0.5" \             # Medio CPU
  --pids-limit=100 \         # Máximo 100 procesos
  nginx

docker run -d --name contenedor-db \
  --memory="1g" \            # 1GB de RAM
  --cpus="1.0" \             # Un CPU completo
  --blkio-weight=300 \       # Prioridad de I/O
  postgres
```

#### **Ventajas del control granular:**
- **Granularidad perfecta**: Desde 50MB hasta lo que necesites
- **Prevención de monopolio**: Un contenedor no puede consumir todos los recursos
- **Optimización**: Mejor aprovechamiento del hardware disponible
- **Predictibilidad**: Comportamiento consistente bajo carga

---

## 🐳 4. ¿Qué es Docker?

**Docker** es una plataforma de contenerización que simplifica la creación, distribución y ejecución de aplicaciones en contenedores. Docker implementa todos los namespaces y cgroups de manera transparente para el usuario.

### Componentes principales de Docker:

- **Docker Engine**: Runtime que gestiona contenedores y orquesta los namespaces
- **Docker Images**: Plantillas inmutables para crear contenedores
- **Docker Containers**: Instancias ejecutables con todos los namespaces aislados
- **Docker Registry**: Repositorio para almacenar y distribuir imágenes
- **Dockerfile**: Archivo de texto con instrucciones para construir imágenes

### Ciclo de vida Docker:

```
Código → Dockerfile → Image → Container → Running App
   ↓         ↓         ↓        ↓           ↓
(write)   (build)   (pull)   (run)     (execute)
```

### **Docker en acción - Aislamiento completo:**

Cuando ejecutas `docker run`, Docker automáticamente:

1. **Crea todos los namespaces** (PID, NET, MNT, UTS, IPC, USER)
2. **Configura cgroups** para limitar recursos
3. **Aísla el proceso** completamente del host y otros contenedores
4. **Asigna recursos** según las especificaciones

```bash
# Ejemplo: Cada contenedor está completamente aislado
docker run -d --name web1 --memory="100m" nginx    # Contenedor 1
docker run -d --name web2 --memory="150m" nginx    # Contenedor 2
docker run -d --name web3 --memory="200m" nginx    # Contenedor 3

# Resultado:
# - 3 procesos totalmente aislados
# - 3 redes independientes con IPs diferentes
# - 3 sistemas de archivos independientes
# - Recursos controlados por cgroups
```

### **Aislamiento en la práctica:**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Container A    │    │  Container B    │    │  Container C    │
│                 │    │                 │    │                 │
│ Hostname: web-a │    │ Hostname: db-b  │    │ Hostname: api-c │
│ IP: 172.17.0.2  │    │ IP: 172.17.0.3  │    │ IP: 172.17.0.4  │
│ RAM: 100MB      │    │ RAM: 512MB      │    │ RAM: 256MB      │
│ CPU: 0.5        │    │ CPU: 1.0        │    │ CPU: 0.8        │
│                 │    │                 │    │                 │
│ Procesos:       │    │ Procesos:       │    │ Procesos:       │
│ ├─ PID 1: nginx │    │ ├─ PID 1: mysql │    │ ├─ PID 1: node  │
│ └─ PID 2: logs  │    │ └─ PID 2: mysql │    │ └─ PID 2: npm   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        ▲                        ▲                        ▲
        │                        │                        │
        └────────── AISLAMIENTO COMPLETO ──────────────────┘
     (No pueden verse entre ellos)
```

---

## 🔧 5. Docker vs otras tecnologías de contenedores

| Tecnología | Descripción | Uso principal |
|------------|-------------|---------------|
| **Docker** | Plataforma completa de contenedores | Desarrollo, testing, producción |
| **Podman** | Alternativa a Docker sin daemon | Seguridad, rootless containers |
| **LXC/LXD** | Contenedores de sistema completo | Virtualización ligera de sistemas |
| **rkt** | Runtime de contenedores de CoreOS | Alta seguridad (discontinuado) |

---

## 🧪 5. Laboratorio práctico: Instalación y primeros pasos con Docker

**Objetivo**: Instalar Docker en la VM de Azure y ejecutar los primeros contenedores.

### 🔧 Pasos:

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

### 📋 [Ver laboratorio completo de instalación Docker](./laboratorios/lab-docker-install.md)

---

## 📊 6. Comandos esenciales de Docker

### Gestión de imágenes:
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

### Gestión de contenedores:
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

### 📋 [Ver guía completa de comandos Docker](./laboratorios/docker-commands-guide.md)

---

## 🔄 7. Ventajas de la contenerización para Kubernetes

La contenerización con Docker proporciona las bases perfectas para Kubernetes:

### ✅ **Portabilidad**
- Las aplicaciones funcionan igual en desarrollo, testing y producción
- Eliminación del problema "funciona en mi máquina"

### ✅ **Escalabilidad**
- Arranque rápido de contenedores (segundos vs minutos)
- Mayor densidad de aplicaciones por servidor

### ✅ **Microservicios**
- Cada servicio en su propio contenedor
- Actualizaciones independientes por servicio

### ✅ **DevOps y CI/CD**
- Imágenes inmutables facilitan deployments
- Pipelines de integración continua más eficientes

### ✅ **Gestión de dependencias**
- Cada aplicación incluye sus dependencias
- Eliminación de conflictos entre versiones

---

## 🚀 8. De Docker a Kubernetes: El concepto de Pods

Aunque Docker resuelve muchos problemas, surgen nuevos desafíos en producción:

### ❌ **Limitaciones de Docker standalone:**
- **Gestión manual**: Arrancar/parar contenedores individualmente
- **Sin alta disponibilidad**: Si el host falla, se pierden los contenedores
- **Networking complejo**: Comunicación entre hosts es manual
- **Sin auto-scaling**: No puede ajustar automáticamente la capacidad
- **Sin self-healing**: Contenedores fallidos no se reinician automáticamente
- **Configuración dispersa**: Difícil gestionar múltiples hosts

### ✅ **Solución: Orquestadores de contenedores**
- **Kubernetes**: Orquestación empresarial completa
- **Docker Swarm**: Orquestación simple nativa de Docker  
- **Apache Mesos**: Orquestación para grandes clusters

### 🎯 **¿Por qué Kubernetes usa "Pods" en lugar de contenedores directos?**

En **Docker** la unidad mínima es el **contenedor**:
```
┌─────────────────┐
│   Contenedor    │
│                 │
│  ┌───────────┐  │
│  │ Aplicación│  │
│  └───────────┘  │
│                 │
│ Todos los       │
│ namespaces      │
│ aislados        │
└─────────────────┘
```

En **Kubernetes** la unidad mínima es el **Pod**:
```
┌──────────────────────────────────────────┐
│                   Pod                    │
│                                          │
│  ┌─────────────┐    ┌─────────────┐     │
│  │Contenedor A │    │Contenedor B │     │
│  │             │    │             │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │   App   │ │    │ │ Sidecar │ │     │
│  │ └─────────┘ │    │ └─────────┘ │     │
│  └─────────────┘    └─────────────┘     │
│                                          │
│ Namespaces COMPARTIDOS:                  │
│ ✓ Network (misma IP)                     │
│ ✓ Storage (volúmenes compartidos)        │
│ ✓ IPC (pueden comunicarse)               │
│                                          │
│ Namespaces SEPARADOS:                    │
│ ✗ PID (procesos aislados)                │
│ ✗ User (usuarios independientes)         │
└──────────────────────────────────────────┘
```

### **¿Por qué esta diferencia es importante?**

#### **1. Comunicación simplificada:**
```bash
# En Docker (contenedores separados):
docker run -d --name app nginx
docker run -d --name sidecar --link app monitoring-agent
# Networking complejo, IP diferentes

# En Kubernetes (Pod):
# Contenedores en el mismo Pod comparten IP
# curl localhost:8080 funciona directamente
```

#### **2. Almacenamiento compartido:**
```yaml
# Pod con volúmenes compartidos
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  - name: content-updater
    image: busybox
    volumeMounts:
    - name: shared-data
      mountPath: /data
  volumes:
  - name: shared-data
    emptyDir: {}
```

#### **3. Patterns de diseño de microservicios:**
```
Pod típico = Aplicación principal + Contenedores auxiliares

┌─────────────────────────────────────────┐
│                 Pod                     │
├─────────────────┬───────────────────────┤
│  App Principal  │    Sidecar Pattern    │
│                 │                       │
│  ┌───────────┐  │  ┌─────────────────┐  │
│  │  Nginx    │  │  │ Log Collector   │  │
│  │  Web App  │  │  │ (Fluent-bit)    │  │
│  └───────────┘  │  └─────────────────┘  │
│                 │                       │
│                 │  ┌─────────────────┐  │
│                 │  │ Metrics Export  │  │
│                 │  │ (Prometheus)    │  │
│                 │  └─────────────────┘  │
└─────────────────┴───────────────────────┘
```

### **Preparándose para Kubernetes:**

Entender cómo funcionan los **namespaces en Docker** es fundamental porque en Kubernetes:

1. **Los Pods heredan el modelo de namespaces de Docker**
2. **Kubernetes gestiona los Pods automáticamente**
3. **Los contenedores en un Pod comparten algunos namespaces**
4. **El aislamiento sigue siendo el principio fundamental**

**👉 Kubernetes emerge como el estándar de facto** para orquestación de contenedores, extendiendo el modelo de Docker con conceptos como Pods para mayor flexibilidad y poder.

---

## 📚 9. Fuentes y referencias técnicas

- [Docker Documentation](https://docs.docker.com/)
- [Container Runtime Interface (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/)
- [Open Container Initiative (OCI)](https://opencontainers.org/)
- [Linux Containers (LXC)](https://linuxcontainers.org/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## 🧠 Resultado esperado

Al finalizar este módulo, el estudiante podrá:

- ✅ Comprender qué es la contenerización y cómo difiere de la virtualización
- ✅ Identificar las tecnologías Linux subyacentes (namespaces, cgroups)
- ✅ Instalar y configurar Docker correctamente
- ✅ Ejecutar y gestionar contenedores básicos
- ✅ Entender las ventajas de los contenedores para aplicaciones modernas
- ✅ Reconocer las limitaciones que llevan a la necesidad de orquestación con Kubernetes

---

## 📋 Checkpoint del Módulo

Antes de continuar al Área 2, asegúrate de poder:

- [ ] Instalar Docker en un sistema Linux
- [ ] Ejecutar contenedores básicos con diferentes opciones
- [ ] Gestionar imágenes y contenedores con comandos CLI
- [ ] Explicar las diferencias entre VMs y contenedores
- [ ] Identificar cuándo necesitas un orquestador como Kubernetes

---

## 📂 Recursos del Módulo

- **🔧 [Laboratorios](./laboratorios/)**
  - [Lab 1: Primer Contenedor](./laboratorios/primer-contenedor-lab.md) ⏱️ 30min
  - [Lab 2: Imágenes Personalizadas](./laboratorios/imagenes-personalizadas-lab.md) ⏱️ 45min
  - [Lab 3: Volúmenes y Persistencia](./laboratorios/volumenes-persistencia-lab.md) ⏱️ 40min
  - [Lab 4: Redes Docker](./laboratorios/redes-docker-lab.md) ⏱️ 35min
  - [Lab 5: Aislamiento de Namespaces](./laboratorios/namespaces-isolation-lab.md) ⏱️ 30min
  - [Lab 6: Docker Compose - Evolución](./laboratorios/docker-compose-evolution-lab.md) ⏱️ 45min
  - [Instalación de Docker](./laboratorios/lab-docker-install.md)
  - [Comandos básicos](./laboratorios/docker-commands-guide.md)
  - [Ejercicios prácticos](./laboratorios/docker-exercises.md)

- **📝 [Ejemplos](./ejemplos/)**
  - [Dockerfiles básicos](./ejemplos/basic-dockerfiles/)
  - [Aplicaciones de ejemplo](./ejemplos/sample-apps/)

---

## ⏭️ Navegación

- **⬅️ [Módulo 1 - Virtualización](../modulo-1-virtualizacion/README.md)**
- **➡️ [Área 2 - Kubernetes](../../area-2-arquitectura-kubernetes/README.md)**
- **🏠 [Área 1 - Inicio](../README.md)**

---

**Tiempo estimado de completado**: 3 horas  
**Nivel de dificultad**: Básico-Intermedio  
**Prerequisitos**: Completar Módulo 1, conocimientos básicos de línea de comandos