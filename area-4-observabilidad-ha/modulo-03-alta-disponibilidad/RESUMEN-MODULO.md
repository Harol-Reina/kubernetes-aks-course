# 📚 RESUMEN - Módulo 03 (Área 4): Alta Disponibilidad

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre la **alta disponibilidad (HA)** en Kubernetes — cómo diseñar aplicaciones y clusters que continúen funcionando cuando componentes individuales fallan. Aprenderás anti-affinity, topology spread, PDBs, y patrones de distribución multi-zona.

**Duración**: 6 horas (teoría + labs)
**Nivel**: Intermedio-Avanzado
**Prerequisitos**: Deployments, Services, Nodes, Scheduler

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Entender qué significa disponibilidad (99.9%, 99.99%)
- ✅ Conocer los puntos únicos de fallo (SPOF)
- ✅ Diferenciar entre HA a nivel de Pod, Node y Zona
- ✅ Entender el principio "design for failure"

### Técnico
- ✅ Configurar Pod Anti-Affinity para distribución entre nodos
- ✅ Usar topologySpreadConstraints para balance
- ✅ Crear PodDisruptionBudgets para mantenimiento seguro
- ✅ Diseñar deployments multi-zona en AKS

---

## 🗺️ Estructura de Aprendizaje

### Niveles de Disponibilidad

```
99%    = 3.65 días de downtime/año     (inaceptable en producción)
99.9%  = 8.76 horas de downtime/año    (mínimo para producción)
99.95% = 4.38 horas de downtime/año    (estándar empresarial)
99.99% = 52.6 minutos de downtime/año  (alta disponibilidad)
```

### Estrategias de HA

```
┌────────────────────────────────────────────────────┐
│  Nivel 1: Réplicas                                  │
│  [Pod1] [Pod2] [Pod3] en el mismo nodo              │
│  ✅ Tolerante a fallos de Pod                       │
│  ❌ Si el nodo falla, todo cae                      │
├────────────────────────────────────────────────────┤
│  Nivel 2: Anti-Affinity                             │
│  Node1:[Pod1]  Node2:[Pod2]  Node3:[Pod3]           │
│  ✅ Tolerante a fallos de nodo                      │
│  ❌ Si la zona falla, todo cae                      │
├────────────────────────────────────────────────────┤
│  Nivel 3: Multi-Zona                                │
│  Zone1:[Pod1]  Zone2:[Pod2]  Zone3:[Pod3]           │
│  ✅ Tolerante a fallos de zona (datacenter)         │
│  ✅ Máxima disponibilidad                           │
└────────────────────────────────────────────────────┘
```

---

## 🔧 Comandos Esenciales

```bash
# Ver distribución de Pods por nodo
kubectl get pods -o wide -n <namespace>

# Ver zonas de los nodos
kubectl get nodes -L topology.kubernetes.io/zone

# Ver PDBs
kubectl get pdb -n <namespace>

# Describir un PDB
kubectl describe pdb <name> -n <namespace>

# Simular drain de nodo
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --dry-run=client

# Ver eventos de scheduling
kubectl get events --field-selector reason=FailedScheduling
```

---

## 📝 Cheat Sheet: YAML Snippets

### Pod Anti-Affinity (Preferida)

```yaml
spec:
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values: [mi-app]
              topologyKey: kubernetes.io/hostname
```

### Topology Spread Constraints

```yaml
spec:
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: mi-app
```

### PodDisruptionBudget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: mi-app-pdb
spec:
  minAvailable: 2       # o usar maxUnavailable: 1
  selector:
    matchLabels:
      app: mi-app
```

---

## ❗ Problemas Comunes

### 1. Pods Pending por anti-affinity estricta
**Causa**: No hay nodos suficientes para cumplir `requiredDuringScheduling`.
**Solución**: Usar `preferredDuringScheduling` o agregar nodos.

### 2. PDB bloquea el drain del nodo
**Causa**: minAvailable es igual al número de réplicas (no permite disruptions).
**Solución**: Asegurar que `replicas - minAvailable >= 1`.

### 3. Pods concentrados en un solo nodo a pesar del spread
**Causa**: topologySpreadConstraints usa maxSkew muy alto.
**Solución**: Reducir maxSkew a 1.

---

## ✅ Checklist

- [ ] Entiendo los niveles de disponibilidad (99.9%, 99.99%)
- [ ] Sé configurar Pod Anti-Affinity
- [ ] Puedo usar topologySpreadConstraints
- [ ] Sé crear PodDisruptionBudgets
- [ ] Entiendo la distribución multi-zona en AKS

---

## 📝 Preguntas de Repaso

### 1. ¿Cuál es la diferencia entre anti-affinity preferida y requerida?

<details><summary>Ver respuesta</summary>
**Preferida** (preferred): El scheduler INTENTA distribuir los Pods en nodos diferentes, pero si no puede, los coloca juntos. Nunca causa Pods Pending.
**Requerida** (required): El scheduler DEBE colocar los Pods en nodos diferentes. Si no hay nodos suficientes, los Pods quedan en Pending.
</details>

### 2. ¿Por qué es importante el PDB durante un upgrade de AKS?

<details><summary>Ver respuesta</summary>
Durante un upgrade, AKS drena los nodos uno por uno (mueve los Pods a otros nodos). Sin PDB, podría mover todos los Pods de tu aplicación simultáneamente, causando downtime. El PDB garantiza que siempre queden al menos N réplicas corriendo.
</details>

---

## 🎓 Certificaciones

- **CKA**: Anti-affinity, PDBs, node maintenance (~10%)
- **AKS**: Multi-zona, availability zones, node surge upgrade

---

## 🔗 Siguiente Paso

Continúa con el **Módulo 04: Troubleshooting Avanzado** para aprender a diagnosticar problemas complejos.
