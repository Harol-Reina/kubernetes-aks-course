# ⚙️ Laboratorios - ConfigMaps y Variables

Este módulo contiene laboratorios prácticos para dominar ConfigMaps y gestión de configuración en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: Environment Variables y Field Ref](./lab-01-env-vars-field-ref/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐☆☆☆

Variables de entorno y referencias a campos.

**Objetivos:**
- Configurar variables de entorno
- Usar fieldRef para metadata
- resourceFieldRef para recursos
- Prácticas básicas

---

### [Lab 02: ConfigMaps Avanzado](./lab-02-configmaps-avanzado/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐☆☆

Uso avanzado de ConfigMaps.

**Objetivos:**
- Crear ConfigMaps desde archivos
- Montar como volúmenes
- Actualización en caliente
- Múltiples ConfigMaps

---

### [Lab 03: Troubleshooting](./lab-03-troubleshooting/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

Diagnóstico de problemas con configuración.

**Objetivos:**
- Diagnosticar errores de ConfigMaps
- Validar configuraciones
- Debugging de variables
- Casos comunes

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (Env Vars)
2. **Nivel Intermedio** → Lab 02 (ConfigMaps avanzado)
3. **Nivel Avanzado** → Lab 03 (Troubleshooting)

**Tiempo total estimado:** 3.5-4 horas

## 📚 Conceptos Clave

### ConfigMap
- Almacena configuración como key-value
- Desacopla configuración del código
- Puede montarse como archivos o env vars

### Formas de Usar ConfigMaps

**Como Variables de Entorno:**
```yaml
env:
- name: CONFIG_VALUE
  valueFrom:
    configMapKeyRef:
      name: my-config
      key: config.key
```

**Como Volumen:**
```yaml
volumes:
- name: config-volume
  configMap:
    name: my-config
```

### FieldRef y ResourceFieldRef

**fieldRef** - Metadata del pod:
- `metadata.name`
- `metadata.namespace`
- `status.podIP`

**resourceFieldRef** - Recursos del container:
- `requests.cpu`
- `limits.memory`

## ⚠️ Antes de Comenzar

```bash
# Ver ConfigMaps existentes
kubectl get configmaps

# Describir un ConfigMap
kubectl describe configmap <name>

# Ver contenido
kubectl get configmap <name> -o yaml
```

## 🧹 Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```

## 💡 Best Practices

- Usa ConfigMaps para configuración no sensible
- Para datos sensibles usa Secrets
- Versionea ConfigMaps con nombres únicos
- Evita ConfigMaps muy grandes (>1MB)
