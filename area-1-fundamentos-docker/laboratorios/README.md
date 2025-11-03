# 🧪 Laboratorios - Área 1: Fundamentos Docker

**Duración total**: 8 horas  
**Modalidad**: Teórico-Práctico

Este área ha sido **reestructurada en dos módulos** para mejor comprensión y progresión del aprendizaje:

---

## 🖥️ **Configuración del Entorno**

**IMPORTANTE**: Antes de comenzar los laboratorios, configura tu entorno de desarrollo:

### **📚 [Guía de Configuración VS Code Tunnel en Azure](./setup-vscode-server.md)**

Esta guía te permitirá:
- ✅ **Ejecutar VS Code desde el navegador** con tunnels seguros
- ✅ **Acceder desde cualquier dispositivo** sin configurar puertos
- ✅ **Autenticación con GitHub/Microsoft** sin contraseñas adicionales
- ✅ **Entorno consistente** para todos los estudiantes
- ✅ **Docker preconfigurado** listo para los laboratorios
- ✅ **Sincronización automática** de configuración y extensiones

**⏱️ Tiempo de configuración**: 20-30 minutos una sola vez

---

## 🏗️ Estructura Modular

### � **Módulo 1: Virtualización** (3 horas)
*Fundamentos de infraestructura y evolución histórica*

| Laboratorio | Duración | Dificultad | Ubicación |
|-------------|----------|------------|-----------|
| **[Lab M1: Creación VM Azure](../modulo-1-virtualizacion/laboratorios/lab-azure-vm.md)** | 45 min | Principiante | `modulo-1-virtualizacion/laboratorios/` |

**Conceptos cubiertos:**
- Evolución de modelos de deployment
- Creación y gestión de VMs en Azure
- Preparación del entorno para contenerización
- Comparación VMs vs Contenedores

---

### 📁 **Módulo 2: Docker** (5 horas)
*Contenerización avanzada y preparación para Kubernetes*

| Laboratorio | Duración | Dificultad | Ubicación |
|-------------|----------|------------|-----------|
| **[Lab M2.1: Primer Contenedor](../modulo-2-docker/laboratorios/primer-contenedor-lab.md)** | 30 min | Principiante | `modulo-2-docker/laboratorios/` |
| **[Lab M2.2: Imágenes Personalizadas](../modulo-2-docker/laboratorios/imagenes-personalizadas-lab.md)** | 45 min | Intermedio | `modulo-2-docker/laboratorios/` |
| **[Lab M2.3: Volúmenes y Persistencia](../modulo-2-docker/laboratorios/volumenes-persistencia-lab.md)** | 40 min | Intermedio | `modulo-2-docker/laboratorios/` |
| **[Lab M2.4: Redes Docker](../modulo-2-docker/laboratorios/redes-docker-lab.md)** | 35 min | Intermedio | `modulo-2-docker/laboratorios/` |
| **[Lab M2.5: Aislamiento Namespaces](../modulo-2-docker/laboratorios/namespaces-isolation-lab.md)** ⭐ | 30 min | Intermedio | `modulo-2-docker/laboratorios/` |
| **[Lab M2.6: Docker Compose Evolution](../modulo-2-docker/laboratorios/docker-compose-evolution-lab.md)** ⭐ | 45 min | Avanzado | `modulo-2-docker/laboratorios/` |

**⭐ = Laboratorios nuevos/mejorados**

**Conceptos cubiertos:**
- Arquitectura de contenedores y namespaces
- Construcción y gestión de imágenes
- Persistencia de datos y networking
- **Namespaces en profundidad** (IPC, PID, Network, Mount, User, UTS)
- **Cgroups** y control de recursos
- **Docker Compose** como preparación para Kubernetes
- **Evolución hacia orquestación**

---

## 🎯 Progresión de Aprendizaje

```
1️⃣ Infraestructura Tradicional (VMs)
         ↓
2️⃣ Contenerización Básica (Docker)
         ↓  
3️⃣ Namespaces y Aislamiento
         ↓
4️⃣ Aplicaciones Multi-Contenedor
         ↓
5️⃣ Preparación para Kubernetes
```

---

## 📚 Laboratorios de Soporte

### **Instalación y Configuración:**
- **[Instalación Docker](../modulo-2-docker/laboratorios/lab-docker-install.md)** - Setup inicial
- **[Comandos básicos](../modulo-2-docker/laboratorios/docker-commands-guide.md)** - Referencia rápida  
- **[Ejercicios prácticos](../modulo-2-docker/laboratorios/docker-exercises.md)** - Práctica adicional

---

## 🚀 Instrucciones de Ejecución

### **Orden recomendado:**

1. **Completar Módulo 1** completo antes de continuar
2. **Seguir secuencia numérica** en Módulo 2 (M2.1 → M2.2 → M2.3 → etc.)
3. **Verificar prerequisitos** de cada laboratorio
4. **Guardar outputs importantes** para referencia en módulos posteriores

### **Prerequisitos generales:**
- ✅ Cuenta de Azure con permisos de Contributor
- ✅ Cliente SSH configurado
- ✅ Editor de texto (VS Code recomendado)
- ✅ Conocimientos básicos de línea de comandos

---

## 💡 Nuevas Características

### **🔬 Laboratorios Técnicos Avanzados:**

**Lab M2.5: Aislamiento Namespaces** - **NUEVO** ⭐
- Exploración práctica de cada tipo de namespace
- Demostración de aislamiento entre contenedores
- Comparación técnica con VMs del Módulo 1
- Ejercicios de troubleshooting

**Lab M2.6: Docker Compose Evolution** - **NUEVO** ⭐  
- Limitaciones de Docker standalone
- Aplicación multi-contenedor completa
- Preparación conceptual para Kubernetes
- Identificación de problemas que K8s resuelve

### **� Mejoras de Contenido:**
- ✅ **Explicaciones técnicas detalladas** de namespaces y cgroups
- ✅ **Comparaciones prácticas** VMs vs Contenedores vs Kubernetes
- ✅ **Evolución conceptual** clara hacia orquestación
- ✅ **Ejercicios de reflexión** que preparan para Área 2

---

## 🎓 Objetivos de Aprendizaje

Al completar estos laboratorios, los estudiantes podrán:

### **Módulo 1 - Virtualización:**
- ✅ Crear y gestionar VMs en Azure
- ✅ Entender la evolución de modelos de deployment
- ✅ Comparar ventajas/desventajas de VMs

### **Módulo 2 - Docker:**
- ✅ Trabajar con contenedores Docker en producción
- ✅ **Explicar el aislamiento de namespaces** en detalle
- ✅ **Construir aplicaciones multi-contenedor** complejas
- ✅ **Identificar limitaciones** de Docker standalone
- ✅ **Prepararse conceptualmente** para Kubernetes

---

## 🔗 Preparación para Kubernetes

### **Conceptos que se transferirán al Área 2:**

| Concepto Docker | Equivalente Kubernetes |
|-----------------|------------------------|
| Contenedores individuales | Pods |
| Docker networks | Services + Ingress |
| Docker volumes | PersistentVolumes |
| Docker Compose | Deployments + Services |
| Namespaces (Docker) | Namespaces (K8s) |
| Resource limits | Resource quotas |

---

## 📊 Tiempo Total Estimado

| Componente | Duración |
|------------|----------|
| **Módulo 1** | 3 horas |
| **Módulo 2** | 5 horas |
| **Total Área 1** | **8 horas** |

---

## 📝 Notas Importantes

- 💰 **Costos Azure**: Los laboratorios generan costos mínimos (~$5-10 USD)
- 🖥️ **SO Compatibilidad**: Comandos probados en Ubuntu 22.04 LTS  
- 🔧 **Troubleshooting**: Cada laboratorio incluye sección de resolución de problemas
- 📚 **Documentación**: READMEs detallados con explicaciones técnicas

---

## ⏭️ Siguiente Área

Una vez completados estos laboratorios, estarás listo para:

**[🚀 Área 2: Kubernetes Core](../../area-2-kubernetes-core/README.md)**

Los conceptos de containerización, namespaces, y orquestación que aprendas aquí serán fundamentales para entender Kubernetes en profundidad.