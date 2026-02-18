# Área 1 - Fundamentos de Virtualización, Contenerización y Docker

> *"Antes de orquestar contenedores con Kubernetes, debemos comprender la evolución desde servidores físicos hasta la contenerización moderna."*

**Duración**: 10-12 horas (principiante) | 7-9 horas (intermedio) | 5-6 horas (certificación)  
**Modalidad**: Teórico – Práctico (50/50)  
**Estado**: ✅ 100% Actualizado con Estructura Pedagógica Completa

---

## 🎯 Objetivos de Aprendizaje

Al completar esta área, serás capaz de:

### 🎓 Conceptuales
- Comprender qué es la virtualización, cómo funciona y sus principales componentes
- Explicar la evolución tecnológica: Hardware dedicado → VMs → Contenedores → Kubernetes
- Identificar las ventajas y desventajas de virtualización vs. contenerización
- Entender las tecnologías Linux subyacentes (namespaces, cgroups, union filesystems)

### 🛠️ Técnicos
- Crear y gestionar máquinas virtuales en Azure Cloud
- Instalar y configurar Docker en Linux, Windows y macOS
- Ejecutar, gestionar y troubleshoot contenedores Docker
- Crear Dockerfiles y construir imágenes optimizadas
- Usar Docker Compose para aplicaciones multi-contenedor

### 🔍 Troubleshooting
- Diagnosticar problemas de rendimiento en VMs (CPU steal time, memory ballooning)
- Resolver errores comunes de Docker (networking, volúmenes, permisos)
- Optimizar imágenes Docker para reducir tamaño y mejorar seguridad
- Identificar cuándo usar VMs vs. Contenedores según el caso de uso

### 🏢 Profesionales
- Justificar decisiones arquitectónicas en entornos empresariales
- Prepararte sólidamente para aprender Kubernetes (Área 2)
- Comprender el contexto histórico y tecnológico de la infraestructura moderna
- Alinearte con certificaciones CKA/CKAD (fundamentos de contenedores)

---

## 📋 Estructura del Área

### 🧭 [Módulo 1: Virtualización Tradicional – Fundamentos de la Infraestructura Moderna](./modulo-1-virtualizacion/README.md)

**Duración**: 4-5 horas (principiante) | 3 horas (intermedio) | 2 horas (certificación)  
**Enfoque**: Fundamentos de virtualización, hipervisores, VMs en Azure

**📚 Contenido Principal:**
- Contexto histórico: Del hardware dedicado a las VMs
- Arquitectura de virtualización y tipos de hipervisores (Tipo 1, Tipo 2)
- KVM, ESXi, Hyper-V: Tecnologías empresariales
- 6 Tipos de virtualización (servidores, red, storage, aplicaciones, datos, NFV)
- Ventajas: Consolidación, aislamiento, snapshots, migración
- Limitaciones: Overhead de SO, arranque lento, licencias
- Laboratorio práctico: VMs en Azure Portal + Azure CLI
- Transición conceptual hacia la contenerización

**🔧 Laboratorios:**
- Lab 1: Crear VM en Azure Portal (Ubuntu Server)
- Lab 2: Gestión con Azure CLI (automatización)
- Lab 3 (opcional): VirtualBox local (sin costos cloud)

**📊 Recursos:**
- README.md: 54KB de teoría completa
- RESUMEN-MODULO.md: 29KB de comandos y troubleshooting
- 10 preguntas de repaso con respuestas detalladas

---

### 🐳 [Módulo 2: Contenerización con Docker – La Evolución de la Virtualización](./modulo-2-docker/README.md)

**Duración**: 6-8 horas (principiante) | 4-5 horas (intermedio) | 3 horas (certificación)  
**Enfoque**: Docker, contenedores y preparación para Kubernetes

**📚 Contenido Principal:**
- Evolución: VMs → Contenedores (por qué surgieron)
- Los 4 Pilares de Docker: Contenedores, Imágenes, Dockerfiles, Docker Hub
- Tecnologías Linux subyacentes: namespaces, cgroups, union filesystems
- Arquitectura Docker: Cliente, Engine, containerd, runc
- Comandos esenciales: run, ps, logs, exec, build, push
- Dockerfiles: Instrucciones, multi-stage builds, optimización
- Volúmenes y redes: Persistencia y comunicación entre contenedores
- Docker Compose: Orquestación multi-contenedor (YAML)
- Mejores prácticas: Seguridad, tamaño de imágenes, Alpine Linux

**🔧 Laboratorios:**
- Lab 1: Instalación de Docker (Linux, Windows, Mac)
- Lab 2: Primeros comandos (nginx, postgres, redis)
- Lab 3: Dockerizar aplicación Node.js (Dockerfile completo)
- Lab 4: Volúmenes y redes (persistencia + networking)
- Lab 5: Docker Compose (web + DB + cache)

**📊 Recursos:**
- README.md: 119KB de teoría completa
- RESUMEN-MODULO.md: 29KB de comandos Docker esenciales
- 50+ comandos Docker documentados
- Ejemplos de Dockerfile para Node.js, Python, Java, Go

---

## 🛣️ Ruta de Aprendizaje

```
┌─────────────────────────────────────────────────────────┐
│         EVOLUCIÓN DE LA INFRAESTRUCTURA                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  📊 Servidores Físicos                                  │
│     • 1 servidor = 1 aplicación                         │
│     • Alto costo, desperdicio de recursos               │
│     • Baja densidad                                     │
│              ↓                                          │
│  🖥️  Virtualización (Módulo 1)                          │
│     • Múltiples VMs por servidor                        │
│     • Mejor aprovechamiento de hardware                 │
│     • Overhead de SO guest completo                     │
│              ↓                                          │
│  🐳 Contenedores con Docker (Módulo 2)                  │
│     • Alta densidad (100+ contenedores/servidor)        │
│     • Arranque instantáneo (segundos)                   │
│     • Portabilidad extrema                              │
│              ↓                                          │
│  ☸️  Orquestación con Kubernetes (Área 2)               │
│     • Gestión de miles de contenedores                  │
│     • Auto-scaling, self-healing, rolling updates       │
│     • Infraestructura declarativa                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Resultados Esperados

Al completar esta área completa, el estudiante será capaz de:

### **✅ Conocimientos Teóricos Sólidos:**
- Explicar la evolución completa: Hardware → VMs → Contenedores → K8s
- Comparar VMs vs contenedores con métricas concretas (arranque, overhead, densidad)
- Identificar cuándo usar cada tecnología según el caso de uso empresarial
- Comprender las bases tecnológicas que hacen posible Kubernetes
- Entender por qué Kubernetes usa contenedores (no VMs) como building blocks

### **✅ Habilidades Prácticas Operacionales:**
- Crear y gestionar máquinas virtuales en Azure (Portal + CLI)
- Instalar y configurar Docker en diferentes entornos (Linux, Win, Mac)
- Ejecutar y administrar contenedores Docker con 50+ comandos
- Crear Dockerfiles optimizados con multi-stage builds
- Usar Docker Compose para stacks multi-contenedor
- Troubleshoot problemas comunes de VMs y contenedores

### **✅ Preparación Óptima para el Área 2 (Kubernetes):**
- Comprensión sólida de contenedores como unidad básica de K8s
- Experiencia práctica con Docker CLI (similar a kubectl)
- Entendimiento profundo de las limitaciones que Kubernetes resuelve
- Contexto histórico y tecnológico completo
- Vocabulario técnico alineado con Kubernetes (imágenes, Pods, registries)

### **✅ Mentalidad Profesional:**
- Capacidad de justificar decisiones técnicas con argumentos sólidos
- Comprensión de trade-offs: VMs vs. Contenedores vs. Serverless
- Visión de arquitecturas cloud-native y microservicios
- Preparación para certificaciones CKA/CKAD (fundamentos)

---

## 📊 Comparativa: VMs vs. Contenedores

| Aspecto | Máquinas Virtuales | Contenedores Docker |
|---------|-------------------|---------------------|
| **SO Guest** | SO completo (2-4 GB) | Comparte kernel del host |
| **Tamaño** | GB (2-20 GB típico) | MB (50-500 MB típico) |
| **Arranque** | Minutos | Segundos |
| **Overhead** | Alto (~20-30%) | Mínimo (~5%) |
| **Densidad** | 5-20 VMs/servidor | 100+ contenedores/servidor |
| **Aislamiento** | Hardware-nivel (completo) | Proceso-nivel (namespaces) |
| **Portabilidad** | ⭐⭐⭐ Limitada | ⭐⭐⭐⭐⭐ Extrema |
| **Uso típico** | Apps legacy, Windows, aislamiento total | Microservicios, apps cloud-native |
| **Ejemplo K8s** | Nodes (Workers) son VMs | Pods ejecutan contenedores |

---

## 📚 Recursos Adicionales del Área

### **📖 Documentación Oficial:**
- [Azure Virtual Machines](https://docs.microsoft.com/es-es/azure/virtual-machines/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [VMware Virtualization Concepts](https://www.vmware.com/topics/glossary/content/virtualization.html)
- [Red Hat - Virtualización](https://www.redhat.com/es/topics/virtualization/what-is-virtualization)
- [Red Hat - Contenedores vs VMs](https://www.redhat.com/es/topics/containers/containers-vs-vms)

### **🔧 Laboratorios y Ejemplos:**
- [Laboratorios Módulo 1 - Virtualización](./modulo-1-virtualizacion/laboratorios/)
- [Laboratorios Módulo 2 - Docker](./modulo-2-docker/laboratorios/)
- [Ejemplos Dockerfile](./modulo-2-docker/ejemplos/dockerfile-examples/)
- [Ejemplos Docker Compose](./modulo-2-docker/ejemplos/docker-compose-examples/)

### **🛠️ Herramientas Complementarias:**
- [VirtualBox](https://www.virtualbox.org/) - Hipervisor tipo 2 gratuito
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) - Docker para Windows/Mac
- [Portainer](https://www.portainer.io/) - GUI para Docker
- [Dive](https://github.com/wagoodman/dive) - Analizar capas de imágenes Docker

### **📚 Referencias Técnicas Avanzadas:**
- [Linux Containers (LXC)](https://linuxcontainers.org/)
- [Open Container Initiative (OCI)](https://opencontainers.org/)
- [Container Runtime Interface (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/)
- [containerd](https://containerd.io/) - Runtime usado por Kubernetes

---

## ⏱️ Cronograma Sugerido

### 🟢 Ruta Principiante (10-12 horas)

| Sesión | Duración | Módulo | Contenido | Actividades |
|--------|----------|--------|-----------|-------------|
| **Día 1 - Sesión 1** | 2h | M1 | Teoría Virtualización | Conceptos, arquitectura, tipos de hipervisores |
| **Día 1 - Sesión 2** | 2h | M1 | Lab Azure VMs | Crear y gestionar VMs en Azure Portal |
| **Día 2 - Sesión 3** | 2h | M2 | Teoría Contenedores | Contenerización, Docker, tecnologías Linux |
| **Día 2 - Sesión 4** | 2h | M2 | Lab Docker Básico | Instalación, primeros comandos, contenedores |
| **Día 3 - Sesión 5** | 2h | M2 | Lab Dockerfiles | Crear imágenes personalizadas, multi-stage |
| **Día 3 - Sesión 6** | 2h | M2 | Lab Docker Compose | Stack multi-contenedor (web + DB) |

### 🟡 Ruta Intermedia (7-9 horas)

| Sesión | Duración | Módulo | Contenido | Actividades |
|--------|----------|--------|-----------|-------------|
| **Día 1 - AM** | 3h | M1 | Virtualización completa | Teoría + Lab Azure combinado |
| **Día 1 - PM** | 3h | M2 | Docker Teoría + Básico | Conceptos + Instalación + Comandos |
| **Día 2 - AM** | 3h | M2 | Docker Avanzado | Dockerfiles + Compose + Troubleshooting |

### 🔴 Ruta Certificación (5-6 horas)

| Sesión | Duración | Módulo | Enfoque | Contenido |
|--------|----------|--------|---------|-----------|
| **Sesión 1** | 2h | M1 | VMs contexto K8s | Diferencias VMs/Contenedores, KVM en clouds |
| **Sesión 2** | 2h | M2 | Docker fundamentos | Comandos esenciales, troubleshooting |
| **Sesión 3** | 2h | M2 | Preparación K8s | containerd, CRI-O, runtime interfaces |

---

## 🔄 Evaluación y Progreso

### **Checkpoint Módulo 1 - Virtualización:**
- [ ] Explicar qué es un hipervisor y diferencias Tipo 1 vs Tipo 2
- [ ] Crear VM en Azure Portal con Ubuntu Server
- [ ] Conectarse por SSH y verificar recursos (lscpu, free, df)
- [ ] Describir 3 ventajas y 3 desventajas de virtualización
- [ ] Justificar por qué surgieron los contenedores

### **Checkpoint Módulo 2 - Docker:**
- [ ] Instalar Docker correctamente y verificar instalación
- [ ] Ejecutar contenedores básicos (nginx, postgres, redis)
- [ ] Crear un Dockerfile para aplicación Node.js o Python
- [ ] Usar volúmenes para persistencia de datos
- [ ] Orquestar stack multi-contenedor con Docker Compose
- [ ] Explicar diferencias entre contenedores y VMs con ejemplos

### **Evaluación Final del Área:**
- [ ] **Teórico**: Explicar evolución completa Hardware → VMs → Contenedores
- [ ] **Práctico**: Dockerizar aplicación completa (frontend + backend + DB)
- [ ] **Troubleshooting**: Resolver 3 problemas comunes de Docker
- [ ] **Preparación K8s**: Listar 5 limitaciones de Docker que K8s resuelve

---

## ✅ Criterios de Completitud

**Para avanzar al Área 2 (Kubernetes), debes:**

✅ **Dominio conceptual**:
- Explicar con claridad qué es un contenedor (no "VM ligera")
- Justificar cuándo usar VMs vs. Contenedores
- Comprender namespaces, cgroups y union filesystems

✅ **Competencia práctica**:
- Ejecutar contenedores con opciones: `-d`, `-p`, `-v`, `-e`, `--name`
- Crear Dockerfiles funcionales y optimizados
- Usar Docker Compose para aplicaciones reales

✅ **Troubleshooting básico**:
- Diagnosticar contenedores que no arrancan (`docker logs`)
- Resolver problemas de networking entre contenedores
- Optimizar imágenes grandes (multi-stage, Alpine)

✅ **Mindset correcto**:
- Reconocer que Docker tiene limitaciones en producción
- Entender por qué se necesita orquestación (K8s)
- Estar motivado para aprender Kubernetes

---

## ▶️ Navegación

- **🏠 [Inicio del Curso](../README.md)**
- **➡️ [Área 2 - Fundamentos y Arquitectura de Kubernetes](../area-2-arquitectura-kubernetes/README.md)**
- **📖 [GUIA-ESTRUCTURA-MODULOS.md](../GUIA-ESTRUCTURA-MODULOS.md)** - Estándares del curso
- **📊 [ESTADO-CURSO.md](../ESTADO-CURSO.md)** - Progreso y métricas
- **🔧 [Laboratorios Generales](../laboratorios/)**
- **📋 [Proyecto Final](../proyecto-final/)**

---

## 💡 Consejos para el Estudio

### 🎯 Estrategias de Aprendizaje

1. **📖 Secuencial y Progresivo**: 
   - Completa el Módulo 1 antes de avanzar al Módulo 2
   - No te saltes los laboratorios prácticos
   - La teoría sin práctica es incompleta

2. **🧪 Hands-On Prioritario**: 
   - Dedica 50% del tiempo a laboratorios
   - Experimenta más allá de las guías
   - Rompe cosas intencionalmente para aprender

3. **🤔 Reflexión Constante**: 
   - Comprende el "por qué" de cada evolución tecnológica
   - Pregunta: "¿Qué problema resuelve esto?"
   - Conecta conceptos entre módulos

4. **🎓 Preparación para Kubernetes**: 
   - Mantén en mente que esto es la base para K8s
   - Toma notas de comandos Docker (similares a kubectl)
   - Identifica limitaciones de Docker que K8s resolverá

5. **📝 Documentación Personal**: 
   - Crea tu propio cheat sheet de comandos
   - Documenta errores y soluciones que encuentres
   - Comparte aprendizajes con la comunidad

### 🚫 Errores Comunes a Evitar

- ❌ Memorizar comandos sin entender conceptos
- ❌ Saltarse laboratorios por "falta de tiempo"
- ❌ Pensar que los contenedores son "VMs ligeras" (NO lo son)
- ❌ Usar siempre imágenes `latest` (mala práctica)
- ❌ Ignorar logs de error (aprendes más de los errores)
- ❌ No hacer backups de VMs/contenedores en labs

### 🎁 Recursos Extra

- **Comunidad**: Únete a [r/docker](https://reddit.com/r/docker) y [r/kubernetes](https://reddit.com/r/kubernetes)
- **Videos**: Busca "Docker tutorial" y "Kubernetes for beginners" en YouTube
- **Práctica**: Usa [Play with Docker](https://labs.play-with-docker.com/) (gratis, online)
- **Certificaciones**: Prepárate para CKA/CKAD con [killer.sh](https://killer.sh)

---

**🎉 ¡Bienvenido al inicio de tu viaje hacia la maestría en Kubernetes!**

*Este área sienta las bases tecnológicas y conceptuales indispensables para comprender cómo Kubernetes orquesta contenedores a escala empresarial.*

**Tiempo total estimado**: 10-12 horas (principiante) | 7-9 horas (intermedio) | 5-6 horas (certificación)  
**Estado**: ✅ 100% Actualizado - Versión 2.0
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