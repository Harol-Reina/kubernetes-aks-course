# 💾 Laboratorios - Resource Limits en Pods

Este modulo contiene laboratorios practicos para dominar la gestion de recursos en Kubernetes.

Todos los laboratorios utilizan un enfoque **100% declarativo** con archivos YAML separados y documentados.

## 📋 Indice de Laboratorios

### [Lab 01: Fundamentos](./lab-01-fundamentos/)
**Duracion:** 35-40 minutos | **Nivel:** Basico

Fundamentos de requests, limits y QoS classes en Kubernetes.

**Archivos YAML:** 5 | **Ejercicios:** 7

**Objetivos:**
- Configurar CPU y memory requests/limits
- Entender la diferencia entre requests y limits
- Identificar las 3 QoS Classes (Guaranteed, Burstable, BestEffort)
- Usar `kubectl top` para monitorear recursos
- Calcular recursos en Pods multi-container e init containers

---

### [Lab 02: Troubleshooting](./lab-02-troubleshooting/)
**Duracion:** 45-50 minutos | **Nivel:** Intermedio

Diagnostico y resolucion de problemas comunes de recursos.

**Archivos YAML:** 8 | **Ejercicios:** 6

**Objetivos:**
- Diagnosticar OOMKilled (Exit Code 137)
- Identificar CPU throttling y su impacto
- Troubleshoot ephemeral storage eviction
- Resolver problemas de Pods Pending
- Usar metricas para troubleshooting

---

### [Lab 03: Produccion](./lab-03-produccion/)
**Duracion:** 50-60 minutos | **Nivel:** Avanzado

Best practices, autoscaling y monitoreo para produccion.

**Archivos YAML:** 12 | **Ejercicios:** 6

**Objetivos:**
- Implementar Tier system (Guaranteed, Burstable, BestEffort por criticidad)
- Configurar VPA (Vertical Pod Autoscaler)
- Configurar HPA (Horizontal Pod Autoscaler)
- Usar Pod-level resources (K8s 1.34+)
- Monitorear con Prometheus

---

### [Lab Resumen: Resources](./lab-resumen-resources/)
**Duracion:** 15 minutos | **Nivel:** Repaso integral

Laboratorio consolidado que despliega todos los conceptos en un solo YAML.

**Archivo:** `resources-lab.yaml`

**Cubre:**
- QoS Guaranteed, Burstable, BestEffort
- Deployment con limits y replicas
- Multi-container resources (suma de contenedores)
- Init container (regla del maximo)
- Monitoreo con kubectl top

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Basico** → Lab 01 (Fundamentos)
2. **Nivel Intermedio** → Lab 02 (Troubleshooting)
3. **Nivel Avanzado** → Lab 03 (Produccion)
4. **Repaso Rapido** → Lab Resumen (15 min)

**Tiempo total estimado:** 2.5-3 horas

## ⚠️ Antes de Comenzar

```bash
# Habilitar metrics-server (necesario para kubectl top)
minikube addons enable metrics-server

# Verificar metricas
kubectl top nodes
kubectl top pods

# Ver recursos disponibles
kubectl describe nodes
```

## 🧹 Limpieza

Cada laboratorio incluye un script de limpieza:

```bash
cd lab-XX-nombre
./cleanup.sh
```
