# SETUP - Lab 04: Complete Cluster Troubleshooting - CKA Simulation

**⚠️ ADVERTENCIA**: Este lab simula fallos criticos del cluster. **SOLO para entornos de prueba**.

## Requisitos Previos

- Cluster de prueba (NO produccion)
- Backup de etcd reciente
- Acceso completo a control plane y workers
- Snapshots del cluster (recomendado)

## Requisitos Minikube

> **Importante:** Este laboratorio requiere configuracion especial en Minikube.

### Addons necesarios

```bash
# Verificar addons activos
minikube addons list

# Habilitar metrics-server (para Escenario 3: Performance)
minikube addons enable metrics-server
```

> **Minikube:** Para Network Policies (Escenario 2), necesitas CNI compatible:
> ```bash
> minikube start --cni=calico
> ```

## Verificacion del Entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar acceso admin
kubectl auth can-i '*' '*' --all-namespaces

# Ejecutar pre-flight check
chmod +x pre-flight-check.sh
./pre-flight-check.sh

# Crear backup antes de empezar
chmod +x create-backup.sh
./create-backup.sh

# Verificar archivos YAML del laboratorio
ls *.yaml
```

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `scenario-02-rbac-role.yaml` | Role pod-reader con permisos limitados |
| `scenario-02-rbac-rolebinding.yaml` | RoleBinding para ServiceAccount |
| `scenario-02-netpol-deny-all.yaml` | NetworkPolicy deny-all en namespace production |
| `scenario-02-netpol-allow-frontend.yaml` | NetworkPolicy permite trafico frontend a backend |
| `scenario-02-netpol-allow-dns.yaml` | NetworkPolicy permite egress DNS |
| `scenario-02-secure-pod.yaml` | Pod con SecurityContext hardened |
| `scenario-03-resourcequota.yaml` | ResourceQuota para namespace production |
| `scenario-03-limitrange.yaml` | LimitRange con defaults de CPU y memoria |
| `scenario-03-priorityclasses.yaml` | PriorityClasses high-priority y low-priority |
| `pre-flight-check.sh` | Script de verificacion de prerrequisitos |
| `create-backup.sh` | Script de backup completo antes de empezar |
| `cleanup.sh` | Script de limpieza y recuperacion |

## Estructura del Lab

5 escenarios complejos que simulan el examen CKA:

| Escenario | Puntos | Descripcion |
|-----------|--------|-------------|
| 1. Multi-Component Failure | 25 | API Server + nodes + DNS + pods |
| 2. Security Breach | 20 | RBAC + Network Policies + SecurityContext |
| 3. Performance Degradation | 20 | ResourceQuotas + LimitRanges + PriorityClasses |
| 4. StatefulSet Recovery | 15 | PVC + volume mount issues |
| 5. Disaster Recovery | 20 | etcd backup/restore completo |

**Passing score**: 66/100 | **Tiempo total**: 120 minutos
