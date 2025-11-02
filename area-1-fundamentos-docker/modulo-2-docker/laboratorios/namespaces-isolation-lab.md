# Ejercicio Práctico: Explorando Namespaces y Aislamiento

**Duración**: 30 minutos  
**Objetivo**: Demostrar prácticamente el aislamiento de namespaces entre contenedores.

## 🎯 Objetivos de aprendizaje

- Comprobar el aislamiento de procesos (PID namespace)
- Verificar el aislamiento de red (Network namespace)
- Demostrar el aislamiento de sistema de archivos (Mount namespace)
- Experimentar con el control de recursos (cgroups)
- Entender la diferencia con VMs del módulo anterior

---

## 📋 Prerequisitos

- Docker instalado y funcionando
- VM de Azure del laboratorio anterior
- Acceso SSH a la VM

---

## 🧪 Ejercicio 1: Aislamiento de Procesos (PID Namespace)

### Paso 1: Crear múltiples contenedores

```bash
# Conectarse a la VM
ssh -i ~/Downloads/vm-key-lab1.pem azureuser@<IP_PUBLICA>

# Ejecutar primer contenedor
docker run -d --name contenedor-a ubuntu:22.04 sleep 3600

# Ejecutar segundo contenedor
docker run -d --name contenedor-b ubuntu:22.04 sleep 3600

# Ejecutar tercer contenedor con más procesos
docker run -d --name contenedor-c nginx
```

### Paso 2: Explorar procesos en cada contenedor

```bash
# Ver procesos en contenedor-a
echo "=== PROCESOS EN CONTENEDOR A ==="
docker exec contenedor-a ps aux

# Ver procesos en contenedor-b
echo "=== PROCESOS EN CONTENEDOR B ==="
docker exec contenedor-b ps aux

# Ver procesos en contenedor-c
echo "=== PROCESOS EN CONTENEDOR C ==="
docker exec contenedor-c ps aux
```

### Paso 3: Analizar el aislamiento

```bash
# Desde el host - ver todos los procesos Docker
echo "=== PROCESOS EN EL HOST ==="
ps aux | grep -E "(docker|sleep|nginx)" | grep -v grep

# ¿Pueden verse entre contenedores?
echo "=== INTENTAR VER PROCESOS DE OTRO CONTENEDOR ==="
docker exec contenedor-a ps aux | grep nginx
# Resultado: No debe aparecer nginx (está en contenedor-c)
```

### 🤔 **Pregunta de análisis:**
¿Por qué cada contenedor ve diferentes PIDs a pesar de estar en la misma máquina?

---

## 🧪 Ejercicio 2: Aislamiento de Red (Network Namespace)

### Paso 1: Inspeccionar las redes de contenedores

```bash
# Ver IP de cada contenedor
echo "=== IPs DE LOS CONTENEDORES ==="
docker inspect contenedor-a | grep IPAddress
docker inspect contenedor-b | grep IPAddress
docker inspect contenedor-c | grep IPAddress

# Verificar desde dentro de cada contenedor
echo "=== RED VISTA DESDE CONTENEDOR A ==="
docker exec contenedor-a ip addr show

echo "=== RED VISTA DESDE CONTENEDOR B ==="
docker exec contenedor-b ip addr show
```

### Paso 2: Probar conectividad entre contenedores

```bash
# Obtener IP del contenedor-c (nginx)
NGINX_IP=$(docker inspect contenedor-c | grep '"IPAddress"' | head -1 | cut -d '"' -f 4)
echo "IP de nginx: $NGINX_IP"

# Desde contenedor-a, intentar conectar a nginx
docker exec contenedor-a apt update && docker exec contenedor-a apt install -y curl
docker exec contenedor-a curl -I http://$NGINX_IP

# Desde contenedor-b, intentar lo mismo
docker exec contenedor-b apt update && docker exec contenedor-b apt install -y curl  
docker exec contenedor-b curl -I http://$NGINX_IP
```

### Paso 3: Crear red personalizada para probar conectividad

```bash
# Crear red personalizada
docker network create mi-red-prueba

# Ejecutar contenedores en la misma red
docker run -d --name web1 --network mi-red-prueba nginx
docker run -d --name web2 --network mi-red-prueba nginx

# Probar conectividad por nombre
docker exec web1 curl -I http://web2
docker exec web2 curl -I http://web1
```

### 🤔 **Pregunta de análisis:**
¿Cómo se compara esto con las VMs donde cada una tenía su propia IP?

---

## 🧪 Ejercicio 3: Aislamiento de Sistema de Archivos (Mount Namespace)

### Paso 1: Crear archivos en cada contenedor

```bash
# Crear archivo en contenedor-a
docker exec contenedor-a bash -c "echo 'Archivo desde contenedor A' > /tmp/archivo-a.txt"
docker exec contenedor-a cat /tmp/archivo-a.txt

# Crear archivo en contenedor-b
docker exec contenedor-b bash -c "echo 'Archivo desde contenedor B' > /tmp/archivo-b.txt" 
docker exec contenedor-b cat /tmp/archivo-b.txt

# Ver qué archivos ve cada contenedor
echo "=== ARCHIVOS EN CONTENEDOR A ==="
docker exec contenedor-a ls -la /tmp/

echo "=== ARCHIVOS EN CONTENEDOR B ==="
docker exec contenedor-b ls -la /tmp/
```

### Paso 2: Intentar acceso cruzado

```bash
# ¿Puede contenedor-a ver el archivo de contenedor-b?
echo "=== CONTENEDOR A BUSCA ARCHIVO DE B ==="
docker exec contenedor-a cat /tmp/archivo-b.txt 2>&1 || echo "No se puede acceder al archivo"

# ¿Puede contenedor-b ver el archivo de contenedor-a?
echo "=== CONTENEDOR B BUSCA ARCHIVO DE A ==="
docker exec contenedor-b cat /tmp/archivo-a.txt 2>&1 || echo "No se puede acceder al archivo"
```

### Paso 3: Volúmenes compartidos

```bash
# Crear contenedores con volumen compartido
docker run -d --name shared-a -v shared-volume:/data ubuntu:22.04 sleep 3600
docker run -d --name shared-b -v shared-volume:/data ubuntu:22.04 sleep 3600

# Crear archivo desde shared-a
docker exec shared-a bash -c "echo 'Archivo compartido' > /data/compartido.txt"

# Leer desde shared-b
docker exec shared-b cat /data/compartido.txt
```

### 🤔 **Pregunta de análisis:**
¿Cuándo es útil el aislamiento de archivos y cuándo necesitas compartir datos?

---

## 🧪 Ejercicio 4: Control de Recursos (Cgroups)

### Paso 1: Contenedores sin límites

```bash
# Ejecutar contenedor sin límites de memoria
docker run -d --name sin-limites nginx

# Ver uso de recursos
docker stats sin-limites --no-stream
```

### Paso 2: Contenedores con límites estrictos

```bash
# Contenedor con límite de 50MB RAM
docker run -d --name limitado-50mb --memory="50m" nginx

# Contenedor con límite de 100MB RAM  
docker run -d --name limitado-100mb --memory="100m" nginx

# Contenedor con límite de CPU
docker run -d --name limitado-cpu --cpus="0.5" nginx

# Comparar uso de recursos
docker stats --no-stream
```

### Paso 3: Probar los límites

```bash
# Intentar consumir más memoria de la permitida
docker run -it --memory="50m" ubuntu:22.04 bash

# Dentro del contenedor, instalar stress
apt update && apt install -y stress

# Intentar usar 100MB (debería fallar con límite de 50MB)
stress --vm 1 --vm-bytes 100M --timeout 10s

# Salir del contenedor
exit
```

### 🤔 **Pregunta de análisis:**
¿Cómo se compara la granularidad de recursos con las VMs del módulo anterior?

---

## 🧪 Ejercicio 5: Comparación Práctica VMs vs Contenedores

### Métricas a comparar:

```bash
# 1. Tiempo de arranque
echo "=== TIEMPO DE ARRANQUE CONTENEDOR ==="
time docker run --rm hello-world

# 2. Uso de memoria
echo "=== USO DE MEMORIA CONTENEDORES ==="
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"

# 3. Tamaño en disco
echo "=== TAMAÑO DE IMÁGENES ==="
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# 4. Cuántos contenedores podemos ejecutar
echo "=== PRUEBA DE DENSIDAD ==="
for i in {1..20}; do
  docker run -d --name test$i --memory="20m" nginx:alpine > /dev/null 2>&1
done

echo "Contenedores creados:"
docker ps --format "table {{.Names}}\t{{.Status}}"

# Ver recursos totales utilizados
docker stats --no-stream
```

### Comparación con VM del módulo anterior:

| Métrica | VM (Módulo 1) | Contenedores (Módulo 2) |
|---------|---------------|-------------------------|
| **Tiempo arranque** | ~2-5 minutos | ~2-5 segundos |
| **RAM mínima** | ~1GB | ~20MB |
| **Tamaño en disco** | ~20GB | ~100MB |
| **Densidad** | 1 VM por host | 20+ contenedores |
| **Aislamiento** | Hardware virtual | Namespaces |

---

## 📊 Análisis de Resultados

### **Preguntas de reflexión:**

1. **¿Cómo funciona el aislamiento de namespaces en la práctica?**

2. **¿Qué ventajas ves en la granularidad de recursos de contenedores?**

3. **¿En qué escenarios preferirías VMs sobre contenedores?**

4. **¿Cómo crees que Kubernetes mejora la gestión de contenedores?**

5. **¿Qué problemas de producción identificas con Docker standalone?**

---

## 🧹 Limpieza

```bash
# Detener y eliminar todos los contenedores de prueba
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# Eliminar volúmenes
docker volume rm shared-volume

# Eliminar red personalizada
docker network rm mi-red-prueba

# Limpiar sistema
docker system prune -f
```

---

## 📝 Entregables

1. **Screenshots** de:
   - Procesos aislados en diferentes contenedores
   - IPs diferentes de cada contenedor
   - Archivos aislados entre contenedores
   - Comparación de recursos VMs vs contenedores

2. **Respuestas** a las preguntas de análisis

3. **Comparación numérica** de métricas VMs vs contenedores

---

## 🔗 Conexión con Kubernetes

Con este ejercicio has visto cómo:

- ✅ Los contenedores están completamente aislados (base para Pods)
- ✅ Los recursos se pueden controlar granularmente (base para límites en K8s)
- ✅ La red se puede gestionar dinámicamente (base para Services en K8s)
- ✅ Los volúmenes se pueden compartir selectivamente (base para PVs en K8s)

**En el Área 2** verás cómo Kubernetes orquesta estos conceptos a escala empresarial.

**Tiempo estimado**: 30-45 minutos  
**Dificultad**: Intermedio