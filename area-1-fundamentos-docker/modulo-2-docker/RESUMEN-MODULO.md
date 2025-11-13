# 📝 Resumen - Módulo 2: Contenerización con Docker

> **Guía rápida de estudio**: Conceptos clave, comandos esenciales Docker y troubleshooting para dominar la contenerización.

---

## 🎯 Conceptos Clave en 5 Minutos

### ¿Qué es un Contenedor?

**Definición**: Un contenedor es un **proceso aislado** que ejecuta una aplicación con todas sus dependencias, compartiendo el kernel del sistema operativo host pero aislado mediante namespaces y cgroups de Linux.

**Analogía**: Un contenedor es como un apartamento en un edificio. Todos los apartamentos (contenedores) comparten la estructura del edificio (kernel del SO), pero cada uno tiene su propio espacio privado, cocina (filesystem), y servicios (procesos).

**Fórmula esencial**:
```
Contenedor = Proceso + Namespaces + Cgroups + Union FS
```

### Los 4 Pilares de Docker

```
1. CONTENEDOR                 2. IMAGEN
   docker run                    docker build
   ┌──────────────┐             ┌──────────────┐
   │   nginx      │             │  nginx:1.25  │
   │   RUNNING    │◄────────────│  TEMPLATE    │
   └──────────────┘   instancia └──────────────┘
                                       ▲
                                       │
3. DOCKERFILE                          │
   docker build                        │
   ┌──────────────┐                    │
   │ FROM nginx   │────────────────────┘
   │ COPY html/   │
   │ EXPOSE 80    │           4. DOCKER HUB
   └──────────────┘              docker pull/push
                                 ┌──────────────┐
                                 │  nginx:1.25  │
                                 │  node:20     │
                                 │  postgres:16 │
                                 └──────────────┘
```

---

## 📊 1. Contenedores vs. VMs - Diferencias Clave

| Aspecto | Contenedor | Máquina Virtual |
|---------|-----------|-----------------|
| **Qué aísla** | Proceso + filesystem | Hardware completo |
| **SO** | Comparte kernel del host | SO guest completo |
| **Tamaño** | 50-500 MB | 2-20 GB |
| **Arranque** | 1-3 segundos | 1-5 minutos |
| **Overhead** | Mínimo (~5%) | Alto (~20-30%) |
| **Densidad** | 100+ por servidor | 5-20 por servidor |
| **Aislamiento** | Proceso-nivel (namespaces) | Hardware-nivel (hipervisor) |
| **Portabilidad** | ⭐⭐⭐⭐⭐ Extrema | ⭐⭐⭐ Moderada |

### Tecnologías Subyacentes de Contenedores

```bash
# Namespaces (aislamiento)
PID      → Árbol de procesos aislado
NET      → Interfaz de red propia
MNT      → Filesystem montado independiente
UTS      → Hostname propio
IPC      → Memoria compartida aislada
USER     → Mapping de UIDs/GIDs

# Cgroups (límites de recursos)
cpu      → Limitar CPU shares
memory   → Limitar RAM
blkio    → Limitar I/O de disco
net_cls  → Prioridad de red
```

---

## 🛠️ 2. Comandos Esenciales Docker

### Gestión de Contenedores (Operaciones Básicas)

```bash
# Ejecutar contenedor desde imagen
docker run [OPCIONES] IMAGEN [COMANDO]

# Ejemplos comunes:
docker run hello-world                    # Test básico
docker run -d nginx                       # Detached mode (background)
docker run -it ubuntu bash                # Interactive + terminal
docker run -d -p 8080:80 nginx            # Publicar puerto 8080→80
docker run -d --name webserver nginx      # Asignar nombre
docker run -d -e ENV_VAR=value app        # Variable de entorno
docker run -d -v /host:/container nginx   # Montar volumen
docker run -d --rm nginx                  # Auto-eliminar al detener
docker run -d --restart=always nginx      # Reiniciar automáticamente

# Listar contenedores
docker ps                    # Solo corriendo
docker ps -a                 # Todos (incluye detenidos)
docker ps -q                 # Solo IDs (útil para scripts)
docker ps --format "{{.Names}}: {{.Status}}"  # Formato custom

# Ver logs
docker logs CONTENEDOR                    # Todos los logs
docker logs -f CONTENEDOR                 # Seguir logs (tail -f)
docker logs --tail 50 CONTENEDOR          # Últimas 50 líneas
docker logs --since 10m CONTENEDOR        # Últimos 10 minutos
docker logs -t CONTENEDOR                 # Con timestamps

# Inspeccionar contenedor (JSON)
docker inspect CONTENEDOR                 # Info completa
docker inspect CONTENEDOR | grep IPAddress  # Solo IP
docker inspect -f '{{.NetworkSettings.IPAddress}}' CONTENEDOR

# Ejecutar comando en contenedor corriendo
docker exec CONTENEDOR COMANDO            # Ejecutar comando
docker exec -it CONTENEDOR bash           # Shell interactivo
docker exec -u root CONTENEDOR comando    # Como usuario root

# Gestión de ciclo de vida
docker start CONTENEDOR                   # Iniciar detenido
docker stop CONTENEDOR                    # Detener gracefully (SIGTERM)
docker stop -t 30 CONTENEDOR              # Timeout de 30 segundos
docker restart CONTENEDOR                 # Reiniciar
docker kill CONTENEDOR                    # Forzar detención (SIGKILL)
docker pause CONTENEDOR                   # Pausar procesos
docker unpause CONTENEDOR                 # Reanudar procesos
docker rm CONTENEDOR                      # Eliminar detenido
docker rm -f CONTENEDOR                   # Forzar eliminación

# Estadísticas y monitoreo
docker stats                              # Stats en tiempo real (todos)
docker stats CONTENEDOR                   # Stats de uno específico
docker top CONTENEDOR                     # Procesos corriendo dentro
docker port CONTENEDOR                    # Mapeo de puertos

# Copiar archivos
docker cp archivo.txt CONTENEDOR:/path/   # Host → Contenedor
docker cp CONTENEDOR:/path/file.txt .     # Contenedor → Host

# Ver cambios en filesystem
docker diff CONTENEDOR                    # Archivos modificados
```

### Gestión de Imágenes

```bash
# Descargar imagen de registry
docker pull nginx                         # Última versión (latest)
docker pull nginx:1.25                    # Versión específica
docker pull nginx:1.25-alpine             # Tag específico

# Listar imágenes locales
docker images                             # Todas las imágenes
docker images nginx                       # Solo nginx
docker images -q                          # Solo IDs
docker images --filter "dangling=true"    # Imágenes sin tag

# Construir imagen desde Dockerfile
docker build .                            # Desde directorio actual
docker build -t miapp:1.0 .               # Con tag
docker build -t miapp:latest -f Dockerfile.prod .  # Dockerfile específico
docker build --no-cache -t miapp:1.0 .    # Sin usar cache
docker build --build-arg VERSION=1.0 .    # Pasar argumentos

# Etiquetar imagen
docker tag miapp:1.0 usuario/miapp:1.0
docker tag miapp:1.0 usuario/miapp:latest

# Subir a registry
docker login                              # Login a Docker Hub
docker push usuario/miapp:1.0
docker push usuario/miapp:latest

# Eliminar imágenes
docker rmi IMAGEN                         # Eliminar imagen
docker rmi -f IMAGEN                      # Forzar eliminación
docker image prune                        # Limpiar imágenes sin usar
docker image prune -a                     # Limpiar todas sin contenedor

# Inspeccionar imagen
docker inspect IMAGEN                     # Metadata completa
docker history IMAGEN                     # Ver capas de la imagen
docker history --no-trunc IMAGEN          # Ver comandos completos

# Guardar y cargar imágenes
docker save -o miapp.tar miapp:1.0        # Exportar a .tar
docker load -i miapp.tar                  # Importar desde .tar
```

### Gestión de Volúmenes

```bash
# Crear volumen
docker volume create mivol
docker volume create --name data-vol

# Listar volúmenes
docker volume ls
docker volume ls -q

# Inspeccionar volumen
docker volume inspect mivol

# Usar volúmenes en contenedores
docker run -d -v mivol:/data nginx              # Named volume
docker run -d -v /host/path:/container nginx    # Bind mount
docker run -d -v mivol:/data:ro nginx           # Read-only
docker run -d --mount source=mivol,target=/data nginx  # Sintaxis mount

# Eliminar volúmenes
docker volume rm mivol
docker volume prune                             # Limpiar sin usar
```

### Gestión de Redes

```bash
# Listar redes
docker network ls

# Crear red
docker network create mired
docker network create --driver bridge mired
docker network create --subnet=172.20.0.0/16 mired

# Inspeccionar red
docker network inspect mired

# Conectar contenedor a red
docker run -d --network mired nginx
docker network connect mired contenedor       # Conectar existente
docker network disconnect mired contenedor    # Desconectar

# Eliminar redes
docker network rm mired
docker network prune                          # Limpiar sin usar
```

### Limpieza y Mantenimiento

```bash
# Limpiar todo lo que no se usa
docker system prune                           # Contenedores, redes, imágenes dangling
docker system prune -a                        # Incluir todas las imágenes
docker system prune -a --volumes              # Incluir volúmenes

# Limpiar por tipo
docker container prune                        # Solo contenedores detenidos
docker image prune                            # Solo imágenes dangling
docker image prune -a                         # Todas las imágenes sin contenedor
docker volume prune                           # Solo volúmenes sin usar
docker network prune                          # Solo redes sin usar

# Ver uso de disco
docker system df                              # Resumen de uso
docker system df -v                           # Detallado por recurso
```

---

## 📋 3. Dockerfile - Sintaxis Esencial

### Instrucciones Fundamentales

```dockerfile
# FROM - Imagen base (siempre primera instrucción)
FROM ubuntu:22.04
FROM node:20-alpine
FROM python:3.11-slim

# LABEL - Metadata de la imagen
LABEL maintainer="tu@email.com"
LABEL version="1.0"
LABEL description="Mi aplicación web"

# ENV - Variables de entorno
ENV NODE_ENV=production
ENV PORT=3000
ENV DATABASE_URL=postgres://db:5432

# WORKDIR - Directorio de trabajo
WORKDIR /app
WORKDIR /usr/src/app

# COPY - Copiar archivos del host a la imagen
COPY package.json .
COPY src/ /app/src/
COPY --chown=node:node . .

# ADD - Similar a COPY pero con features extra (descomprimir .tar)
ADD archivo.tar.gz /app/
ADD https://ejemplo.com/archivo.txt /app/

# RUN - Ejecutar comandos durante el build
RUN apt-get update && apt-get install -y curl
RUN npm install
RUN pip install -r requirements.txt

# Combinar RUN para reducir capas
RUN apt-get update && \
    apt-get install -y curl wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# EXPOSE - Documentar puertos que usa la app
EXPOSE 80
EXPOSE 3000
EXPOSE 8080 8443

# USER - Cambiar usuario (no usar root)
USER node
USER www-data
USER 1001

# CMD - Comando por defecto al iniciar contenedor (puede sobrescribirse)
CMD ["nginx", "-g", "daemon off;"]
CMD ["node", "server.js"]
CMD ["python", "app.py"]

# ENTRYPOINT - Comando principal (no se sobrescribe fácilmente)
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]  # Argumentos por defecto

# VOLUME - Declarar punto de montaje
VOLUME /data
VOLUME ["/var/log", "/var/db"]

# HEALTHCHECK - Verificar salud del contenedor
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/ || exit 1

# ARG - Argumentos de build-time
ARG VERSION=1.0
ARG BUILD_DATE
RUN echo "Building version $VERSION"
```

### Ejemplo Dockerfile Completo (Node.js)

```dockerfile
# Multi-stage build para optimización
FROM node:20-alpine AS builder

# Metadata
LABEL maintainer="dev@example.com"
LABEL version="1.0"

# Variables de build
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Directorio de trabajo
WORKDIR /app

# Copiar solo package files primero (cache de npm install)
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# Copiar código fuente
COPY . .

# Construir aplicación (si aplica)
RUN npm run build

# --- Stage 2: Runtime ---
FROM node:20-alpine

# Usuario no-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copiar node_modules y build desde builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Cambiar a usuario no-root
USER nodejs

# Exponer puerto
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD node healthcheck.js || exit 1

# Comando de inicio
CMD ["node", "dist/server.js"]
```

### Mejores Prácticas de Dockerfile

```dockerfile
# ✅ Usar imágenes oficiales y tags específicos
FROM node:20-alpine  # ✅ Específico
FROM node            # ❌ No usar 'latest' implícito

# ✅ Ordenar comandos para aprovechar cache
COPY package.json .  # Cambia poco
RUN npm install      # Cache de npm
COPY . .             # Cambia frecuentemente

# ✅ Combinar RUN para reducir capas
RUN apt-get update && \
    apt-get install -y package1 package2 && \
    apt-get clean

# ❌ Evitar múltiples RUN innecesarios
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# ✅ Usar .dockerignore para excluir archivos
# .dockerignore
node_modules
.git
*.log
.env

# ✅ No correr como root
USER node

# ❌ Nunca instalar dependencias innecesarias
RUN apt-get install -y vim emacs  # ❌ Herramientas de desarrollo

# ✅ Multi-stage builds para reducir tamaño final
FROM node:20 AS builder
RUN npm run build
FROM node:20-alpine
COPY --from=builder /app/dist ./dist
```

---

## 📋 4. Docker Compose - Orquestación Multi-Contenedor

### Estructura YAML Básica

```yaml
version: '3.8'

services:
  # Servicio 1: Base de datos
  db:
    image: postgres:16-alpine
    container_name: postgres-db
    restart: always
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
      POSTGRES_DB: mydb
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myuser"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Servicio 2: Aplicación web
  web:
    build:
      context: .
      dockerfile: Dockerfile
    image: myapp:latest
    container_name: web-app
    restart: unless-stopped
    ports:
      - "8080:3000"
    environment:
      DATABASE_URL: postgres://myuser:mypassword@db:5432/mydb
      NODE_ENV: production
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./logs:/app/logs
    networks:
      - backend
      - frontend

  # Servicio 3: Proxy reverso
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - web
    networks:
      - frontend

volumes:
  db-data:
    driver: local

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # Solo comunicación interna
```

### Comandos Docker Compose

```bash
# Iniciar servicios
docker compose up                        # Foreground
docker compose up -d                     # Detached (background)
docker compose up --build                # Rebuild imágenes
docker compose up -d --scale web=3       # Escalar servicio

# Ver servicios corriendo
docker compose ps
docker compose ps -a                     # Incluir detenidos

# Ver logs
docker compose logs                      # Todos los servicios
docker compose logs web                  # Servicio específico
docker compose logs -f web               # Seguir logs
docker compose logs --tail 100 web       # Últimas 100 líneas

# Ejecutar comandos en servicio
docker compose exec web bash             # Shell interactivo
docker compose exec db psql -U myuser    # Cliente PostgreSQL
docker compose exec -T web comando       # Sin TTY (scripts)

# Gestión de servicios
docker compose start                     # Iniciar detenidos
docker compose stop                      # Detener
docker compose restart web               # Reiniciar servicio
docker compose pause web                 # Pausar
docker compose unpause web               # Reanudar

# Detener y eliminar
docker compose down                      # Detener y eliminar contenedores
docker compose down -v                   # Incluir volúmenes
docker compose down --rmi all            # Incluir imágenes

# Ver configuración
docker compose config                    # Ver YAML procesado
docker compose config --services         # Listar servicios
docker compose config --volumes          # Listar volúmenes

# Build
docker compose build                     # Build todos los servicios
docker compose build web                 # Build servicio específico
docker compose build --no-cache          # Sin cache

# Pull/Push
docker compose pull                      # Descargar imágenes
docker compose push                      # Subir a registry
```

---

## 🔍 5. Troubleshooting Común

### Problema 1: Contenedor no arranca (Exit inmediato)

**Síntomas**:
```bash
$ docker ps -a
CONTAINER ID   STATUS                      
abc123         Exited (1) 2 seconds ago
```

**Diagnóstico**:
```bash
# Ver logs del contenedor
docker logs abc123

# Ver detalles completos
docker inspect abc123 | grep -A 10 State

# Errores comunes en logs:
# - "No such file or directory" → Comando no existe
# - "Permission denied" → Problemas de permisos
# - "Address already in use" → Puerto ocupado
```

**Soluciones**:

1. **Comando no existe en la imagen**:
```bash
# Verificar qué binarios tiene la imagen
docker run --rm imagen ls /usr/bin
docker run --rm imagen which comando

# Solución: Instalar en Dockerfile
RUN apt-get install -y comando
```

2. **Puerto ya en uso**:
```bash
# Ver qué proceso usa el puerto
sudo lsof -i :8080
sudo netstat -tulpn | grep 8080

# Solución: Cambiar puerto o detener proceso
docker run -p 8081:80 nginx  # Usar otro puerto
```

3. **Aplicación requiere archivo de config faltante**:
```bash
# Solución: Montar configuración
docker run -v /host/config.yml:/app/config.yml imagen
```

---

### Problema 2: Cannot connect to Docker daemon

**Síntomas**:
```bash
$ docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Diagnóstico**:
```bash
# Verificar estado del servicio
sudo systemctl status docker

# Verificar socket existe
ls -l /var/run/docker.sock

# Verificar permisos
groups $USER | grep docker
```

**Soluciones**:

1. **Docker no está corriendo**:
```bash
sudo systemctl start docker
sudo systemctl enable docker  # Auto-start en boot
```

2. **Usuario no tiene permisos**:
```bash
# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Cerrar sesión y volver a entrar, o:
newgrp docker

# Verificar
groups
```

3. **Socket con permisos incorrectos**:
```bash
sudo chmod 666 /var/run/docker.sock
# O mejor: reiniciar Docker daemon
sudo systemctl restart docker
```

---

### Problema 3: Contenedor no puede resolver DNS

**Síntomas**:
```bash
$ docker exec contenedor ping google.com
ping: google.com: Temporary failure in name resolution
```

**Diagnóstico**:
```bash
# Verificar DNS del contenedor
docker exec contenedor cat /etc/resolv.conf

# Verificar DNS del host
cat /etc/resolv.conf

# Probar DNS manualmente
docker exec contenedor nslookup google.com
docker exec contenedor dig google.com
```

**Soluciones**:

1. **Usar DNS público (Google, Cloudflare)**:
```bash
# En docker run
docker run --dns 8.8.8.8 --dns 8.8.4.4 imagen

# En daemon.json (/etc/docker/daemon.json)
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
sudo systemctl restart docker
```

2. **En Docker Compose**:
```yaml
services:
  web:
    image: nginx
    dns:
      - 8.8.8.8
      - 8.8.4.4
```

3. **Problemas con firewall**:
```bash
# Verificar reglas iptables
sudo iptables -L -n | grep DOCKER

# Reiniciar Docker para recrear reglas
sudo systemctl restart docker
```

---

### Problema 4: "No space left on device" al construir imagen

**Síntomas**:
```bash
$ docker build -t miapp .
ERROR: failed to solve: write /var/lib/docker/...: no space left on device
```

**Diagnóstico**:
```bash
# Ver uso de disco de Docker
docker system df
docker system df -v

# Ver espacio total del sistema
df -h /var/lib/docker
```

**Soluciones**:

1. **Limpiar recursos sin usar**:
```bash
# Limpiar todo (cuidado en producción)
docker system prune -a --volumes

# Paso a paso
docker container prune    # Contenedores detenidos
docker image prune -a     # Imágenes sin contenedor
docker volume prune       # Volúmenes sin usar
docker network prune      # Redes sin usar
```

2. **Eliminar imágenes específicas**:
```bash
# Ver imágenes grandes
docker images --format "{{.Size}}\t{{.Repository}}:{{.Tag}}" | sort -h

# Eliminar imágenes antiguas
docker images | grep "months ago" | awk '{print $3}' | xargs docker rmi
```

3. **Cambiar ubicación de Docker data**:
```bash
# Detener Docker
sudo systemctl stop docker

# Editar /etc/docker/daemon.json
{
  "data-root": "/new/path/docker"
}

# Mover datos
sudo rsync -aP /var/lib/docker/ /new/path/docker

# Reiniciar
sudo systemctl start docker
```

---

### Problema 5: Imagen muy grande (GB)

**Síntomas**:
```bash
$ docker images
myapp    latest    3.2GB
```

**Diagnóstico**:
```bash
# Ver capas de la imagen
docker history myapp:latest

# Ver capas más grandes
docker history myapp:latest --no-trunc | sort -k 2 -h
```

**Soluciones**:

1. **Usar imagen base Alpine (mínima)**:
```dockerfile
# Antes
FROM ubuntu:22.04    # ~80MB base

# Después
FROM alpine:3.18     # ~7MB base
FROM node:20-alpine  # ~170MB vs node:20 (1GB)
```

2. **Multi-stage builds**:
```dockerfile
# Stage 1: Build (grande)
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Stage 2: Runtime (mínima)
FROM alpine:3.18
COPY --from=builder /app/myapp /usr/local/bin/
CMD ["myapp"]
```

3. **Optimizar RUN para reducir capas**:
```dockerfile
# ❌ Mal: 3 capas
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean

# ✅ Bien: 1 capa
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

4. **Usar .dockerignore**:
```
# .dockerignore
node_modules
.git
*.log
.env
coverage
test
*.md
```

---

### Problema 6: Contenedor consume 100% CPU

**Síntomas**:
```bash
$ docker stats
CONTAINER  CPU %   MEM USAGE
myapp      234%    512MB
```

**Diagnóstico**:
```bash
# Ver procesos dentro del contenedor
docker top myapp

# Ver stats detallados
docker stats myapp --no-stream

# Ejecutar herramientas de profiling
docker exec myapp top
docker exec myapp ps aux
```

**Soluciones**:

1. **Limitar recursos del contenedor**:
```bash
# Limitar a 1 CPU y 512MB RAM
docker run -d \
  --cpus="1.0" \
  --memory="512m" \
  --name myapp \
  myimage
```

2. **En Docker Compose**:
```yaml
services:
  web:
    image: myapp
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

3. **Identificar código problemático**:
```bash
# Entrar al contenedor y debuggear
docker exec -it myapp bash

# Ver archivos abiertos (posible leak)
lsof | wc -l

# Ver threads
ps -eLf | wc -l
```

---

## 📋 6. Checklist de Conceptos Clave

### ✅ Fundamentos de Contenedores
- [ ] Entiendo qué es un contenedor (proceso aislado, NO una VM ligera)
- [ ] Conozco las 3 tecnologías: namespaces, cgroups, union FS
- [ ] Puedo explicar por qué los contenedores comparten el kernel
- [ ] Comprendo el sistema de capas (layers) de las imágenes
- [ ] Sé la diferencia entre imagen y contenedor

### ✅ Docker CLI - Operaciones Básicas
- [ ] `docker run` con opciones: `-d`, `-p`, `-v`, `-e`, `--name`, `--rm`
- [ ] `docker ps` / `docker ps -a` para listar contenedores
- [ ] `docker logs -f` para ver logs en tiempo real
- [ ] `docker exec -it` para entrar a un contenedor corriendo
- [ ] `docker stop` / `docker rm` para gestión de ciclo de vida

### ✅ Dockerfiles y Construcción de Imágenes
- [ ] Conozco las instrucciones: FROM, RUN, COPY, CMD, ENTRYPOINT, EXPOSE
- [ ] Puedo crear un Dockerfile básico para mi aplicación
- [ ] Entiendo el concepto de multi-stage builds
- [ ] Sé ordenar instrucciones para aprovechar cache de build
- [ ] Uso imágenes Alpine para minimizar tamaño

### ✅ Docker Compose
- [ ] Puedo escribir un docker-compose.yml con múltiples servicios
- [ ] Uso `depends_on` para orquestar inicio de servicios
- [ ] Configuro volúmenes para persistencia de datos
- [ ] Defino redes para aislar servicios
- [ ] Comando `docker compose up -d` / `docker compose down`

### ✅ Troubleshooting
- [ ] Sé usar `docker logs` para diagnosticar errores
- [ ] Uso `docker inspect` para ver configuración completa
- [ ] Puedo resolver problemas de networking entre contenedores
- [ ] Identifico y soluciono problemas de permisos en volúmenes
- [ ] Optimizo imágenes grandes usando mejores prácticas

---

## 🎓 7. Para Certificaciones

### Relevancia en CKA/CKAD

**Cobertura en exámenes**: ~15-20%

**Conceptos Docker que aparecen en Kubernetes**:
- **Container Runtime**: Kubernetes usa containerd (no Docker Engine directamente)
- **Imágenes**: Los Pods ejecutan contenedores desde imágenes Docker
- **Image Pull Policies**: `Always`, `IfNotPresent`, `Never`
- **Registries**: ImagePullSecrets para registries privados
- **Resource Limits**: Similar a `--cpus` y `--memory` de Docker

**Preguntas típicas CKA/CKAD**:
> "Un Pod no puede descargar la imagen. ¿Cómo diagnosticas?"

**Respuesta esperada**:
```bash
# Ver eventos del Pod
kubectl describe pod mypod | grep -A 10 Events

# Errores comunes:
# - ErrImagePull: Imagen no existe o registry inaccesible
# - ImagePullBackOff: Retry después de fallo
# - ErrImageNeverPull: Policy Never pero imagen no está local

# Soluciones:
# 1. Verificar nombre de imagen
# 2. Verificar ImagePullSecrets si es registry privado
# 3. Cambiar imagePullPolicy a IfNotPresent
```

### Comandos críticos para memorizar (CKA/CKAD)

```bash
# Docker CLI (contexto)
docker run / ps / logs / exec / inspect

# Dockerfile (para entender Pods)
FROM / RUN / COPY / CMD / ENTRYPOINT

# Troubleshooting de contenedores
docker logs -f
docker exec -it CONTAINER bash
docker inspect CONTAINER

# Kubernetes equivalentes
kubectl run / get pods / logs / exec / describe
```

---

## 📚 8. Recursos Adicionales

### Documentación Oficial

- **[Docker Docs](https://docs.docker.com/)** - Documentación completa
- **[Docker Hub](https://hub.docker.com/)** - Registry de imágenes públicas
- **[Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)**
- **[Docker Compose Reference](https://docs.docker.com/compose/compose-file/)**
- **[Docker Security](https://docs.docker.com/engine/security/)**

### Herramientas Complementarias

- **[Hadolint](https://github.com/hadolint/hadolint)** - Linter para Dockerfiles
- **[Dive](https://github.com/wagoodman/dive)** - Analizar capas de imágenes
- **[Trivy](https://github.com/aquasecurity/trivy)** - Scanner de vulnerabilidades
- **[Portainer](https://www.portainer.io/)** - GUI para gestión de Docker
- **[Lazydocker](https://github.com/jesseduffield/lazydocker)** - TUI para Docker

### Alternativas a Docker

- **[Podman](https://podman.io/)** - Compatible con Docker, sin daemon, más seguro
- **[containerd](https://containerd.io/)** - Runtime usado por Kubernetes
- **[CRI-O](https://cri-o.io/)** - Runtime específico para Kubernetes
- **[Buildah](https://buildah.io/)** - Construir imágenes sin daemon

---

## 🎯 9. Siguiente Paso

**¿Terminaste este módulo?** ¡Excelente! Ahora estás listo para:

➡️ **[Área 2 - Módulo 1: Introducción a Kubernetes](../../area-2-arquitectura-kubernetes/modulo-01-introduccion-kubernetes/README.md)**

**Lo que aprenderás en Kubernetes**:
- Cómo Kubernetes orquesta miles de contenedores
- Pods como unidad básica (agrupa contenedores)
- Deployments para gestionar replicas y rollouts
- Services para networking entre Pods
- ConfigMaps y Secrets (mejora sobre `-e` de Docker)
- Volumes persistentes (evolución de volúmenes Docker)

**Estadísticas del Módulo 2**:
- ⏱️ **Duración típica**: 6-8 horas (principiante) | 4-5 horas (intermedio)
- 📄 **Páginas de teoría**: ~40 páginas
- 🧪 **Laboratorios**: 5 labs (instalación, comandos, Dockerfile, redes, Compose)
- 📊 **Conceptos clave**: 35+ términos técnicos
- ❓ **Comandos esenciales**: 50+ comandos Docker

---

**✅ Has completado Docker - ¡Estás listo para Kubernetes!**

*Los contenedores son los bloques de construcción. Kubernetes es el arquitecto que los orquesta a escala.*
