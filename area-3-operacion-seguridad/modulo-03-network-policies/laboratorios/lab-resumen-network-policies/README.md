# Resumen Practico: Network Policies en Kubernetes

**Duracion:** 60 minutos | **Nivel:** Principiante absoluto | **Archivo:** `network-policies-lab.yaml`

Un solo YAML despliega 3 microservicios (frontend, backend, database), un Pod de prueba, y todas las NetworkPolicies necesarias para implementar el patron de seguridad mas comun en produccion: default deny + reglas selectivas.

---

## Conceptos Previos (Lee esto antes de ejecutar cualquier comando)

Si nunca has trabajado con Network Policies, esta seccion te explica todo lo que necesitas saber para entender lo que vas a ver en el lab. No saltes este bloque.

---

### La analogia del edificio con guardia de seguridad

Imagina que tu cluster es un edificio corporativo con tres pisos:

```
Piso 3: Base de Datos     (recursos mas sensibles)
Piso 2: Backend / API     (logica de negocio)
Piso 1: Frontend / Web    (lo que ve el usuario)
```

**Sin Network Policies** — sin guardia de seguridad:

Cualquier persona que entre al edificio puede ir a cualquier piso. Si alguien malo entra por la puerta del frontend (por ejemplo, explotando una vulnerabilidad en la aplicacion web), puede subir directamente al piso 3 y acceder a los datos de la base de datos. No hay nada que lo detenga.

**Con Network Policies** — con guardia de seguridad:

El guardia revisa a cada persona antes de dejarla pasar de un piso a otro. Las reglas son:

- El frontend solo puede subir al piso del backend (no al de la base de datos).
- El backend solo puede bajar al piso de la base de datos.
- Un intruso que entre al frontend no puede ir a ningun otro piso: el guardia lo bloquea.

Ese "guardia de seguridad" es el CNI (Container Network Interface) del cluster, el componente de red que aplica las NetworkPolicies. Sin un CNI que las soporte (como Calico o Cilium), las reglas se escriben pero no se aplican.

---

### Que es una NetworkPolicy

Una **NetworkPolicy** es un recurso de Kubernetes que actua como una lista de control de acceso (ACL) a nivel de red. Define que Pods pueden recibir trafico (ingress) y que Pods pueden enviar trafico (egress).

Estructura basica en YAML:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mi-politica
  namespace: mi-namespace
spec:
  podSelector:          # <-- A que Pods aplica esta regla?
    matchLabels:
      app: backend
  policyTypes:
  - Ingress             # <-- Controla trafico ENTRANTE al Pod
  - Egress              # <-- Controla trafico SALIENTE del Pod
  ingress:
  - from:               # <-- Desde donde se permite el trafico entrante?
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080        # <-- En que puerto?
```

Traduccion al lenguaje natural: "Esta regla aplica a los Pods con label `app: backend`. Controla el trafico de entrada. Solo se permite trafico entrante si viene de Pods con label `app: frontend`, y solo al puerto 8080."

---

### Ingress vs Egress: la puerta de entrada y la puerta de salida

Desde el punto de vista de un Pod, hay dos direcciones de trafico:

```
                           POD
                    +----------------+
 trafico entrante   |                |   trafico saliente
 (INGRESS)   -----> |   contenedor   | -------> (EGRESS)
                    |                |
                    +----------------+
```

**Ingress** controla quien puede llamar a este Pod. Si tienes una regla de ingress, defines quienes tienen permiso para establecer una conexion hacia este Pod.

Analogia: el ingress es la puerta de entrada de tu oficina. Tu decides quien puede tocar el timbre y entrar.

**Egress** controla a donde puede llamar este Pod. Si tienes una regla de egress, defines a que destinos tiene permitido conectarse este Pod.

Analogia: el egress es la puerta de salida de tu oficina. Tu decides a que lugares exteriores puede ir.

En la mayoria de arquitecturas de microservicios basta con controlar el ingress. El egress es importante para evitar que un Pod comprometido "llame a casa" (exfiltracion de datos) o se conecte a servicios que no deberia.

---

### Como una NetworkPolicy selecciona a que Pods aplica

El campo `podSelector` en una NetworkPolicy determina a que Pods se aplica la regla. Usa labels para seleccionarlos.

**Ejemplo:** Si tienes Pods con estos labels:

```yaml
# Pod del backend
labels:
  app: backend
  tier: backend

# Pod del frontend
labels:
  app: frontend
  tier: frontend
```

Y una NetworkPolicy con:

```yaml
podSelector:
  matchLabels:
    tier: backend
```

La NetworkPolicy aplica SOLO a los Pods que tienen el label `tier: backend`. Los Pods de frontend y cualquier otro Pod sin ese label no se ven afectados por esta regla.

**El caso especial: podSelector vacio**

```yaml
podSelector: {}
```

Un selector vacio sin matchLabels significa "todos los Pods del namespace". Se usa para crear una politica default deny que afecte a todos.

---

### La politica default deny: bloquear todo por defecto

El patron de seguridad mas recomendado en Kubernetes es:

1. Primero bloquear todo el trafico (deny-all).
2. Luego permitir solo lo necesario con reglas especificas.

Esto se llama "modelo de privilegio minimo" o "zero trust networking".

Tabla comparativa de comportamiento:

```
+------------------------+------------------+------------------+---------------------+
| Situacion              | Pod A → Pod B    | Pod B → Pod A    | Notas               |
+------------------------+------------------+------------------+---------------------+
| Sin ninguna policy     | Permitido        | Permitido        | Red plana (default) |
| Solo deny-all          | Bloqueado        | Bloqueado        | Todo bloqueado      |
| deny-all + allow A→B   | Permitido        | Bloqueado        | Solo una direccion  |
| deny-all + allow A↔B   | Permitido        | Permitido        | Ambas direcciones   |
+------------------------+------------------+------------------+---------------------+
```

**Una NetworkPolicy que bloquea todo se ve asi:**

```yaml
spec:
  podSelector: {}       # Aplica a todos los Pods
  policyTypes:
  - Ingress
  - Egress
  # Sin reglas from/to = no se permite nada
```

Sin reglas `ingress.from` ni `egress.to`, la policy no permite ningun trafico. Es el equivalente a un firewall con la politica "DROP ALL".

---

### Diagrama del flujo que construiremos en este lab

```
ESTADO FINAL (con todas las policies aplicadas):

  Internet / Pod externo
         |
         | ✗ BLOQUEADO
         v
  +-------------+
  |  test-tools |  <--- No tiene labels especiales
  +-------------+
         |
         | ✗ BLOQUEADO a backend y database
         |
  +-------------+
  |   frontend  |  <--- tier: frontend
  |  :80        |
  +-------------+
         |
         | ✓ PERMITIDO (allow-frontend-to-backend)
         v
  +-------------+
  |   backend   |  <--- tier: backend
  |  :8080      |
  +-------------+
         |
         | ✓ PERMITIDO (allow-backend-to-database)
         v
  +-------------+
  |  database   |  <--- tier: database
  |  :5432      |
  +-------------+

Regla DNS (allow-dns):
  Todos los Pods → CoreDNS :53  ✓ PERMITIDO
```

---

## Que aprenderemos en este lab

| Concepto | Que demuestra |
|----------|---------------|
| **Red plana por defecto** | Sin policies, todo Pod puede hablar con todo Pod |
| **deny-all (default deny)** | Bloquear todo el trafico como punto de partida |
| **allow-dns** | Por que DNS necesita su propia politica de egress |
| **Ingress selectivo por labels** | Permitir trafico solo desde Pods especificos |
| **Flujo encadenado** | frontend → backend → database como arquitectura de tres capas |
| **Verificacion con wget** | Confirmar que las reglas funcionan con pruebas reales |
| **Troubleshooting** | Diagnosticar cuando una policy bloquea trafico inesperadamente |

---

## Paso 0: Preparar Minikube con soporte de NetworkPolicies (5 min)

Este es el paso mas importante. Las NetworkPolicies **no funcionan** con el CNI por defecto de Minikube (kindnet). Necesitas iniciar Minikube con Calico, que es un CNI que si aplica las reglas de red.

**Por que el CNI importa?**

El CNI (Container Network Interface) es el componente responsable de la red entre Pods. Cuando creas una NetworkPolicy, Kubernetes la almacena en etcd, pero es el CNI quien la lee y configura las reglas en el kernel de cada nodo. Si el CNI no soporta NetworkPolicies, las reglas se guardan pero nunca se aplican — todo el trafico sigue funcionando como si no existieran.

```bash
# Detener cualquier Minikube existente
minikube stop

# Iniciar Minikube con Calico como CNI
# IMPORTANTE: --cni=calico instala Calico automaticamente
minikube start --cni=calico
```

**Salida esperada:**

```
* minikube v1.32.0 on Linux
* Using the docker driver based on existing profile
* Starting control plane node minikube in cluster minikube
* Pulling base image ...
* Restarting existing docker container for "minikube" ...
* Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
* Configuring Calico (Container Networking Interface) ...
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

Verificar que Calico esta funcionando:

```bash
# Los Pods de Calico deben estar Running
kubectl get pods -n kube-system | grep calico
```

**Salida esperada:**

```
calico-kube-controllers-xxxx   1/1     Running   0          2m
calico-node-xxxx               1/1     Running   0          2m
```

Si los Pods de Calico no aparecen o no estan Running, espera 2-3 minutos y vuelve a ejecutar el comando.

Verificar el estado del cluster:

```bash
kubectl cluster-info
kubectl get nodes
```

**Salida esperada:**

```
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/...

NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   3m    v1.28.3
```

> **Que aprendimos en el Paso 0:** El soporte de NetworkPolicies depende del CNI, no de Kubernetes en si. En produccion en Azure AKS puedes habilitar Azure Network Policy o Calico. En AWS EKS se usa Calico o VPC CNI con network policy support. Siempre verifica que tu CNI soporte NetworkPolicies antes de usarlas.

---

## Paso 1: Desplegar todo (2 min)

```bash
kubectl apply -f network-policies-lab.yaml
```

**Salida esperada:**

```
namespace/lab-network-policies created
deployment.apps/frontend created
service/frontend created
deployment.apps/backend created
service/backend created
deployment.apps/database created
service/database created
pod/test-tools created
networkpolicy.networking.k8s.io/deny-all created
networkpolicy.networking.k8s.io/allow-dns created
networkpolicy.networking.k8s.io/allow-frontend-to-backend created
networkpolicy.networking.k8s.io/allow-backend-to-database created
```

Verificar que todos los recursos estan corriendo:

```bash
kubectl get all -n lab-network-policies
```

**Salida esperada:**

```
NAME                            READY   STATUS    RESTARTS   AGE
pod/backend-xxxxxxxxxx-xxxxx    1/1     Running   0          30s
pod/backend-xxxxxxxxxx-yyyyy    1/1     Running   0          30s
pod/database-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
pod/frontend-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
pod/frontend-xxxxxxxxxx-yyyyy   1/1     Running   0          30s
pod/test-tools                  1/1     Running   0          30s

NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/backend    ClusterIP   10.96.xxx.xxx   <none>        8080/TCP   30s
service/database   ClusterIP   10.96.xxx.xxx   <none>        5432/TCP   30s
service/frontend   ClusterIP   10.96.xxx.xxx   <none>        80/TCP     30s

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/backend    2/2     2            2           30s
deployment.apps/database   1/1     1            1           30s
deployment.apps/frontend   2/2     2            2           30s
```

Ver las NetworkPolicies creadas:

```bash
kubectl get networkpolicies -n lab-network-policies
```

**Salida esperada:**

```
NAME                         POD-SELECTOR      AGE
allow-backend-to-database    tier=database     30s
allow-dns                    <none>            30s
allow-frontend-to-backend    tier=backend      30s
deny-all                     <none>            30s
```

> **Que aprendimos en el Paso 1:** Un solo `kubectl apply -f` creo todos los recursos declarados en el YAML — namespace, Deployments, Services, Pod de prueba y las NetworkPolicies — en el orden correcto. Observa la columna POD-SELECTOR: `<none>` significa que aplica a todos los Pods (selector vacio `{}`), mientras que `tier=database` significa que aplica solo a Pods con ese label.

---

## Paso 2: Verificar conectividad ANTES de las policies — todo funciona (8 min)

**IMPORTANTE:** Este paso funciona SOLO si primero eliminas las NetworkPolicies del YAML. Como el YAML las incluye, las policies ya estan activas desde el Paso 1. Para simular el estado "sin policies" desde el Pod `test-tools`, vamos a observar lo que esta bloqueado y contrastarlo con lo que deberia estar libre.

Para ver el efecto completo de "red plana vs. policies", ejecuta este bloque de pruebas desde `test-tools`. Primero veamos el estado actual (con deny-all activo):

```bash
# Entrar al Pod test-tools
kubectl exec -it test-tools -n lab-network-policies -- sh
```

Dentro del Pod, probar conectividad a todos los servicios:

```sh
# Intentar conectarse al frontend (puerto 80)
# Timeout de 3 segundos para no esperar demasiado
wget -T 3 -qO- http://frontend:80 && echo "EXITO: frontend alcanzado" || echo "BLOQUEADO: frontend no accesible"

# Intentar conectarse al backend (puerto 8080)
wget -T 3 -qO- http://backend:8080 && echo "EXITO: backend alcanzado" || echo "BLOQUEADO: backend no accesible"

# Intentar conectarse a la database (puerto 5432)
wget -T 3 -qO- http://database:5432 && echo "EXITO: database alcanzado" || echo "BLOQUEADO: database no accesible"

# Verificar que DNS funciona (la policy allow-dns lo permite)
nslookup frontend.lab-network-policies.svc.cluster.local

exit
```

**Salida esperada con las policies activas:**

```
wget: download timed out
BLOQUEADO: frontend no accesible
wget: download timed out
BLOQUEADO: backend no accesible
wget: download timed out
BLOQUEADO: database no accesible

Server:         10.96.0.10
Address:        10.96.0.10:53
Name:   frontend.lab-network-policies.svc.cluster.local
Address: 10.96.xxx.xxx
```

Observa que:
- `test-tools` no puede alcanzar a ninguno de los servicios (deny-all lo bloquea).
- DNS si funciona porque la policy `allow-dns` permite el puerto 53 UDP/TCP en egress.

> **Que aprendimos en el Paso 2:** El deny-all ya esta activo y bloquea todo el trafico entre Pods, EXCEPTO DNS. Esto es exactamente lo que queremos: el punto de partida del modelo "zero trust". Nadie puede hablar con nadie hasta que lo autoricemos explicitamente.

---

## Paso 3: Examinar la policy deny-all en detalle (5 min)

Ver la descripcion completa de la policy deny-all:

```bash
kubectl describe networkpolicy deny-all -n lab-network-policies
```

**Salida esperada:**

```
Name:         deny-all
Namespace:    lab-network-policies
Created on:   2026-03-03 10:00:00 +0000 UTC
Labels:       policy=default-deny
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    <none> (Selected pods are isolated for ingress connectivity)
  Allowing egress traffic:
    <none> (Selected pods are isolated for egress connectivity)
  Policy Types: Ingress, Egress
```

Ver tambien la policy allow-dns para entender por que DNS sigue funcionando:

```bash
kubectl describe networkpolicy allow-dns -n lab-network-policies
```

**Salida esperada:**

```
Name:         allow-dns
Namespace:    lab-network-policies
...
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing egress traffic:
    To Port: 53/UDP
    To Port: 53/TCP
    To: <any> (traffic not restricted by destination)
  Policy Types: Egress
```

Verificar los labels de cada grupo de Pods (los que usan los selectors de las policies):

```bash
# Ver los labels de todos los Pods del namespace
kubectl get pods -n lab-network-policies --show-labels
```

**Salida esperada:**

```
NAME                          READY   STATUS    LABELS
backend-xxx-yyy               1/1     Running   app=backend,pod-template-hash=xxx,tier=backend
backend-xxx-zzz               1/1     Running   app=backend,pod-template-hash=xxx,tier=backend
database-xxx-yyy              1/1     Running   app=database,pod-template-hash=xxx,tier=database
frontend-xxx-yyy              1/1     Running   app=frontend,pod-template-hash=xxx,tier=frontend
frontend-xxx-zzz              1/1     Running   app=frontend,pod-template-hash=xxx,tier=frontend
test-tools                    1/1     Running   app=test-tools,role=test
```

Observa que `test-tools` tiene `role: test` pero no tiene `tier: frontend` ni `tier: backend`. Por eso las policies de allow no lo incluiran como origen autorizado.

> **Que aprendimos en el Paso 3:** Las NetworkPolicies usan labels para seleccionar Pods. El `podSelector` en el campo `spec` determina a que Pods aplica la regla. El `podSelector` dentro de `ingress.from` o `egress.to` determina desde/hacia donde se permite el trafico. Los labels son el mecanismo de enlace entre Pods y policies.

---

## Paso 4: Aplicar la policy allow-frontend-to-backend y verificar (10 min)

La policy `allow-frontend-to-backend` ya esta activa desde el Paso 1 (esta en el mismo YAML). Vamos a verificar su efecto desde un Pod de frontend.

Primero, obtener el nombre de un Pod de frontend:

```bash
FRONTEND_POD=$(kubectl get pods -n lab-network-policies -l tier=frontend -o jsonpath='{.items[0].metadata.name}')
echo "Pod frontend seleccionado: $FRONTEND_POD"
```

**Salida esperada:**

```
Pod frontend seleccionado: frontend-xxxxxxxxxx-xxxxx
```

Probar conectividad desde el frontend al backend (deberia funcionar):

```bash
kubectl exec -it $FRONTEND_POD -n lab-network-policies -- sh -c \
  'wget -T 5 -qO- http://backend:8080 && echo "EXITO: frontend puede alcanzar backend" || echo "FALLO: frontend no puede alcanzar backend"'
```

**Salida esperada:**

```
<h1>Backend API</h1>
<p>Microservicio: backend</p>
<p>Puerto: 8080</p>
EXITO: frontend puede alcanzar backend
```

Ahora verificar que el frontend NO puede alcanzar la database directamente:

```bash
kubectl exec -it $FRONTEND_POD -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://database:5432 && echo "EXITO: frontend puede alcanzar database" || echo "BLOQUEADO: frontend no puede alcanzar database (correcto!)"'
```

**Salida esperada:**

```
wget: download timed out
BLOQUEADO: frontend no puede alcanzar database (correcto!)
```

Verificar que test-tools tampoco puede alcanzar el backend (el selector lo excluye):

```bash
kubectl exec -it test-tools -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://backend:8080 && echo "EXITO" || echo "BLOQUEADO: test-tools no puede alcanzar backend (correcto!)"'
```

**Salida esperada:**

```
wget: download timed out
BLOQUEADO: test-tools no puede alcanzar backend (correcto!)
```

Ver la descripcion de la policy para entender por que:

```bash
kubectl describe networkpolicy allow-frontend-to-backend -n lab-network-policies
```

**Salida esperada:**

```
Name:         allow-frontend-to-backend
Namespace:    lab-network-policies
Spec:
  PodSelector: tier=backend
  Allowing ingress traffic:
    To Port: 8080/TCP
    From:
      PodSelector: tier=frontend
  Policy Types: Ingress
```

> **Que aprendimos en el Paso 4:** La NetworkPolicy `allow-frontend-to-backend` actua como un filtro en la puerta de entrada del backend. Solo deja pasar trafico que viene de Pods con label `tier: frontend`. El Pod `test-tools` (que tiene `role: test`) no cumple esa condicion y queda bloqueado. La database tambien queda bloqueada porque no tiene `tier: frontend`. El label es el "carnet de identificacion" que el guardia revisa.

---

## Paso 5: Verificar que solo el trafico permitido funciona (5 min)

Este paso hace un resumen de lo que esta permitido y lo que esta bloqueado. Ejecuta todos los comandos y compara con la tabla al final.

Pruebas desde test-tools (Pod sin labels de tier):

```bash
# Prueba 1: test-tools → frontend (deberia estar bloqueado)
kubectl exec -it test-tools -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://frontend:80 > /dev/null && echo "[1] test→frontend: PERMITIDO" || echo "[1] test→frontend: BLOQUEADO"'

# Prueba 2: test-tools → backend (deberia estar bloqueado)
kubectl exec -it test-tools -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://backend:8080 > /dev/null && echo "[2] test→backend: PERMITIDO" || echo "[2] test→backend: BLOQUEADO"'

# Prueba 3: test-tools → database (deberia estar bloqueado)
kubectl exec -it test-tools -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://database:5432 > /dev/null && echo "[3] test→database: PERMITIDO" || echo "[3] test→database: BLOQUEADO"'
```

Prueba desde frontend:

```bash
FRONTEND_POD=$(kubectl get pods -n lab-network-policies -l tier=frontend -o jsonpath='{.items[0].metadata.name}')

# Prueba 4: frontend → backend (deberia estar permitido)
kubectl exec -it $FRONTEND_POD -n lab-network-policies -- sh -c \
  'wget -T 5 -qO- http://backend:8080 > /dev/null && echo "[4] frontend→backend: PERMITIDO" || echo "[4] frontend→backend: BLOQUEADO"'

# Prueba 5: frontend → database (deberia estar bloqueado)
kubectl exec -it $FRONTEND_POD -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://database:5432 > /dev/null && echo "[5] frontend→database: PERMITIDO" || echo "[5] frontend→database: BLOQUEADO"'
```

**Salida esperada:**

```
[1] test→frontend: BLOQUEADO
[2] test→backend: BLOQUEADO
[3] test→database: BLOQUEADO
[4] frontend→backend: PERMITIDO
[5] frontend→database: BLOQUEADO
```

Tabla de estado a este punto:

```
+------------------+----------+---------+----------+----------+
| Origen           | frontend | backend | database | DNS :53  |
+------------------+----------+---------+----------+----------+
| test-tools       | BLOCK    | BLOCK   | BLOCK    | ALLOW    |
| frontend         | BLOCK*   | ALLOW   | BLOCK    | ALLOW    |
| backend          | BLOCK    | BLOCK   | BLOCK    | ALLOW    |
| database         | BLOCK    | BLOCK   | BLOCK    | ALLOW    |
+------------------+----------+---------+----------+----------+
* frontend no puede llamarse a si mismo por el deny-all de ingress
```

> **Que aprendimos en el Paso 5:** Las policies son selectivas y unidireccionales. `allow-frontend-to-backend` solo permite el trafico frontend → backend, no backend → frontend. Tampoco autoriza a test-tools aunque intente acceder al mismo puerto. El label `tier: frontend` es el que diferencia a un Pod autorizado de uno no autorizado.

---

## Paso 6: Aplicar la policy allow-backend-to-database y verificar (10 min)

La policy `allow-backend-to-database` tambien esta activa desde el Paso 1. Vamos a verificarla desde el backend.

Obtener el nombre de un Pod de backend:

```bash
BACKEND_POD=$(kubectl get pods -n lab-network-policies -l tier=backend -o jsonpath='{.items[0].metadata.name}')
echo "Pod backend seleccionado: $BACKEND_POD"
```

**Salida esperada:**

```
Pod backend seleccionado: backend-xxxxxxxxxx-xxxxx
```

Probar que el backend puede alcanzar la database:

```bash
kubectl exec -it $BACKEND_POD -n lab-network-policies -- sh -c \
  'wget -T 5 -qO- http://database:5432 && echo "EXITO: backend puede alcanzar database" || echo "FALLO: backend no puede alcanzar database"'
```

**Salida esperada:**

```
<h1>Database</h1>
<p>Microservicio: database (simulado con nginx)</p>
<p>Puerto: 5432 (PostgreSQL)</p>
EXITO: backend puede alcanzar database
```

Verificar que el backend NO puede alcanzar el frontend (no existe esa policy):

```bash
kubectl exec -it $BACKEND_POD -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://frontend:80 > /dev/null && echo "PERMITIDO" || echo "BLOQUEADO: backend no puede alcanzar frontend (correcto!)"'
```

**Salida esperada:**

```
wget: download timed out
BLOQUEADO: backend no puede alcanzar frontend (correcto!)
```

Ver la descripcion de la policy:

```bash
kubectl describe networkpolicy allow-backend-to-database -n lab-network-policies
```

**Salida esperada:**

```
Name:         allow-backend-to-database
Namespace:    lab-network-policies
Spec:
  PodSelector: tier=database
  Allowing ingress traffic:
    To Port: 5432/TCP
    From:
      PodSelector: tier=backend
  Policy Types: Ingress
```

> **Que aprendimos en el Paso 6:** La policy `allow-backend-to-database` sigue el mismo patron que la anterior pero protege la capa de datos. Solo los Pods con `tier: backend` pueden conectarse al puerto 5432. El frontend, test-tools y cualquier otro Pod quedan bloqueados. Nota importante: las politicas de ingress se escriben desde la perspectiva del Pod DESTINO (la database), no del Pod origen (el backend).

---

## Paso 7: Verificar el flujo completo frontend → backend → database (10 min)

Este paso simula el flujo real de una aplicacion de tres capas. La peticion de un usuario llega al frontend, el frontend consulta al backend, y el backend consulta a la database.

Verificacion del flujo completo en un solo bloque:

```bash
FRONTEND_POD=$(kubectl get pods -n lab-network-policies -l tier=frontend -o jsonpath='{.items[0].metadata.name}')
BACKEND_POD=$(kubectl get pods -n lab-network-policies -l tier=backend -o jsonpath='{.items[0].metadata.name}')

echo "=== Verificando flujo: frontend → backend ==="
kubectl exec -it $FRONTEND_POD -n lab-network-policies -- sh -c \
  'wget -T 5 -qO- http://backend:8080 > /dev/null && echo "frontend → backend: OK" || echo "frontend → backend: FALLO"'

echo ""
echo "=== Verificando flujo: backend → database ==="
kubectl exec -it $BACKEND_POD -n lab-network-policies -- sh -c \
  'wget -T 5 -qO- http://database:5432 > /dev/null && echo "backend → database: OK" || echo "backend → database: FALLO"'

echo ""
echo "=== Verificando bloqueo: frontend NO puede ir a database ==="
kubectl exec -it $FRONTEND_POD -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://database:5432 > /dev/null && echo "frontend → database: PERMITIDO (INCORRECTO!)" || echo "frontend → database: BLOQUEADO (correcto)"'

echo ""
echo "=== Verificando bloqueo: test-tools no puede ir a ninguno ==="
kubectl exec -it test-tools -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://frontend:80 > /dev/null && echo "test → frontend: PERMITIDO" || echo "test → frontend: BLOQUEADO (correcto)"'
kubectl exec -it test-tools -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://backend:8080 > /dev/null && echo "test → backend: PERMITIDO" || echo "test → backend: BLOQUEADO (correcto)"'
kubectl exec -it test-tools -n lab-network-policies -- sh -c \
  'wget -T 3 -qO- http://database:5432 > /dev/null && echo "test → database: PERMITIDO" || echo "test → database: BLOQUEADO (correcto)"'
```

**Salida esperada:**

```
=== Verificando flujo: frontend → backend ===
frontend → backend: OK

=== Verificando flujo: backend → database ===
backend → database: OK

=== Verificando bloqueo: frontend NO puede ir a database ===
frontend → database: BLOQUEADO (correcto)

=== Verificando bloqueo: test-tools no puede ir a ninguno ===
test → frontend: BLOQUEADO (correcto)
test → backend: BLOQUEADO (correcto)
test → database: BLOQUEADO (correcto)
```

Tabla de estado final:

```
+------------------+----------+---------+----------+----------+
| Origen           | frontend | backend | database | DNS :53  |
+------------------+----------+---------+----------+----------+
| test-tools       | BLOCK    | BLOCK   | BLOCK    | ALLOW    |
| frontend         | BLOCK    | ALLOW   | BLOCK    | ALLOW    |
| backend          | BLOCK    | BLOCK   | ALLOW    | ALLOW    |
| database         | BLOCK    | BLOCK   | BLOCK    | ALLOW    |
+------------------+----------+---------+----------+----------+

Flujo permitido: frontend → backend → database
Acceso directo a database: BLOQUEADO para todos excepto backend
```

Resumen de todas las NetworkPolicies activas:

```bash
kubectl get networkpolicies -n lab-network-policies -o wide
```

**Salida esperada:**

```
NAME                         POD-SELECTOR      AGE
allow-backend-to-database    tier=database     15m
allow-dns                    <none>            15m
allow-frontend-to-backend    tier=backend      15m
deny-all                     <none>            15m
```

> **Que aprendimos en el Paso 7:** Las NetworkPolicies implementan el patron de arquitectura "defense in depth" (defensa en profundidad). Incluso si un atacante comprometiera el Pod de frontend, no podria conectarse directamente a la base de datos. Tendria que comprometer tambien el backend para avanzar — y ese segundo salto tambien esta controlado. Este es el valor real de las Network Policies en produccion.

---

## Resumen Visual

```
                    +-------------------------------------------+
                    |        NAMESPACE: lab-network-policies     |
                    |                                           |
  +--------+        |   +---------+  ALLOW   +---------+       |
  |        |        |   |         | -------> |         |       |
  |internet|        |   | frontend|          | backend |       |
  |        |        |   | :80     | <------- | :8080   |       |
  +--------+        |   +---------+  BLOCK   +---------+       |
      |             |        |           ALLOW   |              |
      | BLOCK       |        | BLOCK         +---v------+       |
      v             |        v               | database |       |
  +----------+      |   +---------+          | :5432    |       |
  |test-tools| ---> |   |         |          +----------+       |
  |          |      |   | backend |                             |
  +----------+      |   | :8080   |                             |
  (role: test)      |   +---------+                             |
                    |                                           |
                    |   DNS :53 → PERMITIDO para todos los Pods |
                    +-------------------------------------------+

Policies activas:
  deny-all              → Bloquea todo el trafico (ingress + egress) por defecto
  allow-dns             → Permite puerto 53 UDP/TCP en egress para todos
  allow-frontend-to-backend → Permite ingress al backend solo desde tier=frontend
  allow-backend-to-database → Permite ingress a database solo desde tier=backend
```

---

## Comandos de Diagnostico Esenciales

Estos comandos cubren el 90% de las situaciones de troubleshooting con Network Policies:

```bash
# Ver todas las NetworkPolicies en un namespace
kubectl get networkpolicies -n lab-network-policies

# Ver el detalle de una NetworkPolicy (selectores, puertos, tipos)
kubectl describe networkpolicy allow-frontend-to-backend -n lab-network-policies

# Ver los labels de los Pods (clave para entender que policies aplican)
kubectl get pods -n lab-network-policies --show-labels

# Probar conectividad desde un Pod especifico
kubectl exec -it test-tools -n lab-network-policies -- wget -T 3 -qO- http://backend:8080

# Ver eventos del namespace (para detectar problemas de red)
kubectl get events -n lab-network-policies --sort-by='.lastTimestamp'

# Ver que NetworkPolicies aplican a un Pod especifico
# (busca los labels del Pod y compara con los podSelector de cada policy)
kubectl get pod backend-xxx -n lab-network-policies --show-labels
kubectl get networkpolicies -n lab-network-policies -o yaml | grep -A 5 podSelector
```

---

## Troubleshooting: problemas frecuentes

**"Aplique la policy pero el trafico sigue pasando"**

Causa mas probable: el CNI no soporta NetworkPolicies. Verifica:

```bash
# Ver que CNI esta instalado
kubectl get pods -n kube-system | grep -E "calico|cilium|weave|flannel"
```

Si ves `flannel` o `kindnet`, ese CNI no aplica NetworkPolicies. Necesitas reiniciar Minikube con `--cni=calico`.

Si usas AKS, verifica que la opcion de Network Policy este habilitada en el cluster:

```bash
az aks show --resource-group mi-rg --name mi-cluster --query networkProfile.networkPolicy
```

---

**"La policy bloquea trafico que deberia permitir"**

Verifica que los labels del Pod coincidan exactamente con los selectores de la policy:

```bash
# Labels del Pod de origen
kubectl get pod frontend-xxx -n lab-network-policies --show-labels

# Selector en la policy
kubectl describe networkpolicy allow-frontend-to-backend -n lab-network-policies | grep "From:"
```

Un error comun: el Pod tiene `app: frontend` pero la policy busca `tier: frontend`. Los labels deben coincidir exactamente, incluyendo el nombre de la clave (key) y el valor (value).

---

**"Aplique deny-all y ahora no puedo resolver DNS"**

El deny-all bloquea tambien el trafico de egress al puerto 53. Sin DNS, los Pods no pueden resolver nombres de Services.

Solucion: agrega la policy `allow-dns` antes o al mismo tiempo que la policy `deny-all`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: mi-namespace
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

---

**"La policy solo tiene Ingress pero los Pods tampoco pueden salir"**

Una policy que solo especifica `policyTypes: [Ingress]` no afecta al egress. Pero si ya existe una policy con `policyTypes: [Egress]` sin reglas permitidas (como la deny-all), el egress sigue bloqueado.

Las NetworkPolicies son aditivas: si hay varias policies que aplican al mismo Pod, el trafico se permite si CUALQUIERA de ellas lo autoriza.

Para verificar que policies aplican a un Pod, busca coincidencias entre los labels del Pod y los `podSelector` de cada policy:

```bash
# Ver todos los selectores de todas las policies
kubectl get networkpolicies -n lab-network-policies -o custom-columns=\
  NAME:.metadata.name,SELECTOR:.spec.podSelector.matchLabels

# Ver labels del Pod que te da problemas
kubectl get pod mi-pod -n mi-namespace --show-labels
```

---

**"El wget tarda mucho antes de mostrar 'download timed out'"**

El timeout por defecto de wget sin la opcion `-T` puede ser de 60 segundos o mas. Siempre usa `-T 3` o `-T 5` en el lab para no esperar demasiado:

```bash
# Con timeout de 3 segundos
wget -T 3 -qO- http://backend:8080
```

---

## Limpieza

```bash
chmod +x cleanup.sh
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-network-policies
kubectl config set-context --current --namespace=default
```
