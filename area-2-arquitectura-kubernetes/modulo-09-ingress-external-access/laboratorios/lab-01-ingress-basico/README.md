# Laboratorio 01: Fundamentos de Ingress

**Duracion estimada:** 40-45 minutos
**Nivel:** Basico
**Objetivo:** Instalar un Ingress Controller, desplegar apps de prueba y configurar enrutamiento por path y por host

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Ingress Controller** | Componente que implementa las reglas Ingress. NGINX Ingress Controller es el mas popular. Se instala con Helm y crea un pod que escucha trafico HTTP/HTTPS y lo enruta a los backends |
| **Path-Based Routing** | Enrutamiento basado en la ruta URL. Permite que un solo punto de entrada dirija `/app1` a un servicio y `/app2` a otro. Usa `pathType: Prefix` para coincidir con subpaths |
| **Host-Based Routing** | Enrutamiento basado en el header `Host` HTTP (virtual hosting). Permite que `app1.example.com` y `app2.example.com` compartan la misma IP pero vayan a backends diferentes |
| **Rewrite Target** | Anotacion que reescribe el path antes de enviarlo al backend. Ej: `/app1/page` se convierte en `/page` para que el backend no necesite conocer el prefijo |
| **IngressClass** | Recurso que identifica que Ingress Controller procesa un Ingress. Permite tener multiples controllers en el mismo cluster |
| **ClusterIP como backend** | Los Services tipo ClusterIP sirven como backends internos para Ingress. El Ingress Controller se comunica con ellos dentro del cluster |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Parte | Descripcion |
|---------|-------|-------------|
| `deployment-apps-test.yaml` | 2 | Dos apps de prueba (app1, app2) con Deployments y Services ClusterIP |
| `ingress-path-based.yaml` | 3 | Ingress con enrutamiento por path: /app1 y /app2 a diferentes backends |
| `ingress-host-based.yaml` | 4 | Ingress con enrutamiento por host: app1.example.com y app2.example.com |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Cluster de Kubernetes funcional (minikube, kind, k3s o cloud)
- kubectl configurado
- Helm instalado

### Verificacion del entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar Helm
helm version

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Parte 1: Instalacion del Ingress Controller (10 min)

### Paso 1.1: Instalar Helm (si no esta instalado)

```bash
# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar instalacion
helm version
```

### Paso 1.2: Anadir repositorio de ingress-nginx

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### Paso 1.3: Instalar nginx ingress controller

```bash
# Para desarrollo (NodePort)
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClass=nginx
```

### Paso 1.4: Verificar instalacion

```bash
# Ver pods del ingress controller
kubectl get pods -n ingress-nginx

# Ver servicio (NodePort)
kubectl get svc -n ingress-nginx

# Ver IngressClass creada
kubectl get ingressclass

# Obtener NodePort
export NODE_PORT=$(kubectl get svc -n ingress-nginx nginx-ingress-controller -o jsonpath='{.spec.ports[0].nodePort}')
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "Ingress URL: http://$NODE_IP:$NODE_PORT"
```

**Verificacion**: Deberias ver el pod `nginx-ingress-controller-*` en estado `Running`.

---

## Parte 2: Crear Aplicaciones de Prueba (5 min)

### Paso 2.1: Revisar y aplicar deployments de ejemplo

Revisa el archivo `deployment-apps-test.yaml` antes de aplicarlo:

```bash
cat deployment-apps-test.yaml
```

Puntos clave del manifiesto:
- **2 Deployments**: app1 y app2, cada uno con 2 replicas
- **2 Services ClusterIP**: servicio-app1 y servicio-app2 (puerto 8080 -> 80)
- **Respuestas identificables**: cada app genera HTML con su nombre y hostname del Pod

```bash
kubectl apply -f deployment-apps-test.yaml
```

### Paso 2.2: Verificar recursos creados

```bash
kubectl get deployments,services,pods
kubectl get endpoints servicio-app1 servicio-app2
```

**Salida esperada:**
```
NAME                   READY   UP-TO-DATE   AVAILABLE
deployment.apps/app1   2/2     2            2
deployment.apps/app2   2/2     2            2

NAME                    TYPE        CLUSTER-IP      PORT(S)
service/servicio-app1   ClusterIP   10.96.x.x       8080/TCP
service/servicio-app2   ClusterIP   10.96.x.x       8080/TCP
```

---

## Parte 3: Ingress Path-Based Routing (10 min)

### Paso 3.1: Revisar y crear Ingress por path

Revisa el archivo `ingress-path-based.yaml`:

```bash
cat ingress-path-based.yaml
```

Puntos clave del manifiesto:
- **rewrite-target**: `/` reescribe el path (elimina /app1, /app2)
- **pathType Prefix**: coincide con /app1 y todos sus subpaths
- **Dos reglas de path**: /app1 -> servicio-app1, /app2 -> servicio-app2

```bash
kubectl apply -f ingress-path-based.yaml
```

### Paso 3.2: Verificar Ingress

```bash
kubectl get ingress path-based-ingress
kubectl describe ingress path-based-ingress
```

### Paso 3.3: Probar con curl

```bash
# Probar app1
curl http://$NODE_IP:$NODE_PORT/app1
# Deberia mostrar: APP 1

# Probar app2
curl http://$NODE_IP:$NODE_PORT/app2
# Deberia mostrar: APP 2

# Probar path inexistente (404)
curl http://$NODE_IP:$NODE_PORT/app3
```

---

## Parte 4: Ingress Host-Based Routing (10 min)

### Paso 4.1: Revisar y crear Ingress por host

Revisa el archivo `ingress-host-based.yaml`:

```bash
cat ingress-host-based.yaml
```

Puntos clave del manifiesto:
- **Dos reglas de host**: app1.example.com y app2.example.com
- **Virtual hosting**: multiples dominios en la misma IP/puerto
- **Cada host** tiene su propio conjunto de paths y backend

```bash
kubectl apply -f ingress-host-based.yaml
```

### Paso 4.2: Configurar DNS local

```bash
# Linux/Mac: Editar /etc/hosts
echo "$NODE_IP app1.example.com app2.example.com" | sudo tee -a /etc/hosts

# Verificar
cat /etc/hosts | grep example.com
```

### Paso 4.3: Probar con curl

```bash
# Probar con header Host (sin DNS)
curl -H "Host: app1.example.com" http://$NODE_IP:$NODE_PORT

# Probar con DNS configurado
curl http://app1.example.com
curl http://app2.example.com

# Probar en navegador
firefox http://app1.example.com
```

---

## Parte 5: Troubleshooting (5-10 min)

### Escenario 1: Ingress retorna 404

```bash
# Diagnosticar
kubectl describe ingress <nombre>
kubectl get svc <service-name>
kubectl get endpoints <service-name>

# Verificar logs del controller
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller --tail=50
```

### Escenario 2: Service sin endpoints

```bash
# Verificar
kubectl get endpoints servicio-app1

# Si esta vacio, verificar:
kubectl get pods -l app=app1
kubectl describe service servicio-app1
```

---

## Limpieza

```bash
# Usar el script de limpieza
chmod +x cleanup.sh
./cleanup.sh
```

---

## Checklist de Completado

- [ ] Ingress controller instalado y funcionando
- [ ] Apps de prueba desplegadas con archivos YAML
- [ ] Path-based routing funciona (/app1, /app2)
- [ ] Host-based routing funciona (app1.example.com)
- [ ] DNS local configurado correctamente
- [ ] Troubleshooting practicado

---

## Proximos Pasos

1. **[Lab 02: Ingress con TLS y Configuraciones Avanzadas](../lab-02-ingress-tls-avanzado/)**
   - Certificados TLS autofirmados
   - Wildcard multi-host
   - URL rewriting con regex
   - CORS
