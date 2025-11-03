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
docker exec web-default route -n

echo "Tabla de ruteo en red personalizada:"
docker exec web-custom route -n

# Verificar configuraciones de red
echo "IP en red default:"
docker exec client-default hostname -I

echo "IP en red personalizada:"
docker exec client-custom hostname -I
```

---

## 🐍 Ejercicio 3: Aplicación Multi-Tier

### **Paso 1: Crear aplicación completa**

```bash
# Crear red para la aplicación
docker network create app-network

# Base de datos
docker run -d --name postgres-db \
  --network app-network \
  -e POSTGRES_DB=mi_app \
  -e POSTGRES_USER=app_user \
  -e POSTGRES_PASSWORD=app_password \
  postgres:15

# API Backend
cat << 'EOF' > app.py
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

cat << 'EOF' > requirements.txt
Flask==2.3.3
psycopg2-binary==2.9.7
EOF

cat << 'EOF' > Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
EOF

# Construir imagen del backend
docker build -t mi-backend-api .
```

### **Paso 2: Desplegar stack completo**

```bash
# Backend API
docker run -d --name backend-api \
  --network app-network \
  -p 5000:5000 \
  mi-backend-api

# Esperar que PostgreSQL arranque
sleep 10

# Inicializar base de datos
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

# Frontend simple
docker run -d --name frontend-web \
  --network app-network \
  -p 8080:80 \
  -v $(pwd)/html:/usr/share/nginx/html \
  nginx

# Crear frontend básico
mkdir -p html
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

# Actualizar nginx con nueva configuración
docker stop frontend-web
docker rm frontend-web

docker run -d --name frontend-web \
  --network app-network \
  -p 8080:80 \
  -v $(pwd)/html:/usr/share/nginx/html \
  -v $(pwd)/html/nginx.conf:/etc/nginx/nginx.conf \
  nginx
```

### **Paso 3: Probar la aplicación**

```bash
# Probar endpoints directamente
curl http://localhost:5000/
curl http://localhost:5000/health
curl http://localhost:5000/users

# Probar a través del frontend
curl http://localhost:8080/api/
curl http://localhost:8080/api/users

# Abrir en navegador: http://localhost:8080
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
# Detener aplicación actual
docker stop frontend-web backend-api postgres-db
docker rm frontend-web backend-api postgres-db

# Base de datos solo en red backend
docker run -d --name postgres-secure \
  --network backend-network \
  -e POSTGRES_DB=mi_app \
  -e POSTGRES_USER=app_user \
  -e POSTGRES_PASSWORD=app_password \
  postgres:15

# API en ambas redes (frontend y backend)
docker run -d --name api-secure \
  --network backend-network \
  mi-backend-api

docker network connect frontend-network api-secure

# Frontend solo en red frontend
docker run -d --name web-secure \
  --network frontend-network \
  -p 8080:80 \
  -v $(pwd)/html:/usr/share/nginx/html \
  -v $(pwd)/html/nginx.conf:/etc/nginx/nginx.conf \
  nginx

# Actualizar configuración para nuevo nombre de backend
sed -i 's/backend-api:5000/api-secure:5000/' html/nginx.conf
docker restart web-secure
```

### **Paso 3: Verificar aislamiento**

```bash
# Inicializar base de datos nuevamente
sleep 10
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

# Instalar herramientas de red en el frontend para las pruebas
docker exec web-secure apt update
docker exec web-secure apt install -y iputils-ping curl

# El frontend NO puede acceder directamente a la base de datos
echo "Probando acceso directo desde frontend a base de datos:"
docker exec web-secure ping -c 2 postgres-secure 2>/dev/null || echo "✓ Acceso bloqueado - aislamiento correcto"

# El frontend SÍ puede acceder a la API
echo "Probando acceso desde frontend a API:"
docker exec web-secure ping -c 2 api-secure && echo "✓ Acceso permitido"

# Instalar herramientas en la API también
docker exec api-secure apt update
docker exec api-secure apt install -y iputils-ping

# La API SÍ puede acceder a la base de datos
echo "Probando acceso desde API a base de datos:"
docker exec api-secure ping -c 2 postgres-secure && echo "✓ Acceso permitido"

# Probar funcionamiento end-to-end
echo "Probando funcionalidad completa:"
curl http://localhost:8080/api/users
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
docker port frontend-web
docker port api-secure

# Ver procesos de red en contenedor
docker exec api-secure netstat -tulpn

# Ver conexiones activas
docker exec api-secure ss -tuln
```

### **Paso 3: Troubleshooting común**

```bash
# Verificar que el contenedor está en la red correcta
docker inspect api-secure | jq '.[0].NetworkSettings.Networks'

# Ver logs de conexión
docker logs api-secure

# Probar conectividad específica
docker exec api-secure nc -zv postgres-secure 5432

# Ver DNS resolution
docker exec api-secure nslookup postgres-secure
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