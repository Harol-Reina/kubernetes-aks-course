# Laboratorio 04: Init Container Migration Pattern - De Docker a Kubernetes

**Duracion estimada:** 70 minutos
**Nivel:** Avanzado
**Objetivo:** Migrar un setup complejo de Docker con orquestacion manual a Init Containers de Kubernetes, demostrando orquestacion automatica de dependencias, setup secuencial garantizado y simplificacion vs Docker tradicional.

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Init Containers** | Contenedores especiales que se ejecutan secuencialmente ANTES de los contenedores principales. Cada uno debe completar exitosamente para que el siguiente inicie |
| **Orquestacion declarativa** | El YAML describe la secuencia completa de setup. Kubernetes gestiona el orden y los reintentos automaticamente, sin scripts bash manuales |
| **pg_isready** | Herramienta de PostgreSQL para verificar disponibilidad de la BD. Usada en el Init Container wait-for-db para esperar activamente en lugar de `sleep` hardcodeado |
| **ConfigMaps como scripts** | Archivos de script y SQL almacenados como ConfigMaps y montados como volumenes. Permite versionado de codigo de setup junto al manifiesto |
| **defaultMode: 0755** | Permisos de archivo aplicados al montar un ConfigMap como volumen. Necesario para que los scripts shell sean ejecutables dentro del contenedor |
| **emptyDir para estado compartido** | Volumenes efimeros usados para compartir archivos entre init containers y el contenedor principal (app-config, setup-status) |

---

## Archivos del Laboratorio

Este laboratorio utiliza archivos separados para cada componente:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `docker-setup.sh` | 1 | Script Docker tradicional (7 pasos manuales) usado como punto de comparacion |
| `app.py` | 2 | Aplicacion Flask con endpoints /, /data (PostgreSQL), /config (archivo preparado por init) |
| `migrate.sql` | 3 | Migracion SQL idempotente ejecutada por el Init Container db-migration |
| `download-config.sh` | 4 | Script de inicializacion que simula descarga de config y escribe /app/setup/complete |
| `postgres-pod.yaml` | 5 | Pod PostgreSQL 13 + Service ClusterIP db-service |
| `init-pod.yaml` | 6 | Pod con 3 Init Containers (wait-for-db, db-migration, config-setup) + app principal |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Elimina pods app-with-init y db, service db-service, configmaps app-code/migration-scripts/setup-scripts |

---

## Practica

### Paso 1: Entender el Problema - Setup Docker Tradicional

```bash
mkdir -p ~/labs/modulo-04/init-migration && cd ~/labs/modulo-04/init-migration

echo "🚀 INIT CONTAINER: Migration from Docker Setup"
echo "=============================================="
```

#### Problema: Docker Setup Complejo (ANTES)

Revisa el archivo `docker-setup.sh` del laboratorio:

```bash
cat docker-setup.sh
```

Copia el archivo al directorio de trabajo y dale permisos de ejecucion:

```bash
cp /ruta/al/lab-04-init-migration/docker-setup.sh .
chmod +x docker-setup.sh
```

**Problemas de este enfoque**:
- 7 pasos manuales
- Esperas hardcodeadas (`sleep 10`)
- Dificil de reproducir
- Sin manejo de errores

### Paso 2: Revisar la Aplicacion Flask

Revisa el archivo `app.py` del laboratorio:

```bash
cat app.py
```

Copia el archivo al directorio de trabajo:

```bash
cp /ruta/al/lab-04-init-migration/app.py .
```

### Paso 3: Preparar Scripts de Inicializacion

```bash
mkdir -p setup-scripts
```

Revisa y copia el script SQL de migraciones:

```bash
cat migrate.sql
cp /ruta/al/lab-04-init-migration/migrate.sql setup-scripts/
```

Revisa y copia el script de descarga de configuracion:

```bash
cat download-config.sh
cp /ruta/al/lab-04-init-migration/download-config.sh setup-scripts/
chmod +x setup-scripts/download-config.sh
```

> **Nota sobre download-config.sh**: Este script contiene un heredoc interno (`<< 'CONFIG'`) que genera el archivo `/app/config/app.json`. El script completo se almacena en un ConfigMap con `defaultMode: 0755` para que sea ejecutable dentro del contenedor.

### Paso 4: Crear ConfigMaps

```bash
# ConfigMap para codigo de la aplicacion
kubectl create configmap app-code --from-file=app.py

# ConfigMap para scripts de migracion
kubectl create configmap migration-scripts --from-file=setup-scripts/migrate.sql

# ConfigMap para scripts de setup
kubectl create configmap setup-scripts --from-file=setup-scripts/download-config.sh
```

### Paso 5: Desplegar Base de Datos

Revisa el archivo `postgres-pod.yaml` antes de aplicarlo:

```bash
cat postgres-pod.yaml
```

```bash
kubectl apply -f postgres-pod.yaml
kubectl wait --for=condition=Ready pod/db --timeout=60s
```

### Paso 6: Revisar Pod con Init Containers (SOLUCION)

Revisa el archivo `init-pod.yaml` antes de aplicarlo:

```bash
cat init-pod.yaml
```

**Ventajas de Init Containers**:
- **Secuencia automatica**: wait-for-db -> migrations -> config
- **Retry automatico**: Si falla, Kubernetes reintenta
- **Declarativo**: Un solo YAML describe todo el setup

### Paso 7: Desplegar Aplicacion

```bash
kubectl apply -f init-pod.yaml
```

### Paso 8: Observar Secuencia de Inicializacion

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

**Estados que veras**:
1. `Init:0/3` - Esperando primer init container
2. `Init:1/3` - wait-for-db completado
3. `Init:2/3` - db-migration completado
4. `Init:3/3` - config-setup completado
5. `Running` - Aplicacion principal ejecutandose

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

### Paso 10: Verificar Aplicacion Principal

```bash
echo ""
echo "--- Main Application ---"
kubectl logs app-with-init -c app
```

### Paso 11: Probar la Aplicacion

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

**Respuestas esperadas**:
- `/`: `{"message": "🚀 App with Init Containers", "setup_complete": true}`
- `/data`: Lista de usuarios de la BD
- `/config`: Configuracion descargada por init container

## Comparacion Docker vs Init Containers

```
┌──────────────────────┬────────────────────┬──────────────────────┐
│     Caracteristica   │  Docker Setup      │  Init Containers     │
├──────────────────────┼────────────────────┼──────────────────────┤
│  Orquestacion        │  ❌ Manual         │  ✅ Automatica       │
│  Dependencias        │  ❌ Scripts bash   │  ✅ Declarativas     │
│  Retry en failure    │  ❌ Manual         │  ✅ Automatico       │
│  Reproducibilidad    │  ❌ Baja           │  ✅ Alta             │
│  Configuracion       │  ❌ Multi-archivo  │  ✅ Single YAML      │
│  Error handling      │  ❌ Manual         │  ✅ Built-in         │
└──────────────────────┴────────────────────┴──────────────────────┘
```

## Diagrama de Secuencia

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

## Beneficios de Init Containers

```
✅ INIT CONTAINER BENEFITS:
├─ 🔄 Sequential execution guaranteed
│   • wait-for-db → migrations → config → app
│   • No race conditions
│
├─ 🛠️ Setup separation from main app
│   • App codigo no contiene logica de setup
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
│   • Sin intervencion manual
│
└─ 🧹 Clean resource management
    • Init containers se eliminan despues
    • No consumen recursos despues de completar
```

## Limpieza

Ejecuta el script de limpieza del laboratorio:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

O manualmente:

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

## Conceptos Clave Aprendidos

1. **Init Containers** ejecutan secuencialmente ANTES de la app principal
2. **Orquestacion declarativa** vs scripts bash imperativos
3. **Retry automatico** de Kubernetes para init containers
4. **Separacion de responsabilidades**: setup vs runtime
5. **Single Pod deployment** simplifica gestion

## Casos de Uso Adicionales

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

## Referencias

- [Init Containers - Kubernetes Docs](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [PostgreSQL in Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-initialization/)

## Siguiente Paso

Continua con **[Lab 5: Migracion de Docker Compose](../lab-05-compose-migration/README.md)** para migrar una aplicacion completa de docker-compose.yml a Kubernetes.
