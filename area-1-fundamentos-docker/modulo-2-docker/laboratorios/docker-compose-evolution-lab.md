# Laboratorio Docker Compose: Primer Paso hacia la Orquestación

**Duración**: 45 minutos  
**Objetivo**: Experimentar con Docker Compose como primer paso hacia Kubernetes

## 🎯 Objetivos de aprendizaje

- Entender las limitaciones de Docker standalone
- Implementar aplicaciones multi-contenedor con Docker Compose
- Descubrir conceptos que evolucionarán a Kubernetes (Services, Networks, Volumes)
- Identificar problemas que Kubernetes resolverá

---

## 📋 Prerequisitos

- VM de Azure configurada del laboratorio anterior
- Docker funcionando
- Git instalado

---

## 🔍 Problema: Aplicación Compleja con Docker

### Situación:
Una aplicación web típica requiere:
- **Frontend**: Interfaz de usuario (React/Angular/etc.)
- **Backend**: API REST (Node.js/Python/etc.)  
- **Base de datos**: Persistencia (PostgreSQL/MySQL/etc.)
- **Cache**: Rendimiento (Redis)
- **Proxy**: Load balancer (Nginx)

**¿Cómo manejar todo esto con `docker run`?** 🤔

---

## 🧪 Ejercicio 1: El Problema de Docker Standalone

### Paso 1: Intentar manualmente (la forma difícil)

```bash
# Conectarse a la VM
ssh -i ~/Downloads/vm-key-lab1.pem azureuser@<IP_PUBLICA>

# 1. Crear red personalizada
docker network create app-network

# 2. Base de datos PostgreSQL
docker run -d \
  --name db \
  --network app-network \
  -e POSTGRES_DB=miapp \
  -e POSTGRES_USER=usuario \
  -e POSTGRES_PASSWORD=secreto \
  -v db-data:/var/lib/postgresql/data \
  postgres:13

# 3. Cache Redis
docker run -d \
  --name cache \
  --network app-network \
  redis:alpine

# 4. Backend API
docker run -d \
  --name backend \
  --network app-network \
  -p 3001:3000 \
  -e DATABASE_URL=postgresql://usuario:secreto@db:5432/miapp \
  -e REDIS_URL=redis://cache:6379 \
  node:16-alpine sh -c "
    npm init -y && 
    npm install express pg redis && 
    echo 'console.log(\"Backend iniciado\"); require(\"http\").createServer((req,res)=>{res.writeHead(200,{\"Content-Type\":\"application/json\"});res.end(JSON.stringify({status:\"API funcionando\",db:\"conectado\",cache:\"conectado\"}))}).listen(3000)' > server.js &&
    node server.js
  "

# 5. Frontend
docker run -d \
  --name frontend \
  --network app-network \
  -p 3000:80 \
  nginx:alpine

# 6. Verificar
docker ps
curl http://localhost:3001
```

### 🤔 **Problemas identificados:**

1. **Comando extremadamente largo y complejo**
2. **Orden de arranque importante** (DB antes que Backend)
3. **Dependencias hardcodeadas**
4. **Difícil de reproducir** en otro entorno
5. **Sin gestión de fallos** automática
6. **Escalado manual**

---

## 🧪 Ejercicio 2: Docker Compose - La Solución

### Paso 1: Instalar Docker Compose

```bash
# Verificar si ya está instalado
docker compose version

# Si no está instalado
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalación
docker compose version
```

### Paso 2: Crear directorio del proyecto

```bash
mkdir ~/docker-compose-lab
cd ~/docker-compose-lab

# Crear estructura
mkdir -p frontend backend database
```

### Paso 3: Crear docker-compose.yml

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Base de datos PostgreSQL
  database:
    image: postgres:13
    container_name: app-database
    environment:
      POSTGRES_DB: miapp
      POSTGRES_USER: usuario
      POSTGRES_PASSWORD: secreto
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U usuario -d miapp"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Cache Redis
  cache:
    image: redis:alpine
    container_name: app-cache
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Backend API
  backend:
    build: ./backend
    container_name: app-backend
    ports:
      - "3001:3000"
    environment:
      DATABASE_URL: postgresql://usuario:secreto@database:5432/miapp
      REDIS_URL: redis://cache:6379
      NODE_ENV: development
    networks:
      - app-network
    depends_on:
      database:
        condition: service_healthy
      cache:
        condition: service_healthy
    restart: unless-stopped

  # Frontend
  frontend:
    build: ./frontend
    container_name: app-frontend
    ports:
      - "3000:80"
    networks:
      - app-network
    depends_on:
      - backend
    restart: unless-stopped

  # Proxy/Load Balancer
  proxy:
    image: nginx:alpine
    container_name: app-proxy
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    networks:
      - app-network
    depends_on:
      - frontend
      - backend
    restart: unless-stopped

networks:
  app-network:
    driver: bridge

volumes:
  db-data:
    driver: local
EOF
```

### Paso 4: Crear archivos de la aplicación

#### Base de datos:
```bash
cat > database/init.sql << 'EOF'
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES 
('Juan Pérez', 'juan@example.com'),
('María García', 'maria@example.com');
EOF
```

#### Backend:
```bash
# Dockerfile del backend
cat > backend/Dockerfile << 'EOF'
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# package.json
cat > backend/package.json << 'EOF'
{
  "name": "backend-api",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "pg": "^8.8.0",
    "redis": "^4.3.0",
    "cors": "^2.8.5"
  }
}
EOF

# server.js
cat > backend/server.js << 'EOF'
const express = require('express');
const { Client } = require('pg');
const redis = require('redis');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Configuración de base de datos
const dbClient = new Client({
  connectionString: process.env.DATABASE_URL
});

// Configuración de Redis
const redisClient = redis.createClient({
  url: process.env.REDIS_URL
});

// Conectar a las bases de datos
async function connectDatabases() {
  try {
    await dbClient.connect();
    await redisClient.connect();
    console.log('✅ Conectado a PostgreSQL y Redis');
  } catch (error) {
    console.error('❌ Error conectando a las bases de datos:', error);
  }
}

connectDatabases();

// Rutas de la API
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Backend funcionando correctamente',
    timestamp: new Date().toISOString()
  });
});

app.get('/users', async (req, res) => {
  try {
    // Verificar cache primero
    const cached = await redisClient.get('users');
    if (cached) {
      return res.json({ 
        data: JSON.parse(cached), 
        source: 'cache' 
      });
    }

    // Si no está en cache, consultar base de datos
    const result = await dbClient.query('SELECT * FROM users ORDER BY id');
    const users = result.rows;

    // Guardar en cache por 60 segundos
    await redisClient.setEx('users', 60, JSON.stringify(users));

    res.json({ 
      data: users, 
      source: 'database' 
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

app.post('/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    const result = await dbClient.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );
    
    // Limpiar cache
    await redisClient.del('users');
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Error al crear usuario' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Servidor backend ejecutándose en puerto ${PORT}`);
});
EOF
```

#### Frontend:
```bash
# Dockerfile del frontend
cat > frontend/Dockerfile << 'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/
COPY script.js /usr/share/nginx/html/
EXPOSE 80
EOF

# HTML
cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>App Demo - Docker Compose</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>🐳 Aplicación Demo con Docker Compose</h1>
        
        <div class="status" id="status">
            <h2>Estado de Servicios</h2>
            <div id="backend-status">Backend: ⏳ Verificando...</div>
        </div>

        <div class="users-section">
            <h2>👥 Gestión de Usuarios</h2>
            <div class="form-section">
                <input type="text" id="name" placeholder="Nombre completo">
                <input type="email" id="email" placeholder="Email">
                <button onclick="addUser()">Agregar Usuario</button>
            </div>
            <div id="users-list">⏳ Cargando usuarios...</div>
        </div>

        <div class="info">
            <h3>Arquitectura de la Aplicación:</h3>
            <ul>
                <li><strong>Frontend:</strong> Nginx sirviendo HTML/CSS/JS</li>
                <li><strong>Backend:</strong> Node.js API con Express</li>
                <li><strong>Base de datos:</strong> PostgreSQL</li>
                <li><strong>Cache:</strong> Redis</li>
                <li><strong>Proxy:</strong> Nginx como load balancer</li>
            </ul>
        </div>
    </div>

    <script src="script.js"></script>
</body>
</html>
EOF

# CSS
cat > frontend/style.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    padding: 20px;
}

.container {
    max-width: 800px;
    margin: 0 auto;
    background: white;
    border-radius: 15px;
    padding: 30px;
    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
}

h1 {
    text-align: center;
    color: #333;
    margin-bottom: 30px;
    font-size: 2.5em;
}

.status {
    background: #f8f9fa;
    padding: 20px;
    border-radius: 10px;
    margin-bottom: 30px;
    border-left: 5px solid #007bff;
}

.users-section {
    margin-bottom: 30px;
}

.form-section {
    display: flex;
    gap: 10px;
    margin-bottom: 20px;
    flex-wrap: wrap;
}

input {
    flex: 1;
    padding: 12px;
    border: 2px solid #ddd;
    border-radius: 8px;
    font-size: 16px;
    min-width: 200px;
}

button {
    padding: 12px 24px;
    background: #007bff;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-size: 16px;
    transition: background 0.3s;
}

button:hover {
    background: #0056b3;
}

#users-list {
    background: #f8f9fa;
    padding: 20px;
    border-radius: 10px;
    min-height: 100px;
}

.user-item {
    background: white;
    padding: 15px;
    margin: 10px 0;
    border-radius: 8px;
    border-left: 4px solid #28a745;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.info {
    background: #e9ecef;
    padding: 20px;
    border-radius: 10px;
    border-left: 5px solid #28a745;
}

.info ul {
    margin-left: 20px;
    margin-top: 10px;
}

.info li {
    margin: 8px 0;
}

.status-ok { color: #28a745; }
.status-error { color: #dc3545; }
.cache-indicator { 
    font-size: 12px; 
    background: #ffc107; 
    padding: 2px 6px; 
    border-radius: 4px; 
    color: #000;
}
EOF

# JavaScript
cat > frontend/script.js << 'EOF'
const API_BASE = 'http://COLOCAR-IP-PUBLICA/api';

// Verificar estado del backend
async function checkBackendStatus() {
    try {
        const response = await fetch(`${API_BASE}/health`);
        const data = await response.json();
        
        document.getElementById('backend-status').innerHTML = 
            `Backend: <span class="status-ok">✅ ${data.message}</span><br>
             <small>Timestamp: ${data.timestamp}</small>`;
    } catch (error) {
        document.getElementById('backend-status').innerHTML = 
            `Backend: <span class="status-error">❌ Error de conexión</span>`;
    }
}

// Cargar lista de usuarios
async function loadUsers() {
    try {
        const response = await fetch(`${API_BASE}/users`);
        const data = await response.json();
        
        const usersList = document.getElementById('users-list');
        
        if (data.data && data.data.length > 0) {
            const cacheIndicator = data.source === 'cache' ? 
                '<span class="cache-indicator">CACHE</span>' : 
                '<span class="cache-indicator" style="background: #28a745; color: white;">DB</span>';
            
            usersList.innerHTML = `
                <div style="margin-bottom: 10px;">
                    <strong>Usuarios (Fuente: ${cacheIndicator})</strong>
                </div>
                ${data.data.map(user => `
                    <div class="user-item">
                        <div>
                            <strong>${user.name}</strong><br>
                            <small>${user.email}</small>
                        </div>
                        <div>
                            <small>ID: ${user.id}</small>
                        </div>
                    </div>
                `).join('')}
            `;
        } else {
            usersList.innerHTML = '<p>No hay usuarios registrados</p>';
        }
    } catch (error) {
        document.getElementById('users-list').innerHTML = 
            '<p class="status-error">❌ Error al cargar usuarios</p>';
    }
}

// Agregar nuevo usuario
async function addUser() {
    const name = document.getElementById('name').value;
    const email = document.getElementById('email').value;
    
    if (!name || !email) {
        alert('Por favor completa todos los campos');
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/users`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ name, email })
        });
        
        if (response.ok) {
            document.getElementById('name').value = '';
            document.getElementById('email').value = '';
            loadUsers(); // Recargar lista
            alert('Usuario agregado correctamente');
        } else {
            alert('Error al agregar usuario');
        }
    } catch (error) {
        alert('Error de conexión');
    }
}

// Inicializar aplicación
document.addEventListener('DOMContentLoaded', () => {
    checkBackendStatus();
    loadUsers();
    
    // Verificar estado cada 30 segundos
    setInterval(checkBackendStatus, 30000);
});
EOF
```

#### Proxy Nginx:
```bash
mkdir nginx
cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:3000;
        # En producción podrías agregar más instancias:
        # server backend2:3000;
        # server backend3:3000;
    }

    server {
        listen 80;
        
        # Servir frontend estático
        location / {
            proxy_pass http://frontend:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        # API del backend
        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
EOF
```

### Paso 5: Ejecutar la aplicación completa

```bash
# Construir y ejecutar todos los servicios
docker compose up -d --build

# Ver el estado de todos los servicios
docker compose ps

# Ver logs de todos los servicios
docker compose logs -f
```

### Paso 6: Probar la aplicación

```bash
# Verificar servicios individualmente
echo "=== HEALTH CHECK BACKEND ==="
curl http://localhost:3001/health

echo "=== USUARIOS VIA API ==="
curl http://localhost:3001/users

echo "=== FRONTEND ==="
curl http://localhost:3000

# Abrir en navegador (si tienes GUI)
# http://localhost:3000
```

---

## 🧪 Ejercicio 3: Operaciones con Docker Compose

### Gestión de servicios:

```bash
# Ver estado detallado
docker compose ps

# Logs de un servicio específico
docker compose logs backend

# Escalar un servicio (limitado en Docker Compose)
docker compose up -d --scale backend=2

# Reiniciar un servicio
docker compose restart backend

# Detener todos los servicios
docker compose stop

# Iniciar servicios detenidos
docker compose start

# Eliminar todo (contenedores, redes, volúmenes)
docker compose down -v
```

### Actualizaciones:

```bash
# Reconstruir solo un servicio
docker compose build backend

# Actualizar un servicio específico
docker compose up -d --no-deps backend

# Actualizar toda la aplicación
docker compose up -d --build
```

---

## 🔍 Análisis: Docker Compose vs Kubernetes

### ✅ **Ventajas de Docker Compose:**

1. **Simplicidad**: Un solo archivo YAML define toda la aplicación
2. **Desarrollo local**: Perfecto para entornos de desarrollo
3. **Reproducibilidad**: Mismo entorno en cualquier máquina
4. **Gestión de dependencias**: `depends_on` maneja el orden de arranque
5. **Redes automáticas**: Comunicación entre servicios por nombre

### ❌ **Limitaciones para producción:**

1. **Single-host**: Solo funciona en una máquina
2. **No alta disponibilidad**: Si falla el host, toda la aplicación se cae  
3. **Escalado limitado**: No puede distribuir carga entre múltiples hosts
4. **Sin auto-recovery**: No reinicia servicios automáticamente
5. **Sin rolling updates**: Actualizaciones causan downtime
6. **Sin health checks avanzados**: Limitado para detectar problemas
7. **Sin load balancing inteligente**: Nginx manual vs automático
8. **Sin secretos management**: Credenciales en texto plano

---

## 🚀 Preparando el salto a Kubernetes

### Conceptos que ya conoces:

| Docker Compose | Kubernetes Equivalente |
|----------------|------------------------|
| `services:` | `Deployment` + `Service` |
| `networks:` | `Service` networking |
| `volumes:` | `PersistentVolume` |
| `depends_on:` | `initContainers` |
| `healthcheck:` | `livenessProbe` / `readinessProbe` |
| `restart:` | `restartPolicy` |
| `ports:` | `Service` + `Ingress` |

### Lo que Kubernetes añade:

- ✅ **Multi-host clustering**
- ✅ **Auto-scaling** horizontal y vertical  
- ✅ **Self-healing** automático
- ✅ **Rolling deployments** sin downtime
- ✅ **Service discovery** avanzado
- ✅ **Load balancing** inteligente
- ✅ **Secrets management** seguro
- ✅ **Resource quotas** por namespace
- ✅ **RBAC** (control de acceso)
- ✅ **Monitoring** integrado

---

## 📊 Ejercicio de Reflexión

### Escenarios de producción:

1. **¿Qué pasa si necesitas 100 instancias del backend?**
   - Docker Compose: ❌ Limitado a un host
   - Kubernetes: ✅ Distribuye automáticamente

2. **¿Qué pasa si se cae el servidor?**
   - Docker Compose: ❌ Toda la aplicación se cae
   - Kubernetes: ✅ Migra automáticamente a otros nodos

3. **¿Cómo actualizas sin downtime?**
   - Docker Compose: ❌ `docker compose up` causa interrupción
   - Kubernetes: ✅ Rolling updates automáticos

4. **¿Cómo gestionas secretos sensibles?**
   - Docker Compose: ❌ Variables en texto plano
   - Kubernetes: ✅ Secrets encriptados

### 🤔 **Preguntas de análisis:**

1. **¿En qué casos seguirías usando Docker Compose?**

2. **¿Qué problemas identificas para usar esto en producción?**

3. **¿Cómo crees que Kubernetes resuelve estos problemas?**

---

## 🧹 Limpieza

```bash
# Detener y eliminar toda la aplicación
docker compose down -v

# Limpiar imágenes no utilizadas
docker image prune -f

# Limpiar sistema completo
docker system prune -f
```

---

## 📝 Entregables

1. **Screenshots** de:
   - Aplicación funcionando en el navegador
   - `docker compose ps` mostrando todos los servicios
   - Logs de los diferentes servicios
   - API responses del backend

2. **Análisis comparativo**: Docker standalone vs Docker Compose vs Kubernetes

3. **Identificación de limitaciones** de Docker Compose para producción

---

## 🔗 Preparación para Kubernetes

Has completado la evolución:

1. ✅ **VMs tradicionales** (Área 1, Módulo 1)
2. ✅ **Contenedores individuales** (Área 1, Módulo 2)  
3. ✅ **Aplicaciones multi-contenedor** (Este laboratorio)
4. 🎯 **Orquestación empresarial** → **Kubernetes** (Área 2)

**En el Área 2** aprenderás cómo Kubernetes transforma estos conceptos en una plataforma de orquestación robusta para producción.

**Tiempo estimado**: 45-60 minutos  
**Dificultad**: Intermedio-Avanzado