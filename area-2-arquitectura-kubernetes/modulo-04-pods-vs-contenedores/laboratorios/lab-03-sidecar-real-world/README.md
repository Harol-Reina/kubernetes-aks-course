# 🏗️ Lab 3: Sidecar Pattern Real-World

## 📋 Información del Laboratorio

- **Duración estimada**: 60 minutos
- **Nivel**: Intermedio-Avanzado
- **Prerrequisitos**:
  - Docker instalado
  - kubectl configurado
  - Cluster Kubernetes activo (minikube/kind)
  - Conocimientos básicos de Python/Flask

## 🎯 Objetivo

Implementar un **sidecar de logging** real con:
- Aplicación web Flask que genera logs estructurados
- Sidecar Fluent Bit que procesa logs en tiempo real
- Comunicación vía shared volume (emptyDir)
- Separación de responsabilidades entre app y logging

## 🧪 Práctica

### Paso 1: Preparación del Entorno

```bash
mkdir -p ~/labs/modulo-04/sidecar-real && cd ~/labs/modulo-04/sidecar-real

echo "🏗️ SIDECAR PATTERN: Real-World Logging"
echo "======================================"
```

### Paso 2: Crear Aplicación Web Flask

```bash
# 1. Crear aplicación web que genera logs
cat > web-app.py << 'EOF'
from flask import Flask, request, jsonify
import logging
import json
import time
from datetime import datetime

app = Flask(__name__)

# Configurar logging para escribir JSON estructurado
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',
    handlers=[
        logging.FileHandler('/var/log/app/access.log'),
        logging.StreamHandler()
    ]
)

@app.route('/')
def home():
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'method': request.method,
        'path': request.path,
        'user_agent': request.headers.get('User-Agent'),
        'ip': request.remote_addr,
        'message': 'Home page accessed'
    }
    app.logger.info(json.dumps(log_entry))
    return jsonify({'message': '🏠 Welcome to Sidecar Demo', 'status': 'ok'})

@app.route('/api/users')
def users():
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'method': request.method,
        'path': request.path,
        'user_agent': request.headers.get('User-Agent'),
        'ip': request.remote_addr,
        'message': 'Users API accessed'
    }
    app.logger.info(json.dumps(log_entry))
    return jsonify([{'id': 1, 'name': 'Alice'}, {'id': 2, 'name': 'Bob'}])

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
```

**🔍 Características de la App**:
- Logs en formato **JSON estructurado**
- Escribe a `/var/log/app/access.log` (shared volume)
- 3 endpoints: `/`, `/api/users`, `/health`

### Paso 3: Crear Dockerfile para la Aplicación

```bash
cat > Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY web-app.py .
RUN pip install flask && mkdir -p /var/log/app
EXPOSE 5000
CMD ["python", "web-app.py"]
EOF
```

### Paso 4: Build de la Imagen

```bash
# Build imagen
docker build -t sidecar-webapp:v1 .

# (Opcional) Cargar en minikube si usas minikube
# minikube image load sidecar-webapp:v1
```

### Paso 5: Configurar Fluent Bit (Sidecar)

```bash
cat > fluent-bit.conf << 'EOF'
[SERVICE]
    Flush         1
    Log_Level     info
    Daemon        off

[INPUT]
    Name              tail
    Path              /var/log/app/access.log
    Tag               app.access
    Refresh_Interval  1
    Read_from_Head    true

[FILTER]
    Name   parser
    Match  app.access
    Key_Name log
    Parser json

[OUTPUT]
    Name   file
    Match  *
    Path   /var/log/processed/
    File   processed.log
    Format json_lines

[OUTPUT]
    Name   stdout
    Match  *
    Format json_lines
EOF
```

**🔍 Funciones de Fluent Bit**:
- **INPUT**: Lee `/var/log/app/access.log` (shared volume)
- **FILTER**: Parsea JSON
- **OUTPUT**: Escribe logs procesados y muestra en stdout

### Paso 6: Crear ConfigMap para Fluent Bit

```bash
kubectl create configmap fluent-config --from-file=fluent-bit.conf
```

### Paso 7: Crear Pod con Sidecar

```bash
cat > sidecar-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: webapp-sidecar
  labels:
    app: webapp
    pattern: sidecar
spec:
  containers:
  # Main application container
  - name: webapp
    image: sidecar-webapp:v1
    imagePullPolicy: Never  # Usar imagen local (minikube)
    ports:
    - containerPort: 5000
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/app
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
        
  # Sidecar container for log processing
  - name: log-processor
    image: fluent/fluent-bit:2.0
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/app
      readOnly: true
    - name: fluent-config
      mountPath: /fluent-bit/etc/fluent-bit.conf
      subPath: fluent-bit.conf
    - name: processed-logs
      mountPath: /var/log/processed
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "128Mi"
        cpu: "100m"
        
  volumes:
  - name: log-volume
    emptyDir: {}
  - name: processed-logs
    emptyDir: {}
  - name: fluent-config
    configMap:
      name: fluent-config
EOF
```

**🔍 Componentes del Pod**:
- **webapp**: Aplicación principal (genera logs)
- **log-processor**: Sidecar (procesa logs)
- **log-volume**: Shared emptyDir para logs
- **fluent-config**: ConfigMap con configuración

### Paso 8: Desplegar Pod

```bash
kubectl apply -f sidecar-pod.yaml
kubectl wait --for=condition=Ready pod/webapp-sidecar --timeout=120s
```

### Paso 9: Generar Tráfico

```bash
# Port forward
kubectl port-forward pod/webapp-sidecar 8080:5000 &
sleep 3

echo ""
echo "🚦 Generando tráfico para demostrar sidecar..."
curl -s http://localhost:8080/ | jq
curl -s http://localhost:8080/api/users | jq  
curl -s http://localhost:8080/health | jq
curl -s http://localhost:8080/
curl -s http://localhost:8080/api/users

sleep 5
```

### Paso 10: Verificar Logs Originales

```bash
echo ""
echo "📝 LOGS ORIGINALES (webapp container):"
kubectl exec webapp-sidecar -c webapp -- cat /var/log/app/access.log
```

**🔍 Observaciones**:
- Logs en formato JSON estructurado
- Incluyen timestamp, método, path, user-agent, IP

### Paso 11: Verificar Logs Procesados por Sidecar

```bash
echo ""
echo "⚙️ LOGS PROCESADOS (sidecar container):"
kubectl exec webapp-sidecar -c log-processor -- cat /var/log/processed/processed.log
```

**🔍 Observaciones**:
- Logs procesados por Fluent Bit
- Formato normalizado
- Listos para enviar a sistema central (Elasticsearch, etc.)

### Paso 12: Ver Logs de Contenedores

```bash
echo ""
echo "📊 CONTAINER LOGS:"
echo "--- WebApp Container ---"
kubectl logs webapp-sidecar -c webapp --tail=5

echo ""
echo "--- Log Processor Container ---"
kubectl logs webapp-sidecar -c log-processor --tail=10
```

### Paso 13: Análisis de Recursos

```bash
echo ""
echo "💾 RESOURCE USAGE:"
kubectl top pod webapp-sidecar --containers
```

**🔍 Observaciones**:
- Webapp consume ~128Mi RAM
- Log processor consume ~64Mi RAM
- Resource isolation entre funciones

### Paso 14: Cleanup Port Forward

```bash
# Stop port-forward
kill %1 2>/dev/null
```

## 📊 Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    Pod: webapp-sidecar                  │
│                                                         │
│  ┌──────────────┐           ┌─────────────────┐        │
│  │   webapp     │           │  log-processor  │        │
│  │   (Flask)    │           │  (Fluent Bit)   │        │
│  │              │           │                 │        │
│  │  Port: 5000  │           │                 │        │
│  └──────┬───────┘           └────────┬────────┘        │
│         │                            │                 │
│         │    writes                  │ reads           │
│         ▼                            ▼                 │
│  ┌─────────────────────────────────────────┐           │
│  │     log-volume (emptyDir)               │           │
│  │     /var/log/app/access.log             │           │
│  └─────────────────────────────────────────┘           │
│                                                         │
│  Network: localhost (shared)                            │
│  IP: 10.244.x.x                                         │
└─────────────────────────────────────────────────────────┘
```

## ✅ Beneficios del Sidecar Pattern Demostrados

```
✅ SIDECAR PATTERN BENEFITS:
├─ 🔄 Separación de responsabilidades
│   • Webapp: Lógica de negocio
│   • Sidecar: Logging/procesamiento
│
├─ 🌐 Comunicación via shared volume
│   • Sin dependencias entre contenedores
│   • Acoplamiento mínimo
│
├─ 📊 Procesamiento en tiempo real
│   • Fluent Bit lee y procesa logs instantáneamente
│   • No afecta performance de la app
│
├─ 🔍 Logs estructurados y enriquecidos
│   • JSON parsing
│   • Normalización
│   • Ready para enviar a Elasticsearch/Splunk
│
└─ ⚖️ Resource isolation entre funciones
    • Límites independientes de CPU/memoria
    • Escalado independiente
```

## 🧹 Limpieza

```bash
# Detener port-forward si sigue activo
killall kubectl 2>/dev/null

# Eliminar recursos
kubectl delete pod webapp-sidecar
kubectl delete configmap fluent-config

# Limpiar archivos locales
cd ~
rm -rf ~/labs/modulo-04/sidecar-real
```

## 🎓 Conceptos Clave Aprendidos

1. **Sidecar Pattern** para extender funcionalidad sin modificar app
2. **Shared Volumes** (emptyDir) para comunicación entre contenedores
3. **Fluent Bit** como log processor real-world
4. **Resource Limits** independientes por contenedor
5. **Separación de responsabilidades** en microservicios

## 🚀 Mejoras Adicionales

### Variante 1: Enviar logs a Elasticsearch

Modificar `fluent-bit.conf`:

```ini
[OUTPUT]
    Name   es
    Match  *
    Host   elasticsearch-service
    Port   9200
    Index  webapp-logs
    Type   _doc
```

### Variante 2: Sidecar de Métricas

Agregar Prometheus exporter sidecar:

```yaml
- name: metrics-exporter
  image: nginx/nginx-prometheus-exporter:latest
  args: ["-nginx.scrape-uri=http://localhost:80/metrics"]
  ports:
  - containerPort: 9113
```

## 📚 Referencias

- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [Kubernetes Sidecar Pattern](https://kubernetes.io/docs/concepts/cluster-administration/logging/#sidecar-container-with-logging-agent)
- [emptyDir Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)

## ⏭️ Siguiente Paso

Continúa con **[Lab 4: Init Container Migration Pattern](./lab-04-init-migration.md)** para migrar setup complejo de Docker a Init Containers.
