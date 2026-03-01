# Laboratorio 01: Evolucion Historica - LXC vs Docker vs Kubernetes

**Duracion estimada:** 30 minutos
**Nivel:** Basico
**Objetivo:** Experimentar de forma practica la diferencia entre tres enfoques de containerizacion comparando aislamiento de red, configuracion necesaria y facilidad de comunicacion entre contenedores

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **LXC networking** | Contenedores con `--network none` que simulan el aislamiento total del enfoque LXC tradicional. Sin interfaz de red, la comunicacion entre contenedores es imposible |
| **Docker bridge network** | Red bridge personalizada que permite comunicacion entre contenedores usando nombres de contenedor como hostnames. Docker DNS interno resuelve los nombres automaticamente |
| **Pod multi-container** | Unidad fundamental de Kubernetes. Dos o mas contenedores en el mismo Pod comparten network namespace, IPC y UTS namespace automaticamente |
| **Shared network namespace** | Los contenedores dentro de un Pod tienen la misma IP y se comunican via localhost sin ninguna configuracion adicional |
| **kubectl wait** | Comando para esperar a que un Pod alcance una condicion especifica (Ready, Initialized) antes de continuar. Util en scripts y automatizacion |
| **kubectl exec -c** | Ejecuta un comando en un contenedor especifico de un Pod multi-container. Requiere el flag `-c nombre-contenedor` |

---

## Archivos del Laboratorio

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `evolution-pod.yaml` | 4 | Pod multi-container con nginx (web, puerto 80) y httpd (api, puerto 8080) para demostrar Kubernetes networking |
| `cleanup.sh` | - | Script de limpieza de todos los recursos del laboratorio (Pods Kubernetes y contenedores Docker) |

---

## Practica

### Paso 1: Preparacion del Entorno

```bash
# Crear directorio para el lab
mkdir -p ~/labs/modulo-04/evolution-demo && cd ~/labs/modulo-04/evolution-demo

echo "DEMO: Evolucion LXC - Docker - Kubernetes"
echo "=============================================="
```

### Paso 2: Simular Enfoque LXC (Aislamiento Total)

```bash
echo ""
echo "PASO 1: Enfoque LXC (Aislamiento total)"
echo "- Crear 2 contenedores Docker aislados"
echo "- Intentar comunicacion directa"
echo "- Observar complejidad"

# Crear dos contenedores sin network bridge
docker run -d --name lxc-app1 --network none nginx:alpine
docker run -d --name lxc-app2 --network none nginx:alpine

# Verificar aislamiento total
echo "Contenedores sin networking:"
docker exec lxc-app1 ip addr show
docker exec lxc-app2 ip addr show

# Cleanup
docker stop lxc-app1 lxc-app2 && docker rm lxc-app1 lxc-app2
```

**Observaciones:**
- Ambos contenedores **NO tienen** interfaz de red (excepto `lo`)
- No pueden comunicarse entre si
- Representa el nivel de aislamiento de LXC tradicional

### Paso 3: Enfoque Docker (Bridge Network)

```bash
echo ""
echo "PASO 2: Enfoque Docker (Bridge Network)"
echo "- Crear red bridge personalizada"
echo "- Contenedores se comunican via IP interna"
echo "- Comunicacion funcional pero manual"

# Crear red bridge
docker network create evolution-demo

# Crear contenedores en la red
docker run -d --name docker-web --network evolution-demo nginx:alpine
docker run -d --name docker-api --network evolution-demo httpd:alpine

# Probar comunicacion
echo "Comunicacion Docker bridge:"
docker exec docker-web nslookup docker-api
docker exec docker-web wget -qO- http://docker-api

# Cleanup
docker stop docker-web docker-api && docker rm docker-web docker-api
docker network rm evolution-demo
```

**Observaciones:**
- Los contenedores **pueden comunicarse** usando nombres de contenedor
- Docker DNS interno resuelve `docker-api` a su IP interna
- Requiere configuracion manual de red

### Paso 4: Enfoque Kubernetes (Pod Networking)

```bash
echo ""
echo "PASO 3: Enfoque Kubernetes (Pod Networking)"
echo "- Crear Pod multi-container"
echo "- Comunicacion via localhost"
echo "- Networking automatico"
```

Revisa el archivo `evolution-pod.yaml` antes de aplicarlo:

```bash
cat evolution-pod.yaml
```

Puntos clave del manifiesto:
- Dos contenedores en el mismo Pod: `web` (nginx, puerto 80) y `api` (httpd, puerto 8080)
- Comparten el mismo network namespace automaticamente
- `api` se reconfigura para escuchar en el puerto 8080 (httpd usa 80 por defecto, mismo que nginx)

Aplica el Pod y verifica la comunicacion:

```bash
# Aplicar Pod
kubectl apply -f evolution-pod.yaml
```

Salida esperada:
```
pod/evolution-demo created
```

```bash
# Esperar a que este listo
kubectl wait --for=condition=Ready pod/evolution-demo --timeout=60s
```

Salida esperada:
```
pod/evolution-demo condition met
```

```bash
# Probar comunicacion localhost: desde web hacia api
kubectl exec evolution-demo -c web -- wget -qO- http://localhost:8080
```

Salida esperada (pagina por defecto de Apache httpd):
```html
<html><body><h1>It works!</h1></body></html>
```

```bash
# Probar comunicacion localhost: desde api hacia web
kubectl exec evolution-demo -c api -- wget -qO- http://localhost:80
```

Salida esperada (pagina por defecto de nginx):
```html
<!DOCTYPE html>
<html>
<head><title>Welcome to nginx!</title></head>
...
```

```bash
# Ver informacion de IP del Pod
kubectl describe pod evolution-demo | grep IP
```

Salida esperada:
```
IP:           10.244.0.X
IPs:          IP=10.244.0.X
```

**Observaciones:**
- Los contenedores **comparten la misma interfaz de red**
- Comunicacion via `localhost` sin configuracion adicional
- Kubernetes maneja el networking automaticamente

## Resumen Comparativo

```
+-------------+----------------------+-----------------------+---------------------+
|  Enfoque    |   LXC                |   Docker              |  Kubernetes         |
+-------------+----------------------+-----------------------+---------------------+
| Networking  | Aislamiento total    | Bridge network        | Shared namespace    |
| Comunicacion| Imposible            | Via IP/nombre DNS     | Via localhost       |
| Config      | Manual complejo      | Manual moderado       | Automatico          |
| Uso caso    | Legacy systems       | Single-host apps      | Multi-host apps     |
+-------------+----------------------+-----------------------+---------------------+
```

## Resultados Esperados

Al completar este laboratorio, habras experimentado:

- **LXC**: Aislamiento total = Comunicacion imposible
- **Docker**: Bridge network = Comunicacion por IP/nombre
- **Kubernetes**: Shared networking = Comunicacion localhost

## Limpieza

Ejecuta el script de limpieza incluido:

```bash
bash cleanup.sh
```

O si necesitas limpiar manualmente:

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

## Conceptos Clave Aprendidos

1. **Evolucion del networking** en containerizacion
2. **Trade-offs** entre aislamiento y simplicidad
3. **Ventajas de Kubernetes** para comunicacion entre contenedores
4. **Shared network namespace** en Pods

## Siguiente Paso

Continua con **Lab 02: Namespace Sharing Deep Dive** para explorar en detalle que namespaces comparten los contenedores en un Pod.
