# Laboratorio 02: Ingress con TLS y Configuraciones Avanzadas

**Duracion estimada:** 50-60 minutos
**Nivel:** Intermedio
**Prerequisitos:** Lab 01 completado, Ingress controller instalado

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **TLS Termination** | El Ingress Controller descifra el trafico HTTPS y envia HTTP plano al backend. Centraliza la gestion de certificados en un solo punto en lugar de configurar TLS en cada servicio |
| **Secret TLS** | Secret de tipo `kubernetes.io/tls` que almacena certificado (`tls.crt`) y clave privada (`tls.key`). Se referencia desde el Ingress para habilitar HTTPS |
| **Certificado Wildcard** | Certificado que cubre todos los subdominios de un dominio (*.example.com). Reduce la cantidad de certificados a gestionar cuando hay multiples subdominios |
| **SSL Redirect** | Redireccion automatica de HTTP a HTTPS (308 Permanent Redirect). Garantiza que todo el trafico sea cifrado sin depender del cliente |
| **URL Rewriting (Regex)** | Reescritura de paths usando expresiones regulares con grupos de captura. Permite exponer servicios bajo prefijos (/api/users -> /users en el backend) |
| **CORS** | Cross-Origin Resource Sharing. Headers HTTP que permiten a un frontend en un dominio hacer peticiones a una API en otro dominio. Sin CORS, los navegadores bloquean estas peticiones |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Parte | Descripcion |
|---------|-------|-------------|
| `ingress-tls-single.yaml` | 1 | Ingress con TLS para un solo host (app.example.com) con redireccion HTTP->HTTPS |
| `ingress-multi-host-tls.yaml` | 2 | Ingress multi-host con certificado wildcard (*.example.com) |
| `ingress-rewrite.yaml` | 3 | Ingress con URL rewriting usando expresiones regulares |
| `ingress-cors.yaml` | 3 | Ingress con CORS habilitado para peticiones cross-origin |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

**Nota:** Este lab reutiliza los backends del Lab 01 (`deployment-apps-test.yaml`). Asegurate de tenerlos desplegados.

---

## Requisitos Previos

- Lab 01 completado (apps de prueba desplegadas)
- Ingress Controller NGINX instalado
- openssl disponible en el sistema

### Verificacion del entorno

```bash
# Verificar Ingress Controller
kubectl get pods -n ingress-nginx

# Verificar backends del Lab 01
kubectl get deployments app1 app2
kubectl get svc servicio-app1 servicio-app2

# Verificar openssl
openssl version

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Parte 1: Certificados TLS (15 min)

### Paso 1.1: Generar certificado autofirmado

```bash
# Certificado para app.example.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=app.example.com/O=MyOrg"

# Verificar certificado
openssl x509 -in tls.crt -text -noout | grep -E "Subject:|Not"
```

### Paso 1.2: Crear Secret TLS

```bash
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Verificar Secret
kubectl get secret tls-secret
kubectl describe secret tls-secret
```

### Paso 1.3: Revisar y crear Ingress con TLS

Revisa el archivo `ingress-tls-single.yaml`:

```bash
cat ingress-tls-single.yaml
```

Puntos clave del manifiesto:
- **ssl-redirect**: redirige HTTP a HTTPS automaticamente
- **force-ssl-redirect**: fuerza HTTPS incluso detras de balanceador L4
- **tls.hosts**: lista de dominios cubiertos por el certificado
- **tls.secretName**: referencia al Secret con certificado y clave

```bash
kubectl apply -f ingress-tls-single.yaml
```

### Paso 1.4: Probar HTTPS

```bash
# Configurar /etc/hosts si no existe
echo "$NODE_IP app.example.com" | sudo tee -a /etc/hosts

# Probar con curl (ignorar certificado autofirmado)
curl -k https://app.example.com

# Verificar redireccion HTTP -> HTTPS
curl -I http://app.example.com
# Debe retornar: 308 Permanent Redirect

# Ver detalles del certificado
openssl s_client -connect app.example.com:443 -servername app.example.com < /dev/null 2>&1 | grep -E "subject=|issuer="
```

---

## Parte 2: Certificado Wildcard Multi-Host (15 min)

### Paso 2.1: Generar certificado wildcard

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout wildcard.key -out wildcard.crt \
  -subj "/CN=*.example.com/O=MyOrg" \
  -addext "subjectAltName=DNS:*.example.com,DNS:example.com"

kubectl create secret tls wildcard-tls \
  --cert=wildcard.crt \
  --key=wildcard.key
```

### Paso 2.2: Revisar y aplicar Ingress multi-host con TLS

Revisa el archivo `ingress-multi-host-tls.yaml`:

```bash
cat ingress-multi-host-tls.yaml
```

Puntos clave del manifiesto:
- **Un bloque TLS** con wildcard cubre app1, app2 y api
- **Un solo Secret** para todos los subdominios
- **Multiples reglas host** apuntando a diferentes backends

```bash
kubectl apply -f ingress-multi-host-tls.yaml
```

### Paso 2.3: Configurar y probar

```bash
# Anadir hosts
echo "$NODE_IP app1.example.com app2.example.com" | sudo tee -a /etc/hosts

# Probar
curl -k https://app1.example.com
curl -k https://app2.example.com
```

---

## Parte 3: Anotaciones Avanzadas (20 min)

### Paso 3.1: URL Rewriting

Revisa el archivo `ingress-rewrite.yaml`:

```bash
cat ingress-rewrite.yaml
```

Puntos clave del manifiesto:
- **rewrite-target con `$2`**: usa el segundo grupo de captura regex
- **use-regex**: habilita expresiones regulares en paths
- **Patron `/api(/|$)(.*)`**: captura todo despues de /api

```bash
kubectl apply -f ingress-rewrite.yaml

# Probar rewrite
curl http://api.example.com/api/users
# /api/users -> /users en el backend
```

### Paso 3.2: CORS

Revisa el archivo `ingress-cors.yaml`:

```bash
cat ingress-cors.yaml
```

Puntos clave del manifiesto:
- **enable-cors**: activa headers CORS en respuestas
- **cors-allow-origin**: origenes permitidos (`*` = todos)
- **cors-allow-methods**: metodos HTTP permitidos

```bash
kubectl apply -f ingress-cors.yaml

# Verificar headers CORS
curl -H "Origin: https://frontend.com" -I http://api.example.com
# Buscar: Access-Control-Allow-Origin
```

---

## Limpieza

```bash
# Usar el script de limpieza
chmod +x cleanup.sh
./cleanup.sh
```

---

## Checklist

- [ ] Certificados autofirmados generados
- [ ] Secrets TLS creados
- [ ] HTTPS funcionando con ingress-tls-single.yaml
- [ ] Certificado wildcard multi-host funciona
- [ ] URL rewriting probado con regex
- [ ] CORS configurado y verificado

---

## Proximos Pasos

1. **[Lab 03: Ingress en Produccion](../lab-03-ingress-produccion/)**
   - Canary deployments
   - Rate limiting y seguridad
   - Alta disponibilidad
   - Monitoreo

---

**Anterior:** [Lab 01: Ingress Basico](../lab-01-ingress-basico/)
