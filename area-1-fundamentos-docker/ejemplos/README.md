# 📦 Ejemplos de Dockerización

Ejemplos prácticos de aplicaciones dockerizadas para el curso de Kubernetes.

---

## 📁 Contenido

### 1. Aplicación Node.js Dockerizada

**Archivos:**
- `Dockerfile.nodejs` - Dockerfile optimizado con mejores prácticas
- `package.json` - Dependencias de la aplicación
- `server.js` - Servidor Express.js simple
- `docker-compose.yml` - Orquestación multi-servicio

**Características del Dockerfile:**
- ✅ Imagen base Alpine (ligera)
- ✅ Usuario no-root para seguridad
- ✅ Health check integrado
- ✅ Multi-stage build ready
- ✅ Variables de entorno configurables
- ✅ Cache de npm optimizado

---

## 🚀 Uso Rápido

### Opción 1: Ejecutar con Docker

```bash
# Navegar a la carpeta de ejemplos
cd /media/Data/Source/Courses/K8S/area-1-fundamentos-docker/ejemplos

# Construir la imagen
docker build -f Dockerfile.nodejs -t ejemplo-nodejs:1.0 .

# Ejecutar el contenedor
docker run -d -p 3000:3000 --name mi-app ejemplo-nodejs:1.0

# Verificar que funciona
curl http://localhost:3000

# Ver logs
docker logs -f mi-app

# Detener y eliminar
docker stop mi-app
docker rm mi-app
```

### Opción 2: Ejecutar con Docker Compose

```bash
# Levantar toda la aplicación
docker compose up -d

# Ver logs
docker compose logs -f

# Detener
docker compose down
```

---

## 🧪 Probar la Aplicación

### Endpoints disponibles:

```bash
# Mensaje de bienvenida
curl http://localhost:3000/

# Health check (usado por Docker)
curl http://localhost:3000/health

# Información del sistema
curl http://localhost:3000/info

# Ejemplo con parámetros
curl http://localhost:3000/api/users/123
```

**Respuesta esperada del endpoint principal:**
```json
{
  "message": "¡Hola desde Docker! 🐳",
  "application": "Ejemplo Node.js dockerizado",
  "version": "1.0.0",
  "environment": "production",
  "timestamp": "2025-11-09T..."
}
```

---

## 🔍 Explorar el Contenedor

```bash
# Ejecutar bash dentro del contenedor
docker exec -it mi-app sh

# Dentro del contenedor:
whoami                  # Debería mostrar 'appuser'
pwd                     # /app
ls -la                  # Ver archivos de la aplicación
ps aux                  # Ver procesos
cat /etc/os-release    # Ver información del SO Alpine
exit
```

---

## 🛠️ Mejores Prácticas Implementadas

### Seguridad
- ✅ Usuario no-root (`appuser`)
- ✅ Imagen Alpine (superficie de ataque reducida)
- ✅ Dependencias de producción únicamente
- ✅ Health checks para monitoreo

### Optimización
- ✅ Cache de capas Docker optimizado
- ✅ `.dockerignore` para excluir archivos innecesarios
- ✅ `npm ci` en lugar de `npm install`
- ✅ Limpieza de cache de npm

### Operaciones
- ✅ Logs estructurados con timestamps
- ✅ Manejo de señales SIGTERM/SIGINT
- ✅ Health check endpoint
- ✅ Variables de entorno configurables

---

## 📝 Modificar y Personalizar

### Cambiar el puerto:

```bash
docker run -d -p 8080:3000 -e PORT=3000 --name mi-app ejemplo-nodejs:1.0
```

### Cambiar entorno:

```bash
docker run -d -p 3000:3000 -e NODE_ENV=development --name mi-app ejemplo-nodejs:1.0
```

### Agregar volumen para desarrollo:

```bash
docker run -d -p 3000:3000 -v $(pwd):/app --name mi-app ejemplo-nodejs:1.0
```

---

## 🐳 Docker Compose

El archivo `docker-compose.yml` incluye una configuración completa con:
- Aplicación Node.js
- Health checks
- Redes personalizadas
- Límites de recursos
- Restart policies

---

## 📚 Conceptos Aplicados

Este ejemplo demuestra:

1. **Dockerfile multi-capa** - Optimización de cache
2. **Seguridad** - Usuario no-root
3. **Health checks** - Monitoreo de disponibilidad
4. **Variables de entorno** - Configuración flexible
5. **Logging** - Salida estructurada
6. **Graceful shutdown** - Manejo de señales
7. **Express.js** - Framework web moderno

---

## 🔗 Próximos Pasos

Estos ejemplos son la base para:
- Desplegar en Kubernetes (Área 2)
- Implementar CI/CD pipelines
- Configurar monitoring y observabilidad
- Escalar horizontalmente con orquestación

---

**✍️ Creado para**: Curso Kubernetes AKS  
**📅 Última actualización**: Noviembre 2025  
**📌 Nivel**: Básico-Intermedio
