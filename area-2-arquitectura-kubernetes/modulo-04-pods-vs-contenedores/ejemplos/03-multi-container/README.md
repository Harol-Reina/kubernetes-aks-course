# 🎨 Patrones Multi-Contenedor: Sidecar

Ejemplos prácticos del patrón **Sidecar Container** en Kubernetes.

## 📖 ¿Qué es un Sidecar?

Un **sidecar** es un contenedor auxiliar que extiende o mejora el contenedor principal sin modificar su código. Corre simultáneamente con la aplicación principal, compartiendo recursos del Pod (network, volumes).

## 📁 Ejemplos Disponibles

### 01. Sidecar: Logging
**Archivo:** `01-sidecar-logging.yaml`

Demuestra cómo un sidecar procesa logs de Nginx usando Fluent Bit.

**Arquitectura:**
- **Main:** Nginx (genera logs)
- **Sidecar:** Fluent Bit (procesa y envía logs)
- **Shared:** emptyDir volume

**Uso:**
```bash
# Aplicar
kubectl apply -f 01-sidecar-logging.yaml

# Ver logs del sidecar
kubectl logs web-with-logging -c log-processor

# Generar tráfico para ver logs
kubectl exec web-with-logging -c web-app -- curl localhost

# Cleanup
kubectl delete pod web-with-logging
kubectl delete configmap fluent-config
kubectl delete service web-logging-svc
```

**Qué aprendes:**
- ✅ Compartir volúmenes entre contenedores
- ✅ Procesamiento de logs sin modificar la app
- ✅ Configuración de Fluent Bit con ConfigMap

---

### 02. Sidecar: Monitoring
**Archivo:** `02-sidecar-monitoring.yaml`

Demuestra cómo un sidecar exporta métricas de Nginx para Prometheus.

**Arquitectura:**
- **Main:** Nginx (genera métricas)
- **Sidecar:** Prometheus exporter (expone métricas)
- **Shared:** Network namespace (localhost)

**Uso:**
```bash
# Aplicar
kubectl apply -f 02-sidecar-monitoring.yaml

# Port forward para ver métricas
kubectl port-forward pod/app-with-monitoring 9113:9113

# Ver métricas Prometheus
curl localhost:9113/metrics

# Cleanup
kubectl delete pod app-with-monitoring
kubectl delete configmap nginx-monitoring-config
kubectl delete service app-monitoring-svc
```

**Qué aprendes:**
- ✅ Comunicación localhost entre contenedores
- ✅ Exportar métricas sin modificar la app
- ✅ Configuración de Prometheus exporter

---

### 03. Sidecar: Service Mesh (Envoy)
**Archivo:** `03-sidecar-service-mesh.yaml`

Demuestra cómo un sidecar proxy maneja todo el tráfico de red.

**Arquitectura:**
- **Main:** App HTTP simple
- **Sidecar:** Envoy proxy (maneja networking)
- **Flow:** External → Envoy → App

**Uso:**
```bash
# Aplicar
kubectl apply -f 03-sidecar-service-mesh.yaml

# Port forward para acceder
kubectl port-forward pod/app-with-proxy 8080:10000

# Acceder a la app (vía Envoy)
curl localhost:8080

# Ver admin interface de Envoy
kubectl port-forward pod/app-with-proxy 9901:9901
curl localhost:9901/stats

# Cleanup
kubectl delete pod app-with-proxy
kubectl delete configmap envoy-config
kubectl delete service service-mesh-svc
```

**Qué aprendes:**
- ✅ Proxy transparente con Envoy
- ✅ Traffic routing y observability
- ✅ Fundamentos de service mesh

---

## 🎯 Cuándo Usar Sidecar

| Situación | ¿Sidecar? | Razón |
|-----------|-----------|-------|
| Procesar logs | ✅ Sí | Acceso a filesystem compartido |
| Exportar métricas | ✅ Sí | Sin modificar código |
| Service mesh proxy | ✅ Sí | Intercepta tráfico transparentemente |
| Sincronizar configs | ✅ Sí | Update sin reiniciar app |
| Lógica de negocio | ❌ No | Incluir en main container |

## 📚 Recursos Adicionales

- [Kubernetes Patterns: Sidecar](https://kubernetes.io/blog/2015/06/the-distributed-system-toolkit-patterns/)
- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [Envoy Proxy](https://www.envoyproxy.io/)

## 🔗 Ver También

- [../04-init-containers/](../04-init-containers/) - Init Container pattern
- [../05-ambassador/](../05-ambassador/) - Ambassador pattern
- [../../README.md](../../README.md) - Documentación principal
