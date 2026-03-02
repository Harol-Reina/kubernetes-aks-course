# Setup - Lab 04: Init Container Migration Pattern

## Prerequisitos

### Conocimientos Requeridos

- Conceptos basicos de Pods y multi-container Pods
- Comprension de ConfigMaps y como montarlos como volumenes
- Nociones de Python/Flask y PostgreSQL
- Haber completado el Lab 03 (Sidecar Pattern) es recomendable

### Herramientas Necesarias

| Herramienta | Version Minima | Proposito |
|-------------|---------------|-----------|
| `kubectl` | >= 1.24 | Gestion del cluster |
| `docker` | >= 20.10 | Referencia para entender el setup Docker tradicional (docker-setup.sh) |
| `minikube` o cluster K8s | >= 1.24 | Entorno de ejecucion |
| `curl` | cualquiera | Prueba de los endpoints de la app |
| `jq` | cualquiera | Formateo de respuestas JSON |

> **Nota sobre Docker**: El archivo `docker-setup.sh` es solo un punto de comparacion didactico. El laboratorio principal no requiere ejecutar Docker; todos los recursos se despliegan directamente en Kubernetes via `kubectl`.

> **Nota sobre ConfigMaps**: Este laboratorio usa ConfigMaps para distribuir codigo Python (`app.py`), SQL (`migrate.sql`) y scripts shell (`download-config.sh`) a los contenedores. El ConfigMap `setup-scripts` usa `defaultMode: 0755` para que los scripts sean ejecutables.

### Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `docker-setup.sh` | Script Docker tradicional (punto de comparacion) |
| `app.py` | Aplicacion Flask con conexion a PostgreSQL |
| `migrate.sql` | Migracion SQL idempotente para crear tabla users |
| `download-config.sh` | Script de inicializacion con heredoc interno |
| `postgres-pod.yaml` | Pod PostgreSQL 13 + Service ClusterIP |
| `init-pod.yaml` | Pod con 3 Init Containers + contenedor app |
| `cleanup.sh` | Script de limpieza de todos los recursos |

## Verificacion del Entorno

### 1. Verificar cluster

```bash
kubectl cluster-info
kubectl get nodes
```

Salida esperada:
```
Kubernetes control plane is running at https://192.168.49.2:8443
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   5d    v1.28.0
```

### 2. Verificar permisos

```bash
kubectl auth can-i create pods
kubectl auth can-i create configmaps
kubectl auth can-i create services
```

### 3. Verificar archivos del laboratorio

```bash
ls -la /ruta/al/lab-04-init-migration/
# Deben estar: docker-setup.sh, app.py, migrate.sql, download-config.sh,
#              postgres-pod.yaml, init-pod.yaml, cleanup.sh
```

## Notas de Configuracion

- El Init Container `wait-for-db` usa `pg_isready` (incluido en la imagen `postgres:13`) para esperar activamente a que PostgreSQL este disponible, sin necesidad de `sleep` hardcodeado
- El Init Container `db-migration` ejecuta el script SQL via `psql`. La variable `PGPASSWORD` se define como variable de entorno para autenticacion no interactiva
- El Init Container `config-setup` usa la imagen `busybox` y ejecuta `download-config.sh`. El script crea `/app/setup/complete` como "señal" de que el setup termino correctamente
- Los volumenes `app-config` y `setup-status` son `emptyDir`: se crean vacios y los init containers escriben en ellos; el contenedor principal los lee al iniciar
