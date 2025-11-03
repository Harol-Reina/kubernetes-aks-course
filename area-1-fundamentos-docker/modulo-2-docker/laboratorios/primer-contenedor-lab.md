# 🐳 Lab M2.1: Primer Contenedor

**Duración**: 30 minutos  
**Dificultad**: Principiante  
**Prerequisitos**: Docker instalado

## 🎯 Objetivos

- Ejecutar tu primer contenedor Docker
- Entender la diferencia entre imágenes y contenedores
- Explorar comandos básicos de gestión
- Comparar con VMs del Módulo 1

---

## 📋 Prerequisitos

```bash
# Verificar instalación Docker
docker --version
# Docker version 24.0.6, build ed223bc

# Verificar servicio activo
sudo systemctl status docker
```

---

## 🚀 Ejercicio 1: Hello World

### **Paso 1: Ejecutar primer contenedor**

```bash
# Ejecutar contenedor básico
docker run hello-world

# ¿Qué sucede?
# 1. Docker busca la imagen 'hello-world' localmente
# 2. No la encuentra, la descarga de Docker Hub
# 3. Crea un contenedor nuevo
# 4. Ejecuta el contenedor
# 5. Muestra el mensaje y termina
```

### **Paso 2: Listar contenedores**

```bash
# Ver contenedores en ejecución
docker ps

# Ver todos los contenedores (incluidos detenidos)
docker ps -a

# Encontrarás el contenedor hello-world con status "Exited"
```

### **Reflexión**: 
- ¿Cuánto tiempo tomó ejecutar vs. una VM?
- ¿Qué recursos consume el contenedor detenido?

---

## 🌐 Ejercicio 2: Servidor Web Interactivo

### **Paso 1: Ejecutar Nginx**

```bash
# Ejecutar servidor web en background
docker run -d --name mi-nginx -p 8080:80 nginx

# -d: detached (background)
# --name: nombre personalizado
# -p 8080:80: mapear puerto host:contenedor
```

### **Paso 2: Verificar funcionamiento**

```bash
# Ver contenedores ejecutándose
docker ps

# Probar conectividad
curl http://localhost:8080
# Deberías ver el HTML de bienvenida de Nginx

# Desde navegador
# http://localhost:8080
```

### **Paso 3: Inspeccionar contenedor**

```bash
# Ver detalles del contenedor
docker inspect mi-nginx

# Ver logs
docker logs mi-nginx

# Ver procesos internos
docker exec mi-nginx ps aux
```

---

## 🔧 Ejercicio 3: Contenedor Interactivo

### **Paso 1: Ubuntu interactivo**

```bash
# Crear contenedor Ubuntu interactivo
docker run -it --name mi-ubuntu ubuntu:22.04 bash

# -i: interactivo
# -t: pseudo-terminal
# ubuntu:22.04: imagen específica
# bash: comando a ejecutar
```

### **Paso 2: Explorar dentro del contenedor**

```bash
# Dentro del contenedor Ubuntu
cat /etc/os-release

# Ver procesos
ps aux

# Ver filesystem
ls -la /

# Instalar herramientas
apt update && apt install -y curl htop

# Ver recursos
htop
```

### **Paso 3: Comparar con el host**

```bash
# Abrir otra terminal (fuera del contenedor)
# Ver procesos del host
ps aux | grep docker

# Ver namespaces
sudo lsns

# ¿Qué diferencias notas?
```

---

## 📊 Ejercicio 4: Gestión de Recursos

### **Paso 1: Contenedor con límites**

```bash
# Contenedor con límites de recursos
docker run -d --name nginx-limitado \
  --memory="128m" \
  --cpus="0.5" \
  -p 8081:80 \
  nginx

# --memory: límite de RAM
# --cpus: límite de CPU
```

### **Paso 2: Monitorear recursos**

```bash
# Ver estadísticas en tiempo real
docker stats

# Ver solo contenedores específicos
docker stats nginx-limitado mi-nginx

# Comparar consumo entre contenedores
```

### **Paso 3: Prueba de carga**

```bash
# Instalar herramienta de carga (en el host)
sudo apt install -y apache2-utils

# Generar carga en nginx limitado
ab -n 1000 -c 10 http://localhost:8081/

# Observar estadísticas durante la carga
docker stats nginx-limitado
```

---

## 🧹 Ejercicio 5: Limpieza y Gestión

### **Paso 1: Detener contenedores**

```bash
# Detener contenedor específico
docker stop mi-nginx

# Detener todos los contenedores
docker stop $(docker ps -q)

# Ver estado después de detener
docker ps -a
```

### **Paso 2: Eliminar contenedores**

```bash
# Eliminar contenedor específico
docker rm hello-world

# Eliminar contenedor en ejecución (forzado)
docker rm -f nginx-limitado

# Eliminar todos los contenedores detenidos
docker container prune
```

### **Paso 3: Gestión de imágenes**

```bash
# Ver imágenes descargadas
docker images

# Información de una imagen
docker inspect nginx

# Eliminar imagen no utilizada
docker rmi hello-world

# Limpiar imágenes no utilizadas
docker image prune
```

---

## 🔍 Ejercicio 6: Debugging y Troubleshooting

### **Paso 1: Acceder a contenedor en ejecución**

```bash
# Ejecutar comando en contenedor activo
docker exec mi-nginx cat /etc/nginx/nginx.conf

# Sesión interactiva en contenedor
docker exec -it mi-nginx bash

# Dentro del contenedor nginx
ls -la /usr/share/nginx/html/
cat /var/log/nginx/access.log
```

### **Paso 2: Copiar archivos**

```bash
# Crear archivo HTML personalizado
echo "<h1>Mi página personalizada</h1>" > custom.html

# Copiar al contenedor
docker cp custom.html mi-nginx:/usr/share/nginx/html/

# Verificar desde navegador
curl http://localhost:8080/custom.html
```

### **Paso 3: Análisis de problemas**

```bash
# Ver logs detallados
docker logs --follow mi-nginx

# En otra terminal, generar requests
curl http://localhost:8080/inexistente

# Ver logs de error
docker logs mi-nginx | grep error
```

---

## 📋 Verificación de Aprendizaje

### **Preguntas de reflexión:**

1. **¿Cuánto tiempo tomó arrancar cada contenedor vs. una VM?**
2. **¿Qué sucede cuando detienes un contenedor? ¿Se pierden los datos?**
3. **¿Cómo se compara el consumo de recursos con VMs?**
4. **¿Qué ventajas y desventajas notas comparado con VMs?**

### **Comandos que debes dominar:**

```bash
# Básicos
docker run
docker ps
docker stop
docker rm

# Inspección
docker logs
docker inspect
docker stats

# Ejecución
docker exec
docker cp
```

---

## 🎓 Resultado Esperado

Al completar este laboratorio, deberías poder:

- ✅ Ejecutar contenedores en modo detached e interactivo
- ✅ Gestionar el ciclo de vida de contenedores
- ✅ Mapear puertos y acceder a servicios
- ✅ Monitorear recursos y logs
- ✅ Comparar ventajas de contenedores vs VMs
- ✅ Realizar troubleshooting básico

---

## 🚀 Siguiente Paso

**[Lab M2.2: Imágenes Personalizadas](./imagenes-personalizadas-lab.md)**

---

## 🔧 Troubleshooting

### **Error: "docker: command not found"**
```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Logout y login nuevamente
```

### **Error: "permission denied"**
```bash
# Agregar usuario al grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### **Puerto 8080 ocupado**
```bash
# Usar puerto diferente
docker run -d --name mi-nginx -p 8090:80 nginx
```