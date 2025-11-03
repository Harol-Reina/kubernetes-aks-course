# 💾 Lab M2.3: Volúmenes y Persistencia

**Duración**: 40 minutos  
**Dificultad**: Intermedio  
**Prerequisitos**: [Lab M2.2 completado](./imagenes-personalizadas-lab.md)

## 🎯 Objetivos

- Entender la persistencia de datos en contenedores
- Trabajar con bind mounts y volúmenes nombrados
- Implementar estrategias de backup y restauración
- Compartir datos entre contenedores

---

## 📋 Prerequisitos

```bash
# Verificar Docker funcionando
docker --version

# Limpiar entorno
docker system prune -f

# Crear directorio de trabajo
mkdir ~/docker-volumes-lab
cd ~/docker-volumes-lab
```

---

## 💭 Ejercicio 1: Entender el Problema de Persistencia

### **Paso 1: Contenedor sin persistencia**

```bash
# Crear contenedor con datos temporales
docker run -it --name temp-container ubuntu:22.04 bash

# Dentro del contenedor:
echo "Datos importantes" > /tmp/archivo.txt
echo "Configuración crítica" > /etc/mi-config.conf
ls -la /tmp/archivo.txt
exit
```

### **Paso 2: Verificar pérdida de datos**

```bash
# Eliminar contenedor
docker rm temp-container

# Crear nuevo contenedor con la misma imagen
docker run -it --name nuevo-container ubuntu:22.04 bash

# Dentro del contenedor:
ls -la /tmp/archivo.txt
# ¡El archivo no existe!
cat /etc/mi-config.conf
# ¡La configuración se perdió!
exit

# Limpiar
docker rm nuevo-container
```

### **Reflexión**: 
- ¿Qué implicaciones tiene esto para aplicaciones reales?
- ¿Cómo afecta esto a bases de datos, logs, configuraciones?

---

## 📁 Ejercicio 2: Bind Mounts - Mapeo Directo

### **Paso 1: Crear directorio en el host**

```bash
# Crear estructura de directorios
mkdir -p ~/docker-volumes-lab/datos
mkdir -p ~/docker-volumes-lab/config
mkdir -p ~/docker-volumes-lab/logs

# Crear archivos de prueba
echo "Configuración del host" > ~/docker-volumes-lab/config/app.conf
echo "<!DOCTYPE html><html><body><h1>Página desde host</h1></body></html>" > ~/docker-volumes-lab/datos/index.html
```

### **Paso 2: Usar bind mount con servidor web**

```bash
# Ejecutar Nginx con bind mount
docker run -d --name nginx-bind \
  -p 8080:80 \
  -v ~/docker-volumes-lab/datos:/usr/share/nginx/html \
  -v ~/docker-volumes-lab/logs:/var/log/nginx \
  nginx

# Verificar funcionamiento
curl http://localhost:8080
```

### **Paso 3: Modificar archivos desde el host**

```bash
# Modificar archivo desde el host
echo "<!DOCTYPE html><html><body><h1>Página actualizada desde el HOST</h1><p>Timestamp: $(date)</p></body></html>" > ~/docker-volumes-lab/datos/index.html

# Verificar cambios inmediatos
curl http://localhost:8080

# Ver logs generados
ls -la ~/docker-volumes-lab/logs/
tail ~/docker-volumes-lab/logs/access.log
```

### **Paso 4: Modificar desde dentro del contenedor**

```bash
# Acceder al contenedor
docker exec -it nginx-bind bash

# Dentro del contenedor:
echo "<h2>Archivo creado desde el contenedor</h2>" > /usr/share/nginx/html/desde-container.html
echo "Log desde contenedor: $(date)" >> /var/log/nginx/custom.log
exit

# Verificar cambios en el host
curl http://localhost:8080/desde-container.html
cat ~/docker-volumes-lab/logs/custom.log
```

---

## 🗂️ Ejercicio 3: Volúmenes Nombrados

### **Paso 1: Crear volúmenes nombrados**

```bash
# Crear volúmenes nombrados
docker volume create mi-volumen-datos
docker volume create mi-volumen-config
docker volume create mi-volumen-db

# Listar volúmenes
docker volume ls

# Inspeccionar volumen
docker volume inspect mi-volumen-datos
```

### **Paso 2: Base de datos con volumen persistente**

```bash
# Ejecutar PostgreSQL con volumen nombrado
docker run -d --name postgres-persistente \
  -e POSTGRES_PASSWORD=mi-password \
  -e POSTGRES_DB=mi-base-datos \
  -v mi-volumen-db:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15

# Esperar que arranque
sleep 10

# Verificar que está ejecutándose
docker ps | grep postgres
```

### **Paso 3: Agregar datos a la base**

```bash
# Conectar y crear datos
docker exec -it postgres-persistente psql -U postgres -d mi-base-datos

# Dentro de PostgreSQL:
# CREATE TABLE usuarios (id SERIAL PRIMARY KEY, nombre VARCHAR(100), email VARCHAR(100));
# INSERT INTO usuarios (nombre, email) VALUES ('Juan Pérez', 'juan@ejemplo.com');
# INSERT INTO usuarios (nombre, email) VALUES ('María García', 'maria@ejemplo.com');
# SELECT * FROM usuarios;
# \q

# Alternativa usando comando directo:
docker exec postgres-persistente psql -U postgres -d mi-base-datos -c "
CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY, 
  nombre VARCHAR(100), 
  email VARCHAR(100)
);
INSERT INTO usuarios (nombre, email) VALUES 
  ('Juan Pérez', 'juan@ejemplo.com'),
  ('María García', 'maria@ejemplo.com');
"
```

### **Paso 4: Verificar persistencia**

```bash
# Detener y eliminar contenedor
docker stop postgres-persistente
docker rm postgres-persistente

# Crear nuevo contenedor con el mismo volumen
docker run -d --name postgres-nuevo \
  -e POSTGRES_PASSWORD=mi-password \
  -e POSTGRES_DB=mi-base-datos \
  -v mi-volumen-db:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15

# Esperar arranque
sleep 10

# Verificar que los datos persisten
docker exec postgres-nuevo psql -U postgres -d mi-base-datos -c "SELECT * FROM usuarios;"

# ¡Los datos están ahí!
```

---

## 🔄 Ejercicio 4: Compartir Volúmenes entre Contenedores

### **Paso 1: Contenedor productor de datos**

```bash
# Crear aplicación que genera logs
docker run -d --name log-producer \
  -v mi-volumen-datos:/app/logs \
  ubuntu:22.04 \
  bash -c "
    while true; do
      echo \"[$(date)] Log desde productor: $$RANDOM\" >> /app/logs/app.log
      sleep 5
    done
  "
```

### **Paso 2: Contenedor consumidor de datos**

```bash
# Crear aplicación que lee logs
docker run -d --name log-consumer \
  -v mi-volumen-datos:/app/logs:ro \
  ubuntu:22.04 \
  bash -c "
    while true; do
      echo \"=== Últimas 5 líneas de logs ===\" > /tmp/resumen.txt
      tail -5 /app/logs/app.log >> /tmp/resumen.txt
      cat /tmp/resumen.txt
      sleep 10
    done
  "

# Nota: :ro significa read-only
```

### **Paso 3: Monitorear ambos contenedores**

```bash
# Ver logs del productor
docker logs -f log-producer &

# Ver logs del consumidor
docker logs -f log-consumer &

# Matar procesos en background después de un momento
# Ctrl+C para detener
```

### **Paso 4: Verificar archivos compartidos**

```bash
# Verificar contenido del volumen desde otro contenedor
docker run --rm -v mi-volumen-datos:/data ubuntu:22.04 cat /data/app.log

# Ver últimas líneas
docker run --rm -v mi-volumen-datos:/data ubuntu:22.04 tail -10 /data/app.log
```

---

## 💿 Ejercicio 5: Backup y Restauración

### **Paso 1: Crear datos de prueba**

```bash
# Crear contenedor con datos importantes
docker run -d --name app-importante \
  -v mi-volumen-config:/app/config \
  ubuntu:22.04 \
  bash -c "
    echo 'usuario=admin' > /app/config/database.conf
    echo 'password=secreto123' >> /app/config/database.conf
    echo 'host=localhost' >> /app/config/database.conf
    echo 'puerto=5432' >> /app/config/database.conf
    echo '{\"configuracion\": {\"debug\": false, \"version\": \"1.0\"}}' > /app/config/app.json
    while true; do sleep 30; done
  "
```

### **Paso 2: Realizar backup del volumen**

```bash
# Crear backup usando tar
docker run --rm \
  -v mi-volumen-config:/backup-source \
  -v ~/docker-volumes-lab:/backup-destination \
  ubuntu:22.04 \
  tar czf /backup-destination/config-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /backup-source .

# Verificar backup creado
ls -la ~/docker-volumes-lab/config-backup-*.tar.gz
```

### **Paso 3: Simular pérdida de datos**

```bash
# Eliminar datos del volumen
docker run --rm -v mi-volumen-config:/data ubuntu:22.04 rm -rf /data/*

# Verificar que se perdieron los datos
docker exec app-importante ls -la /app/config/
# Debería estar vacío
```

### **Paso 4: Restaurar desde backup**

```bash
# Encontrar el archivo de backup más reciente
BACKUP_FILE=$(ls -t ~/docker-volumes-lab/config-backup-*.tar.gz | head -1)
echo "Restaurando desde: $BACKUP_FILE"

# Restaurar datos
docker run --rm \
  -v mi-volumen-config:/restore-destination \
  -v ~/docker-volumes-lab:/backup-source \
  ubuntu:22.04 \
  tar xzf /backup-source/$(basename $BACKUP_FILE) -C /restore-destination

# Verificar restauración
docker exec app-importante ls -la /app/config/
docker exec app-importante cat /app/config/database.conf
```

---

## 🔍 Ejercicio 6: Inspección y Debugging

### **Paso 1: Información de volúmenes**

```bash
# Ver todos los volúmenes
docker volume ls

# Información detallada de un volumen
docker volume inspect mi-volumen-db

# Ver qué contenedores usan un volumen
docker ps -a --filter volume=mi-volumen-datos
```

### **Paso 2: Acceder directamente a volúmenes**

```bash
# Encontrar ubicación física del volumen
VOLUME_PATH=$(docker volume inspect mi-volumen-datos | jq -r '.[0].Mountpoint')
echo "Volumen ubicado en: $VOLUME_PATH"

# Acceder como root (si es necesario)
sudo ls -la $VOLUME_PATH

# Contenedor temporal para inspeccionar
docker run -it --rm -v mi-volumen-datos:/inspect ubuntu:22.04 bash
# Dentro del contenedor: ls -la /inspect/
```

### **Paso 3: Estadísticas de uso**

```bash
# Tamaño de volúmenes
docker system df

# Información detallada
docker system df -v

# Uso específico de un volumen
docker run --rm -v mi-volumen-db:/data ubuntu:22.04 du -sh /data
```

---

## 🧪 Ejercicio 7: Casos de Uso Avanzados

### **Paso 1: Crear aplicación backend**

```bash
# Crear directorio para la aplicación backend
mkdir -p ~/docker-volumes-lab/backend-app

# Crear una simple aplicación Node.js
cat << 'EOF' > ~/docker-volumes-lab/backend-app/package.json
{
  "name": "simple-backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

cat << 'EOF' > ~/docker-volumes-lab/backend-app/server.js
const express = require('express');
const app = express();
const port = 3000;

// Middleware para logs
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Rutas de API
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'Backend API'
  });
});

app.get('/api/users', (req, res) => {
  res.json([
    { id: 1, name: 'Juan Pérez', email: 'juan@ejemplo.com' },
    { id: 2, name: 'María García', email: 'maria@ejemplo.com' },
    { id: 3, name: 'Carlos López', email: 'carlos@ejemplo.com' }
  ]);
});

app.get('/api/info', (req, res) => {
  res.json({
    message: 'API funcionando correctamente',
    version: '1.0.0',
    environment: 'docker',
    timestamp: new Date().toISOString()
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Backend API ejecutándose en puerto ${port}`);
});
EOF

# Crear Dockerfile para el backend
cat << 'EOF' > ~/docker-volumes-lab/backend-app/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY server.js .
EXPOSE 3000
CMD ["node", "server.js"]
EOF
```

### **Paso 2: Construir y ejecutar el backend**

```bash
# Construir imagen del backend
cd ~/docker-volumes-lab/backend-app
docker build -t mi-backend:1.0 .

# Crear red personalizada para comunicación entre contenedores
docker network create app-network

# Ejecutar el backend en la red personalizada
docker run -d --name backend \
  --network app-network \
  -v ~/docker-volumes-lab/logs-centralizados:/var/log/apps \
  mi-backend:1.0

# Verificar que el backend está funcionando
sleep 5
docker logs backend
```

### **Paso 3: Configuración de Nginx con proxy**

```bash
# Volver al directorio principal
cd ~/docker-volumes-lab

# Crear configuración dinámica para Nginx
mkdir -p ~/docker-volumes-lab/config-dinamica

cat << 'EOF' > ~/docker-volumes-lab/config-dinamica/nginx.conf
events {
    worker_connections 1024;
}

http {
    # Configuración básica
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Formato de logs
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    server {
        listen 80;
        server_name localhost;
        
        # Logs
        access_log /var/log/nginx/access.log main;
        error_log  /var/log/nginx/error.log;

        # Servir archivos estáticos
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ =404;
        }
        
        # Proxy para API backend
        location /api/ {
            proxy_pass http://backend:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeouts
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }
        
        # Página de estado
        location /status {
            return 200 "Nginx funcionando correctamente\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Crear página web mejorada
mkdir ~/docker-volumes-lab/datos
cat << 'EOF' > ~/docker-volumes-lab/datos/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aplicación Full Stack con Docker</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 20px; margin-bottom: 30px; }
        .section { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        button { background-color: #4CAF50; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin: 5px; }
        button:hover { background-color: #45a049; }
        #resultado { background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-top: 10px; white-space: pre-wrap; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🐳 Aplicación Full Stack con Docker</h1>
            <p class="timestamp">Última actualización: <span id="timestamp"></span></p>
        </div>
        
        <div class="section">
            <h2>🌐 Frontend (Nginx)</h2>
            <p>Esta página es servida por Nginx usando volúmenes de Docker</p>
            <button onclick="checkStatus()">🔍 Verificar Estado del Servidor</button>
        </div>
        
        <div class="section">
            <h2>🔧 Backend API (Node.js)</h2>
            <p>El backend está ejecutándose en un contenedor separado</p>
            <button onclick="testAPI('/api/health')">💓 Health Check</button>
            <button onclick="testAPI('/api/users')">👥 Obtener Usuarios</button>
            <button onclick="testAPI('/api/info')">ℹ️ Información del Sistema</button>
        </div>
        
        <div class="section">
            <h3>📋 Resultado:</h3>
            <div id="resultado">Haz clic en algún botón para probar la API...</div>
        </div>
    </div>

    <script>
        // Actualizar timestamp
        document.getElementById('timestamp').textContent = new Date().toLocaleString();
        
        // Función para probar API
        async function testAPI(endpoint) {
            const resultado = document.getElementById('resultado');
            resultado.textContent = 'Cargando...';
            
            try {
                const response = await fetch(endpoint);
                const data = await response.json();
                resultado.textContent = 
                    `✅ Éxito!\n\n` +
                    `Endpoint: ${endpoint}\n` +
                    `Status: ${response.status}\n` +
                    `Respuesta:\n${JSON.stringify(data, null, 2)}`;
            } catch (error) {
                resultado.textContent = 
                    `❌ Error!\n\n` +
                    `Endpoint: ${endpoint}\n` +
                    `Error: ${error.message}`;
            }
        }
        
        // Función para verificar estado
        async function checkStatus() {
            const resultado = document.getElementById('resultado');
            resultado.textContent = 'Verificando estado del servidor...';
            
            try {
                const response = await fetch('/status');
                const text = await response.text();
                resultado.textContent = 
                    `✅ Estado del Servidor!\n\n` +
                    `Status: ${response.status}\n` +
                    `Respuesta: ${text}`;
            } catch (error) {
                resultado.textContent = 
                    `❌ Error de servidor!\n\n` +
                    `Error: ${error.message}`;
            }
        }
    </script>
</body>
</html>
EOF
```

### **Paso 4: Ejecutar Nginx con proxy configurado**

```bash
# Ejecutar Nginx en la misma red que el backend
docker run -d --name nginx-proxy \
  --network app-network \
  -p 8081:80 \
  -v ~/docker-volumes-lab/config-dinamica/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v ~/docker-volumes-lab/datos:/usr/share/nginx/html \
  -v ~/docker-volumes-lab/logs-centralizados:/var/log/nginx \
  nginx

# Esperar a que arranque
sleep 5

# Verificar que ambos contenedores están ejecutándose
docker ps | grep -E "(nginx-proxy|backend)"
```

### **Paso 5: Probar la aplicación completa**

```bash
# Probar el frontend
echo "🌐 Probando frontend:"
curl -s http://localhost:8081 | grep -o '<title>.*</title>'

# Probar el proxy hacia el backend
echo -e "\n🔧 Probando backend a través del proxy:"
curl -s http://localhost:8081/api/health | jq .

echo -e "\n👥 Probando endpoint de usuarios:"
curl -s http://localhost:8081/api/users | jq .

echo -e "\n📊 Probando endpoint de información:"
curl -s http://localhost:8081/api/info | jq .

echo -e "\n🔍 Probando estado del servidor:"
curl -s http://localhost:8081/status

# Abrir en navegador (opcional)
echo -e "\n🌍 Abre http://localhost:8081 en tu navegador para probar la interfaz completa"
```

### **Paso 2: Logs centralizados**

```bash
# Crear directorio para logs centralizados
mkdir -p ~/docker-volumes-lab/logs-centralizados

# Múltiples servicios enviando logs al mismo lugar
docker run -d --name servicio1 \
  -v ~/docker-volumes-lab/logs-centralizados:/var/log/apps \
  ubuntu:22.04 \
  bash -c "while true; do echo \"[SERVICIO1] $(date): Evento importante\" >> /var/log/apps/servicio1.log; sleep 15; done"

docker run -d --name servicio2 \
  -v ~/docker-volumes-lab/logs-centralizados:/var/log/apps \
  ubuntu:22.04 \
  bash -c "while true; do echo \"[SERVICIO2] $(date): Procesando datos\" >> /var/log/apps/servicio2.log; sleep 20; done"

# Monitorear logs centralizados
tail -f ~/docker-volumes-lab/logs-centralizados/*.log
```

---

## 🧹 Ejercicio 8: Limpieza y Gestión

### **Paso 1: Identificar volúmenes no utilizados**

```bash
# Ver volúmenes huérfanos
docker volume ls -f dangling=true

# Crear volumen no utilizado para prueba
docker volume create volumen-huerfano

# Ver nuevamente
docker volume ls -f dangling=true
```

### **Paso 2: Limpiar volúmenes**

```bash
# Detener todos los contenedores
docker stop $(docker ps -q)

# Eliminar contenedores
docker rm $(docker ps -aq)

# Eliminar volúmenes no utilizados
docker volume prune

# Eliminar volumen específico
docker volume rm volumen-huerfano

# Verificar limpieza
docker volume ls
```

---

## 📋 Verificación de Aprendizaje

### **Comandos que debes dominar:**

```bash
# Volúmenes
docker volume create nombre
docker volume ls
docker volume inspect nombre
docker volume rm nombre
docker volume prune

# Bind mounts
docker run -v /host/path:/container/path imagen

# Volúmenes nombrados
docker run -v volumen-name:/container/path imagen

# Backup/Restore
docker run --rm -v vol:/source -v /backup:/dest ubuntu tar czf /dest/backup.tar.gz -C /source .
```

### **Conceptos clave:**

1. **Bind Mounts**: Mapeo directo host ↔ contenedor
2. **Volúmenes Nombrados**: Gestionados por Docker
3. **Persistencia**: Los datos sobreviven al contenedor
4. **Compartir**: Múltiples contenedores pueden usar el mismo volumen

---

## 🎓 Resultado Esperado

Al completar este laboratorio, deberías poder:

- ✅ Configurar persistencia de datos efectiva
- ✅ Elegir entre bind mounts y volúmenes nombrados
- ✅ Compartir datos entre contenedores
- ✅ Realizar backup y restauración de volúmenes
- ✅ Gestionar el ciclo de vida de volúmenes
- ✅ Debugging de problemas de persistencia

---

## 🚀 Siguiente Paso

**[Lab M2.4: Redes en Docker](./redes-docker-lab.md)**

---

## 🔧 Troubleshooting

### **Error: "mount point does not exist"**
```bash
# Crear directorio si no existe
mkdir -p /ruta/del/host
```

### **Error: "permission denied"**
```bash
# Verificar permisos del directorio
ls -la /ruta/del/padre/
# Cambiar propietario si es necesario
sudo chown $USER:$USER /ruta/del/directorio
```

### **Volumen no se monta**
```bash
# Verificar sintaxis del comando
docker run -v /absoluta/host/path:/container/path imagen
# No usar rutas relativas para bind mounts
```

### **Datos no persisten**
```bash
# Verificar que el volumen está montado
docker inspect contenedor | jq '.[0].Mounts'
```