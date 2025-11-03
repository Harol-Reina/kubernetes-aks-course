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
docker exec contenedor-a which ps >/dev/null 2>&1 || docker exec contenedor-a apt update && docker exec contenedor-a apt install -y procps
docker exec contenedor-a ps aux

# Ver procesos en contenedor-b
echo "=== PROCESOS EN CONTENEDOR B ==="
docker exec contenedor-b which ps >/dev/null 2>&1 || docker exec contenedor-b apt update && docker exec contenedor-b apt install -y procps
docker exec contenedor-b ps aux

# Ver procesos en contenedor-c (nginx también necesita procps)
echo "=== PROCESOS EN CONTENEDOR C ==="
docker exec contenedor-c which ps >/dev/null 2>&1 || docker exec contenedor-c apt update && docker exec contenedor-c apt install -y procps
docker exec contenedor-c ps aux
```

### Paso 3: Analizar el aislamiento

```bash
# Desde el host - ver todos los procesos Docker
echo "=== PROCESOS EN EL HOST ==="
ps aux | grep -E "(docker|sleep|nginx)" | grep -v grep

# ¿Pueden verse entre contenedores?
echo "=== INTENTAR VER PROCESOS DE OTRO CONTENEDOR ==="
docker exec contenedor-a ps aux | grep nginx || echo "No se puede ver nginx desde contenedor-a (aislamiento correcto)"
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
docker exec contenedor-a which ip >/dev/null 2>&1 || docker exec contenedor-a apt update && docker exec contenedor-a apt install -y iproute2
docker exec contenedor-a ip addr show 2>/dev/null || docker exec contenedor-a cat /proc/net/dev

echo "=== RED VISTA DESDE CONTENEDOR B ==="
docker exec contenedor-b which ip >/dev/null 2>&1 || docker exec contenedor-b apt update && docker exec contenedor-b apt install -y iproute2
docker exec contenedor-b ip addr show 2>/dev/null || docker exec contenedor-b cat /proc/net/dev
```

### Paso 2: Probar conectividad entre contenedores

```bash
# Obtener IP del contenedor-c (nginx)
NGINX_IP=$(docker inspect contenedor-c | grep '"IPAddress"' | head -1 | cut -d '"' -f 4)
echo "IP de nginx: $NGINX_IP"

# Instalar curl en los contenedores Ubuntu (nginx también necesita curl)
echo "Instalando herramientas de red en contenedores Ubuntu..."
docker exec contenedor-a apt update && docker exec contenedor-a apt install -y curl
docker exec contenedor-b apt update && docker exec contenedor-b apt install -y curl

# Instalar curl en nginx también si no está disponible
docker exec contenedor-c which curl >/dev/null 2>&1 || docker exec contenedor-c apt update && docker exec contenedor-c apt install -y curl

# Desde contenedor-a, intentar conectar a nginx
echo "=== CONECTIVIDAD DESDE CONTENEDOR A ==="
docker exec contenedor-a curl -I http://$NGINX_IP

# Desde contenedor-b, intentar lo mismo
echo "=== CONECTIVIDAD DESDE CONTENEDOR B ==="
docker exec contenedor-b curl -I http://$NGINX_IP
```

### Paso 3: Crear red personalizada para probar conectividad

```bash
# Crear red personalizada
docker network create mi-red-prueba

# Ejecutar contenedores en la misma red
docker run -d --name web1 --network mi-red-prueba nginx
docker run -d --name web2 --network mi-red-prueba nginx

# Esperar que arranquen
sleep 5

# Probar conectividad por nombre (instalar curl en nginx si es necesario)
echo "=== CONECTIVIDAD POR NOMBRE EN RED PERSONALIZADA ==="
docker exec web1 which curl >/dev/null 2>&1 || docker exec web1 apt update && docker exec web1 apt install -y curl
docker exec web2 which curl >/dev/null 2>&1 || docker exec web2 apt update && docker exec web2 apt install -y curl
docker exec web1 curl -I http://web2 || echo "Conectividad fallida desde web1 a web2"
docker exec web2 curl -I http://web1 || echo "Conectividad fallida desde web2 a web1"
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
# Crear contenedor interactivo con límite de memoria
echo "=== CREANDO CONTENEDOR CON LÍMITE DE MEMORIA ==="
docker run -it --memory="50m" --name test-memory ubuntu:22.04 bash << 'EOF'

# Dentro del contenedor, instalar stress y herramientas
echo "Instalando herramientas de stress..."
apt update && apt install -y stress htop

echo "Información del sistema:"
cat /proc/meminfo | grep MemTotal

echo "Intentando usar 100MB (debería fallar con límite de 50MB)..."
stress --vm 1 --vm-bytes 100M --timeout 10s || echo "Stress test completado o falló por límites de memoria"

echo "Probando con 30MB (dentro del límite)..."
stress --vm 1 --vm-bytes 30M --timeout 5s && echo "Test de 30MB exitoso"

# Salir del contenedor
exit
EOF

# Verificar el contenedor desde el host
echo "=== ESTADÍSTICAS DEL CONTENEDOR CON LÍMITES ==="
docker stats test-memory --no-stream 2>/dev/null || echo "Contenedor ya terminó"

# Limpiar
docker rm test-memory 2>/dev/null || true
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

# 2. Uso de memoria de contenedores existentes
echo "=== USO DE MEMORIA CONTENEDORES ==="
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null || echo "No hay contenedores ejecutándose"

# 3. Tamaño en disco
echo "=== TAMAÑO DE IMÁGENES ==="
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# 4. Cuántos contenedores podemos ejecutar
echo "=== PRUEBA DE DENSIDAD ==="
echo "Creando 20 contenedores nginx ligeros..."

# Crear contenedores con manejo de errores
CREATED_COUNT=0
for i in {1..20}; do
  if docker run -d --name test$i --memory="20m" nginx:alpine > /dev/null 2>&1; then
    CREATED_COUNT=$((CREATED_COUNT + 1))
  else
    echo "Error creando contenedor test$i"
  fi
done

echo "Contenedores creados exitosamente: $CREATED_COUNT"
echo "Lista de contenedores:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep test

# Ver recursos totales utilizados
echo "=== RECURSOS UTILIZADOS ==="
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}" | head -10
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
echo "=== LIMPIANDO CONTENEDORES ==="
docker stop $(docker ps -aq) 2>/dev/null || echo "No hay contenedores ejecutándose"
docker rm $(docker ps -aq) 2>/dev/null || echo "No hay contenedores para eliminar"

# Eliminar volúmenes
echo "=== LIMPIANDO VOLÚMENES ==="
docker volume rm shared-volume 2>/dev/null || echo "Volumen shared-volume no existe"

# Eliminar red personalizada
echo "=== LIMPIANDO REDES ==="
docker network rm mi-red-prueba 2>/dev/null || echo "Red mi-red-prueba no existe"

# Limpiar sistema completo
echo "=== LIMPIEZA GENERAL ==="
docker system prune -f

# Verificar limpieza
echo "=== ESTADO FINAL ==="
echo "Contenedores restantes: $(docker ps -a --format '{{.Names}}' | wc -l)"
echo "Imágenes disponibles: $(docker images --format '{{.Repository}}:{{.Tag}}' | wc -l)"
echo "Redes personalizadas: $(docker network ls --filter type=custom --format '{{.Name}}' | wc -l)"
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