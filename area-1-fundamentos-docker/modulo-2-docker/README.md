# 🐳 Módulo 2: Contenerización con Docker – La Evolución de la Virtualización

**Duración**: 3 horas  
**Modalidad**: Teórico – Práctico

## 🎯 Objetivo del módulo

Comprender los fundamentos de la contenerización, Docker como plataforma de contenedores, y cómo esta tecnología representa una evolución natural de la virtualización, preparando las bases conceptuales y técnicas para Kubernetes.

---

## 🧩 1. ¿Qué es la contenerización?

La **contenerización** es una forma de virtualización a nivel de sistema operativo que permite ejecutar aplicaciones y sus dependencias en procesos aislados que comparten el kernel del sistema operativo host.

### Diferencias fundamentales con la virtualización tradicional:

| Aspecto | Máquina Virtual | Contenedor |
|---------|----------------|------------|
| **SO Guest** | Completo (GB) | Compartido (MB) |
| **Arranque** | Minutos | Segundos |
| **Recursos** | Alto overhead | Mínimo overhead |
| **Aislamiento** | Hardware virtual | Namespaces/cgroups |
| **Portabilidad** | Limitada al hipervisor | Alta entre hosts |
| **Densidad** | Baja (2-10 VMs) | Alta (100+ contenedores) |

### Arquitectura de contenerización:

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

---

## ⚙️ 2. Tecnologías fundamentales de Linux

Los contenedores utilizan características nativas del kernel Linux:

### **Linux Namespaces** (Aislamiento):
- **PID**: Aislamiento de procesos - cada contenedor ve solo sus procesos
- **NET**: Aislamiento de red - interfaces, routing, puertos independientes  
- **MNT**: Aislamiento del filesystem - cada contenedor tiene su propio árbol de directorios
- **UTS**: Aislamiento del hostname - nombre único por contenedor
- **IPC**: Aislamiento de IPC - comunicación entre procesos independiente
- **USER**: Aislamiento de usuarios - mapeo de UIDs independiente

### **Control Groups (cgroups)** (Limitación de recursos):
- **CPU**: Límites y reservas de procesamiento
- **Memory**: Límites de memoria RAM y swap
- **I/O**: Límites de lectura/escritura de disco
- **Network**: Límites de ancho de banda

---

## 🐳 3. ¿Qué es Docker?

**Docker** es una plataforma de contenerización que simplifica la creación, distribución y ejecución de aplicaciones en contenedores.

### Componentes principales de Docker:

- **Docker Engine**: Runtime que gestiona contenedores
- **Docker Images**: Plantillas inmutables para crear contenedores
- **Docker Containers**: Instancias ejecutables de imágenes
- **Docker Registry**: Repositorio para almacenar y distribuir imágenes
- **Dockerfile**: Archivo de texto con instrucciones para construir imágenes

### Ciclo de vida Docker:

```
Código → Dockerfile → Image → Container → Running App
   ↓         ↓         ↓        ↓           ↓
(write)   (build)   (pull)   (run)     (execute)
```

---

## 🔧 4. Docker vs otras tecnologías de contenedores

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

## 🚀 8. Evolución hacia la orquestación

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

**👉 Kubernetes emerge como el estándar de facto** para orquestación de contenedores, lo que nos lleva al siguiente área del curso.

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