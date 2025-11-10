# 🔄 Módulo 06: ReplicaSets y Gestión de Réplicas

**Duración**: 90 minutos  
**Modalidad**: Práctico-Intensivo  
**Dificultad**: Intermedio  
**Versión Kubernetes**: 1.28+ (Noviembre 2025)

## 🎯 Objetivos del Módulo

Al completar este módulo serás capaz de:

- ✅ **Comprender ReplicaSets** y su rol en la arquitectura de Kubernetes
- ✅ **Crear y gestionar ReplicaSets** usando manifiestos YAML
- ✅ **Entender la relación** entre ReplicaSets y Pods
- ✅ **Implementar auto-recuperación** de Pods con ReplicaSets
- ✅ **Escalar aplicaciones** horizontalmente
- ✅ **Usar selectores de labels** para gestión de Pods
- ✅ **Comprender limitaciones** y cuándo usar Deployments

---

## 📋 Tabla de Contenidos

1. [Prerequisitos](#-1-prerequisitos)
2. [¿Qué es un ReplicaSet?](#-2-qué-es-un-replicaset)
3. [Creación de ReplicaSets](#-3-creación-de-replicasets)
4. [Gestión y Operaciones](#-4-gestión-y-operaciones)
5. [Escalado de Réplicas](#-5-escalado-de-réplicas)
6. [Ownership y References](#-6-ownership-y-references)
7. [Limitaciones de ReplicaSets](#-7-limitaciones-de-replicasets)
8. [Mejores Prácticas](#-8-mejores-prácticas)
9. [Ejemplos y Laboratorios](#-ejemplos-y-laboratorios-prácticos)
10. [Recursos Adicionales](#-9-recursos-adicionales)

---

## 🔧 1. Prerequisitos

### **Verificar Cluster**

```bash
# Verificar que minikube está corriendo
minikube status

# Verificar conexión
kubectl cluster-info

# Limpiar recursos previos del módulo 05
kubectl delete pods --all
```

### **Conceptos Previos Requeridos**

Antes de comenzar este módulo, debes dominar:
- ✅ Creación y gestión de Pods (Módulo 05)
- ✅ Labels y Selectors
- ✅ Manifiestos YAML básicos
- ✅ Comandos kubectl esenciales

---

## 🔍 2. ¿Qué es un ReplicaSet?

### **2.1 Definición**

Un **ReplicaSet** es un controlador de Kubernetes que:
- Garantiza que un número específico de réplicas de Pod estén corriendo en todo momento
- Auto-recupera Pods que fallan o son eliminados
- Escala horizontal automáticamente
- Gestiona Pods usando selectores de labels

### **2.2 ReplicaSet vs Pod**

```
┌─────────────────────────────────────────────────────────────┐
│                  POD vs REPLICASET                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🔴 POD (Nivel Bajo)                                        │
│  ├─ Unidad mínima de ejecución                              │
│  ├─ Sin auto-recuperación                                   │
│  ├─ Sin escalado automático                                 │
│  └─ Ideal para: Testing, Jobs únicos                        │
│                                                             │
│  🟢 REPLICASET (Nivel Alto)                                 │
│  ├─ Controlador de Pods                                     │
│  ├─ Auto-recuperación automática                            │
│  ├─ Escalado horizontal                                     │
│  ├─ Gestión declarativa de estado                           │
│  └─ Ideal para: Aplicaciones con múltiples réplicas         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### **2.3 Arquitectura y Funcionamiento**

```
┌─────────────────────────────────────────────────────────────┐
│              ARQUITECTURA DE REPLICASET                     │
└─────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │   ReplicaSet    │
                    │  replicas: 3    │
                    │  selector:      │
                    │    app: web     │
                    └────────┬────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
                ▼            ▼            ▼
           ┌────────┐  ┌────────┐  ┌────────┐
           │ Pod 1  │  │ Pod 2  │  │ Pod 3  │
           │app: web│  │app: web│  │app: web│
           │owner:RS│  │owner:RS│  │owner:RS│
           └────────┘  └────────┘  └────────┘

Flujo de Control:
1. ReplicaSet busca Pods con label "app: web"
2. Cuenta cuántos Pods encuentra
3. Si encuentra < 3: crea nuevos Pods
4. Si encuentra > 3: elimina Pods sobrantes
5. Si encuentra = 3: no hace nada (estado deseado alcanzado)
```

**Componentes clave**:

1. **Selector**: Define qué Pods gestionar usando labels
2. **Replicas**: Número deseado de Pods
3. **Template**: Plantilla para crear nuevos Pods
4. **Owner References**: Marca de propiedad en cada Pod

### **2.4 Ciclo de Vida**

```yaml
Estado Deseado (Manifiesto)    ←→    Estado Actual (Cluster)
        ↓                                     ↓
   replicas: 3                           Pods running: 2
        ↓                                     ↓
    ReplicaSet detecta diferencia
        ↓
    Crea 1 Pod adicional
        ↓
    Estado reconciliado: 3 = 3
```

---

## 🚀 3. Creación de ReplicaSets

### **3.1 Estructura Básica de un ReplicaSet**

📄 **Ver ejemplo**: [`ejemplos/01-basico/replicaset-simple.yaml`](./ejemplos/01-basico/replicaset-simple.yaml)

```yaml
apiVersion: apps/v1      # ← API Group: apps
kind: ReplicaSet         # ← Tipo de recurso
metadata:
  name: nginx-rs         # ← Nombre del ReplicaSet
  labels:
    app: nginx           # ← Labels del ReplicaSet
spec:
  replicas: 3            # ← Número de réplicas deseadas
  selector:              # ← Cómo encuentra Pods
    matchLabels:
      app: nginx         # ← Busca Pods con este label
  template:              # ← Plantilla para crear Pods
    metadata:
      labels:
        app: nginx       # ← Labels de los Pods creados
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
```

**Componentes explicados**:

| Campo | Descripción | Obligatorio |
|-------|-------------|-------------|
| `apiVersion: apps/v1` | API Group para ReplicaSets | ✅ Sí |
| `kind: ReplicaSet` | Tipo de objeto | ✅ Sí |
| `metadata.name` | Nombre único del ReplicaSet | ✅ Sí |
| `spec.replicas` | Número de Pods deseados | ✅ Sí |
| `spec.selector` | Selector de labels | ✅ Sí |
| `spec.template` | Plantilla de Pod | ✅ Sí |

### **3.2 Crear ReplicaSet**

```bash
# Crear ReplicaSet desde archivo
kubectl apply -f ejemplos/01-basico/replicaset-simple.yaml

# Verificar creación
kubectl get replicasets
# o forma corta:
kubectl get rs

# Ver Pods creados por el ReplicaSet
kubectl get pods --show-labels

# Ver detalles del ReplicaSet
kubectl describe rs nginx-rs
```

**Salida esperada**:
```
NAME       DESIRED   CURRENT   READY   AGE
nginx-rs   3         3         3       30s

NAME                READY   STATUS    RESTARTS   AGE   LABELS
nginx-rs-abc12      1/1     Running   0          30s   app=nginx
nginx-rs-def34      1/1     Running   0          30s   app=nginx
nginx-rs-ghi56      1/1     Running   0          30s   app=nginx
```

### **3.3 Anatomía del Selector**

El **selector** es crucial - define qué Pods gestiona el ReplicaSet:

```yaml
spec:
  selector:
    matchLabels:          # Coincidencia exacta
      app: nginx
      tier: frontend
    
    # O usando matchExpressions (más flexible)
    matchExpressions:
    - key: app
      operator: In
      values:
      - nginx
      - apache
```

**Operadores disponibles**:
- `In`: Label value está en la lista
- `NotIn`: Label value NO está en la lista
- `Exists`: Label key existe
- `DoesNotExist`: Label key NO existe

---

## ⚙️ 4. Gestión y Operaciones

### **4.1 Inspeccionar ReplicaSets**

```bash
# Listar todos los ReplicaSets
kubectl get rs

# Ver detalles completos
kubectl describe rs nginx-rs

# Ver manifiesto completo en YAML
kubectl get rs nginx-rs -o yaml

# Ver solo la especificación
kubectl get rs nginx-rs -o jsonpath='{.spec}' | jq

# Ver eventos relacionados
kubectl get events --field-selector involvedObject.name=nginx-rs
```

### **4.2 Auto-Recuperación Demostrada**

📄 **Ver ejemplo**: [`ejemplos/02-auto-recuperacion/replicaset-auto-heal.yaml`](./ejemplos/02-auto-recuperacion/replicaset-auto-heal.yaml)

```bash
# Crear ReplicaSet con 3 réplicas
kubectl apply -f ejemplos/02-auto-recuperacion/replicaset-auto-heal.yaml

# Ver Pods creados
kubectl get pods -l app=auto-heal

# Eliminar un Pod manualmente
POD_NAME=$(kubectl get pods -l app=auto-heal -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Observar auto-recuperación inmediata
kubectl get pods -l app=auto-heal --watch
```

**Qué sucede**:
1. ReplicaSet detecta que hay 2 Pods (falta 1)
2. Crea un nuevo Pod automáticamente
3. Estado deseado (3) = Estado actual (3)

### **4.3 Ver Logs de Múltiples Pods**

```bash
# Logs de todos los Pods de un ReplicaSet
kubectl logs -l app=nginx --all-containers=true

# Logs de un Pod específico
kubectl logs nginx-rs-abc12

# Seguir logs en tiempo real
kubectl logs -l app=nginx -f --max-log-requests=10
```

### **4.4 Ejecutar Comandos en Pods**

```bash
# Entrar a un Pod específico
kubectl exec -it nginx-rs-abc12 -- sh

# Ejecutar comando en todos los Pods (con bucle)
for pod in $(kubectl get pods -l app=nginx -o name); do
  echo "Pod: $pod"
  kubectl exec $pod -- hostname
done
```

---

## 📊 5. Escalado de Réplicas

### **5.1 Escalado Declarativo (Recomendado)**

Modifica el manifiesto YAML:

```yaml
spec:
  replicas: 5  # ← Cambiar de 3 a 5
```

```bash
# Aplicar cambios
kubectl apply -f ejemplos/01-basico/replicaset-simple.yaml

# Ver escalado en tiempo real
kubectl get pods -l app=nginx --watch
```

### **5.2 Escalado Imperativo**

```bash
# Escalar a 5 réplicas
kubectl scale rs nginx-rs --replicas=5

# Verificar
kubectl get rs nginx-rs

# Ver nuevos Pods creándose
kubectl get pods -l app=nginx
```

### **5.3 Reducir Réplicas**

```bash
# Reducir a 2 réplicas
kubectl scale rs nginx-rs --replicas=2

# ReplicaSet eliminará 3 Pods automáticamente
kubectl get pods -l app=nginx --watch
```

**Nota importante**: 
- ✅ ReplicaSet elige qué Pods eliminar
- ✅ Generalmente elimina los más recientes primero
- ✅ Garantiza terminación graceful (grace period)

### **5.4 Ejemplo Práctico: Escalado Bajo Carga**

📄 **Ver ejemplo**: [`ejemplos/03-escalado/replicaset-load-test.yaml`](./ejemplos/03-escalado/replicaset-load-test.yaml)

```bash
# Crear ReplicaSet con 3 réplicas
kubectl apply -f ejemplos/03-escalado/replicaset-load-test.yaml

# Simular carga (en otro terminal)
kubectl run load-generator --image=busybox --restart=Never -- /bin/sh -c \
  "while sleep 0.01; do wget -q -O- http://nginx-service; done"

# Escalar para manejar la carga
kubectl scale rs nginx-load --replicas=10

# Ver distribución de carga
kubectl top pods -l app=load-test
```

---

## 🔗 6. Ownership y References

### **6.1 Owner References Explicado**

Cada Pod creado por un ReplicaSet tiene metadata especial:

```bash
# Ver Owner Reference de un Pod
kubectl get pod nginx-rs-abc12 -o yaml | grep -A 5 ownerReferences
```

**Salida**:
```yaml
ownerReferences:
- apiVersion: apps/v1
  kind: ReplicaSet
  name: nginx-rs
  uid: 12345-67890-abcde
  controller: true
  blockOwnerDeletion: true
```

**Significado**:
- `kind: ReplicaSet`: Este Pod pertenece a un ReplicaSet
- `name: nginx-rs`: Nombre del ReplicaSet dueño
- `uid`: ID único del ReplicaSet
- `controller: true`: El ReplicaSet controla este Pod
- `blockOwnerDeletion: true`: No se puede eliminar el ReplicaSet mientras el Pod exista

### **6.2 Adopción de Pods Huérfanos**

⚠️ **PELIGRO**: ReplicaSet puede adoptar Pods existentes

📄 **Ver ejemplo**: [`ejemplos/04-ownership/pods-huerfanos.yaml`](./ejemplos/04-ownership/pods-huerfanos.yaml)

```bash
# Crear Pods manualmente SIN ReplicaSet
kubectl run pod-manual-1 --image=nginx:alpine
kubectl run pod-manual-2 --image=nginx:alpine

# Agregar label que coincide con un ReplicaSet
kubectl label pod pod-manual-1 app=nginx
kubectl label pod pod-manual-2 app=nginx

# Crear ReplicaSet que busca app=nginx
kubectl apply -f ejemplos/01-basico/replicaset-simple.yaml

# Ver qué pasó
kubectl get pods --show-labels
kubectl get rs nginx-rs
```

**Resultado**:
```
NAME                READY   LABELS              OWNER
pod-manual-1        1/1     app=nginx          ReplicaSet/nginx-rs ← ADOPTADO
pod-manual-2        1/1     app=nginx          ReplicaSet/nginx-rs ← ADOPTADO
nginx-rs-xyz        1/1     app=nginx          ReplicaSet/nginx-rs ← CREADO
```

**¿Por qué es peligroso?**
- Los Pods manuales pueden tener configuración diferente
- ReplicaSet los trata como iguales
- Crea inconsistencias en el cluster

### **6.3 Verificar Propiedad**

```bash
# Ver qué Pods son gestionados por el ReplicaSet
kubectl get pods -l app=nginx -o custom-columns=\
NAME:.metadata.name,\
OWNER:.metadata.ownerReferences[0].name

# Ver UID del ReplicaSet
kubectl get rs nginx-rs -o jsonpath='{.metadata.uid}'

# Comparar con UID en los Pods
kubectl get pod nginx-rs-abc12 -o jsonpath='{.metadata.ownerReferences[0].uid}'
```

---

## ⚠️ 7. Limitaciones de ReplicaSets

### **7.1 Problema #1: No Actualiza Pods Existentes**

**El problema**:
```yaml
# Manifiesto inicial
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine  # ← Versión vieja
```

```bash
# Cambiar a nueva versión
# image: nginx:1.21-alpine

# Aplicar cambios
kubectl apply -f replicaset.yaml
# ReplicaSet updated ✅

# Ver Pods
kubectl get pods -o jsonpath='{.items[*].spec.containers[0].image}'
# nginx:1.20-alpine ← ¡Siguen con la versión vieja! ❌
```

**¿Por qué?**
- ReplicaSet solo garantiza NÚMERO de réplicas
- No verifica CONFIGURACIÓN de Pods existentes
- Pods existentes NO se actualizan automáticamente

**Solución temporal (manual)**:
```bash
# Eliminar Pods uno por uno
kubectl delete pod nginx-rs-abc12
# ReplicaSet crea nuevo Pod con nueva configuración

# Repetir para cada Pod...
# ❌ Esto es tedioso y propenso a errores
```

### **7.2 Problema #2: Sin Rolling Updates**

```
┌──────────────────────────────────────────────────┐
│         COMPARACIÓN DE UPDATES                   │
├──────────────────────────────────────────────────┤
│                                                  │
│  ❌ REPLICASET (Manual):                         │
│  1. Cambiar manifiesto                           │
│  2. Eliminar Pod 1 manualmente                   │
│  3. Esperar que se cree                          │
│  4. Repetir para Pod 2, 3, 4...                  │
│  5. Downtime durante el proceso                  │
│                                                  │
│  ✅ DEPLOYMENT (Automático):                     │
│  1. Cambiar manifiesto                           │
│  2. kubectl apply                                │
│  3. Rolling update automático                    │
│  4. Zero downtime                                │
│  5. Rollback automático si falla                 │
│                                                  │
└──────────────────────────────────────────────────┘
```

### **7.3 Problema #3: Sin Historial de Versiones**

```bash
# Ver revisiones del ReplicaSet
kubectl rollout history rs nginx-rs
# Error: ReplicaSets don't support rollout history

# No hay rollback
kubectl rollout undo rs nginx-rs
# Error: This command is not supported for ReplicaSets
```

### **7.4 Cuándo Usar ReplicaSet vs Deployment**

| Característica | ReplicaSet | Deployment |
|----------------|------------|------------|
| Auto-recuperación | ✅ | ✅ |
| Escalado | ✅ | ✅ |
| Rolling Updates | ❌ | ✅ |
| Rollback | ❌ | ✅ |
| Historial de versiones | ❌ | ✅ |
| Estrategias de deploy | ❌ | ✅ |
| **Uso recomendado** | Testing, aprendizaje | **Producción** |

**Conclusión**: 
- 🟡 ReplicaSets: Útiles para entender la arquitectura
- 🟢 Deployments: **Siempre úsalos en producción**

---

## ✅ 8. Mejores Prácticas

### **8.1 Naming Conventions**

```yaml
metadata:
  name: <app>-<component>-rs
  # Ejemplos:
  # frontend-web-rs
  # backend-api-rs
  # cache-redis-rs
```

### **8.2 Labels Consistentes**

```yaml
metadata:
  labels:
    app: myapp           # ← Aplicación
    component: frontend  # ← Componente
    tier: web           # ← Capa
spec:
  selector:
    matchLabels:
      app: myapp        # ← DEBE coincidir
  template:
    metadata:
      labels:
        app: myapp      # ← DEBE coincidir
        component: frontend
        tier: web
```

**Regla de oro**: 
- Selector DEBE estar incluido en template labels
- Template labels pueden tener labels adicionales
- Nunca crees Pods manualmente con los mismos labels

### **8.3 Resources y Limits**

```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

### **8.4 Health Checks**

```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
```

### **8.5 Seguridad**

```yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
      - name: nginx
        image: nginx:alpine
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
```

---

## 🧪 Ejemplos y Laboratorios Prácticos

### **📁 Ejemplos YAML Disponibles**

Todos los ejemplos están en [`ejemplos/`](./ejemplos/) organizados por categoría:

#### **01-basico/** - Fundamentos de ReplicaSets
| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| `replicaset-simple.yaml` | ReplicaSet básico con 3 réplicas | Estructura básica, selector |
| `replicaset-multi-container.yaml` | ReplicaSet con Pods multi-contenedor | Template avanzado |

#### **02-auto-recuperacion/** - Auto-Healing
| Archivo | Descripción | Demuestra |
|---------|-------------|-----------|
| `replicaset-auto-heal.yaml` | Demo de auto-recuperación | Self-healing, resiliencia |

#### **03-escalado/** - Gestión de Réplicas
| Archivo | Descripción | Uso |
|---------|-------------|-----|
| `replicaset-load-test.yaml` | ReplicaSet para pruebas de carga | Escalado horizontal |

#### **04-ownership/** - Ownership y Referencias
| Archivo | Descripción | Demuestra |
|---------|-------------|-----------|
| `pods-huerfanos.yaml` | Pods sin owner | Adopción por ReplicaSet |
| `replicaset-adoption.yaml` | ReplicaSet que adopta Pods | Owner references |

#### **05-limitaciones/** - Problemas de ReplicaSets
| Archivo | Descripción | Problema |
|---------|-------------|----------|
| `replicaset-no-update.yaml` | Update que no funciona | Sin rolling updates |

**Ver guía completa**: [`ejemplos/README.md`](./ejemplos/README.md)

---

### **🎓 Laboratorios Hands-On**

| # | Laboratorio | Duración | Nivel | Temas |
|---|-------------|----------|-------|-------|
| 1 | [Creación de ReplicaSets](./laboratorios/lab-01-crear-replicasets.md) | 30 min | Básico | Crear, inspeccionar, escalar |
| 2 | [Auto-Recuperación y Escalado](./laboratorios/lab-02-auto-recuperacion.md) | 40 min | Intermedio | Self-healing, escalado dinámico |
| 3 | [Ownership y Limitaciones](./laboratorios/lab-03-ownership-limitaciones.md) | 50 min | Avanzado | Owner refs, adopción, updates |

**Comandos rápidos**:
```bash
# Aplicar todos los ejemplos básicos
kubectl apply -f ejemplos/01-basico/

# Limpiar todos los ejemplos
kubectl delete rs --all
```

---

## 📚 9. Recursos Adicionales

### **9.1 Comandos de Referencia Rápida**

```bash
# CREAR
kubectl apply -f replicaset.yaml
kubectl create rs nginx-rs --image=nginx --replicas=3 --dry-run=client -o yaml

# LISTAR
kubectl get rs
kubectl get rs -o wide
kubectl get rs --show-labels

# INSPECCIONAR
kubectl describe rs nginx-rs
kubectl get rs nginx-rs -o yaml

# ESCALAR
kubectl scale rs nginx-rs --replicas=5
kubectl edit rs nginx-rs

# ELIMINAR
kubectl delete rs nginx-rs
kubectl delete rs nginx-rs --cascade=orphan  # Mantener Pods

# LOGS Y DEBUG
kubectl logs -l app=nginx --all-containers
kubectl get events --field-selector involvedObject.kind=ReplicaSet
```

### **9.2 Recursos de Aprendizaje**

- 📖 [Documentación oficial - ReplicaSets](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
- 📖 [ReplicaSet vs Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- 📖 [Owner References](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/)
- 🎓 [Deployments en Kubernetes - pabpereza.dev](https://pabpereza.dev/docs/cursos/kubernetes/deployments_en_kubernetes_rolling_updates_y_gestion_de_aplicaciones)

### **9.3 Próximos Pasos**

En el **Módulo 07: Deployments**, aprenderás:
- ✅ Rolling updates automáticos
- ✅ Rollback a versiones anteriores
- ✅ Estrategias de despliegue (RollingUpdate, Recreate)
- ✅ Gestión de versiones e historial
- ✅ Blue-Green y Canary deployments

---

## 🎓 Resumen del Módulo

Has aprendido:

✅ **Qué es un ReplicaSet** y su arquitectura  
✅ **Crear y gestionar ReplicaSets** con YAML  
✅ **Auto-recuperación** de Pods automática  
✅ **Escalar horizontalmente** aplicaciones  
✅ **Owner references** y adopción de Pods  
✅ **Limitaciones** y cuándo usar Deployments  

**Puntos clave**:
- 🔑 ReplicaSets **garantizan número de réplicas**, no actualizan configuración
- 🔑 **Owner references** controlan propiedad de Pods
- 🔑 **Selectores de labels** deben ser únicos y específicos
- 🔑 En producción: **siempre usa Deployments**, no ReplicaSets directos

---

**📅 Fecha de actualización**: Noviembre 2025  
**🔖 Versión**: 1.0  
**👨‍💻 Autor**: Curso Kubernetes AKS

---

**⬅️ Anterior**: [Módulo 05 - Gestión de Pods](../modulo-05-gestion-pods/README.md)  
**➡️ Siguiente**: [Módulo 07 - Deployments y Rolling Updates](../modulo-07-deployments/README.md)
