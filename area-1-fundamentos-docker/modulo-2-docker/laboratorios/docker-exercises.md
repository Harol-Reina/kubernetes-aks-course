# 🏃‍♂️ Docker Exercises - Ejercicios Prácticos

**Duración**: 2-3 horas (ejercicios variados)  
**Dificultad**: Principiante a Avanzado  
**Objetivo**: Reforzar conceptos a través de práctica dirigida

---

## � Prerequisitos

- [Lab M2.7: Docker Compose completado](./docker-compose-evolution-lab.md)
- Todos los labs previos (M2.1 → M2.6) completados
- Conocimiento de Docker CLI
- Entorno de práctica disponible (VM o local)

---

## �📚 Estructura de Ejercicios

### **🟢 Nivel Principiante** (15-20 min c/u)
- [Ejercicio 1: Primeros Pasos](#ejercicio-1-primeros-pasos)
- [Ejercicio 2: Gestión Básica](#ejercicio-2-gestión-básica)
- [Ejercicio 3: Volúmenes Simples](#ejercicio-3-volúmenes-simples)

### **🟡 Nivel Intermedio** (25-30 min c/u)
- [Ejercicio 4: Aplicación Web](#ejercicio-4-aplicación-web)
- [Ejercicio 5: Base de Datos](#ejercicio-5-base-de-datos)
- [Ejercicio 6: Redes Personalizadas](#ejercicio-6-redes-personalizadas)

### **🔴 Nivel Avanzado** (35-45 min c/u)
- [Ejercicio 7: Multi-Container App](#ejercicio-7-multi-container-app)
- [Ejercicio 8: Microservicios](#ejercicio-8-microservicios)
- [Ejercicio 9: DevOps Pipeline](#ejercicio-9-devops-pipeline)

---

## 🟢 Ejercicio 1: Primeros Pasos

### **Objetivo**: Familiarizarse con comandos básicos

**Tiempo estimado**: 15 minutos

### **Tareas:**

1. **Ejecutar contenedores básicos**
   ```bash
   # Ejecutar hello-world
   docker run hello-world
   
   # Ejecutar Ubuntu interactivo
   docker run -it ubuntu:22.04 bash
   # Dentro: explore, instale algo, salga
   
   # Ejecutar nginx en background
   docker run -d --name mi-web nginx
   ```

2. **Gestionar contenedores**
   ```bash
   # Listar contenedores
   docker ps
   docker ps -a
   
   # Ver logs
   docker logs mi-web
   
   # Detener y eliminar
   docker stop mi-web
   docker rm mi-web
   ```

3. **Trabajar con imágenes**
   ```bash
   # Listar imágenes
   docker images
   
   # Descargar imagen específica
   docker pull redis:7.0-alpine
   
   # Ver información de imagen
   docker inspect redis:7.0-alpine
   ```

### **Verificación:**
- [ ] Ejecutaste al menos 3 contenedores diferentes
- [ ] Listaste contenedores activos e inactivos
- [ ] Detuviste y eliminaste contenedores
- [ ] Descargaste una imagen manualmente

---

## 🟢 Ejercicio 2: Gestión Básica

### **Objetivo**: Practicar el ciclo de vida completo

**Tiempo estimado**: 20 minutos

### **Tareas:**

1. **Crear contenedor con configuración**
   ```bash
   # Servidor web con puerto y nombre
   docker run -d --name servidor-web -p 8080:80 nginx
   
   # Verificar acceso
   curl http://localhost:8080
   ```

2. **Ejecutar comandos en contenedores**
   ```bash
   # Acceder al contenedor
   docker exec -it servidor-web bash
   
   # Modificar página principal
   echo "<h1>Mi página personalizada</h1>" > /usr/share/nginx/html/index.html
   exit
   
   # Verificar cambio
   curl http://localhost:8080
   ```

3. **Gestionar múltiples contenedores**
   ```bash
   # Crear múltiples instancias
   docker run -d --name web1 -p 8081:80 nginx
   docker run -d --name web2 -p 8082:80 nginx
   docker run -d --name web3 -p 8083:80 nginx
   
   # Gestionar en lote
   docker stop web1 web2 web3
   docker rm web1 web2 web3
   ```

### **Verificación:**
- [ ] Creaste contenedor con mapeo de puertos
- [ ] Modificaste contenido desde dentro del contenedor
- [ ] Gestionaste múltiples contenedores simultáneamente

---

## 🟢 Ejercicio 3: Volúmenes Simples

### **Objetivo**: Entender persistencia de datos

**Tiempo estimado**: 20 minutos

### **Tareas:**

1. **Problema de persistencia**
   ```bash
   # Crear contenedor y agregar datos
   docker run -it --name temp ubuntu:22.04 bash
   # Dentro: echo "datos importantes" > /tmp/archivo.txt
   # exit
   
   # Eliminar contenedor
   docker rm temp
   
   # Crear nuevo contenedor
   docker run -it --name temp2 ubuntu:22.04 bash
   # Dentro: cat /tmp/archivo.txt (no existe!)
   # exit
   docker rm temp2
   ```

2. **Usar bind mount**
   ```bash
   # Crear directorio en host
   mkdir ~/ejercicio-volumen
   echo "Archivo desde host" > ~/ejercicio-volumen/test.txt
   
   # Contenedor con bind mount
   docker run -it --name con-volumen \
     -v ~/ejercicio-volumen:/data \
     ubuntu:22.04 bash
   # Dentro: ls /data, cat /data/test.txt
   # Crear: echo "Desde contenedor" > /data/desde-contenedor.txt
   # exit
   
   # Verificar en host
   ls ~/ejercicio-volumen/
   cat ~/ejercicio-volumen/desde-contenedor.txt
   ```

3. **Usar volumen nombrado**
   ```bash
   # Crear volumen
   docker volume create mi-volumen
   
   # Usar volumen en contenedor
   docker run -it --name con-vol-nombrado \
     -v mi-volumen:/app/data \
     ubuntu:22.04 bash
   # Dentro: echo "En volumen nombrado" > /app/data/persistente.txt
   # exit
   
   # Nuevo contenedor con mismo volumen
   docker run -it --name con-vol-nombrado2 \
     -v mi-volumen:/app/data \
     ubuntu:22.04 bash
   # Dentro: cat /app/data/persistente.txt (¡existe!)
   # exit
   ```

### **Verificación:**
- [ ] Experimentaste pérdida de datos sin volúmenes
- [ ] Usaste bind mount exitosamente
- [ ] Compartiste datos entre contenedores con volumen nombrado

---

## 🟡 Ejercicio 4: Aplicación Web

### **Objetivo**: Construir y desplegar aplicación personalizada

**Tiempo estimado**: 30 minutos

### **Tareas:**

1. **Crear aplicación Node.js**
   ```bash
   mkdir ~/ejercicio-web-app
   cd ~/ejercicio-web-app
   
   # package.json
   cat << 'EOF' > package.json
   {
     "name": "mi-app-web",
     "version": "1.0.0",
     "main": "server.js",
     "scripts": {
       "start": "node server.js"
     },
     "dependencies": {
       "express": "^4.18.2"
     }
   }
   EOF
   
   # server.js
   cat << 'EOF' > server.js
   const express = require('express');
   const app = express();
   const port = 3000;
   
   app.use(express.static('public'));
   
   app.get('/api/info', (req, res) => {
     res.json({
       mensaje: 'Mi aplicación funciona!',
       timestamp: new Date().toISOString(),
       hostname: require('os').hostname()
     });
   });
   
   app.listen(port, () => {
     console.log(`Servidor ejecutándose en puerto ${port}`);
   });
   EOF
   
   # Crear directorio public
   mkdir public
   cat << 'EOF' > public/index.html
   <!DOCTYPE html>
   <html>
   <head>
     <title>Mi App Web</title>
     <style>body { font-family: Arial; margin: 40px; }</style>
   </head>
   <body>
     <h1>🚀 Mi Aplicación Web</h1>
     <button onclick="fetchInfo()">Obtener Info del Servidor</button>
     <div id="info"></div>
     
     <script>
       function fetchInfo() {
         fetch('/api/info')
           .then(response => response.json())
           .then(data => {
             document.getElementById('info').innerHTML = 
               '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
           });
       }
     </script>
   </body>
   </html>
   EOF
   ```

2. **Crear Dockerfile**
   ```bash
   cat << 'EOF' > Dockerfile
   FROM node:18-alpine
   
   WORKDIR /app
   
   COPY package.json .
   RUN npm install
   
   COPY . .
   
   EXPOSE 3000
   
   USER node
   
   CMD ["npm", "start"]
   EOF
   ```

3. **Construir y ejecutar**
   ```bash
   # Construir imagen
   docker build -t mi-web-app:1.0 .
   
   # Ejecutar aplicación
   docker run -d --name mi-app -p 3000:3000 mi-web-app:1.0
   
   # Probar aplicación
   curl http://localhost:3000/api/info
   # Abrir navegador: http://localhost:3000
   ```

### **Verificación:**
- [ ] Creaste aplicación Node.js funcional
- [ ] Construiste imagen Docker personalizada
- [ ] Desplegaste aplicación accesible desde el navegador

---

## 🟡 Ejercicio 5: Base de Datos

### **Objetivo**: Gestionar base de datos con persistencia

**Tiempo estimado**: 25 minutos

### **Tareas:**

1. **Desplegar PostgreSQL**
   ```bash
   # Crear volumen para datos
   docker volume create postgres-data
   
   # Ejecutar PostgreSQL
   docker run -d --name mi-postgres \
     -e POSTGRES_DB=mi_tienda \
     -e POSTGRES_USER=admin \
     -e POSTGRES_PASSWORD=mi_password \
     -v postgres-data:/var/lib/postgresql/data \
     -p 5432:5432 \
     postgres:15
   
   # Esperar que arranque
   sleep 10
   ```

2. **Crear esquema de base de datos**
   ```bash
   # Conectar y crear tablas
   docker exec -it mi-postgres psql -U admin -d mi_tienda
   
   # Dentro de psql:
   CREATE TABLE productos (
     id SERIAL PRIMARY KEY,
     nombre VARCHAR(100) NOT NULL,
     precio DECIMAL(10,2) NOT NULL,
     categoria VARCHAR(50),
     stock INTEGER DEFAULT 0,
     fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   
   INSERT INTO productos (nombre, precio, categoria, stock) VALUES
   ('Laptop Dell', 1299.99, 'Electrónicos', 15),
   ('Mouse Logitech', 29.99, 'Accesorios', 50),
   ('Teclado Mecánico', 159.99, 'Accesorios', 25),
   ('Monitor 24"', 299.99, 'Electrónicos', 8);
   
   SELECT * FROM productos;
   \q
   ```

3. **Probar persistencia**
   ```bash
   # Detener contenedor
   docker stop mi-postgres
   
   # Eliminar contenedor (pero no el volumen)
   docker rm mi-postgres
   
   # Crear nuevo contenedor con mismo volumen
   docker run -d --name postgres-nuevo \
     -e POSTGRES_DB=mi_tienda \
     -e POSTGRES_USER=admin \
     -e POSTGRES_PASSWORD=mi_password \
     -v postgres-data:/var/lib/postgresql/data \
     -p 5432:5432 \
     postgres:15
   
   sleep 10
   
   # Verificar que los datos persisten
   docker exec postgres-nuevo psql -U admin -d mi_tienda -c "SELECT * FROM productos;"
   ```

4. **Backup y restore**
   ```bash
   # Crear backup
   docker exec postgres-nuevo pg_dump -U admin mi_tienda > backup.sql
   
   # Verificar backup
   head -20 backup.sql
   ```

### **Verificación:**
- [ ] Desplegaste PostgreSQL con volumen persistente
- [ ] Creaste esquema y datos de prueba
- [ ] Verificaste persistencia tras recrear contenedor
- [ ] Realizaste backup de la base de datos

---

## 🟡 Ejercicio 6: Redes Personalizadas

### **Objetivo**: Configurar comunicación entre servicios

**Tiempo estimado**: 30 minutos

### **Tareas:**

1. **Crear redes aisladas**
   ```bash
   # Red para frontend
   docker network create frontend-net
   
   # Red para backend  
   docker network create backend-net
   
   # Verificar redes
   docker network ls
   ```

2. **Desplegar servicios en redes específicas**
   ```bash
   # Base de datos en red backend
   docker run -d --name db \
     --network backend-net \
     -e POSTGRES_DB=app_db \
     -e POSTGRES_USER=app_user \
     -e POSTGRES_PASSWORD=app_pass \
     postgres:15
   
   # API en ambas redes
   docker run -d --name api \
     --network backend-net \
     -p 5000:5000 \
     -e DATABASE_URL=postgresql://app_user:app_pass@db:5432/app_db \
     # Usaríamos una imagen de API aquí
     nginx
   
   docker network connect frontend-net api
   
   # Frontend solo en red frontend
   docker run -d --name frontend \
     --network frontend-net \
     -p 8080:80 \
     nginx
   ```

3. **Probar conectividad y aislamiento**
   ```bash
   # El frontend puede llegar a la API
   docker exec frontend ping -c 2 api
   
   # El frontend NO puede llegar directamente a la DB
   docker exec frontend ping -c 2 db
   # Esto debe fallar
   
   # La API SÍ puede llegar a la DB
   docker exec api ping -c 2 db
   ```

4. **Aplicación práctica con Nginx proxy**
   ```bash
   # Crear configuración de Nginx
   mkdir ~/ejercicio-redes
   cd ~/ejercicio-redes
   
   cat << 'EOF' > nginx.conf
   events {
       worker_connections 1024;
   }
   
   http {
       upstream backend {
           server api:5000;
       }
       
       server {
           listen 80;
           
           location / {
               root /usr/share/nginx/html;
               index index.html;
           }
           
           location /api/ {
               proxy_pass http://backend/;
           }
       }
   }
   EOF
   
   cat << 'EOF' > index.html
   <h1>Frontend con Proxy</h1>
   <p>Este frontend puede comunicarse con el backend a través de la red.</p>
   EOF
   
   # Actualizar frontend con configuración
   docker stop frontend
   docker rm frontend
   
   docker run -d --name frontend \
     --network frontend-net \
     -p 8080:80 \
     -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf \
     -v $(pwd)/index.html:/usr/share/nginx/html/index.html \
     nginx
   ```

### **Verificación:**
- [ ] Creaste redes personalizadas
- [ ] Configuraste servicios en redes específicas
- [ ] Verificaste aislamiento entre redes
- [ ] Implementaste comunicación controlada entre servicios

---

## 🔴 Ejercicio 7: Multi-Container App

### **Objetivo**: Orquestar aplicación completa manualmente

**Tiempo estimado**: 45 minutos

### **Tareas:**

1. **Diseñar arquitectura**
   ```
   [Load Balancer] -> [Frontend] -> [API] -> [Database]
                                   |
                                   v
                               [Redis Cache]
   ```

2. **Preparar aplicación API**
   ```bash
   mkdir ~/ejercicio-multi-app
   cd ~/ejercicio-multi-app
   
   # Crear API con Flask
   cat << 'EOF' > app.py
   from flask import Flask, jsonify, request
   import psycopg2
   import redis
   import json
   import os
   from datetime import datetime
   
   app = Flask(__name__)
   
   # Configuración
   DB_HOST = os.environ.get('DB_HOST', 'localhost')
   REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
   
   def get_db():
       return psycopg2.connect(
           host=DB_HOST,
           database='shop_db',
           user='shop_user',
           password='shop_pass'
       )
   
   def get_redis():
       return redis.Redis(host=REDIS_HOST, port=6379, decode_responses=True)
   
   @app.route('/health')
   def health():
       try:
           db = get_db()
           db.close()
           r = get_redis()
           r.ping()
           return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})
       except Exception as e:
           return jsonify({'status': 'unhealthy', 'error': str(e)}), 500
   
   @app.route('/products')
   def get_products():
       try:
           r = get_redis()
           cached = r.get('products')
           if cached:
               return jsonify(json.loads(cached))
           
           db = get_db()
           cursor = db.cursor()
           cursor.execute('SELECT id, name, price FROM products')
           products = [{'id': row[0], 'name': row[1], 'price': float(row[2])} for row in cursor.fetchall()]
           db.close()
           
           # Cache por 5 minutos
           r.setex('products', 300, json.dumps(products))
           
           return jsonify(products)
       except Exception as e:
           return jsonify({'error': str(e)}), 500
   
   @app.route('/stats')
   def get_stats():
       try:
           r = get_redis()
           visits = r.incr('page_visits')
           return jsonify({'visits': visits, 'server': os.environ.get('HOSTNAME', 'unknown')})
       except Exception as e:
           return jsonify({'error': str(e)}), 500
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   EOF
   
   cat << 'EOF' > requirements.txt
   Flask==2.3.3
   psycopg2-binary==2.9.7
   redis==4.6.0
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
   
   # Construir imagen
   docker build -t shop-api:1.0 .
   ```

3. **Crear redes y volúmenes**
   ```bash
   # Redes
   docker network create shop-frontend
   docker network create shop-backend
   docker network create shop-cache
   
   # Volúmenes
   docker volume create shop-db-data
   docker volume create shop-redis-data
   ```

4. **Desplegar servicios en orden**
   ```bash
   # 1. Base de datos
   docker run -d --name shop-db \
     --network shop-backend \
     -v shop-db-data:/var/lib/postgresql/data \
     -e POSTGRES_DB=shop_db \
     -e POSTGRES_USER=shop_user \
     -e POSTGRES_PASSWORD=shop_pass \
     postgres:15
   
   # 2. Cache Redis
   docker run -d --name shop-redis \
     --network shop-cache \
     -v shop-redis-data:/data \
     redis:7.0-alpine
   
   # 3. API (conectada a backend y cache)
   docker run -d --name shop-api-1 \
     --network shop-backend \
     -e DB_HOST=shop-db \
     -e REDIS_HOST=shop-redis \
     shop-api:1.0
   
   docker network connect shop-cache shop-api-1
   docker network connect shop-frontend shop-api-1
   
   # 4. Segundo API para load balancing
   docker run -d --name shop-api-2 \
     --network shop-backend \
     -e DB_HOST=shop-db \
     -e REDIS_HOST=shop-redis \
     shop-api:1.0
   
   docker network connect shop-cache shop-api-2
   docker network connect shop-frontend shop-api-2
   
   # 5. Load Balancer con Nginx
   cat << 'EOF' > nginx-lb.conf
   events { worker_connections 1024; }
   
   http {
       upstream api_servers {
           server shop-api-1:5000;
           server shop-api-2:5000;
       }
       
       server {
           listen 80;
           
           location /api/ {
               proxy_pass http://api_servers/;
               proxy_set_header Host $host;
               proxy_set_header X-Real-IP $remote_addr;
           }
           
           location / {
               root /usr/share/nginx/html;
               index index.html;
           }
       }
   }
   EOF
   
   cat << 'EOF' > frontend.html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Shop App</title>
       <style>
           body { font-family: Arial; margin: 40px; }
           .product { border: 1px solid #ccc; margin: 10px; padding: 15px; }
           button { padding: 10px; margin: 5px; background: #007bff; color: white; border: none; cursor: pointer; }
       </style>
   </head>
   <body>
       <h1>🛒 Multi-Container Shop</h1>
       
       <button onclick="checkHealth()">Health Check</button>
       <button onclick="loadProducts()">Load Products</button>
       <button onclick="getStats()">Get Stats</button>
       
       <div id="content"></div>
       
       <script>
           function checkHealth() {
               fetch('/api/health')
                   .then(r => r.json())
                   .then(data => display(data));
           }
           
           function loadProducts() {
               fetch('/api/products')
                   .then(r => r.json())
                   .then(data => display(data));
           }
           
           function getStats() {
               fetch('/api/stats')
                   .then(r => r.json())
                   .then(data => display(data));
           }
           
           function display(data) {
               document.getElementById('content').innerHTML = 
                   '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
           }
       </script>
   </body>
   </html>
   EOF
   
   docker run -d --name shop-frontend \
     --network shop-frontend \
     -p 8080:80 \
     -v $(pwd)/nginx-lb.conf:/etc/nginx/nginx.conf \
     -v $(pwd)/frontend.html:/usr/share/nginx/html/index.html \
     nginx
   ```

5. **Inicializar datos**
   ```bash
   # Esperar que arranque PostgreSQL
   sleep 15
   
   # Crear tabla y datos
   docker exec shop-db psql -U shop_user -d shop_db -c "
   CREATE TABLE products (
       id SERIAL PRIMARY KEY,
       name VARCHAR(100),
       price DECIMAL(10,2)
   );
   
   INSERT INTO products (name, price) VALUES
   ('Laptop Gaming', 1599.99),
   ('Smartphone Pro', 899.99),
   ('Tablet Ultra', 549.99),
   ('Smartwatch', 299.99);
   "
   ```

6. **Probar aplicación completa**
   ```bash
   # Health check
   curl http://localhost:8080/api/health
   
   # Productos (primera vez desde DB, segunda desde cache)
   curl http://localhost:8080/api/products
   curl http://localhost:8080/api/products
   
   # Stats con load balancing
   curl http://localhost:8080/api/stats
   curl http://localhost:8080/api/stats
   curl http://localhost:8080/api/stats
   
   # Navegador: http://localhost:8080
   ```

### **Verificación:**
- [ ] Desplegaste aplicación multi-container
- [ ] Implementaste load balancing
- [ ] Configuraste caching con Redis
- [ ] Verificaste comunicación entre todos los servicios

---

## 🔴 Ejercicio 8: Microservicios

### **Objetivo**: Implementar arquitectura de microservicios

**Tiempo estimado**: 40 minutos

### **Tareas:**

1. **Diseñar microservicios**
   - User Service (gestión de usuarios)
   - Product Service (catálogo de productos)
   - Order Service (procesamiento de pedidos)
   - API Gateway (enrutamiento)

2. **Implementar servicios**
   ```bash
   mkdir ~/ejercicio-microservicios
   cd ~/ejercicio-microservicios
   
   # User Service
   mkdir user-service
   cd user-service
   
   cat << 'EOF' > app.py
   from flask import Flask, jsonify, request
   import json
   
   app = Flask(__name__)
   
   users = [
       {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'},
       {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'}
   ]
   
   @app.route('/users', methods=['GET'])
   def get_users():
       return jsonify(users)
   
   @app.route('/users/<int:user_id>', methods=['GET'])
   def get_user(user_id):
       user = next((u for u in users if u['id'] == user_id), None)
       if user:
           return jsonify(user)
       return jsonify({'error': 'User not found'}), 404
   
   @app.route('/health')
   def health():
       return jsonify({'service': 'user-service', 'status': 'healthy'})
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   EOF
   
   cat << 'EOF' > Dockerfile
   FROM python:3.11-slim
   WORKDIR /app
   RUN pip install Flask==2.3.3
   COPY app.py .
   EXPOSE 5000
   CMD ["python", "app.py"]
   EOF
   
   docker build -t user-service:1.0 .
   cd ..
   
   # Product Service
   mkdir product-service
   cd product-service
   
   cat << 'EOF' > app.py
   from flask import Flask, jsonify, request
   import json
   
   app = Flask(__name__)
   
   products = [
       {'id': 1, 'name': 'Laptop', 'price': 999.99, 'stock': 10},
       {'id': 2, 'name': 'Mouse', 'price': 29.99, 'stock': 50},
       {'id': 3, 'name': 'Keyboard', 'price': 79.99, 'stock': 25}
   ]
   
   @app.route('/products', methods=['GET'])
   def get_products():
       return jsonify(products)
   
   @app.route('/products/<int:product_id>', methods=['GET'])
   def get_product(product_id):
       product = next((p for p in products if p['id'] == product_id), None)
       if product:
           return jsonify(product)
       return jsonify({'error': 'Product not found'}), 404
   
   @app.route('/health')
   def health():
       return jsonify({'service': 'product-service', 'status': 'healthy'})
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   EOF
   
   cat << 'EOF' > Dockerfile
   FROM python:3.11-slim
   WORKDIR /app
   RUN pip install Flask==2.3.3
   COPY app.py .
   EXPOSE 5000
   CMD ["python", "app.py"]
   EOF
   
   docker build -t product-service:1.0 .
   cd ..
   
   # Order Service
   mkdir order-service
   cd order-service
   
   cat << 'EOF' > app.py
   from flask import Flask, jsonify, request
   import requests
   import json
   from datetime import datetime
   
   app = Flask(__name__)
   
   orders = []
   order_counter = 1
   
   @app.route('/orders', methods=['POST'])
   def create_order():
       global order_counter
       data = request.get_json()
       
       # Validar usuario
       try:
           user_response = requests.get(f"http://user-service:5000/users/{data['user_id']}")
           if user_response.status_code != 200:
               return jsonify({'error': 'Invalid user'}), 400
       except:
           return jsonify({'error': 'User service unavailable'}), 503
       
       # Validar productos
       try:
           for item in data['items']:
               product_response = requests.get(f"http://product-service:5000/products/{item['product_id']}")
               if product_response.status_code != 200:
                   return jsonify({'error': f'Invalid product {item["product_id"]}'}), 400
       except:
           return jsonify({'error': 'Product service unavailable'}), 503
       
       order = {
           'id': order_counter,
           'user_id': data['user_id'],
           'items': data['items'],
           'created_at': datetime.now().isoformat(),
           'status': 'created'
       }
       orders.append(order)
       order_counter += 1
       
       return jsonify(order), 201
   
   @app.route('/orders', methods=['GET'])
   def get_orders():
       return jsonify(orders)
   
   @app.route('/health')
   def health():
       return jsonify({'service': 'order-service', 'status': 'healthy'})
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   EOF
   
   cat << 'EOF' > Dockerfile
   FROM python:3.11-slim
   WORKDIR /app
   RUN pip install Flask==2.3.3 requests==2.31.0
   COPY app.py .
   EXPOSE 5000
   CMD ["python", "app.py"]
   EOF
   
   docker build -t order-service:1.0 .
   cd ..
   ```

3. **Implementar API Gateway**
   ```bash
   mkdir api-gateway
   cd api-gateway
   
   cat << 'EOF' > nginx.conf
   events { worker_connections 1024; }
   
   http {
       server {
           listen 80;
           
           location /api/users/ {
               proxy_pass http://user-service:5000/;
               proxy_set_header Host $host;
           }
           
           location /api/products/ {
               proxy_pass http://product-service:5000/;
               proxy_set_header Host $host;
           }
           
           location /api/orders/ {
               proxy_pass http://order-service:5000/;
               proxy_set_header Host $host;
           }
           
           location / {
               root /usr/share/nginx/html;
               index index.html;
           }
       }
   }
   EOF
   
   cat << 'EOF' > index.html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Microservices App</title>
       <style>
           body { font-family: Arial; margin: 40px; }
           .section { margin: 20px 0; padding: 20px; border: 1px solid #ddd; }
           button { padding: 10px; margin: 5px; background: #007bff; color: white; border: none; cursor: pointer; }
           textarea { width: 100%; height: 100px; }
       </style>
   </head>
   <body>
       <h1>🏗️ Microservices Demo</h1>
       
       <div class="section">
           <h2>Users</h2>
           <button onclick="getUsers()">Get Users</button>
           <button onclick="getUser(1)">Get User 1</button>
       </div>
       
       <div class="section">
           <h2>Products</h2>
           <button onclick="getProducts()">Get Products</button>
           <button onclick="getProduct(1)">Get Product 1</button>
       </div>
       
       <div class="section">
           <h2>Orders</h2>
           <button onclick="getOrders()">Get Orders</button>
           <button onclick="createOrder()">Create Order</button>
           <textarea id="orderData" placeholder="Order JSON">
   {
     "user_id": 1,
     "items": [
       {"product_id": 1, "quantity": 1},
       {"product_id": 2, "quantity": 2}
     ]
   }</textarea>
       </div>
       
       <div class="section">
           <h2>Health Checks</h2>
           <button onclick="checkHealth('users')">User Service</button>
           <button onclick="checkHealth('products')">Product Service</button>
           <button onclick="checkHealth('orders')">Order Service</button>
       </div>
       
       <div id="result" style="margin-top: 20px; padding: 20px; background: #f8f9fa;"></div>
       
       <script>
           function getUsers() { fetch('/api/users/users').then(r => r.json()).then(display); }
           function getUser(id) { fetch(`/api/users/users/${id}`).then(r => r.json()).then(display); }
           function getProducts() { fetch('/api/products/products').then(r => r.json()).then(display); }
           function getProduct(id) { fetch(`/api/products/products/${id}`).then(r => r.json()).then(display); }
           function getOrders() { fetch('/api/orders/orders').then(r => r.json()).then(display); }
           function checkHealth(service) { fetch(`/api/${service}/health`).then(r => r.json()).then(display); }
           
           function createOrder() {
               const data = document.getElementById('orderData').value;
               fetch('/api/orders/orders', {
                   method: 'POST',
                   headers: {'Content-Type': 'application/json'},
                   body: data
               }).then(r => r.json()).then(display);
           }
           
           function display(data) {
               document.getElementById('result').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
           }
       </script>
   </body>
   </html>
   EOF
   
   cd ..
   ```

4. **Desplegar microservicios**
   ```bash
   # Crear red
   docker network create microservices-net
   
   # Desplegar servicios
   docker run -d --name user-service \
     --network microservices-net \
     user-service:1.0
   
   docker run -d --name product-service \
     --network microservices-net \
     product-service:1.0
   
   docker run -d --name order-service \
     --network microservices-net \
     order-service:1.0
   
   # API Gateway
   docker run -d --name api-gateway \
     --network microservices-net \
     -p 8080:80 \
     -v $(pwd)/api-gateway/nginx.conf:/etc/nginx/nginx.conf \
     -v $(pwd)/api-gateway/index.html:/usr/share/nginx/html/index.html \
     nginx
   ```

5. **Probar microservicios**
   ```bash
   # Health checks
   curl http://localhost:8080/api/users/health
   curl http://localhost:8080/api/products/health
   curl http://localhost:8080/api/orders/health
   
   # Datos
   curl http://localhost:8080/api/users/users
   curl http://localhost:8080/api/products/products
   
   # Crear pedido
   curl -X POST http://localhost:8080/api/orders/orders \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": 1,
       "items": [
         {"product_id": 1, "quantity": 1},
         {"product_id": 2, "quantity": 2}
       ]
     }'
   
   # Ver pedidos
   curl http://localhost:8080/api/orders/orders
   ```

### **Verificación:**
- [ ] Implementaste 3 microservicios independientes
- [ ] Configuraste API Gateway con enrutamiento
- [ ] Verificaste comunicación entre servicios
- [ ] Creaste pedido que valida datos en múltiples servicios

---

## 🔴 Ejercicio 9: DevOps Pipeline

### **Objetivo**: Simular pipeline de CI/CD con contenedores

**Tiempo estimado**: 35 minutos

### **Tareas:**

1. **Crear aplicación con tests**
   ```bash
   mkdir ~/ejercicio-devops-pipeline
   cd ~/ejercicio-devops-pipeline
   
   cat << 'EOF' > app.py
   from flask import Flask, jsonify
   import os
   
   app = Flask(__name__)
   
   @app.route('/')
   def home():
       return jsonify({
           'message': 'Hello DevOps!',
           'version': os.environ.get('VERSION', '1.0.0'),
           'environment': os.environ.get('ENVIRONMENT', 'development')
       })
   
   @app.route('/health')
   def health():
       return jsonify({'status': 'healthy'})
   
   def add_numbers(a, b):
       return a + b
   
   def multiply_numbers(a, b):
       return a * b
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   EOF
   
   cat << 'EOF' > test_app.py
   import unittest
   from app import app, add_numbers, multiply_numbers
   
   class TestApp(unittest.TestCase):
       def setUp(self):
           self.client = app.test_client()
   
       def test_home_endpoint(self):
           response = self.client.get('/')
           self.assertEqual(response.status_code, 200)
           data = response.get_json()
           self.assertIn('message', data)
   
       def test_health_endpoint(self):
           response = self.client.get('/health')
           self.assertEqual(response.status_code, 200)
           data = response.get_json()
           self.assertEqual(data['status'], 'healthy')
   
       def test_add_numbers(self):
           self.assertEqual(add_numbers(2, 3), 5)
           self.assertEqual(add_numbers(-1, 1), 0)
   
       def test_multiply_numbers(self):
           self.assertEqual(multiply_numbers(3, 4), 12)
           self.assertEqual(multiply_numbers(0, 5), 0)
   
   if __name__ == '__main__':
       unittest.main()
   EOF
   
   cat << 'EOF' > requirements.txt
   Flask==2.3.3
   EOF
   ```

2. **Crear Dockerfiles para diferentes etapas**
   ```bash
   # Dockerfile para testing
   cat << 'EOF' > Dockerfile.test
   FROM python:3.11-slim
   
   WORKDIR /app
   
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   
   COPY . .
   
   # Ejecutar tests
   CMD ["python", "-m", "unittest", "test_app.py", "-v"]
   EOF
   
   # Dockerfile para producción
   cat << 'EOF' > Dockerfile.prod
   FROM python:3.11-slim
   
   RUN useradd --create-home --shell /bin/bash appuser
   
   WORKDIR /app
   
   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt
   
   COPY app.py .
   
   RUN chown -R appuser:appuser /app
   USER appuser
   
   EXPOSE 5000
   
   HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
     CMD curl -f http://localhost:5000/health || exit 1
   
   CMD ["python", "app.py"]
   EOF
   ```

3. **Pipeline Script**
   ```bash
   cat << 'EOF' > pipeline.sh
   #!/bin/bash
   
   set -e
   
   echo "🚀 Starting DevOps Pipeline..."
   
   # Configuración
   APP_NAME="devops-app"
   VERSION=${1:-"1.0.0"}
   ENVIRONMENT=${2:-"staging"}
   
   echo "📦 Building test image..."
   docker build -f Dockerfile.test -t ${APP_NAME}:test .
   
   echo "🧪 Running tests..."
   docker run --rm ${APP_NAME}:test
   
   if [ $? -eq 0 ]; then
       echo "✅ Tests passed!"
   else
       echo "❌ Tests failed!"
       exit 1
   fi
   
   echo "🏗️ Building production image..."
   docker build -f Dockerfile.prod -t ${APP_NAME}:${VERSION} .
   
   echo "🏷️ Tagging images..."
   docker tag ${APP_NAME}:${VERSION} ${APP_NAME}:latest
   docker tag ${APP_NAME}:${VERSION} ${APP_NAME}:${ENVIRONMENT}
   
   echo "🔍 Security scan (simulated)..."
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     --name security-scan \
     alpine:latest sh -c "
       echo 'Scanning ${APP_NAME}:${VERSION}...'
       echo '✅ No critical vulnerabilities found'
       echo '⚠️  2 medium-severity issues found'
       echo '🔒 Security scan completed'
     "
   
   echo "🚀 Deploying to ${ENVIRONMENT}..."
   
   # Detener versión anterior si existe
   docker stop ${APP_NAME}-${ENVIRONMENT} 2>/dev/null || true
   docker rm ${APP_NAME}-${ENVIRONMENT} 2>/dev/null || true
   
   # Desplegar nueva versión
   if [ "$ENVIRONMENT" = "production" ]; then
       PORT=8080
   else
       PORT=8081
   fi
   
   docker run -d \
     --name ${APP_NAME}-${ENVIRONMENT} \
     -p ${PORT}:5000 \
     -e VERSION=${VERSION} \
     -e ENVIRONMENT=${ENVIRONMENT} \
     --restart unless-stopped \
     ${APP_NAME}:${VERSION}
   
   echo "⏳ Waiting for application to start..."
   sleep 5
   
   echo "🩺 Health check..."
   curl -f http://localhost:${PORT}/health
   
   if [ $? -eq 0 ]; then
       echo "✅ Deployment successful!"
       echo "🌐 Application available at: http://localhost:${PORT}"
   else
       echo "❌ Health check failed!"
       exit 1
   fi
   
   echo "📊 Deployment summary:"
   echo "  - Application: ${APP_NAME}"
   echo "  - Version: ${VERSION}"
   echo "  - Environment: ${ENVIRONMENT}"
   echo "  - Port: ${PORT}"
   
   docker images | grep ${APP_NAME}
   
   echo "🎉 Pipeline completed successfully!"
   EOF
   
   chmod +x pipeline.sh
   ```

4. **Ejecutar pipeline**
   ```bash
   # Pipeline para staging
   ./pipeline.sh 1.0.0 staging
   
   # Probar aplicación en staging
   curl http://localhost:8081/
   curl http://localhost:8081/health
   
   # Pipeline para production
   ./pipeline.sh 1.0.1 production
   
   # Probar aplicación en production
   curl http://localhost:8080/
   curl http://localhost:8080/health
   ```

5. **Monitoreo y logs**
   ```bash
   # Ver logs de aplicaciones
   docker logs devops-app-staging
   docker logs devops-app-production
   
   # Monitorear en tiempo real
   docker stats devops-app-staging devops-app-production
   
   # Simular load testing
   for i in {1..10}; do
     curl -s http://localhost:8080/ > /dev/null &
     curl -s http://localhost:8081/ > /dev/null &
   done
   wait
   
   echo "Load test completed"
   ```

6. **Rollback procedure**
   ```bash
   cat << 'EOF' > rollback.sh
   #!/bin/bash
   
   APP_NAME="devops-app"
   ENVIRONMENT=${1:-"staging"}
   PREVIOUS_VERSION=${2:-"1.0.0"}
   
   echo "🔄 Rolling back ${ENVIRONMENT} to version ${PREVIOUS_VERSION}..."
   
   # Detener versión actual
   docker stop ${APP_NAME}-${ENVIRONMENT}
   docker rm ${APP_NAME}-${ENVIRONMENT}
   
   # Determinar puerto
   if [ "$ENVIRONMENT" = "production" ]; then
       PORT=8080
   else
       PORT=8081
   fi
   
   # Desplegar versión anterior
   docker run -d \
     --name ${APP_NAME}-${ENVIRONMENT} \
     -p ${PORT}:5000 \
     -e VERSION=${PREVIOUS_VERSION} \
     -e ENVIRONMENT=${ENVIRONMENT} \
     --restart unless-stopped \
     ${APP_NAME}:${PREVIOUS_VERSION}
   
   echo "✅ Rollback completed!"
   EOF
   
   chmod +x rollback.sh
   
   # Probar rollback
   ./rollback.sh staging 1.0.0
   curl http://localhost:8081/
   ```

### **Verificación:**
- [ ] Creaste pipeline automatizado con tests
- [ ] Implementaste despliegue multi-ambiente
- [ ] Configuraste health checks automáticos
- [ ] Probaste procedimiento de rollback

---

## 🎯 Evaluación Final

### **Checklist de Competencias**

**Básico (🟢)**
- [ ] Ejecutar y gestionar contenedores
- [ ] Construir imágenes personalizadas
- [ ] Configurar volúmenes para persistencia
- [ ] Mapear puertos y acceder a servicios

**Intermedio (🟡)**
- [ ] Crear redes personalizadas
- [ ] Implementar comunicación entre contenedores
- [ ] Gestionar múltiples servicios
- [ ] Realizar troubleshooting básico

**Avanzado (🔴)**
- [ ] Diseñar arquitecturas multi-container
- [ ] Implementar load balancing
- [ ] Configurar pipelines de CI/CD
- [ ] Gestionar microservicios

### **Proyecto Final Integrador**

Combina todos los ejercicios en una sola aplicación que incluya:

1. **Frontend** (React/Angular/Vue)
2. **API Gateway** (Nginx)
3. **Microservicios** (mínimo 3)
4. **Base de datos** (PostgreSQL)
5. **Cache** (Redis)
6. **Monitoreo** (logs centralizados)
7. **CI/CD Pipeline** automatizado

---

## 🧹 Limpieza Global

```bash
#!/bin/bash
# cleanup-all.sh

echo "🧹 Limpiando todos los ejercicios..."

# Detener todos los contenedores
docker stop $(docker ps -q) 2>/dev/null

# Eliminar contenedores
docker rm $(docker ps -aq) 2>/dev/null

# Eliminar imágenes personalizadas
docker rmi $(docker images --filter "reference=*/*:*" -q) 2>/dev/null
docker rmi $(docker images --filter "reference=*:*" -q) 2>/dev/null

# Eliminar volúmenes
docker volume prune -f

# Eliminar redes
docker network prune -f

# Limpieza del sistema
docker system prune -a -f

echo "✅ Limpieza completada!"
```

---

**🎉 ¡Felicitaciones!** Has completado todos los ejercicios prácticos de Docker. Ahora tienes las habilidades necesarias para trabajar efectivamente con contenedores en proyectos reales.