# 🌐 Laboratorios - Services y Endpoints

Este modulo contiene laboratorios practicos para dominar Services y Endpoints en Kubernetes.

Todos los laboratorios utilizan un enfoque **100% declarativo** con archivos YAML documentados.

## 📋 Indice de Laboratorios

### [Lab 01: ClusterIP Basics](./lab-01-clusterip-basics/)
**Duracion:** 40 minutos | **Dificultad:** Basico

Fundamentos de Services tipo ClusterIP, Endpoints y DNS discovery.

**Archivos YAML:** 3 | **Tecnicas:** ClusterIP, Endpoints automaticos, DNS discovery, balanceo de carga, readinessProbe, port-forward

---

### [Lab 02: NodePort y LoadBalancer](./lab-02-nodeport-loadbalancer/)
**Duracion:** 50 minutos | **Dificultad:** Intermedio

Exposicion de servicios al exterior del cluster con NodePort y LoadBalancer.

**Archivos YAML:** 6 | **Tecnicas:** NodePort auto/custom, LoadBalancer, externalTrafficPolicy Cluster vs Local, healthCheckNodePort

---

### [Lab 03: Advanced Services](./lab-03-advanced-services/)
**Duracion:** 60 minutos | **Dificultad:** Avanzado

Caracteristicas avanzadas de Services y Endpoints para produccion.

**Archivos YAML:** 13 | **Tecnicas:** ExternalName, Headless Services, Endpoints manuales, StatefulSet, migracion gradual, PDB, HPA, security context

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Basico** → Lab 01 (ClusterIP)
2. **Nivel Intermedio** → Lab 02 (NodePort/LoadBalancer)
3. **Nivel Avanzado** → Lab 03 (Advanced)

**Tiempo total estimado:** 2.5 horas

## 📚 Tipos de Services

### ClusterIP (Default)
- Acceso solo interno
- IP virtual del cluster
- DNS automatico

### NodePort
- Expone en puerto del nodo
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

Cada laboratorio incluye un script de limpieza:

```bash
cd lab-XX-nombre
chmod +x cleanup.sh
./cleanup.sh
```
