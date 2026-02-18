# 📚 Docker Commands Guide

**Referencia Rápida**: Comandos esenciales para trabajar con Docker  
**Actualizado**: Diciembre 2024  
**Compatibilidad**: Docker 24.0+

---

## 🐳 Comandos Básicos de Contenedores

### **Ejecutar Contenedores**

```bash
# Ejecutar contenedor básico
docker run hello-world

# Ejecutar en modo detached (background)
docker run -d nginx

# Ejecutar interactivo con terminal
docker run -it ubuntu:22.04 bash

# Ejecutar con nombre personalizado
docker run --name mi-contenedor nginx

# Ejecutar con mapeo de puertos
docker run -p 8080:80 nginx

# Ejecutar con variables de entorno
docker run -e MYSQL_ROOT_PASSWORD=secreto mysql:8.0

# Ejecutar con límites de recursos
docker run --memory="512m" --cpus="1.0" nginx

# Ejecutar con volumen
docker run -v /host/path:/container/path nginx

# Ejecutar con red personalizada
docker run --network mi-red nginx

# Ejecutar con restart policy
docker run --restart unless-stopped nginx

# Ejecutar con usuario específico
docker run --user 1000:1000 nginx

# Combinar múltiples opciones
docker run -d \
  --name mi-app \
  --network app-net \
  -p 3000:3000 \
  -v /datos:/app/data \
  -e NODE_ENV=production \
  --restart unless-stopped \
  mi-app:latest
```

### **Gestionar Contenedores**

```bash
# Listar contenedores en ejecución
docker ps

# Listar todos los contenedores
docker ps -a

# Listar solo IDs de contenedores
docker ps -q

# Listar con formato personalizado
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Filtrar contenedores
docker ps --filter "status=running"
docker ps --filter "name=nginx"
docker ps --filter "label=env=production"

# Detener contenedor
docker stop CONTAINER_ID
docker stop mi-contenedor

# Detener múltiples contenedores
docker stop $(docker ps -q)

# Reiniciar contenedor
docker restart mi-contenedor

# Pausar/despausar contenedor
docker pause mi-contenedor
docker unpause mi-contenedor

# Eliminar contenedor
docker rm CONTAINER_ID
docker rm mi-contenedor

# Forzar eliminación de contenedor en ejecución
docker rm -f mi-contenedor

# Eliminar todos los contenedores detenidos
docker container prune

# Eliminar múltiples contenedores
docker rm $(docker ps -aq)
```

### **Inspeccionar Contenedores**

```bash
# Ver información detallada
docker inspect mi-contenedor

# Ver solo la IP del contenedor
docker inspect mi-contenedor | jq -r '.[0].NetworkSettings.IPAddress'

# Ver logs del contenedor
docker logs mi-contenedor

# Seguir logs en tiempo real
docker logs -f mi-contenedor

# Ver últimas N líneas de logs
docker logs --tail 50 mi-contenedor

# Ver logs con timestamps
docker logs -t mi-contenedor

# Ver estadísticas en tiempo real
docker stats

# Ver estadísticas de contenedor específico
docker stats mi-contenedor

# Ver procesos dentro del contenedor
docker top mi-contenedor

# Ver puertos mapeados
docker port mi-contenedor

# Ver cambios en el filesystem
docker diff mi-contenedor
```

### **Ejecutar Comandos en Contenedores**

```bash
# Ejecutar comando en contenedor
docker exec mi-contenedor ls -la

# Sesión interactiva en contenedor
docker exec -it mi-contenedor bash

# Ejecutar como usuario específico
docker exec -u root -it mi-contenedor bash

# Ejecutar en directorio específico
docker exec -w /app mi-contenedor ls -la

# Copiar archivos desde/hacia contenedor
docker cp archivo.txt mi-contenedor:/ruta/destino/
docker cp mi-contenedor:/ruta/origen/archivo.txt ./
```

---

## 🖼️ Comandos de Imágenes

### **Gestionar Imágenes**

```bash
# Listar imágenes
docker images

# Listar solo IDs de imágenes
docker images -q

# Listar con filtros
docker images --filter "dangling=true"
docker images --filter "label=version=1.0"

# Buscar imágenes en Docker Hub
docker search nginx

# Descargar imagen
docker pull ubuntu:22.04

# Descargar versión específica
docker pull redis:7.0-alpine

# Descargar todas las versiones de una imagen
docker pull --all-tags ubuntu

# Ver información de imagen
docker inspect ubuntu:22.04

# Ver historial de capas
docker history ubuntu:22.04

# Eliminar imagen
docker rmi ubuntu:22.04

# Forzar eliminación
docker rmi -f ubuntu:22.04

# Eliminar imágenes no utilizadas
docker image prune

# Eliminar todas las imágenes
docker rmi $(docker images -q)
```

### **Construir Imágenes**

```bash
# Construir imagen básica
docker build -t mi-app:latest .

# Construir con Dockerfile específico
docker build -f Dockerfile.prod -t mi-app:prod .

# Construir con argumentos
docker build --build-arg VERSION=1.0 -t mi-app:1.0 .

# Construir sin caché
docker build --no-cache -t mi-app:latest .

# Construir solo hasta etapa específica (multi-stage)
docker build --target builder -t mi-app:dev .

# Construir con contexto remoto
docker build -t mi-app https://github.com/usuario/repo.git

# Ver el proceso de construcción
docker build -t mi-app:latest . --progress=plain

# Construir con labels
docker build -t mi-app \
  --label "version=1.0" \
  --label "maintainer=tu-email@ejemplo.com" \
  .
```

### **Etiquetar y Registry**

```bash
# Etiquetar imagen
docker tag mi-app:latest mi-app:v1.0
docker tag mi-app:latest registro.com/usuario/mi-app:latest

# Subir imagen a registry
docker push mi-app:latest
docker push registro.com/usuario/mi-app:latest

# Acceder a registry privado
docker login registry.empresa.com
docker push registry.empresa.com/mi-app:latest

# Desloguearse
docker logout registry.empresa.com
```

---

## 📦 Comandos de Volúmenes

### **Gestionar Volúmenes**

```bash
# Crear volumen
docker volume create mi-volumen

# Crear volumen con driver específico
docker volume create --driver local mi-volumen

# Crear volumen con opciones
docker volume create \
  --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.100,rw \
  --opt device=:/ruta/nfs \
  mi-volumen-nfs

# Listar volúmenes
docker volume ls

# Filtrar volúmenes
docker volume ls --filter "dangling=true"

# Inspeccionar volumen
docker volume inspect mi-volumen

# Eliminar volumen
docker volume rm mi-volumen

# Eliminar volúmenes no utilizados
docker volume prune

# Eliminar todos los volúmenes
docker volume rm $(docker volume ls -q)
```

### **Usar Volúmenes**

```bash
# Bind mount (mapeo directo)
docker run -v /host/path:/container/path nginx

# Volumen nombrado
docker run -v mi-volumen:/data nginx

# Volumen anónimo
docker run -v /data nginx

# Múltiples volúmenes
docker run \
  -v /host/config:/app/config:ro \
  -v datos:/app/data \
  -v logs:/var/log \
  mi-app

# Backup de volumen
docker run --rm \
  -v mi-volumen:/backup-source \
  -v /host/backup:/backup-dest \
  ubuntu \
  tar czf /backup-dest/backup.tar.gz -C /backup-source .

# Restaurar volumen
docker run --rm \
  -v mi-volumen:/restore-dest \
  -v /host/backup:/backup-source \
  ubuntu \
  tar xzf /backup-source/backup.tar.gz -C /restore-dest
```

---

## 🌐 Comandos de Redes

### **Gestionar Redes**

```bash
# Listar redes
docker network ls

# Crear red bridge
docker network create mi-red

# Crear red con configuración específica
docker network create \
  --driver bridge \
  --subnet=172.20.0.0/16 \
  --ip-range=172.20.240.0/20 \
  --gateway=172.20.0.1 \
  mi-red-custom

# Crear red host
docker network create --driver host mi-red-host

# Crear red macvlan
docker network create \
  --driver macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  mi-macvlan

# Inspeccionar red
docker network inspect mi-red

# Conectar contenedor a red
docker network connect mi-red mi-contenedor

# Desconectar contenedor de red
docker network disconnect mi-red mi-contenedor

# Eliminar red
docker network rm mi-red

# Eliminar redes no utilizadas
docker network prune
```

### **Usar Redes**

```bash
# Ejecutar contenedor en red específica
docker run --network mi-red nginx

# Ejecutar con IP específica
docker run --network mi-red --ip 172.20.240.10 nginx

# Ejecutar con alias de red
docker run --network mi-red --network-alias web nginx

# Exponer puerto específico
docker run -p 8080:80 nginx

# Exponer todos los puertos
docker run -P nginx

# Exponer en interfaz específica
docker run -p 127.0.0.1:8080:80 nginx

# Exponer rango de puertos
docker run -p 8080-8085:8080-8085 mi-app
```

---

## 🗂️ Docker Compose Básico

### **Comandos de Compose**

```bash
# Ejecutar servicios
docker compose up

# Ejecutar en background
docker compose up -d

# Ejecutar servicios específicos
docker compose up web db

# Construir imágenes antes de ejecutar
docker compose up --build

# Forzar recreación de contenedores
docker compose up --force-recreate

# Detener servicios
docker compose down

# Detener y eliminar volúmenes
docker compose down -v

# Ver logs
docker compose logs

# Seguir logs
docker compose logs -f

# Ver logs de servicio específico
docker compose logs web

# Ver estado de servicios
docker compose ps

# Ejecutar comando en servicio
docker compose exec web bash

# Escalar servicios
docker compose up --scale web=3

# Ver configuración procesada
docker compose config
```

---

## 🧹 Comandos de Limpieza

### **Limpieza del Sistema**

```bash
# Limpieza básica (contenedores, redes, imágenes dangling)
docker system prune

# Limpieza agresiva (incluye volúmenes)
docker system prune -a --volumes

# Ver uso del disco
docker system df

# Ver información detallada de uso
docker system df -v

# Limpiar contenedores detenidos
docker container prune

# Limpiar imágenes no utilizadas
docker image prune

# Limpiar imágenes dangling
docker image prune -a

# Limpiar volúmenes no utilizados
docker volume prune

# Limpiar redes no utilizadas
docker network prune

# Limpiar cache de construcción
docker builder prune
```

### **Limpieza Selectiva**

```bash
# Eliminar contenedores por filtro
docker rm $(docker ps -aq --filter "status=exited")

# Eliminar imágenes por filtro
docker rmi $(docker images -q --filter "dangling=true")

# Eliminar contenedores más antiguos que X días
docker container prune --filter "until=72h"

# Eliminar imágenes más antiguas que X días
docker image prune --filter "until=168h"
```

---

## 🔍 Comandos de Debugging

### **Información del Sistema**

```bash
# Información general de Docker
docker info

# Versión de Docker
docker version

# Ver eventos en tiempo real
docker events

# Ver eventos filtrados
docker events --filter container=mi-contenedor

# Ver procesos de Docker en el host
ps aux | grep docker
```

### **Debugging de Contenedores**

```bash
# Verificar estado de salud
docker inspect mi-contenedor | jq '.[0].State.Health'

# Ver últimos logs con errores
docker logs mi-contenedor 2>&1 | grep -i error

# Ejecutar shell para debugging
docker exec -it mi-contenedor /bin/sh

# Ver variables de entorno
docker exec mi-contenedor env

# Ver filesystem del contenedor
docker exec mi-contenedor df -h

# Ver procesos en el contenedor
docker exec mi-contenedor ps aux

# Verificar conectividad de red
docker exec mi-contenedor ping google.com

# Verificar DNS
docker exec mi-contenedor nslookup google.com

# Ver puertos abiertos
docker exec mi-contenedor netstat -tulpn
```

---

## ⚡ Scripts y Aliases Útiles

### **Aliases Recomendados**

```bash
# Agregar al ~/.bashrc o ~/.zshrc
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dsp='docker system prune'
alias dlog='docker logs'
alias dexec='docker exec -it'
alias drun='docker run --rm -it'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'

# Función para logs con timestamp
dlogt() {
    docker logs -t "$1"
}

# Función para ejecutar con límites
drunlim() {
    docker run --rm -it --memory="512m" --cpus="1.0" "$@"
}
```

### **Scripts de Mantenimiento**

```bash
#!/bin/bash
# docker-cleanup.sh - Script de limpieza completa

echo "🧹 Iniciando limpieza de Docker..."

echo "📦 Deteniendo contenedores..."
docker stop $(docker ps -q) 2>/dev/null

echo "🗑️ Eliminando contenedores..."
docker container prune -f

echo "🖼️ Eliminando imágenes no utilizadas..."
docker image prune -a -f

echo "📦 Eliminando volúmenes no utilizados..."
docker volume prune -f

echo "🌐 Eliminando redes no utilizadas..."
docker network prune -f

echo "🏗️ Eliminando cache de construcción..."
docker builder prune -a -f

echo "✅ Limpieza completada!"
docker system df
```

---

## 📋 Referencia Rápida por Categoría

### **Ciclo de Vida del Contenedor**
```bash
docker run → docker ps → docker logs → docker exec → docker stop → docker rm
```

### **Ciclo de Vida de la Imagen**
```bash
docker build → docker images → docker tag → docker push → docker pull → docker rmi
```

### **Ciclo de Vida del Volumen**
```bash
docker volume create → docker volume ls → docker volume inspect → docker volume rm
```

### **Ciclo de Vida de la Red**
```bash
docker network create → docker network ls → docker network inspect → docker network rm
```

---

## 🔧 Troubleshooting Común

### **Problemas Frecuentes**

```bash
# "docker: command not found"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# "permission denied"
sudo usermod -aG docker $USER
newgrp docker

# "port already in use"
sudo netstat -tulpn | grep :puerto
# Cambiar puerto o detener proceso

# "no space left on device"
docker system prune -a --volumes

# "cannot connect to docker daemon"
sudo systemctl start docker
sudo systemctl enable docker

# Contenedor no responde
docker exec contenedor ps aux
docker logs contenedor
docker restart contenedor

# Imagen no se puede eliminar
docker ps -a | grep imagen
docker rm $(docker ps -aq --filter ancestor=imagen)
docker rmi imagen
```

---

**💡 Tip**: Siempre usa `docker --help` o `docker COMANDO --help` para obtener ayuda específica de cualquier comando.

---

**🔗 Recursos Adicionales:**
- [Documentación Oficial de Docker](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Docker Commands Cheat Sheet](https://docs.docker.com/get-started/docker_cheatsheet.pdf)