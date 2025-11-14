# 🌐 Laboratorios - Services y Endpoints

Este módulo contiene laboratorios prácticos para dominar Services y Endpoints en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: ClusterIP Basics](./lab-01-clusterip-basics/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐☆☆☆

Fundamentos de Services tipo ClusterIP.

**Objetivos:**
- Crear Services ClusterIP
- Configurar selectors
- Acceso interno entre pods
- DNS interno de Kubernetes

---

### [Lab 02: NodePort y LoadBalancer](./lab-02-nodeport-loadbalancer/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐☆☆

Exposición de servicios al exterior del cluster.

**Objetivos:**
- Crear Services NodePort
- Configurar LoadBalancer
- Exponer aplicaciones externamente
- Comprender diferencias entre tipos

---

### [Lab 03: Advanced Services](./lab-03-advanced-services/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Características avanzadas de Services y Endpoints.

**Objetivos:**
- ExternalName Services
- Headless Services
- Endpoints manuales
- Service discovery avanzado

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (ClusterIP)
2. **Nivel Intermedio** → Lab 02 (NodePort/LoadBalancer)
3. **Nivel Avanzado** → Lab 03 (Advanced)

**Tiempo total estimado:** 4-5 horas

## 📚 Tipos de Services

### ClusterIP (Default)
- Acceso solo interno
- IP virtual del cluster
- DNS automático

### NodePort
- Expone en puerto del node
- Rango: 30000-32767
- Acceso externo limitado

### LoadBalancer
- Provisiona load balancer externo
- Requiere cloud provider
- Acceso externo completo

### ExternalName
- Alias a servicios externos
- No usa selectors
- DNS CNAME

## ⚠️ Antes de Comenzar

```bash
# Verificar cluster
kubectl cluster-info

# Ver services existentes
kubectl get svc --all-namespaces

# Verificar DNS
kubectl get svc -n kube-system kube-dns
```

## 🧹 Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```
