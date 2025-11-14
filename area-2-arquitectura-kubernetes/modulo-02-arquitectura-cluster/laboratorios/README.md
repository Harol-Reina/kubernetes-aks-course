# 🏗️ Laboratorios - Arquitectura del Cluster

Este módulo contiene laboratorios prácticos para comprender la arquitectura de Kubernetes a nivel de cluster.

## 📋 Índice de Laboratorios

### [Lab 01: Exploración de la Arquitectura](./lab-01-exploracion-arquitectura/)
**Duración:** 45-60 minutos | **Dificultad:** ⭐⭐☆☆☆

Exploración práctica de los componentes del cluster de Kubernetes.

**Objetivos:**
- Identificar componentes del control plane
- Explorar componentes de worker nodes
- Entender la comunicación entre componentes

---

### [Lab 02: Control Plane Práctico](./lab-02-control-plane-practico/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

Análisis detallado del funcionamiento del control plane.

**Objetivos:**
- Examinar API Server, Scheduler, Controller Manager
- Analizar etcd y su rol en el cluster
- Comprender el flujo de requests

---

### [Lab 03: Worker Nodes](./lab-03-worker-nodes/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

Exploración de los componentes que ejecutan en worker nodes.

**Objetivos:**
- Analizar kubelet y su funcionamiento
- Explorar kube-proxy y networking
- Comprender el container runtime

---

### [Lab 04: Troubleshooting Networking](./lab-04-troubleshooting-networking/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Diagnóstico y solución de problemas de red en el cluster.

**Objetivos:**
- Diagnosticar problemas de conectividad
- Analizar logs de componentes de red
- Resolver problemas comunes de networking

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (Exploración)
2. **Nivel Intermedio** → Labs 02-03 (Control Plane y Workers)
3. **Nivel Avanzado** → Lab 04 (Troubleshooting)

**Tiempo total estimado:** 4-5 horas

## 📚 Recursos Adicionales

- [Kubernetes Architecture Documentation](https://kubernetes.io/docs/concepts/architecture/)
- [Components Overview](https://kubernetes.io/docs/concepts/overview/components/)
- [Cluster Architecture Best Practices](https://kubernetes.io/docs/setup/best-practices/)

## ⚠️ Antes de Comenzar

Verifica que tienes todos los prerequisitos ejecutando:
```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodes
kubectl get nodes

# Verificar componentes del sistema
kubectl get pods -n kube-system
```

## 🧹 Limpieza

Cada laboratorio incluye un script `cleanup.sh` para limpiar recursos:
```bash
cd lab-XX-nombre
./cleanup.sh
```
