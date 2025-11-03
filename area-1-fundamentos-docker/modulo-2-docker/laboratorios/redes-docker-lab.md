# 🌐 Lab M2.4: Redes en Docker

**Duración**: 50 minutos  
**Dificultad**: Intermedio-Avanzado  
**Prerequisitos**: [Lab M2.3 completado](./volumenes-persistencia-lab.md)

## 🎯 Objetivos

- Comprender los diferentes tipos de redes en Docker
- Configurar comunicación entre contenedores
- Implementar aislamiento de red y seguridad
- Trabajar con redes personalizadas

---

## 📋 Prerequisitos

```bash
# Verificar Docker funcionando
docker --version

# Limpiar entorno
docker system prune -f

# Crear directorio de trabajo
mkdir ~/docker-networks-lab
cd ~/docker-networks-lab
```

---

## 🔍 Ejercicio 1: Explorar Redes por Defecto

### **Paso 1: Investigar redes existentes**

```bash
# Listar redes de Docker
docker network ls

# Inspeccionar red bridge por defecto
docker network inspect bridge

# Ver configuración de red del host
ip addr show docker0
```

### **Paso 2: Contenedor en red por defecto**

```bash
# Ejecutar contenedor sin configuración de red
docker run -d --name web-default nginx

# Inspeccionar configuración de red
docker inspect web-default | jq '.[0].NetworkSettings'

# Ver IP asignada
docker inspect web-default | jq -r '.[0].NetworkSettings.IPAddress'

# Probar conectividad desde el host
WEB_IP=$(docker inspect web-default | jq -r '.[0].NetworkSettings.IPAddress')
curl http://$WEB_IP
```

### **Paso 3: Comunicación entre contenedores en red default**

```bash
# Crear segundo contenedor
docker run -d --name client-default ubuntu:22.04 sleep 3600

# Instalar herramientas de red necesarias
docker exec client-default apt update
docker exec client-default apt install -y iputils-ping curl dnsutils

# Probar conectividad por IP
docker exec client-default ping -c 3 $WEB_IP

# ¿Funciona la resolución de nombres?
docker exec client-default ping -c 3 web-default
# Esto fallará en la red bridge por defecto

# Alternativa usando curl si ping falla
echo "Probando conectividad HTTP:"
docker exec client-default curl -s http://$WEB_IP | head -n 5
```

---

## 🏗️ Ejercicio 2: Redes Personalizadas

### **Paso 1: Crear red personalizada**

```bash
# Crear red bridge personalizada
docker network create mi-red-app

# Inspeccionar la nueva red
docker network inspect mi-red-app

# Ver configuración de subred
docker network inspect mi-red-app | jq '.[0].IPAM.Config'
```

### **Paso 2: Contenedores en red personalizada**

```bash
# Crear contenedores en la red personalizada
docker run -d --name web-custom --network mi-red-app nginx
docker run -d --name client-custom --network mi-red-app ubuntu:22.04 sleep 3600

# Instalar herramientas necesarias en el cliente
docker exec client-custom apt update
docker exec client-custom apt install -y iputils-ping curl dnsutils

# Verificar conectividad por nombre
docker exec client-custom ping -c 3 web-custom
# ¡Ahora funciona la resolución DNS!

# Verificar conectividad HTTP
docker exec client-custom curl http://web-custom
```

### **Paso 3: Comparar comportamiento**

```bash
# Intentar comunicación entre redes diferentes
docker exec client-default ping -c 3 web-custom
# Esto fallará - las redes están aisladas

# Alternativa con curl para verificar aislamiento
echo "Intentando conectar desde red default a red personalizada:"
docker exec client-default curl --connect-timeout 5 http://web-custom 2>/dev/null || echo "Conexión fallida: las redes están aisladas ✓"

# Ver tabla de ruteo en los contenedores
echo "Tabla de ruteo en red default:"
# Instalar herramientas de red en nginx (si es necesario)
docker exec web-default which route >/dev/null 2>&1 || docker exec web-default apt update && docker exec web-default apt install -y net-tools
docker exec web-default route -n

echo "Tabla de ruteo en red personalizada:"
# Instalar herramientas de red en nginx personalizada
docker exec web-custom which route >/dev/null 2>&1 || docker exec web-custom apt update && docker exec web-custom apt install -y net-tools
docker exec web-custom route -n

# Alternativa usando ip route (más moderno y disponible)
echo "Rutas usando ip route (red default):"
docker exec web-default ip route

echo "Rutas usando ip route (red personalizada):"
docker exec web-custom ip route

# Verificar configuraciones de red
echo "IP en red default:"
docker exec client-default hostname -I

echo "IP en red personalizada:"
docker exec client-custom hostname -I
```

---

## 🐍 Ejercicio 3: Aplicación Multi-Tier

### **Paso 1: Preparar estructura del proyecto**

```bash
# Crear red para la aplicación
docker network create app-network

# Crear estructura de directorios
mkdir -p ~/docker-networks-lab/multi-tier-app
cd ~/docker-networks-lab/multi-tier-app
mkdir -p html backend

# Crear frontend básico
cat << 'EOF' > html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Mi App Multi-Tier</title>
    <style>
        body { font-family: Arial; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        button { padding: 10px; margin: 5px; background: #007bff; color: white; border: none; cursor: pointer; }
        #result { margin-top: 20px; padding: 20px; background: #f8f9fa; border: 1px solid #dee2e6; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Docker Multi-Tier App</h1>
        
        <button onclick="testAPI()">Test API</button>
        <button onclick="checkHealth()">Check Health</button>
        <button onclick="getUsers()">Get Users</button>
        
        <div id="result"></div>
    </div>

    <script>
        function testAPI() {
            fetch('/api/')
                .then(response => response.json())
                .then(data => displayResult(data));
        }
        
        function checkHealth() {
            fetch('/api/health')
                .then(response => response.json())
                .then(data => displayResult(data));
        }
        
        function getUsers() {
            fetch('/api/users')
                .then(response => response.json())
                .then(data => displayResult(data));
        }
        
        function displayResult(data) {
            document.getElementById('result').innerHTML = 
                '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
        }
    </script>
</body>
</html>
EOF

# Configurar Nginx como proxy
cat << 'EOF' > html/nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend-api:5000;
    }
    
    server {
        listen 80;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF

echo "✅ Estructura del proyecto creada en ~/docker-networks-lab/multi-tier-app"
ls -la html/
```

### **Paso 2: Crear aplicación backend**

```bash
# API Backend
cat << 'EOF' > backend/app.py
from flask import Flask, jsonify
import psycopg2
import os

app = Flask(__name__)

def get_db_connection():
    return psycopg2.connect(
        host='postgres-db',  # Nombre del contenedor
        database='mi_app',
        user='app_user',
        password='app_password'
    )

@app.route('/')
def home():
    return jsonify({'mensaje': 'API funcionando', 'version': '1.0'})

@app.route('/health')
def health():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        conn.close()
        return jsonify({'status': 'healthy', 'database': 'connected'})
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

@app.route('/users')
def users():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT id, nombre FROM usuarios')
        users = [{'id': row[0], 'nombre': row[1]} for row in cursor.fetchall()]
        conn.close()
        return jsonify(users)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat << 'EOF' > backend/requirements.txt
Flask==2.3.3
psycopg2-binary==2.9.7
EOF

cat << 'EOF' > backend/Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
EOF

# Construir imagen del backend
cd backend
docker build -t mi-backend-api .
cd ..

echo "✅ Backend creado y imagen construida"
```

### **Paso 3: Desplegar stack completo**

```bash
# Base de datos
echo "🗄️ Desplegando base de datos PostgreSQL..."
docker run -d --name postgres-db \
  --network app-network \
  -e POSTGRES_DB=mi_app \
  -e POSTGRES_USER=app_user \
  -e POSTGRES_PASSWORD=app_password \
  postgres:15

# Backend API
echo "🔧 Desplegando API Backend..."
docker run -d --name backend-api \
  --network app-network \
  -p 5000:5000 \
  mi-backend-api

# Frontend con configuración pre-creada
echo "🌐 Desplegando Frontend Web..."
docker run -d --name frontend-web \
  --network app-network \
  -p 8080:80 \
  -v $(pwd)/html:/usr/share/nginx/html \
  -v $(pwd)/html/nginx.conf:/etc/nginx/nginx.conf \
  nginx

# Verificar que todos los contenedores están ejecutándose
echo "📋 Verificando estado de los contenedores:"
docker ps --filter network=app-network --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### **Paso 4: Inicializar base de datos y probar**

```bash
# Esperar que PostgreSQL arranque completamente
echo "⏳ Esperando que PostgreSQL arranque..."
sleep 15

# Verificar que PostgreSQL está listo
docker logs postgres-db | tail -5

# Inicializar base de datos
echo "🗄️ Inicializando base de datos..."
docker exec postgres-db psql -U app_user -d mi_app -c "
CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL
);

INSERT INTO usuarios (nombre) VALUES 
  ('Alice Developer'),
  ('Bob DevOps'),
  ('Charlie Architect')
ON CONFLICT DO NOTHING;
"

# Verificar que los datos se insertaron
echo "📋 Verificando datos en la base:"
docker exec postgres-db psql -U app_user -d mi_app -c "SELECT * FROM usuarios;"

# Probar endpoints directamente
echo "🔧 Probando API directamente:"
curl -s http://localhost:5000/ | jq .
curl -s http://localhost:5000/health | jq .
curl -s http://localhost:5000/users | jq .

# Probar a través del frontend (proxy)
echo "🌐 Probando API a través del proxy:"
curl -s http://localhost:8080/api/ | jq .
curl -s http://localhost:8080/api/users | jq .

# Verificar que el frontend está accesible
echo "📄 Verificando frontend:"
curl -s http://localhost:8080 | grep -o '<title>.*</title>'

echo "✅ Aplicación completa desplegada!"
echo "🌍 Abre http://localhost:8080 en tu navegador para usar la interfaz completa"
echo "🔧 API directa disponible en http://localhost:5000"
```

---

## 🔒 Ejercicio 4: Aislamiento y Seguridad

### **Paso 1: Crear redes separadas**

```bash
# Red para frontend y API
docker network create frontend-network

# Red para API y base de datos  
docker network create backend-network

# Red DMZ (zona desmilitarizada)
docker network create dmz-network
```

### **Paso 2: Redesplegar con aislamiento**

```bash
# Volver al directorio del proyecto
cd ~/docker-networks-lab/multi-tier-app

# Detener aplicación actual
docker stop frontend-web backend-api postgres-db 2>/dev/null || true
docker rm frontend-web backend-api postgres-db 2>/dev/null || true

# Crear versión del backend que funcione con postgres-secure
echo "⚙️ Creando backend para entorno seguro..."
cat << 'EOF' > backend/app-secure.py
from flask import Flask, jsonify
import psycopg2
import os

app = Flask(__name__)

def get_db_connection():
    # Usar variable de entorno o valor por defecto
    db_host = os.environ.get('DATABASE_HOST', 'postgres-secure')
    return psycopg2.connect(
        host=db_host,
        database='mi_app',
        user='app_user',
        password='app_password'
    )

@app.route('/')
def home():
    return jsonify({'mensaje': 'API Segura funcionando', 'version': '1.0', 'ambiente': 'seguro'})

@app.route('/health')
def health():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        conn.close()
        db_host = os.environ.get('DATABASE_HOST', 'postgres-secure')
        return jsonify({'status': 'healthy', 'database': 'connected', 'db_host': db_host})
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

@app.route('/users')
def users():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT id, nombre FROM usuarios')
        users = [{'id': row[0], 'nombre': row[1]} for row in cursor.fetchall()]
        conn.close()
        return jsonify(users)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Crear Dockerfile para versión segura
cat << 'EOF' > backend/Dockerfile-secure
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app-secure.py app.py

EXPOSE 5000

CMD ["python", "app.py"]
EOF

# Construir nueva imagen para entorno seguro
cd backend
docker build -f Dockerfile-secure -t mi-backend-api-secure .
cd ..

# Base de datos solo en red backend
echo "🗄️ Desplegando base de datos en red backend..."
docker run -d --name postgres-secure \
  --network backend-network \
  -e POSTGRES_DB=mi_app \
  -e POSTGRES_USER=app_user \
  -e POSTGRES_PASSWORD=app_password \
  postgres:15

# API en ambas redes (frontend y backend) con variable de entorno
echo "🔧 Desplegando API en ambas redes..."
docker run -d --name api-secure \
  --network backend-network \
  -e DATABASE_HOST=postgres-secure \
  mi-backend-api-secure

docker network connect frontend-network api-secure

# Actualizar configuración para nuevo nombre de backend
echo "⚙️ Actualizando configuración de nginx..."
sed -i 's/backend-api:5000/api-secure:5000/' html/nginx.conf

# Frontend solo en red frontend
echo "🌐 Desplegando frontend en red frontend..."
docker run -d --name web-secure \
  --network frontend-network \
  -p 8080:80 \
  -v $(pwd)/html:/usr/share/nginx/html \
  -v $(pwd)/html/nginx.conf:/etc/nginx/nginx.conf \
  nginx

# Verificar despliegue
echo "📋 Verificando contenedores desplegados:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
```

### **Paso 3: Verificar aislamiento**

```bash
# Esperar que PostgreSQL arranque
echo "⏳ Esperando que PostgreSQL arranque..."
sleep 15

# Inicializar base de datos nuevamente
echo "🗄️ Inicializando base de datos segura..."
docker exec postgres-secure psql -U app_user -d mi_app -c "
CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL
);

INSERT INTO usuarios (nombre) VALUES 
  ('Secure Alice'),
  ('Secure Bob'),
  ('Secure Charlie')
ON CONFLICT DO NOTHING;
"

# Verificar que los datos se insertaron
echo "📋 Verificando datos en la base segura:"
docker exec postgres-secure psql -U app_user -d mi_app -c "SELECT * FROM usuarios;"

# Instalar herramientas de red en el frontend para las pruebas
docker exec web-secure apt update
docker exec web-secure apt install -y iputils-ping curl

# El frontend NO puede acceder directamente a la base de datos
echo "🔒 Probando acceso directo desde frontend a base de datos:"
docker exec web-secure ping -c 2 postgres-secure 2>/dev/null || echo "✓ Acceso bloqueado - aislamiento correcto"

# El frontend SÍ puede acceder a la API
echo "🔓 Probando acceso desde frontend a API:"
docker exec web-secure ping -c 2 api-secure && echo "✓ Acceso permitido"

# Instalar herramientas en la API también
docker exec api-secure apt update
docker exec api-secure apt install -y iputils-ping

# La API SÍ puede acceder a la base de datos
echo "🔓 Probando acceso desde API a base de datos:"
docker exec api-secure ping -c 2 postgres-secure && echo "✓ Acceso permitido"

# Verificar conectividad de la API con la base de datos
echo "🔧 Verificando health check de la API:"
curl -s http://localhost:8080/api/health | jq .

# Probar funcionamiento end-to-end
echo "🌐 Probando funcionalidad completa:"
curl -s http://localhost:8080/api/users | jq .

# Verificar que la API puede resolver el nombre de la base de datos
echo "🔍 Verificando resolución DNS desde la API:"
docker exec api-secure nslookup postgres-secure 2>/dev/null || docker exec api-secure getent hosts postgres-secure

echo "✅ Verificación de aislamiento completada!"
echo "📊 Resumen de conectividad:"
echo "  - Frontend → API: ✅ Permitido"
echo "  - Frontend → Database: ❌ Bloqueado"
echo "  - API → Database: ✅ Permitido"
```

---

## 🌐 Ejercicio 5: Tipos de Red Avanzados

### **Paso 1: Red Host**

```bash
# Contenedor usando red del host directamente
docker run -d --name nginx-host \
  --network host \
  nginx

# No hay mapeo de puertos, usa directamente puerto 80 del host
# CUIDADO: Esto puede conflictuar con servicios del host

# Verificar
curl http://localhost
# o netstat -tulpn | grep :80

# Limpiar rápidamente
docker stop nginx-host
docker rm nginx-host
```

### **Paso 2: Red None**

```bash
# Contenedor completamente aislado
docker run -d --name aislado \
  --network none \
  ubuntu:22.04 sleep 3600

# Ver configuración de red (solo loopback)
docker exec aislado ip addr show

# Intentar instalar herramientas (esto también fallará por falta de conectividad)
echo "Intentando actualizar paquetes en contenedor aislado:"
docker exec aislado apt update 2>/dev/null || echo "✓ Sin conectividad externa - aislamiento completo"

# Verificar que solo tiene interfaz loopback
echo "Interfaces de red disponibles:"
docker exec aislado ip addr show | grep -E "^[0-9]+:"

# No hay conectividad externa (esto fallará)
echo "Probando conectividad externa:"
docker exec aislado ping -c 2 8.8.8.8 2>/dev/null || echo "✓ Sin acceso a internet"
```

### **Paso 3: Macvlan Network**

```bash
# Crear red macvlan (si el entorno lo permite)
# NOTA: Esto requiere configuración específica del host

# docker network create -d macvlan \
#   --subnet=192.168.1.0/24 \
#   --gateway=192.168.1.1 \
#   -o parent=eth0 \
#   mi-macvlan

# Contenedor con IP directa en la red física
# docker run -d --name web-macvlan \
#   --network mi-macvlan \
#   --ip=192.168.1.100 \
#   nginx

# Esto es útil para casos que requieren IPs específicas
```

---

## 🔍 Ejercicio 6: Debugging de Redes

### **Paso 1: Herramientas de diagnóstico**

```bash
# Contenedor con herramientas de red
docker run -it --name nettools \
  --network app-network \
  nicolaka/netshoot

# Dentro del contenedor:
# nslookup postgres-db
# dig postgres-db
# ping postgres-db
# nmap -p 5432 postgres-db
# curl http://backend-api:5000/health
# exit
```

### **Paso 2: Analizar tráfico**

```bash
# Ver puertos expuestos
docker port frontend-web 2>/dev/null || echo "No hay puertos expuestos en frontend-web"
docker port api-secure 2>/dev/null || echo "No hay puertos expuestos en api-secure"

# Instalar herramientas de red si no están disponibles
echo "Instalando herramientas de red en api-secure:"
docker exec api-secure which netstat >/dev/null 2>&1 || {
  docker exec api-secure apt update && docker exec api-secure apt install -y net-tools iproute2
}

# Ver procesos de red en contenedor
echo "Procesos de red en api-secure:"
docker exec api-secure netstat -tulpn 2>/dev/null || docker exec api-secure ss -tulpn

# Ver conexiones activas (alternativa moderna)
echo "Conexiones activas usando ss:"
docker exec api-secure ss -tuln

# Verificar puertos específicos
echo "Verificando puerto 5000 en api-secure:"
docker exec api-secure ss -tlnp | grep :5000 || echo "Puerto 5000 no está en escucha"
```

### **Paso 3: Troubleshooting común**

```bash
# Verificar que el contenedor está en la red correcta
docker inspect api-secure | jq '.[0].NetworkSettings.Networks'

# Ver logs de conexión
docker logs api-secure

# Instalar herramientas de diagnóstico si es necesario
echo "Preparando herramientas para diagnóstico:"
docker exec api-secure which nc >/dev/null 2>&1 || {
  docker exec api-secure apt update && docker exec api-secure apt install -y netcat-openbsd dnsutils
}

# Probar conectividad específica a puerto
echo "Probando conectividad a PostgreSQL:"
docker exec api-secure nc -zv postgres-secure 5432 2>/dev/null && echo "✓ Puerto 5432 accesible" || echo "✗ Puerto 5432 no accesible"

# Ver DNS resolution
echo "Resolviendo nombre postgres-secure:"
docker exec api-secure nslookup postgres-secure 2>/dev/null || {
  echo "nslookup no disponible, usando getent:"
  docker exec api-secure getent hosts postgres-secure
}

# Alternativa para verificar conectividad usando curl
echo "Verificando conectividad HTTP (si aplica):"
docker exec api-secure curl -s --connect-timeout 3 http://postgres-secure:5432 2>/dev/null && echo "✓ HTTP responde" || echo "ℹ️ No es un servicio HTTP (normal para PostgreSQL)"

# Verificar interfaces de red del contenedor
echo "Interfaces de red en api-secure:"
docker exec api-secure ip addr show
```

---

## 📊 Ejercicio 7: Monitoreo de Red

### **Paso 1: Estadísticas de red**

```bash
# Estadísticas de interfaz docker
docker exec frontend-web cat /proc/net/dev

# Estadísticas por contenedor
docker stats --format "table {{.Container}}\t{{.NetIO}}"

# Información detallada de red
docker inspect api-secure | jq '.[0].NetworkSettings.Networks'
```

### **Paso 2: Configuración avanzada**

```bash
# Crear red con configuración específica
docker network create mi-red-custom \
  --driver bridge \
  --subnet=172.20.0.0/16 \
  --ip-range=172.20.240.0/20 \
  --gateway=172.20.0.1

# Ver configuración
docker network inspect mi-red-custom

# Asignar IP específica
docker run -d --name test-ip \
  --network mi-red-custom \
  --ip 172.20.240.10 \
  nginx

# Verificar IP asignada
docker inspect test-ip | jq -r '.[0].NetworkSettings.Networks."mi-red-custom".IPAddress'
```

---

## 🧹 Ejercicio 8: Limpieza y Gestión

### **Paso 1: Identificar recursos de red**

```bash
# Ver todas las redes
docker network ls

# Ver redes no utilizadas
docker network ls --filter "dangling=true"

# Ver qué contenedores usan cada red
for network in $(docker network ls -q); do
  echo "Red: $(docker network inspect $network | jq -r '.[0].Name')"
  docker network inspect $network | jq -r '.[0].Containers | keys[]' 2>/dev/null || echo "  Sin contenedores"
  echo
done
```

### **Paso 2: Limpiar recursos**

```bash
# Detener contenedores
docker stop $(docker ps -q)

# Eliminar contenedores
docker rm $(docker ps -aq)

# Eliminar redes no utilizadas
docker network prune

# Eliminar red específica
docker network rm mi-red-custom

# Verificar limpieza
docker network ls
```

---

## 📋 Verificación de Aprendizaje

### **Comandos que debes dominar:**

```bash
# Gestión de redes
docker network ls
docker network create nombre
docker network inspect nombre
docker network rm nombre
docker network prune

# Conectar contenedores
docker run --network nombre imagen
docker network connect red contenedor
docker network disconnect red contenedor

# Debugging
docker port contenedor
docker exec contenedor netstat -tulpn
docker logs contenedor
```

### **Conceptos clave:**

1. **Red Bridge**: Red por defecto, NAT desde host
2. **Red Personalizada**: DNS automático, aislamiento
3. **Red Host**: Sin aislamiento, usa red del host directamente
4. **Red None**: Completamente aislado
5. **Comunicación**: Por nombre en redes personalizadas

---

## 🎓 Resultado Esperado

Al completar este laboratorio, deberías poder:

- ✅ Configurar diferentes tipos de redes Docker
- ✅ Implementar comunicación segura entre contenedores
- ✅ Diseñar arquitecturas multi-tier con aislamiento
- ✅ Debugging de problemas de conectividad
- ✅ Optimizar el rendimiento de red
- ✅ Implementar seguridad de red en contenedores

---

## 🚀 Próximos Pasos

¡Felicitaciones! Has completado todos los laboratorios del Módulo 2. 

**Continúa con:**
- Práctica adicional con [Docker Commands Guide](./docker-commands-guide.md)
- Ejercicios complementarios en [Docker Exercises](./docker-exercises.md)
- Módulo 3: Orquestación de Contenedores

---

## 🔧 Troubleshooting

### **Error: "network not found"**
```bash
# Verificar que la red existe
docker network ls
# Crear la red si no existe
docker network create nombre-red
```

### **Error: "port already in use"**
```bash
# Ver qué proceso usa el puerto
sudo netstat -tulpn | grep :puerto
# Usar puerto diferente o detener el proceso
```

### **No hay conectividad entre contenedores**
```bash
# Verificar que están en la misma red
docker inspect contenedor1 | jq '.[0].NetworkSettings.Networks'
docker inspect contenedor2 | jq '.[0].NetworkSettings.Networks'
```

### **DNS no resuelve nombres de contenedores**
```bash
# Solo funciona en redes personalizadas, no en bridge default
docker network create mi-red
docker run --network mi-red --name contenedor1 imagen1
docker run --network mi-red --name contenedor2 imagen2
```