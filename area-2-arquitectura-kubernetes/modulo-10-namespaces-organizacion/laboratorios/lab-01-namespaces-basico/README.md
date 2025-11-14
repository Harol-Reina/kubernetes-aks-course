# Laboratorio 01: Fundamentos de Namespaces

**Duración estimada**: 35-40 minutos  
**Nivel**: Básico  
**Requisitos**: Cluster Kubernetes funcional (minikube, kind, o cloud)

---

## Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

✅ Crear y gestionar namespaces con kubectl  
✅ Configurar y cambiar contextos de kubectl  
✅ Desplegar aplicaciones en diferentes namespaces  
✅ Entender y usar DNS cross-namespace  
✅ Gestionar recursos en múltiples namespaces simultáneamente

---

## Parte 1: Creación y Gestión de Namespaces (10 min)

### Paso 1: Listar Namespaces del Sistema

```bash
# Ver namespaces existentes
kubectl get namespaces
# o abreviado:
kubectl get ns

# Salida esperada:
# NAME              STATUS   AGE
# default           Active   5d
# kube-node-lease   Active   5d
# kube-public       Active   5d
# kube-system       Active   5d
```

**Pregunta**: ¿Cuál es el propósito de cada namespace del sistema?

<details>
<summary>Respuesta</summary>

- **default**: Namespace predeterminado para objetos sin namespace especificado
- **kube-system**: Componentes del sistema de Kubernetes (API server, etcd, etc.)
- **kube-public**: Recursos públicamente accesibles
- **kube-node-lease**: Heartbeat de nodos (mecanismo de detección de fallos)
</details>

### Paso 2: Crear Namespaces (Imperativo)

```bash
# Crear namespace 'development'
kubectl create namespace development

# Crear con labels
kubectl create namespace staging \
  --labels=environment=staging,team=platform

# Verificar
kubectl get ns --show-labels
```

### Paso 3: Crear Namespace (Declarativo)

Crear archivo `namespace-production.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: prod
    team: platform
    critical: "true"
  annotations:
    description: "Production environment"
    sla: "99.9% uptime"
```

```bash
# Aplicar
kubectl apply -f namespace-production.yaml

# Verificar
kubectl describe namespace production
```

**✅ Checkpoint 1**: Deberías tener 3 namespaces nuevos (development, staging, production)

---

## Parte 2: Gestión de Contextos kubectl (10 min)

### Paso 4: Ver Contexto Actual

```bash
# Ver contexto activo
kubectl config current-context

# Ver namespace por defecto del contexto actual
kubectl config view --minify | grep namespace:
```

### Paso 5: Cambiar Namespace del Contexto

```bash
# Establecer namespace 'development' como default
kubectl config set-context --current --namespace=development

# Verificar
kubectl config view --minify | grep namespace:

# Ahora 'kubectl get pods' listará pods de 'development'
kubectl get pods  # (sin -n)
```

### Paso 6: Crear Contextos Personalizados

```bash
# Crear contexto para staging
kubectl config set-context staging-context \
  --cluster=$(kubectl config current-context | cut -d'-' -f1) \
  --namespace=staging

# Crear contexto para production
kubectl config set-context prod-context \
  --cluster=$(kubectl config current-context | cut -d'-' -f1) \
  --namespace=production

# Listar contextos
kubectl config get-contexts

# Cambiar entre contextos
kubectl config use-context staging-context
kubectl get pods  # Ahora lista pods de 'staging'

kubectl config use-context prod-context
kubectl get pods  # Ahora lista pods de 'production'
```

**💡 Tip**: Instala `kubens` para cambiar de namespace rápidamente:

```bash
# macOS
brew install kubectx

# Uso
kubens                  # Listar namespaces
kubens development      # Cambiar a 'development'
kubens -                # Volver al anterior
```

**✅ Checkpoint 2**: Debes poder cambiar entre contextos y ver el namespace correcto

---

## Parte 3: Despliegue Multi-Namespace (10 min)

### Paso 7: Desplegar Aplicación en Múltiples Namespaces

Crear archivo `webapp-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  type: ClusterIP
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 80
```

```bash
# Desplegar en development
kubectl apply -f webapp-deployment.yaml -n development

# Desplegar en staging (1 réplica más)
kubectl apply -f webapp-deployment.yaml -n staging
kubectl scale deployment webapp --replicas=3 -n staging

# Desplegar en production (5 réplicas)
kubectl apply -f webapp-deployment.yaml -n production
kubectl scale deployment webapp --replicas=5 -n production

# Verificar despliegues
kubectl get deployments --all-namespaces -l app=webapp
```

**Salida esperada**:

```
NAMESPACE     NAME     READY   UP-TO-DATE   AVAILABLE   AGE
development   webapp   2/2     2            2           1m
staging       webapp   3/3     3            3           1m
production    webapp   5/5     5            5           1m
```

**✅ Checkpoint 3**: Debes ver webapp desplegada en los 3 namespaces con diferentes réplicas

---

## Parte 4: DNS Cross-Namespace (10 min)

### Paso 8: Verificar Servicios

```bash
# Listar servicios en todos los namespaces
kubectl get svc --all-namespaces -l app=webapp

# Verificar DNS de cada servicio
# Formato: <service-name>.<namespace-name>.svc.cluster.local
```

**DNS esperado**:
- Development: `webapp.development.svc.cluster.local`
- Staging: `webapp.staging.svc.cluster.local`
- Production: `webapp.production.svc.cluster.local`

### Paso 9: Testing DNS desde Mismo Namespace

```bash
# Crear Pod de prueba en development
kubectl run test-pod --image=alpine -n development \
  --restart=Never -- sleep 3600

# Ejecutar shell en el Pod
kubectl exec -it test-pod -n development -- sh

# Dentro del Pod:
apk add curl bind-tools

# Resolver DNS (mismo namespace - short name funciona)
nslookup webapp
# Debe resolver a webapp.development.svc.cluster.local

# Hacer request HTTP
curl http://webapp
# Debe retornar página de nginx

exit
```

### Paso 10: Testing DNS Cross-Namespace

```bash
# Desde Pod en 'development', acceder a service en 'production'
kubectl exec -it test-pod -n development -- sh

# Dentro del Pod:
# ❌ Short name NO funciona cross-namespace
curl http://webapp
# Retorna webapp de 'development'

# ✅ Usar namespace en el DNS
curl http://webapp.production
# Retorna webapp de 'production'

# ✅ FQDN completo
curl http://webapp.production.svc.cluster.local
# Retorna webapp de 'production'

# Verificar resolución DNS
nslookup webapp.production
nslookup webapp.staging

exit
```

**✅ Checkpoint 4**: Debes poder acceder a servicios cross-namespace usando `<service>.<namespace>`

---

## Parte 5: Gestión de Recursos Multi-Namespace (5 min)

### Paso 11: Comandos Útiles

```bash
# Ver TODOS los pods en TODOS los namespaces
kubectl get pods --all-namespaces -l app=webapp

# Contar pods por namespace
kubectl get pods --all-namespaces -l app=webapp --no-headers | \
  awk '{print $1}' | sort | uniq -c

# Ver uso de recursos
kubectl top pods -n development
kubectl top pods -n production

# Ver logs de una app en múltiples namespaces
for ns in development staging production; do
  echo "=== Logs from $ns ==="
  kubectl logs -n $ns -l app=webapp --tail=5
done

# Eliminar deployment en namespace específico
kubectl delete deployment webapp -n development

# Verificar
kubectl get deployments --all-namespaces -l app=webapp
```

---

## Desafíos Adicionales

### Desafío 1: Comunicación Cross-Namespace

Crea un Pod en `development` que llame a un servicio en `production` y muestre la respuesta.

<details>
<summary>Solución</summary>

```bash
# Crear Job que hace curl
kubectl create job test-cross-ns --image=curlimages/curl -n development \
  -- curl -s http://webapp.production

# Ver logs
kubectl logs -n development jobs/test-cross-ns
```
</details>

### Desafío 2: Comparar Configuraciones

Escribe un script que compare el número de réplicas de 'webapp' en los 3 namespaces.

<details>
<summary>Solución</summary>

```bash
#!/bin/bash
for ns in development staging production; do
  replicas=$(kubectl get deployment webapp -n $ns -o jsonpath='{.spec.replicas}')
  echo "$ns: $replicas réplicas"
done
```
</details>

---

## Limpieza

```bash
# Eliminar recursos creados
kubectl delete -f webapp-deployment.yaml -n development
kubectl delete -f webapp-deployment.yaml -n staging
kubectl delete -f webapp-deployment.yaml -n production

# Eliminar namespaces (CUIDADO: elimina TODOS los recursos dentro)
kubectl delete namespace development
kubectl delete namespace staging
kubectl delete namespace production

# Restaurar contexto original
kubectl config use-context <tu-contexto-original>
```

---

## Resumen

En este laboratorio has aprendido:

✅ Crear namespaces con kubectl y YAML  
✅ Configurar y cambiar contextos  
✅ Desplegar aplicaciones en múltiples namespaces  
✅ Usar DNS cross-namespace  
✅ Gestionar recursos multi-namespace

### Próximos Pasos

- **Lab 02**: ResourceQuota y LimitRange
- **Módulo 11**: Resource Limits en Pods (detalle)
- **Módulo 19**: RBAC (permisos por namespace)

---

**📚 Navegación**:
- ⬅️ [Volver al README del módulo](../README.md)
- ➡️ [Lab 02: ResourceQuota y LimitRange](lab-02-quotas-limits.md)
