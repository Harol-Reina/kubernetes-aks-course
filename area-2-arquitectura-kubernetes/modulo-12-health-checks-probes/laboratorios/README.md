# 🏥 Laboratorios - Health Checks y Probes

Este modulo contiene laboratorios practicos para dominar health checks y probes en Kubernetes.

## Indice de Laboratorios

| Lab | Nombre | Duracion | Nivel | Descripcion |
|-----|--------|----------|-------|-------------|
| [Lab 01](./lab-01-liveness-probes/) | Probes Basico | 60-75 min | Basico | Liveness (HTTP y exec), readiness con Deployment, probes combinadas |
| [Lab 02](./lab-02-readiness-probes/) | Startup y Produccion | 75-90 min | Intermedio | Startup probes, configuraciones avanzadas, patrones de produccion |
| [Lab 03](./lab-03-startup-probes/) | Troubleshooting | 45 min | Intermedio | Diagnosticar CrashLoopBackOff, label mismatch, timeouts, cascading failures |
| [Lab Resumen](./lab-resumen-probes/) | Resumen Practico | 15 min | Repaso | Un solo YAML con todos los conceptos: liveness, readiness, startup, troubleshooting |

---

## Ruta de Aprendizaje Recomendada

1. **Nivel Basico** → Lab 01 (Probes basico: liveness y readiness)
2. **Nivel Intermedio** → Lab 02 (Startup probes y produccion)
3. **Nivel Avanzado** → Lab 03 (Troubleshooting de probes)
4. **Repaso Rapido** → Lab Resumen (15 min, todos los conceptos)

**Tiempo total estimado:** ~3.5 horas (labs completos) + 15 min (resumen)

---

## Tipos de Probes

| Tipo | Proposito | Si falla... | Caso de uso |
|------|-----------|-------------|-------------|
| **Liveness** | Esta vivo el contenedor? | Kubelet reinicia el contenedor | Deadlocks, crashes |
| **Readiness** | Esta listo para trafico? | Removido de Endpoints del Service | Carga de cache, conexion BD |
| **Startup** | Termino de iniciar? | Cuenta como fallo de startup | Apps con inicio lento (>30s) |

## Metodos de Probe

### HTTP GET
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
```

### TCP Socket
```yaml
livenessProbe:
  tcpSocket:
    port: 8080
```

### Exec Command
```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
```

---

## Antes de Comenzar

```bash
# Verificar cluster
kubectl cluster-info

# Ver pods en ejecucion
kubectl get pods

# Monitorear eventos
kubectl get events --watch
```

## Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```
