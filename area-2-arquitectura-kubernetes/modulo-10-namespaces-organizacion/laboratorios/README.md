# Laboratorios - Namespaces y Organizacion

Este modulo contiene laboratorios practicos para dominar Namespaces y organizacion de recursos en Kubernetes.

## Indice de Laboratorios

### [Lab 01: Namespaces Basico](./lab-01-namespaces-basico/)
**Duracion:** 35-40 minutos | **Dificultad:** Basico

Creacion de namespaces, contextos de kubectl, despliegue multi-namespace y DNS cross-namespace.

**Archivos YAML:**
- `namespace-production.yaml` - Namespace con labels y annotations
- `webapp.yaml` - Deployment + Service reutilizable con `-n`

---

### [Lab 02: Quotas y Limits](./lab-02-quotas-limits/)
**Duracion:** 45-50 minutos | **Dificultad:** Intermedio

ResourceQuota para limitar recursos agregados, LimitRange para defaults y rangos por container.

**Archivos YAML:**
- `resourcequota-compute.yaml` - Quota de CPU, memoria, pods, services
- `limitrange-compute.yaml` - Defaults, min, max y ratios por container
- `resourcequota-besteffort.yaml` - Quota con scope BestEffort

---

### [Lab 03: Multi-Tenancy](./lab-03-multi-tenancy/)
**Duracion:** 50-60 minutos | **Dificultad:** Avanzado

Arquitectura multi-tenant con RBAC, NetworkPolicies y aislamiento completo entre tenants.

**Archivos YAML:**
- `tenant-setup.yaml` - 3 namespaces con ResourceQuota y LimitRange
- `tenant-rbac.yaml` - ServiceAccount, Role y RoleBinding por tenant
- `networkpolicy-deny-all.yaml` - Default deny all (reutilizable con `-n`)
- `networkpolicy-allow-same-ns.yaml` - Allow intra-namespace (reutilizable con `-n`)

---

### [Lab Resumen: Namespaces Completo](./lab-resumen-namespaces/)
**Duracion:** 60 minutos | **Dificultad:** Repaso integral | **Plataforma:** Minikube

Un solo YAML despliega 3 namespaces con deployments, quotas, limits, RBAC y NetworkPolicies para practicar todos los conceptos de un vistazo.

**Archivo YAML:**
- `namespaces-lab.yaml` - Todo el lab en un archivo

**Conceptos cubiertos:**
Namespaces, DNS cross-namespace, ResourceQuota, LimitRange, RBAC, NetworkPolicy

---

## Ruta de Aprendizaje Recomendada

1. **Nivel Basico** -> Lab 01 (Namespaces basico)
2. **Nivel Intermedio** -> Lab 02 (Quotas y Limits)
3. **Nivel Avanzado** -> Lab 03 (Multi-tenancy)
4. **Repaso integral** -> Lab Resumen (todos los conceptos en 1 hora con Minikube)

**Tiempo total estimado:** 3.5-4 horas

## Enfoque Declarativo

Todos los laboratorios usan archivos YAML documentados. Cada archivo incluye:
- Descripcion del recurso y su proposito
- Conceptos clave explicados en los comentarios
- Prerequisitos y comandos de verificacion
- Namespace donde se crea el recurso

## Antes de Comenzar

```bash
kubectl cluster-info
kubectl get namespaces
ls lab-01-namespaces-basico/*.yaml
ls lab-02-quotas-limits/*.yaml
ls lab-03-multi-tenancy/*.yaml
```

## Limpieza

Cada laboratorio incluye un script `cleanup.sh` con limpieza especifica:

```bash
cd lab-XX-nombre
chmod +x cleanup.sh
./cleanup.sh
```
