# Troubleshooting - Problemas Comunes del Laboratorio

---

## 1. Pod en estado Pending

**Sintoma**: `kubectl get pods` muestra STATUS `Pending`.

**Causas y soluciones**:

```bash
# Ver la razon exacta
kubectl describe pod <nombre-pod> -n <namespace>
# Busca la seccion "Events" al final
```

| Causa | Mensaje en Events | Solucion |
|-------|-------------------|----------|
| No hay CPU/RAM en el nodo | `Insufficient cpu` o `Insufficient memory` | Espera a que el cluster autoscaler agregue nodos, o reduce los requests del Pod |
| ResourceQuota excedida | `exceeded quota` | Revisa la quota: `kubectl describe resourcequota -n <ns>`. Elimina pods o aumenta la quota |
| LimitRange viola minimo/maximo | `minimum cpu usage per Container` | Ajusta los requests/limits del Pod para que esten dentro del rango del LimitRange |

---

## 2. Pod en estado CrashLoopBackOff

**Sintoma**: El Pod se reinicia repetidamente.

```bash
# Ver logs del contenedor que falla
kubectl logs <nombre-pod> -n <namespace>
kubectl logs <nombre-pod> -n <namespace> --previous  # logs del intento anterior

# Ver eventos
kubectl describe pod <nombre-pod> -n <namespace>
```

| Causa | Que buscar | Solucion |
|-------|-----------|----------|
| OOMKilled | `Last State: Terminated, Reason: OOMKilled` | Aumenta `limits.memory` del contenedor |
| Error en command/args | `Error` en los logs | Verifica que la imagen y los comandos son correctos |
| Secret no existe | `secret "X" not found` | Crea el Secret antes que el Deployment |
| ConfigMap no existe | `configmap "X" not found` | Crea el ConfigMap antes que el Deployment |

---

## 3. Service LoadBalancer sin IP externa

**Sintoma**: `EXTERNAL-IP` muestra `<pending>` por mas de 5 minutos.

```bash
kubectl get svc -n tienda-web
kubectl describe svc frontend-external -n tienda-web
```

**Soluciones**:
- Azure tarda 2-3 minutos en asignar IP. Espera un poco mas.
- Verifica que tienes permisos para crear Load Balancers en Azure.
- En la consola de Azure, revisa el recurso Load Balancer en el resource group `MC_...`.

---

## 4. No hay metricas en kubectl top

**Sintoma**: `kubectl top pods` da error `Metrics API not available`.

```bash
# Verificar que metrics-server esta corriendo
kubectl get pods -n kube-system | grep metrics-server

# Si no esta, en AKS deberia estar por defecto.
# Reinstalar si es necesario:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**Nota**: metrics-server necesita ~1 minuto despues de iniciar para empezar a reportar metricas.

---

## 5. Prometheus no recolecta metricas

**Sintoma**: En Grafana los dashboards muestran "No data".

```bash
# Verificar que Prometheus esta corriendo
kubectl get pods -n monitoring

# Acceder a Prometheus UI y verificar targets
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
# Abrir http://localhost:9090/targets
```

**Verificar**:
- Que los targets muestran estado `UP` (no `DOWN`)
- Que Prometheus puede acceder a los endpoints de metricas
- Que el ServiceMonitor selector coincide con los labels de los Services

---

## 6. Comunicacion cross-namespace falla

**Sintoma**: `curl` o `wget` desde un Pod no llega a un Service en otro namespace.

```bash
# Test manual de DNS
kubectl run debug --rm -it --image=busybox:1.36 -n tienda-web -- nslookup api-gateway.tienda-api.svc.cluster.local

# Test de conectividad HTTP
kubectl run debug --rm -it --image=busybox:1.36 -n tienda-web -- wget -qO- http://api-gateway.tienda-api.svc.cluster.local:8080/health
```

**Verificar**:
- El Service existe: `kubectl get svc -n tienda-api`
- El Pod del Service esta Running
- El puerto es correcto (8080 no 80)
- DNS funciona: nslookup devuelve IP

---

## 7. Cluster Autoscaler no agrega nodos

**Sintoma**: Hay Pods Pending pero no se agregan nodos.

```bash
# Ver eventos del cluster autoscaler
kubectl get events -A --field-selector reason=ScaleUp
kubectl get events -A --field-selector reason=NotTriggerScaleUp

# Ver estado actual de nodos
kubectl get nodes -o wide
```

**Posibles causas**:
- Ya se alcanzo el maximo de nodos (4 en este lab)
- El Pod Pending tiene requests que no caben en ningun tipo de nodo
- El autoscaler necesita 1-3 minutos para reaccionar

---

## 8. Error "exceeded quota" al crear Pods

**Sintoma**: `kubectl apply` falla con `forbidden: exceeded quota`.

```bash
# Ver uso actual vs limite de la quota
kubectl describe resourcequota -n <namespace>
```

**Ejemplo de salida**:
```
Name:            quota-tienda-api
Resource         Used   Hard
--------         ----   ----
limits.cpu       900m   3
limits.memory    640Mi  2Gi
pods             3      10
requests.cpu     300m   1500m
requests.memory  384Mi  1Gi
```

**Solucion**: Elimina Pods que ya no necesites o ajusta la quota.

---

## 9. Grafana no carga / port-forward se corta

**Sintoma**: `kubectl port-forward` se desconecta.

```bash
# Verificar que el Pod de Grafana esta Running
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Reiniciar port-forward
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

# Si el Pod esta en CrashLoopBackOff, revisar logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

**Tip**: Si usas Azure Cloud Shell, el port-forward puede ser inestable. Usa una terminal local.

---

## 10. Comandos de diagnostico rapido

```bash
# Estado general de todo el lab
kubectl get all -n tienda-web
kubectl get all -n tienda-api
kubectl get all -n tienda-db
kubectl get all -n stress-test
kubectl get all -n monitoring

# Consumo de recursos por nodo
kubectl top nodes

# Consumo de recursos por pod (todos los namespaces del lab)
kubectl top pods -n tienda-web
kubectl top pods -n tienda-api
kubectl top pods -n tienda-db
kubectl top pods -n stress-test

# Quotas de todos los namespaces
kubectl describe resourcequota -A | grep -A 10 "tienda\|stress"

# Eventos recientes (ultimos 10 minutos)
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Estado del HPA
kubectl get hpa -n tienda-api

# Nodos y su capacidad
kubectl describe nodes | grep -A 5 "Allocated resources"
```
