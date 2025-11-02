# Kubectl Cheat Sheet

## 🚀 Comandos Básicos

### Información del Clúster
```bash
# Información del clúster
kubectl cluster-info

# Versión de kubectl y del servidor
kubectl version

# Estado de los nodos
kubectl get nodes
kubectl describe node <node-name>

# Configuración actual
kubectl config view
kubectl config current-context
kubectl config get-contexts
```

### Contexts y Namespaces
```bash
# Cambiar context
kubectl config use-context <context-name>

# Cambiar namespace por defecto
kubectl config set-context --current --namespace=<namespace>

# Listar namespaces
kubectl get namespaces
kubectl get ns

# Crear namespace
kubectl create namespace <namespace>
```

## 📦 Gestión de Pods

### Operaciones Básicas
```bash
# Listar pods
kubectl get pods
kubectl get pods -o wide
kubectl get pods --all-namespaces
kubectl get pods -n <namespace>

# Describir pod
kubectl describe pod <pod-name>
kubectl describe pod <pod-name> -n <namespace>

# Crear pod
kubectl run <pod-name> --image=<image>
kubectl run nginx --image=nginx --port=80

# Eliminar pod
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> -n <namespace>
```

### Logs y Debugging
```bash
# Ver logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous
kubectl logs <pod-name> --since=1h
kubectl logs <pod-name> --tail=100
kubectl logs -f <pod-name>  # Follow logs

# Ejecutar comandos en pod
kubectl exec <pod-name> -- <command>
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -c <container> -- /bin/sh

# Port forwarding
kubectl port-forward <pod-name> <local-port>:<pod-port>
kubectl port-forward pod/nginx 8080:80
```

## 🚀 Deployments

### Gestión de Deployments
```bash
# Crear deployment
kubectl create deployment <name> --image=<image>
kubectl create deployment nginx --image=nginx --replicas=3

# Listar deployments
kubectl get deployments
kubectl get deploy

# Describir deployment
kubectl describe deployment <deployment-name>

# Actualizar deployment
kubectl set image deployment/<deployment-name> <container>=<image>
kubectl set image deployment/nginx nginx=nginx:1.21

# Escalar deployment
kubectl scale deployment <deployment-name> --replicas=<number>
kubectl scale deployment nginx --replicas=5

# Eliminar deployment
kubectl delete deployment <deployment-name>
```

### Rollouts
```bash
# Ver historial de rollout
kubectl rollout history deployment/<deployment-name>

# Ver estado de rollout
kubectl rollout status deployment/<deployment-name>

# Hacer rollback
kubectl rollout undo deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name> --to-revision=<revision>

# Pausar/reanudar rollout
kubectl rollout pause deployment/<deployment-name>
kubectl rollout resume deployment/<deployment-name>
```

## 🌐 Services

### Operaciones con Services
```bash
# Listar services
kubectl get services
kubectl get svc

# Describir service
kubectl describe service <service-name>

# Crear service
kubectl expose deployment <deployment-name> --port=<port> --target-port=<target-port>
kubectl expose deployment nginx --port=80 --target-port=80 --type=NodePort

# Eliminar service
kubectl delete service <service-name>
```

### Port Forwarding para Services
```bash
# Port forward a service
kubectl port-forward service/<service-name> <local-port>:<service-port>
kubectl port-forward svc/nginx 8080:80
```

## 📋 ConfigMaps y Secrets

### ConfigMaps
```bash
# Crear ConfigMap desde literales
kubectl create configmap <name> --from-literal=<key>=<value>
kubectl create configmap app-config --from-literal=database_url=postgres://localhost

# Crear ConfigMap desde archivo
kubectl create configmap <name> --from-file=<file>
kubectl create configmap app-config --from-file=config.properties

# Listar ConfigMaps
kubectl get configmaps
kubectl get cm

# Ver contenido de ConfigMap
kubectl describe configmap <name>
kubectl get configmap <name> -o yaml
```

### Secrets
```bash
# Crear Secret desde literales
kubectl create secret generic <name> --from-literal=<key>=<value>
kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password=secret

# Crear Secret desde archivo
kubectl create secret generic <name> --from-file=<file>

# Crear Secret TLS
kubectl create secret tls <name> --cert=<cert-file> --key=<key-file>

# Listar Secrets
kubectl get secrets

# Ver Secret (no muestra valores)
kubectl describe secret <name>
kubectl get secret <name> -o yaml
```

## 🔍 Labels y Selectors

### Trabajar con Labels
```bash
# Listar con labels
kubectl get pods --show-labels
kubectl get pods -l <key>=<value>
kubectl get pods -l "app in (frontend,backend)"

# Agregar label
kubectl label pod <pod-name> <key>=<value>
kubectl label pod nginx app=web

# Remover label
kubectl label pod <pod-name> <key>-
kubectl label pod nginx app-

# Cambiar label
kubectl label pod <pod-name> <key>=<new-value> --overwrite
```

### Filtros Avanzados
```bash
# Múltiples condiciones
kubectl get pods -l app=nginx,version=v1

# Operadores
kubectl get pods -l 'environment!=production'
kubectl get pods -l 'tier in (frontend,backend)'
kubectl get pods -l 'partition notin (customer1,customer2)'
```

## 🛠️ Troubleshooting

### Información de Debug
```bash
# Top (recursos)
kubectl top nodes
kubectl top pods
kubectl top pods --containers

# Eventos
kubectl get events
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector type=Warning

# Describe para debugging
kubectl describe <resource-type> <resource-name>
kubectl describe pod <pod-name>
kubectl describe node <node-name>
```

### Comandos de Red
```bash
# Probar conectividad
kubectl run test-pod --image=curlimages/curl -i --rm --restart=Never -- curl <url>
kubectl run test-pod --image=busybox -i --rm --restart=Never -- nslookup <service-name>

# DNS testing
kubectl run test-dns --image=busybox -i --rm --restart=Never -- nslookup kubernetes.default
```

## 📁 Archivos YAML

### Aplicar y Gestionar
```bash
# Aplicar archivo
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/

# Crear desde archivo
kubectl create -f <file.yaml>

# Eliminar desde archivo
kubectl delete -f <file.yaml>

# Validar sintaxis
kubectl apply --dry-run=client -f <file.yaml>
kubectl apply --dry-run=server -f <file.yaml>

# Ver YAML de recurso existente
kubectl get <resource> <name> -o yaml
kubectl get pod nginx -o yaml > nginx-pod.yaml
```

### Patches
```bash
# Patch estratégico
kubectl patch deployment nginx -p '{"spec":{"replicas":3}}'

# Patch tipo merge
kubectl patch deployment nginx --type merge -p '{"spec":{"replicas":3}}'

# Patch JSON
kubectl patch deployment nginx --type json -p='[{"op": "replace", "path": "/spec/replicas", "value": 3}]'
```

## 🔧 Recursos Avanzados

### HPA (Horizontal Pod Autoscaler)
```bash
# Crear HPA
kubectl autoscale deployment <deployment-name> --cpu-percent=50 --min=1 --max=10

# Ver HPA
kubectl get hpa
kubectl describe hpa <hpa-name>
```

### RBAC
```bash
# Verificar permisos
kubectl auth can-i <verb> <resource>
kubectl auth can-i create pods
kubectl auth can-i create pods --as=user1
kubectl auth can-i create pods --as=system:serviceaccount:default:mysa

# Crear ClusterRole
kubectl create clusterrole pod-reader --verb=get,list,watch --resource=pods

# Crear RoleBinding
kubectl create rolebinding pod-reader-binding --clusterrole=pod-reader --user=user1
```

### Jobs y CronJobs
```bash
# Crear Job
kubectl create job hello --image=busybox -- echo "Hello World"

# Crear CronJob
kubectl create cronjob hello --image=busybox --schedule="*/1 * * * *" -- echo "Hello World"

# Ver Jobs
kubectl get jobs
kubectl get cronjobs
```

## 📊 Formatos de Salida

```bash
# Diferentes formatos
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# Sorting
kubectl get pods --sort-by=.metadata.creationTimestamp
kubectl get pods --sort-by=.status.phase
```

## 🎯 Comandos Útiles One-liners

```bash
# Obtener IPs de todos los pods
kubectl get pods -o wide --no-headers | awk '{print $6}'

# Pods que no están Running
kubectl get pods --field-selector=status.phase!=Running

# Eliminar todos los pods en estado Evicted
kubectl get pods | grep Evicted | awk '{print $1}' | xargs kubectl delete pod

# Ver imágenes de todos los contenedores
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .spec.containers[*]}{.image}{"\n"}{end}{end}'

# Contar pods por namespace
kubectl get pods --all-namespaces | awk '{print $1}' | sort | uniq -c

# Ver recursos utilizados por pods
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory
```

## 🚨 Comandos de Emergencia

```bash
# Forzar eliminación de pod
kubectl delete pod <pod-name> --force --grace-period=0

# Evacuar nodo (cordon + drain)
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Deshabilitar scheduling en nodo
kubectl cordon <node-name>

# Habilitar scheduling en nodo
kubectl uncordon <node-name>

# Reiniciar todos los pods de un deployment
kubectl rollout restart deployment/<deployment-name>
```