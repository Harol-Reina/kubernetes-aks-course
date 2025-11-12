# Cheat Sheet de Minikube

Referencia rápida de comandos de Minikube más utilizados.

---

## Gestión del Cluster

### Iniciar/Detener
```bash
# Iniciar cluster (configuración básica)
minikube start

# Iniciar con driver específico
minikube start --driver=docker

# Iniciar con recursos personalizados
minikube start --cpus=4 --memory=8192 --disk-size=40g

# Iniciar versión específica de K8s
minikube start --kubernetes-version=v1.28.0

# Detener cluster (mantiene estado)
minikube stop

# Pausar cluster (congela procesos)
minikube pause

# Reanudar cluster pausado
minikube unpause
```

### Gestión
```bash
# Ver estado del cluster
minikube status

# Eliminar cluster completamente
minikube delete

# Eliminar todos los clusters
minikube delete --all

# Reiniciar cluster
minikube stop && minikube start
```

---

## Perfiles (Múltiples Clusters)

```bash
# Crear cluster con perfil específico
minikube start -p dev

# Listar perfiles
minikube profile list

# Cambiar perfil activo
minikube profile dev

# Ver perfil actual
minikube profile

# Eliminar perfil específico
minikube delete -p dev
```

---

## Información del Cluster

```bash
# Ver información general
minikube status
minikube version

# Ver IP del cluster
minikube ip

# SSH al nodo
minikube ssh

# Ver logs del cluster
minikube logs

# Ver configuración actual
minikube config view
```

---

## Addons

### Listar y Habilitar
```bash
# Listar todos los addons
minikube addons list

# Habilitar addon
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable ingress

# Deshabilitar addon
minikube addons disable dashboard

# Ver estado de addon específico
minikube addons list | grep dashboard
```

### Addons Populares
```bash
# Metrics Server (métricas de recursos)
minikube addons enable metrics-server

# Dashboard (UI web)
minikube addons enable dashboard
minikube dashboard

# Ingress (acceso HTTP externo)
minikube addons enable ingress

# Registry (registry local)
minikube addons enable registry

# Storage Provisioner (volúmenes persistentes)
# Habilitado por defecto

# Metrics Server + Dashboard
minikube addons enable metrics-server dashboard
```

---

## Servicios

```bash
# Listar servicios
minikube service list

# Obtener URL de servicio
minikube service <nombre-servicio> --url

# Abrir servicio en navegador
minikube service <nombre-servicio>

# Ejemplo con namespace
minikube service <nombre-servicio> -n <namespace> --url
```

---

## Dashboard

```bash
# Abrir dashboard en navegador
minikube dashboard

# Obtener URL del dashboard (sin abrir)
minikube dashboard --url

# Dashboard en namespace específico
minikube dashboard -n kube-system
```

---

## Docker Registry Local

```bash
# Habilitar registry
minikube addons enable registry

# Configurar Docker para usar registry de Minikube
eval $(minikube docker-env)

# Ver variables de entorno de Docker
minikube docker-env

# Volver a usar Docker local
eval $(minikube docker-env -u)
```

---

## Tunneling y Port Forwarding

```bash
# Crear tunnel (acceso a LoadBalancer services)
minikube tunnel

# Port forward a servicio específico
kubectl port-forward service/<nombre> <puerto-local>:<puerto-servicio>
```

---

## Configuración

```bash
# Ver configuración actual
minikube config view

# Configurar driver por defecto
minikube config set driver docker

# Configurar CPUs por defecto
minikube config set cpus 4

# Configurar memoria por defecto (MB)
minikube config set memory 8192

# Ver valor específico
minikube config get driver

# Eliminar configuración
minikube config unset driver
```

---

## Troubleshooting

### Diagnóstico
```bash
# Ver logs detallados
minikube logs

# Ver logs con follow
minikube logs -f

# Ver últimas 100 líneas
minikube logs --length=100

# SSH y explorar
minikube ssh
# Dentro del nodo:
#   docker ps
#   crictl ps
#   journalctl -u kubelet
```

### Limpieza
```bash
# Detener y limpiar
minikube stop
minikube delete

# Limpiar caché de imágenes
minikube delete --purge

# Limpiar todo (todos los perfiles)
minikube delete --all --purge
```

### Reinicio Limpio
```bash
# Procedimiento completo
minikube stop
minikube delete
rm -rf ~/.minikube
minikube start --driver=docker
```

---

## Cache de Imágenes

```bash
# Pre-cargar imagen en Minikube
minikube cache add nginx:latest

# Listar imágenes en cache
minikube cache list

# Eliminar imagen del cache
minikube cache delete nginx:latest

# Recargar cache
minikube cache reload
```

---

## Múltiples Nodos (Experimental)

```bash
# Crear cluster multi-nodo
minikube start --nodes=3

# Agregar nodo a cluster existente
minikube node add

# Listar nodos
minikube node list

# Eliminar nodo
minikube node delete <nombre-nodo>
```

---

## Comandos de Docker en Minikube

```bash
# Usar Docker daemon de Minikube
eval $(minikube docker-env)

# Ahora 'docker' apunta a Minikube
docker ps
docker images

# Construir imagen directamente en Minikube
docker build -t mi-app:latest .

# Volver a Docker local
eval $(minikube docker-env -u)
```

---

## Actualizaciones

```bash
# Actualizar Minikube
# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verificar versión
minikube version

# Actualizar cluster a nueva versión de K8s
minikube start --kubernetes-version=v1.28.0
```

---

## Ejemplos de Workflows Comunes

### Desarrollo Local
```bash
# Iniciar entorno de desarrollo
minikube start --driver=docker --cpus=4 --memory=8192
minikube addons enable metrics-server dashboard ingress

# Usar Docker de Minikube
eval $(minikube docker-env)

# Construir y desplegar
docker build -t mi-app:dev .
kubectl apply -f deployment.yaml

# Acceder a la app
minikube service mi-servicio
```

### Testing Rápido
```bash
# Cluster efímero
minikube start --driver=docker
kubectl apply -f test-app.yaml
# ... hacer pruebas ...
minikube delete
```

### CI/CD
```bash
# Cluster para CI
minikube start --driver=docker --wait=all
minikube status
kubectl apply -f manifests/
kubectl wait --for=condition=ready pod -l app=test
# ... ejecutar tests ...
minikube delete
```

---

## Variables de Entorno Útiles

```bash
# Cambiar directorio de Minikube
export MINIKUBE_HOME=/ruta/personalizada

# No mostrar actualización
export MINIKUBE_SUPPRESS_NO_UPGRADE=true

# Driver por defecto
export MINIKUBE_DRIVER=docker

# En memoria (no persistir datos)
export MINIKUBE_IN_STYLE=false
```

---

## Recursos y Referencias

- **Documentación oficial**: https://minikube.sigs.k8s.io/docs/
- **Drivers soportados**: https://minikube.sigs.k8s.io/docs/drivers/
- **GitHub**: https://github.com/kubernetes/minikube
- **Addons**: https://minikube.sigs.k8s.io/docs/handbook/addons/

---

**Tip**: Crea alias para comandos frecuentes:
```bash
alias mk='minikube'
alias mks='minikube start --driver=docker'
alias mkd='minikube dashboard'
alias mkssh='minikube ssh'
```
