# Laboratorio 2: ConfigMaps Avanzado

## Objetivos

✅ Crear ConfigMaps desde literales y archivos  
✅ Consumir ConfigMaps como variables de entorno  
✅ Montar ConfigMaps como volúmenes  
✅ Combinar ConfigMaps con Secrets  
✅ Actualizar configuración sin recrear Pods

**Duración estimada**: 60 minutos

---

## Parte 1: Crear ConfigMaps (15 min)

### Método 1: Desde Literales

```bash
# ConfigMap con configuración de app
kubectl create configmap app-config \
  --from-literal=database.host=postgres.default.svc.cluster.local \
  --from-literal=database.port=5432 \
  --from-literal=app.environment=production

# Verificar
kubectl get configmap app-config -o yaml
```

### Método 2: Desde Archivos

Crear archivo nginx.conf:

```bash
cat > nginx.conf <<'EOF'
server {
    listen 8080;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Crear ConfigMap desde archivo
kubectl create configmap nginx-config --from-file=nginx.conf

# Verificar contenido
kubectl describe configmap nginx-config
```

### Método 3: YAML (Recomendado)

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings
data:
  # Configuración simple
  log.level: "info"
  max.connections: "100"
  
  # Archivo completo
  app.properties: |
    spring.datasource.url=jdbc:postgresql://postgres:5432/mydb
    spring.jpa.hibernate.ddl-auto=update
    logging.level.root=INFO
EOF
```

---

## Parte 2: Consumir como Variables (15 min)

### Opción A: Variables Individuales

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: app-env-individual
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "env | grep DB_ && sleep 3600"]
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.host
    
    - name: DB_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.port
EOF
```

Verificar:

```bash
kubectl exec app-env-individual -- env | grep DB_
# DB_HOST=postgres.default.svc.cluster.local
# DB_PORT=5432
```

### Opción B: Todas las Claves (envFrom)

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: app-env-all
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "env | sort && sleep 3600"]
    envFrom:
    - configMapRef:
        name: app-config
EOF
```

⚠️ **Importante**: Las claves con `.` o `-` se convierten automáticamente (ej: `database.host` → `database_host`).

---

## Parte 3: Montar como Volúmenes (20 min)

### Paso 1: Deployment de Nginx

```yaml
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-configmap
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpine
        ports:
        - containerPort: 8080
        
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf
      
      volumes:
      - name: config
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 8080
EOF
```

### Paso 2: Probar Nginx

```bash
# Port-forward
kubectl port-forward svc/nginx 8080:80 &

# Probar
curl http://localhost:8080/health
# OK
```

### Paso 3: Actualizar ConfigMap

```bash
# Actualizar puerto en nginx.conf
kubectl patch configmap nginx-config \
  --patch '{"data":{"nginx.conf":"server { listen 8080; location / { return 200 \"Version 2.0\\n\"; } }"}}'

# ⚠️ Con subPath, necesitas recrear Pod
kubectl rollout restart deployment/nginx-configmap

# Verificar
sleep 10
curl http://localhost:8080/
# Version 2.0
```

---

## Parte 4: ConfigMaps + Secrets (10 min)

### Paso 1: Crear Secret

```bash
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password='SuperSecret123!'
```

### Paso 2: Deployment con ConfigMap + Secret

```yaml
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh", "-c", "env | grep -E '(DB_|APP_)' && sleep 3600"]
        
        # Variables desde ConfigMap
        envFrom:
        - configMapRef:
            name: app-config
        
        # Secretos individuales
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
EOF
```

### Paso 3: Verificar

```bash
POD=$(kubectl get pod -l app=webapp -o jsonpath='{.items[0].metadata.name}')

kubectl exec $POD -- env | grep DB_
# DB_HOST=postgres.default.svc.cluster.local
# DB_PORT=5432
# DB_USERNAME=admin
# DB_PASSWORD=SuperSecret123!
```

---

## Ejercicio Final: Aplicación Completa

Crea una aplicación que:

1. Use ConfigMap para configuración pública
2. Use Secret para credenciales
3. Monte un archivo de configuración JSON
4. Exponga un endpoint /config

<details>
<summary>💡 Solución Completa</summary>

```yaml
# 1. ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  
  config.json: |
    {
      "database": {
        "host": "postgres.default.svc.cluster.local",
        "port": 5432
      },
      "features": {
        "cache": true,
        "metrics": true
      }
    }
---
# 2. Secret
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
stringData:
  DB_PASSWORD: "secret123"
  API_KEY: "sk-1234567890"
---
# 3. Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: nginx:1.27-alpine
        
        # Variables desde ConfigMap
        envFrom:
        - configMapRef:
            name: myapp-config
        
        # Secretos
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: DB_PASSWORD
        
        # Montar config.json
        volumeMounts:
        - name: config-file
          mountPath: /app/config
      
      volumes:
      - name: config-file
        configMap:
          name: myapp-config
          items:
          - key: config.json
            path: config.json
```

Verificar:

```bash
POD=$(kubectl get pod -l app=myapp -o jsonpath='{.items[0].metadata.name}')

# Variables
kubectl exec $POD -- env | grep -E '(APP_|DB_|LOG)'

# Archivo
kubectl exec $POD -- cat /app/config/config.json
```

</details>

---

## Limpieza

```bash
kubectl delete configmap app-config nginx-config app-settings myapp-config
kubectl delete secret db-credentials myapp-secrets
kubectl delete deployment nginx-configmap webapp myapp
kubectl delete service nginx
kubectl delete pod app-env-individual app-env-all
```

---

## Resumen

✅ ConfigMaps desde literales/archivos/YAML  
✅ Consumir como env vars (individual o todas las claves)  
✅ Montar como volúmenes (con/sin subPath)  
✅ Combinar ConfigMaps + Secrets  
✅ Actualizar configuración (con limitaciones)

**Continúa con**: [Laboratorio 3 - Troubleshooting](lab-03-troubleshooting.md)
