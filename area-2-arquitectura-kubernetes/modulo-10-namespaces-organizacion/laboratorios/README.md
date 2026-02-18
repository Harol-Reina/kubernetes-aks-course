# 📦 Laboratorios - Namespaces y Organización

Este módulo contiene laboratorios prácticos para dominar Namespaces y organización de recursos en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: Namespaces Básico](./lab-01-namespaces-basico/)
**Duración:** 45-60 minutos | **Dificultad:** ⭐⭐☆☆☆

Introducción a namespaces y su uso básico.

**Objetivos:**
- Crear y eliminar namespaces
- Listar recursos por namespace
- Cambiar contexto entre namespaces
- Comprender namespace default

---

### [Lab 02: Quotas y Limits](./lab-02-quotas-limits/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐☆☆

Implementación de ResourceQuotas y LimitRanges.

**Objetivos:**
- Configurar ResourceQuotas
- Implementar LimitRanges
- Limitar recursos por namespace
- Prevenir abuso de recursos

---

### [Lab 03: Multi-tenancy](./lab-03-multi-tenancy/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Implementación de multi-tenancy con namespaces.

**Objetivos:**
- Diseñar arquitectura multi-tenant
- Aislamiento de recursos
- Network policies por namespace
- Best practices de organización

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (Namespaces básico)
2. **Nivel Intermedio** → Lab 02 (Quotas y Limits)
3. **Nivel Avanzado** → Lab 03 (Multi-tenancy)

**Tiempo total estimado:** 4-5 horas

## 📚 Conceptos Clave

### ¿Qué son los Namespaces?
- Aislamiento lógico de recursos
- No aislamiento físico (networking, storage)
- Organización y control de acceso
- Multi-tenancy básico

### Namespaces del Sistema
- `default`: Namespace por defecto
- `kube-system`: Componentes del sistema
- `kube-public`: Recursos públicos
- `kube-node-lease`: Node heartbeats

### ResourceQuota
Limita recursos agregados en un namespace:
- CPU total
- Memoria total
- Número de objetos (pods, services, etc.)

### LimitRange
Define límites por recurso individual:
- CPU/memoria por container
- CPU/memoria por pod
- Storage por PVC

## ⚠️ Antes de Comenzar

```bash
# Ver namespaces existentes
kubectl get namespaces

# Ver recursos en un namespace
kubectl get all -n kube-system

# Configurar namespace por defecto
kubectl config set-context --current --namespace=dev
```

## 🧹 Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```

## 💡 Best Practices

- Usa namespaces para separar entornos (dev, staging, prod)
- Implementa ResourceQuotas en producción
- Nunca uses `default` namespace en producción
- Combina con RBAC para control de acceso
