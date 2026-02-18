# Ejemplo 02: PodDisruptionBudget (PDB) Examples

## 🎯 Objetivo
Ejemplos de PodDisruptionBudgets para proteger aplicaciones durante mantenimiento.

## 📝 Descripción
PDBs que garantizan alta disponibilidad durante:
- Draining de nodos
- Upgrades de cluster
- Scaling down de nodos
- Mantenimiento planificado

## 🚀 Uso

```bash
# Aplicar PDBs
kubectl apply -f pdb-examples.yaml

# Verificar PDBs
kubectl get pdb

# Describir un PDB
kubectl describe pdb frontend-pdb

# Ver qué aplicaciones protege
kubectl get pods -l app=frontend
```

## 📊 Ejemplos incluidos

### 1. PDB por mínimo disponible
```yaml
minAvailable: 2  # Siempre 2 pods mínimo
```

### 2. PDB por máximo unavailable
```yaml
maxUnavailable: 1  # Máximo 1 pod down a la vez
```

### 3. PDB con porcentaje
```yaml
maxUnavailable: 25%  # 25% de pods puede estar down
```

## 🧪 Testing de PDB

```bash
# Intentar drenar nodo con PDB activo
kubectl drain <node-name> --ignore-daemonsets

# Ver si PDB previene evicción
kubectl get events | grep -i evict

# Escalar deployment y ver PDB ajustarse
kubectl scale deployment frontend --replicas=10
kubectl get pdb frontend-pdb
```

## ⚠️ Consideraciones

- PDB solo afecta **evictions voluntarias** (drain, scale down)
- NO protege de fallos de nodo (crashes)
- Debe coordinarse con número de réplicas
- Uso en producción: SIEMPRE con aplicaciones críticas

[Volver a ejemplos](../README.md)
