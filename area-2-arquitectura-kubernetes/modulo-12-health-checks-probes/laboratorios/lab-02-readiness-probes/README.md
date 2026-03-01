# Laboratorio 02: Startup Probes y Casos Avanzados

**Duracion estimada:** 60 minutos
**Nivel:** Intermedio
**Objetivo:** Configurar Startup Probes para aplicaciones de arranque lento, combinar las 3 probes correctamente, e implementar configuraciones optimizadas para produccion

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Startup Probe** | Probe que protege durante el arranque inicial. Liveness y Readiness se activan solo despues de que Startup tenga exito |
| **App de arranque lento** | Patron comun en bases de datos y apps Java/Spring. Sin Startup Probe, la Liveness reinicia prematuramente |
| **PostgreSQL con 3 probes** | Caso real: Startup espera inicializacion, Liveness verifica proceso, Readiness verifica queries SQL |
| **Endpoints dedicados** | Best practice: crear rutas /startup, /health, /ready para cada probe en lugar de reutilizar la misma |
| **Optimizacion HA** | Liveness tolerante (evita cascading failures) + Readiness sensible (control rapido de trafico) |
| **Cascading failures** | Probes agresivas bajo carga causan reinicios en cadena que saturan el cluster |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `slow-app-without-startup.yaml` | 1 | Pod de arranque lento SIN Startup Probe (demuestra el problema) |
| `slow-app-with-startup.yaml` | 1 | Mismo Pod CON Startup Probe (solucion correcta) |
| `postgres-production.yaml` | 2 | Pod PostgreSQL con Startup + Liveness + Readiness |
| `nodejs-production.yaml` | 3 | Deployment Node.js 3 replicas con endpoints dedicados por probe |
| `critical-app.yaml` | 4 | Deployment 5 replicas con probes optimizadas para alta disponibilidad |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Cluster de Kubernetes funcional (Minikube recomendado)
- `kubectl` configurado
- Lab 01 completado (conceptos de Liveness y Readiness)

> Este laboratorio funciona con la configuracion por defecto de Minikube.

> **Nota:** El Ejercicio 3 (Node.js) requiere acceso a internet para `npm install`.

### Verificacion del entorno

```bash
kubectl cluster-info
kubectl get nodes

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Parte 1: Startup Probe para Aplicaciones Lentas

### Escenario

Tienes una aplicacion que tarda 2-3 minutos en arrancar. Sin Startup Probe, la Liveness Probe la reiniciaria prematuramente.

### Paso 1.1: Sin Startup Probe (Problematico)

Revisa el archivo `slow-app-without-startup.yaml`:

```bash
cat slow-app-without-startup.yaml
```

Puntos clave:
- La app tarda 120 segundos en arrancar (simula Java/Spring)
- `initialDelaySeconds: 30` no es suficiente
- Tolerancia total: 30s + (10s x 3) = 60s, pero la app necesita 120s

```bash
kubectl apply -f slow-app-without-startup.yaml
kubectl get pods slow-app-without-startup -w
```

**Problema**: El Pod se reinicia porque tarda mas de 60s (initialDelay 30s + 30s de tolerancia)

### Paso 1.2: Con Startup Probe (Solucion)

Revisa el archivo `slow-app-with-startup.yaml`:

```bash
cat slow-app-with-startup.yaml
```

Puntos clave:
- **Startup Probe**: `failureThreshold: 30` x `periodSeconds: 10` = 300s (5 min) de arranque
- La Liveness Probe se activa SOLO despues de que Startup tenga exito
- El archivo `/tmp/started` se crea despues de los 120s de arranque

```bash
kubectl apply -f slow-app-with-startup.yaml
kubectl get pods slow-app-with-startup -w
kubectl describe pod slow-app-with-startup
```

**Resultado**: El Pod arranca correctamente sin reinicios.

---

## Parte 2: PostgreSQL con Probes Completas

### Paso 2.1: Desplegar PostgreSQL

Revisa el archivo `postgres-production.yaml`:

```bash
cat postgres-production.yaml
```

Puntos clave:
- **Startup**: `pg_isready` verifica que PostgreSQL acepte conexiones (hasta 5 min)
- **Liveness**: `pg_isready` periodico para detectar proceso caido
- **Readiness**: `pg_isready` + query SQL `SELECT 1` para verificar que la DB funcione

```bash
kubectl apply -f postgres-production.yaml
kubectl logs postgres-production -f
```

### Paso 2.2: Verificar Secuencia de Probes

```bash
# Ver orden de ejecucion de probes
kubectl describe pod postgres-production | grep -A5 "Startup\|Liveness\|Readiness"
```

Observa que:
1. **Startup** se ejecuta primero
2. **Liveness** y **Readiness** se activan despues de Startup exitosa

---

## Parte 3: Aplicacion Node.js con Endpoints Dedicados

### Paso 3.1: Deployment Completo

Revisa el archivo `nodejs-production.yaml`:

```bash
cat nodejs-production.yaml
```

Puntos clave:
- 3 replicas de una API Express con endpoints dedicados
- `/startup` retorna 503 durante los primeros 15s, luego 200
- `/health` siempre retorna 200 (el proceso esta vivo)
- `/ready` retorna 200 solo cuando la app esta completamente lista
- Startup Probe permite hasta 60s para npm install + carga inicial

```bash
kubectl apply -f nodejs-production.yaml
kubectl get pods -l app=nodejs -w
```

### Paso 3.2: Probar Endpoints

```bash
# Port forward
kubectl port-forward deployment/nodejs-production 3000:3000

# En otra terminal
curl http://localhost:3000/startup
curl http://localhost:3000/health
curl http://localhost:3000/ready
```

---

## Parte 4: Optimizacion de Probes para Produccion

### Escenario: Alta Disponibilidad

Revisa el archivo `critical-app.yaml`:

```bash
cat critical-app.yaml
```

Puntos clave:
- **Startup** rapido: app ligera, 20s max (2s x 10)
- **Liveness** muy tolerante: 150s (30s x 5) para evitar cascading failures
- **Readiness** sensible: 10s (5s x 2) para control rapido de trafico

```bash
kubectl apply -f critical-app.yaml
kubectl get pods -l app=critical -w
```

### Analisis de Configuracion

| Probe | periodSeconds | failureThreshold | Tiempo Total | Estrategia |
|-------|---------------|------------------|--------------|------------|
| Startup | 2s | 10 | 20s | Rapido (app ligera) |
| Liveness | 30s | 5 | 150s | Muy tolerante |
| Readiness | 5s | 2 | 10s | Sensible |

---

## Parte 5: Casos Reales de Troubleshooting

### Caso 1: Cascading Failures bajo Carga

**Sintoma**: Pods se reinician en cadena bajo alta carga

**Causa**: Liveness Probe muy agresiva

```yaml
# MAL: Muy agresiva
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 2
  failureThreshold: 1    # Un fallo = reinicio
  timeoutSeconds: 1      # 1s de timeout
```

**Solucion**:

```yaml
# BIEN: Tolerante
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 10
  failureThreshold: 5    # Tolerante
  timeoutSeconds: 5      # Timeout generoso
```

---

## Limpieza

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete pod slow-app-without-startup slow-app-with-startup postgres-production
kubectl delete deployment nodejs-production critical-app
```

---

## Resumen

Al completar este laboratorio has practicado:

- Startup Probes para evitar reinicios prematuros en apps de arranque lento
- Las 3 probes combinadas en un caso real (PostgreSQL)
- Endpoints dedicados para cada tipo de probe (Node.js)
- Optimizacion de probes para alta disponibilidad
- Liveness tolerante para evitar cascading failures

## Siguiente Laboratorio

**[Laboratorio 03 - Troubleshooting de Health Checks](../lab-03-startup-probes/)**
