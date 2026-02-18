# Laboratorio: Instalación y Comandos Básicos de Docker

**Duración**: 60 minutos  
**Objetivo**: Instalar Docker en la VM de Azure y ejecutar los primeros contenedores para entender los fundamentos de la contenerización.

## 🎯 Objetivos de aprendizaje

- Instalar Docker Engine en Ubuntu
- Ejecutar los primeros contenedores
- Comprender la diferencia entre imágenes y contenedores
- Gestionar contenedores con comandos básicos
- Comparar el rendimiento con las VMs del módulo anterior

---

## 📋 Prerequisitos

- VM de Azure del laboratorio anterior (o crear una nueva)
- Acceso SSH a la VM
- Conocimientos básicos de línea de comandos Linux

---

## 🔧 Laboratorio 1: Instalación de Docker

### Paso 1: Conectarse a la VM

```bash
# Conectarse a la VM del laboratorio anterior
ssh -i ~/Downloads/vm-key-lab1.pem azureuser@<IP_PUBLICA>
```

### Paso 2: Preparar el sistema

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar paquetes necesarios
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common
```

### Paso 3: Agregar repositorio oficial de Docker

```bash
# Agregar clave GPG oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Verificar la clave (debe mostrar la huella digital)
sudo gpg --show-keys /usr/share/keyrings/docker-archive-keyring.gpg

# Agregar repositorio Docker
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Paso 4: Instalar Docker Engine

```bash
# Actualizar índice de paquetes
sudo apt update

# Instalar Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verificar que Docker se instaló correctamente
sudo docker --version
sudo docker compose version
```

### Paso 5: Configurar Docker para uso sin sudo

```bash
# Agregar usuario actual al grupo docker
sudo usermod -aG docker $USER

# Mostrar grupos del usuario
groups $USER

# Cerrar sesión y volver a conectar para aplicar cambios
exit
```

```bash
# Reconectarse
ssh -i ~/Downloads/vm-key-lab1.pem azureuser@<IP_PUBLICA>

# Verificar que Docker funciona sin sudo
docker --version
docker info
```

---

## 🔧 Laboratorio 2: Primeros contenedores

### Paso 1: Hello World de Docker

```bash
# Ejecutar el primer contenedor
docker run hello-world

# ¿Qué pasó?
# 1. Docker buscó la imagen 'hello-world' localmente
# 2. Como no la encontró, la descargó de Docker Hub
# 3. Creó un contenedor a partir de la imagen
# 4. Ejecutó el contenedor
# 5. El contenedor mostró el mensaje y se detuvo
```

### Paso 2: Explorar lo que sucedió

```bash
# Ver todos los contenedores (incluidos los detenidos)
docker ps -a

# Ver las imágenes descargadas
docker images

# Inspeccionar la imagen hello-world
docker inspect hello-world

# Ver historial de la imagen
docker history hello-world
```

### Paso 3: Contenedor interactivo

```bash
# Ejecutar contenedor Ubuntu interactivo
docker run -it ubuntu:22.04 bash

# Dentro del contenedor, ejecutar:
ls /
cat /etc/os-release
ps aux
whoami
hostname
exit
```

### Paso 4: Contenedor en background

```bash
# Ejecutar nginx en background
docker run -d -p 80:80 --name mi-nginx nginx

# ¿Qué significan los parámetros?
# -d: detached (en background)
# -p 80:80: mapear puerto 80 del host al puerto 80 del contenedor
# --name: dar un nombre al contenedor
# nginx: imagen a usar
```

### Paso 5: Interactuar con el contenedor nginx

```bash
# Ver contenedores en ejecución
docker ps

# Probar que nginx funciona
curl http://localhost
curl -I http://localhost

# Ver logs del contenedor
docker logs mi-nginx

# Ver estadísticas en tiempo real
docker stats mi-nginx
# Presiona Ctrl+C para salir

# Ejecutar comando dentro del contenedor
docker exec -it mi-nginx bash

# Dentro del contenedor nginx:
ls /usr/share/nginx/html/
cat /usr/share/nginx/html/index.html
ps aux
exit
```

---

## 🔧 Laboratorio 3: Gestión de contenedores

### Paso 1: Ciclo de vida de contenedores

```bash
# Crear contenedor sin iniciarlo
docker create --name mi-ubuntu ubuntu:22.04

# Ver estado del contenedor
docker ps -a

# Iniciar el contenedor
docker start mi-ubuntu

# Ver estado
docker ps -a

# Detener el contenedor
docker stop mi-ubuntu

# Ver estado
docker ps -a

# Eliminar el contenedor
docker rm mi-ubuntu

# Verificar que se eliminó
docker ps -a
```

### Paso 2: Múltiples contenedores

```bash
# Ejecutar varios contenedores nginx
docker run -d -p 8080:80 --name nginx1 nginx
docker run -d -p 8081:80 --name nginx2 nginx
docker run -d -p 8082:80 --name nginx3 nginx

# Ver todos los contenedores
docker ps

# Probar cada uno
curl http://localhost:8080
curl http://localhost:8081  
curl http://localhost:8082

# Ver estadísticas de todos
docker stats --no-stream
```

### Paso 3: Gestión de imágenes

```bash
# Descargar imagen sin ejecutar contenedor
docker pull redis:alpine
docker pull postgres:15

# Ver todas las imágenes
docker images

# Ver espacio usado
docker system df

# Información detallada de una imagen
docker inspect nginx
```

---

## 🔧 Laboratorio 4: Comandos útiles

### Paso 1: Comandos de información

```bash
# Información general de Docker
docker info

# Versión detallada
docker version

# Ayuda de comandos
docker --help
docker run --help
```

### Paso 2: Comandos de limpieza

```bash
# Detener todos los contenedores
docker stop $(docker ps -q)

# Eliminar todos los contenedores detenidos
docker container prune -f

# Ver contenedores restantes
docker ps -a

# Eliminar imágenes no utilizadas
docker image prune -f

# Limpiar todo el sistema (cuidado!)
docker system prune -f

# Ver espacio liberado
docker system df
```

### Paso 3: Comandos de búsqueda

```bash
# Buscar imágenes en Docker Hub
docker search nginx
docker search redis
docker search "python"

# Descargar imagen específica
docker pull nginx:alpine
docker pull redis:6-alpine

# Comparar tamaños
docker images | grep nginx
docker images | grep redis
```

---

## 🧪 Ejercicios prácticos

### **Ejercicio 1: Comparación de arranque**

```bash
# Medir tiempo de arranque de contenedor
time docker run --rm hello-world

# Crear VM nueva para comparar
# (En Azure Portal, crear nueva VM y medir tiempo de arranque)

# ¿Cuál es más rápido? ¿Por qué?
```

### **Ejercicio 2: Uso de recursos**

```bash
# Ejecutar contenedor con límites de memoria
docker run -d --name limited-nginx --memory="50m" nginx

# Verificar límites
docker stats limited-nginx --no-stream

# Ejecutar sin límites
docker run -d --name unlimited-nginx nginx

# Comparar
docker stats --no-stream
```

### **Ejercicio 3: Persistencia de datos**

```bash
# Crear archivo en contenedor
docker run -it --name test-ubuntu ubuntu:22.04 bash
# Dentro del contenedor:
echo "Hola desde el contenedor" > /tmp/mi-archivo.txt
cat /tmp/mi-archivo.txt
exit

# Eliminar contenedor
docker rm test-ubuntu

# Crear nuevo contenedor de la misma imagen
docker run -it --name test-ubuntu2 ubuntu:22.04 bash
# Dentro del contenedor:
ls /tmp/
# ¿Está el archivo? ¿Por qué?
exit
```

### **Ejercicio 4: Variables de entorno**

```bash
# Ejecutar contenedor con variables de entorno
docker run -d --name mysql-test \
  -e MYSQL_ROOT_PASSWORD=mi-password \
  -e MYSQL_DATABASE=mi-base \
  mysql:8

# Ver las variables en el contenedor
docker exec mysql-test env | grep MYSQL

# Ver logs para confirmar configuración
docker logs mysql-test
```

---

## 📊 Análisis comparativo: VMs vs Contenedores

### **Métricas a comparar:**

```bash
# 1. Tiempo de arranque
# VM: ~2-5 minutos
# Contenedor: 
time docker run --rm nginx nginx -v
```

```bash
# 2. Uso de memoria
# Ver memoria de la VM host
free -h

# Ver memoria de contenedores
docker stats --no-stream
```

```bash
# 3. Tamaño en disco
# VM: Varios GB
# Imágenes Docker:
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

```bash
# 4. Densidad (cuántos puedes ejecutar)
# VM en Azure B1s: 1 VM por host
# Contenedores: Probar ejecutar 10 nginx
for i in {1..10}; do
  docker run -d --name nginx$i -p $((8080+i)):80 nginx
done

docker ps
docker stats --no-stream
```

---

## 🔄 Casos de uso prácticos

### **Caso 1: Servidor web temporal**

```bash
# Necesitas un servidor web rápido para pruebas
docker run -d -p 3000:80 --name web-temp nginx

# Probar
curl http://localhost:3000

# Cuando termines, eliminar
docker rm -f web-temp
```

### **Caso 2: Base de datos para desarrollo**

```bash
# Necesitas PostgreSQL para desarrollar
docker run -d --name postgres-dev \
  -e POSTGRES_PASSWORD=dev123 \
  -e POSTGRES_DB=mi_app \
  -p 5432:5432 \
  postgres:15

# Conectarse (necesitas cliente psql)
# docker exec -it postgres-dev psql -U postgres -d mi_app
```

### **Caso 3: Herramienta temporal**

```bash
# Necesitas usar una herramienta sin instalarla
docker run --rm -it python:3.11 python

# Dentro de Python:
print("Hola desde contenedor Python!")
import sys
print(sys.version)
exit()
```

---

## 📝 Cuestionario de comprensión

1. **¿Cuál es la diferencia entre una imagen y un contenedor?**

2. **¿Por qué los contenedores arrancan más rápido que las VMs?**

3. **¿Qué sucede con los datos cuando eliminas un contenedor?**

4. **¿Cuándo usarías una VM y cuándo un contenedor?**

5. **¿Qué problemas resuelve Docker comparado con VMs?**

---

## 🧹 Limpieza

```bash
# Detener todos los contenedores
docker stop $(docker ps -q)

# Eliminar todos los contenedores
docker rm $(docker ps -aq)

# Eliminar imágenes no usadas
docker image prune -f

# Limpiar todo
docker system prune -a -f

# Verificar limpieza
docker ps -a
docker images
```

---

## 📝 Entregables del laboratorio

1. **Screenshots** de:
   - Instalación exitosa de Docker
   - Múltiples contenedores ejecutándose
   - Comparación de stats entre VMs y contenedores

2. **Comandos ejecutados** y su output

3. **Respuestas** al cuestionario de comprensión

4. **Reflexión**: ¿Cómo cambiaría tu flujo de desarrollo usando contenedores?

---

## 🔗 Siguientes pasos

Con este laboratorio completado:

- ✅ Entiendes la diferencia práctica entre VMs y contenedores
- ✅ Puedes gestionar contenedores básicos
- ✅ Comprendes las ventajas de Docker
- ✅ Estás listo para conceptos avanzados de contenedores
- ✅ Preparado para entender por qué necesitas Kubernetes

**Tiempo estimado**: 60-90 minutos  
**Dificultad**: Básico-Intermedio