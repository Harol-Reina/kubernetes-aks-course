# 🚀 Lab 1: Evolución Histórica Práctica

## 📋 Información del Laboratorio

- **Duración estimada**: 30 minutos
- **Nivel**: Principiante
- **Prerrequisitos**:
  - Docker instalado
  - kubectl configurado
  - Cluster Kubernetes activo (minikube/kind)

## 🎯 Objetivo

Experimentar de forma práctica la diferencia entre tres enfoques de containerización:
1. **LXC** - Contenedores completamente aislados (sin networking)
2. **Docker** - Contenedores con bridge network
3. **Kubernetes** - Pods con networking compartido (localhost)

## 🧪 Práctica

### Paso 1: Preparación del Entorno

```bash
# Crear directorio para el lab
mkdir -p ~/labs/modulo-04/evolution-demo && cd ~/labs/modulo-04/evolution-demo

echo "🎯 DEMO: Evolución LXC → Docker → Kubernetes"
echo "=============================================="
```

### Paso 2: Simular Enfoque LXC (Aislamiento Total)

```bash
echo ""
echo "📦 PASO 1: Enfoque LXC (Aislamiento total)"
echo "├─ Crear 2 contenedores Docker aislados"
echo "├─ Intentar comunicación directa"
echo "└─ Observar complejidad"

# Crear dos contenedores sin network bridge
docker run -d --name lxc-app1 --network none nginx:alpine
docker run -d --name lxc-app2 --network none nginx:alpine

# Verificar aislamiento total
echo "❌ Contenedores sin networking:"
docker exec lxc-app1 ip addr show
docker exec lxc-app2 ip addr show

# Cleanup
docker stop lxc-app1 lxc-app2 && docker rm lxc-app1 lxc-app2
```

**🔍 Observaciones**:
- Ambos contenedores **NO tienen** interfaz de red (excepto `lo`)
- No pueden comunicarse entre sí
- Representa el nivel de aislamiento de LXC tradicional

### Paso 3: Enfoque Docker (Bridge Network)

```bash
echo ""
echo "🌉 PASO 2: Enfoque Docker (Bridge Network)"  
echo "├─ Crear red bridge personalizada"
echo "├─ Contenedores se comunican vía IP interna"
echo "└─ Comunicación funcional pero manual"

# Crear red bridge
docker network create evolution-demo

# Crear contenedores en la red
docker run -d --name docker-web --network evolution-demo nginx:alpine
docker run -d --name docker-api --network evolution-demo httpd:alpine

# Probar comunicación
echo "✅ Comunicación Docker bridge:"
docker exec docker-web nslookup docker-api
docker exec docker-web wget -qO- http://docker-api

# Cleanup
docker stop docker-web docker-api && docker rm docker-web docker-api
docker network rm evolution-demo
```

**🔍 Observaciones**:
- Los contenedores **pueden comunicarse** usando nombres de contenedor
- Docker DNS interno resuelve `docker-api` a su IP interna
- Requiere configuración manual de red

### Paso 4: Enfoque Kubernetes (Pod Networking)

```bash
echo ""
echo "☸️ PASO 3: Enfoque Kubernetes (Pod Networking)"
echo "├─ Crear Pod multi-container"
echo "├─ Comunicación vía localhost"
echo "└─ Networking automático"

cat > evolution-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: evolution-demo
  labels:
    demo: evolution
spec:
  containers:
  - name: web
    image: nginx:alpine
    ports:
    - containerPort: 80
    
  - name: api
    image: httpd:alpine
    ports:
    - containerPort: 8080
    # httpd usa puerto 80 por defecto
    # nginx también usa 80, pero en el Pod solo uno puede usar cada puerto
    # Cambiaremos httpd a puerto 8080
    command: ["/bin/sh"]
    args: ["-c", "sed 's/Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf > /tmp/httpd.conf && httpd -f /tmp/httpd.conf -D FOREGROUND"]
EOF

# Aplicar Pod
kubectl apply -f evolution-pod.yaml

# Esperar a que esté listo
kubectl wait --for=condition=Ready pod/evolution-demo --timeout=60s

# Probar comunicación localhost
echo "✅ Comunicación Kubernetes (localhost):"
kubectl exec evolution-demo -c web -- wget -qO- http://localhost:8080
kubectl exec evolution-demo -c api -- wget -qO- http://localhost:80

# Ver información del Pod
kubectl describe pod evolution-demo | grep IP

# Cleanup
kubectl delete pod evolution-demo
```

**🔍 Observaciones**:
- Los contenedores **comparten la misma interfaz de red**
- Comunicación vía `localhost` sin configuración adicional
- Kubernetes maneja el networking automáticamente

## 📊 Resumen Comparativo

```
┌─────────────┬──────────────────────┬───────────────────────┬─────────────────────┐
│  Enfoque    │   LXC                │   Docker              │  Kubernetes         │
├─────────────┼──────────────────────┼───────────────────────┼─────────────────────┤
│ Networking  │ Aislamiento total    │ Bridge network        │ Shared namespace    │
│ Comunicación│ ❌ Imposible         │ ✅ Via IP/nombre DNS  │ ✅ Via localhost    │
│ Config      │ Manual complejo      │ Manual moderado       │ ✅ Automático       │
│ Uso caso    │ Legacy systems       │ Single-host apps      │ Multi-host apps     │
└─────────────┴──────────────────────┴───────────────────────┴─────────────────────┘
```

## ✅ Resultados Esperados

Al completar este laboratorio, habrás experimentado:

- ✅ **LXC**: Aislamiento total = Comunicación imposible
- ✅ **Docker**: Bridge network = Comunicación por IP/nombre
- ✅ **Kubernetes**: Shared networking = Comunicación localhost

## 🧹 Limpieza

Los comandos de cleanup ya están incluidos en el script. Si necesitas limpiar manualmente:

```bash
# Docker cleanup
docker stop $(docker ps -aq --filter name=lxc-app) 2>/dev/null
docker rm $(docker ps -aq --filter name=lxc-app) 2>/dev/null
docker stop $(docker ps -aq --filter name=docker-) 2>/dev/null
docker rm $(docker ps -aq --filter name=docker-) 2>/dev/null
docker network rm evolution-demo 2>/dev/null

# Kubernetes cleanup
kubectl delete pod evolution-demo 2>/dev/null
```

## 🎓 Conceptos Clave Aprendidos

1. **Evolución del networking** en containerización
2. **Trade-offs** entre aislamiento y simplicidad
3. **Ventajas de Kubernetes** para comunicación entre contenedores
4. **Shared network namespace** en Pods

## ⏭️ Siguiente Paso

Continúa con **[Lab 2: Namespace Sharing Deep Dive](./lab-02-namespace-sharing.md)** para explorar en detalle qué namespaces comparten los contenedores en un Pod.
