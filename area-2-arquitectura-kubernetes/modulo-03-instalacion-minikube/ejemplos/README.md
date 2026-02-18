# Ejemplos del Módulo 03: Instalación de Minikube

Esta carpeta contiene todos los ejemplos prácticos, scripts de instalación y configuración mencionados en el README principal del módulo.

---

## Estructura de Directorios

```
ejemplos/
├── 01-instalacion/          # Scripts de instalación
├── 02-configuracion/        # Scripts de configuración
└── 03-primeros-pasos/       # Ejemplos para primeros pasos
```

---

## 📁 01-instalacion/

Scripts para instalar las herramientas necesarias.

### Archivos:

#### `install-docker.sh`
Instalación automatizada de Docker Engine en Ubuntu.
```bash
sudo ./install-docker.sh
```

**Características**:
- ✅ Instalación desde repositorio oficial de Docker
- ✅ Configuración de permisos de usuario
- ✅ Verificación post-instalación
- ✅ Mensajes informativos claros

---

#### `install-kubectl.sh`
Instalación de kubectl (cliente de Kubernetes).
```bash
./install-kubectl.sh          # Instalación local (~/.local/bin)
sudo ./install-kubectl.sh     # Instalación global (/usr/local/bin)
```

**Características**:
- ✅ Descarga de última versión estable
- ✅ Verificación de checksums (seguridad)
- ✅ Detección automática de arquitectura
- ✅ Instalación local o global

---

#### `install-minikube.sh`
Instalación de Minikube.
```bash
./install-minikube.sh         # Instalación local
sudo ./install-minikube.sh    # Instalación global
```

**Características**:
- ✅ Última versión desde repositorio oficial
- ✅ Verificación de prerequisitos (Docker)
- ✅ Multi-arquitectura (amd64, arm64)
- ✅ Guía de próximos pasos

---

#### `comparativa-drivers.md`
Documentación completa comparando diferentes drivers de Minikube.

**Contenido**:
- Comparación detallada de 6 drivers (Docker, VirtualBox, KVM, Hyper-V, Podman, None)
- Tabla comparativa de características
- Recomendaciones por caso de uso
- Comandos de troubleshooting específicos por driver

**Cuándo leerlo**: Antes de decidir qué driver usar o si tienes problemas con el driver actual.

---

## 📁 02-configuracion/

Scripts para configurar el entorno después de la instalación.

### Archivos:

#### `setup-environment.sh`
**Script maestro** que automatiza toda la configuración del entorno.
```bash
./setup-environment.sh
```

**Funcionalidad**:
- Instala Docker, kubectl, Minikube (si no están presentes)
- Configura autocomplete según tu shell
- Verifica que todo funciona correctamente
- Proporciona guía de próximos pasos

**Recomendación**: Úsalo si empiezas desde cero.

---

#### `kubectl-autocomplete-bash.sh` / `kubectl-autocomplete-zsh.sh`
Configuración de autocompletado para kubectl.

**Bash**:
```bash
./kubectl-autocomplete-bash.sh
source ~/.bashrc
```

**Zsh**:
```bash
./kubectl-autocomplete-zsh.sh
source ~/.zshrc
```

**Beneficios**:
- ⌨️ Autocompleta comandos con TAB
- ⌨️ Autocompleta nombres de recursos
- ⌨️ Alias `k` para kubectl configurado

---

#### `minikube-start-custom.sh`
Inicia Minikube con configuración personalizada.

```bash
./minikube-start-custom.sh              # Perfil default
./minikube-start-custom.sh dev          # Perfil 'dev'
```

**Parámetros personalizables** (edita el script):
- `DRIVER`: docker (default), virtualbox, kvm2, etc.
- `CPUS`: 2 (default)
- `MEMORY`: 4096 MB (default)
- `DISK_SIZE`: 20g (default)
- `KUBERNETES_VERSION`: latest (default)

**Ejemplo de personalización**:
```bash
# Editar script
CPUS="4"
MEMORY="8192"
```

---

#### `verify-cluster.sh`
Verifica que el cluster está funcionando correctamente.

```bash
./verify-cluster.sh              # Perfil default
./verify-cluster.sh dev          # Perfil específico
```

**Verificaciones**:
- ✅ Minikube instalado
- ✅ kubectl instalado
- ✅ Cluster corriendo
- ✅ Componentes del sistema (kubelet, apiserver)
- ✅ Nodos en estado Ready
- ✅ Pods del sistema corriendo

**Cuándo usarlo**:
- Después de iniciar Minikube
- Si sospechas problemas con el cluster
- Para debugging rápido

---

#### `minikube-cheatsheet.md`
Referencia rápida de comandos de Minikube.

**Secciones**:
- Gestión del cluster (start/stop/delete)
- Perfiles (múltiples clusters)
- Addons
- Servicios
- Dashboard
- Configuración
- Troubleshooting
- Workflows comunes

**Cuándo leerlo**: Cuando necesites recordar un comando específico.

---

## 📁 03-primeros-pasos/

Ejemplos prácticos para desplegar tus primeras aplicaciones.

### Archivos:

#### `primera-app.sh`
Script que despliega Nginx automáticamente usando comandos imperativos.

```bash
./primera-app.sh
```

**Qué hace**:
1. Crea deployment de Nginx
2. Espera que el pod esté listo
3. Expone como servicio NodePort
4. Muestra URL de acceso

**Propósito**: Aprender comandos imperativos (`kubectl create`, `kubectl expose`).

**Limpieza**:
```bash
kubectl delete service nginx
kubectl delete deployment nginx
```

---

#### `nginx-deployment.yaml`
Deployment y Service de Nginx usando manifiestos YAML.

```bash
kubectl apply -f nginx-deployment.yaml
```

**Contenido**:
- Deployment con 2 réplicas
- Resource limits configurados
- Service tipo NodePort

**Acceso**:
```bash
minikube service nginx-service --url
```

**Propósito**: Aprender enfoque declarativo (manifiestos YAML).

**Limpieza**:
```bash
kubectl delete -f nginx-deployment.yaml
```

---

#### `webapp-complete.yaml`
Aplicación web completa con múltiples recursos.

```bash
kubectl apply -f webapp-complete.yaml
```

**Recursos incluidos**:
- **Deployment**: 3 réplicas con labels
- **Service**: NodePort para acceso externo
- **ConfigMap**: Configuración de la aplicación
- **Probes**: Liveness y Readiness configuradas
- **Resources**: Limits y requests definidos

**Características pedagógicas**:
- Labels y selectors
- Variables de entorno
- Health checks
- Resource management
- Buenas prácticas

**Acceso**:
```bash
minikube service webapp-service --url
```

**Exploración**:
```bash
# Ver todos los recursos
kubectl get all

# Ver ConfigMap
kubectl get configmap webapp-config -o yaml

# Ver logs
kubectl logs -l app=webapp

# Describir deployment
kubectl describe deployment webapp
```

**Limpieza**:
```bash
kubectl delete -f webapp-complete.yaml
```

---

## 🚀 Flujo de Trabajo Recomendado

### Para Principiantes (Setup Inicial)

```bash
# 1. Instalación automática completa
cd ejemplos/02-configuracion
./setup-environment.sh

# 2. Cerrar sesión y volver a entrar (permisos Docker)
exit

# 3. Iniciar Minikube con configuración custom
cd ejemplos/02-configuracion
./minikube-start-custom.sh

# 4. Verificar que todo funciona
./verify-cluster.sh

# 5. Desplegar primera app
cd ../03-primeros-pasos
./primera-app.sh
```

---

### Para Instalación Manual (Paso a Paso)

```bash
# 1. Instalar Docker
cd ejemplos/01-instalacion
sudo ./install-docker.sh
exit  # Cerrar sesión

# 2. Instalar kubectl
./install-kubectl.sh

# 3. Instalar Minikube
./install-minikube.sh

# 4. Configurar autocomplete (bash)
cd ../02-configuracion
./kubectl-autocomplete-bash.sh
source ~/.bashrc

# 5. Iniciar Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# 6. Verificar cluster
./verify-cluster.sh
```

---

### Para Desarrollo Diario

```bash
# Iniciar cluster
minikube start

# Verificar estado
minikube status

# Desplegar con YAML
kubectl apply -f ejemplos/03-primeros-pasos/webapp-complete.yaml

# Acceder a la app
minikube service webapp-service

# Ver logs y estado
kubectl logs -l app=webapp --tail=50 -f
kubectl get pods -w

# Al terminar
minikube stop
```

---

## 📋 Checklist de Uso

### Instalación Inicial
- [ ] Ejecutar `setup-environment.sh` o scripts individuales
- [ ] Cerrar sesión y volver a entrar (permisos Docker)
- [ ] Verificar que `docker`, `kubectl`, `minikube` funcionan
- [ ] Configurar autocomplete para tu shell
- [ ] Iniciar primer cluster con `minikube-start-custom.sh`
- [ ] Verificar cluster con `verify-cluster.sh`

### Primera Aplicación
- [ ] Ejecutar `primera-app.sh` (comandos imperativos)
- [ ] Acceder a la aplicación en el navegador
- [ ] Limpiar recursos creados
- [ ] Aplicar `nginx-deployment.yaml` (enfoque declarativo)
- [ ] Comparar ambos enfoques
- [ ] Explorar `webapp-complete.yaml` (caso completo)

### Configuración Avanzada
- [ ] Leer `comparativa-drivers.md`
- [ ] Consultar `minikube-cheatsheet.md`
- [ ] Habilitar addons necesarios
- [ ] Configurar perfiles para diferentes entornos

---

## 🛠️ Troubleshooting

### Scripts no son ejecutables
```bash
chmod +x ejemplos/*/*.sh
```

### Docker requiere sudo
```bash
sudo usermod -aG docker $USER
newgrp docker
# O cierra sesión y vuelve a entrar
```

### Minikube no inicia
```bash
# Ver logs
minikube logs

# Reinicio limpio
cd ejemplos/02-configuracion
minikube delete
./minikube-start-custom.sh
```

### kubectl no conecta
```bash
# Verificar contexto
kubectl config current-context

# Debería mostrar: minikube

# Si no, configurar:
kubectl config use-context minikube
```

---

## 📚 Orden de Lectura Recomendado

1. **README.md** (raíz del módulo) - Teoría y conceptos
2. **comparativa-drivers.md** - Entender opciones de drivers
3. **setup-environment.sh** - Instalación automática
4. **verify-cluster.sh** - Verificación del entorno
5. **primera-app.sh** - Primer deployment
6. **nginx-deployment.yaml** - Manifiestos básicos
7. **webapp-complete.yaml** - Caso completo
8. **minikube-cheatsheet.md** - Referencia continua

---

## 🔗 Referencias

Todos estos scripts están diseñados para funcionar con:
- **Sistema**: Ubuntu 20.04+
- **Driver**: Docker (recomendado para este curso)
- **Recursos mínimos**: 2 CPUs, 4GB RAM, 20GB disco

Para otros drivers o sistemas operativos, consulta `comparativa-drivers.md`.

---

## ✅ Próximos Pasos

Después de completar estos ejemplos, continúa con:
- **modulo-04-pods-vs-contenedores**: Entender pods y contenedores
- **modulo-05-gestion-pods**: Gestión avanzada de pods
- **Laboratorios**: Práctica guiada paso a paso

---

**¿Problemas?** Consulta el README principal del módulo (sección Troubleshooting) o ejecuta `verify-cluster.sh` para diagnóstico automático.
