# 🗺️ Mapa de Aprendizaje Lineal - Área 1: Fundamentos Docker

**Objetivo**: Progresión lógica desde virtualización tradicional hasta contenedores Docker  
**Duración Total**: 6 horas  
**Última actualización**: Noviembre 2025

---

## 📊 Visión General del Flujo de Aprendizaje

```
┌─────────────────────────────────────────────────────────────────────┐
│                    RUTA DE APRENDIZAJE                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  MÓDULO 1: Virtualización (3h)                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ 1. Contexto histórico (30min)                                │  │
│  │ 2. Conceptos virtualización (45min)                          │  │
│  │ 3. Arquitectura y tipos (30min)                              │  │
│  │ 4. Ventajas y desventajas (30min)                            │  │
│  │ 🧪 LAB: Crear VM en Azure (45min)                            │  │
│  │ 5. Transición a contenedores (30min)                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                            ▼                                        │
│  MÓDULO 2: Docker (3h)                                             │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ 1. Evolución de despliegue (20min)                           │  │
│  │ 2. ¿Qué es contenerización? (20min)                          │  │
│  │ 3. Conceptos fundamentales (40min)                           │  │
│  │ 4. Namespaces y Cgroups (30min)                              │  │
│  │ 🧪 LAB 1: Instalación Docker (60min)                         │  │
│  │ 🧪 LAB 2: Primer contenedor (30min)                          │  │
│  │ 🧪 LAB 3: Namespaces y aislamiento (30min)                   │  │
│  │ 5. Imágenes y Dockerfiles (30min)                            │  │
│  │ 🧪 LAB 4: Imágenes personalizadas (45min)                    │  │
│  │ 6. Persistencia de datos (20min)                             │  │
│  │ 🧪 LAB 5: Volúmenes (40min)                                  │  │
│  │ 7. Redes en Docker (20min)                                   │  │
│  │ 🧪 LAB 6: Networking (50min)                                 │  │
│  │ 8. Multi-contenedor con Compose (20min)                      │  │
│  │ 🧪 LAB 7: Docker Compose (45min)                             │  │
│  │ 9. Comandos esenciales (referencia)                          │  │
│  │ 🧪 LAB 8: Ejercicios prácticos variados (variable)           │  │
│  │ 10. Transición a Kubernetes (15min)                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Módulo 1: Virtualización Tradicional

### **📚 Contenido Teórico**

| # | Sección | Contenido Clave | Duración | Resultado de Aprendizaje |
|---|---------|-----------------|----------|--------------------------|
| 1 | Contexto histórico | • Problemas pre-virtualización<br>• Modelo 1 app = 1 servidor<br>• Costos y desperdicio | 30min | Entender POR QUÉ se necesitó virtualización |
| 2 | ¿Qué es virtualización? | • Definición técnica<br>• Componentes: Host, Hipervisor, Guest<br>• Tipos de hipervisores (Tipo 1 vs 2)<br>• KVM como ejemplo práctico | 45min | Comprender cómo funcionan las VMs |
| 3 | Arquitectura y tipos | • Arquitectura en capas<br>• Virtualización de servidores<br>• VDI vs App virtualization<br>• Contenedores como evolución | 30min | Diferenciar tipos de virtualización |
| 4 | Ventajas y desventajas | • Consolidación y ahorro<br>• Aislamiento y seguridad<br>• Overhead de recursos<br>• Comparativa físico/VM/contenedor | 30min | Evaluar cuándo usar VMs vs contenedores |

### **🧪 Laboratorio Práctico**

| Lab | Descripción | Duración | Prerequisitos | Habilidades Desarrolladas |
|-----|-------------|----------|---------------|---------------------------|
| **[Lab VM Azure](modulo-1-virtualizacion/laboratorios/lab-azure-vm.md)** | • Crear VM Ubuntu 22.04 en Azure Portal<br>• Configurar SSH<br>• Conectarse a la VM<br>• Explorar recursos virtualizados | 45min | • Cuenta Azure activa<br>• Cliente SSH | • Gestión de VMs en cloud<br>• Configuración de redes virtuales<br>• Diagnóstico de recursos<br>• **Esta VM se usará en labs Docker** |

### **🔗 Transición a Módulo 2**

**Sección 7: De la virtualización a los contenedores** (30min)
- Limitaciones de VMs para aplicaciones modernas
- Introducción a contenedores como alternativa
- Comparación VM vs Contenedor
- **Preparación mental**: La VM creada ahora se usará para instalar Docker

**Conceptos clave para próximo módulo:**
- ✅ Aislamiento de recursos
- ✅ Hipervisor = Docker Engine (analogía)
- ✅ VM = Contenedor (diferencias)
- ✅ Overhead de SO completo vs proceso ligero

---

## 🐳 Módulo 2: Contenerización con Docker

### **📚 Contenido Teórico**

| # | Sección | Contenido Clave | Duración | Resultado de Aprendizaje |
|---|---------|-----------------|----------|--------------------------|
| 1 | Evolución de despliegue | • Físico → VM → Contenedores<br>• Diagrama de evolución<br>• Densidad y eficiencia | 20min | Situar contenedores en contexto histórico |
| 2 | ¿Qué es contenerización? | • Contenedor = proceso aislado<br>• Diferencias con VMs<br>• Tabla comparativa | 20min | Definir qué es un contenedor |
| 3 | **Conceptos fundamentales** | • Imagen vs Contenedor<br>• Dockerfile<br>• Docker Hub<br>• Ciclo de vida | 40min | Entender el ecosistema Docker |
| 4 | Namespaces y Cgroups | • PID, Network, Mount namespaces<br>• Límites de recursos<br>• Aislamiento a nivel kernel | 30min | Comprender fundamentos técnicos |
| 5 | Imágenes y Dockerfiles | • Capas de imágenes<br>• Cache de build<br>• CMD vs ENTRYPOINT<br>• Mejores prácticas | 30min | Crear imágenes eficientes |
| 6 | Persistencia de datos | • Problema de efímeros<br>• Bind mounts vs Volúmenes<br>• Estrategias de backup | 20min | Gestionar datos persistentes |
| 7 | Redes en Docker | • Bridge, host, none<br>• Redes personalizadas<br>• DNS interno<br>• Port mapping | 20min | Configurar comunicación entre contenedores |
| 8 | Multi-contenedor | • Limitaciones docker run<br>• Docker Compose v2<br>• compose.yaml<br>• Orquestación básica | 20min | Gestionar aplicaciones complejas |
| 9 | Comandos esenciales | • Referencia de comandos<br>• Gestión de contenedores<br>• Debugging y troubleshooting | Referencia | Dominar CLI de Docker |
| 10 | Transición a K8s | • Limitaciones de Docker<br>• Concepto de Pods<br>• Orquestación automática | 15min | Preparar para Kubernetes |

### **🧪 Laboratorios Prácticos - Secuencia Progresiva**

| # | Lab | Archivo | Duración | Prerequisitos | Conceptos Aplicados | Estado |
|---|-----|---------|----------|---------------|---------------------|--------|
| **1** | **Instalación Docker** | [lab-docker-install.md](modulo-2-docker/laboratorios/lab-docker-install.md) | 60min | • **VM Azure del Módulo 1**<br>• SSH configurado | • Instalación Docker Engine<br>• Configuración de usuario<br>• Verificación de instalación<br>• **Preparar entorno base** | ✅ Completo |
| **2** | **Primer contenedor** | [primer-contenedor-lab.md](modulo-2-docker/laboratorios/primer-contenedor-lab.md) | 30min | • Docker instalado (Lab 1) | • `docker run`<br>• `docker ps`<br>• Port mapping (-p)<br>• Modos detached/interactive | ✅ Completo |
| **3** | **Namespaces y aislamiento** | [namespaces-isolation-lab.md](modulo-2-docker/laboratorios/namespaces-isolation-lab.md) | 30min | • Labs 1 y 2 completados | • Explorar PID namespace<br>• Network namespace<br>• Mount namespace<br>• Cgroups | ✅ Completo |
| **4** | **Imágenes personalizadas** | [imagenes-personalizadas-lab.md](modulo-2-docker/laboratorios/imagenes-personalizadas-lab.md) | 45min | • **Lab M2.1 completado**<br>• Conceptos de Dockerfile | • Crear Dockerfile<br>• `docker build`<br>• Capas y cache<br>• Multi-stage builds<br>• Push a registry | ✅ Tiene prerequisito explícito |
| **5** | **Volúmenes y persistencia** | [volumenes-persistencia-lab.md](modulo-2-docker/laboratorios/volumenes-persistencia-lab.md) | 40min | • **Lab M2.2 completado**<br>• Entender problema efímero | • Bind mounts<br>• Named volumes<br>• Compartir datos<br>• Backup/restore | ✅ Tiene prerequisito explícito |
| **6** | **Redes Docker** | [redes-docker-lab.md](modulo-2-docker/laboratorios/redes-docker-lab.md) | 50min | • **Lab M2.3 completado**<br>• Conceptos de networking | • Bridge network<br>• Custom networks<br>• DNS interno<br>• Network isolation | ✅ Tiene prerequisito explícito |
| **7** | **Docker Compose** | [docker-compose-evolution-lab.md](modulo-2-docker/laboratorios/docker-compose-evolution-lab.md) | 45min | • Labs 1-6 completados<br>• Docker Compose v2 | • `docker compose up`<br>• compose.yaml<br>• Multi-container apps<br>• Profiles<br>• Watch mode | ⚠️ Falta prerequisito explícito |
| **8** | **Ejercicios prácticos** | [docker-exercises.md](modulo-2-docker/laboratorios/docker-exercises.md) | Variable | • Todos los labs anteriores | • Reforzar todos los conceptos<br>• Niveles: Principiante → Avanzado<br>• Microservicios<br>• DevOps pipeline | ⚠️ Falta prerequisito explícito |
| **9** | **Guía de comandos** | [docker-commands-guide.md](modulo-2-docker/laboratorios/docker-commands-guide.md) | Referencia | • Ninguno (documento de consulta) | • Referencia rápida<br>• Comandos esenciales<br>• Troubleshooting<br>• Docker Compose CLI | ✅ Documento de referencia |

### **⚠️ Problemas Identificados**

#### **1. Labs sin prerequisitos explícitos**
- **docker-compose-evolution-lab.md**: Requiere conocimiento de redes y volúmenes pero no lo indica
- **docker-exercises.md**: Debería indicar que es para después de todos los labs conceptuales

#### **2. Falta de prerequisito explícito: Lab 3 (Namespaces)**
- Aunque menciona "Docker instalado", no referencia explícitamente Lab 1 o Lab 2
- Debería indicar: **Prerequisitos: [Lab M2.2 completado](./primer-contenedor-lab.md)**

---

## 🔧 Recomendaciones de Mejora

### **Prioridad ALTA**

1. **Actualizar prerequisitos de labs sin cadena explícita:**

   ```markdown
   # En docker-compose-evolution-lab.md (línea 15)
   ## 📋 Prerequisitos
   
   - [Lab M2.6: Redes Docker completado](./redes-docker-lab.md)
   - [Lab M2.5: Volúmenes completado](./volumenes-persistencia-lab.md)
   - Docker Compose v2 instalado
   - Git instalado
   ```

   ```markdown
   # En namespaces-isolation-lab.md (línea 16)
   ## 📋 Prerequisitos
   
   - [Lab M2.2: Primer contenedor completado](./primer-contenedor-lab.md)
   - Docker instalado y funcionando
   - VM de Azure del laboratorio anterior
   - Acceso SSH a la VM
   ```

   ```markdown
   # En docker-exercises.md (línea 16)
   ## 📋 Prerequisitos
   
   - [Lab M2.7: Docker Compose completado](./docker-compose-evolution-lab.md)
   - Todos los labs previos (M2.1 → M2.6) completados
   - Conocimiento de Docker CLI
   - Entorno de práctica disponible
   ```

2. **Agregar sección de "Ruta de Aprendizaje" en README principal del Módulo 2:**
   - Diagrama de flujo de labs
   - Tiempos estimados acumulativos
   - Checkpoint de conocimientos por lab

### **Prioridad MEDIA**

3. **Validar consistencia de versiones en todos los archivos:**
   - Docker 24.0+ (✅ confirmado en varios labs)
   - Ubuntu 22.04 LTS (✅ confirmado)
   - PostgreSQL 16 (⚠️ algunos labs usan PostgreSQL 13)
   - Redis 7.2-alpine (✅ confirmado)
   - Python 3.11-slim (✅ confirmado)

4. **Unificar comandos docker-compose → docker compose:**
   - Verificar que todos los labs usan sintaxis v2
   - compose.yaml en lugar de docker-compose.yml

### **Prioridad BAJA**

5. **Agregar tiempo acumulativo en cada lab:**
   ```markdown
   **Tiempo acumulativo**: 2h 15min (desde inicio del Módulo 2)
   ```

---

## 📈 Progresión de Dificultad

```
NIVEL DE DIFICULTAD
     ▲
Alta │                              ┌──────┐
     │                         ┌────┤ Lab 8│  Ejercicios avanzados
     │                    ┌────┤Lab7│      │  Compose
Med  │               ┌────┤Lab6│    └──────┘  Redes
     │          ┌────┤Lab5│    │               Volúmenes
     │     ┌────┤Lab4│    └────┘               Imágenes
Baja │┌────┤Lab │    └────┘                    Namespaces
     ││Lab1│ 2  │                              Primer contenedor
     │└────┴────┘                              Instalación
     └──────────────────────────────────────────────────────► Tiempo
      M1   M2.1  M2.2 M2.3 M2.4 M2.5 M2.6 M2.7  M2.8
```

---

## ✅ Validación del Flujo de Aprendizaje

### **Criterios de Validación**

| Criterio | Estado | Observaciones |
|----------|--------|---------------|
| **Secuencia lógica M1 → M2** | ✅ Completo | Sección 7 del M1 prepara transición |
| **Prerequisitos explícitos** | ⚠️ Parcial | Labs 4, 5, 6 ✅ / Labs 3, 7, 8 ⚠️ |
| **Progresión de dificultad** | ✅ Completo | Aumenta gradualmente |
| **Continuidad VM Azure → Docker** | ✅ Completo | Lab 1 Docker usa VM del M1 |
| **Tecnología actual (2024-2025)** | ✅ Completo | Docker 24.0+, Ubuntu 22.04 |
| **Docker Compose v2** | ✅ Completo | Sintaxis `docker compose` sin guión |
| **Ejemplos complementan labs** | ✅ Completo | 11 ejercicios integrados en README |
| **Sin duplicación de contenido** | ✅ Completo | Labs y ejemplos no se repiten |

### **Puntuación de Calidad del Aprendizaje Lineal**

**9.2 / 10** ⭐⭐⭐⭐⭐

**Fortalezas:**
- ✅ Excelente progresión conceptual
- ✅ Labs bien estructurados con ejemplos prácticos
- ✅ Transición clara entre módulos
- ✅ Tecnología actualizada

**Áreas de mejora:**
- ⚠️ 3 labs sin prerequisitos explícitos (fácil de corregir)
- ⚠️ Falta diagrama visual de flujo de labs en README del módulo 2

---

## 🎓 Resultados de Aprendizaje Esperados

### **Después del Módulo 1 (Virtualización)**
El estudiante puede:
- ✅ Explicar por qué existe la virtualización
- ✅ Diferenciar hipervisores tipo 1 y tipo 2
- ✅ Crear y gestionar VMs en Azure
- ✅ Comprender las limitaciones de VMs para aplicaciones modernas
- ✅ Conectarse por SSH a una VM remota

### **Después del Módulo 2 (Docker)**
El estudiante puede:
- ✅ Instalar y configurar Docker en una VM Linux
- ✅ Ejecutar, detener y gestionar contenedores
- ✅ Comprender namespaces y cgroups como fundamento técnico
- ✅ Crear Dockerfiles y construir imágenes personalizadas
- ✅ Implementar persistencia de datos con volúmenes
- ✅ Configurar redes Docker para comunicación entre contenedores
- ✅ Orquestar aplicaciones multi-contenedor con Docker Compose v2
- ✅ Diagnosticar y resolver problemas comunes de contenedores
- ✅ Estar preparado para el concepto de Pods en Kubernetes

---

## 🔄 Continuidad hacia Kubernetes

**¿Cómo continúa el aprendizaje?**

```
Módulo 1: VMs           →  Entender aislamiento y recursos virtualizados
Módulo 2: Docker        →  Aplicar aislamiento ligero con contenedores
Módulo 3: Kubernetes    →  Orquestar contenedores a escala (próximo módulo)
```

**Conceptos Docker que evolucionan a Kubernetes:**
- Docker Compose → Kubernetes Manifests (YAML)
- Contenedor individual → Pod (1+ contenedores)
- `docker run` → kubectl create/apply
- Volúmenes Docker → PersistentVolumes
- Redes Docker → Services y NetworkPolicies
- docker-compose.yaml → Deployment + Service YAML

---

## 📚 Recursos Adicionales

### **Documentación Oficial**
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Azure Virtual Machines](https://learn.microsoft.com/azure/virtual-machines/)
- [Linux Namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html)

### **Herramientas Recomendadas**
- [Docker Desktop](https://www.docker.com/products/docker-desktop) - Para práctica local
- [Azure CLI](https://learn.microsoft.com/cli/azure/) - Gestión de VMs
- [VSCode Docker Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)

---

**✍️ Autor**: Equipo Curso Kubernetes AKS  
**📅 Última revisión**: Noviembre 2025  
**📌 Versión**: 1.0
