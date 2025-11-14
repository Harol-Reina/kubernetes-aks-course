# Laboratorio 1: Variables de Entorno y Field References

## Objetivos

✅ Crear variables de entorno estáticas en Pods  
✅ Usar Field References para acceder a metadata del Pod  
✅ Inyectar límites de recursos como variables  
✅ Verificar variables dentro de contenedores

**Duración estimada**: 30 minutos

---

## Parte 1: Variables Estáticas (10 min)

### Paso 1: Crear Pod con Variables

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: env-basic
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | grep APP_ && sleep 3600"]
    env:
    - name: APP_NAME
      value: "MyFirstApp"
    - name: APP_VERSION
      value: "1.0.0"
    - name: DATABASE_HOST
      value: "db.example.com"
EOF
```

### Paso 2: Verificar Variables

```bash
# Ver logs (env se imprime al arrancar)
kubectl logs env-basic

# Ejecutar comando dentro del Pod
kubectl exec env-basic -- env | grep -E '(APP_|DATABASE)'

# Output esperado:
# APP_NAME=MyFirstApp
# APP_VERSION=1.0.0
# DATABASE_HOST=db.example.com
```

### Paso 3: Usar Variables en Script

```bash
kubectl exec env-basic -- sh -c 'echo "Conectando a $DATABASE_HOST..."'

# Output:
# Conectando a db.example.com...
```

---

## Parte 2: Field References - Metadata (10 min)

### Paso 1: Pod con Metadata

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: field-ref-metadata
  labels:
    app: demo
    tier: backend
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | grep POD_ && sleep 3600"]
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    
    - name: POD_LABELS
      valueFrom:
        fieldRef:
          fieldPath: metadata.labels
EOF
```

### Paso 2: Verificar Field References

```bash
kubectl exec field-ref-metadata -- env | grep POD_

# Output esperado:
# POD_NAME=field-ref-metadata
# POD_NAMESPACE=default
# POD_IP=10.244.x.x
# POD_LABELS={"app":"demo","tier":"backend"}
```

### Paso 3: Usar en Logging

Imagina una app que necesita loggear el nombre del Pod:

```bash
kubectl exec field-ref-metadata -- sh -c '
  echo "[$(date)] [$POD_NAMESPACE/$POD_NAME] Procesando request desde $POD_IP"
'

# Output:
# [Mon Nov 10 12:34:56 UTC 2025] [default/field-ref-metadata] Procesando request desde 10.244.1.5
```

---

## Parte 3: Resource Field References (10 min)

### Paso 1: Pod con Límites de Recursos

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: resource-ref
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | grep -E '(CPU|MEM)' && sleep 3600"]
    
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
    
    env:
    - name: MY_CPU_REQUEST
      valueFrom:
        resourceFieldRef:
          resource: requests.cpu
    
    - name: MY_CPU_LIMIT
      valueFrom:
        resourceFieldRef:
          resource: limits.cpu
    
    - name: MY_MEM_REQUEST
      valueFrom:
        resourceFieldRef:
          resource: requests.memory
          divisor: "1Mi"
    
    - name: MY_MEM_LIMIT
      valueFrom:
        resourceFieldRef:
          resource: limits.memory
          divisor: "1Mi"
EOF
```

### Paso 2: Verificar Recursos

```bash
kubectl exec resource-ref -- env | grep -E '(CPU|MEM)'

# Output esperado:
# MY_CPU_REQUEST=1  (100 milicores)
# MY_CPU_LIMIT=1    (500 milicores)
# MY_MEM_REQUEST=128
# MY_MEM_LIMIT=512
```

**Nota**: CPU se reporta en unidades (1 = 1000m), por eso 100m = 0.1 ≈ 1.

---

## Experimento: Logging Distribuido

Crear un Deployment con field references para logging:

```yaml
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-logging
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: app
        image: busybox
        command: 
        - sh
        - -c
        - |
          while true; do
            echo "[\$LOG_NAMESPACE/\$LOG_POD_NAME@\$LOG_NODE] Request procesado en \$LOG_POD_IP"
            sleep 5
          done
        
        env:
        - name: LOG_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        
        - name: LOG_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        
        - name: LOG_NODE
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        
        - name: LOG_POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
EOF
```

Ver logs de múltiples Pods:

```bash
# Logs de todos los Pods
kubectl logs -l app=webapp --tail=10

# Output:
# [default/webapp-7d8f6c9b4-x5k2p@minikube] Request procesado en 10.244.0.5
# [default/webapp-7d8f6c9b4-p2k4m@minikube] Request procesado en 10.244.0.6
# [default/webapp-7d8f6c9b4-z8n1q@minikube] Request procesado en 10.244.0.7
```

---

## Ejercicio Final

Crea un Pod que combine **todos los tipos** de variables:

1. **Estáticas**: `APP_NAME=MyApp`, `VERSION=1.0`
2. **Field References**: `POD_NAME`, `POD_NAMESPACE`, `POD_IP`
3. **Resource References**: `CPU_LIMIT`, `MEM_LIMIT`

<details>
<summary>💡 Solución</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: combined-vars
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | sort && sleep 3600"]
    
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
    
    env:
    # Estáticas
    - name: APP_NAME
      value: "MyApp"
    - name: VERSION
      value: "1.0"
    
    # Field References
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    
    # Resource References
    - name: CPU_LIMIT
      valueFrom:
        resourceFieldRef:
          resource: limits.cpu
    - name: MEM_LIMIT
      valueFrom:
        resourceFieldRef:
          resource: limits.memory
          divisor: "1Mi"
```

</details>

---

## Preguntas de Repaso

**1. ¿Cuál es la diferencia entre una variable estática y una field reference?**

<details>
<summary>Respuesta</summary>

- **Variable estática**: Valor hardcoded, siempre igual (ej: `APP_NAME=MyApp`)
- **Field reference**: Valor dinámico extraído del Pod en runtime (ej: `POD_NAME` es diferente para cada Pod de un Deployment)

</details>

**2. ¿Qué pasa si eliminas y recreacreates un Pod con field references?**

<details>
<summary>Respuesta</summary>

Las field references se actualizan automáticamente porque se evalúan en **runtime**. El nuevo Pod tendrá:
- Nuevo `POD_NAME` (nombre generado)
- Posible nueva `POD_IP`
- Posible diferente `POD_NODE`

</details>

**3. ¿Por qué usar `divisor: "1Mi"` en resource field references?**

<details>
<summary>Respuesta</summary>

Convierte bytes a MiB para legibilidad:
- Sin divisor: `134217728` (bytes)
- Con `divisor: "1Mi"`: `128` (MiB)

</details>

---

## Limpieza

```bash
kubectl delete pod env-basic field-ref-metadata resource-ref combined-vars
kubectl delete deployment webapp-logging
```

---

## Resumen

✅ Variables estáticas: Valores simples hardcoded  
✅ Field References: Metadata/status dinámico del Pod  
✅ Resource References: Límites de CPU/memoria  
✅ Uso práctico: Logging distribuido, auto-configuración

**Continúa con**: [Laboratorio 2 - ConfigMaps Avanzado](lab-02-configmaps-avanzado.md)
