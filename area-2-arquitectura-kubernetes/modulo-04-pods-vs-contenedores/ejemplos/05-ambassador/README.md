# 🔗 Patrones Multi-Contenedor: Ambassador

Ejemplos prácticos del patrón **Ambassador Container** en Kubernetes.

## 📖 ¿Qué es un Ambassador?

Un **ambassador** es un contenedor que actúa como proxy/intermediario entre el contenedor principal y servicios externos. La aplicación conecta a `localhost` pensando que es el servicio real, pero el ambassador maneja routing, pooling, balancing, etc.

## 📁 Ejemplos Disponibles

### 01. Ambassador: Database Connection Pooling
**Archivo:** `01-ambassador-db-pool.yaml`

Demuestra connection pooling a PostgreSQL usando PgBouncer.

**Arquitectura:**
- **Main:** App (conecta a localhost:5432)
- **Ambassador:** PgBouncer (connection pooling)
- **External:** PostgreSQL server

**Uso:**
```bash
# Aplicar
kubectl apply -f 01-ambassador-db-pool.yaml

# Ver logs de PgBouncer
kubectl logs app-with-pooling -c db-ambassador

# Ver logs de la app
kubectl logs app-with-pooling -c app

# Cleanup
kubectl delete pod app-with-pooling
kubectl delete configmap pgbouncer-config
```

**Qué aprendes:**
- ✅ Connection pooling transparente
- ✅ Configuración de PgBouncer
- ✅ Reducción de overhead de conexiones
- ✅ App no necesita implementar pooling

**Nota:** Requiere un PostgreSQL service. Ver comentarios en el YAML para crear uno de prueba.

---

### 02. Ambassador: Load Balancing con HAProxy
**Archivo:** `02-ambassador-loadbalancer.yaml`

Demuestra load balancing entre múltiples backends con HAProxy.

**Arquitectura:**
- **Main:** App (conecta a localhost:5432)
- **Ambassador:** HAProxy (load balancer)
- **External:** 3 réplicas de PostgreSQL

**Uso:**
```bash
# Aplicar
kubectl apply -f 02-ambassador-loadbalancer.yaml

# Port forward para ver stats
kubectl port-forward pod/app-with-lb 8404:8404

# Ver stats de HAProxy en navegador
# http://localhost:8404/stats

# Ver logs de load balancing
kubectl logs app-with-lb -c haproxy-ambassador

# Ver consultas de la app
kubectl logs app-with-lb -c app

# Cleanup
kubectl delete pod app-with-lb
kubectl delete configmap haproxy-config
kubectl delete service app-lb-svc
```

**Qué aprendes:**
- ✅ Round-robin load balancing
- ✅ Health checking automático
- ✅ Circuit breaking (evita backends down)
- ✅ Estadísticas en tiempo real
- ✅ Configuración de HAProxy

**Nota:** Ver comentarios en el YAML para crear réplicas de PostgreSQL con StatefulSet.

---

### 03. Ambassador: SSL/TLS Termination
**Archivo:** `03-ambassador-ssl.yaml`

Demuestra cómo el ambassador maneja encryption/decryption.

**Arquitectura:**
- **Main:** App HTTP simple (puerto 8080)
- **Ambassador:** Nginx (SSL termination en puerto 443)
- **External:** Clientes HTTPS

**Uso:**
```bash
# Aplicar
kubectl apply -f 03-ambassador-ssl.yaml

# Port forward para HTTPS
kubectl port-forward pod/app-with-ssl 8443:443

# Acceder vía HTTPS (self-signed cert)
curl -k https://localhost:8443

# Ver logs de Nginx
kubectl logs app-with-ssl -c ssl-ambassador

# Ver health endpoint
curl -k https://localhost:8443/health

# Cleanup
kubectl delete pod app-with-ssl
kubectl delete configmap nginx-ssl-config
kubectl delete secret tls-cert
kubectl delete service app-ssl-svc
```

**Qué aprendes:**
- ✅ SSL/TLS termination
- ✅ App usa HTTP simple
- ✅ Centralización de certificados
- ✅ Security headers
- ✅ HTTP → HTTPS redirect

**Nota:** Usa certificado self-signed para demo. En producción usar cert-manager o similar.

---

## 🎯 Cuándo Usar Ambassador

| Situación | ¿Ambassador? | Razón |
|-----------|--------------|-------|
| Connection pooling | ✅ Sí | Reduce overhead |
| Load balancing | ✅ Sí | Distribuye carga |
| SSL termination | ✅ Sí | Simplifica app |
| Circuit breaking | ✅ Sí | Resiliencia automática |
| Service mesh light | ✅ Sí | Alternativa a Istio |
| Conexión directa simple | ❌ No | Overhead innecesario |
| Service mesh completo | ❌ No | Usar Istio/Linkerd |

## 🔄 Diferencias vs Sidecar

| Aspecto | Ambassador | Sidecar |
|---------|------------|---------|
| **Propósito** | 🔀 Proxy hacia externos | 🔧 Extender funcionalidad |
| **Interacción** | 🌐 Network (localhost) | 📁 Volumes compartidos |
| **Ejemplos** | Load balancing, SSL | Logging, monitoring |

## 📊 Comparación de Tecnologías

| Uso | Tecnología | Ventajas |
|-----|------------|----------|
| **Connection pooling** | PgBouncer | Ligero, específico para PostgreSQL |
| **Load balancing** | HAProxy | Rápido, stats detallados |
| **SSL termination** | Nginx | Flexible, bien documentado |
| **Service mesh** | Envoy | Feature-rich, usado por Istio |

## 📚 Recursos Adicionales

- [HAProxy Documentation](http://www.haproxy.org/)
- [PgBouncer](https://www.pgbouncer.org/)
- [Nginx SSL Termination](https://nginx.org/en/docs/http/configuring_https_servers.html)

## 🔗 Ver También

- [../03-multi-container/](../03-multi-container/) - Sidecar pattern
- [../04-init-containers/](../04-init-containers/) - Init Container pattern
- [../../README.md](../../README.md) - Documentación principal
