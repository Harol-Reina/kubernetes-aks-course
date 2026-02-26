# Laboratorio 03: Ingress en Produccion

**Duracion estimada:** 60-70 minutos
**Nivel:** Avanzado
**Prerequisitos:** Labs 01 y 02 completados

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Canary Deployment** | Estrategia de despliegue que envia un porcentaje pequeno del trafico a una nueva version (canary) mientras la mayoria va a la version estable. Permite validar cambios con riesgo minimo y rollback inmediato |
| **Canary Weight** | Anotacion que define el porcentaje (0-100) de trafico dirigido al backend canary. Se puede ajustar dinamicamente con `kubectl patch` sin downtime |
| **Rate Limiting** | Limita peticiones por segundo (limit-rps) y conexiones simultaneas (limit-connections) por IP. Protege contra abuso y sobrecarga. Retorna 503 cuando se excede el limite |
| **IP Whitelist** | Restringe acceso a un endpoint solo a rangos de IP autorizados (CIDR). Peticiones desde IPs no autorizadas reciben 403 Forbidden. Esencial para endpoints administrativos |
| **PodDisruptionBudget** | Garantiza un numero minimo de replicas disponibles durante disrupciones voluntarias (drain de nodo, upgrades). No protege contra crashes involuntarios |
| **Metricas Prometheus** | El Ingress Controller NGINX expone metricas en formato Prometheus (puerto 10254). Permite monitorear requests, latencia, errores y estado de backends |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Parte | Descripcion |
|---------|-------|-------------|
| `deployment-canary.yaml` | 1 | Deployments y Services para v1 (estable) y v2 (canary) de la app |
| `ingress-production.yaml` | 1 | Ingress principal que dirige trafico a v1 |
| `ingress-canary.yaml` | 1 | Ingress canary que desvía 20% del trafico a v2 |
| `ingress-rate-limit.yaml` | 2 | Ingress con rate limiting (5 rps, 10 conexiones max) |
| `ingress-whitelist.yaml` | 2 | Ingress con restriccion de acceso por IP |
| `pdb-ingress-nginx.yaml` | 3 | PodDisruptionBudget para el Ingress Controller |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Labs 01 y 02 completados
- Ingress Controller NGINX instalado
- Helm instalado (para escalar el controller)

### Verificacion del entorno

```bash
# Verificar Ingress Controller
kubectl get pods -n ingress-nginx

# Verificar IngressClass
kubectl get ingressclass

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Parte 1: Canary Deployments (20 min)

### Paso 1.1: Revisar y desplegar v1 y v2

Revisa el archivo `deployment-canary.yaml`:

```bash
cat deployment-canary.yaml
```

Puntos clave del manifiesto:
- **Dos Deployments**: app-v1 (estable) y app-v2 (canary), cada uno con 3 replicas
- **Label de version**: `version: v1` y `version: v2` para seleccion independiente
- **Services separados**: cada version tiene su propio Service
- **Respuestas identificables**: v1 muestra "VERSION 1", v2 muestra "VERSION 2 - NEW"

```bash
kubectl apply -f deployment-canary.yaml

# Verificar
kubectl get deployments,services,pods -l app=myapp
```

**Salida esperada:**
```
NAME                     READY   UP-TO-DATE
deployment.apps/app-v1   3/3     3
deployment.apps/app-v2   3/3     3

NAME             TYPE        CLUSTER-IP     PORT(S)
service/app-v1   ClusterIP   10.96.x.x      80/TCP
service/app-v2   ClusterIP   10.96.x.x      80/TCP
```

### Paso 1.2: Configurar canary (20% trafico a v2)

Revisa los archivos de Ingress:

```bash
cat ingress-production.yaml
cat ingress-canary.yaml
```

Puntos clave:
- **ingress-production.yaml**: Ingress principal, sin anotaciones canary, dirige a app-v1
- **ingress-canary.yaml**: marcado con `canary: "true"` y `canary-weight: "20"`, dirige a app-v2
- **Mismo host**: ambos Ingress usan `app.example.com`

```bash
# Configurar DNS
echo "$NODE_IP app.example.com" | sudo tee -a /etc/hosts

# Aplicar ambos Ingress
kubectl apply -f ingress-production.yaml
kubectl apply -f ingress-canary.yaml

# Verificar
kubectl get ingress
```

### Paso 1.3: Verificar distribucion

```bash
# Generar 100 requests
for i in {1..100}; do
  curl -s http://app.example.com | grep -o "VERSION [12]"
done | sort | uniq -c

# Deberia mostrar ~20 v2 y ~80 v1
```

### Paso 1.4: Ajustar peso del canary

```bash
# Aumentar canary a 50%
kubectl patch ingress canary -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"50"}}}'

# Probar nuevamente
for i in {1..100}; do
  curl -s http://app.example.com | grep -o "VERSION [12]"
done | sort | uniq -c
# Deberia mostrar ~50/50
```

---

## Parte 2: Rate Limiting y Seguridad (15 min)

### Paso 2.1: Rate limiting

Revisa el archivo `ingress-rate-limit.yaml`:

```bash
cat ingress-rate-limit.yaml
```

Puntos clave del manifiesto:
- **limit-rps: "5"**: maximo 5 peticiones por segundo por IP
- **limit-connections: "10"**: maximo 10 conexiones simultaneas
- Exceder el limite retorna **503 Service Temporarily Unavailable**

```bash
# Configurar DNS
echo "$NODE_IP api.example.com" | sudo tee -a /etc/hosts

kubectl apply -f ingress-rate-limit.yaml

# Probar rate limit (enviar 20 requests rapidos)
for i in {1..20}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://api.example.com
done
# Veras varios 503 Service Temporarily Unavailable
```

### Paso 2.2: IP Whitelist

Revisa el archivo `ingress-whitelist.yaml`:

```bash
cat ingress-whitelist.yaml
```

Puntos clave del manifiesto:
- **whitelist-source-range**: lista de rangos CIDR permitidos
- IPs no autorizadas reciben **403 Forbidden**
- Formato: `IP/32` para una sola IP, `10.0.0.0/8` para rango completo

```bash
# Obtener tu IP y editar el archivo
MY_IP=$(curl -s https://ifconfig.me)
echo "Tu IP publica: $MY_IP"

# Opcion 1: Editar ingress-whitelist.yaml y reemplazar 203.0.113.1 con tu IP
# Opcion 2: Usar sed
sed "s/203.0.113.1/$MY_IP/" ingress-whitelist.yaml | kubectl apply -f -

# Configurar DNS
echo "$NODE_IP admin.example.com" | sudo tee -a /etc/hosts

# Probar (deberia funcionar desde tu IP)
curl http://admin.example.com
```

---

## Parte 3: Alta Disponibilidad (15 min)

### Paso 3.1: Escalar ingress controller

```bash
# Escalar a 3 replicas
helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --reuse-values \
  --set controller.replicaCount=3

# Verificar
kubectl get pods -n ingress-nginx
```

### Paso 3.2: PodDisruptionBudget

Revisa el archivo `pdb-ingress-nginx.yaml`:

```bash
cat pdb-ingress-nginx.yaml
```

Puntos clave del manifiesto:
- **minAvailable: 2**: siempre al menos 2 replicas disponibles
- **namespace: ingress-nginx**: el PDB va en el mismo namespace que el controller
- Protege durante drain de nodos y upgrades del cluster

```bash
kubectl apply -f pdb-ingress-nginx.yaml

# Verificar
kubectl get pdb -n ingress-nginx
kubectl describe pdb ingress-nginx-pdb -n ingress-nginx
```

---

## Parte 4: Monitoreo (10 min)

### Paso 4.1: Ver metricas

```bash
# Port-forward al puerto de metricas
kubectl port-forward -n ingress-nginx svc/nginx-ingress-controller-metrics 10254:10254 &

# Ver metricas de Prometheus
curl http://localhost:10254/metrics | grep nginx_ingress_controller_requests
```

### Paso 4.2: Logs

```bash
# Logs en tiempo real
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller -f

# Filtrar por Ingress especifico
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller | grep "canary"
```

---

## Best Practices Checklist

### Seguridad
- [ ] TLS habilitado con certificados validos
- [ ] Force SSL redirect configurado
- [ ] HSTS enabled
- [ ] Rate limiting en APIs publicas
- [ ] IP whitelist para endpoints sensibles
- [ ] Basic auth o OAuth para admin

### Alta Disponibilidad
- [ ] Minimo 3 replicas del ingress controller
- [ ] PodDisruptionBudget configurado
- [ ] Resource requests/limits definidos
- [ ] Health checks (readiness/liveness)
- [ ] Anti-affinity rules

### Rendimiento
- [ ] Gzip compression habilitada
- [ ] Proxy buffers optimizados
- [ ] Timeouts apropiados
- [ ] Connection pooling

### Monitoreo
- [ ] Metricas de Prometheus habilitadas
- [ ] Logs centralizados
- [ ] Alertas configuradas (cert expiration, 5xx)
- [ ] Dashboards de Grafana

---

## Limpieza

```bash
# Usar el script de limpieza
chmod +x cleanup.sh
./cleanup.sh
```

---

## Checklist Final

- [ ] Canary deployment implementado y probado con archivos YAML
- [ ] Peso del canary ajustado dinamicamente
- [ ] Rate limiting funciona (503 al exceder)
- [ ] IP whitelist configurado (403 para IPs no autorizadas)
- [ ] Ingress controller escalado a 3 replicas
- [ ] PDB creado con pdb-ingress-nginx.yaml
- [ ] Metricas verificadas

---

**Felicitaciones!** Has completado el modulo de Ingress.

**Anterior:** [Lab 02: TLS Avanzado](../lab-02-ingress-tls-avanzado/)
**Inicio:** [Volver al README del modulo](../README.md)
