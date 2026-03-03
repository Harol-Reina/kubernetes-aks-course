# Resumen Practico: Prometheus y Grafana en Kubernetes

**Duracion:** 60 minutos | **Nivel:** Principiante | **Archivo:** `prometheus-lab.yaml`

Un solo YAML despliega Prometheus, Grafana, una webapp con metricas, y un generador de carga para practicar monitoreo de extremo a extremo en Minikube.

---

## Conceptos Previos: Antes de Empezar

Si nunca has trabajado con Prometheus o Grafana, lee esta seccion completa antes de los pasos del lab. Si ya conoces el tema, salta directamente al Paso 0.

### La analogia del termometro digital

Piensa en tu cluster de Kubernetes como un edificio con muchas habitaciones (los Pods). Cada habitacion tiene condiciones diferentes: temperatura, humedad, nivel de ruido.

**Prometheus es como un sistema de sensores automaticos** que mide la temperatura (uso de CPU), el nivel de agua (uso de memoria), y el trafico de personas (peticiones HTTP) en cada habitacion, cada 15 segundos, y guarda todos esos datos en un registro historico.

**Grafana es la pantalla central** en la entrada del edificio donde el administrador puede ver graficos de temperatura de todas las habitaciones a lo largo del tiempo, comparar el consumo de energia entre pisos, y configurar una alarma que avisa si alguna habitacion supera los 40 grados.

Sin este sistema, el administrador tendria que ir fisicamente a cada habitacion y leer un termometro manual. Con Prometheus + Grafana, tiene una vision completa en tiempo real desde un solo lugar.

---

### Por que necesitamos metricas (y por que los logs no son suficientes)

Los **logs** te dicen **que paso**: "ERROR: conexion rechazada a las 14:32". Son utiles para diagnosticar fallos puntuales.

Las **metricas** te dicen **como esta rindiendo el sistema** en este momento y a lo largo del tiempo:

- El uso de CPU lleva subiendo durante 4 horas, ahora esta al 95%
- La memoria de un microservicio crece 2MB cada minuto (fuga de memoria)
- Los tiempos de respuesta se han triplicado en las ultimas 2 horas

Sin metricas, estas situaciones son invisibles hasta que el sistema falla completamente y los usuarios empiezan a quejarse. Con Prometheus, puedes configurar alertas que avisan *antes* del fallo.

```
SIN METRICAS:                     CON METRICAS:

Uso CPU 95%  ← nadie lo sabe     Uso CPU 95%  ← ALERTA enviada
     |                                 |         hace 1 hora
     |  4h despues                     |         equipo ya actuo
     v                                 v
Sistema caido                     Sistema escalado a tiempo
Usuarios afectados                Usuarios no lo notaron
```

---

### El modelo Pull de Prometheus

Existen dos modelos para recolectar metricas:

**Modelo Push**: la aplicacion envia activamente sus metricas a un servidor central cada cierto tiempo. Es como si cada empleado te enviara un correo con su reporte de horas cada hora.

**Modelo Pull**: Prometheus va activamente a buscar las metricas de cada aplicacion segun un intervalo configurado. Es como si tu fueras a hablar con cada empleado y le preguntaras directamente "cuantas horas llevas trabajando hoy".

Prometheus usa el **modelo Pull**:

```
                    cada 15 segundos
                          |
                          v
Prometheus  -----------> GET /metrics  -------> webapp-metricas:9113
(servidor)               (scraping)             (endpoint de metricas)
    |
    | almacena en TSDB
    v
Base de datos
de series temporales
    |
    | PromQL queries
    v
Grafana (dashboards)
```

Ventaja del modelo Pull: Prometheus controla el ritmo. Si un target esta caido, Prometheus lo detecta inmediatamente porque el scraping falla. Con Push, si la app deja de enviar datos, podria pasar desapercibido por mucho tiempo.

---

### Los 3 tipos de metricas que usaras en este lab

Prometheus tiene 4 tipos de metricas, pero en este lab trabajaras principalmente con 3:

**Counter (Contador)**: Solo puede aumentar. Cuenta eventos acumulados desde que el proceso arranco. Nunca decrece (a menos que el proceso se reinicie).

```
nginx_http_requests_total = 1247   <-- total de requests desde que arranco nginx
nginx_http_requests_total = 1248   <-- un segundo despues, un request mas
nginx_http_requests_total = 1249   <-- otro request mas
```

Para ver la *tasa* (requests por segundo), usas `rate()`:
```promql
rate(nginx_http_requests_total[5m])
```
Esto calcula el incremento promedio por segundo en los ultimos 5 minutos.

**Gauge (Indicador)**: Puede subir y bajar. Representa un valor en un instante dado, como un termometro.

```
nginx_connections_active = 12   <-- 12 conexiones activas ahora
nginx_connections_active = 15   <-- tres segundos despues, 3 mas
nginx_connections_active = 8    <-- un minuto despues, bajaron
```

Los Gauges se usan directamente sin `rate()`.

**Histogram (Histograma)**: Mide la distribucion de valores. Util para latencias.

```
http_request_duration_seconds_bucket{le="0.1"}  = 234  ← peticiones <= 100ms
http_request_duration_seconds_bucket{le="0.5"}  = 891  ← peticiones <= 500ms
http_request_duration_seconds_bucket{le="1.0"}  = 943  ← peticiones <= 1 segundo
http_request_duration_seconds_bucket{le="+Inf"} = 950  ← total de peticiones
```

---

### PromQL basico: el lenguaje de consultas de Prometheus

PromQL (Prometheus Query Language) es el lenguaje para consultar los datos almacenados en Prometheus. Funciona en la interfaz web de Prometheus y como fuente de datos para dashboards de Grafana.

Sintaxis basica:

```promql
# 1. Seleccionar una metrica por nombre (devuelve el valor actual)
nginx_http_requests_total

# 2. Filtrar por etiquetas con {}
nginx_http_requests_total{status="200"}

# 3. Usar rate() para ver la tasa de un Counter (cambio por segundo)
rate(nginx_http_requests_total[5m])

# 4. Filtrar por etiqueta de instancia
nginx_connections_active{instance="webapp-metricas:9113"}

# 5. Calcular porcentaje (ejemplo: tasa de errores)
rate(nginx_http_requests_total{status=~"5.."}[5m])
  /
rate(nginx_http_requests_total[5m])
  * 100

# 6. Ver todas las series de una metrica (todas las etiquetas)
up
```

La metrica `up` es especial: Prometheus la crea automaticamente para cada target. Vale `1` si el scraping fue exitoso y `0` si fallo. Es la primera metrica que debes revisar para verificar que Prometheus esta alcanzando tus aplicaciones.

---

### Diagrama completo del flujo

```
                    NAMESPACE: lab-prometheus

  +------------------+     GET /metrics     +-------------------+
  |  webapp-metricas |  <--- cada 15s ---   |    prometheus     |
  |  (nginx + sidecar|                      |  (prom/prometheus)|
  |   nginx-exporter)|  metricas en         |                   |
  |  2 replicas      |  formato Prometheus  |  ConfigMap:       |
  |  Port 9113       |                      |  prometheus.yml   |
  +------------------+                      |  Port 9090        |
          ^                                 +-------------------+
          |                                          |
          |  trafico HTTP                            |  PromQL queries
          |  (~2 req/s)                              v
  +------------------+                      +-------------------+
  | generador-carga  |                      |      grafana      |
  | (busybox loop)   |                      |  (grafana/grafana)|
  |                  |                      |  Port 3000        |
  +------------------+                      +-------------------+
                                                     |
                                                     | Dashboards
                                                     v
                                             [Tu navegador]
                                           minikube service grafana
```

---

## Conceptos Cubiertos en Este Lab

| Concepto | Que practica |
|----------|--------------|
| **Modelo Pull de Prometheus** | Ver como Prometheus hace scraping de targets en /metrics |
| **ConfigMap como configuracion** | Montar prometheus.yml desde un ConfigMap |
| **Patron sidecar exporter** | nginx-exporter convierte stats de nginx a formato Prometheus |
| **NodePort para acceso externo** | Acceder a UI de Prometheus y Grafana desde el navegador |
| **Generador de carga** | Producir trafico real para ver metricas en movimiento |
| **PromQL basico** | Consultar metricas de nginx con rate(), filtros por etiqueta |
| **Datasource en Grafana** | Conectar Grafana con Prometheus como fuente de datos |
| **Dashboard manual** | Crear un panel de visualizacion en Grafana paso a paso |

---

## Paso 0: Preparar Minikube (5 min)

Minikube crea un cluster de Kubernetes local en tu maquina. Para este lab no necesitamos addons adicionales: Prometheus y Grafana se despliegan como Pods normales dentro del cluster.

```bash
minikube start
```

Verificar que el cluster esta listo:

```bash
minikube status
kubectl cluster-info
kubectl get nodes
```

**Salida esperada de `minikube status`:**

```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

**Salida esperada de `kubectl get nodes`:**

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   5m    v1.27.0
```

**Que significa STATUS=Ready**: El nodo esta listo para aceptar cargas de trabajo. Si ves `NotReady`, espera 30 segundos y vuelve a ejecutar el comando.

---

## Paso 1: Desplegar el Stack de Monitoreo (2 min)

Este comando aplica el archivo `prometheus-lab.yaml` que contiene todos los recursos del lab: el namespace, la configuracion de Prometheus, la webapp, el servidor Prometheus, Grafana, y el generador de carga.

```bash
kubectl apply -f prometheus-lab.yaml
```

**Salida esperada:**

```
namespace/lab-prometheus created
configmap/prometheus-config created
deployment.apps/webapp-metricas created
service/webapp-metricas created
deployment.apps/prometheus created
service/prometheus created
deployment.apps/grafana created
service/grafana created
pod/generador-carga created
```

Verificar que los recursos se crearon en el namespace correcto:

```bash
kubectl get all -n lab-prometheus
```

**Salida esperada (los Pods pueden tardar 60-90 segundos en arrancar):**

```
NAME                                   READY   STATUS    RESTARTS   AGE
pod/generador-carga                    1/1     Running   0          90s
pod/grafana-7d9b5c8f4-xk2pq            1/1     Running   0          90s
pod/prometheus-6f7b9c4d8-n3mwz         1/1     Running   0          90s
pod/webapp-metricas-5c8f9d7b6-j4rtk    2/2     Running   0          90s
pod/webapp-metricas-5c8f9d7b6-p8mxn    2/2     Running   0          90s

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
service/grafana           NodePort    10.96.45.123    <none>        3000:30300/TCP
service/prometheus        NodePort    10.96.78.234    <none>        9090:30090/TCP
service/webapp-metricas   ClusterIP   10.96.12.56     <none>        80/TCP,9113/TCP
```

**Nota sobre los 2/2 en webapp-metricas**: El `2/2` indica que hay 2 contenedores en ese Pod (nginx + nginx-exporter) y ambos estan listos. Si ves `1/2`, el sidecar todavia esta arrancando — espera 30 segundos.

**Que acabamos de aprender**: Un solo archivo YAML creo todo el stack de monitoreo. El namespace `lab-prometheus` agrupa todos los recursos y los aísla de otros workloads. Los Services de tipo NodePort exponen Prometheus (puerto 30090) y Grafana (puerto 30300) para que podamos acceder desde el navegador.

---

## Paso 2: Acceder a la UI de Prometheus (5 min)

Prometheus tiene una interfaz web donde puedes ver los targets que esta monitoreando, ejecutar consultas PromQL, y revisar el estado de las reglas de alerta.

```bash
# Obtener la URL de Prometheus (abre el navegador automaticamente en macOS/Linux)
minikube service prometheus -n lab-prometheus --url
```

**Salida esperada:**

```
http://192.168.49.2:30090
```

Copia esa URL y abrela en tu navegador. Tambien puedes usar:

```bash
# Este comando abre el navegador directamente
minikube service prometheus -n lab-prometheus
```

En la interfaz de Prometheus, navega a **Status > Targets** (menu superior). Debes ver la lista de jobs configurados en el ConfigMap:

**Salida esperada en la pagina Targets:**

```
Endpoint                          State    Labels                    Last Scrape
http://localhost:9090/metrics     UP       job="prometheus"          12s ago
http://webapp-metricas:9113/...   UP       job="webapp-metricas"     8s ago
http://generador-carga:8080/...   DOWN     job="generador-carga"     15s ago
```

**Como leer esta tabla:**
- **UP**: Prometheus pudo hacer scraping exitosamente. Hay metricas disponibles.
- **DOWN**: Prometheus no pudo alcanzar ese target. En nuestro lab, `generador-carga` aparecera DOWN porque el Pod de busybox no expone un endpoint `/metrics` real en el puerto 8080 — esta configuracion es solo para ilustrar como se define un job.
- **Last Scrape**: hace cuantos segundos fue el ultimo scraping exitoso.

**Que acabamos de aprender**: La pagina Targets es tu primer punto de verificacion cuando Prometheus no recibe datos. Si un target esta DOWN, la causa puede ser que la app no esta corriendo, que el puerto es incorrecto, o que la ruta `/metrics` no existe.

---

## Paso 3: Explorar Metricas de nginx con PromQL (10 min)

Ahora vamos a usar PromQL para consultar las metricas que Prometheus esta recolectando de nuestra webapp nginx.

En la interfaz de Prometheus, ve a la pagina principal (haz clic en el logo de Prometheus). Hay una barra de busqueda en el centro. Escribe las siguientes consultas una por una y haz clic en **Execute**.

**Consulta 1: Ver si los targets estan UP**

```promql
up
```

Haz clic en **Execute** y luego en la pestana **Table**.

**Salida esperada:**

```
Element                                                     Value
up{instance="localhost:9090", job="prometheus"}             1
up{instance="webapp-metricas:9113", job="webapp-metricas"}  1
up{instance="generador-carga:8080", job="generador-carga"}  0
```

`1` significa que el scraping fue exitoso (target UP). `0` significa fallo (target DOWN). Esta es la metrica mas fundamental de Prometheus.

**Consulta 2: Total de conexiones activas en nginx**

```promql
nginx_connections_active
```

**Salida esperada:**

```
Element                                                           Value
nginx_connections_active{instance="webapp-metricas:9113", ...}   2
nginx_connections_active{instance="webapp-metricas:9113", ...}   3
```

Veras dos filas porque hay 2 replicas de webapp-metricas. Cada instancia reporta sus propias conexiones activas. Este es un **Gauge**: puede subir y bajar.

**Consulta 3: Tasa de requests HTTP por segundo (ultimos 5 minutos)**

```promql
rate(nginx_http_requests_total[5m])
```

**Salida esperada:**

```
Element                                                               Value
nginx_http_requests_total{..., instance="webapp-metricas:9113"...}   1.98
nginx_http_requests_total{..., instance="webapp-metricas:9113"...}   2.03
```

El generador de carga produce aproximadamente 2 requests por segundo. `rate()` toma el incremento del Counter `nginx_http_requests_total` en los ultimos 5 minutos y lo divide por los segundos transcurridos, devolviendo requests/segundo.

**Por que no puedes usar el Counter directamente**: Si ejecutas `nginx_http_requests_total` sin `rate()`, veras un numero que solo crece (por ejemplo, 847). Ese numero representa *todos* los requests desde que nginx arranco — no cuantos estan ocurriendo *ahora mismo*.

**Consulta 4: Desglose por codigo de respuesta HTTP**

```promql
rate(nginx_http_requests_total[5m])
```

Ahora haz clic en **Graph** (en lugar de Table) para ver la evolucion en el tiempo. Debes ver dos lineas: una para las peticiones normales (codigo 200) y otra para las peticiones invalidas (codigo 404) que genera el generador de carga cada 5 requests.

**Que acabamos de aprender**: PromQL distingue entre ver datos en un instante (Table) y ver la evolucion historica (Graph). Para Counters, siempre usamos `rate()` para ver la velocidad de cambio, no el valor acumulado.

---

## Paso 4: Verificar la Configuracion de Prometheus (5 min)

Veamos como Prometheus carga la configuracion desde el ConfigMap.

```bash
# Ver el ConfigMap con la configuracion de Prometheus
kubectl get configmap prometheus-config -n lab-prometheus -o yaml
```

**Salida esperada (fragmento):**

```yaml
apiVersion: v1
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      - job_name: 'webapp-metricas'
        static_configs:
          - targets: ['webapp-metricas:80']
        metrics_path: '/metrics'
...
```

Ahora verifiquemos que el archivo esta correctamente montado dentro del Pod de Prometheus:

```bash
# Obtener el nombre del Pod de Prometheus
kubectl get pod -n lab-prometheus -l app=prometheus

# Leer el archivo de configuracion montado (reemplaza <nombre-pod>)
kubectl exec -n lab-prometheus <nombre-pod> -- cat /etc/prometheus/prometheus.yml
```

**Salida esperada:**

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
...
```

El contenido del ConfigMap esta disponible dentro del contenedor como un archivo en `/etc/prometheus/prometheus.yml`. Esto lo configuramos con `volumeMounts` y `volumes` en el Deployment.

**Recargar la configuracion sin reiniciar el Pod:**

Prometheus soporta recargar su configuracion en caliente si se le envia una peticion POST a `/-/reload`. Esto es util en produccion para aplicar cambios sin downtime:

```bash
# Obtener la IP del Pod de Prometheus
PROM_POD=$(kubectl get pod -n lab-prometheus -l app=prometheus -o jsonpath='{.items[0].metadata.name}')

# Enviar reload (dentro del cluster)
kubectl exec -n lab-prometheus $PROM_POD -- wget -q --post-data='' http://localhost:9090/-/reload -O -
```

**Salida esperada:**

```
Reloading configuration file...
```

**Que acabamos de aprender**: Los ConfigMaps permiten separar la configuracion del codigo de la imagen. Si necesitas cambiar el intervalo de scraping o anadir un nuevo target, solo modificas el ConfigMap y recargas Prometheus — sin necesidad de reconstruir la imagen Docker ni reiniciar el servidor.

---

## Paso 5: Acceder a Grafana y Configurar Datasource (10 min)

Grafana es la herramienta de visualizacion. Se conecta con Prometheus como fuente de datos y permite crear dashboards con graficos, tablas, y alertas visuales.

```bash
# Obtener la URL de Grafana
minikube service grafana -n lab-prometheus --url
```

**Salida esperada:**

```
http://192.168.49.2:30300
```

Abre esa URL en tu navegador. Veras la pantalla de login de Grafana.

**Credenciales:**
- Usuario: `admin`
- Contrasena: `admin123`

Una vez dentro, configura Prometheus como datasource:

1. En el menu lateral izquierdo, haz clic en el icono de engranaje (**Configuration**) y selecciona **Data Sources**.
2. Haz clic en **Add data source**.
3. Selecciona **Prometheus** de la lista.
4. En el campo **URL**, escribe: `http://prometheus:9090`

   El nombre `prometheus` es el nombre del Service de Kubernetes. Dentro del mismo namespace, los Services son accesibles por su nombre gracias a CoreDNS.

5. Haz clic en **Save & Test**.

**Salida esperada:**

```
Data source connected and labels found.
```

Si ves este mensaje, Grafana puede hablar con Prometheus correctamente.

**Por que usamos el nombre del Service y no una IP:**

En Kubernetes, las IPs de los Pods cambian cada vez que el Pod se reinicia. El Service tiene una IP estable, pero incluso mejor: tiene un nombre DNS estable. CoreDNS resuelve `prometheus` a la IP del Service automaticamente. Si el Pod de Prometheus se reinicia y obtiene nueva IP, el Service (y su DNS) siguen apuntando al nuevo Pod.

---

## Paso 6: Crear un Dashboard en Grafana (15 min)

Vamos a crear un dashboard sencillo con 3 paneles para monitorear nuestra webapp:
- Panel 1: Tasa de requests HTTP por segundo
- Panel 2: Conexiones activas en nginx
- Panel 3: Estado de los targets (UP/DOWN)

**Crear el dashboard:**

1. En el menu lateral, haz clic en el icono de cuadrado con + (**Create**) y selecciona **Dashboard**.
2. Haz clic en **Add new panel**.

**Panel 1: Tasa de requests**

En el editor de paneles:
- En el campo **Metrics browser**, escribe:
  ```promql
  rate(nginx_http_requests_total[5m])
  ```
- Haz clic en **Run queries**.
- Deberias ver una linea en el grafico con valores alrededor de 2 (requests por segundo).
- En el panel derecho, en **Panel options**, cambia el **Title** a `Tasa de Requests HTTP (req/s)`.
- Haz clic en **Apply** (esquina superior derecha).

**Panel 2: Conexiones activas**

- Haz clic en **Add panel** y luego **Add new panel**.
- En **Metrics browser**, escribe:
  ```promql
  nginx_connections_active
  ```
- Cambia el **Title** a `Conexiones Activas en nginx`.
- Haz clic en **Apply**.

**Panel 3: Estado de targets**

- Haz clic en **Add panel** y luego **Add new panel**.
- En **Metrics browser**, escribe:
  ```promql
  up
  ```
- En **Panel options**, cambia el **Title** a `Estado de Targets (1=UP, 0=DOWN)`.
- Haz clic en **Apply**.

**Guardar el dashboard:**

- Haz clic en el icono de disco (save) en la barra superior.
- Nombre: `Dashboard Prometheus Lab`.
- Haz clic en **Save**.

**Que deberias ver en el dashboard:**

```
Panel 1: Tasa de Requests             Panel 2: Conexiones Activas
+----------------------------------+  +----------------------------------+
|                                  |  |                                  |
|  ~2.0 req/s  --------            |  |  2-5 conexiones  ---___---       |
|              (generador activo)  |  |  (fluctua con trafico)           |
+----------------------------------+  +----------------------------------+

Panel 3: Estado de Targets
+----------------------------------+
|  prometheus: 1 (UP)              |
|  webapp-metricas: 1 (UP)         |
|  generador-carga: 0 (DOWN)       |
+----------------------------------+
```

**Que acabamos de aprender**: Grafana usa PromQL para obtener datos de Prometheus y los visualiza en tiempo real. Cada panel es independiente y puede tener su propia consulta, rango de tiempo, y tipo de visualizacion.

---

## Paso 7: Explorar las Metricas del Generador de Carga (5 min)

El generador de carga esta produciendo trafico continuamente hacia la webapp. Vamos a observar ese trafico en tiempo real desde la linea de comandos y desde Prometheus.

```bash
# Ver los logs del generador para confirmar que esta activo
kubectl logs generador-carga -n lab-prometheus --tail=20
```

**Salida esperada:**

```
Iniciando generador de carga hacia webapp-metricas...
Request 20 - aplicando delay de 2s (simulacion de carga)
Request 40 - aplicando delay de 2s (simulacion de carga)
```

Cada 20 requests el generador hace una pausa de 2 segundos. Esto simula momentos de carga alta y deberia ser visible como caidas breves en el grafico de `rate()` en Prometheus.

Ahora observa las metricas directamente desde el endpoint del exporter de nginx:

```bash
# Acceder al endpoint /metrics del nginx-exporter directamente
WEBAPP_POD=$(kubectl get pod -n lab-prometheus -l app=webapp-metricas -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n lab-prometheus $WEBAPP_POD -c nginx-exporter -- wget -q -O - http://localhost:9113/metrics | head -30
```

**Salida esperada:**

```
# HELP nginx_connections_accepted Accepted client connections
# TYPE nginx_connections_accepted counter
nginx_connections_accepted 847
# HELP nginx_connections_active Active client connections
# TYPE nginx_connections_active gauge
nginx_connections_active 2
# HELP nginx_connections_handled Handled connections
# TYPE nginx_connections_handled counter
nginx_connections_handled 847
# HELP nginx_connections_reading Connections where NGINX is reading the request header
# TYPE nginx_connections_reading gauge
nginx_connections_reading 0
# HELP nginx_connections_waiting Idle client connections
# TYPE nginx_connections_waiting gauge
nginx_connections_waiting 1
# HELP nginx_connections_writing Connections where NGINX is writing the response back to the client
# TYPE nginx_connections_writing gauge
nginx_connections_writing 1
# HELP nginx_http_requests_total Total http requests
# TYPE nginx_http_requests_total counter
nginx_http_requests_total 1892
```

**Como leer este formato Prometheus:**

- `# HELP`: descripcion de la metrica.
- `# TYPE counter/gauge/histogram`: tipo de la metrica.
- La linea siguiente: `nombre_metrica{etiquetas} valor`.

Este es exactamente el formato de texto que Prometheus espera cuando hace scraping de un endpoint `/metrics`. Cualquier aplicacion que exponga sus datos en este formato puede ser monitoreada por Prometheus.

**Verificar en Prometheus que los datos llegaron:**

En la interfaz de Prometheus, ejecuta:

```promql
nginx_http_requests_total
```

Compara el valor con lo que viste en el exec anterior. Deben ser similares (el scraping ocurre cada 15 segundos, por lo que puede haber una pequena diferencia).

---

## Paso 8: Limpiar (3 min)

El script de limpieza elimina el namespace `lab-prometheus` y todos los recursos dentro de el (Prometheus, Grafana, webapp, generador, ConfigMap, Services), luego restaura el contexto de kubectl al namespace `default`.

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-prometheus
kubectl config set-context --current --namespace=default
```

**Salida esperada del cleanup.sh:**

```
Iniciando limpieza del Lab Resumen Prometheus...

  Eliminando namespace lab-prometheus y todos sus recursos...
  ✓ namespace/lab-prometheus eliminado (Prometheus, Grafana, webapp, generador incluidos)

Restaurando namespace por defecto...
  ✓ Contexto restaurado a namespace 'default'

Limpieza completada!
```

**Verificar que la limpieza fue exitosa:**

```bash
kubectl get ns lab-prometheus
```

**Salida esperada:**

```
Error from server (NotFound): namespaces "lab-prometheus" not found
```

---

## Diagrama de Recursos del Lab

```
NAMESPACE: lab-prometheus
|
+-- ConfigMap: prometheus-config
|     prometheus.yml con 3 jobs de scraping
|
+-- Deployment: webapp-metricas (2 replicas)
|   +-- Container: nginx (puerto 80)
|   +-- Container: nginx-exporter (puerto 9113, metricas)
|   Service: webapp-metricas (ClusterIP, 80 y 9113)
|
+-- Deployment: prometheus (1 replica)
|   +-- Container: prom/prometheus (puerto 9090)
|   +-- Volume: prometheus-config (desde ConfigMap)
|   +-- Volume: prometheus-data (emptyDir)
|   Service: prometheus (NodePort 30090)
|
+-- Deployment: grafana (1 replica)
|   +-- Container: grafana/grafana (puerto 3000)
|   +-- Volume: grafana-data (emptyDir)
|   Service: grafana (NodePort 30300)
|
+-- Pod: generador-carga
      +-- Container: busybox (bucle curl cada 0.5s)
```

---

## Resumen: Lo Que Aprendiste en Este Lab

Al completar este lab has practicado los siguientes conceptos:

- **Modelo Pull de Prometheus**: Prometheus va activamente a buscar metricas de cada target definido en `scrape_configs`, cada 15 segundos.
- **ConfigMap como configuracion**: La configuracion de Prometheus (`prometheus.yml`) se almacena en un ConfigMap y se monta dentro del Pod mediante `volumeMounts`.
- **Patron sidecar exporter**: Cuando una aplicacion no expone metricas en formato Prometheus de forma nativa, se agrega un contenedor sidecar (el exporter) que traduce las stats de la app al formato esperado.
- **Tipos de metricas**: Counter (solo sube, usar `rate()`), Gauge (sube y baja, usar directo), Histogram (distribucion de valores).
- **PromQL basico**: `up` para verificar targets, `rate(counter[5m])` para tasas, filtros con `{}`.
- **NodePort para acceso desde el navegador**: Los Services de tipo NodePort exponen aplicaciones del cluster a tu maquina local a traves de un puerto fijo en el nodo de Minikube.
- **Grafana Datasource**: Grafana se conecta con Prometheus usando el nombre DNS del Service (`http://prometheus:9090`) como URL del datasource.
- **Dashboards en Grafana**: Cada panel del dashboard ejecuta una consulta PromQL y visualiza los resultados en tiempo real.

---

## Referencia Rapida de Comandos

```bash
# Desplegar el lab completo
kubectl apply -f prometheus-lab.yaml

# Ver el estado de todos los recursos
kubectl get all -n lab-prometheus

# Obtener URL de Prometheus (abrir en navegador)
minikube service prometheus -n lab-prometheus --url

# Obtener URL de Grafana (abrir en navegador)
minikube service grafana -n lab-prometheus --url

# Ver logs del generador de carga
kubectl logs generador-carga -n lab-prometheus -f

# Ver metricas crudas del nginx-exporter
WEBAPP_POD=$(kubectl get pod -n lab-prometheus -l app=webapp-metricas -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n lab-prometheus $WEBAPP_POD -c nginx-exporter -- wget -q -O - http://localhost:9113/metrics

# Ver el ConfigMap de Prometheus
kubectl get configmap prometheus-config -n lab-prometheus -o yaml

# Entrar al Pod de Prometheus para inspeccionar
kubectl exec -it -n lab-prometheus $(kubectl get pod -n lab-prometheus -l app=prometheus -o jsonpath='{.items[0].metadata.name}') -- sh

# Limpiar todo
./cleanup.sh
```

---

## Consultas PromQL de Referencia para Este Lab

```promql
# Estado de todos los targets (1=UP, 0=DOWN)
up

# Tasa de requests HTTP de nginx (req/s en ultimos 5 min)
rate(nginx_http_requests_total[5m])

# Conexiones activas en nginx
nginx_connections_active

# Conexiones en espera (idle)
nginx_connections_waiting

# Total de requests acumulados desde que arranco nginx
nginx_http_requests_total

# Metricas internas de Prometheus: cuantos targets tiene
prometheus_sd_discovered_targets

# Cada cuanto hace scraping Prometheus (en segundos)
scrape_interval_seconds
```
