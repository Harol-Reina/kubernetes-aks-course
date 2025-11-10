# Índice de Ejemplos - Módulo 10: Namespaces y Organización

## Descripción General

Esta carpeta contiene **15 ejemplos prácticos** que cubren todos los aspectos de Namespaces en Kubernetes, desde conceptos básicos hasta patrones avanzados de multi-tenancy.

---

## 📁 Estructura de Ejemplos

```
ejemplos/
├── 01-basico/                  # Fundamentos de namespaces
│   ├── namespace-basic.yaml
│   ├── namespace-with-labels.yaml
│   └── deployment-multi-namespace.yaml
├── 02-contextos/               # Kubeconfig y contextos
│   ├── kubeconfig-example.yaml
│   └── context-switching.sh
├── 03-quotas/                  # ResourceQuota
│   ├── resourcequota-basic.yaml
│   └── resourcequota-advanced.yaml
├── 04-limits/                  # LimitRange
│   └── limitrange-basic.yaml
├── 05-organizacion/            # Patrones de organización
│   └── namespace-by-environment.yaml
└── README.md                   # Este archivo
```

---

## 📋 Tabla de Ejemplos

| # | Archivo | Nivel | Conceptos | Tiempo |
|---|---------|-------|-----------|--------|
| 1 | [namespace-basic.yaml](01-basico/namespace-basic.yaml) | Básico | Creación, labels, annotations | 5 min |
| 2 | [namespace-with-labels.yaml](01-basico/namespace-with-labels.yaml) | Básico | Labels estratégicos, filtrado | 10 min |
| 3 | [deployment-multi-namespace.yaml](01-basico/deployment-multi-namespace.yaml) | Básico | Despliegue multi-namespace | 15 min |
| 4 | [kubeconfig-example.yaml](02-contextos/kubeconfig-example.yaml) | Intermedio | Contextos, clusters, users | 15 min |
| 5 | [context-switching.sh](02-contextos/context-switching.sh) | Intermedio | Script helper para contextos | 20 min |
| 6 | [resourcequota-basic.yaml](03-quotas/resourcequota-basic.yaml) | Intermedio | Quotas CPU, memoria, objetos | 15 min |
| 7 | [resourcequota-advanced.yaml](03-quotas/resourcequota-advanced.yaml) | Avanzado | Scopes, PriorityClass | 25 min |
| 8 | [limitrange-basic.yaml](04-limits/limitrange-basic.yaml) | Intermedio | Defaults, min/max, ratios | 20 min |
| 9 | [namespace-by-environment.yaml](05-organizacion/namespace-by-environment.yaml) | Avanzado | Organización por entorno | 30 min |

**Total**: 155 minutos (~2.5 horas de práctica)

---

## 🎯 Casos de Uso por Categoría

### 1. Fundamentos (01-basico/)

**¿Cuándo usar?**
- Aprender a crear y gestionar namespaces
- Entender labels y organización básica
- Desplegar aplicaciones en múltiples namespaces

**Ejemplos clave**:
- `namespace-basic.yaml`: Primer namespace con metadata completa
- `namespace-with-labels.yaml`: Estrategia de labeling multi-dimensional
- `deployment-multi-namespace.yaml`: App en dev, staging, prod

### 2. Contextos y Kubeconfig (02-contextos/)

**¿Cuándo usar?**
- Gestionar múltiples clústeres
- Cambiar entre namespaces frecuentemente
- Automatizar workflows de switching

**Ejemplos clave**:
- `kubeconfig-example.yaml`: Configuración completa con múltiples contextos
- `context-switching.sh`: Script interactivo para cambio rápido

### 3. ResourceQuota (03-quotas/)

**¿Cuándo usar?**
- Limitar consumo de recursos por namespace
- Implementar multi-tenancy
- Prevenir agotamiento de recursos del clúster

**Ejemplos clave**:
- `resourcequota-basic.yaml`: Quotas esenciales (CPU, memoria, pods)
- `resourcequota-advanced.yaml`: Scopes, PriorityClass, count quotas

### 4. LimitRange (04-limits/)

**¿Cuándo usar?**
- Establecer defaults para Pods sin recursos especificados
- Limitar rangos permitidos por objeto
- Prevenir configuraciones extremas

**Ejemplos clave**:
- `limitrange-basic.yaml`: Defaults, min/max, ratios completos

### 5. Organización (05-organizacion/)

**¿Cuándo usar?**
- Diseñar estructura de namespaces para empresa
- Implementar separación por entorno/equipo/proyecto
- Establecer políticas de recursos

**Ejemplos clave**:
- `namespace-by-environment.yaml`: Patrón dev/staging/prod completo

---

## 🚀 Guía de Aprendizaje Progresivo

### Ruta 1: Principiante (3 horas)

1. **Fundamentos** (30 min)
   - `namespace-basic.yaml`
   - `namespace-with-labels.yaml`

2. **Multi-namespace** (45 min)
   - `deployment-multi-namespace.yaml`
   - Testing de DNS cross-namespace

3. **Contextos** (30 min)
   - `kubeconfig-example.yaml`
   - Práctica de switching manual

4. **Quotas Básicas** (45 min)
   - `resourcequota-basic.yaml`
   - Testing de límites

5. **LimitRange** (30 min)
   - `limitrange-basic.yaml`
   - Observar defaults aplicados

### Ruta 2: Intermedio (2 horas)

1. **Labels Avanzados** (20 min)
   - `namespace-with-labels.yaml`
   - Filtrado multi-dimensional

2. **Automatización de Contextos** (40 min)
   - `context-switching.sh`
   - Customizar script

3. **Quotas Avanzadas** (60 min)
   - `resourcequota-advanced.yaml`
   - Scopes, PriorityClass, testing

### Ruta 3: Avanzado (2.5 horas)

1. **Arquitectura Multi-Entorno** (90 min)
   - `namespace-by-environment.yaml`
   - Implementar pipeline completo

2. **Integración Completa** (60 min)
   - Combinar quotas + limits + RBAC
   - Testing de aislamiento

---

## 📖 Comandos Útiles por Ejemplo

### Ejemplo 1-3: Namespaces Básicos

```bash
# Aplicar ejemplos básicos
kubectl apply -f 01-basico/

# Listar namespaces con labels
kubectl get ns --show-labels

# Filtrar por label
kubectl get ns -l environment=prod

# Describir namespace
kubectl describe ns development

# Ver recursos en un namespace
kubectl get all -n development
```

### Ejemplo 4-5: Contextos

```bash
# Ver configuración kubeconfig
kubectl config view

# Listar contextos
kubectl config get-contexts

# Cambiar contexto
kubectl config use-context production

# Cambiar namespace del contexto actual
kubectl config set-context --current --namespace=production

# Script helper
chmod +x 02-contextos/context-switching.sh
./02-contextos/context-switching.sh -c production
```

### Ejemplo 6-7: ResourceQuota

```bash
# Aplicar quota
kubectl apply -f 03-quotas/resourcequota-basic.yaml

# Ver quota
kubectl get resourcequota -n development
kubectl describe resourcequota compute-quota -n development

# Ver uso actual
kubectl describe ns development | grep -A 15 "Resource Quotas"

# Testing de límites
kubectl run test --image=nginx -n development \
  --requests='cpu=100m,memory=128Mi' \
  --limits='cpu=200m,memory=256Mi'
```

### Ejemplo 8: LimitRange

```bash
# Aplicar LimitRange
kubectl apply -f 04-limits/limitrange-basic.yaml

# Ver LimitRange
kubectl describe limitrange compute-limits -n development

# Crear Pod sin recursos (observar defaults aplicados)
kubectl run test --image=nginx -n development
kubectl get pod test -n development -o yaml | grep -A 10 resources:
```

### Ejemplo 9: Organización por Entorno

```bash
# Aplicar estructura completa
kubectl apply -f 05-organizacion/namespace-by-environment.yaml

# Comparar recursos entre entornos
for ns in development staging production; do
  echo "=== $ns ==="
  kubectl get deployment webapp -n $ns -o wide
done

# Verificar quotas por entorno
kubectl get resourcequota --all-namespaces

# Promover imagen entre entornos
kubectl set image deployment/webapp webapp=myapp:v1.1.0 -n development
kubectl set image deployment/webapp webapp=myapp:v1.1.0 -n staging
kubectl set image deployment/webapp webapp=myapp:v1.1.0 -n production
```

---

## 🔍 Testing y Validación

### Validar Quotas

```bash
# Crear namespace con quota
kubectl create ns test-quota
kubectl apply -f 03-quotas/resourcequota-basic.yaml

# Intentar exceder quota (debe fallar)
kubectl run big-pod --image=nginx -n test-quota \
  --requests='cpu=5,memory=10Gi' \
  --limits='cpu=10,memory=20Gi'

# Verificar error
# Error: exceeded quota: compute-quota, requested: requests.cpu=5
```

### Validar LimitRange

```bash
# Aplicar LimitRange
kubectl apply -f 04-limits/limitrange-basic.yaml

# Crear Pod sin recursos
kubectl run test --image=nginx -n development

# Verificar defaults aplicados
kubectl get pod test -n development -o jsonpath='{.spec.containers[0].resources}'
```

### Validar DNS Cross-Namespace

```bash
# Crear deployment en múltiples namespaces
kubectl apply -f 01-basico/deployment-multi-namespace.yaml

# Testing DNS desde Pod
kubectl run -it --rm debug --image=alpine -n development -- sh
# Dentro del Pod:
apk add curl bind-tools
nslookup webapp.production.svc.cluster.local
curl http://webapp.production
```

---

## 🎓 Ejercicios Propuestos

### Ejercicio 1: Labels Personalizados

Modifica `namespace-with-labels.yaml` para agregar:
- Label `region: us-west-2`
- Label `compliance: pci-dss`
- Annotation `budget: "50000"`

### Ejercicio 2: Quota Personalizada

Crea un ResourceQuota para namespace `testing` con:
- Max 5 Pods
- CPU request: 2 cores
- Memory request: 4Gi
- Max 2 Services LoadBalancer

### Ejercicio 3: LimitRange Ajustado

Crea un LimitRange para `production` con:
- Default CPU: 1 core
- Default Memory: 1Gi
- Ratio máximo: 2 (límite puede ser 2× request)

### Ejercicio 4: Multi-Tenant

Diseña estructura de namespaces para 3 clientes:
- `tenant-companyA`
- `tenant-companyB`
- `tenant-companyC`

Cada uno con:
- ResourceQuota de 10 cores, 20Gi RAM
- LimitRange apropiado
- Labels para identificar tenant

---

## 🔗 Referencias

### Relacionado con Módulos

- **Módulo 11**: Resource Limits en Pods (detalle de requests/limits)
- **Módulo 12**: LimitRange (profundización)
- **Módulo 13**: ResourceQuota (casos avanzados)
- **Módulo 19**: RBAC (permisos por namespace)

### Documentación Oficial

- [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/)
- [Configure Kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)

---

## 🛠️ Herramientas Recomendadas

| Herramienta | Propósito | Instalación |
|-------------|-----------|-------------|
| **kubectx** | Cambio rápido de contextos | `brew install kubectx` |
| **kubens** | Cambio rápido de namespaces | Incluido con kubectx |
| **k9s** | TUI para Kubernetes | `brew install k9s` |
| **Lens** | IDE visual de K8s | https://k8slens.dev |
| **stern** | Logs multi-pod/namespace | `brew install stern` |

---

## ⚠️ Troubleshooting Común

### Error: "exceeded quota"

```bash
# Ver quota actual
kubectl describe ns <namespace> | grep -A 10 "Resource Quotas"

# Ver uso específico
kubectl describe resourcequota <quota-name> -n <namespace>

# Solución: Eliminar pods o aumentar quota
```

### Error: "must specify limits/requests"

```bash
# Causa: Namespace tiene ResourceQuota pero Pod no especifica recursos

# Solución: Agregar resources al Pod
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "200m"
    memory: "256Mi"
```

### DNS no resuelve cross-namespace

```bash
# Usar FQDN completo
curl http://service.namespace.svc.cluster.local

# O nombre corto con namespace
curl http://service.namespace
```

---

## 📝 Notas Importantes

1. **Orden de aplicación**: Crear namespace antes que quotas/limits
2. **LimitRange no es retroactivo**: Solo aplica a Pods nuevos
3. **Eliminar namespace**: ⚠️ Elimina TODOS los recursos dentro
4. **Labels**: Usar convención consistente (kebab-case)
5. **Testing**: Siempre probar en dev antes de aplicar en prod

---

**📚 Navegación**:
- 🏠 [Volver al README principal](../README.md)
- 📖 [Ver Laboratorios](../laboratorios/)
- ➡️ [Módulo 11 - Resource Limits](../../modulo-11-resource-limits-pods/README.md)
