# Ejemplos de Ingress - Módulo 09

Este directorio contiene ejemplos prácticos de configuraciones de Ingress organizados por categorías y nivel de complejidad.

## Índice de Ejemplos

### 01. Básicos

| Archivo | Descripción | Nivel |
|---------|-------------|-------|
| [ingress-minimal.yaml](01-basico/ingress-minimal.yaml) | Ingress más simple, enruta todo a un Service | Básico |
| [deployment-apps-test.yaml](01-basico/deployment-apps-test.yaml) | Apps de prueba (app1, app2) para testing | Básico |

### 02. Routing

| Archivo | Descripción | Nivel |
|---------|-------------|-------|
| [ingress-path-based.yaml](02-routing/ingress-path-based.yaml) | Routing por ruta (/app1, /app2) | Básico |
| [ingress-host-based.yaml](02-routing/ingress-host-based.yaml) | Routing por hostname (app1.example.com) | Básico |
| [ingress-wildcard-host.yaml](02-routing/ingress-wildcard-host.yaml) | Hosts con wildcard (*.example.com) | Intermedio |

### 03. TLS/HTTPS

| Archivo | Descripción | Nivel |
|---------|-------------|-------|
| [ingress-tls-single-host.yaml](03-tls/ingress-tls-single-host.yaml) | HTTPS con certificado para un host | Intermedio |
| [ingress-tls-multi-host.yaml](03-tls/ingress-tls-multi-host.yaml) | HTTPS con certificado wildcard multi-host | Intermedio |

### 04. Anotaciones (Nginx)

| Archivo | Descripción | Nivel |
|---------|-------------|-------|
| [ingress-rewrite.yaml](04-annotations/ingress-rewrite.yaml) | URL rewriting con regex | Intermedio |
| [ingress-sticky-sessions.yaml](04-annotations/ingress-sticky-sessions.yaml) | Sesiones persistentes con cookies | Intermedio |
| [ingress-rate-limit.yaml](04-annotations/ingress-rate-limit.yaml) | Límite de peticiones por IP | Avanzado |
| [ingress-whitelist-ip.yaml](04-annotations/ingress-whitelist-ip.yaml) | Restricción de acceso por IP | Avanzado |

### 05. Avanzados

| Archivo | Descripción | Nivel |
|---------|-------------|-------|
| [ingress-canary.yaml](05-avanzado/ingress-canary.yaml) | Canary deployments (traffic splitting) | Avanzado |
| [ingress-auth-basic.yaml](05-avanzado/ingress-auth-basic.yaml) | Autenticación HTTP básica | Intermedio |
| [ingress-cors.yaml](05-avanzado/ingress-cors.yaml) | Configuración CORS completa | Intermedio |

### 06. Producción

| Archivo | Descripción | Nivel |
|---------|-------------|-------|
| [ingress-multi-app-production.yaml](06-produccion/ingress-multi-app-production.yaml) | Config completa multi-app para producción | Avanzado |

## Guía de Aprendizaje

### Ruta Recomendada

```
1. Básicos (30 min)
   └─ ingress-minimal.yaml
   └─ deployment-apps-test.yaml

2. Routing (45 min)
   └─ ingress-path-based.yaml
   └─ ingress-host-based.yaml
   └─ ingress-wildcard-host.yaml

3. TLS (30 min)
   └─ ingress-tls-single-host.yaml
   └─ ingress-tls-multi-host.yaml

4. Anotaciones (60 min)
   └─ ingress-rewrite.yaml
   └─ ingress-sticky-sessions.yaml
   └─ ingress-rate-limit.yaml
   └─ ingress-whitelist-ip.yaml

5. Avanzados (90 min)
   └─ ingress-canary.yaml
   └─ ingress-auth-basic.yaml
   └─ ingress-cors.yaml

6. Producción (60 min)
   └─ ingress-multi-app-production.yaml
```

## Casos de Uso

### Por Escenario

| Escenario | Ejemplo Recomendado |
|-----------|---------------------|
| Exponer una app simple | `ingress-minimal.yaml` |
| Múltiples apps bajo diferentes rutas | `ingress-path-based.yaml` |
| Múltiples apps con diferentes dominios | `ingress-host-based.yaml` |
| Agregar HTTPS a tu app | `ingress-tls-single-host.yaml` |
| Modificar URLs antes de enviar al backend | `ingress-rewrite.yaml` |
| Mantener sesiones en el mismo Pod | `ingress-sticky-sessions.yaml` |
| Proteger contra abuso/DDoS | `ingress-rate-limit.yaml` |
| Restringir acceso por IP | `ingress-whitelist-ip.yaml` |
| Testing de nueva versión en producción | `ingress-canary.yaml` |
| Proteger con usuario/password | `ingress-auth-basic.yaml` |
| Habilitar CORS para API | `ingress-cors.yaml` |
| Deploy completo de producción | `ingress-multi-app-production.yaml` |

## Prerequisitos

### Instalación de Ingress Controller

```bash
# Añadir repo Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Instalar nginx ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClass=nginx

# Verificar instalación
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
kubectl get ingressclass
```

## Comandos Útiles

### Gestión de Ingress

```bash
# Listar todos los Ingress
kubectl get ingress

# Ver detalles de un Ingress
kubectl describe ingress <nombre>

# Ver YAML de un Ingress
kubectl get ingress <nombre> -o yaml

# Editar Ingress
kubectl edit ingress <nombre>

# Eliminar Ingress
kubectl delete ingress <nombre>
```

### Troubleshooting

```bash
# Ver logs del ingress controller
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller -f

# Ver configuración nginx generada
kubectl exec -n ingress-nginx deployment/nginx-ingress-controller -- cat /etc/nginx/nginx.conf

# Verificar endpoints de un Service
kubectl get endpoints <service-name>

# Probar desde dentro del clúster
kubectl run curl-test --image=curlimages/curl -it --rm -- sh
```

### Testing

```bash
# Obtener IP del Ingress
INGRESS_IP=$(kubectl get svc -n ingress-nginx nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Para NodePort
NODE_PORT=$(kubectl get svc -n ingress-nginx nginx-ingress-controller -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')

# Probar con curl (especificando header Host)
curl -H "Host: app.example.com" http://$INGRESS_IP

# Configurar /etc/hosts (Linux/Mac)
echo "$INGRESS_IP app.example.com" | sudo tee -a /etc/hosts

# Probar con curl usando DNS
curl http://app.example.com
```

## Referencias

- [README Principal](../README.md)
- [Laboratorio 01: Fundamentos de Ingress](../laboratorios/lab-01-ingress-basico.md)
- [Laboratorio 02: TLS y Configuraciones Avanzadas](../laboratorios/lab-02-ingress-tls-avanzado.md)
- [Laboratorio 03: Ingress en Producción](../laboratorios/lab-03-ingress-produccion.md)
- [Nginx Ingress Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)
- [Kubernetes Ingress Docs](https://kubernetes.io/docs/concepts/services-networking/ingress/)
