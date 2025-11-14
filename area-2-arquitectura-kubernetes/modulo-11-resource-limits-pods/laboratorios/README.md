# 💾 Laboratorios - Resource Limits en Pods

Este módulo contiene laboratorios prácticos para dominar la gestión de recursos en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: Fundamentos](./lab-01-fundamentos/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

Fundamentos de requests y limits en Kubernetes.

**Objetivos:**
- Configurar CPU requests/limits
- Configurar memory requests/limits
- Entender la diferencia entre requests y limits
- Observar el comportamiento del scheduler

---

### [Lab 02: Troubleshooting](./lab-02-troubleshooting/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Diagnóstico de problemas relacionados con recursos.

**Objetivos:**
- Diagnosticar OOMKilled
- Identificar throttling de CPU
- Analizar QoS classes
- Resolver problemas de scheduling

---

### [Lab 03: Producción](./lab-03-produccion/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Best practices para ambientes de producción.

**Objetivos:**
- Definir requests/limits óptimos
- Implementar LimitRanges
- Configurar PodDisruptionBudgets
- Monitorear uso de recursos

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (Fundamentos)
2. **Nivel Intermedio** → Lab 02 (Troubleshooting)
3. **Nivel Avanzado** → Lab 03 (Producción)

**Tiempo total estimado:** 4-5 horas

## 📚 Conceptos Clave

### Requests vs Limits

**Requests:**
- Recursos garantizados
- Usados por el scheduler para ubicación
- Mínimo que el pod necesita

**Limits:**
- Recursos máximos permitidos
- Pod puede ser throttled o killed si excede
- Protege el node de sobrecarga

### QoS Classes

**Guaranteed:**
- Requests = Limits para todos los containers
- Máxima prioridad
- Último en ser evicted

**Burstable:**
- Requests < Limits
- Prioridad media
- Puede usar recursos extras si disponibles

**BestEffort:**
- Sin requests ni limits
- Mínima prioridad
- Primero en ser evicted

## ⚠️ Antes de Comenzar

```bash
# Habilitar metrics-server
minikube addons enable metrics-server

# Verificar métricas
kubectl top nodes
kubectl top pods

# Ver recursos disponibles
kubectl describe nodes
```

## 🧹 Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```

## 💡 Best Practices

- Siempre define requests en producción
- Limits opcionales según necesidad
- Monitorea uso real antes de definir
- Usa LimitRanges para defaults
