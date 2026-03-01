# Laboratorio 03: Sidecar Pattern Real-World - Logging con Fluent Bit

**Duracion estimada:** 60 minutos
**Nivel:** Intermedio-Avanzado
**Objetivo:** Implementar un sidecar de logging real con Flask y Fluent Bit, comunicados via shared volume (emptyDir), demostrando separacion de responsabilidades en un Pod multi-container.

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Sidecar pattern** | Contenedor auxiliar que extiende la funcionalidad de la app principal sin modificarla. El sidecar Fluent Bit procesa los logs que genera Flask |
| **emptyDir shared volume** | Volumen efimero compartido entre contenedores del mismo Pod. La app escribe en `/var/log/app` y el sidecar lee desde el mismo path |
| **Fluent Bit** | Log processor ligero que lee, parsea y reenvía logs. Configurado via ConfigMap montado como archivo de configuracion |
| **JSON logs estructurados** | La app genera logs en JSON con campos timestamp, method, path, ip. Facilita el parseo automatico por el sidecar |
| **Resource limits por contenedor** | Cada contenedor del Pod tiene sus propios `requests` y `limits` de CPU/memoria, garantizando aislamiento de recursos |
| **ConfigMap como archivo de config** | La configuracion de Fluent Bit se almacena en un ConfigMap y se monta como archivo individual via `subPath` |

---

## Archivos del Laboratorio

Este laboratorio utiliza archivos separados para cada componente:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `web-app.py` | 1 | Aplicacion Flask que genera logs JSON estructurados al shared volume |
| `Dockerfile` | 2 | Imagen minimalista python:3.9-slim con Flask instalado |
| `fluent-bit.conf` | 3 | Configuracion del sidecar Fluent Bit: INPUT tail, FILTER parser JSON, OUTPUT file+stdout |
| `sidecar-pod.yaml` | 4 | Pod multi-container con webapp + log-processor y volumenes compartidos |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Elimina pod webapp-sidecar, configmap fluent-config y detiene port-forward |

---

## Practica

### Paso 1: Preparacion del Entorno

```bash
mkdir -p ~/labs/modulo-04/sidecar-real && cd ~/labs/modulo-04/sidecar-real

echo "🏗️ SIDECAR PATTERN: Real-World Logging"
echo "======================================"
```

### Paso 2: Revisar la Aplicacion Web Flask

Revisa el archivo `web-app.py` del laboratorio:

```bash
cat web-app.py
```

Copia el archivo al directorio de trabajo:

```bash
cp /ruta/al/lab-03-sidecar-real-world/web-app.py .
```

**Caracteristicas de la App**:
- Logs en formato **JSON estructurado**
- Escribe a `/var/log/app/access.log` (shared volume)
- 3 endpoints: `/`, `/api/users`, `/health`

### Paso 3: Revisar el Dockerfile

Revisa el archivo `Dockerfile` del laboratorio:

```bash
cat Dockerfile
```

Copia el archivo al directorio de trabajo:

```bash
cp /ruta/al/lab-03-sidecar-real-world/Dockerfile .
```

### Paso 4: Build de la Imagen

```bash
# Build imagen
docker build -t sidecar-webapp:v1 .

# (Opcional) Cargar en minikube si usas minikube
# minikube image load sidecar-webapp:v1
```

### Paso 5: Revisar la Configuracion de Fluent Bit (Sidecar)

Revisa el archivo `fluent-bit.conf` del laboratorio:

```bash
cat fluent-bit.conf
```

**Funciones de Fluent Bit**:
- **INPUT**: Lee `/var/log/app/access.log` (shared volume)
- **FILTER**: Parsea JSON
- **OUTPUT**: Escribe logs procesados y muestra en stdout

### Paso 6: Crear ConfigMap para Fluent Bit

Copia el archivo de configuracion al directorio de trabajo y crea el ConfigMap:

```bash
cp /ruta/al/lab-03-sidecar-real-world/fluent-bit.conf .
kubectl create configmap fluent-config --from-file=fluent-bit.conf
```

### Paso 7: Revisar y Crear Pod con Sidecar

Revisa el archivo `sidecar-pod.yaml` antes de aplicarlo:

```bash
cat sidecar-pod.yaml
```

Puntos clave del manifiesto:
- **webapp**: Aplicacion principal (genera logs)
- **log-processor**: Sidecar (procesa logs)
- **log-volume**: Shared emptyDir para logs
- **fluent-config**: ConfigMap con configuracion

### Paso 8: Desplegar Pod

```bash
kubectl apply -f sidecar-pod.yaml
kubectl wait --for=condition=Ready pod/webapp-sidecar --timeout=120s
```

### Paso 9: Generar Trafico

```bash
# Port forward
kubectl port-forward pod/webapp-sidecar 8080:5000 &
sleep 3

echo ""
echo "🚦 Generando trafico para demostrar sidecar..."
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

**Observaciones**:
- Logs en formato JSON estructurado
- Incluyen timestamp, metodo, path, user-agent, IP

### Paso 11: Verificar Logs Procesados por Sidecar

```bash
echo ""
echo "⚙️ LOGS PROCESADOS (sidecar container):"
kubectl exec webapp-sidecar -c log-processor -- cat /var/log/processed/processed.log
```

**Observaciones**:
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

### Paso 13: Analisis de Recursos

```bash
echo ""
echo "💾 RESOURCE USAGE:"
kubectl top pod webapp-sidecar --containers
```

**Observaciones**:
- Webapp consume ~128Mi RAM
- Log processor consume ~64Mi RAM
- Resource isolation entre funciones

### Paso 14: Cleanup Port Forward

```bash
# Stop port-forward
kill %1 2>/dev/null
```

## Diagrama de Arquitectura

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

## Beneficios del Sidecar Pattern Demostrados

```
✅ SIDECAR PATTERN BENEFITS:
├─ 🔄 Separacion de responsabilidades
│   • Webapp: Logica de negocio
│   • Sidecar: Logging/procesamiento
│
├─ 🌐 Comunicacion via shared volume
│   • Sin dependencias entre contenedores
│   • Acoplamiento minimo
│
├─ 📊 Procesamiento en tiempo real
│   • Fluent Bit lee y procesa logs instantaneamente
│   • No afecta performance de la app
│
├─ 🔍 Logs estructurados y enriquecidos
│   • JSON parsing
│   • Normalizacion
│   • Ready para enviar a Elasticsearch/Splunk
│
└─ ⚖️ Resource isolation entre funciones
    • Limites independientes de CPU/memoria
    • Escalado independiente
```

## Limpieza

Ejecuta el script de limpieza del laboratorio:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

O manualmente:

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

## Conceptos Clave Aprendidos

1. **Sidecar Pattern** para extender funcionalidad sin modificar app
2. **Shared Volumes** (emptyDir) para comunicacion entre contenedores
3. **Fluent Bit** como log processor real-world
4. **Resource Limits** independientes por contenedor
5. **Separacion de responsabilidades** en microservicios

## Mejoras Adicionales

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

### Variante 2: Sidecar de Metricas

Agregar Prometheus exporter sidecar:

```yaml
- name: metrics-exporter
  image: nginx/nginx-prometheus-exporter:latest
  args: ["-nginx.scrape-uri=http://localhost:80/metrics"]
  ports:
  - containerPort: 9113
```

## Referencias

- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [Kubernetes Sidecar Pattern](https://kubernetes.io/docs/concepts/cluster-administration/logging/#sidecar-container-with-logging-agent)
- [emptyDir Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)

## Siguiente Paso

Continua con **[Lab 4: Init Container Migration Pattern](../lab-04-init-migration/README.md)** para migrar setup complejo de Docker a Init Containers.
