# Ejemplos de Deployments

Esta carpeta contiene ejemplos prácticos organizados por categoría para el módulo de Deployments y Rolling Updates.

## 📋 Índice de Ejemplos

### [01-basico/](01-basico/) - Ejemplos Básicos
Introducción a Deployments con configuraciones fundamentales.

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`deployment-simple.yaml`](01-basico/deployment-simple.yaml) | Deployment básico con 3 réplicas nginx | Estructura básica, labels, selectors |
| [`deployment-multi-container.yaml`](01-basico/deployment-multi-container.yaml) | Sidecar pattern con nginx + log-aggregator | Multi-container Pods, volúmenes compartidos |

**Tiempo estimado**: 15 minutos  
**Nivel**: Principiante

---

### [02-rolling-updates/](02-rolling-updates/) - Rolling Updates
Control del proceso de actualización gradual.

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`deployment-rolling-params.yaml`](02-rolling-updates/deployment-rolling-params.yaml) | Control con maxSurge y maxUnavailable | Parámetros de rolling update |
| [`deployment-update-demo.yaml`](02-rolling-updates/deployment-update-demo.yaml) | Demostración paso a paso de actualización | Proceso completo de update |

**Tiempo estimado**: 20 minutos  
**Nivel**: Intermedio

---

### [03-estrategias/](03-estrategias/) - Estrategias de Despliegue
Comparación entre RollingUpdate y Recreate.

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`deployment-rolling-update.yaml`](03-estrategias/deployment-rolling-update.yaml) | Estrategia RollingUpdate con alta disponibilidad | Zero downtime, maxUnavailable: 0 |
| [`deployment-recreate.yaml`](03-estrategias/deployment-recreate.yaml) | Estrategia Recreate con downtime | Recreate, escenarios de uso |

**Tiempo estimado**: 15 minutos  
**Nivel**: Intermedio

---

### [04-rollback/](04-rollback/) - Rollback y Versionado
Gestión de versiones y recuperación ante errores.

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`deployment-revision-history.yaml`](04-rollback/deployment-revision-history.yaml) | Control de historial con revisionHistoryLimit | Gestión de versiones |
| [`deployment-rollback-demo.yaml`](04-rollback/deployment-rollback-demo.yaml) | Escenario completo de rollback | Recuperación de errores |

**Tiempo estimado**: 25 minutos  
**Nivel**: Intermedio

---

### [05-change-cause/](05-change-cause/) - Anotaciones Change-Cause
Best practices para tracking de cambios.

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`deployment-annotated.yaml`](05-change-cause/deployment-annotated.yaml) | Uso de kubernetes.io/change-cause | Historial descriptivo, tracking |

**Tiempo estimado**: 10 minutos  
**Nivel**: Intermedio

---

### [06-pause-resume/](06-pause-resume/) - Pause y Resume
Control avanzado de rollouts para múltiples cambios.

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`deployment-multiple-changes.yaml`](06-pause-resume/deployment-multiple-changes.yaml) | Múltiples cambios en un solo rollout | Pause/resume workflow |

**Tiempo estimado**: 20 minutos  
**Nivel**: Avanzado

---

### [07-produccion/](07-produccion/) - Configuración de Producción
Best practices completas para entornos productivos.

| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| [`deployment-production-ready.yaml`](07-produccion/deployment-production-ready.yaml) | Configuración completa production-ready | Security, HA, monitoring, probes |

**Tiempo estimado**: 30 minutos  
**Nivel**: Avanzado

---

## 🚀 Quick Start

### Aplicar un ejemplo

```bash
# Navegar a la categoría deseada
cd 01-basico/

# Aplicar el ejemplo
kubectl apply -f deployment-simple.yaml

# Verificar el Deployment
kubectl get deployment deployment-simple

# Ver los Pods creados
kubectl get pods -l app=deployment-simple

# Ver detalles
kubectl describe deployment deployment-simple
```

### Limpiar recursos

```bash
# Eliminar un Deployment específico
kubectl delete -f deployment-simple.yaml

# O por nombre
kubectl delete deployment deployment-simple

# Verificar limpieza
kubectl get deployments
kubectl get pods
```

---

## 📚 Ruta de Aprendizaje Recomendada

### Nivel 1: Fundamentos (40 min)
1. `01-basico/deployment-simple.yaml` - Estructura básica
2. `01-basico/deployment-multi-container.yaml` - Multi-container
3. `03-estrategias/deployment-recreate.yaml` - Estrategia Recreate

### Nivel 2: Updates y Rollouts (60 min)
4. `02-rolling-updates/deployment-rolling-params.yaml` - Parámetros
5. `02-rolling-updates/deployment-update-demo.yaml` - Demo completa
6. `03-estrategias/deployment-rolling-update.yaml` - RollingUpdate HA

### Nivel 3: Gestión Avanzada (70 min)
7. `04-rollback/deployment-revision-history.yaml` - Historial
8. `04-rollback/deployment-rollback-demo.yaml` - Rollback completo
9. `05-change-cause/deployment-annotated.yaml` - Annotations
10. `06-pause-resume/deployment-multiple-changes.yaml` - Pause/Resume

### Nivel 4: Producción (30 min)
11. `07-produccion/deployment-production-ready.yaml` - Best practices

**Tiempo total**: ~3 horas

---

## 🛠️ Comandos Útiles

### Gestión de Deployments

```bash
# Ver todos los Deployments
kubectl get deployments

# Ver con labels
kubectl get deployments --show-labels

# Ver con wide output
kubectl get deployments -o wide

# Describir un Deployment
kubectl describe deployment <nombre>

# Ver YAML completo
kubectl get deployment <nombre> -o yaml

# Ver eventos
kubectl get events --sort-by='.lastTimestamp'
```

### Rolling Updates

```bash
# Actualizar imagen
kubectl set image deployment/<nombre> <container>=<nueva-imagen>

# Ver estado del rollout
kubectl rollout status deployment/<nombre>

# Ver historial
kubectl rollout history deployment/<nombre>

# Ver revisión específica
kubectl rollout history deployment/<nombre> --revision=<N>

# Pausar rollout
kubectl rollout pause deployment/<nombre>

# Reanudar rollout
kubectl rollout resume deployment/<nombre>
```

### Rollback

```bash
# Rollback a revisión anterior
kubectl rollout undo deployment/<nombre>

# Rollback a revisión específica
kubectl rollout undo deployment/<nombre> --to-revision=<N>

# Reiniciar rollout
kubectl rollout restart deployment/<nombre>
```

### Escalado

```bash
# Escalar manualmente
kubectl scale deployment/<nombre> --replicas=<N>

# Ver estado de scaling
kubectl get deployment <nombre> -w
```

### Debugging

```bash
# Ver logs de un Deployment (primeros Pods)
kubectl logs deployment/<nombre>

# Ver logs de todos los Pods
kubectl logs -l app=<label>

# Seguir logs en tiempo real
kubectl logs -f deployment/<nombre>

# Ejecutar comando en Pod
kubectl exec -it deployment/<nombre> -- sh
```

---

## 🎯 Conceptos Clave por Ejemplo

### Básico
- Estructura de un Deployment
- Labels y selectors
- Template de Pod
- Multi-container patterns

### Rolling Updates
- `maxSurge`: Pods extra durante update
- `maxUnavailable`: Pods que pueden estar down
- Proceso de rolling update
- Velocidad de actualización

### Estrategias
- **RollingUpdate**: Zero downtime (recomendado)
- **Recreate**: Downtime completo (casos específicos)
- Trade-offs entre estrategias

### Rollback
- `revisionHistoryLimit`: Cuántas versiones guardar
- Historial de revisiones
- Rollback automático y manual
- Gestión de versiones

### Change-Cause
- Annotation `kubernetes.io/change-cause`
- Alternativa a `--record` (deprecated)
- Historial descriptivo
- Best practices de tracking

### Pause/Resume
- Pausar rollouts
- Múltiples cambios en un rollout
- Control fino del proceso
- Ventanas de mantenimiento

### Producción
- Security context
- Resource limits
- Health checks (liveness, readiness, startup)
- High availability
- Pod anti-affinity
- Lifecycle hooks
- Monitoring annotations

---

## 📖 Referencias

- [README principal del módulo](../README.md)
- [Laboratorio 1: Crear Deployments](../laboratorios/lab-01-crear-deployments.md)
- [Laboratorio 2: Rolling Updates](../laboratorios/lab-02-rolling-updates.md)
- [Laboratorio 3: Rollback y Versiones](../laboratorios/lab-03-rollback-versiones.md)
- [Documentación oficial de Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [pabpereza.dev - Deployments](https://pabpereza.dev/docs/cursos/kubernetes/deployments_en_kubernetes_rolling_updates_y_gestion_de_aplicaciones)

---

## ⚠️ Notas Importantes

1. **Namespace**: Todos los ejemplos usan el namespace `default`. En producción, usa namespaces específicos.

2. **Imágenes**: Los ejemplos usan imágenes públicas de nginx. En producción, usa tu registry privado.

3. **Resources**: Los límites de recursos están ajustados para clusters pequeños. Ajusta según tu entorno.

4. **Security**: El ejemplo de producción tiene security contexts. Aplícalos a TODOS los Deployments productivos.

5. **Clean up**: Recuerda limpiar recursos después de cada ejemplo para evitar conflictos.

---

## 🔍 Troubleshooting

### Problema: ImagePullBackOff
```bash
# Ver eventos del Deployment
kubectl describe deployment <nombre>

# Ver logs del Pod
kubectl describe pod <pod-name>

# Verificar imagen
kubectl get deployment <nombre> -o jsonpath='{.spec.template.spec.containers[*].image}'
```

### Problema: Pods no arrancan
```bash
# Ver estado de Pods
kubectl get pods -l app=<label>

# Ver logs
kubectl logs <pod-name>

# Ver eventos
kubectl get events --field-selector involvedObject.name=<pod-name>
```

### Problema: Rollout atascado
```bash
# Ver estado
kubectl rollout status deployment/<nombre>

# Ver detalles
kubectl describe deployment <nombre>

# Deshacer si necesario
kubectl rollout undo deployment/<nombre>
```

---

## 💡 Tips

1. **Usa --dry-run**: Prueba cambios sin aplicarlos
   ```bash
   kubectl apply -f deployment.yaml --dry-run=client
   ```

2. **Watch mode**: Observa cambios en tiempo real
   ```bash
   kubectl get pods -w
   ```

3. **Labels**: Usa labels consistentes para facilitar búsquedas
   ```bash
   kubectl get all -l app=mi-app
   ```

4. **Diff**: Ver cambios antes de aplicar
   ```bash
   kubectl diff -f deployment.yaml
   ```

5. **Explain**: Ver documentación de campos
   ```bash
   kubectl explain deployment.spec.strategy
   ```

---

**Siguiente paso**: Practica con los [Laboratorios](../laboratorios/) para aplicar estos conceptos en escenarios reales.
