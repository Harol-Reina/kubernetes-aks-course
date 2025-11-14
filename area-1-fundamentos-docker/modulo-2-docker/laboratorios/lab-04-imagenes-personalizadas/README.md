# 🛠️ Lab M2.2: Imágenes Personalizadas

**Duración**: 45 minutos  
**Dificultad**: Intermedio  
**Prerequisitos**: [Lab M2.1 completado](./primer-contenedor-lab.md)

## 🎯 Objetivos

- Crear Dockerfiles para imágenes personalizadas
- Entender las capas y el caché de Docker
- Implementar mejores prácticas de construcción
- Trabajar con registros de imágenes

---

## 📋 Prerequisitos

```bash
# Verificar Docker funcionando
docker run hello-world

# Limpiar entorno anterior
docker system prune -f
```

---

## 🏗️ Ejercicio 1: Primera Imagen Personalizada

### **Paso 1: Crear aplicación simple**

```bash
# Crear directorio de trabajo
mkdir ~/docker-lab-m2-2
cd ~/docker-lab-m2-2

# Crear aplicación Python simple
cat << 'EOF' > app.py
from flask import Flask
import os
import socket

app = Flask(__name__)

@app.route('/')
def hello():
    hostname = socket.gethostname()
    version = os.environ.get('APP_VERSION', '1.0')
    return f'''
    <h1>¡Hola desde Docker!</h1>
    <p>Hostname: {hostname}</p>
    <p>Versión: {version}</p>
    <p>Esta es mi primera imagen personalizada 🐳</p>
    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Crear archivo de dependencias
cat << 'EOF' > requirements.txt
Flask==2.3.3
Werkzeug==2.3.7
EOF
```

### **Paso 2: Crear primer Dockerfile**

```bash
cat << 'EOF' > Dockerfile
# Imagen base
FROM python:3.11-slim

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY requirements.txt .

# Instalar dependencias
RUN pip install -r requirements.txt

# Copiar código de aplicación
COPY app.py .

# Exponer puerto
EXPOSE 5000

# Comando por defecto
CMD ["python", "app.py"]
EOF
```

### **Paso 3: Construir la imagen**

```bash
# Construir imagen
docker build -t mi-flask-app:v1.0 .

# Ver el proceso capa por capa
# Observar cómo se cachean las capas

# Listar imágenes
docker images | grep mi-flask-app
```

### **Paso 4: Ejecutar contenedor**

```bash
# Ejecutar aplicación
docker run -d --name flask-app -p 5000:5000 mi-flask-app:v1.0

# Probar aplicación
curl http://localhost:5000

# Ver desde navegador
# http://localhost:5000
```

---

## 🔧 Ejercicio 2: Optimización de Imágenes

### **Paso 1: Dockerfile mejorado**

```bash
cat << 'EOF' > Dockerfile.optimized
# Usar imagen base más específica
FROM python:3.11-slim-bullseye

# Metadatos de la imagen
LABEL maintainer="tu-email@ejemplo.com"
LABEL version="1.0"
LABEL description="Aplicación Flask personalizada"

# Crear usuario no-root
RUN useradd --create-home --shell /bin/bash appuser

# Establecer directorio de trabajo
WORKDIR /app

# Copiar y instalar dependencias primero (mejor caché)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código de aplicación
COPY app.py .

# Cambiar propietario de archivos
RUN chown -R appuser:appuser /app

# Cambiar a usuario no-root
USER appuser

# Variables de entorno
ENV APP_VERSION=1.1
ENV FLASK_ENV=production

# Exponer puerto
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/ || exit 1

# Comando por defecto
CMD ["python", "app.py"]
EOF
```

### **Paso 2: Construir imagen optimizada**

```bash
# Construir nueva versión
docker build -f Dockerfile.optimized -t mi-flask-app:v1.1 .

# Comparar tamaños de imágenes
docker images | grep mi-flask-app

# Ejecutar nueva versión
docker run -d --name flask-app-v11 -p 5001:5000 mi-flask-app:v1.1

# Probar funcionamiento
curl http://localhost:5001
```

### **Paso 3: Análisis de capas**

```bash
# Ver historial de capas
docker history mi-flask-app:v1.0
docker history mi-flask-app:v1.1

# Inspeccionar imagen
docker inspect mi-flask-app:v1.1

# Ver configuración de healthcheck
docker ps
# La columna STATUS mostrará el estado de salud
```

---

## 🏗️ Ejercicio 3: Multi-stage Builds

### **Paso 1: Aplicación más compleja**

```bash
# Crear aplicación con compilación
cat << 'EOF' > Dockerfile.multistage
# Etapa de construcción
FROM node:18-alpine AS builder

WORKDIR /app

# Crear package.json
COPY << 'PACKAGE' package.json
{
  "name": "mi-app-node",
  "version": "1.0.0",
  "scripts": {
    "build": "echo 'Building app...' && mkdir -p dist && echo 'console.log(\"App built!\");' > dist/app.js"
  },
  "dependencies": {}
}
PACKAGE

# Instalar dependencias de build (simulado)
RUN npm install

# Simular proceso de build
RUN npm run build

# Etapa de producción
FROM node:18-alpine AS production

WORKDIR /app

# Copiar solo los archivos necesarios desde builder
COPY --from=builder /app/dist ./dist

# Usuario no-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S appuser -u 1001

USER appuser

EXPOSE 3000

CMD ["node", "dist/app.js"]
EOF
```

### **Paso 2: Construir imagen multi-stage**

```bash
# Construir imagen multi-stage
docker build -f Dockerfile.multistage -t mi-node-app:multistage .

# Comparar tamaño con imagen de desarrollo
docker build --target builder -f Dockerfile.multistage -t mi-node-app:dev .

# Ver diferencias de tamaño
docker images | grep mi-node-app

# La imagen de producción debe ser mucho más pequeña
```

---

## 🐍 Ejercicio 4: Imagen Python Avanzada

### **Paso 1: Aplicación con dependencias del sistema**

```bash
# Crear nueva aplicación
mkdir flask-advanced
cd flask-advanced

cat << 'EOF' > app.py
from flask import Flask, jsonify
import psutil
import json
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        'mensaje': 'API de monitoreo del sistema',
        'timestamp': datetime.now().isoformat(),
        'version': '2.0'
    })

@app.route('/stats')
def stats():
    return jsonify({
        'cpu_percent': psutil.cpu_percent(interval=1),
        'memory': {
            'total': psutil.virtual_memory().total,
            'available': psutil.virtual_memory().available,
            'percent': psutil.virtual_memory().percent
        },
        'disk': {
            'total': psutil.disk_usage('/').total,
            'free': psutil.disk_usage('/').free,
            'percent': psutil.disk_usage('/').percent
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

cat << 'EOF' > requirements.txt
Flask==2.3.3
psutil==5.9.5
EOF

# Dockerfile avanzado
cat << 'EOF' > Dockerfile
FROM python:3.11-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# Instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar aplicación
COPY app.py .

# Cambiar propietario
RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:5000/ || exit 1

CMD ["python", "app.py"]
EOF
```

### **Paso 2: Construir y probar**

```bash
# Construir imagen
docker build -t flask-monitoring:v2.0 .

# Ejecutar contenedor
docker run -d --name monitoring -p 5002:5000 flask-monitoring:v2.0

# Probar endpoints
curl http://localhost:5002/
curl http://localhost:5002/stats | jq

# Ver información del sistema del contenedor
```

---

## 🏷️ Ejercicio 5: Etiquetado y Versioning

### **Paso 1: Sistema de etiquetas**

```bash
# Volver al directorio principal
cd ~/docker-lab-m2-2

# Construir con múltiples tags
docker build -t mi-flask-app:latest .
docker build -t mi-flask-app:v1.2 .
docker build -t mi-flask-app:stable .

# Ver todas las versiones
docker images | grep mi-flask-app

# Etiquetar imagen existente
docker tag mi-flask-app:v1.1 mi-flask-app:backup
```

### **Paso 2: Información de imagen**

```bash
# Ver información detallada
docker inspect mi-flask-app:latest

# Ver solo labels
docker inspect mi-flask-app:latest | jq '.[0].Config.Labels'

# Ver variables de entorno
docker inspect mi-flask-app:latest | jq '.[0].Config.Env'
```

---

## 📤 Ejercicio 6: Trabajar con Registry Local

### **Paso 1: Registry local**

```bash
# Ejecutar registry local
docker run -d -p 5000:5000 --name registry registry:2

# Verificar que está ejecutándose
curl http://localhost:5000/v2/
```

### **Paso 2: Subir imagen al registry**

```bash
# Etiquetar para registry local
docker tag mi-flask-app:latest localhost:5000/mi-flask-app:latest

# Subir imagen
docker push localhost:5000/mi-flask-app:latest

# Verificar en registry
curl http://localhost:5000/v2/_catalog
curl http://localhost:5000/v2/mi-flask-app/tags/list
```

### **Paso 3: Descargar imagen**

```bash
# Eliminar imagen local
docker rmi localhost:5000/mi-flask-app:latest
docker rmi mi-flask-app:latest

# Descargar desde registry
docker pull localhost:5000/mi-flask-app:latest

# Ejecutar imagen descargada
docker run -d --name test-registry -p 5003:5000 localhost:5000/mi-flask-app:latest

# Verificar funcionamiento
curl http://localhost:5003/
```

---

## 🧪 Ejercicio 7: .dockerignore y Optimización

### **Paso 1: Crear archivos innecesarios**

```bash
# Crear archivos que no queremos en la imagen
echo "Archivo temporal" > temp.txt
echo "Logs locales" > debug.log
mkdir node_modules
echo "Dependencias locales" > node_modules/package.txt

# Crear archivos README
echo "# Documentación local" > README.md
```

### **Paso 2: Crear .dockerignore**

```bash
cat << 'EOF' > .dockerignore
# Archivos temporales
*.tmp
*.log
temp.txt

# Directorios de dependencias
node_modules/
__pycache__/
*.pyc

# Documentación
README.md
*.md

# Control de versiones
.git/
.gitignore

# IDEs
.vscode/
.idea/

# Archivos del sistema
.DS_Store
Thumbs.db
EOF
```

### **Paso 3: Comparar builds**

```bash
# Build sin .dockerignore (renombrar temporalmente)
mv .dockerignore .dockerignore.bak
docker build -t mi-flask-app:sin-ignore .

# Build con .dockerignore
mv .dockerignore.bak .dockerignore
docker build -t mi-flask-app:con-ignore .

# Comparar tamaños
docker images | grep mi-flask-app

# Ver qué archivos se incluyeron
docker run --rm mi-flask-app:sin-ignore ls -la
docker run --rm mi-flask-app:con-ignore ls -la
```

---

## 📋 Verificación de Aprendizaje

### **Comandos que debes dominar:**

```bash
# Construcción
docker build -t nombre:tag .
docker build -f Dockerfile.custom .

# Etiquetado
docker tag imagen:tag nuevo-nombre:tag

# Registry
docker push registro/imagen:tag
docker pull registro/imagen:tag

# Inspección
docker history imagen
docker inspect imagen
```

### **Conceptos clave:**

1. **Capas de Docker**: Cada instrucción en Dockerfile crea una capa
2. **Caché de construcción**: Docker reutiliza capas si no cambian
3. **Multi-stage builds**: Reducen tamaño final de imagen
4. **Dockerignore**: Excluye archivos innecesarios del contexto

---

## 🧹 Limpieza

```bash
# Detener todos los contenedores
docker stop $(docker ps -q)

# Eliminar contenedores
docker rm $(docker ps -aq)

# Eliminar imágenes de prueba
docker rmi mi-flask-app:v1.0 mi-flask-app:v1.1
docker rmi mi-node-app:multistage mi-node-app:dev
docker rmi flask-monitoring:v2.0

# Limpiar sistema
docker system prune -f
```

---

## 🎓 Resultado Esperado

Al completar este laboratorio, deberías poder:

- ✅ Crear Dockerfiles optimizados
- ✅ Implementar multi-stage builds
- ✅ Usar .dockerignore efectivamente
- ✅ Gestionar etiquetas y versiones
- ✅ Trabajar con registries locales
- ✅ Optimizar tamaño de imágenes

---

## 🚀 Siguiente Paso

**[Lab M2.3: Volúmenes y Persistencia](./volumenes-persistencia-lab.md)**

---

## 🔧 Troubleshooting

### **Error: "COPY failed"**
- Verificar que los archivos existen
- Revisar .dockerignore
- Usar paths relativos al contexto

### **Imagen muy grande**
- Usar imágenes base slim/alpine
- Implementar multi-stage builds
- Limpiar caché de paquetes

### **Registry connection refused**
```bash
# Verificar registry ejecutándose
docker ps | grep registry
# Reiniciar si es necesario
docker restart registry
```