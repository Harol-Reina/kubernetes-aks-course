# Resumen Practico: CI/CD y GitOps

**Duracion:** 60 minutos | **Nivel:** Principiante | **Archivo:** `cicd-lab.yaml`

Un solo YAML despliega dos versiones de una aplicacion (v1 y v2), un canary deployment, un Service para blue-green switching, un ConfigMap con configuracion de pipeline simulada y un ServiceAccount con permisos minimos para CI/CD. Practicas rolling update, blue-green deployment, canary deployment y rollback sin necesidad de ArgoCD ni GitHub Actions.

---

## Conceptos Previos: Antes de Empezar

Si nunca has trabajado con CI/CD o GitOps, lee esta seccion antes de los pasos del lab. Si ya conoces el tema, salta directamente al Paso 0.

### La fabrica automatizada: la analogia del CI/CD

Imagina que tienes una fabrica de automoviles. Hay dos formas de construir cada coche nuevo:

**Sin CI/CD (deploy manual)**: cada vez que quieres entregar un coche, mandas a un mecanico a la fabrica con sus propias herramientas, sus propias instrucciones escritas a mano, y su propio criterio. Cada coche puede quedar ligeramente diferente. Si el mecanico se equivoca, puede danyar la cadena de produccion. No hay registro de que exactamente hizo. Y si el mecanico esta de vacaciones a las 2 AM cuando hay un problema urgente, tienes un problema.

**Con CI/CD (deploy automatizado)**: tienes una linea de produccion robotizada. Cada vez que un ingeniero aprueba un nuevo diseno en el sistema, la linea de produccion: toma el diseno, construye el coche (build), lo inspecciona con sensores automatizados (tests), lo escanea por defectos de seguridad (security scan) y lo entrega al cliente (deploy). Cada coche es identico, reproducible, y hay un registro completo de cada paso. Si algo falla, la linea se detiene y el ingeniero recibe una notificacion inmediata.

**GitOps va un paso mas alla**: el plano del coche (estado deseado del cluster) esta guardado en un repositorio central. Un robot (ArgoCD o Flux) monitorea ese repositorio constantemente. Si alguien cambia un tornillo manualmente en la fabrica sin actualizar el plano, el robot lo detecta y lo corrige. El repositorio Git es la unica fuente de verdad.

---

### CI vs CD vs Continuous Deployment: las tres etapas

Los tres terminos suenan similares pero describen tres responsabilidades distintas dentro del mismo pipeline:

**Continuous Integration (CI) — "construir y validar"**

CI es la practica de integrar cambios de codigo frecuentemente en un repositorio compartido, donde cada integracion se verifica automaticamente. Cada `git push` dispara: construccion de la imagen Docker, tests unitarios, tests de integracion, analisis de codigo estatico y escaneo de vulnerabilidades.

El objetivo es detectar errores lo antes posible, mientras el contexto del cambio todavia esta fresco. Un error detectado 5 minutos despues del commit es 10 veces mas barato de corregir que uno detectado dos semanas despues.

**Continuous Delivery (CD) — "siempre listo para produccion"**

CD extiende CI: el artefacto (imagen Docker) que paso todos los tests se mueve automaticamente a un entorno de staging. El deploy a produccion es manual, pero siempre es posible porque el artefacto ya fue validado.

Continuous Delivery responde a la pregunta: "podemos desplegar ahora mismo si queremos?" La respuesta siempre es si.

**Continuous Deployment — "despliegue automatico a produccion"**

Continuous Deployment (a veces tambien abreviado CD) va un paso mas: cada cambio que pasa todos los tests se despliega automaticamente a produccion sin intervencion humana. Es el nivel mas alto de automatizacion.

La distincion importa en el contexto empresarial: organizaciones en sectores regulados (finanzas, salud, gobierno) generalmente usan Continuous Delivery con aprobacion manual obligatoria para produccion. Empresas de software de alta velocidad como Netflix usan Continuous Deployment.

```
CI/CD Pipeline completo:
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Commit  │──>│  Build   │──>│  Test    │──>│  Scan    │──>│  Deploy  │
│          │   │          │   │          │   │          │   │          │
│ git push │   │ docker   │   │ unit     │   │ trivy    │   │ kubectl  │
│          │   │ build    │   │ integra  │   │ sonarqube│   │ apply    │
│          │   │ push ACR │   │ e2e      │   │          │   │ helm     │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
     |              |               |               |              |
  Developer      Registry       Test Report    Security       K8s Cluster
  hace un        recibe         con pass/      Report con     corre nueva
  cambio         imagen         fail status    CVEs           version
```

---

### GitOps: Git como unica fuente de verdad

GitOps es una filosofia de operaciones donde el estado completo de la infraestructura y las aplicaciones se describe en archivos declarativos (YAML) almacenados en un repositorio Git. Un operador en el cluster (ArgoCD o Flux) monitorea ese repositorio y reconcilia el cluster para que siempre coincida con lo que esta en Git.

La diferencia clave respecto a CI/CD tradicional:

- **CI/CD tradicional (push)**: el pipeline "empuja" cambios al cluster cuando detecta un commit. El cluster es el destino pasivo de los pipelines.

- **GitOps (pull)**: el operador en el cluster "jala" el estado deseado de Git continuamente. Si alguien hace un `kubectl apply` manual en produccion, el operador detecta la desviacion y la revierte automaticamente.

```
GitOps: El bucle de reconciliacion

  Repositorio Git              Operador en Cluster        Cluster Kubernetes
  (fuente de verdad)           (ArgoCD / Flux)            (estado real)

  deployment.yaml     ---->    Compara cada 3min   ---->   Deployments
  service.yaml        ---->    Detecta diferencias  ---->   Services
  configmap.yaml      ---->    Aplica cambios       ---->   ConfigMaps
                               automaticamente

  Si alguien hace kubectl apply manual:
  Estado en Git != Estado en cluster  ---->  Operador REVIERTE el cambio manual
```

---

### Estrategias de despliegue: Rolling, Blue-Green y Canary

Kubernetes ofrece tres estrategias principales para actualizar una aplicacion sin tiempo de inactividad:

**Rolling Update (por defecto)**

Kubernetes reemplaza los Pods de la version antigua por Pods de la version nueva de forma gradual, uno por uno (o en grupos segun maxSurge/maxUnavailable). La aplicacion nunca se detiene completamente: siempre hay Pods corriendo durante la transicion.

```
Rolling Update:
  Antes: [v1][v1][v1]
  t=1:   [v1][v1][v2]   <- un Pod nuevo
  t=2:   [v1][v2][v2]   <- dos Pods nuevos
  t=3:   [v2][v2][v2]   <- migracion completa

  Trafico distribuido entre v1 y v2 durante la transicion.
```

Ventaja: simple, sin recursos adicionales, nativo en Kubernetes. Desventaja: durante la transicion hay dos versiones corriendo simultaneamente (puede causar incompatibilidades).

**Blue-Green Deployment**

Se mantienen dos entornos completos e identicos: "azul" (blue, version actual) y "verde" (green, version nueva). El Service apunta inicialmente al entorno azul. Cuando la version verde esta lista y validada, se cambia el selector del Service de blue a green. El trafico se redirige instantaneamente.

```
Blue-Green:
  Blue (v1): [v1][v1][v1]  <-- Service apunta aqui (activo)
  Green(v2): [v2][v2][v2]  <-- preparado, sin trafico

  Switch: kubectl patch service -p '{"spec":{"selector":{"version":"v2"}}}'

  Blue (v1): [v1][v1][v1]  (standby, listo para rollback)
  Green(v2): [v2][v2][v2]  <-- Service apunta aqui (activo)

  Rollback instantaneo: volver el selector a v1
```

Ventaja: rollback instantaneo, sin periodo de dos versiones simultaneas. Desventaja: requiere el doble de recursos durante la transicion.

**Canary Deployment**

Se despliega la nueva version a un subconjunto pequeno de replicas (1 de 10, por ejemplo) mientras la mayoria sigue en la version estable. Un porcentaje pequeno del trafico real llega al canary. Si hay errores, solo afectan a ese porcentaje. Despues de validar, se incrementa gradualmente el porcentaje hasta llegar al 100%.

```
Canary Deployment:
  v1 (stable): [v1][v1][v1][v1][v1][v1][v1][v1][v1]  <- 9 replicas (90%)
  v2 (canary): [v2]                                   <- 1 replica  (10%)

  Service sin filtro de version:
  Trafico -> 90% a v1, 10% a v2

  Despues de validar metricas:
  v1: [v1][v1][v1][v1][v1][v1]   <- 6 replicas (60%)
  v2: [v2][v2][v2][v2]           <- 4 replicas (40%)

  Si todo va bien: 0 replicas v1, 10 replicas v2
```

Ventaja: bajo impacto si hay errores, permite A/B testing con trafico real. Desventaja: mas complejo de gestionar, las dos versiones corren simultaneamente.

---

### Diagrama ASCII del pipeline CI/CD completo

```
  Desarrollador                 Sistema CI/CD               Kubernetes Cluster
  ┌───────────┐                 ┌─────────────────────┐     ┌──────────────────┐
  │           │  git push       │                     │     │                  │
  │  Escribe  │────────────────>│ 1. TRIGGER           │     │                  │
  │  codigo   │                 │    (webhook)         │     │                  │
  │           │                 │         |            │     │                  │
  └───────────┘                 │         v            │     │                  │
                                │ 2. BUILD             │     │                  │
                                │    docker build      │     │                  │
                                │    docker push ACR   │     │                  │
                                │         |            │     │                  │
                                │         v            │     │                  │
                                │ 3. TEST              │     │                  │
                                │    unit tests        │     │                  │
                                │    integration       │     │                  │
                                │         |            │     │                  │
                                │    FALLO? --> STOP   │     │                  │
                                │         |            │     │                  │
                                │         v            │     │                  │
                                │ 4. SECURITY SCAN     │     │                  │
                                │    trivy image scan  │     │                  │
                                │         |            │     │                  │
                                │         v            │     │                  │
                                │ 5. DEPLOY STAGING    │────>│  staging NS      │
                                │    kubectl apply     │     │  app-v2 (1 rep.) │
                                │         |            │     │                  │
                                │ 6. APPROVAL GATE     │     │                  │
                                │    (manual review)   │     │                  │
                                │         |            │     │                  │
                                │         v            │     │                  │
                                │ 7. DEPLOY PROD       │────>│  production NS   │
                                │    blue-green switch │     │  app-v2 (3 rep.) │
                                │    o rolling update  │     │                  │
                                └─────────────────────┘     └──────────────────┘
```

---

### ArgoCD y Flux: que son y cuando usarlos

Tanto ArgoCD como Flux son operadores de GitOps para Kubernetes. Ambos monitorean un repositorio Git y sincronizan el estado del cluster con lo que esta definido en Git.

**ArgoCD**

ArgoCD proporciona una interfaz web visual que muestra el estado de cada aplicacion: si esta sincronizada con Git, si hay desviaciones, el arbol de recursos desplegados y el historial de sincronizaciones. Es especialmente popular en equipos que prefieren visibilidad visual del estado del cluster.

Concepto central: la `Application` es un recurso de Kubernetes que define que repositorio Git monitorear, que ruta dentro del repositorio contiene los manifiestos, y a que cluster/namespace desplegar.

```yaml
# Ejemplo de Application de ArgoCD (solo referencia, no parte del lab)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webapp
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/empresa/k8s-manifests
    targetRevision: main
    path: apps/webapp/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true      # elimina recursos borrados del repo
      selfHeal: true   # revierte cambios manuales en el cluster
```

**Flux**

Flux es mas orientado a GitOps "puro": opera exclusivamente via CLI y YAML, sin interfaz web por defecto. Sigue mas de cerca la filosofia de "todo en Git". Es muy popular en organizaciones que ya tienen pipelines GitOps maduros y quieren menos dependencias de UI.

**Cuando usar cada uno**

Usa ArgoCD cuando: tu equipo valora la visibilidad visual, estan adoptando GitOps por primera vez, necesitas dashboards de estado para auditorias o para mostrar a stakeholders.

Usa Flux cuando: tienes un equipo maduro de GitOps, prefieres operar todo via CLI y Git, necesitas integracion profunda con Helm y Kustomize sin configuracion adicional.

Para este lab no necesitamos ni ArgoCD ni Flux: practicamos los conceptos fundamentales directamente con `kubectl`. ArgoCD y Flux automatizan lo que haremos a mano.

---

## Conceptos Cubiertos en Este Lab

| Concepto | Que demuestra |
|----------|---------------|
| **Rolling Update** | Actualizacion gradual sin downtime con `kubectl set image` |
| **Blue-Green Deployment** | Dos versiones simultaneas, switch instantaneo via selector del Service |
| **Canary Deployment** | 1 replica de v2 junto a 3 de v1 para validar con trafico real (~25%) |
| **Rollback** | Revertir a version anterior con `kubectl rollout undo` |
| **ServiceAccount** | Permisos minimos para el pipeline (principio de minimo privilegio) |
| **ConfigMap de pipeline** | Configuracion externalizada del pipeline CI/CD |
| **kubectl rollout** | Comandos para gestionar el ciclo de vida de los Deployments |

---

## Diagrama Visual de los Recursos

```
                    +-------------------------------------------------+
                    |           NAMESPACE: lab-cicd                   |
                    |                                                 |
  +-----------------+-------------------------------------------------+
  | ServiceAccount  |                                                 |
  |                 |  cicd-bot (Role: cicd-deployer)                 |
  |                 |  Permisos: Deployments(get/update), Pods(read)  |
  +-----------------+-------------------------------------------------+
  | ConfigMap       |                                                 |
  |                 |  pipeline-config (REGISTRY, STRATEGY, etc.)     |
  +-----------------+-------------------------------------------------+
  | Blue-Green      |                                                 |
  |                 |  app-v1 (3 replicas, nginx:1.24) <-- ACTIVO     |
  |                 |  app-v2 (0 replicas, nginx:1.25)    STANDBY     |
  |                 |  webapp-service -> selector: version: v1        |
  +-----------------+-------------------------------------------------+
  | Canary          |                                                 |
  |                 |  app-canary (1 replica, nginx:1.25, ~25% traf.) |
  +-----------------+-------------------------------------------------+
  | Herramientas    |                                                 |
  |                 |  blue-green-switch-demo (busybox para tests)    |
  +-------------------------------------------------+--------------+
```

---

## Paso 0: Preparar Minikube (2 min)

Minikube crea un cluster de Kubernetes local en tu maquina. Para este lab no necesitas addons especiales, pero es buena practica verificar que el cluster esta sano antes de empezar.

```bash
minikube start

# Verificar estado del cluster
minikube status
kubectl cluster-info
kubectl get nodes
```

**Salida esperada de `kubectl get nodes`:**

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   5m    v1.28.3
```

La columna STATUS debe mostrar `Ready`. Si muestra `NotReady`, espera 30 segundos y vuelve a ejecutar el comando.

---

## Paso 1: Desplegar Todo (2 min)

Este comando aplica el archivo `cicd-lab.yaml` que contiene todos los recursos del lab: el namespace, el ConfigMap, el ServiceAccount con su Role, los dos Deployments (v1 y v2), el Service, el canary deployment y el Pod de herramientas.

```bash
kubectl apply -f cicd-lab.yaml
```

Verificar:

```bash
# Ver namespace creado
kubectl get ns lab-cicd --show-labels

# Ver todos los recursos
kubectl get all -n lab-cicd
```

**Salida esperada de `kubectl get all -n lab-cicd`:**

```
NAME                              READY   STATUS    RESTARTS   AGE
pod/blue-green-switch-demo        1/1     Running   0          30s
pod/app-v1-abc123-xxx             1/1     Running   0          30s
pod/app-v1-abc123-yyy             1/1     Running   0          30s
pod/app-v1-abc123-zzz             1/1     Running   0          30s
pod/app-canary-def456-aaa         1/1     Running   0          30s

NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/webapp-service   ClusterIP   10.96.10.100   <none>        80/TCP    30s

NAME                        READY   UP-TO-DATE   AVAILABLE   REPLICAS   AGE
deployment.apps/app-v1      3/3     3            3           3          30s
deployment.apps/app-v2      0/0     0            0           0          30s
deployment.apps/app-canary  1/1     1            1           1          30s
```

Observa que `app-v2` muestra `0/0` en la columna READY: tiene 0 replicas porque aun no hemos iniciado el despliegue de la nueva version. Ese es el punto de partida del blue-green deployment.

**Verificar el ConfigMap y ServiceAccount:**

```bash
kubectl get configmap pipeline-config -n lab-cicd -o yaml
kubectl get serviceaccount cicd-bot -n lab-cicd
kubectl get role cicd-deployer -n lab-cicd -o yaml
```

**Que acabamos de aprender**: Un solo archivo YAML puede contener multiples recursos de diferentes tipos separados por `---`. Kubernetes los crea todos en el orden en que aparecen. El namespace se crea primero porque los demas recursos lo referencian.

---

## Paso 2: Practicar Rolling Update (10 min)

El rolling update es la estrategia por defecto de Kubernetes. Antes de pasar a estrategias mas avanzadas, vamos a entender como funciona actualizando el Deployment `app-v1` de nginx:1.24 a nginx:1.25.

**Estado inicial:**

```bash
# Ver la imagen actual de app-v1
kubectl get deployment app-v1 -n lab-cicd -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Salida esperada:**

```
nginx:1.24
```

**Ejecutar el rolling update:**

```bash
# Actualizar la imagen (como lo haria el pipeline de CI/CD)
kubectl set image deployment/app-v1 webapp=nginx:1.25 -n lab-cicd

# Observar el rollout en tiempo real (Ctrl+C para salir)
kubectl rollout status deployment/app-v1 -n lab-cicd -w
```

**Salida esperada durante el rollout:**

```
Waiting for deployment "app-v1" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "app-v1" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "app-v1" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "app-v1" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "app-v1" rollout to finish: 1 old replicas are pending termination...
deployment "app-v1" successfully rolled out
```

**Ver el historial de rollouts:**

```bash
kubectl rollout history deployment/app-v1 -n lab-cicd
```

**Salida esperada:**

```
deployment.apps/app-v1
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

Las dos revisiones corresponden a: revision 1 (nginx:1.24, el despliegue inicial) y revision 2 (nginx:1.25, el rolling update que acabamos de hacer). La columna CHANGE-CAUSE muestra `<none>` porque no usamos `--record` (ese flag esta deprecado; en produccion se usa la anotacion `kubernetes.io/change-cause`).

**Verificar la nueva imagen:**

```bash
kubectl get deployment app-v1 -n lab-cicd -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Salida esperada:**

```
nginx:1.25
```

**Como leer lo que paso**: Kubernetes creo nuevos Pods con nginx:1.25 uno a uno, esperando que cada uno estuviera Ready antes de eliminar uno de los Pods antiguos con nginx:1.24. En ningun momento se apago el servicio completamente. Esta es la garantia del rolling update: siempre hay al menos `replicas - maxUnavailable` Pods disponibles para atender trafico.

**Que acabamos de aprender**: `kubectl set image` actua como el comando que ejecutaria un pipeline de CI/CD despues de construir y publicar la nueva imagen. El Deployment gestiona el rolling update automaticamente respetando los limites de disponibilidad configurados.

---

## Paso 3: Practicar Rollback (8 min)

Un pipeline de CI/CD maduro debe poder hacer rollback rapidamente cuando algo falla en produccion. Kubernetes mantiene el historial de revisiones del Deployment, lo que permite revertir a una version anterior con un solo comando.

**Situacion**: imagina que el equipo de QA detecto un bug critico en nginx:1.25 despues del deploy del Paso 2. Necesitamos revertir a nginx:1.24 inmediatamente.

**Hacer rollback a la revision anterior:**

```bash
kubectl rollout undo deployment/app-v1 -n lab-cicd
```

**Salida esperada:**

```
deployment.apps/app-v1 rolled back
```

**Verificar que el rollback funciono:**

```bash
# Ver la imagen actual (debe ser nginx:1.24 de nuevo)
kubectl get deployment app-v1 -n lab-cicd -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Salida esperada:**

```
nginx:1.24
```

**Ver el historial actualizado:**

```bash
kubectl rollout history deployment/app-v1 -n lab-cicd
```

**Salida esperada:**

```
deployment.apps/app-v1
REVISION  CHANGE-CAUSE
2         <none>
3         <none>
```

Observa que la revision 1 desaparecio y hay una nueva revision 3. Esto es porque el rollback no es un "retroceder en el tiempo": es un nuevo cambio hacia adelante que aplica la configuracion de una revision anterior. La revision 3 tiene la misma imagen que la revision 1 (nginx:1.24).

**Rollback a una revision especifica:**

```bash
# Ver los detalles de una revision especifica
kubectl rollout history deployment/app-v1 -n lab-cicd --revision=2

# Rollback a una revision especifica (si quisieras volver a nginx:1.25)
# kubectl rollout undo deployment/app-v1 -n lab-cicd --to-revision=2
```

**Que acabamos de aprender**: `kubectl rollout undo` es el comando de "panico" cuando un deploy falla en produccion. En un entorno de GitOps real, el rollback seria un `git revert` que vuelve a sincronizar el cluster al commit anterior. Ambos mecanismos logran el mismo resultado, pero el `git revert` tiene la ventaja de que queda registrado en el historial de Git.

---

## Paso 4: Blue-Green Deployment (12 min)

El blue-green deployment nos permite tener dos versiones completas corriendo simultaneamente y hacer el switch de trafico de forma instantanea. En el YAML del lab, `app-v1` es el slot "azul" (activo) y `app-v2` es el slot "verde" (listo para activarse).

**Estado actual del Service:**

```bash
# Ver a que version apunta el Service
kubectl get service webapp-service -n lab-cicd -o jsonpath='{.spec.selector}'
```

**Salida esperada:**

```
{"app":"webapp","version":"v1"}
```

El Service enruta el trafico solo a Pods con las etiquetas `app: webapp` y `version: v1`. Los Pods de `app-v2` no reciben trafico aunque esten corriendo.

**Paso 4.1: Escalar app-v2 al mismo nivel que app-v1**

En un blue-green deployment real, primero desplegamos la nueva version completa (mismo numero de replicas que la version activa) y la validamos antes de hacer el switch:

```bash
# Escalar app-v2 a 3 replicas (mismo que app-v1)
kubectl scale deployment app-v2 -n lab-cicd --replicas=3

# Esperar que app-v2 este completamente disponible
kubectl rollout status deployment/app-v2 -n lab-cicd
```

**Salida esperada:**

```
deployment "app-v2" successfully rolled out
```

**Verificar que ambas versiones estan corriendo:**

```bash
kubectl get pods -n lab-cicd -l app=webapp --show-labels
```

**Salida esperada:**

```
NAME                        READY   STATUS    RESTARTS   AGE   LABELS
app-v1-abc123-xxx           1/1     Running   0          15m   app=webapp,version=v1,slot=blue
app-v1-abc123-yyy           1/1     Running   0          15m   app=webapp,version=v1,slot=blue
app-v1-abc123-zzz           1/1     Running   0          15m   app=webapp,version=v1,slot=blue
app-v2-def456-aaa           1/1     Running   0          30s   app=webapp,version=v2,slot=green
app-v2-def456-bbb           1/1     Running   0          30s   app=webapp,version=v2,slot=green
app-v2-def456-ccc           1/1     Running   0          30s   app=webapp,version=v2,slot=green
```

Las 6 replicas estan corriendo: 3 de v1 recibiendo trafico, 3 de v2 listas pero sin trafico todavia.

**Paso 4.2: Validar app-v2 antes del switch**

Antes de redirigir el trafico de produccion, validamos que app-v2 funciona correctamente:

```bash
# Hacer una peticion directa a un Pod de app-v2 (sin pasar por el Service)
kubectl exec -n lab-cicd blue-green-switch-demo -- \
  wget -qO- http://$(kubectl get pod -n lab-cicd -l version=v2 -o jsonpath='{.items[0].status.podIP}')

# Verificar que la version correcta esta respondiendo
kubectl exec -n lab-cicd blue-green-switch-demo -- \
  wget -qO- http://$(kubectl get pod -n lab-cicd -l version=v2 -o jsonpath='{.items[0].status.podIP}') | head -5
```

**Salida esperada (pagina de bienvenida de nginx):**

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

**Paso 4.3: Ejecutar el blue-green switch**

Con app-v2 validada, redirigimos todo el trafico cambiando el selector del Service:

```bash
# BLUE-GREEN SWITCH: redirigir trafico de v1 a v2
kubectl patch service webapp-service -n lab-cicd \
  -p '{"spec":{"selector":{"app":"webapp","version":"v2"}}}'
```

**Salida esperada:**

```
service/webapp-service patched
```

**Verificar que el switch funciono:**

```bash
# Confirmar que el selector ahora apunta a v2
kubectl get service webapp-service -n lab-cicd -o jsonpath='{.spec.selector}'
```

**Salida esperada:**

```
{"app":"webapp","version":"v2"}
```

**Probar que el trafico llega a v2:**

```bash
# El Service ahora enruta a v2
kubectl exec -n lab-cicd blue-green-switch-demo -- \
  wget -qO- http://webapp-service | head -3
```

**Paso 4.4: Rollback instantaneo si algo falla**

La ventaja clave del blue-green es que app-v1 sigue corriendo con 3 replicas listas. Si detectamos un problema con v2 despues del switch, el rollback es instantaneo:

```bash
# Rollback instantaneo: volver a apuntar al slot azul (v1)
kubectl patch service webapp-service -n lab-cicd \
  -p '{"spec":{"selector":{"app":"webapp","version":"v1"}}}'

# El trafico vuelve a v1 inmediatamente (no hay rolling, es instantaneo)
kubectl get service webapp-service -n lab-cicd -o jsonpath='{.spec.selector}'
```

**Salida esperada:**

```
{"app":"webapp","version":"v1"}
```

**Que acabamos de aprender**: El blue-green deployment es una estrategia de intercambio de trafico, no de reemplazo gradual. La clave es el selector del Service: al cambiarlo, todo el trafico se redirige instantaneamente. El costo es tener el doble de recursos durante la transicion (los dos slots corriendo al mismo tiempo).

---

## Paso 5: Canary Deployment (10 min)

El canary deployment nos permite enviar un porcentaje pequeno del trafico real a la nueva version, monitorizando metricas antes de hacer el rollout completo. En nuestro lab, `app-canary` tiene 1 replica de nginx:1.25 y `app-v1` tiene 3 replicas de nginx:1.24 (o nginx:1.25 si no revertiste despues del Paso 3).

**Entender la distribucion de trafico actual:**

```bash
# Contar replicas por version
kubectl get deployment -n lab-cicd

# Ver los Pods con sus versiones
kubectl get pods -n lab-cicd -l app=webapp -o custom-columns=\
"NAME:.metadata.name,VERSION:.metadata.labels.version,STATUS:.status.phase"
```

**Salida esperada:**

```
NAME                        VERSION   STATUS
app-v1-abc123-xxx           v1        Running
app-v1-abc123-yyy           v1        Running
app-v1-abc123-zzz           v1        Running
app-canary-def456-aaa       canary    Running
```

Con un Service que selecciona `app: webapp` (sin filtrar por version), el trafico se distribuye entre los 4 Pods que coinciden: 3 de v1 (75%) y 1 canary (25%). Esto es el canary deployment a nivel de Kubernetes nativo.

**Verificar que el Service canary (sin filtro de version) existe:**

El Service `webapp-service` actualmente apunta a `version: v1`, no al canary. Para que el canary reciba trafico hay que crear un Service sin el filtro de version, o modificar el existente. Vamos a crear un Service canary temporal:

```bash
kubectl expose deployment app-canary -n lab-cicd \
  --name=webapp-canary-service \
  --port=80 \
  --target-port=http
```

**Salida esperada:**

```
service/webapp-canary-service exposed
```

**Simular trafico al canary:**

```bash
# 10 peticiones al canary (deberian responder todas con nginx)
for i in $(seq 1 5); do
  kubectl exec -n lab-cicd blue-green-switch-demo -- \
    wget -qO- http://webapp-canary-service 2>/dev/null | grep -o "nginx" | head -1
  echo "Peticion $i: respondio"
done
```

**Salida esperada:**

```
nginx
Peticion 1: respondio
nginx
Peticion 2: respondio
nginx
Peticion 3: respondio
nginx
Peticion 4: respondio
nginx
Peticion 5: respondio
```

**Incrementar el canary gradualmente:**

Si las metricas del canary son buenas (sin errores, latencia normal), el siguiente paso es incrementar las replicas del canary y reducir las de v1:

```bash
# Incrementar canary a 2 replicas (33% del trafico si v1 tiene 4 replicas)
kubectl scale deployment app-canary -n lab-cicd --replicas=2

# Ver la nueva distribucion
kubectl get pods -n lab-cicd -l app=webapp --no-headers | \
  awk '{print $1}' | \
  xargs -I {} kubectl get pod {} -n lab-cicd -o jsonpath='{.metadata.labels.version}{"\n"}' | \
  sort | uniq -c
```

**En un entorno de produccion real**, los incrementos del canary se automatizan con herramientas como Flagger (que monitorea metricas de Prometheus y ajusta las replicas automaticamente) o Argo Rollouts (con soporte nativo para canary y blue-green con analisis automatico).

**Que acabamos de aprender**: El canary deployment en Kubernetes nativo se implementa controlando el numero de replicas de dos Deployments que comparten las mismas etiquetas de selector en el Service. La distribucion de trafico es proporcional al numero de Pods, no un porcentaje configurado explicitamente. Para control exacto del porcentaje de trafico necesitas un Service Mesh (Istio, Linkerd) o un Ingress Controller con soporte de weight-based routing.

---

## Paso 6: Explorar el ServiceAccount del Pipeline (8 min)

En CI/CD real, el pipeline nunca debe usar credenciales de administrador del cluster. El principio de minimo privilegio exige que el Service Principal o ServiceAccount del pipeline solo tenga los permisos estrictamente necesarios para desplegar aplicaciones.

**Ver los permisos del ServiceAccount cicd-bot:**

```bash
# Ver el Role asignado a cicd-bot
kubectl get role cicd-deployer -n lab-cicd -o yaml
```

**Salida esperada (fragmento clave):**

```yaml
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch", "update", "patch"]
```

**Verificar que los permisos esten correctamente asignados:**

```bash
# kubectl auth can-i verifica si un ServiceAccount tiene permiso para una accion
# Sintaxis: kubectl auth can-i VERBO RECURSO --as=system:serviceaccount:NAMESPACE:NOMBRE

# El pipeline PUEDE actualizar Deployments (necesario para kubectl set image)
kubectl auth can-i update deployments -n lab-cicd \
  --as=system:serviceaccount:lab-cicd:cicd-bot
```

**Salida esperada:**

```
yes
```

```bash
# El pipeline NO PUEDE borrar Deployments (proteccion contra accidentes)
kubectl auth can-i delete deployments -n lab-cicd \
  --as=system:serviceaccount:lab-cicd:cicd-bot
```

**Salida esperada:**

```
no
```

```bash
# El pipeline NO PUEDE crear namespaces (aislamiento de permisos)
kubectl auth can-i create namespaces \
  --as=system:serviceaccount:lab-cicd:cicd-bot
```

**Salida esperada:**

```
no
```

**Ver la configuracion del pipeline desde el ConfigMap:**

```bash
kubectl get configmap pipeline-config -n lab-cicd -o jsonpath='{.data}' | \
  python3 -c "import sys,json; data=json.load(sys.stdin); [print(f'{k}: {v}') for k,v in data.items()]"
```

**Salida esperada:**

```
REGISTRY: myregistry.azurecr.io
APP_NAME: webapp
ENVIRONMENT: staging
ROLLOUT_STRATEGY: blue-green
CANARY_WEIGHT: 20
ROLLBACK_ENABLED: true
MAX_SURGE: 1
MAX_UNAVAILABLE: 0
GIT_REPO: https://github.com/empresa/k8s-manifests
GIT_BRANCH: main
SYNC_POLICY: automated
```

**Que acabamos de aprender**: `kubectl auth can-i` es una herramienta de auditoria esencial para verificar que un ServiceAccount tiene exactamente los permisos que necesita, ni mas ni menos. El principio de minimo privilegio es critico en pipelines de CI/CD porque el pipeline tiene acceso automatizado al cluster y un permiso excesivo podria ser explotado si el pipeline es comprometido.

---

## Paso 7: Simular GitOps: Detectar Deriva del Estado (8 min)

GitOps parte del principio de que el estado del cluster debe coincidir siempre con el estado declarado en Git. En este paso vamos a simular una "deriva" (un cambio manual que no esta en Git) y ver como un operador de GitOps lo detectaria.

**Situacion**: alguien hizo un cambio urgente directamente en el cluster sin crear un PR en Git. Vamos a simular eso:

```bash
# Cambio manual: agregar una etiqueta al Deployment (simula kubectl edit en produccion)
kubectl label deployment app-v1 -n lab-cicd hotfix=true emergency=yes

# Ver el cambio
kubectl get deployment app-v1 -n lab-cicd --show-labels
```

**Salida esperada:**

```
NAME     READY   UP-TO-DATE   AVAILABLE   AGE   LABELS
app-v1   3/3     3            3           20m   app=webapp,...,emergency=yes,hotfix=true,...
```

**Simular lo que ArgoCD o Flux detectarian:**

```bash
# ArgoCD compara el estado en Git con el estado en el cluster.
# Como no tenemos ArgoCD instalado, simulamos la comparacion manualmente.

# Estado "en Git" (lo que deberia existir segun cicd-lab.yaml):
echo "Etiquetas declaradas en cicd-lab.yaml:"
echo "  app: webapp"
echo "  version: v1"
echo "  slot: blue"

echo ""

# Estado real en el cluster:
echo "Etiquetas reales en el cluster:"
kubectl get deployment app-v1 -n lab-cicd -o jsonpath='{.metadata.labels}' | \
  python3 -c "import sys,json; data=json.load(sys.stdin); [print(f'  {k}: {v}') for k,v in sorted(data.items())]"

echo ""
echo "DERIVA DETECTADA: las etiquetas 'hotfix' y 'emergency' no estan en Git."
echo "Un operador GitOps (ArgoCD selfHeal: true) las eliminaria automaticamente."
```

**Salida esperada:**

```
Etiquetas declaradas en cicd-lab.yaml:
  app: webapp
  version: v1
  slot: blue

Etiquetas reales en el cluster:
  app: webapp
  emergency: yes
  hotfix: true
  slot: blue
  version: v1

DERIVA DETECTADA: las etiquetas 'hotfix' y 'emergency' no estan en Git.
Un operador GitOps (ArgoCD selfHeal: true) las eliminaria automaticamente.
```

**Como ArgoCD revertir la deriva:**

```bash
# En GitOps con selfHeal activado, ArgoCD volveria a aplicar el manifiesto de Git.
# Simulamos eso con kubectl apply:
kubectl apply -f cicd-lab.yaml 2>&1 | grep -E "configured|unchanged|created"
```

**Salida esperada:**

```
namespace/lab-cicd unchanged
configmap/pipeline-config unchanged
serviceaccount/cicd-bot unchanged
...
deployment.apps/app-v1 configured   <- las etiquetas extra se eliminaron
...
```

```bash
# Verificar que la deriva fue corregida
kubectl get deployment app-v1 -n lab-cicd --show-labels
```

**Salida esperada:**

```
NAME     READY   UP-TO-DATE   AVAILABLE   AGE   LABELS
app-v1   3/3     3            3           25m   app=webapp,pod-template-hash=abc123,slot=blue,version=v1
```

Las etiquetas `hotfix` y `emergency` ya no estan. `kubectl apply` con el manifiesto original "reconcilio" el estado, que es exactamente lo que hace un operador de GitOps automaticamente.

**Que acabamos de aprender**: GitOps no es solo un pipeline que aplica cambios: es un bucle de reconciliacion continuo. `kubectl apply` es idempotente: si el estado ya coincide con el manifiesto, no hace nada. Si hay una diferencia, la corrige. ArgoCD y Flux automatizan ese `kubectl apply` continuo, comparando el estado del cluster con los manifiestos en Git cada pocos minutos.

---

## Paso 8: Limpiar (2 min)

El script de limpieza elimina el namespace `lab-cicd` y todos los recursos dentro de el (Deployments, Services, ConfigMap, ServiceAccount, Role, etc.) y restaura el contexto de kubectl al namespace `default`.

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-cicd
kubectl config set-context --current --namespace=default
```

**Verificar que la limpieza fue exitosa:**

```bash
kubectl get ns lab-cicd
# Debe mostrar: Error from server (NotFound): namespaces "lab-cicd" not found
```

---

## Resumen Visual

```
+--------------------------------------------------+
|  ROLLING UPDATE (estrategia por defecto)          |
|  - Reemplazo gradual Pod a Pod                    |
|  - kubectl set image -> rollout automatico        |
|  - rollout undo para rollback                     |
+------------------------+-------------------------+
                         |
                         v
+--------------------------------------------------+
|  BLUE-GREEN (dos slots completos)                 |
|  - Slot Blue (v1, activo) + Slot Green (v2, listo)|
|  - Switch: patch al selector del Service          |
|  - Rollback instantaneo (cambiar selector de vuelta)|
+------------------------+-------------------------+
                         |
                         v
+--------------------------------------------------+
|  CANARY (porcentaje de trafico)                   |
|  - 1 replica canary + N replicas estables         |
|  - Trafico proporcional a replicas                |
|  - Incrementar gradualmente si metricas son buenas|
+--------------------------------------------------+
```

## Lo Que Aprendiste en Este Lab

Al completar este lab has practicado los siguientes conceptos:

- **Rolling Update**: como Kubernetes reemplaza Pods gradualmente con `kubectl set image` y como monitorear el progreso con `kubectl rollout status`
- **Rollback**: como revertir a una version anterior con `kubectl rollout undo` y la diferencia con el rollback de GitOps via `git revert`
- **Blue-Green Deployment**: como mantener dos versiones simultaneas y hacer el switch de trafico instantaneo cambiando el selector del Service
- **Canary Deployment**: como controlar el porcentaje de trafico enviando a la nueva version usando el numero de replicas como mecanismo de distribucion
- **ServiceAccount con minimo privilegio**: como restringir los permisos del pipeline de CI/CD usando Role y RoleBinding
- **Deteccion de deriva de estado**: como `kubectl apply` reconcilia el estado del cluster con los manifiestos declarativos, que es el principio central de GitOps
- **ConfigMap como fuente de configuracion del pipeline**: como externalizar la configuracion del pipeline en Kubernetes
