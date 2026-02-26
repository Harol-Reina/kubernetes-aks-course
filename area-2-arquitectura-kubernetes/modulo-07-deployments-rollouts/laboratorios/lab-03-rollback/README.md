# Laboratorio 3: Rollback y Gestión de Versiones

## 📋 Información del Laboratorio

- **Duración estimada**: 60 minutos
- **Nivel**: Avanzado
- **Requisitos**: Laboratorios 1 y 2 completados
- **Namespace**: `lab-rollback`

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:

1. Gestionar historial de revisiones con `revisionHistoryLimit`
2. Visualizar y explorar versiones anteriores
3. Realizar rollback a versiones específicas
4. Detectar y recuperarse de despliegues fallidos
5. Usar `change-cause` annotations en archivos YAML
6. Implementar estrategias de rollback en producción
7. Gestionar todas las versiones de forma declarativa con archivos YAML

## 📚 Prerrequisitos

- Laboratorios 1 y 2 completados
- Conocimiento de rolling updates
- Cluster de Kubernetes funcional

---

## 💡 ¿Qué es un Rollback?

Un **rollback** es el proceso de revertir un Deployment a una versión anterior que funcionaba correctamente. Es una de las capacidades más importantes de Kubernetes para garantizar la disponibilidad de las aplicaciones.

### ¿Cómo funciona internamente?

```
              Deployment (version-history)
              ┌─────────────────────────┐
              │ spec.template           │
              │   image: nginx:1.23     │  ← Versión actual
              └────────────┬────────────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────┴──────┐ ┌────┴────┐ ┌───────┴──────┐
     │ ReplicaSet  │ │ RS (v4) │ │ RS (v5)      │
     │ (v3)        │ │ 0 Pods  │ │ 4 Pods ←     │  ← ACTIVO
     │ 0 Pods      │ │         │ │ (actual)     │
     └─────────────┘ └─────────┘ └──────────────┘
           │                            │
           │    kubectl rollout undo    │
           │        --to-revision=3     │
           │                            │
     ┌─────┴───────┐            ┌───────┴──────┐
     │ RS (v3)     │            │ RS (v5)      │
     │ 4 Pods ←    │  ACTIVO    │ 0 Pods       │
     │ (restaurado)│            │              │
     └─────────────┘            └──────────────┘
```

Cada vez que actualizas un Deployment, Kubernetes:

1. **Crea un nuevo ReplicaSet** con la configuración actualizada
2. **Escala el nuevo ReplicaSet** hacia arriba (nuevos Pods)
3. **Escala el viejo ReplicaSet** hacia abajo (a 0 Pods)
4. **Mantiene los ReplicaSets viejos** (según `revisionHistoryLimit`) para poder hacer rollback

Cuando haces rollback, Kubernetes simplemente **reactiva un ReplicaSet antiguo** escalándolo de vuelta, y reduce el actual a 0. No necesita reconstruir nada — los ReplicaSets ya existen.

### Conceptos clave

| Concepto | Descripción |
|----------|-------------|
| **Revisión** | Cada cambio al Deployment crea una nueva revisión numerada |
| **revisionHistoryLimit** | Cuántos ReplicaSets antiguos mantener (default: 10) |
| **change-cause** | Anotación que documenta el propósito de cada revisión |
| **progressDeadlineSeconds** | Tiempo máximo para que un rollout progrese antes de marcarlo como fallido |
| **kubectl rollout undo** | Comando para revertir a la versión anterior |
| **--to-revision=N** | Revertir a una revisión específica del historial |

### ¿Cuándo hacer rollback?

- La nueva versión tiene Pods en `ImagePullBackOff` (imagen rota)
- Los Pods entran en `CrashLoopBackOff` (aplicación falla al arrancar)
- El readinessProbe falla (la aplicación no responde correctamente)
- Se detectan errores en producción después del deploy
- Métricas de error rate aumentan después de un release

---

## 📁 Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las versiones están definidas como archivos YAML:

| Archivo | Ejercicio | Descripción |
|---------|-----------|-------------|
| `version-history-v1.yaml` | 1 | v1.0.0 - Release inicial nginx:1.19 |
| `version-history-v2.yaml` | 1 | v1.1.0 - Actualización a nginx:1.20 |
| `version-history-v3.yaml` | 1 | v1.2.0 - Actualización a nginx:1.21 |
| `version-history-v4.yaml` | 1 | v1.3.0 - Actualización a nginx:1.22 |
| `version-history-v5.yaml` | 1 | v2.0.0 - Major release nginx:1.23 |
| `version-history-v6.yaml` | 1 | v2.1.0 - Excede revisionHistoryLimit |
| `production-app-v1.yaml` | 3 | v1.0.0 - Release estable producción |
| `production-app-v2-broken.yaml` | 3 | v2.0.0 - Deploy con imagen ROTA |
| `auto-rollback-v1.yaml` | 4 | v1.0 - Versión saludable |
| `auto-rollback-v2-broken.yaml` | 4 | v2.0 - Deploy con imagen ROTA |
| `versioned-app-v1.yaml` | 5 | v1.0.0 - Initial release |
| `versioned-app-v2.yaml` | 5 | v1.1.0 - Feature update |
| `versioned-app-v3.yaml` | 5 | v1.1.1 - Hotfix (última buena) |
| `versioned-app-v4-broken.yaml` | 5 | v2.0.0 - Major release ROTO |
| `critical-service-v1.yaml` | Desafío | v3.2.1 - Servicio estable |
| `critical-service-v2-broken.yaml` | Desafío | v3.3.0 - Servicio ROTO |
| `safe-rollback.sh` | 5 | Script de rollback automático |

> **Nota**: Los archivos con sufijo `-broken` contienen imágenes inválidas que fallan intencionalmente para practicar el diagnóstico y rollback.

## 🔧 Preparación del Entorno

```bash
# Crear namespace
kubectl create namespace lab-rollback
kubectl config set-context --current --namespace=lab-rollback

# Verificar
kubectl get namespaces | grep lab-rollback
```

**Output esperado**:
```
lab-rollback   Active   5s
```

---

## Ejercicio 1: Historial de Revisiones (15 min)

### Paso 1.1: Revisar el manifiesto inicial

```bash
cat version-history-v1.yaml
```

Puntos clave:
- `revisionHistoryLimit: 5` → Kubernetes mantiene hasta 5 ReplicaSets antiguos
- `change-cause` en annotations → Documenta el propósito de cada revisión
- `maxUnavailable: 0` → Cero downtime durante updates

### Paso 1.2: Crear Deployment y construir historial de versiones

Aplica las 5 primeras versiones secuencialmente, esperando a que cada una complete:

```bash
# Versión 1: Release inicial (nginx 1.19)
kubectl apply -f version-history-v1.yaml
kubectl rollout status deployment version-history

# Versión 2: Actualización menor (nginx 1.20)
kubectl apply -f version-history-v2.yaml
kubectl rollout status deployment version-history

# Versión 3: Actualización menor (nginx 1.21)
kubectl apply -f version-history-v3.yaml
kubectl rollout status deployment version-history

# Versión 4: Actualización menor (nginx 1.22)
kubectl apply -f version-history-v4.yaml
kubectl rollout status deployment version-history

# Versión 5: Major release (nginx 1.23)
kubectl apply -f version-history-v5.yaml
kubectl rollout status deployment version-history
```

### Paso 1.3: Ver historial completo

```bash
kubectl rollout history deployment version-history
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         v1.0.0 - Release inicial con nginx 1.19
2         v1.1.0 - Actualización menor nginx 1.20
3         v1.2.0 - Actualización menor nginx 1.21
4         v1.3.0 - Actualización menor nginx 1.22
5         v2.0.0 - Major release nginx 1.23
```

### Paso 1.4: Ver detalles de revisión específica

```bash
# Ver detalles de revisión 3
kubectl rollout history deployment version-history --revision=3
```

**Output esperado**:
```
deployment.apps/version-history with revision #3
Pod Template:
  Labels:	app=version-history
	pod-template-hash=abc123
	version=v1.2.0
  Annotations:	kubernetes.io/change-cause: v1.2.0 - Actualización menor nginx 1.21
  Containers:
   nginx:
    Image:	nginx:1.21-alpine
    Port:	80/TCP
    Environment:
      APP_VERSION:	v1.2.0
    ...
```

### Paso 1.5: Ver ReplicaSets históricos

```bash
kubectl get replicaset -l app=version-history
```

**Output esperado**:
```
NAME                      DESIRED   CURRENT   READY   AGE
version-history-rev1      0         0         0       10m
version-history-rev2      0         0         0       8m
version-history-rev3      0         0         0       6m
version-history-rev4      0         0         0       4m
version-history-rev5      4         4         4       2m  <- Actual
```

**Explicación**:
- Cada revisión tiene su propio ReplicaSet
- Los viejos quedan en 0 réplicas (listos para rollback)
- Se mantienen según `revisionHistoryLimit: 5`

### Paso 1.6: Probar revisionHistoryLimit

Compara las diferencias entre v5 y v6:

```bash
diff version-history-v5.yaml version-history-v6.yaml
```

Aplica la versión 6:

```bash
kubectl apply -f version-history-v6.yaml
kubectl rollout status deployment version-history

# Ver ReplicaSets después de aplicar v6
kubectl get replicaset -l app=version-history
```

### ✅ Verificación

**Pregunta**: ¿Qué pasó con la revisión 1 (v1.0.0) al crear la revisión 6?

<details>
<summary>Respuesta</summary>
El ReplicaSet MÁS VIEJO (rev1) se eliminó automáticamente. Solo se mantienen los últimos 5. Ahora tienes rev2, rev3, rev4, rev5, rev6.
</details>

---

## Ejercicio 2: Rollback Básico (10 min)

### Paso 2.1: Ver versión actual

```bash
# Ver imagen actual
kubectl get deployment version-history -o jsonpath='{.spec.template.spec.containers[0].image}'
echo
```

**Output**: `nginx:alpine` (v2.1.0)

```bash
# Ver versión en variable de entorno
kubectl exec deployment/version-history -- env | grep APP_VERSION
```

**Output**: `APP_VERSION=v2.1.0`

### Paso 2.2: Rollback a versión anterior (undo)

```bash
# Rollback a la versión inmediatamente anterior
kubectl rollout undo deployment version-history
```

**Output**: `deployment.apps/version-history rolled back`

```bash
# Ver estado del rollback
kubectl rollout status deployment version-history
```

### Paso 2.3: Verificar rollback

```bash
# Ver imagen ahora
kubectl get deployment version-history -o jsonpath='{.spec.template.spec.containers[0].image}'
echo
```

**Output**: `nginx:1.23-alpine` (v2.0.0)

```bash
# Ver historial actualizado
kubectl rollout history deployment version-history
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
2         v1.1.0 - Actualización menor nginx 1.20
3         v1.2.0 - Actualización menor nginx 1.21
4         v1.3.0 - Actualización menor nginx 1.22
6         v2.1.0 - Latest nginx
7         v2.0.0 - Major release nginx 1.23  <- ¡Ahora es revision 7!
```

**Explicación**:
- Rollback NO elimina la revisión problemática
- Crea una NUEVA revisión (7) con el contenido de la anterior (5)
- La revisión 1 (v1.0.0) ya se había eliminado por `revisionHistoryLimit: 5`

### Paso 2.4: Rollback a revisión específica

```bash
# Ver historial
kubectl rollout history deployment version-history

# Rollback a revisión 3 (nginx 1.21, v1.2.0)
kubectl rollout undo deployment version-history --to-revision=3
```

**Output**: `deployment.apps/version-history rolled back`

```bash
# Verificar imagen
kubectl get deployment version-history -o jsonpath='{.spec.template.spec.containers[0].image}'
echo
```

**Output**: `nginx:1.21-alpine`

```bash
# Verificar variable de entorno
kubectl exec deployment/version-history -- env | grep APP_VERSION
```

**Output**: `APP_VERSION=v1.2.0`

### ✅ Verificación

**Pregunta**: ¿Cómo se numeran las revisiones después de rollback a --to-revision=3?

```bash
kubectl rollout history deployment version-history
```

<details>
<summary>Respuesta</summary>
La revisión 3 desaparece y se crea una nueva revisión (8) con su contenido:

```
REVISION  CHANGE-CAUSE
2         v1.1.0 - ...
4         v1.3.0 - ...
6         v2.1.0 - ...
7         v2.0.0 - ...
8         v1.2.0 - ...  <- contenido de ex-revision 3
```
</details>

---

## Ejercicio 3: Rollback de Deployment Fallido (15 min)

### Paso 3.1: Revisar y crear Deployment productivo

Revisa el manifiesto estable:

```bash
cat production-app-v1.yaml
```

Puntos clave:
- `revisionHistoryLimit: 10` → Amplio historial
- `livenessProbe` + `readinessProbe` → Detección de fallos
- `maxUnavailable: 0` → Protección total de los Pods existentes

```bash
kubectl apply -f production-app-v1.yaml
kubectl rollout status deployment production-app
```

### Paso 3.2: Revisar el manifiesto roto antes de aplicar

```bash
diff production-app-v1.yaml production-app-v2-broken.yaml
```

Observa el cambio clave: `image: nginx:broken-tag-12345` — esta imagen **no existe**.

### Paso 3.3: Desplegar versión con imagen ROTA

**Terminal 1** (monitoreo):
```bash
kubectl get pods -l app=production-app -w
```

**Terminal 2** (deploy roto):
```bash
kubectl apply -f production-app-v2-broken.yaml
```

**Observación en Terminal 1**:
```
production-app-old-abc   1/1     Running       0     2m
production-app-new-xyz   0/1     Pending       0     0s
production-app-new-xyz   0/1     ContainerCreating   0     0s
production-app-new-xyz   0/1     ErrImagePull        0     5s
production-app-new-xyz   0/1     ImagePullBackOff    0     20s
production-app-new-xyz   0/1     ErrImagePull        0     35s
production-app-new-xyz   0/1     ImagePullBackOff    0     50s
```

**Explicación**:
- El nuevo Pod NO puede arrancar (imagen no existe)
- Queda en estado `ImagePullBackOff`
- Los Pods viejos SIGUEN corriendo (maxUnavailable: 0)
- La aplicación sigue funcional

### Paso 3.4: Ver estado del Deployment

```bash
kubectl get deployment production-app
```

**Output**:
```
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
production-app   5/5     1            5           5m
```

**Explicación**:
- `READY: 5/5` → Los 5 Pods viejos siguen ready
- `UP-TO-DATE: 1` → 1 Pod nuevo creado (pero no ready)
- `AVAILABLE: 5` → Aplicación funcionando normalmente

```bash
kubectl rollout status deployment production-app
```

**Output**:
```
Waiting for deployment "production-app" rollout to finish: 1 out of 5 new replicas have been updated...
```

**Estado**: Rollout ATASCADO

### Paso 3.5: Ver detalles del error

```bash
# Ver eventos del Deployment
kubectl describe deployment production-app | tail -20

# Ver Pod con error
kubectl get pods -l app=production-app | grep -E "ImagePullBackOff|ErrImagePull"
```

### Paso 3.6: Rollback inmediato

```bash
# Rollback a versión anterior (la que funcionaba)
kubectl rollout undo deployment production-app
```

**Output**: `deployment.apps/production-app rolled back`

```bash
# Monitorear el rollback
kubectl rollout status deployment production-app
```

**Output**: `deployment "production-app" successfully rolled out`

```bash
# Verificar que todo está OK
kubectl get pods -l app=production-app
```

**Output esperado**:
```
NAME                          READY   STATUS    RESTARTS   AGE
production-app-old-abc        1/1     Running   0          8m
production-app-old-def        1/1     Running   0          8m
production-app-old-ghi        1/1     Running   0          8m
production-app-old-jkl        1/1     Running   0          8m
production-app-old-mno        1/1     Running   0          8m
```

Todos los Pods corriendo con imagen válida.

### ✅ Verificación

**Pregunta**: ¿Por qué la aplicación NO tuvo downtime durante el deploy fallido?

<details>
<summary>Respuesta</summary>
Por `maxUnavailable: 0`. Kubernetes NO elimina Pods viejos hasta que los nuevos estén Ready. Como los nuevos nunca llegaron a Ready, los viejos se mantuvieron intactos sirviendo tráfico.
</details>

---

## Ejercicio 4: Detectar Rollouts Fallidos con progressDeadlineSeconds (10 min)

### Paso 4.1: Revisar y crear Deployment con deadline

```bash
cat auto-rollback-v1.yaml
```

Punto clave: `progressDeadlineSeconds: 120` — si el rollout no progresa en 2 minutos, Kubernetes lo marca como **fallido**.

```bash
kubectl apply -f auto-rollback-v1.yaml
kubectl rollout status deployment auto-rollback
```

### Paso 4.2: Comparar con la versión rota

```bash
diff auto-rollback-v1.yaml auto-rollback-v2-broken.yaml
```

### Paso 4.3: Desplegar versión rota

```bash
kubectl apply -f auto-rollback-v2-broken.yaml
```

**Terminal 1**:
```bash
kubectl get pods -l app=auto-rollback -w
```

**Observación**: Pods nuevos quedan en `ImagePullBackOff`

### Paso 4.4: Esperar timeout

```bash
# Esperar ~2 minutos (progressDeadlineSeconds: 120)
kubectl rollout status deployment auto-rollback --timeout=3m
```

**Output después de timeout**:
```
error: deployment "auto-rollback" exceeded its progress deadline
```

```bash
# Ver condiciones del Deployment
kubectl get deployment auto-rollback -o jsonpath='{.status.conditions[?(@.type=="Progressing")]}' | jq
```

**Output esperado**:
```json
{
  "type": "Progressing",
  "status": "False",
  "reason": "ProgressDeadlineExceeded",
  "message": "ReplicaSet auto-rollback-xyz has timed out progressing."
}
```

**Explicación**:
- Kubernetes detecta que el rollout NO progresa
- Marca el Deployment como fallido
- **NO hace rollback automático** (debes hacerlo manual)

### Paso 4.5: Rollback manual

```bash
kubectl rollout undo deployment auto-rollback
kubectl rollout status deployment auto-rollback
```

**Output**: `deployment "auto-rollback" successfully rolled out`

### ✅ Verificación

**Pregunta**: ¿Kubernetes hace rollback automático cuando falla un deployment?

<details>
<summary>Respuesta</summary>
NO. Kubernetes solo DETIENE el rollout y marca el estado como fallido (`ProgressDeadlineExceeded`). El rollback debe hacerse MANUALMENTE con `kubectl rollout undo`. Para rollback automático necesitarías herramientas externas como Argo Rollouts o Flagger.
</details>

---

## Ejercicio 5: Workflow Completo de Versiones (10 min)

### Paso 5.1: Revisar los archivos versionados

Revisa la progresión de versiones:

```bash
# Ver diferencias entre cada versión
diff versioned-app-v1.yaml versioned-app-v2.yaml
diff versioned-app-v2.yaml versioned-app-v3.yaml
diff versioned-app-v3.yaml versioned-app-v4-broken.yaml
```

Observa cómo cada archivo incluye:
- Annotations de metadata (version, release date, ticket JIRA)
- Labels semánticos (app, version, tier)
- change-cause descriptivo con ticket reference

### Paso 5.2: Simular ciclo de releases

```bash
# Release v1.0.0 (initial)
kubectl apply -f versioned-app-v1.yaml
kubectl rollout status deployment versioned-app

# Release v1.1.0 (feature)
kubectl apply -f versioned-app-v2.yaml
kubectl rollout status deployment versioned-app

# Release v1.1.1 (hotfix)
kubectl apply -f versioned-app-v3.yaml
kubectl rollout status deployment versioned-app
```

### Paso 5.3: Ver historial completo

```bash
kubectl rollout history deployment versioned-app
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         v1.0.0 - Initial release (2025-01-15)
2         v1.1.0 - Feature: improved logging (PROD-1002)
3         v1.1.1 - Hotfix: memory leak (PROD-1003)
```

### Paso 5.4: Desplegar versión rota

```bash
kubectl apply -f versioned-app-v4-broken.yaml
```

### Paso 5.5: Detectar y hacer rollback

```bash
# Ver estado actual
kubectl get deployment versioned-app
kubectl get pods -l app=versioned-app

# Verificar historial
kubectl rollout history deployment versioned-app
```

**Output**:
```
REVISION  CHANGE-CAUSE
1         v1.0.0 - Initial release (2025-01-15)
2         v1.1.0 - Feature: improved logging (PROD-1002)
3         v1.1.1 - Hotfix: memory leak (PROD-1003)
4         v2.0.0 - MAJOR: API redesign (PROD-1004 - BROKEN)
```

```bash
# Rollback a última versión buena conocida (v1.1.1, revisión 3)
kubectl rollout undo deployment versioned-app --to-revision=3
```

### Paso 5.6: Verificar recuperación

```bash
# Verificar versión
kubectl exec deployment/versioned-app -- env | grep APP_VERSION
```

**Output**: `APP_VERSION=v1.1.1`

```bash
# Ver historial actualizado
kubectl rollout history deployment versioned-app
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         v1.0.0 - Initial release (2025-01-15)
2         v1.1.0 - Feature: improved logging (PROD-1002)
4         v2.0.0 - MAJOR: API redesign (PROD-1004 - BROKEN)
5         v1.1.1 - Hotfix: memory leak (PROD-1003)  <- Nueva revisión
```

### ✅ Verificación

**Ejercicio**: Usa el script de rollback automático incluido:

```bash
chmod +x safe-rollback.sh
./safe-rollback.sh versioned-app lab-rollback
```

<details>
<summary>¿Qué hace el script?</summary>

El script `safe-rollback.sh` verifica si hay Pods con errores en el Deployment. Si detecta problemas, ejecuta rollback automáticamente y actualiza el change-cause con la fecha del rollback de emergencia.

</details>

---

## 🎓 Desafío Final: Simulación de Incidente en Producción

### Escenario

Eres el SRE de turno. A las 3 AM recibes una alerta: el deployment `critical-service` tiene Pods fallando después de un release.

**Datos**:
- Deployment: `critical-service`
- Réplicas: 10
- Última versión buena: v3.2.1 (revision 1)
- Versión actual (broken): v3.3.0 (revision 2)
- SLA: 99.9% uptime

**Tareas**:
1. Crear el deployment estable
2. Desplegar la versión rota
3. Diagnosticar el problema
4. Realizar rollback
5. Verificar recuperación completa

<details>
<summary>Solución Completa</summary>

**Paso 1: Crear versión estable**

```bash
kubectl apply -f critical-service-v1.yaml
kubectl rollout status deployment critical-service
```

**Paso 2: Desplegar versión rota**

Revisa primero las diferencias:

```bash
diff critical-service-v1.yaml critical-service-v2-broken.yaml
```

Aplica la versión rota:

```bash
kubectl apply -f critical-service-v2-broken.yaml
```

**Paso 3: Diagnóstico (como SRE)**

```bash
# Ver estado general
kubectl get deployment critical-service
kubectl get pods -l app=critical-service

# Identificar Pods con problemas
kubectl get pods -l app=critical-service | grep -E "ImagePullBackOff|ErrImagePull|CrashLoopBackOff"

# Ver eventos
kubectl describe deployment critical-service | tail -30

# Verificar historial
kubectl rollout history deployment critical-service
```

**Paso 4: Rollback de emergencia**

```bash
# Rollback inmediato
kubectl rollout undo deployment critical-service

# Monitorear recuperación
kubectl rollout status deployment critical-service
```

**Paso 5: Verificación final**

```bash
# Verificar TODOS los Pods healthy
kubectl get pods -l app=critical-service

# Verificar imagen
kubectl get deployment critical-service -o jsonpath='{.spec.template.spec.containers[0].image}'
echo

# Verificar versión
kubectl exec deployment/critical-service -- env | grep APP_VERSION

# Confirmar en historial
kubectl rollout history deployment critical-service
```

**Output esperado**:
```
All Pods Running
Image: nginx:1.21-alpine
Version: v3.2.1
Availability: 10/10
```

</details>

---

## 🧹 Limpieza

Ejecuta el script de limpieza incluido:

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete deployment --all -n lab-rollback
kubectl delete namespace lab-rollback
kubectl config set-context --current --namespace=default
```

---

## 📝 Resumen

En este laboratorio aprendiste:

- **Rollback**: Revertir un Deployment a una versión anterior usando ReplicaSets históricos
- **Enfoque declarativo**: Todas las versiones gestionadas como archivos YAML versionados (v1, v2, v3...)
- **Historial de revisiones**: `revisionHistoryLimit` controla cuántas versiones guardar
- **Visualizar versiones**: `kubectl rollout history` muestra todas las revisiones
- **Rollback básico**: `kubectl rollout undo` vuelve a versión anterior
- **Rollback específico**: `--to-revision=N` va a versión exacta
- **Change-cause**: Anotaciones en YAML para tracking descriptivo
- **Detección de fallos**: `progressDeadlineSeconds` marca deployments atascados
- **Alta disponibilidad**: `maxUnavailable: 0` previene downtime durante fallos
- **diff entre versiones**: Comparar manifiestos YAML antes de aplicar cambios

---

## 🔗 Recursos Relacionados

- [Laboratorio 1: Crear Deployments](../lab-01-crear-deployments/)
- [Laboratorio 2: Rolling Updates](../lab-02-rolling-updates/)
- [Ejemplos de Rollback](../../ejemplos/04-rollback/)
- [README del módulo](../../README.md)

---

**¡Felicitaciones! 🎉**
Has completado todos los laboratorios del módulo de Deployments. Ahora dominas:
- Creación y gestión de Deployments
- Rolling updates y estrategias
- Rollback y recuperación de incidentes

**Siguiente paso**: Aplicar estos conocimientos en proyectos reales y explorar [HorizontalPodAutoscaler](../../modulo-08-autoscaling/) para escalado automático.
