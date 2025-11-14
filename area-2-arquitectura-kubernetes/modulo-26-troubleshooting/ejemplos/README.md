# Ejemplos de Troubleshooting

Este directorio contiene 5 ejemplos organizados en carpetas individuales, cada uno con sus propios archivos YAML, scripts y documentación.

## 📁 Estructura

```
ejemplos/
├── README.md                           # Este archivo
├── 01-broken-apps/                     # Aplicaciones con errores
│   ├── README.md
│   ├── broken-apps.yaml
│   └── cleanup.sh
├── 02-troubleshooting-tools/           # Herramientas de debugging
│   ├── README.md
│   ├── troubleshooting-tools.yaml
│   ├── deploy-all.sh
│   └── cleanup.sh
├── 03-common-errors/                   # Errores comunes
│   ├── README.md
│   ├── common-errors.yaml
│   └── cleanup.sh
├── 04-performance-test/                # Tests de performance
│   ├── README.md
│   ├── performance-test.yaml
│   ├── load-generator.sh
│   └── cleanup.sh
└── 05-rbac-debugging/                  # RBAC troubleshooting
    ├── README.md
    ├── rbac-debugging.yaml
    ├── test-permissions.sh
    └── cleanup.sh
```

## 📋 Ejemplos Disponibles

### 1. [Broken Apps](./01-broken-apps/) ⭐⭐⭐
**12 pods con errores intencionales**

Aprende a diagnosticar:
- CrashLoopBackOff
- ImagePullBackOff
- OOMKilled
- Init container failures
- Liveness/Readiness probe issues
- Missing ConfigMaps/Secrets
- Volume mount errors

**Archivos**: `broken-apps.yaml`, `cleanup.sh`

### 2. [Troubleshooting Tools](./02-troubleshooting-tools/) ⭐⭐
**10 herramientas de debugging listas para usar**

Pods de debugging:
- netshoot (networking completo)
- busybox (lightweight)
- dnsutils (DNS)
- curl (HTTP testing)
- Variantes con privilegios

**Archivos**: `troubleshooting-tools.yaml`, `deploy-all.sh`, `cleanup.sh`

### 3. [Common Errors](./03-common-errors/) ⭐⭐⭐
**12 configuraciones erróneas típicas**

Errores comunes:
- Service sin endpoints
- Port mismatches
- PVC Pending
- Network Policies
- Ingress issues
- HPA sin metrics

**Archivos**: `common-errors.yaml`, `fixes.yaml`, `cleanup.sh`

### 4. [Performance Test](./04-performance-test/) ⭐⭐⭐⭐
**10 escenarios de performance y recursos**

Tests de:
- Memory/CPU stress
- ResourceQuota/LimitRange
- QoS classes
- HPA bajo carga
- PriorityClass
- Node pressure

**Archivos**: `performance-test.yaml`, `load-generator.sh`, `cleanup.sh`

### 5. [RBAC Debugging](./05-rbac-debugging/) ⭐⭐⭐⭐
**11 escenarios RBAC (8 errores + 3 correctos)**

Problemas de permisos:
- ServiceAccount sin permisos
- Wrong verbs
- Namespace mismatch
- API Group errors
- Scope confusion

**Archivos**: `rbac-debugging.yaml`, `test-permissions.sh`, `cleanup.sh`

## 🚀 Uso Rápido

### Opción 1: Ejemplo Individual

```bash
cd 01-broken-apps/
cat README.md              # Leer instrucciones
kubectl apply -f broken-apps.yaml
# ... diagnosticar y resolver ...
./cleanup.sh
```

### Opción 2: Todos los Ejemplos

```bash
# Aplicar todos
for dir in 0*/; do
  kubectl apply -f "$dir"/*.yaml
done

# Ver estado
kubectl get all --all-namespaces

# Limpiar todos
for dir in 0*/; do
  if [ -f "$dir/cleanup.sh" ]; then
    chmod +x "$dir/cleanup.sh"
    "$dir/cleanup.sh"
  fi
done
```

## 📚 Orden de Estudio Recomendado

### Nivel Básico-Intermedio
1. **Broken Apps** (01) - Fundamentos de troubleshooting
2. **Troubleshooting Tools** (02) - Familiarizarse con herramientas

### Nivel Intermedio-Avanzado
3. **Common Errors** (03) - Errores de configuración
4. **Performance Test** (04) - Recursos y performance

### Nivel Avanzado
5. **RBAC Debugging** (05) - Seguridad y permisos

## 🎯 Objetivos de Aprendizaje

Después de completar estos ejemplos, deberás poder:

- ✅ Diagnosticar cualquier pod en estado de error en <5 minutos
- ✅ Usar pods de debugging efectivamente
- ✅ Identificar y corregir configuraciones incorrectas
- ✅ Troubleshoot problemas de recursos y performance
- ✅ Resolver problemas RBAC con `kubectl auth can-i`
- ✅ Aplicar metodología sistemática de troubleshooting

## 💡 Tips

1. **Siempre lee el README** de cada ejemplo primero
2. **No mires las soluciones** inmediatamente - intenta resolver solo
3. **Usa comandos de diagnóstico** antes de aplicar fixes
4. **Documenta tus hallazgos** para reforzar aprendizaje
5. **Practica múltiples veces** hasta que sea natural
6. **Cronométrate** - el examen CKA tiene límite de tiempo

## 🧹 Limpieza Global

```bash
# Desde la carpeta ejemplos/
find . -name "cleanup.sh" -exec chmod +x {} \;
find . -name "cleanup.sh" -exec {} \;

# O manualmente
kubectl delete all --all
kubectl delete pvc,configmap,secret,networkpolicy,ingress,hpa --all
kubectl delete sa --all --field-selector metadata.name!=default
```

## 📖 Recursos Relacionados

- [README Principal del Módulo](../README.md)
- [RESUMEN-MODULO](../RESUMEN-MODULO.md) - Cheatsheet de comandos
- [Laboratorios](../laboratorios/) - Práctica hands-on guiada

---

**Tiempo total estimado**: 3-4 horas para todos los ejemplos  
**CKA Coverage**: ~15% del examen (Troubleshooting domain)
