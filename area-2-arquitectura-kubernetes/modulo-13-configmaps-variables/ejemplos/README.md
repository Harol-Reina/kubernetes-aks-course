# Índice de Ejemplos - ConfigMaps y Variables

Este directorio contiene **ejemplos progresivos** organizados por categoría.

---

## 📁 Estructura de Ejemplos

```
ejemplos/
├── 01-env-vars-basicas/        # Variables de entorno estáticas
├── 02-field-references/        # Referencias a metadata/status/resources
├── 03-configmap-literal/       # Crear ConfigMaps desde literales (CLI)
├── 04-configmap-file/          # Crear ConfigMaps desde archivos
├── 05-configmap-env/           # Consumir ConfigMaps como variables
├── 06-configmap-volume/        # Montar ConfigMaps como volúmenes
└── 07-combinados/              # Casos reales y avanzados
```

---

## 01-env-vars-basicas/

**Variables de entorno hardcoded en manifiestos**

| Archivo | Descripción |
|---------|-------------|
| `pod-env-static.yaml` | Pod simple con 6 variables estáticas |
| `deployment-env-static.yaml` | Deployment con variables para DB, Redis, App |

**Uso**:
```bash
kubectl apply -f 01-env-vars-basicas/pod-env-static.yaml
kubectl exec env-vars-basic -- env | grep DATABASE
```

---

## 02-field-references/

**Inyectar información dinámica del Pod**

| Archivo | Descripción |
|---------|-------------|
| `pod-field-ref.yaml` | Metadata (name, namespace, uid, labels), Status (podIP), Spec (nodeName) |
| `pod-resource-ref.yaml` | Límites y requests de CPU/memoria |
| `deployment-field-logging.yaml` | Structured logging con metadata del Pod |

**Uso**:
```bash
kubectl apply -f 02-field-references/pod-field-ref.yaml
kubectl exec field-ref-demo -- env | grep MY_
```

**Casos de uso**:
- Logging distribuido (identificar Pod/namespace/nodo)
- Auto-scaling basado en recursos
- Debugging y troubleshooting

---

## 03-configmap-literal/

**Crear ConfigMaps desde CLI con `--from-literal`**

| Archivo | Descripción |
|---------|-------------|
| `create-from-literal.sh` | Script para crear 3 ConfigMaps (app-config, redis-config, feature-flags) |
| `configmap-literals.yaml` | Equivalente en YAML (GitOps-friendly) |

**Uso**:
```bash
# Método CLI
chmod +x 03-configmap-literal/create-from-literal.sh
./03-configmap-literal/create-from-literal.sh

# Método YAML
kubectl apply -f 03-configmap-literal/configmap-literals.yaml

# Verificar
kubectl get configmap app-config -o yaml
```

---

## 04-configmap-file/

**Crear ConfigMaps desde archivos**

| Archivo | Descripción |
|---------|-------------|
| `nginx.conf` | Configuración de Nginx (puerto 8080, /health endpoint) |
| `index.html` | Página HTML de ejemplo |
| `create-from-file.sh` | Script para crear ConfigMap desde archivos |
| `nginx-configmap.yaml` | ConfigMap completo en YAML |

**Uso**:
```bash
# Método CLI
cd 04-configmap-file/
kubectl create configmap nginx-config --from-file=nginx.conf --from-file=index.html

# Método YAML
kubectl apply -f 04-configmap-file/nginx-configmap.yaml

# Ver claves
kubectl describe configmap nginx-config
```

---

## 05-configmap-env/

**Consumir ConfigMaps como variables de entorno**

| Archivo | Descripción |
|---------|-------------|
| `pod-env-individual.yaml` | Mapear claves específicas (`configMapKeyRef`) |
| `pod-env-all.yaml` | Importar TODAS las claves (`envFrom`) |
| `deployment-multi-configmaps.yaml` | Múltiples ConfigMaps con prefijos |

**Comparación**:

```yaml
# Opción 1: Individual (control granular)
env:
- name: DATABASE_HOST
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: database.host

# Opción 2: Todas las claves
envFrom:
- configMapRef:
    name: app-config
```

**Uso**:
```bash
kubectl apply -f 05-configmap-env/pod-env-individual.yaml
kubectl exec env-from-configmap-individual -- env | grep DATABASE
```

---

## 06-configmap-volume/

**Montar ConfigMaps como archivos en volúmenes**

| Archivo | Descripción |
|---------|-------------|
| `pod-volume-all-keys.yaml` | Montar TODAS las claves como archivos |
| `pod-volume-selective-keys.yaml` | Seleccionar claves específicas + renombrar |
| `deployment-nginx-full.yaml` | Nginx completo con config montado |

**Diferencias**:

```yaml
# Todas las claves
volumes:
- name: config
  configMap:
    name: app-files
# Resultado: /etc/config/app.properties, /etc/config/database.yaml, /etc/config/init.sh

# Solo claves específicas
volumes:
- name: config
  configMap:
    name: app-files
    items:
    - key: app.properties
      path: app.conf  # Renombrar
# Resultado: solo /etc/config/app.conf
```

**Uso**:
```bash
kubectl apply -f 06-configmap-volume/deployment-nginx-full.yaml
kubectl port-forward deployment/nginx-with-configmap 8080:8080
curl http://localhost:8080
```

---

## 07-combinados/

**Casos reales y avanzados**

| Archivo | Descripción |
|---------|-------------|
| `deployment-auto-reload.yaml` | Sidecar con inotify para auto-reload de nginx |
| `immutable-configmap-versioning.yaml` | ConfigMaps inmutables con versionado (v1, v2) |
| `nodejs-app-complete.yaml` | App Node.js con ConfigMap + Secret + volumes |
| `app.js` | Código Node.js que consume configuración |

**Casos de uso**:

1. **Auto-reload**: Detectar cambios en ConfigMap y recargar app sin downtime
2. **Inmutabilidad**: Proteger contra cambios accidentales + mejor performance
3. **Aplicación completa**: Patrón real con separación de config pública/secreta

**Uso**:
```bash
# Inmutabilidad
kubectl apply -f 07-combinados/immutable-configmap-versioning.yaml
kubectl get configmaps -l app=myapp

# Actualizar a v2 (requiere cambiar referencia en Deployment)
kubectl set env deployment/myapp --from=configmap/app-config-v2 --overwrite
kubectl rollout status deployment/myapp
```

---

## Comandos Útiles

### Crear ConfigMaps

```bash
# Desde literales
kubectl create configmap my-config \
  --from-literal=key1=value1 \
  --from-literal=key2=value2

# Desde archivos
kubectl create configmap my-config \
  --from-file=config.yaml \
  --from-file=script.sh

# Desde directorio completo
kubectl create configmap my-config --from-file=./config-dir/

# Desde YAML (recomendado)
kubectl apply -f configmap.yaml
```

### Inspeccionar ConfigMaps

```bash
# Listar
kubectl get configmaps

# Ver en YAML
kubectl get configmap <name> -o yaml

# Describir (muestra claves sin valores completos)
kubectl describe configmap <name>

# Ver clave específica
kubectl get configmap <name> -o jsonpath='{.data.my-key}'
```

### Actualizar ConfigMaps

```bash
# Editar interactivamente
kubectl edit configmap <name>

# Patch (actualización parcial)
kubectl patch configmap <name> \
  --patch '{"data":{"new-key":"new-value"}}'

# Reemplazar desde archivo
kubectl apply -f configmap-updated.yaml
```

### Debugging

```bash
# Ver variables en Pod
kubectl exec <pod-name> -- env | sort

# Ver archivos montados
kubectl exec <pod-name> -- ls -la /etc/config/
kubectl exec <pod-name> -- cat /etc/config/my-file

# Ver eventos relacionados
kubectl get events --field-selector involvedObject.name=<pod-name>
```

---

## Comparación Rápida: ConfigMap vs Secret

| Aspecto | ConfigMap | Secret |
|---------|-----------|--------|
| **Contenido** | Plain text | Base64 encoded |
| **Uso** | Configuración pública | Datos sensibles |
| **Almacenamiento** | etcd (sin cifrado) | etcd (cifrado at-rest opcional) |
| **Límite** | 1 MiB | 1 MiB |
| **Ejemplo** | URLs, ports, feature flags | Passwords, API keys, certs |

---

## Decisiones de Diseño

### ¿Cuándo Usar Variables de Entorno?

✅ **Usa variables cuando**:
- La configuración es **simple** (pocos valores)
- No necesitas **archivos completos**
- La app espera env vars (apps 12-factor)

❌ **Evita variables cuando**:
- Tienes **archivos grandes** (nginx.conf, JSON complejo)
- Necesitas **actualización dinámica** sin recrear Pods

### ¿Cuándo Usar Volúmenes?

✅ **Usa volúmenes cuando**:
- Necesitas **archivos completos** (configs, scripts)
- Quieres **actualización automática** (sin subPath)
- Múltiples archivos relacionados (directorio completo)

❌ **Evita volúmenes cuando**:
- Solo necesitas **valores simples** (usa env vars)
- Usas `subPath` (no se actualiza automáticamente)

---

## Mejores Prácticas

### 1. Nomenclatura Clara

```yaml
# ✅ Descriptivo
metadata:
  name: nginx-config-prod-v2
  labels:
    app: nginx
    environment: production
    version: "2"

# ❌ Genérico
metadata:
  name: config
```

### 2. Documentación

```yaml
metadata:
  annotations:
    description: "Configuración principal de Nginx para producción"
    owner: "team-infrastructure"
    last-updated: "2025-11-10"
data:
  # Puerto donde Nginx escucha (default: 8080)
  port: "8080"
```

### 3. Versionado (para ConfigMaps inmutables)

```yaml
# app-config-v1 → app-config-v2 → app-config-v3
# Deployment siempre referencia versión específica
envFrom:
- configMapRef:
    name: app-config-v2  # Explícito
```

### 4. Validación

```bash
# Antes de aplicar
kubectl create configmap test --from-file=config.yaml --dry-run=client -o yaml

# Ver qué cambiaría
kubectl diff -f configmap-updated.yaml
```

---

## Troubleshooting

### Variables no aparecen

```bash
# 1. Verificar ConfigMap existe
kubectl get configmap <name>

# 2. Ver contenido
kubectl get configmap <name> -o yaml

# 3. Verificar referencia en Pod
kubectl get pod <pod-name> -o yaml | grep -A10 envFrom
```

### ConfigMap no se actualiza

```bash
# Variables ENV: Nunca se actualizan (recrear Pod)
kubectl rollout restart deployment/<name>

# Volumen con subPath: Nunca se actualiza (recrear Pod)

# Volumen sin subPath: Se actualiza en ~60-90s
# Pero la app debe recargar configuración
```

---

## Próximos Pasos

🧪 **Practica con los laboratorios**:
- [Laboratorio 1: Variables y Field References](../laboratorios/lab-01-env-vars-field-ref.md)
- [Laboratorio 2: ConfigMaps Avanzado](../laboratorios/lab-02-configmaps-avanzado.md)
- [Laboratorio 3: Troubleshooting](../laboratorios/lab-03-troubleshooting.md)

📖 **Lee la documentación principal**:
- [README del Módulo](../README.md)

🔗 **Recursos oficiales**:
- [Kubernetes Docs - ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Docs - Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
