# Resumen Practico: RBAC y Control de Acceso

**Duracion:** 60 minutos | **Nivel:** Principiante a Intermedio | **Archivo:** `rbac-lab.yaml`

Un solo YAML despliega un entorno completo de RBAC con 3 ServiceAccounts (desarrollador, deployer, auditor), Roles y ClusterRoles con diferentes niveles de permisos, RoleBindings, una aplicación de prueba y un Secret para verificar restricciones de acceso.

---

## Conceptos Previos: Antes de Empezar

Si nunca has trabajado con RBAC en Kubernetes, lee esta sección completa. Si ya conoces el tema, salta al Paso 0.

### ¿Qué es RBAC?

**RBAC** significa **Role-Based Access Control** (Control de Acceso Basado en Roles). Es un sistema que controla **quién** puede hacer **qué** en tu cluster de Kubernetes.

Imagina que tu cluster de Kubernetes es un edificio de oficinas. Sin RBAC, todos los que entran al edificio tienen las llaves de todas las puertas: pueden entrar a cualquier oficina, abrir cualquier cajón, borrar cualquier documento. Con RBAC, cada persona recibe un juego de llaves específico que solo abre las puertas que necesita.

```
SIN RBAC (todos son admin):          CON RBAC (cada uno lo suyo):
┌──────────────────────────┐         ┌──────────────────────────┐
│  Todos pueden:            │         │  Desarrollador:          │
│  ✗ Borrar producción     │         │  ✓ Ver Pods de su NS     │
│  ✗ Leer todos los Secrets│         │  ✗ No borra nada         │
│  ✗ Crear cluster-admin   │         │  ✗ No ve Secrets         │
│  ✗ Eliminar namespaces   │         ├──────────────────────────┤
│                           │         │  Deployer (CI/CD):       │
│  = DESASTRE esperando     │         │  ✓ Crear Deployments     │
│    a ocurrir              │         │  ✓ Crear Services        │
│                           │         │  ✗ No elimina nada       │
│                           │         ├──────────────────────────┤
│                           │         │  Auditor:                │
│                           │         │  ✓ Ver TODO (lectura)    │
│                           │         │  ✗ No modifica nada      │
└──────────────────────────┘         └──────────────────────────┘
```

### Las 4 Piezas de RBAC

RBAC en Kubernetes tiene exactamente 4 componentes. Cada uno tiene un propósito claro:

```
┌─────────────────────────────────────────────────────────────┐
│                     RBAC en Kubernetes                       │
│                                                              │
│  ¿QUIÉN?              ¿QUÉ PERMISOS?        ¿DÓNDE?       │
│  ┌──────────────┐     ┌──────────────┐      ┌───────────┐  │
│  │ ServiceAccount│     │ Role         │      │ Namespace  │  │
│  │ (o User/Group)│◄───►│ (permisos)   │      │ (ámbito)   │  │
│  └──────────────┘     └──────────────┘      └───────────┘  │
│         │                    │                              │
│         │    ┌───────────────┘                              │
│         │    │                                               │
│         ▼    ▼                                               │
│  ┌──────────────────┐                                       │
│  │ RoleBinding       │                                       │
│  │ (une quién+qué)   │                                       │
│  └──────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
```

1. **ServiceAccount** = La identidad (quién eres). Como tu documento de identidad.
2. **Role** = Los permisos (qué puedes hacer). Como una lista de permisos escritos en papel.
3. **RoleBinding** = La conexión (quién tiene qué permisos). Como darle la lista de permisos a una persona específica.
4. **Namespace** = El alcance (dónde aplican los permisos). Como el departamento de una empresa.

### Role vs ClusterRole

| Tipo | Alcance | Analogía |
|------|---------|----------|
| **Role** | Solo UN namespace | Llave que abre puertas de UN piso del edificio |
| **ClusterRole** | TODO el cluster | Llave maestra que abre puertas de TODOS los pisos |
| **RoleBinding** | Asigna Role en UN namespace | Dar la llave del piso al empleado |
| **ClusterRoleBinding** | Asigna ClusterRole globalmente | Dar la llave maestra al guardia de seguridad |

### Los Verbos de RBAC

Los **verbos** definen qué acciones se permiten sobre los recursos:

| Verbo | Qué permite | Equivalente HTTP | Ejemplo kubectl |
|-------|------------|-------------------|-----------------|
| `get` | Ver UN recurso | GET /pods/nombre | `kubectl get pod mi-pod` |
| `list` | Listar TODOS | GET /pods | `kubectl get pods` |
| `watch` | Observar cambios | GET /pods?watch=true | `kubectl get pods -w` |
| `create` | Crear nuevo | POST /pods | `kubectl create deployment...` |
| `update` | Reemplazar | PUT /pods/nombre | `kubectl replace -f...` |
| `patch` | Modificar parcial | PATCH /pods/nombre | `kubectl patch pod...` |
| `delete` | Eliminar | DELETE /pods/nombre | `kubectl delete pod...` |

**Solo lectura** = get + list + watch
**Despliegue** = get + list + watch + create + update + patch
**Admin completo** = todos los verbos incluyendo delete

### ¿Qué es un ServiceAccount?

Un **ServiceAccount** es una identidad para procesos que corren dentro del cluster (como Pods o pipelines CI/CD). Es diferente de una cuenta de usuario humano:

- **User**: Humano que usa kubectl desde su computadora.
- **ServiceAccount**: Proceso automático dentro del cluster (ej: pipeline, controlador, agente de monitoreo).

Cada Pod tiene un ServiceAccount asociado. Si no especificas uno, usa el ServiceAccount `default` del namespace (que normalmente tiene permisos muy limitados).

---

## Conceptos Cubiertos en Este Lab

| Concepto | Qué demuestra | Relevancia Certificación |
|----------|---------------|--------------------------|
| ServiceAccount | Identidad para Pods y procesos | CKA, CKAD |
| Role | Permisos dentro de un namespace | CKA, CKAD |
| ClusterRole | Permisos en todo el cluster | CKA |
| RoleBinding | Asignar permisos a identidades | CKA, CKAD |
| ClusterRoleBinding | Asignar permisos globales | CKA |
| Principio Mínimo Privilegio | Diseño de permisos seguros | CKA, AKS |
| Verificación con `auth can-i` | Auditar permisos | CKA, CKAD |

---

## Diagrama Visual del Lab

```
┌─────────────────────────────────────────────────────────────┐
│  NAMESPACE: lab-rbac                                        │
│                                                             │
│  ServiceAccounts:                                           │
│  ┌─────────────┐  ┌──────────┐  ┌──────────┐              │
│  │ desarrollador│  │ deployer │  │ auditor  │              │
│  │ (lectura)    │  │ (deploy) │  │ (global) │              │
│  └──────┬──────┘  └────┬─────┘  └────┬─────┘              │
│         │              │              │                     │
│         ▼              ▼              ▼                     │
│  ┌─────────────┐  ┌──────────┐  ┌──────────────┐          │
│  │ Role:       │  │ Role:    │  │ ClusterRole: │          │
│  │ solo-lectura│  │ deployer │  │ auditor-     │          │
│  │             │  │ -role    │  │ global       │          │
│  │ get,list    │  │ get,list │  │ get,list     │          │
│  │ watch pods  │  │ create   │  │ watch ALL    │          │
│  │ deployments │  │ update   │  │ namespaces   │          │
│  │ configmaps  │  │ patch    │  │              │          │
│  └─────────────┘  └──────────┘  └──────────────┘          │
│                                                             │
│  Recursos de prueba:                                        │
│  ┌──────────────────┐  ┌─────────────┐  ┌──────────────┐  │
│  │ Deployment:      │  │ Service:    │  │ Secret:      │  │
│  │ webapp-rbac (x2) │  │ webapp-rbac │  │ db-creds     │  │
│  └──────────────────┘  └─────────────┘  │ (RESTRINGIDO)│  │
│                                          └──────────────┘  │
│  [test-rbac pod con SA: desarrollador]                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Paso 0: Preparar Minikube (3 min)

```bash
# Iniciar Minikube (si no está corriendo)
minikube start --cpus 2 --memory 4096

# Verificar el cluster
kubectl cluster-info
kubectl get nodes
```

**Salida esperada:**

```
Kubernetes control plane is running at https://192.168.49.2:8443
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.28.3
```

---

## Paso 1: Desplegar Todo (2 min)

```bash
kubectl apply -f rbac-lab.yaml
```

**Salida esperada:**

```
namespace/lab-rbac created
serviceaccount/desarrollador created
serviceaccount/deployer created
serviceaccount/auditor created
role.rbac.authorization.k8s.io/solo-lectura created
role.rbac.authorization.k8s.io/deployer-role created
clusterrole.rbac.authorization.k8s.io/auditor-global created
rolebinding.rbac.authorization.k8s.io/desarrollador-lectura created
rolebinding.rbac.authorization.k8s.io/deployer-acceso created
clusterrolebinding.rbac.authorization.k8s.io/auditor-acceso-global created
deployment.apps/webapp-rbac created
service/webapp-rbac created
secret/db-credentials created
pod/test-rbac created
```

### Verificar los recursos

```bash
kubectl get all,sa,roles,rolebindings -n lab-rbac
```

**Salida esperada:**

```
NAME                              READY   STATUS    RESTARTS   AGE
pod/test-rbac                     1/1     Running   0          30s
pod/webapp-rbac-xxxxx-yyyyy       1/1     Running   0          30s
pod/webapp-rbac-xxxxx-zzzzz       1/1     Running   0          30s

NAME                  TYPE        CLUSTER-IP     PORT(S)   AGE
service/webapp-rbac   ClusterIP   10.96.x.x      80/TCP    30s

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/webapp-rbac   2/2     2            2           30s

NAME                       SECRETS   AGE
serviceaccount/default       0       30s
serviceaccount/auditor       0       30s
serviceaccount/deployer      0       30s
serviceaccount/desarrollador 0       30s
```

---

## Paso 2: Explorar los Roles y Permisos (10 min)

### Ver el Role de solo lectura

```bash
kubectl describe role solo-lectura -n lab-rbac
```

**Salida esperada:**

```
Name:         solo-lectura
Namespace:    lab-rbac
Labels:       lab=rbac-resumen
PolicyRule:
  Resources              Verbs
  ---------              -----
  configmaps             [get list]
  endpoints              [get list watch]
  pods                   [get list watch]
  pods/log               [get list watch]
  services               [get list watch]
  deployments.apps       [get list watch]
  replicasets.apps       [get list watch]
```

**¿Cómo leer esta tabla?**
- **Resources**: Los tipos de objetos que este Role permite acceder.
- **Verbs**: Las acciones permitidas. Solo `get`, `list` y `watch` = solo lectura.
- **No aparecen**: `create`, `update`, `patch`, `delete` = no puede modificar nada.

### Ver el Role de deployer

```bash
kubectl describe role deployer-role -n lab-rbac
```

**Nota la diferencia**: El deployer-role incluye `create`, `update` y `patch` en Deployments y Services. Puede crear y modificar, pero no eliminar.

### Ver el ClusterRole del auditor

```bash
kubectl describe clusterrole auditor-global
```

**Nota**: Este ClusterRole tiene acceso a recursos de RBAC (roles, rolebindings) porque el auditor necesita poder revisar qué permisos tienen los demás.

---

## Paso 3: Verificar Permisos con "auth can-i" (10 min)

El comando `kubectl auth can-i` es la herramienta principal para verificar si un usuario o ServiceAccount tiene permiso para realizar una acción.

### Probar permisos del desarrollador

```bash
# ¿Puede el desarrollador listar Pods en lab-rbac?
kubectl auth can-i list pods \
  --as=system:serviceaccount:lab-rbac:desarrollador \
  -n lab-rbac
```

**Salida esperada:** `yes`

```bash
# ¿Puede el desarrollador CREAR Pods en lab-rbac?
kubectl auth can-i create pods \
  --as=system:serviceaccount:lab-rbac:desarrollador \
  -n lab-rbac
```

**Salida esperada:** `no`

```bash
# ¿Puede el desarrollador leer Secrets?
kubectl auth can-i get secrets \
  --as=system:serviceaccount:lab-rbac:desarrollador \
  -n lab-rbac
```

**Salida esperada:** `no`

**El desarrollador solo puede VER recursos, nunca crear, modificar ni ver Secrets.**

### Probar permisos del deployer

```bash
# ¿Puede el deployer crear Deployments?
kubectl auth can-i create deployments \
  --as=system:serviceaccount:lab-rbac:deployer \
  -n lab-rbac
```

**Salida esperada:** `yes`

```bash
# ¿Puede el deployer ELIMINAR Deployments?
kubectl auth can-i delete deployments \
  --as=system:serviceaccount:lab-rbac:deployer \
  -n lab-rbac
```

**Salida esperada:** `no`

```bash
# ¿Puede el deployer leer Secrets?
kubectl auth can-i get secrets \
  --as=system:serviceaccount:lab-rbac:deployer \
  -n lab-rbac
```

**Salida esperada:** `no`

**El deployer puede crear y actualizar, pero NO puede eliminar ni leer Secrets.**

### Probar permisos del auditor (acceso global)

```bash
# ¿Puede el auditor listar Pods en kube-system? (otro namespace)
kubectl auth can-i list pods \
  --as=system:serviceaccount:lab-rbac:auditor \
  -n kube-system
```

**Salida esperada:** `yes`

```bash
# ¿Puede el auditor CREAR algo?
kubectl auth can-i create pods \
  --as=system:serviceaccount:lab-rbac:auditor \
  -n lab-rbac
```

**Salida esperada:** `no`

**El auditor puede VER todo en todos los namespaces, pero no puede modificar nada.**

---

## Paso 4: Probar Permisos Desde Dentro del Cluster (10 min)

El Pod `test-rbac` tiene el ServiceAccount `desarrollador`. Vamos a ejecutar comandos desde dentro para ver los permisos en acción.

### Listar Pods (permitido)

```bash
kubectl exec test-rbac -n lab-rbac -- kubectl get pods -n lab-rbac
```

**Salida esperada:**

```
NAME                          READY   STATUS    RESTARTS   AGE
test-rbac                     1/1     Running   0          5m
webapp-rbac-xxxxx-yyyyy       1/1     Running   0          5m
webapp-rbac-xxxxx-zzzzz       1/1     Running   0          5m
```

### Intentar crear un Pod (denegado)

```bash
kubectl exec test-rbac -n lab-rbac -- kubectl run test-pod --image=nginx -n lab-rbac
```

**Salida esperada (ERROR):**

```
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:lab-rbac:desarrollador"
cannot create resource "pods" in API group "" in the namespace "lab-rbac"
```

**Esto es RBAC en acción**: el ServiceAccount `desarrollador` no tiene el verbo `create` en el recurso `pods`, así que Kubernetes rechaza la petición.

### Intentar leer Secrets (denegado)

```bash
kubectl exec test-rbac -n lab-rbac -- kubectl get secrets -n lab-rbac
```

**Salida esperada (ERROR):**

```
Error from server (Forbidden): secrets is forbidden: User "system:serviceaccount:lab-rbac:desarrollador"
cannot list resource "secrets" in API group "" in the namespace "lab-rbac"
```

---

## Paso 5: Ver las RoleBindings (5 min)

### Listar todas las RoleBindings

```bash
kubectl get rolebindings -n lab-rbac -o wide
```

**Salida esperada:**

```
NAME                    ROLE                  AGE   USERS   GROUPS   SERVICEACCOUNTS
deployer-acceso         Role/deployer-role    10m                    lab-rbac/deployer
desarrollador-lectura   Role/solo-lectura     10m                    lab-rbac/desarrollador
```

### Ver la ClusterRoleBinding

```bash
kubectl get clusterrolebindings | grep rbac-resumen
```

**Salida esperada:**

```
auditor-acceso-global   ClusterRole/auditor-global   10m
```

---

## Paso 6: Listar TODOS los Permisos de un ServiceAccount (5 min)

```bash
# Ver todos los permisos del desarrollador en lab-rbac
kubectl auth can-i --list \
  --as=system:serviceaccount:lab-rbac:desarrollador \
  -n lab-rbac
```

**Salida esperada:**

```
Resources                       Non-Resource URLs   Resource Names   Verbs
configmaps                      []                  []               [get list]
endpoints                       []                  []               [get list watch]
pods                            []                  []               [get list watch]
pods/log                        []                  []               [get list watch]
services                        []                  []               [get list watch]
deployments.apps                []                  []               [get list watch]
replicasets.apps                []                  []               [get list watch]
...
```

---

## Paso 7: Simular un Despliegue como Deployer (8 min)

```bash
# Crear un Deployment como si fueras el deployer
kubectl create deployment nginx-test --image=nginx:1.25-alpine \
  --as=system:serviceaccount:lab-rbac:deployer \
  -n lab-rbac
```

**Salida esperada:** `deployment.apps/nginx-test created`

```bash
# Verificar que se creó
kubectl get deployments -n lab-rbac \
  --as=system:serviceaccount:lab-rbac:deployer
```

```bash
# Intentar ELIMINAR (denegado - no tiene verbo delete)
kubectl delete deployment nginx-test \
  --as=system:serviceaccount:lab-rbac:deployer \
  -n lab-rbac
```

**Salida esperada (ERROR):**

```
Error from server (Forbidden): deployments.apps "nginx-test" is forbidden:
User "system:serviceaccount:lab-rbac:deployer" cannot delete resource "deployments"
```

```bash
# Limpiar como admin
kubectl delete deployment nginx-test -n lab-rbac
```

---

## Troubleshooting: Problemas Comunes de RBAC

### Error: "Forbidden" al ejecutar kubectl

```
Error from server (Forbidden): pods is forbidden: User "..." cannot list resource "pods"
```

**Causa**: El usuario/ServiceAccount no tiene permisos suficientes.
**Diagnóstico**:
```bash
# Ver qué permisos tiene
kubectl auth can-i --list --as=<user> -n <namespace>
```
**Solución**: Crear un Role con los verbos necesarios y un RoleBinding que los asigne.

### ServiceAccount no puede acceder a recursos de otro namespace

**Causa**: Un Role solo aplica en su namespace. Para acceso cross-namespace necesitas un ClusterRole.
**Solución**: Crear un ClusterRole + ClusterRoleBinding.

### Permisos se aplican pero no funcionan

**Causa**: El RoleBinding puede estar en el namespace equivocado.
**Diagnóstico**:
```bash
kubectl get rolebindings -n <namespace> -o wide
```
**Solución**: Verificar que el RoleBinding está en el mismo namespace que el Role y los recursos.

### No puedo ver quién tiene acceso a qué

**Solución**: Listar todos los bindings:
```bash
kubectl get rolebindings,clusterrolebindings -A -o wide
```

---

## Limpieza (1 min)

```bash
./cleanup.sh
```

**Salida esperada:**

```
🧹 Iniciando limpieza del Lab Resumen RBAC...

  ✓ namespace/lab-rbac eliminado (todos los recursos incluidos)
  ✓ clusterrole/auditor-global eliminado
  ✓ clusterrolebinding/auditor-acceso-global eliminado

Restaurando namespace por defecto...
  ✓ Contexto restaurado a namespace 'default'

🎉 Limpieza completada!
```

**Nota importante**: El cleanup elimina también el ClusterRole y ClusterRoleBinding, que son recursos cluster-scoped y NO se eliminan automáticamente al borrar el namespace.

---

## Resumen de Conceptos Practicados

| Concepto | Comando Clave | Lo que aprendiste |
|----------|--------------|-------------------|
| ServiceAccount | `kubectl get sa -n <ns>` | Identidad para Pods |
| Role | `kubectl describe role <name>` | Permisos en un namespace |
| ClusterRole | `kubectl describe clusterrole` | Permisos globales |
| RoleBinding | `kubectl get rolebindings -o wide` | Asignar permisos |
| auth can-i | `kubectl auth can-i <verb> <resource>` | Verificar permisos |
| --as | `kubectl --as=system:serviceaccount:...` | Impersonar usuario |

---

## Siguiente Paso

Ahora que entiendes RBAC, el siguiente módulo te enseñará **Network Policies**: cómo controlar qué Pods pueden comunicarse con qué otros Pods a nivel de red. RBAC controla quién puede GESTIONAR recursos, Network Policies controlan quién puede COMUNICARSE con quién.
