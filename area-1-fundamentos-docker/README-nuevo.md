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