# 🔄 Laboratorios - ReplicaSets y Réplicas

Este módulo contiene laboratorios prácticos para dominar ReplicaSets y gestión de réplicas en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: Crear ReplicaSets](./lab-01-crear-replicasets/)
**Duración:** 45-60 minutos | **Dificultad:** ⭐⭐☆☆☆

Creación y configuración básica de ReplicaSets.

**Objetivos:**
- Crear ReplicaSets desde YAML
- Configurar número de réplicas
- Entender selectors y labels
- Verificar el estado del ReplicaSet

---

### [Lab 02: Auto-recuperación](./lab-02-auto-recuperacion/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

Comprobación de la capacidad de auto-recuperación de ReplicaSets.

**Objetivos:**
- Eliminar pods manualmente
- Observar la recreación automática
- Analizar eventos y logs
- Comprender el reconciliation loop

---

### [Lab 03: Ownership y Limitaciones](./lab-03-ownership-limitaciones/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

Exploración del ownership de pods y limitaciones de ReplicaSets.

**Objetivos:**
- Entender la relación owner-dependent
- Explorar limitaciones de ReplicaSets
- Comparar con Deployments
- Best practices

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (Creación básica)
2. **Nivel Intermedio** → Lab 02 (Auto-recuperación)
3. **Nivel Avanzado** → Lab 03 (Ownership)

**Tiempo total estimado:** 3-3.5 horas

## 📚 Conceptos Clave

### ReplicaSet
- Garantiza un número específico de réplicas de pod
- Usa selectors para identificar pods
- Auto-recuperación ante fallos
- Base para Deployments

### Diferencias con Deployments
- ReplicaSets: Gestión de réplicas
- Deployments: ReplicaSets + estrategias de actualización

## ⚠️ Antes de Comenzar

```bash
# Verificar cluster
kubectl cluster-info

# Verificar namespace
kubectl get ns default

# Limpiar recursos previos
kubectl delete rs --all
```

## 🧹 Limpieza

Cada laboratorio incluye un script `cleanup.sh`:
```bash
cd lab-XX-nombre
./cleanup.sh
```
