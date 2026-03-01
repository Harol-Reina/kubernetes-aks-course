# Apendice B: Cheat Sheet Consolidado

> Este apendice consolida los comandos mas usados del curso. Para versiones completas, consulta:
> - [kubectl Cheat Sheet](../recursos/cheat-sheets/kubectl-cheatsheet.md)
> - [Docker Cheat Sheet](../recursos/cheat-sheets/docker-cheatsheet.md)

---

## Comandos Esenciales de kubectl

### Informacion del Cluster

```bash
# Informacion general del cluster
kubectl cluster-info

# Version de kubectl y del servidor
kubectl version

# Estado de los nodos
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node <node-name>

# Configuracion actual
kubectl config view
kubectl config current-context
kubectl config get-contexts
```

### Contextos y Namespaces

```bash
# Cambiar context
kubectl config use-context <context-name>

# Cambiar namespace por defecto
kubectl config set-context --current --namespace=<namespace>

# Listar namespaces
kubectl get namespaces

# Crear namespace
kubectl create namespace <namespace>
```

### Gestion de Pods

```bash
# Listar pods
kubectl get pods
kubectl get pods -o wide
kubectl get pods --all-namespaces
kubectl get pods -n <namespace>

# Describir pod (eventos, estado, configuracion)
kubectl describe pod <pod-name>

# Crear pod imperativo
kubectl run <pod-name> --image=<image>
kubectl run nginx --image=nginx --port=80

# Eliminar pod
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> --force --grace-period=0
```

### Logs y Debugging

```bash
# Ver logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous
kubectl logs <pod-name> --since=1h
kubectl logs <pod-name> --tail=100
kubectl logs -f <pod-name>                    # Follow en tiempo real

# Ejecutar comandos en pod
kubectl exec <pod-name> -- <command>
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -c <container> -- /bin/sh

# Port forwarding
kubectl port-forward <pod-name> <local-port>:<pod-port>
kubectl port-forward svc/<service-name> <local-port>:<service-port>
```

### Deployments

```bash
# Crear deployment
kubectl create deployment <name> --image=<image>
kubectl create deployment nginx --image=nginx --replicas=3

# Listar deployments
kubectl get deployments
kubectl get deploy

# Actualizar imagen
kubectl set image deployment/<name> <container>=<image>

# Escalar
kubectl scale deployment <name> --replicas=<number>

# Rolling updates y rollbacks
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=<N>
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>
kubectl rollout restart deployment/<name>
```

### Services

```bash
# Listar services
kubectl get services
kubectl get svc

# Crear service (exponer deployment)
kubectl expose deployment <name> --port=<port> --target-port=<target-port>
kubectl expose deployment nginx --port=80 --target-port=80 --type=NodePort

# Describir service
kubectl describe service <service-name>
```

### ConfigMaps y Secrets

```bash
# ConfigMaps
kubectl create configmap <name> --from-literal=<key>=<value>
kubectl create configmap <name> --from-file=<file>
kubectl get configmaps
kubectl describe configmap <name>
kubectl get configmap <name> -o yaml

# Secrets
kubectl create secret generic <name> --from-literal=<key>=<value>
kubectl create secret generic <name> --from-file=<file>
kubectl create secret tls <name> --cert=<cert-file> --key=<key-file>
kubectl get secrets
kubectl get secret <name> -o yaml
```

### Labels y Selectors

```bash
# Listar con labels
kubectl get pods --show-labels
kubectl get pods -l <key>=<value>
kubectl get pods -l "app in (frontend,backend)"

# Agregar/cambiar/remover labels
kubectl label pod <pod-name> <key>=<value>
kubectl label pod <pod-name> <key>=<new-value> --overwrite
kubectl label pod <pod-name> <key>-
```

### RBAC

```bash
# Verificar permisos
kubectl auth can-i <verb> <resource>
kubectl auth can-i create pods
kubectl auth can-i create pods --as=user1
kubectl auth can-i create pods --as=system:serviceaccount:default:mysa

# Crear roles y bindings
kubectl create clusterrole pod-reader --verb=get,list,watch --resource=pods
kubectl create rolebinding pod-reader-binding --clusterrole=pod-reader --user=user1
```

### Jobs y CronJobs

```bash
# Crear Job
kubectl create job hello --image=busybox -- echo "Hello World"

# Crear CronJob
kubectl create cronjob hello --image=busybox --schedule="*/1 * * * *" -- echo "Hello"

# Ver estado
kubectl get jobs
kubectl get cronjobs
```

### Archivos YAML

```bash
# Aplicar / crear / eliminar desde archivo
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/
kubectl create -f <file.yaml>
kubectl delete -f <file.yaml>

# Validar sintaxis (dry run)
kubectl apply --dry-run=client -f <file.yaml>
kubectl apply --dry-run=server -f <file.yaml>

# Exportar YAML de recurso existente
kubectl get <resource> <name> -o yaml
```

### Troubleshooting

```bash
# Uso de recursos
kubectl top nodes
kubectl top pods
kubectl top pods --containers

# Eventos del cluster
kubectl get events
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector type=Warning

# Probar conectividad y DNS
kubectl run test --image=curlimages/curl -i --rm --restart=Never -- curl <url>
kubectl run test --image=busybox -i --rm --restart=Never -- nslookup <service>
```

### Formatos de Salida

```bash
# Diferentes formatos
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# Sorting
kubectl get pods --sort-by=.metadata.creationTimestamp
```

### Node Maintenance

```bash
# Evacuar nodo
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Restaurar nodo
kubectl uncordon <node-name>
```

### HPA (Horizontal Pod Autoscaler)

```bash
# Crear HPA
kubectl autoscale deployment <name> --cpu-percent=50 --min=1 --max=10

# Ver HPA
kubectl get hpa
kubectl describe hpa <hpa-name>
```

### One-liners Utiles

```bash
# Pods que no estan Running
kubectl get pods --field-selector=status.phase!=Running

# Ver imagenes de todos los pods
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .spec.containers[*]}{.image}{"\n"}{end}{end}'

# Ver recursos utilizados ordenados
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory
```

---

## Comandos Esenciales de Docker

### Ciclo de Vida de Contenedores

```bash
# Ejecutar contenedor
docker run <image>
docker run -d nginx                               # Background
docker run --name mi-nginx nginx                  # Con nombre
docker run -p 8080:80 nginx                       # Mapeo de puertos
docker run -it ubuntu /bin/bash                   # Interactivo
docker run -e MYSQL_ROOT_PASSWORD=secret mysql:8  # Variables de entorno
docker run -v /host/path:/container/path nginx    # Con volumen
docker run -it --rm alpine sh                     # Auto-eliminar al salir

# Gestionar contenedores
docker ps                                         # Listar en ejecucion
docker ps -a                                      # Todos (incluidos detenidos)
docker stop <container>
docker start <container>
docker restart <container>
docker rm <container>
docker rm -f <container>                          # Forzar
```

### Interaccion con Contenedores

```bash
# Ejecutar comandos
docker exec <container> <command>
docker exec -it <container> /bin/bash

# Logs
docker logs <container>
docker logs -f <container>                        # Follow
docker logs --tail 100 <container>

# Inspeccionar
docker inspect <container>
docker stats                                      # Recursos en tiempo real
docker top <container>                            # Procesos
```

### Imagenes

```bash
# Gestion de imagenes
docker images
docker pull <image>:<tag>
docker rmi <image>
docker image prune -a

# Construir imagen
docker build -t <name>:<tag> .
docker build -t mi-app:1.0 -f Dockerfile.prod .
docker build --no-cache -t mi-app .

# Registry
docker tag <source> <target>
docker push <image>:<tag>
docker login
```

### Volumenes y Redes

```bash
# Volumenes
docker volume create <name>
docker volume ls
docker volume inspect <name>
docker volume rm <name>
docker volume prune

# Redes
docker network create <name>
docker network ls
docker network inspect <name>
docker network connect <network> <container>
docker network disconnect <network> <container>
```

### Docker Compose

```bash
# Operaciones basicas
docker-compose up -d
docker-compose down
docker-compose down -v                            # Con volumenes
docker-compose ps
docker-compose logs -f <service>
docker-compose exec <service> <command>
docker-compose build
docker-compose restart
docker-compose up --scale web=3
docker-compose config                             # Validar
```

### Limpieza

```bash
# Limpieza selectiva
docker container prune
docker image prune -a
docker volume prune
docker network prune

# Limpieza completa
docker system prune -a
docker system df                                  # Ver uso de espacio
```

### Limitacion de Recursos

```bash
docker run -m 512m nginx                          # Limitar memoria
docker run --cpus="1.5" nginx                     # Limitar CPU
docker run --restart=unless-stopped nginx          # Restart policy
```

### Emergencia

```bash
docker stop $(docker ps -q)                       # Parar todos
docker kill $(docker ps -q)                       # Matar todos
docker system prune -a --volumes                  # Eliminar todo
sudo systemctl restart docker                     # Reiniciar daemon
journalctl -u docker.service                      # Logs del daemon
```
