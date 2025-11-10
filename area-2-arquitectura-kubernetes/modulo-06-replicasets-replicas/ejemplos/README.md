# 📚 Ejemplos de ReplicaSets

Esta carpeta contiene ejemplos prácticos organizados por categoría para el **Módulo 06: ReplicaSets y Gestión de Réplicas**.

---

## 📁 Estructura de Carpetas

```
ejemplos/
├── 01-basico/                    # Fundamentos de ReplicaSets
├── 02-auto-recuperacion/         # Self-healing y resiliencia
├── 03-escalado/                  # Gestión de réplicas
├── 04-ownership/                 # Owner references y adopción
├── 05-limitaciones/              # Problemas de ReplicaSets
└── README.md                     # ← Estás aquí
```

---

## 🎯 Categorías de Ejemplos

### **01-basico/** - Fundamentos

Ejemplos básicos para entender la estructura de ReplicaSets.

| Archivo | Réplicas | Conceptos | Nivel |
|---------|----------|-----------|-------|
| `replicaset-simple.yaml` | 3 | Estructura básica, selector, template | Básico |
| `replicaset-multi-container.yaml` | 2 | Multi-container, patrón sidecar, volúmenes | Intermedio |

**Comandos rápidos**:
```bash
# Aplicar todos los ejemplos básicos
kubectl apply -f 01-basico/

# Ver ReplicaSets creados
kubectl get rs

# Ver Pods con labels
kubectl get pods --show-labels

# Limpiar
kubectl delete -f 01-basico/
```

---

### **02-auto-recuperacion/** - Self-Healing

Demostración de auto-recuperación automática.

| Archivo | Réplicas | Demuestra | Uso |
|---------|----------|-----------|-----|
| `replicaset-auto-heal.yaml` | 3 | Auto-recovery, resiliencia | Testing |

**Demo paso a paso**:
```bash
# 1. Crear ReplicaSet
kubectl apply -f 02-auto-recuperacion/replicaset-auto-heal.yaml

# 2. Ver Pods (en una terminal)
kubectl get pods -l app=auto-heal --watch

# 3. En OTRA terminal, eliminar un Pod
POD=$(kubectl get pods -l app=auto-heal -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD

# 4. Observar cómo se crea automáticamente un nuevo Pod
```

---

### **03-escalado/** - Gestión de Réplicas

Ejemplos de escalado horizontal.

| Archivo | Réplicas Iniciales | Para | Conceptos |
|---------|-------------------|------|-----------|
| `replicaset-load-test.yaml` | 3 | Pruebas de carga | Escalado, anti-affinity |

**Demo de escalado**:
```bash
# 1. Crear ReplicaSet
kubectl apply -f 03-escalado/replicaset-load-test.yaml

# 2. Escalar a 10 réplicas
kubectl scale rs nginx-load --replicas=10

# 3. Ver distribución de Pods
kubectl get pods -l app=load-test -o wide

# 4. Reducir a 2 réplicas
kubectl scale rs nginx-load --replicas=2

# 5. Ver qué Pods se eliminan
kubectl get pods -l app=load-test --watch
```

---

### **04-ownership/** - Owner References

⚠️ **Ejemplos avanzados** - Demuestran comportamiento de adopción.

| Archivo | Descripción | ⚠️ Nivel Riesgo |
|---------|-------------|----------------|
| `pods-huerfanos.yaml` | 3 Pods manuales con labels | Bajo |
| `replicaset-adoption.yaml` | ReplicaSet que adopta Pods | **Alto** |

**Demo de adopción** (cuidado):
```bash
# 1. Crear Pods huérfanos
kubectl apply -f 04-ownership/pods-huerfanos.yaml

# 2. Ver Pods (sin owner)
kubectl get pods --show-labels
kubectl get pod pod-huerfano-1 -o yaml | grep -A 5 ownerReferences
# Output: (vacío - sin owner)

# 3. Crear ReplicaSet que adoptará los Pods
kubectl apply -f 04-ownership/replicaset-adoption.yaml

# 4. Ver owner references AHORA
kubectl get pod pod-huerfano-1 -o yaml | grep -A 5 ownerReferences
# Output: kind: ReplicaSet, name: adoption-rs

# 5. Ver versiones de nginx INCONSISTENTES
kubectl get pods -o custom-columns=\
NAME:.metadata.name,\
IMAGE:.spec.containers[0].image,\
OWNER:.metadata.ownerReferences[0].name

# Limpiar
kubectl delete -f 04-ownership/
```

**⚠️ Lección importante**: 
- No crear Pods manualmente con labels que pueda usar un ReplicaSet
- Siempre usar labels únicos y específicos

---

### **05-limitaciones/** - Problemas de ReplicaSets

Demuestra por qué necesitas Deployments en lugar de ReplicaSets.

| Archivo | Problema | Solución |
|---------|----------|----------|
| `replicaset-no-update.yaml` | No actualiza Pods existentes | Usar Deployments |

**Demo de limitación**:
```bash
# 1. Crear ReplicaSet con nginx:1.20-alpine
kubectl apply -f 05-limitaciones/replicaset-no-update.yaml

# 2. Ver versión actual
kubectl get pods -l app=no-update -o jsonpath='{.items[*].spec.containers[0].image}'
# Output: nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine

# 3. EDITAR replicaset-no-update.yaml
# Cambiar: image: nginx:1.21-alpine

# 4. Aplicar cambios
kubectl apply -f 05-limitaciones/replicaset-no-update.yaml
# ReplicaSet/no-update-rs configured

# 5. Ver versión (NO CAMBIÓ)
kubectl get pods -l app=no-update -o jsonpath='{.items[*].spec.containers[0].image}'
# Output: nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine ← ❌ Sin cambios

# 6. Forzar actualización (manual)
kubectl delete pod $(kubectl get pods -l app=no-update -o jsonpath='{.items[0].metadata.name}')

# 7. Ver versión del nuevo Pod
kubectl get pods -l app=no-update -o jsonpath='{.items[*].spec.containers[0].image}'
# Output: nginx:1.20-alpine nginx:1.20-alpine nginx:1.21-alpine ← ✅ Solo el nuevo

# Limpiar
kubectl delete -f 05-limitaciones/
```

**Conclusión**: ReplicaSets no soportan rolling updates → Usa Deployments

---

## 🧪 Comandos Útiles por Categoría

### **Inspección**
```bash
# Listar ReplicaSets
kubectl get rs
kubectl get rs -o wide

# Ver detalles
kubectl describe rs <nombre-rs>

# Ver Pods de un ReplicaSet
kubectl get pods -l app=<label-value>

# Ver owner references
kubectl get pod <pod-name> -o yaml | grep -A 10 ownerReferences
```

### **Escalado**
```bash
# Escalar imperativo
kubectl scale rs <nombre-rs> --replicas=5

# Escalar declarativo
# 1. Editar manifiesto: replicas: 5
# 2. kubectl apply -f archivo.yaml

# Auto-escalar (requiere metrics-server)
kubectl autoscale rs <nombre-rs> --min=2 --max=10 --cpu-percent=80
```

### **Debugging**
```bash
# Ver logs de todos los Pods
kubectl logs -l app=<label> --all-containers=true

# Seguir logs
kubectl logs -l app=<label> -f

# Ver eventos
kubectl get events --field-selector involvedObject.kind=ReplicaSet

# Ejecutar comando en Pod
kubectl exec -it <pod-name> -- sh
```

### **Limpieza**
```bash
# Eliminar ReplicaSet Y sus Pods
kubectl delete rs <nombre-rs>

# Eliminar ReplicaSet pero MANTENER Pods
kubectl delete rs <nombre-rs> --cascade=orphan

# Eliminar todos los ReplicaSets
kubectl delete rs --all
```

---

## 📊 Tabla Resumen de Todos los Ejemplos

| Categoría | Archivo | Réplicas | Nivel | Conceptos Clave |
|-----------|---------|----------|-------|-----------------|
| Básico | `replicaset-simple.yaml` | 3 | ⭐ | Estructura, selector, template |
| Básico | `replicaset-multi-container.yaml` | 2 | ⭐⭐ | Multi-container, sidecar |
| Auto-heal | `replicaset-auto-heal.yaml` | 3 | ⭐ | Self-healing, resiliencia |
| Escalado | `replicaset-load-test.yaml` | 3 | ⭐⭐ | Escalado, anti-affinity |
| Ownership | `pods-huerfanos.yaml` | - | ⭐⭐⭐ | Pods sin owner |
| Ownership | `replicaset-adoption.yaml` | 5 | ⭐⭐⭐ | Adopción, owner refs |
| Limitaciones | `replicaset-no-update.yaml` | 3 | ⭐⭐⭐ | Sin rolling updates |

**Leyenda**:
- ⭐ = Básico
- ⭐⭐ = Intermedio
- ⭐⭐⭐ = Avanzado

---

## 🎓 Progresión de Aprendizaje Recomendada

1. **Empezar con básicos**:
   ```bash
   kubectl apply -f 01-basico/replicaset-simple.yaml
   ```

2. **Probar auto-recuperación**:
   ```bash
   kubectl apply -f 02-auto-recuperacion/replicaset-auto-heal.yaml
   # Eliminar un Pod y ver cómo se recupera
   ```

3. **Experimentar con escalado**:
   ```bash
   kubectl apply -f 03-escalado/replicaset-load-test.yaml
   kubectl scale rs nginx-load --replicas=10
   ```

4. **Entender ownership** (avanzado):
   ```bash
   kubectl apply -f 04-ownership/pods-huerfanos.yaml
   kubectl apply -f 04-ownership/replicaset-adoption.yaml
   ```

5. **Comprender limitaciones**:
   ```bash
   kubectl apply -f 05-limitaciones/replicaset-no-update.yaml
   # Intentar actualizar la imagen
   ```

---

## 🔗 Referencias

- [Documentación principal del módulo](../README.md)
- [Laboratorio 01: Creación de ReplicaSets](../laboratorios/lab-01-crear-replicasets.md)
- [Laboratorio 02: Auto-Recuperación](../laboratorios/lab-02-auto-recuperacion.md)
- [Laboratorio 03: Ownership](../laboratorios/lab-03-ownership-limitaciones.md)

---

## ⚠️ Notas Importantes

1. **Limpieza**: Siempre eliminar recursos después de experimentar
   ```bash
   kubectl delete rs --all
   ```

2. **Labels únicos**: No usar labels genéricos como `app: test` en producción

3. **Preferir Deployments**: En producción, siempre usa Deployments en lugar de ReplicaSets directos

4. **Ownership**: Ten cuidado con Pods huérfanos que puedan ser adoptados

---

**Última actualización**: Noviembre 2025  
**Versión**: 1.0
