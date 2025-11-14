# Lab 04: Complete Cluster Troubleshooting - CKA Simulation

**⚠️ ADVERTENCIA**: Este lab simula fallos críticos del cluster. **SOLO para entornos de prueba**.

## Prerrequisitos Críticos

- Cluster de prueba (NO producción)
- Backup de etcd reciente
- Acceso completo a control plane y workers
- Snapshots del cluster (recomendado)

## Archivos

- `README.md` - Instrucciones y escenarios completos
- `pre-flight-check.sh` - Verificar prerrequisitos
- `create-backup.sh` - Backup completo antes de empezar
- `cleanup.sh` - Limpieza y recuperación

## Antes de Empezar

```bash
# 1. Verificar prerrequisitos
chmod +x pre-flight-check.sh
./pre-flight-check.sh

# 2. Crear backup
chmod +x create-backup.sh
./create-backup.sh

# 3. Iniciar lab (leer README.md)
```

## Estructura del Lab

El lab tiene 5 escenarios complejos que simulan el examen CKA:
1. Multi-Component Failure (25 pts)
2. Security Breach (20 pts)
3. Performance Issues (20 pts)
4. StatefulSet Recovery (15 pts)
5. Disaster Recovery (20 pts)

**Passing score**: 66/100

## Tiempo

- **Total**: 120 minutos
- **Por escenario**: 20-30 minutos

## Recuperación de Emergencia

Si algo sale mal, usa `cleanup.sh` para restaurar el cluster.
