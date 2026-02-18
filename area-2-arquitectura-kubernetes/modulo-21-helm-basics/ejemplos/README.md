# Helm Examples - Índice de Ejemplos

Ejemplos progresivos de Helm Charts con complejidad creciente.

## ✅ Status: 6/6 Ejemplos Completados (100%)

| # | Ejemplo | Complejidad | Templates | Status |
|---|---------|-------------|-----------|--------|
| 1 | basic-chart | 🟢 Básico | 3 | ✅ |
| 2 | values-override | 🟢 Básico | Docs | ✅ |
| 3 | multi-tier-app | 🟡 Intermedio | 6 | ✅ |
| 4 | helm-hooks | 🟡 Intermedio | 5 | ✅ |
| 5 | chart-dependencies | 🟡 Intermedio | 4 | ✅ |
| 6 | advanced-templates | 🔴 Avanzado | 11 | ✅ |

**Validación**: ✅ Todos los charts válidos (0 errores)

## 📚 Ejemplos Disponibles

### 1. Basic Chart (🟢 Básico)
**Ubicación**: `./basic-chart/`

Chart básico funcional con:
- ✅ Deployment con NGINX
- ✅ Service (ClusterIP/NodePort/LoadBalancer)
- ✅ Configuración básica con values.yaml
- ✅ Health checks (liveness/readiness)
- ✅ Resource limits

**Usar para**: Aprender estructura básica de Helm y workflow completo.

```bash
cd basic-chart
helm install my-nginx .
```

**Duración**: 15 minutos

---

### 2. Values Override (🟢 Básico-Intermedio)
**Ubicación**: `./values-override-example.md`

Demostración de configuración multi-entorno:
- ✅ values.yaml (development defaults)
- ✅ values-staging.yaml (staging overrides)
- ✅ values-production.yaml (production overrides)
- ✅ Estrategias de override con `-f` y `--set`

**Usar para**: Gestionar múltiples ambientes con el mismo chart.

**Duración**: 20 minutos

---

### 3. Multi-Tier Application (🟡 Intermedio)
**Ubicación**: `./multi-tier-app/`

Aplicación completa con:
- ✅ Frontend (NGINX - 2 réplicas)
- ✅ Backend (Node.js - 3 réplicas)
- ✅ Database (PostgreSQL StatefulSet)
- ✅ Redis cache
- ✅ Ingress con TLS
- ✅ Secrets management
- ✅ Persistent volumes

**Usar para**: Desplegar aplicación real completa.

```bash
cd multi-tier-app
helm install myapp .
```

**Duración**: 30 minutos

---

### 4. Helm Hooks (🟡 Intermedio)
**Ubicación**: `./helm-hooks/`

Uso de hooks de ciclo de vida:
- ✅ pre-install: Preparación inicial
- ✅ post-install: Seed de datos
- ✅ pre-upgrade: Backup database
- ✅ post-upgrade: Migraciones
- ✅ Hook weights y delete policies

**Usar para**: Tareas automatizadas en ciclo de vida.

```bash
cd helm-hooks
helm install myapp .
kubectl logs job/myapp-pre-install
```

**Duración**: 25 minutos

---

### 5. Chart Dependencies (🟡 Intermedio)
**Ubicación**: `./chart-dependencies/`

Chart con subcharts externos:
- ✅ Subchart PostgreSQL (Bitnami)
- ✅ Subchart Redis (Bitnami)
- ✅ Declaración de dependencies en Chart.yaml
- ✅ Values passing a subcharts
- ✅ Conditional dependencies
- ✅ Service discovery entre componentes

**Usar para**: Composición de aplicaciones con charts externos.

```bash
cd chart-dependencies
helm dependency update
helm install myapp .
```

**Duración**: 25 minutos

---

### 6. Advanced Templates (🔴 Avanzado)
**Ubicación**: `./advanced-templates/`

Templates avanzados con helpers:
- ✅ _helpers.tpl con 20+ named templates
- ✅ Template functions (sprig)
- ✅ Flow control avanzado
- ✅ Validation helpers
- ✅ Checksums para auto-restart
- ✅ DRY principles
- ✅ 11 tipos de recursos K8s

**Usar para**: Aprender mejores prácticas y templates reutilizables.

```bash
cd advanced-templates
helm template myapp .
helm install myapp .
```

**Duración**: 40 minutos

---

## 🔍 Validación de Todos los Charts

Script automático para validar todos los ejemplos:

```bash
# Ejecutar validación completa
./validate-all-charts.sh
```

**Resultado esperado**:
```
✅ basic-chart: 3 templates, 43 sintaxis Go
✅ multi-tier-app: 6 templates, 155 sintaxis Go
✅ helm-hooks: 5 templates, 28 sintaxis Go
✅ chart-dependencies: 4 templates, 83 sintaxis Go
✅ advanced-templates: 11 templates, 334 sintaxis Go
✅ Todos los charts son válidos (0 errores)
```

---

## 🎯 Ruta de Aprendizaje Recomendada

### Principiante (🟢 1-2 horas)
1. **Basic Chart** (15 min) - Estructura y workflow
2. **Values Override** (20 min) - Multi-entorno
3. **Practicar Labs 01-02** (60 min)

### Intermedio (🟡 2-3 horas)
1. **Multi-Tier App** (30 min) - Aplicación completa
2. **Helm Hooks** (25 min) - Automatización
3. **Chart Dependencies** (25 min) - Composición
4. **Practicar Labs 03-04** (60 min)

### Avanzado (🔴 2-3 horas)
1. **Advanced Templates** (40 min) - Templating experto
2. **Estudiar _helpers.tpl** (30 min)
3. **Crear charts propios** (variable)

---

## 🚀 Quick Start

### Opción 1: Basic Chart (Recomendado para comenzar)

```bash
cd basic-chart
helm lint .
helm template test-release .
helm install my-nginx .
helm status my-nginx
helm uninstall my-nginx
```

### Opción 2: Instalar desde repositorio público

```bash
# Más rápido para probar Helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-nginx bitnami/nginx
helm status my-nginx
helm uninstall my-nginx
```

---

## 📖 Recursos Adicionales

- **README principal**: `../README.md`
- **Resumen rápido**: `../RESUMEN-MODULO.md`
- **Laboratorios**: `../laboratorios/`
- **Helm Docs**: https://helm.sh/docs/

---

## ✅ Checklist de Aprendizaje

- [ ] Completar basic-chart
- [ ] Completar values-override
- [ ] Lab 01: Helm Basics
- [ ] Lab 02: Crear Chart
- [ ] Completar multi-tier-app
- [ ] Lab 03: Multi-Entorno
- [ ] Completar helm-hooks
- [ ] Lab 04: Hooks Avanzado
- [ ] Completar chart-dependencies
- [ ] Completar advanced-templates
- [ ] Crear chart propio desde cero

---

**Nota**: Los ejemplos marcados como "pendiente" se pueden crear expandiendo
los conceptos de `basic-chart` o usando `helm create` como base.
