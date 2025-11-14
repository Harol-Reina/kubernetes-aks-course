# 🚀 Lab 4: Init Container Migration Pattern

## 📋 Información del Laboratorio

- **Duración estimada**: 70 minutos
- **Nivel**: Avanzado
- **Prerrequisitos**:
  - Docker instalado
  - kubectl configurado
  - Cluster Kubernetes activo (minikube/kind)
  - Conocimientos de Python/Flask y PostgreSQL

## 🎯 Objetivo

Migrar un **setup complejo de Docker** (con múltiples contenedores de inicialización) a **Init Containers** de Kubernetes, demostrando:
- Orquestación automática de dependencias
- Setup secuencial garantizado
- Simplificación vs Docker tradicional

## 🧪 Práctica

### Paso 1: Entender el Problema - Setup Docker Tradicional

```bash
mkdir -p ~/labs/modulo-04/init-migration && cd ~/labs/modulo-04/init-migration

echo "🚀 INIT CONTAINER: Migration from Docker Setup"
echo "=============================================="
```

#### Problema: Docker Setup Complejo (ANTES)

```bash
cat > docker-setup.sh << 'EOF'
#!/bin/bash
echo "🐳 Docker Traditional Setup (Complex)"

# 1. Create network
docker network create app-setup

# 2. Database setup
docker run -d --name db --network app-setup \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=pass \
  postgres:13

# 3. Wait for DB (manual orchestration)
echo "⏳ Waiting for database..."
sleep 10

# 4. Run migrations (separate container)
docker run --rm --network app-setup \
  -e DATABASE_URL=postgres://user:pass@db:5432/myapp \
  migrate/migrate:v4.15.1 \
  -path /migrations -database postgres://user:pass@db:5432/myapp up

# 5. Seed data (another container)
docker run --rm --network app-setup \
  -e DATABASE_URL=postgres://user:pass@db:5432/myapp \
  my-seed-image:v1

# 6. Download assets (yet another container)  
docker run --rm -v $(pwd)/assets:/output \
  busybox wget -O /output/app.js https://cdn.example.com/app.js

# 7. Finally start main app
docker run -d --name app --network app-setup \
  -v $(pwd)/assets:/app/static \
  -e DATABASE_URL=postgres://user:pass@db:5432/myapp \
  my-app:v1

echo "❌ Problems with this approach:"
echo "├─ Manual orchestration"
echo "├─ Complex dependency management"  
echo "├─ Multiple network/volume setups"
echo "└─ Hard to reproduce consistently"
EOF

chmod +x docker-setup.sh
```

**❌ Problemas**:
- 7 pasos manuales
- Esperas hardcodeadas (`sleep 10`)
- Difícil de reproducir
- Sin manejo de errores

### Paso 2: Crear Aplicación Flask

```bash
cat > app.py << 'EOF'
from flask import Flask, jsonify
import os
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        database=os.environ.get('DB_NAME', 'myapp'),
        user=os.environ.get('DB_USER', 'user'),
        password=os.environ.get('DB_PASSWORD', 'pass')
    )

@app.route('/')
def home():
    return jsonify({
        'message': '🚀 App with Init Containers',
        'status': 'running',
        'setup_complete': os.path.exists('/app/setup/complete')
    })

@app.route('/data')
def data():
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT * FROM users LIMIT 5')
        users = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({'users': users})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/config')
def config():
    config_file = '/app/config/app.json'
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            import json
            config = json.load(f)
        return jsonify(config)
    return jsonify({'error': 'Config not found'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
```

### Paso 3: Crear Scripts de Inicialización

```bash
mkdir -p setup-scripts

# Script SQL para migraciones
cat > setup-scripts/migrate.sql << 'EOF'
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES 
('Alice Johnson', 'alice@example.com'),
('Bob Smith', 'bob@example.com'),
('Charlie Brown', 'charlie@example.com')
ON CONFLICT (email) DO NOTHING;
EOF

# Script para descargar configuración
cat > setup-scripts/download-config.sh << 'EOF'
#!/bin/sh
echo "📥 Downloading configuration..."
mkdir -p /app/config

# Simulate downloading config
cat > /app/config/app.json << 'CONFIG'
{
  "app_name": "My Application",
  "version": "1.0.0",
  "features": {
    "logging": true,
    "metrics": true,
    "debug": false
  },
  "database": {
    "pool_size": 10,
    "timeout": 30
  }
}
CONFIG

echo "✅ Configuration downloaded successfully"
echo "complete" > /app/setup/complete
EOF

chmod +x setup-scripts/download-config.sh
```

### Paso 4: Crear ConfigMaps

```bash
# ConfigMap para código de la aplicación
kubectl create configmap app-code --from-file=app.py

# ConfigMap para scripts de migración
kubectl create configmap migration-scripts --from-file=setup-scripts/migrate.sql

# ConfigMap para scripts de setup
kubectl create configmap setup-scripts --from-file=setup-scripts/download-config.sh
```

### Paso 5: Desplegar Base de Datos

```bash
cat > postgres-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: db
  labels:
    app: database
spec:
  containers:
  - name: postgres
    image: postgres:13
    ports:
    - containerPort: 5432
    env:
    - name: POSTGRES_DB
      value: myapp
    - name: POSTGRES_USER
      value: user
    - name: POSTGRES_PASSWORD
      value: pass

---
apiVersion: v1
kind: Service
metadata:
  name: db-service
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF

kubectl apply -f postgres-pod.yaml
kubectl wait --for=condition=Ready pod/db --timeout=60s
```

### Paso 6: Crear Pod con Init Containers (SOLUCIÓN)

```bash
cat > init-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: app-with-init
  labels:
    app: myapp
    pattern: init-containers
spec:
  # Init containers run sequentially BEFORE main containers
  initContainers:
  
  # Init 1: Wait for database to be ready
  - name: wait-for-db
    image: postgres:13
    command: ['sh', '-c']
    args:
      - |
        echo "⏳ Waiting for database to be ready..."
        until pg_isready -h db-service -p 5432 -U user; do
          echo "Database not ready, waiting..."
          sleep 2
        done
        echo "✅ Database is ready!"
    env:
    - name: PGPASSWORD
      value: "pass"
      
  # Init 2: Run database migrations
  - name: db-migration
    image: postgres:13
    command: ['sh', '-c']
    args:
      - |
        echo "🗄️ Running database migrations..."
        psql -h db-service -U user -d myapp -f /migrations/migrate.sql
        echo "✅ Migrations completed!"
    env:
    - name: PGPASSWORD
      value: "pass"
    volumeMounts:
    - name: migration-scripts
      mountPath: /migrations
      
  # Init 3: Download configuration
  - name: config-setup
    image: busybox
    command: ['/setup/download-config.sh']
    volumeMounts:
    - name: setup-scripts
      mountPath: /setup
    - name: app-config
      mountPath: /app/config
    - name: setup-status
      mountPath: /app/setup
      
  # Main application container (starts AFTER all init containers complete)
  containers:
  - name: app
    image: python:3.9-slim
    command: ['sh', '-c']
    args:
      - |
        pip install flask psycopg2-binary
        python /app/app.py
    ports:
    - containerPort: 5000
    env:
    - name: DB_HOST
      value: "db-service"
    - name: DB_NAME
      value: "myapp"
    - name: DB_USER
      value: "user"
    - name: DB_PASSWORD
      value: "pass"
    volumeMounts:
    - name: app-code
      mountPath: /app
    - name: app-config
      mountPath: /app/config
    - name: setup-status
      mountPath: /app/setup
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "500m"
        
  volumes:
  - name: app-code
    configMap:
      name: app-code
  - name: migration-scripts
    configMap:
      name: migration-scripts
  - name: setup-scripts
    configMap:
      name: setup-scripts
      defaultMode: 0755
  - name: app-config
    emptyDir: {}
  - name: setup-status
    emptyDir: {}
EOF
```

**✅ Ventajas de Init Containers**:
- **Secuencia automática**: wait-for-db → migrations → config
- **Retry automático**: Si falla, Kubernetes reintenta
- **Declarativo**: Un solo YAML describe todo el setup

### Paso 7: Desplegar Aplicación

```bash
kubectl apply -f init-pod.yaml
```

### Paso 8: Observar Secuencia de Inicialización

```bash
echo ""
echo "👀 OBSERVANDO SECUENCIA DE INIT CONTAINERS:"
echo "├─ Watching pod initialization..."

# Mostrar progreso de init containers
kubectl get pods app-with-init -w &
WATCH_PID=$!
sleep 20
kill $WATCH_PID 2>/dev/null
```

**🔍 Estados que verás**:
1. `Init:0/3` - Esperando primer init container
2. `Init:1/3` - wait-for-db completado
3. `Init:2/3` - db-migration completado
4. `Init:3/3` - config-setup completado
5. `Running` - Aplicación principal ejecutándose

### Paso 9: Verificar Logs de Init Containers

```bash
echo ""
echo "📋 LOGS DE INIT CONTAINERS:"

echo "--- Wait for DB ---"
kubectl logs app-with-init -c wait-for-db

echo ""
echo "--- DB Migration ---"
kubectl logs app-with-init -c db-migration

echo ""
echo "--- Config Setup ---"
kubectl logs app-with-init -c config-setup
```

### Paso 10: Verificar Aplicación Principal

```bash
echo ""
echo "--- Main Application ---"
kubectl logs app-with-init -c app
```

### Paso 11: Probar la Aplicación

```bash
kubectl wait --for=condition=Ready pod/app-with-init --timeout=120s
kubectl port-forward pod/app-with-init 8080:5000 &
sleep 3

echo ""
echo "🧪 TESTING APPLICATION:"
curl -s http://localhost:8080/ | jq
curl -s http://localhost:8080/data | jq
curl -s http://localhost:8080/config | jq

kill %1 2>/dev/null
```

**✅ Respuestas esperadas**:
- `/`: `{"message": "🚀 App with Init Containers", "setup_complete": true}`
- `/data`: Lista de usuarios de la BD
- `/config`: Configuración descargada por init container

## 📊 Comparación Docker vs Init Containers

```
┌──────────────────────┬────────────────────┬──────────────────────┐
│     Característica   │  Docker Setup      │  Init Containers     │
├──────────────────────┼────────────────────┼──────────────────────┤
│  Orquestación        │  ❌ Manual         │  ✅ Automática       │
│  Dependencias        │  ❌ Scripts bash   │  ✅ Declarativas     │
│  Retry en failure    │  ❌ Manual         │  ✅ Automático       │
│  Reproducibilidad    │  ❌ Baja           │  ✅ Alta             │
│  Configuración       │  ❌ Multi-archivo  │  ✅ Single YAML      │
│  Error handling      │  ❌ Manual         │  ✅ Built-in         │
└──────────────────────┴────────────────────┴──────────────────────┘
```

## 📐 Diagrama de Secuencia

```
┌─────────────────────────────────────────────────────────────┐
│                 Pod Initialization Sequence                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Init: wait-for-db                                       │
│     ├─ pg_isready check                                     │
│     └─ ✅ DB Ready                                          │
│                                                             │
│  2. Init: db-migration                                      │
│     ├─ Execute SQL migrations                               │
│     ├─ Create users table                                   │
│     └─ ✅ Migrations Complete                               │
│                                                             │
│  3. Init: config-setup                                      │
│     ├─ Download configuration                               │
│     ├─ Write to /app/config                                 │
│     └─ ✅ Config Ready                                      │
│                                                             │
│  4. Main Container: app                                     │
│     ├─ pip install dependencies                             │
│     ├─ Start Flask server                                   │
│     └─ 🚀 App Running                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## ✅ Beneficios de Init Containers

```
✅ INIT CONTAINER BENEFITS:
├─ 🔄 Sequential execution guaranteed
│   • wait-for-db → migrations → config → app
│   • No race conditions
│
├─ 🛠️ Setup separation from main app
│   • App código no contiene lógica de setup
│   • Clean separation of concerns
│
├─ 🎯 Single Pod = atomic deployment
│   • Un solo apply para todo
│   • Rollback simple
│
├─ 📋 Declarative dependency management
│   • YAML describe toda la secuencia
│   • No bash scripts
│
├─ 🔁 Automatic retry on failure
│   • Kubernetes reintenta init containers
│   • Sin intervención manual
│
└─ 🧹 Clean resource management
    • Init containers se eliminan después
    • No consumen recursos después de completar
```

## 🧹 Limpieza

```bash
# Detener port-forward
killall kubectl 2>/dev/null

# Eliminar recursos
kubectl delete pod app-with-init db
kubectl delete service db-service
kubectl delete configmap app-code migration-scripts setup-scripts

# Limpiar archivos locales
cd ~
rm -rf ~/labs/modulo-04/init-migration
```

## 🎓 Conceptos Clave Aprendidos

1. **Init Containers** ejecutan secuencialmente ANTES de la app principal
2. **Orquestación declarativa** vs scripts bash imperativos
3. **Retry automático** de Kubernetes para init containers
4. **Separación de responsabilidades**: setup vs runtime
5. **Single Pod deployment** simplifica gestión

## 🚀 Casos de Uso Adicionales

### 1. Wait for Multiple Services

```yaml
initContainers:
- name: wait-for-services
  image: busybox
  command: ['sh', '-c']
  args:
    - |
      until nslookup redis-service && nslookup db-service; do
        echo "Waiting for services..."
        sleep 2
      done
```

### 2. Download Large Assets

```yaml
initContainers:
- name: download-assets
  image: busybox
  command: ['sh', '-c']
  args: ['wget -O /assets/app.js https://cdn.example.com/app.js']
  volumeMounts:
  - name: assets
    mountPath: /assets
```

### 3. Security Setup

```yaml
initContainers:
- name: setup-permissions
  image: busybox
  command: ['sh', '-c']
  args: ['chown -R 1000:1000 /data && chmod 755 /data']
  volumeMounts:
  - name: data
    mountPath: /data
```

## 📚 Referencias

- [Init Containers - Kubernetes Docs](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [PostgreSQL in Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-initialization/)

## ⏭️ Siguiente Paso

Continúa con **[Lab 5: Migración de Docker Compose](./lab-05-compose-migration.md)** para migrar una aplicación completa de docker-compose.yml a Kubernetes.
