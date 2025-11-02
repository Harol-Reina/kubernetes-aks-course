# Docker Cheat Sheet

## 🐳 Comandos Básicos

### Información del Sistema
```bash
# Versión de Docker
docker --version
docker version

# Información del sistema
docker info

# Ayuda
docker --help
docker <command> --help
```

### Gestión de Imágenes
```bash
# Listar imágenes
docker images
docker image ls

# Buscar imágenes en Docker Hub
docker search <image-name>
docker search nginx

# Descargar imagen
docker pull <image-name>:<tag>
docker pull nginx:latest
docker pull ubuntu:20.04

# Eliminar imagen
docker rmi <image-id-or-name>
docker rmi nginx:latest

# Eliminar imágenes no utilizadas
docker image prune
docker image prune -a  # Elimina todas las imágenes sin usar
```

## 📦 Gestión de Contenedores

### Crear y Ejecutar Contenedores
```bash
# Ejecutar contenedor
docker run <image>
docker run nginx

# Ejecutar en modo detached (background)
docker run -d nginx

# Ejecutar con nombre personalizado
docker run --name mi-nginx nginx

# Ejecutar con mapeo de puertos
docker run -p <host-port>:<container-port> <image>
docker run -p 8080:80 nginx

# Ejecutar modo interactivo
docker run -it ubuntu /bin/bash
docker run -it --rm alpine sh  # --rm elimina automáticamente al salir

# Ejecutar con variables de entorno
docker run -e MYSQL_ROOT_PASSWORD=secreto mysql:8.0

# Ejecutar con volúmenes
docker run -v /host/path:/container/path nginx
docker run -v mi-volumen:/data nginx
```

### Gestión de Contenedores en Ejecución
```bash
# Listar contenedores en ejecución
docker ps

# Listar todos los contenedores (incluidos detenidos)
docker ps -a

# Parar contenedor
docker stop <container-id-or-name>
docker stop mi-nginx

# Iniciar contenedor detenido
docker start <container-id-or-name>

# Reiniciar contenedor
docker restart <container-id-or-name>

# Eliminar contenedor
docker rm <container-id-or-name>
docker rm mi-nginx

# Forzar eliminación de contenedor en ejecución
docker rm -f <container-id-or-name>
```

### Interactuar con Contenedores
```bash
# Ejecutar comando en contenedor en ejecución
docker exec <container-id-or-name> <command>
docker exec mi-nginx ls -la

# Acceso interactivo a contenedor
docker exec -it <container-id-or-name> /bin/bash
docker exec -it mi-nginx sh

# Ver logs del contenedor
docker logs <container-id-or-name>
docker logs -f mi-nginx  # Follow logs
docker logs --tail 100 mi-nginx  # Últimas 100 líneas
docker logs --since 2h mi-nginx  # Logs de las últimas 2 horas

# Inspeccionar contenedor
docker inspect <container-id-or-name>

# Ver estadísticas de contenedores
docker stats
docker stats <container-id-or-name>

# Ver procesos en contenedor
docker top <container-id-or-name>
```

## 🏗️ Construcción de Imágenes

### Dockerfile y Build
```bash
# Construir imagen desde Dockerfile
docker build -t <image-name>:<tag> <path>
docker build -t mi-app:1.0 .
docker build -t mi-app:latest -f Dockerfile.prod .

# Construir con argumentos
docker build --build-arg ARG_NAME=value -t mi-app .

# Construcción sin cache
docker build --no-cache -t mi-app .

# Ver historial de capas de imagen
docker history <image-name>
```

### Tagging y Registry
```bash
# Crear tag para imagen
docker tag <source-image> <target-image>
docker tag mi-app:1.0 mi-registry.com/mi-app:1.0

# Subir imagen a registry
docker push <image-name>:<tag>
docker push mi-registry.com/mi-app:1.0

# Login a registry
docker login
docker login mi-registry.com
docker login -u username -p password mi-registry.com

# Logout de registry
docker logout
docker logout mi-registry.com
```

## 💾 Volúmenes y Almacenamiento

### Gestión de Volúmenes
```bash
# Crear volumen
docker volume create <volume-name>
docker volume create mi-volumen

# Listar volúmenes
docker volume ls

# Inspeccionar volumen
docker volume inspect <volume-name>

# Eliminar volumen
docker volume rm <volume-name>

# Eliminar volúmenes no utilizados
docker volume prune
```

### Tipos de Montaje
```bash
# Volume mount
docker run -v mi-volumen:/app/data nginx

# Bind mount
docker run -v /host/path:/container/path nginx
docker run -v $(pwd):/app nginx

# tmpfs mount (en memoria)
docker run --tmpfs /tmp nginx
```

## 🌐 Redes

### Gestión de Redes
```bash
# Listar redes
docker network ls

# Crear red personalizada
docker network create <network-name>
docker network create mi-red
docker network create --driver bridge mi-red

# Inspeccionar red
docker network inspect <network-name>

# Conectar contenedor a red
docker network connect <network-name> <container-name>

# Desconectar contenedor de red
docker network disconnect <network-name> <container-name>

# Eliminar red
docker network rm <network-name>

# Eliminar redes no utilizadas
docker network prune
```

### Ejecutar con Redes
```bash
# Ejecutar en red específica
docker run --network <network-name> nginx

# Ejecutar sin red
docker run --network none alpine

# Usar red del host
docker run --network host nginx
```

## 🧹 Limpieza del Sistema

### Comandos de Limpieza
```bash
# Limpiar contenedores detenidos
docker container prune

# Limpiar imágenes no utilizadas
docker image prune
docker image prune -a  # Incluye imágenes sin tag

# Limpiar volúmenes no utilizados
docker volume prune

# Limpiar redes no utilizadas
docker network prune

# Limpieza completa del sistema
docker system prune
docker system prune -a  # Más agresivo

# Ver uso de espacio
docker system df
```

## 📊 Monitoreo y Debug

### Información de Contenedores
```bash
# Estadísticas en tiempo real
docker stats

# Procesos en contenedor
docker top <container-name>

# Cambios en filesystem
docker diff <container-name>

# Eventos del sistema Docker
docker events
docker events --filter container=<container-name>

# Copiar archivos
# De host a contenedor
docker cp /host/file <container-name>:/container/path

# De contenedor a host
docker cp <container-name>:/container/file /host/path
```

## 🐙 Docker Compose

### Comandos Básicos
```bash
# Iniciar servicios
docker-compose up
docker-compose up -d  # En background

# Parar servicios
docker-compose down
docker-compose down -v  # Elimina también volúmenes

# Ver servicios
docker-compose ps

# Logs de servicios
docker-compose logs
docker-compose logs <service-name>
docker-compose logs -f <service-name>  # Follow

# Ejecutar comando en servicio
docker-compose exec <service-name> <command>
docker-compose exec web bash

# Construir servicios
docker-compose build
docker-compose build <service-name>

# Reiniciar servicios
docker-compose restart
docker-compose restart <service-name>
```

### Escalado y Control
```bash
# Escalar servicio
docker-compose up --scale <service-name>=<replicas>
docker-compose up --scale web=3

# Validar archivo compose
docker-compose config

# Ver configuración procesada
docker-compose config --services
```

## 🔧 Comandos Avanzados

### Debugging y Troubleshooting
```bash
# Ejecutar en modo debug
docker run --rm -it --entrypoint /bin/sh <image>

# Ver configuración de daemon
docker system info

# Inspeccionar objeto Docker
docker inspect <object-id-or-name>

# Exportar/Importar contenedores
docker export <container-name> > container.tar
docker import container.tar <new-image-name>

# Guardar/Cargar imágenes
docker save <image-name> > image.tar
docker load < image.tar
```

### Limitación de Recursos
```bash
# Limitar memoria
docker run -m 512m nginx
docker run --memory=1g nginx

# Limitar CPU
docker run --cpus="1.5" nginx
docker run --cpu-shares=512 nginx

# Limitar reintentos
docker run --restart=on-failure:3 nginx
docker run --restart=unless-stopped nginx
```

## 🎯 One-liners Útiles

```bash
# Eliminar todos los contenedores detenidos
docker rm $(docker ps -a -q)

# Eliminar todas las imágenes
docker rmi $(docker images -q)

# Eliminar contenedores por estado
docker rm $(docker ps -a -f status=exited -q)

# Ver IPs de contenedores
docker inspect $(docker ps -q) | grep IPAddress | grep -v null

# Backup de volumen
docker run --rm -v <volume-name>:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data

# Restore de volumen
docker run --rm -v <volume-name>:/data -v $(pwd):/backup alpine tar xzf /backup/backup.tar.gz -C /

# Conectar a red de otro contenedor
docker run --network container:<container-name> alpine

# Ver variables de entorno de contenedor
docker exec <container-name> env
```

## 🚨 Comandos de Emergencia

```bash
# Parar todos los contenedores
docker stop $(docker ps -q)

# Eliminar todo (CUIDADO!)
docker system prune -a --volumes

# Matar todos los contenedores
docker kill $(docker ps -q)

# Reiniciar daemon Docker (Linux)
sudo systemctl restart docker

# Ver logs del daemon
journalctl -u docker.service
```