# Laboratorios del Módulo 03: Instalación de Minikube

Este directorio contiene laboratorios prácticos paso a paso para aprender a instalar y configurar un entorno de Kubernetes usando Minikube.

---

## 📚 Laboratorios Disponibles

### Lab 01: Instalación de Docker
**Archivo**: `instalacion-docker.md`  
**Duración**: 30-40 minutos  
**Nivel**: Principiante

**Objetivos**:
- Instalar Docker Engine en Ubuntu
- Configurar permisos de usuario
- Verificar instalación correcta
- Ejecutar primer contenedor

**Prerequisitos**:
- Ubuntu 20.04+
- Acceso sudo
- Conexión a internet

**Relación con ejemplos**:
- Script automatizado: `ejemplos/01-instalacion/install-docker.sh`
- Teoría: README.md - Sección 2

---

### Lab 02: Instalación de kubectl
**Archivo**: `instalacion-kubectl.md`  
**Duración**: 20-30 minutos  
**Nivel**: Principiante

**Objetivos**:
- Instalar kubectl (cliente de Kubernetes)
- Configurar autocomplete
- Comprender comandos básicos
- Preparar entorno para conectarse a clusters

**Prerequisitos**:
- Ninguno (kubectl es independiente)

**Relación con ejemplos**:
- Script automatizado: `ejemplos/01-instalacion/install-kubectl.sh`
- Autocomplete: `ejemplos/02-configuracion/kubectl-autocomplete-bash.sh`
- Teoría: README.md - Sección 3

---

### Lab 03: Instalación de Minikube
**Archivo**: `instalacion-minikube.md`  
**Duración**: 30-45 minutos  
**Nivel**: Principiante-Intermedio

**Objetivos**:
- Instalar Minikube
- Iniciar primer cluster
- Comprender parámetros de configuración
- Verificar cluster funcionando

**Prerequisitos**:
- Docker instalado (Lab 01)
- kubectl instalado (Lab 02)

**Relación con ejemplos**:
- Script instalación: `ejemplos/01-instalacion/install-minikube.sh`
- Script inicio: `ejemplos/02-configuracion/minikube-start-custom.sh`
- Verificación: `ejemplos/02-configuracion/verify-cluster.sh`
- Teoría: README.md - Sección 4

---

### Lab 04: Preparación de VM
**Archivo**: `preparacion-vm.md`  
**Duración**: 45-60 minutos  
**Nivel**: Intermedio

**Objetivos**:
- Configurar Azure VM para Kubernetes
- Optimizar recursos del sistema
- Configurar networking
- Preparar entorno completo de desarrollo

**Prerequisitos**:
- Azure VM con Ubuntu
- Acceso SSH
- Conocimientos básicos de Linux

**Contexto**: Este laboratorio es específico para el entorno de Azure VM que usamos en el curso.

---

### Lab 05: Verificación y Testing
**Archivo**: `verificacion-testing.md`  
**Duración**: 40-60 minutos  
**Nivel**: Intermedio

**Objetivos**:
- Verificar instalación completa
- Ejecutar tests de funcionalidad
- Troubleshooting de problemas comunes
- Validar cluster production-ready

**Prerequisitos**:
- Labs 01, 02, 03 completados
- Cluster Minikube funcionando

**Relación con ejemplos**:
- Script verificación: `ejemplos/02-configuracion/verify-cluster.sh`
- Primera app: `ejemplos/03-primeros-pasos/primera-app.sh`
- Teoría: README.md - Sección 7 (Troubleshooting)

---

### Lab 06: Configuración del Driver (Avanzado)
**Archivo**: `configuracion-driver-none.md`  
**Duración**: 60+ minutos  
**Nivel**: Avanzado

**Objetivos**:
- Comprender driver "none" (bare metal)
- Configuración avanzada de Minikube
- Casos de uso especiales
- Limitaciones y consideraciones

**⚠️ ADVERTENCIA**: El driver "none" está **deprecado** y NO es recomendado para la mayoría de usuarios.

**Prerequisitos**:
- Experiencia con Kubernetes
- Conocimientos avanzados de Linux
- Entender riesgos de seguridad

**Recomendación**: Usa este laboratorio solo con propósitos educativos o casos muy específicos. Para uso normal, utiliza el driver Docker (ver `ejemplos/01-instalacion/comparativa-drivers.md`).

---

## 🎯 Ruta de Aprendizaje Recomendada

### Para Principiantes Completos

```
1. preparacion-vm.md           (si usas Azure VM)
   ↓
2. instalacion-docker.md        (Lab 01)
   ↓
3. instalacion-kubectl.md       (Lab 02)
   ↓
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
