# 🚀 Laboratorios - Instalación de Minikube# Laboratorios del Módulo 03: Instalación de Minikube



Este módulo contiene laboratorios prácticos para la instalación completa de Minikube en una VM.Este directorio contiene laboratorios prácticos paso a paso para aprender a instalar y configurar un entorno de Kubernetes usando Minikube.



## 📋 Índice de Laboratorios---



### [Lab 01: Preparación de VM](./lab-01-preparacion-vm/)## 📚 Laboratorios Disponibles

**Duración:** 30-45 minutos | **Dificultad:** ⭐⭐☆☆☆

### Lab 01: Instalación de Docker

Preparación del entorno base para Minikube.**Archivo**: `instalacion-docker.md`  

**Duración**: 30-40 minutos  

**Objetivos:****Nivel**: Principiante

- Actualizar sistema operativo

- Configurar requisitos previos**Objetivos**:

- Verificar recursos disponibles- Instalar Docker Engine en Ubuntu

- Configurar red y permisos- Configurar permisos de usuario

- Verificar instalación correcta

---- Ejecutar primer contenedor



### [Lab 02: Instalación de Docker](./lab-02-instalacion-docker/)**Prerequisitos**:

**Duración:** 45-60 minutos | **Dificultad:** ⭐⭐☆☆☆- Ubuntu 20.04+

- Acceso sudo

Instalación y configuración de Docker como runtime.- Conexión a internet



**Objetivos:****Relación con ejemplos**:

- Instalar Docker Engine- Script automatizado: `ejemplos/01-instalacion/install-docker.sh`

- Configurar usuario sin sudo- Teoría: README.md - Sección 2

- Verificar instalación

- Configurar daemon---



---### Lab 02: Instalación de kubectl

**Archivo**: `instalacion-kubectl.md`  

### [Lab 03: Instalación de kubectl](./lab-03-instalacion-kubectl/)**Duración**: 20-30 minutos  

**Duración:** 20-30 minutos | **Dificultad:** ⭐☆☆☆☆**Nivel**: Principiante



Instalación de la herramienta CLI de Kubernetes.**Objetivos**:

- Instalar kubectl (cliente de Kubernetes)

**Objetivos:**- Configurar autocomplete

- Descargar kubectl- Comprender comandos básicos

- Instalar y configurar PATH- Preparar entorno para conectarse a clusters

- Verificar instalación

- Autocompletado**Prerequisitos**:

- Ninguno (kubectl es independiente)

---

**Relación con ejemplos**:

### [Lab 04: Instalación de Minikube](./lab-04-instalacion-minikube/)- Script automatizado: `ejemplos/01-instalacion/install-kubectl.sh`

**Duración:** 30-45 minutos | **Dificultad:** ⭐⭐☆☆☆- Autocomplete: `ejemplos/02-configuracion/kubectl-autocomplete-bash.sh`

- Teoría: README.md - Sección 3

Instalación de Minikube.

---

**Objetivos:**

- Descargar Minikube### Lab 03: Instalación de Minikube

- Instalar binario**Archivo**: `instalacion-minikube.md`  

- Verificar instalación**Duración**: 30-45 minutos  

- Configuración inicial**Nivel**: Principiante-Intermedio



---**Objetivos**:

- Instalar Minikube

### [Lab 05: Configuración Driver None](./lab-05-configuracion-driver-none/)- Iniciar primer cluster

**Duración:** 45-60 minutos | **Dificultad:** ⭐⭐⭐☆☆- Comprender parámetros de configuración

- Verificar cluster funcionando

Configuración de Minikube con driver none (bare metal).

**Prerequisitos**:

**Objetivos:**- Docker instalado (Lab 01)

- Entender driver none- kubectl instalado (Lab 02)

- Configurar permisos

- Iniciar Minikube sin VM**Relación con ejemplos**:

- Troubleshooting común- Script instalación: `ejemplos/01-instalacion/install-minikube.sh`

- Script inicio: `ejemplos/02-configuracion/minikube-start-custom.sh`

---- Verificación: `ejemplos/02-configuracion/verify-cluster.sh`

- Teoría: README.md - Sección 4

### [Lab 06: Verificación y Testing](./lab-06-verificacion-testing/)

**Duración:** 45-60 minutos | **Dificultad:** ⭐⭐☆☆☆---



Verificación completa de la instalación.### Lab 04: Preparación de VM

**Archivo**: `preparacion-vm.md`  

**Objetivos:****Duración**: 45-60 minutos  

- Verificar componentes del cluster**Nivel**: Intermedio

- Desplegar aplicación de prueba

- Probar networking**Objetivos**:

- Comandos esenciales- Configurar Azure VM para Kubernetes

- Optimizar recursos del sistema

---- Configurar networking

- Preparar entorno completo de desarrollo

## 🎯 Ruta de Aprendizaje Recomendada

**Prerequisitos**:

Ejecutar los laboratorios **en orden secuencial** (01 → 06):- Azure VM con Ubuntu

- Acceso SSH

1. **Preparación** → Labs 01-02 (VM y Docker)- Conocimientos básicos de Linux

2. **Herramientas** → Labs 03-04 (kubectl y Minikube)

3. **Configuración** → Labs 05-06 (Driver y Verificación)**Contexto**: Este laboratorio es específico para el entorno de Azure VM que usamos en el curso.



**Tiempo total estimado:** 3.5-5 horas---



## 📚 Prerequisitos Generales### Lab 05: Verificación y Testing

**Archivo**: `verificacion-testing.md`  

### Hardware Mínimo**Duración**: 40-60 minutos  

- CPU: 2 cores (4 recomendado)**Nivel**: Intermedio

- RAM: 4GB (8GB recomendado)

- Disco: 20GB libres**Objetivos**:

- Verificar instalación completa

### Software- Ejecutar tests de funcionalidad

- Ubuntu 20.04 o superior- Troubleshooting de problemas comunes

- Acceso root/sudo- Validar cluster production-ready

- Conexión a Internet estable

**Prerequisitos**:

### Conocimientos- Labs 01, 02, 03 completados

- Linux básico (comandos, permisos)- Cluster Minikube funcionando

- Conceptos básicos de virtualización

- Familiaridad con terminal**Relación con ejemplos**:

- Script verificación: `ejemplos/02-configuracion/verify-cluster.sh`

## ⚠️ Importante- Primera app: `ejemplos/03-primeros-pasos/primera-app.sh`

- Teoría: README.md - Sección 7 (Troubleshooting)

### Driver None vs Other Drivers

**Driver None:**---

- ✅ Máximo rendimiento

- ✅ Sin overhead de virtualización### Lab 06: Configuración del Driver (Avanzado)

- ❌ Requiere root**Archivo**: `configuracion-driver-none.md`  

- ❌ Afecta sistema host**Duración**: 60+ minutos  

- **Recomendado solo para VMs dedicadas****Nivel**: Avanzado



**Docker/VirtualBox/etc:****Objetivos**:

- ✅ Aislamiento del host- Comprender driver "none" (bare metal)

- ✅ No requiere root- Configuración avanzada de Minikube

- ❌ Menor rendimiento- Casos de uso especiales

- **Recomendado para desarrollo local**- Limitaciones y consideraciones



## 🧹 Limpieza**⚠️ ADVERTENCIA**: El driver "none" está **deprecado** y NO es recomendado para la mayoría de usuarios.



Para desinstalar completamente:**Prerequisitos**:

```bash- Experiencia con Kubernetes

# Detener y eliminar Minikube- Conocimientos avanzados de Linux

minikube delete --all --purge- Entender riesgos de seguridad



# Eliminar binarios**Recomendación**: Usa este laboratorio solo con propósitos educativos o casos muy específicos. Para uso normal, utiliza el driver Docker (ver `ejemplos/01-instalacion/comparativa-drivers.md`).

sudo rm /usr/local/bin/minikube

sudo rm /usr/local/bin/kubectl---



# Eliminar configuraciones## 🎯 Ruta de Aprendizaje Recomendada

rm -rf ~/.minikube

rm -rf ~/.kube### Para Principiantes Completos

```

```

## 💡 Tips1. preparacion-vm.md           (si usas Azure VM)

   ↓

- Usa `minikube status` para verificar estado2. instalacion-docker.md        (Lab 01)

- `minikube logs` para troubleshooting   ↓

- `minikube ssh` para acceder al node3. instalacion-kubectl.md       (Lab 02)

- Snapshots de VM antes de cambios importantes   ↓

4. instalacion-minikube.md      (Lab 03)
   ↓
5. verificacion-testing.md      (Lab 05)
```

**Tiempo total**: 3-4 horas

---

### Para Usuarios con Experiencia

Si ya tienes Docker/kubectl instalados:

```
1. instalacion-minikube.md      (Lab 03)
   ↓
2. verificacion-testing.md      (Lab 05)
   ↓
3. Ejemplos prácticos           (ejemplos/03-primeros-pasos/)
```

**Tiempo total**: 1-2 horas

---

### Para Exploración Avanzada

```
1. Completar ruta principiante
   ↓
2. configuracion-driver-none.md (Lab 06 - opcional)
   ↓
3. Experimentar con diferentes drivers
   (ver ejemplos/01-instalacion/comparativa-drivers.md)
```

---

## 🚀 Acceso Rápido

### Instalación Automatizada

Si prefieres instalación rápida sin pasos manuales:

```bash
cd ../ejemplos/02-configuracion
./setup-environment.sh
```

Este script ejecuta automáticamente:
- Instalación de Docker (si no está)
- Instalación de kubectl (si no está)
- Instalación de Minikube (si no está)
- Configuración de autocomplete
- Verificación completa

**Después**, continúa con los laboratorios para entender qué se instaló.

---

### Instalación Manual Paso a Paso

Para aprender el proceso completo:

```bash
# Lab 01: Docker
cd laboratorios
# Seguir instrucciones en instalacion-docker.md

# Lab 02: kubectl
# Seguir instrucciones en instalacion-kubectl.md

# Lab 03: Minikube
# Seguir instrucciones en instalacion-minikube.md

# Lab 05: Verificación
# Seguir instrucciones en verificacion-testing.md
```

---

## 📋 Checklist de Progreso

Marca los laboratorios a medida que los completas:

- [ ] **Lab 04**: Preparación de VM (Azure VM)
- [ ] **Lab 01**: Instalación de Docker
- [ ] **Lab 02**: Instalación de kubectl
- [ ] **Lab 03**: Instalación de Minikube
- [ ] **Lab 05**: Verificación y Testing
- [ ] **Opcional**: Primera aplicación (`ejemplos/03-primeros-pasos/primera-app.sh`)
- [ ] **Opcional**: Manifiestos YAML (`ejemplos/03-primeros-pasos/*.yaml`)
- [ ] **Lab 06**: Configuración avanzada (solo si es necesario)

---

## 🔗 Integración con Ejemplos

Los laboratorios están **complementados** por ejemplos automatizados:

| Laboratorio | Script Relacionado | Propósito |
|-------------|-------------------|-----------|
| Lab 01 (Docker) | `ejemplos/01-instalacion/install-docker.sh` | Automatización |
| Lab 02 (kubectl) | `ejemplos/01-instalacion/install-kubectl.sh` | Automatización |
| Lab 03 (Minikube) | `ejemplos/01-instalacion/install-minikube.sh` | Automatización |
| Lab 03 (Minikube) | `ejemplos/02-configuracion/minikube-start-custom.sh` | Configuración |
| Lab 05 (Verificación) | `ejemplos/02-configuracion/verify-cluster.sh` | Diagnóstico |
| - | `ejemplos/03-primeros-pasos/primera-app.sh` | Práctica |

**Enfoque pedagógico**:
1. **Leer** teoría en README.md principal
2. **Practicar** con laboratorios (manual, paso a paso)
3. **Automatizar** con scripts de ejemplos
4. **Experimentar** con manifiestos YAML

---

## 🛠️ Troubleshooting por Laboratorio

### Lab 01: Docker
**Problema común**: "Cannot connect to Docker daemon"
```bash
# Solución
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker
```

### Lab 02: kubectl
**Problema común**: "kubectl: command not found"
```bash
# Solución
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Lab 03: Minikube
**Problema común**: "Exiting due to DRV_NOT_HEALTHY"
```bash
# Solución
# Ver ejemplos/02-configuracion/verify-cluster.sh
minikube delete
minikube start --driver=docker
```

### Lab 05: Verificación
**Problema común**: Pods en estado CrashLoopBackOff
```bash
# Diagnóstico
kubectl describe pod <nombre-pod>
kubectl logs <nombre-pod>
# Ver README.md - Sección 7 (Troubleshooting)
```

---

## 📖 Recursos Adicionales

### Documentación Complementaria
- **README principal**: `../README.md` - Teoría completa
- **Ejemplos**: `../ejemplos/README.md` - Guía de scripts
- **Comparativa de drivers**: `../ejemplos/01-instalacion/comparativa-drivers.md`
- **Cheat sheet**: `../ejemplos/02-configuracion/minikube-cheatsheet.md`

### Referencias Externas
- [Documentación oficial de Minikube](https://minikube.sigs.k8s.io/docs/)
- [Documentación de Docker](https://docs.docker.com/)
- [Documentación de kubectl](https://kubernetes.io/docs/reference/kubectl/)

---

## ✅ Verificación Final

Después de completar los laboratorios, deberías poder:

```bash
# Verificar versiones instaladas
docker --version
kubectl version --client
minikube version

# Verificar cluster funcionando
minikube status
kubectl get nodes

# Desplegar aplicación de prueba
kubectl create deployment test --image=nginx
kubectl get pods

# Limpiar
kubectl delete deployment test
```

Si todos estos comandos funcionan, ¡has completado exitosamente el módulo! 🎉

---

## 🎓 Próximos Pasos

Una vez completados estos laboratorios, continúa con:

1. **Módulo 04**: Pods vs Contenedores
2. **Módulo 05**: Gestión de Pods
3. **Módulo 06**: ReplicaSets y Réplicas

Todos los módulos siguientes asumen que tienes Minikube instalado y funcionando.

---

## 📝 Notas Importantes

### Sobre el Driver "None"
El laboratorio `configuracion-driver-none.md` existe con propósitos educativos, pero:
- ⚠️ El driver "none" está **deprecado**
- ⚠️ No proporciona aislamiento
- ⚠️ Puede causar conflictos con el sistema
- ⚠️ Dificulta la limpieza

**Recomendación**: Usa el driver Docker para este curso.

### Sobre Azure VM
El laboratorio `preparacion-vm.md` es específico para nuestro entorno de curso. Si usas otra plataforma:
- Local: Salta este laboratorio
- AWS/GCP: Adapta los comandos según tu proveedor
- Bare metal: Verifica prerequisitos de hardware

### Actualización de Contenidos
Los laboratorios fueron creados originalmente para configuraciones específicas. El nuevo README principal y los ejemplos proporcionan:
- ✅ Enfoque actualizado (driver Docker)
- ✅ Scripts automatizados
- ✅ Mejor troubleshooting
- ✅ Buenas prácticas actuales

**Sugerencia**: Usa los laboratorios existentes para **práctica manual** y los scripts de ejemplos para **automatización y referencia**.

---

**Última actualización**: Noviembre 2024  
**Mantenido por**: Equipo del curso de Kubernetes
