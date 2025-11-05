# Módulo 3: Instalación y Configuración de Minikube

**Duración**: 60 minutos  
**Objetivo**: Configurar un entorno local de Kubernetes usando Minikube en Azure VM

## 🎯 Objetivos de aprendizaje

- Instalar y configurar Minikube en una VM de Azure
- Configurar kubectl con autocompletado
- Entender los diferentes drivers de Minikube
- Implementar Minikube con driver `none` para acceso directo
- Verificar la instalación y funcionamiento del cluster

---

## 📋 Prerequisitos

- VM de Azure configurada (2 vCPUs, 4GB RAM mínimo)
- Acceso SSH a la VM
- Usuario con permisos sudo
- Conexión a internet estable

---

## 🏗️ Arquitectura del entorno

```
┌─────────────────────────────────────────┐
│              Azure VM                   │
│  ┌─────────────────────────────────────┐│
│  │          Minikube Cluster           ││
│  │                                     ││
│  │ ┌─────────────┐ ┌─────────────────┐ ││
│  │ │   kubectl   │ │  Control Plane  │ ││
│  │ │   (client)  │ │  - API Server   │ ││
│  │ │             │ │  - etcd         │ ││
│  │ └─────────────┘ │  - Scheduler    │ ││
│  │                 │  - Controller   │ ││
│  │ ┌─────────────┐ └─────────────────┘ ││
│  │ │    Pods     │ ┌─────────────────┐ ││
│  │ │ Workloads   │ │     kubelet     │ ││
│  │ │             │ │   (Node Agent)  │ ││
│  │ └─────────────┘ └─────────────────┘ ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

---

## 🔧 Opciones de drivers de Minikube

### **Driver Docker**
```bash
# Ventajas:
✅ Fácil instalación
✅ Aislamiento completo
✅ Compatible con la mayoría de sistemas

# Desventajas:
❌ Overhead de contenedor adicional
❌ Acceso limitado a servicios
❌ Problemas con LoadBalancer
```

### **Driver VirtualBox/VMware**
```bash
# Ventajas:
✅ VM completa aislada
✅ Simula entorno real

# Desventajas:
❌ Alto consumo de recursos
❌ Complejidad de red
❌ Rendimiento limitado
```

### **Driver None (Recomendado para este curso)**
```bash
# Ventajas:
✅ Acceso directo a todos los servicios
✅ Máximo rendimiento
✅ Ideal para desarrollo y aprendizaje
✅ Sin overhead de virtualización

# Desventajas:
❌ Menor aislamiento
❌ Requiere configuración manual
❌ Solo para entornos de desarrollo
```

---

## 📚 Contenido del módulo

### **Laboratorios prácticos:**
1. **[Lab 3.1: Preparación de la VM](./laboratorios/preparacion-vm.md)**
   - Configuración del sistema
   - Instalación de dependencias
   - Configuración de usuario

2. **[Lab 3.2: Instalación de Docker](./laboratorios/instalacion-docker.md)**
   - Instalación y configuración de Docker
   - Verificación del funcionamiento
   - Configuración de permisos

3. **[Lab 3.3: Instalación de kubectl](./laboratorios/instalacion-kubectl.md)**
   - Descarga e instalación de kubectl
   - Configuración de autocompletado
   - Verificación de funcionalidad

4. **[Lab 3.4: Instalación de Minikube](./laboratorios/instalacion-minikube.md)**
   - Descarga e instalación de Minikube
   - Configuración inicial
   - Comparación de drivers

5. **[Lab 3.5: Configuración con Driver None](./laboratorios/configuracion-driver-none.md)**
   - Configuración específica para driver none
   - Inicio del cluster
   - Verificación del funcionamiento

6. **[Lab 3.6: Verificación y Testing](./laboratorios/verificacion-testing.md)**
   - Pruebas de funcionalidad
   - Despliegue de aplicación de prueba
   - Troubleshooting común

### **Ejemplos de código:**
- Scripts de instalación automatizada
- Configuraciones de kubectl
- Manifiestos de prueba
- Scripts de verificación

---

## 🎯 Resultados esperados

Al completar este módulo, tendrás:

### **✅ Entorno funcionando:**
- Minikube instalado y configurando
- kubectl configurado con autocompletado
- Cluster de Kubernetes local operativo
- Acceso directo a todos los servicios

### **✅ Conocimientos adquiridos:**
- Diferentes opciones de instalación de Kubernetes local
- Ventajas y desventajas de cada driver
- Configuración de herramientas CLI
- Troubleshooting básico de Minikube

### **✅ Habilidades prácticas:**
- Gestión de clusters locales
- Uso de kubectl avanzado
- Configuración de entornos de desarrollo
- Resolución de problemas comunes

---

## 🚀 Comandos esenciales que aprenderás

```bash
# Gestión del cluster
minikube start --driver=none
minikube status
minikube stop
minikube delete

# Información del cluster
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

# Configuración de kubectl
kubectl config view
kubectl config current-context
kubectl config use-context minikube

# Autocompletado y ayuda
kubectl completion bash
kubectl explain pods
kubectl get pods --help
```

---

## 📊 Métricas de éxito

| Criterio | Verificación |
|----------|-------------|
| **Minikube funcionando** | `minikube status` → Running |
| **kubectl conectado** | `kubectl get nodes` → Ready |
| **Pods del sistema** | `kubectl get pods -n kube-system` → Running |
| **Autocompletado** | `kubectl get po<TAB>` → pods |
| **Acceso a servicios** | Pods accesibles directamente |

---

## 🔗 Recursos adicionales

- [Documentación oficial de Minikube](https://minikube.sigs.k8s.io/docs/)
- [Instalación de kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Autocompletado de kubectl](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-autocomplete)
- [Troubleshooting de Minikube](https://minikube.sigs.k8s.io/docs/handbook/troubleshooting/)

---

## ⚠️ Consideraciones importantes

### **Requisitos de sistema:**
- **RAM**: Mínimo 4GB (recomendado 8GB)
- **CPU**: Mínimo 2 cores
- **Disk**: 20GB libres mínimo
- **OS**: Ubuntu 20.04+ o distribución compatible

### **Seguridad:**
- El driver `none` ejecuta como root
- Solo para entornos de desarrollo/aprendizaje
- No usar en producción
- Considerar firewall y acceso a puertos

### **Limitaciones:**
- Driver `none` requiere privilegios elevados
- Algunos addons pueden no funcionar completamente
- Configuración manual de ciertos componentes

---

**Tiempo estimado de completado**: 60-90 minutos  
**Nivel de dificultad**: Intermedio  
**Prerequisitos técnicos**: Conocimientos básicos de Linux y Docker