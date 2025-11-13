# 📚 RESUMEN - Módulo 13: ConfigMaps y Variables de Entorno

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre la **gestión de configuración externa** en Kubernetes - cómo separar la configuración del código siguiendo el principio de 12-Factor App. Aprenderás a usar variables de entorno, field references y ConfigMaps para hacer tus aplicaciones portables entre entornos.

**Duración**: 6 horas (teoría + labs)  
**Nivel**: Intermedio  
**Prerequisitos**: Pods, Deployments, Namespaces

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### Fundamentos
- ✅ Entender el principio de separación configuración/código
- ✅ Diferenciar env vars, field references y ConfigMaps
- ✅ Saber cuándo usar ConfigMaps vs Secrets
- ✅ Comprender actualizaciones de ConfigMaps

### Técnico
- ✅ Definir variables de entorno en Pods
- ✅ Usar field references (metadata.namespace, podIP, etc.)
- ✅ Crear ConfigMaps (literales, archivos, directorios)
- ✅ Consumir ConfigMaps (env vars y volumes)
- ✅ Gestionar actualizaciones de configuración

### Avanzado
- ✅ Implementar ConfigMaps inmutables
- ✅ Combinar múltiples fuentes de configuración
- ✅ Aplicar hot-reload patterns
- ✅ Diseñar versionado de ConfigMaps
- ✅ Troubleshoot problemas de configuración

---

## 🗺️ Estructura de Aprendizaje

### Fase 1: Variables de Entorno Básicas (20 min)
**Teoría**: Sección 2 del README

#### ¿Qué son las Variables de Entorno?

**Variables de entorno** = Pares clave-valor disponibles en el proceso del contenedor.

**Uso típico**:
```bash
# En la aplicación
DB_HOST=postgres
DB_PORT=5432
LOG_LEVEL=debug
```

#### Configuración en Kubernetes

**YAML básico**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_HOST
      value: "postgres.default.svc.cluster.local"
    - name: DB_PORT
      value: "5432"
    - name: LOG_LEVEL
      value: "info"
```

**Verificar variables en Pod**:
```bash
# Ver todas las env vars
kubectl exec myapp -- env

# Ver una específica
kubectl exec myapp -- printenv DB_HOST
```

#### Cuándo Usar Env Vars Directas

**✅ Usar para**:
- Valores simples y pocos (<5 variables)
- Valores específicos de un solo Pod
- Testing rápido

**❌ NO usar para**:
- Configuración compleja (archivos .properties, .json, .yaml)
- Secretos (usar Secrets)
- Valores compartidos entre múltiples Pods (usar ConfigMaps)

---

### Fase 2: Field References (25 min)
**Teoría**: Sección 3 del README

#### ¿Qué son Field References?

**Field References** = Acceder a **metadata del Pod** como variables de entorno.

**Campos disponibles**:
- `metadata.name` - Nombre del Pod
- `metadata.namespace` - Namespace del Pod
- `metadata.uid` - UID único del Pod
- `spec.nodeName` - Nodo donde corre el Pod
- `spec.serviceAccountName` - Service account
- `status.podIP` - IP del Pod
- `status.hostIP` - IP del nodo

#### Configuración

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  namespace: production
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    # Field references
    - name: MY_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    
    - name: MY_POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    
    - name: MY_POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    
    - name: MY_NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
```

**Resultado en el contenedor**:
```bash
kubectl exec myapp -- env | grep MY_

# MY_POD_NAME=myapp
# MY_POD_NAMESPACE=production
# MY_POD_IP=10.244.0.5
# MY_NODE_NAME=node-1
```

#### Casos de Uso

**1. Logging contextual**:
```python
import os
import logging

logging.basicConfig(
    format=f'[{os.getenv("MY_POD_NAME")}] %(message)s'
)
# Logs: [myapp-abc123] User logged in
```

**2. Distributed tracing**:
```javascript
const tracer = initTracer({
  serviceName: process.env.MY_POD_NAME,
  tags: {
    namespace: process.env.MY_POD_NAMESPACE,
    podIP: process.env.MY_POD_IP
  }
});
```

**3. Service discovery**:
```bash
# Construir URL dinámica
REDIS_URL="redis://redis.${MY_POD_NAMESPACE}.svc.cluster.local:6379"
```

**Lab 1**: [Env Vars y Field Ref](laboratorios/lab-01-env-vars-field-ref.md) - 40 min

---

### Fase 3: ConfigMaps - Creación (30 min)
**Teoría**: Sección 4 del README

#### ¿Qué es un ConfigMap?

**ConfigMap** = Objeto de Kubernetes para almacenar configuración no sensible en pares clave-valor.

**Beneficios**:
- ✅ Separación configuración/código
- ✅ Misma imagen en múltiples entornos
- ✅ Configuración centralizada
- ✅ Actualizaciones sin rebuild

#### Métodos de Creación

**1. Desde Literales** (valores inline):
```bash
kubectl create configmap app-config \
  --from-literal=DB_HOST=postgres \
  --from-literal=DB_PORT=5432 \
  --from-literal=LOG_LEVEL=info
```

**Verificar**:
```bash
kubectl get configmap app-config -o yaml

# data:
#   DB_HOST: postgres
#   DB_PORT: "5432"
#   LOG_LEVEL: info
```

---

**2. Desde Archivo Individual**:
```bash
# Crear archivo
cat > app.properties <<EOF
database.host=postgres
database.port=5432
log.level=info
EOF

# Crear ConfigMap
kubectl create configmap app-config \
  --from-file=app.properties
```

**Resultado**:
```yaml
data:
  app.properties: |
    database.host=postgres
    database.port=5432
    log.level=info
```

**Con nombre de clave personalizado**:
```bash
kubectl create configmap app-config \
  --from-file=config.properties=app.properties
#              ↑ key           ↑ archivo
```

---

**3. Desde Directorio**:
```bash
# Estructura
config/
├── database.conf
├── cache.conf
└── logging.conf

# Crear ConfigMap
kubectl create configmap app-config \
  --from-file=config/
```

**Resultado**: Cada archivo se convierte en una clave.

---

**4. Declarativo (YAML)**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  # Valores simples
  DB_HOST: "postgres"
  DB_PORT: "5432"
  
  # Archivos completos
  app.properties: |
    database.host=postgres
    database.port=5432
    log.level=info
  
  nginx.conf: |
    server {
      listen 80;
      server_name example.com;
    }
```

```bash
kubectl apply -f configmap.yaml
```

---

### Fase 4: ConfigMaps - Consumo (40 min)
**Teoría**: Sección 5 del README

#### Opción 1: Como Variables de Entorno Individuales

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_HOST
    - name: DB_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_PORT
```

**Verificar**:
```bash
kubectl exec myapp -- printenv DB_HOST
# postgres
```

---

#### Opción 2: Todas las Claves como Env Vars (envFrom)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    envFrom:
    - configMapRef:
        name: app-config
```

**Resultado**: Todas las claves del ConfigMap se convierten en variables de entorno.

**Ventaja**: Menos verboso, todas las claves automáticamente.

---

#### Opción 3: Como Volumen (Archivos)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config    # Directorio donde se montan
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

**Resultado en el contenedor**:
```bash
kubectl exec myapp -- ls /etc/config
# DB_HOST
# DB_PORT
# LOG_LEVEL

kubectl exec myapp -- cat /etc/config/DB_HOST
# postgres
```

**Cada clave del ConfigMap = 1 archivo**.

---

#### Opción 4: Archivos Específicos del ConfigMap

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf        # Solo montar este archivo
  volumes:
  - name: config-volume
    configMap:
      name: nginx-config
      items:
      - key: nginx.conf          # Clave del ConfigMap
        path: nginx.conf         # Nombre del archivo
```

**Uso**: Montar archivo de configuración específico (nginx.conf, application.yml, etc.)

---

#### Comparación: Env Vars vs Volumes

| Aspecto | Env Vars | Volumes |
|---------|----------|---------|
| **Uso** | Valores simples | Archivos completos |
| **Actualización** | ❌ No (requiere restart) | ✅ Sí (automático) |
| **Formato** | KEY=value | Archivos |
| **Ejemplo** | DB_HOST=postgres | nginx.conf, app.properties |

**Lab 2**: [ConfigMaps Avanzado](laboratorios/lab-02-configmaps-avanzado.md) - 60 min

---

### Fase 5: Actualizaciones de ConfigMaps (20 min)
**Teoría**: Sección 6 del README

#### ¿Qué pasa al actualizar un ConfigMap?

**ConfigMap como ENV VARS**:
```bash
# Actualizar ConfigMap
kubectl edit configmap app-config

# ❌ Variables de entorno NO se actualizan automáticamente
# Requiere restart del Pod
kubectl rollout restart deployment myapp
```

**ConfigMap como VOLUME**:
```bash
# Actualizar ConfigMap
kubectl edit configmap app-config

# ✅ Archivos se actualizan automáticamente (en ~60s)
# La app debe detectar cambios (watch file)
```

#### Hot-Reload Pattern

**En la aplicación** (ejemplo Node.js):
```javascript
const fs = require('fs');
const configPath = '/etc/config/app.json';

// Watch para cambios
fs.watch(configPath, (event) => {
  if (event === 'change') {
    console.log('Config changed, reloading...');
    const newConfig = JSON.parse(
      fs.readFileSync(configPath, 'utf8')
    );
    applyConfig(newConfig);
  }
});
```

#### Estrategia: ConfigMaps Versionados

**Problema**: Cambios en ConfigMap afectan todos los Pods.

**Solución**: Versionar ConfigMaps.

```yaml
# ConfigMap versionado
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-v2    # Incluir versión
data:
  DB_HOST: "postgres-new"
---
# Deployment referencia versión específica
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        envFrom:
        - configMapRef:
            name: app-config-v2    # Versión específica
```

**Beneficio**: Rollback fácil, cambiar a `app-config-v1`.

---

### Fase 6: Secrets (Introducción) (20 min)
**Teoría**: Sección 7 del README

#### ConfigMaps vs Secrets

| Aspecto | ConfigMap | Secret |
|---------|-----------|--------|
| **Datos** | Configuración pública | Datos sensibles |
| **Codificación** | Texto plano | Base64 |
| **Uso** | DB host, URLs | Passwords, API keys, certs |
| **Seguridad** | Bajo | Medio (RBAC, encryption at rest) |

#### Ejemplo rápido de Secret

```bash
# Crear Secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=supersecret
```

**Consumir en Pod**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
```

**Nota**: Secrets se cubren en detalle en el Módulo 14.

---

### Fase 7: ConfigMaps Inmutables (20 min)
**Teoría**: Sección 8 del README

#### ¿Qué son ConfigMaps Inmutables?

**Inmutable** = No se puede modificar después de crear (K8s 1.21+).

**Beneficios**:
- ✅ **Performance**: kubelet no necesita watch por cambios
- ✅ **Seguridad**: Previene cambios accidentales
- ✅ **Estabilidad**: Config no cambia bajo los Pods

**Crear inmutable**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
immutable: true      # ← Inmutable
data:
  DB_HOST: "postgres"
  DB_PORT: "5432"
```

**Intentar modificar**:
```bash
kubectl edit configmap app-config
# Error: field is immutable
```

**Para cambiar**: Eliminar y recrear (o crear nueva versión).

```bash
kubectl delete configmap app-config
kubectl apply -f configmap-v2.yaml
```

**Cuándo usar**:
- ✅ Producción con configuración estable
- ✅ Clústeres grandes (mejor performance)
- ✅ Configuración crítica (prevenir cambios)

**Cuándo NO usar**:
- ❌ Desarrollo (necesitas cambiar frecuentemente)
- ❌ Feature flags dinámicos

---

### Fase 8: Best Practices (30 min)
**Teoría**: Sección 9 del README

#### 1. Separar Configuración por Entorno

**Estructura**:
```
configmaps/
├── app-config-dev.yaml
├── app-config-staging.yaml
└── app-config-prod.yaml
```

**Aplicar según entorno**:
```bash
kubectl apply -f configmaps/app-config-dev.yaml -n development
kubectl apply -f configmaps/app-config-prod.yaml -n production
```

---

#### 2. Usar Nombres Descriptivos

**❌ MALO**:
```yaml
name: config
name: cm1
name: data
```

**✅ BUENO**:
```yaml
name: myapp-database-config
name: nginx-config
name: redis-config
```

---

#### 3. Versionar ConfigMaps

```yaml
metadata:
  name: app-config-v1
  labels:
    app: myapp
    version: "1"
```

**Deployment**:
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        envFrom:
        - configMapRef:
            name: app-config-v1
```

**Rollback**: Cambiar a `app-config-v1` anterior.

---

#### 4. ConfigMaps Pequeños

**Límite**: 1 MiB por ConfigMap.

**❌ NO guardar**:
- Binarios grandes
- Archivos de logs
- Datasets completos

**✅ Guardar**:
- Archivos de configuración (<100 KB)
- Valores de configuración
- Pequeños templates

---

#### 5. Combinar Fuentes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    # 1. Variable estática
    - name: ENV
      value: "production"
    
    # 2. Field reference
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    
    # 3. ConfigMap individual
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_HOST
    
    # 4. Secret
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    
    # 5. Todas las claves de ConfigMap
    envFrom:
    - configMapRef:
        name: app-config
    
    # 6. Volume
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: nginx-config
```

---

#### 6. GitOps para ConfigMaps

**Estructura de repo**:
```
k8s-config/
├── base/
│   └── configmap.yaml
└── overlays/
    ├── dev/
    │   └── configmap.yaml
    ├── staging/
    │   └── configmap.yaml
    └── prod/
        └── configmap.yaml
```

**Aplicar con Kustomize**:
```bash
kubectl apply -k overlays/prod/
```

**Lab 3**: [Troubleshooting](laboratorios/lab-03-troubleshooting.md) - 50 min

---

### Fase 9: Troubleshooting (30 min)
**Teoría**: Sección 10 del README

#### Problema 1: ConfigMap no existe

**Síntoma**:
```bash
kubectl get pods
# NAME    READY   STATUS                 RESTARTS   AGE
# myapp   0/1     CreateContainerConfigError   0     10s
```

**Diagnóstico**:
```bash
kubectl describe pod myapp

# Warning  Failed  10s  kubelet  
# Error: configmap "app-config" not found
```

**Solución**:
```bash
# Verificar que existe
kubectl get configmap

# Crear si falta
kubectl create configmap app-config \
  --from-literal=DB_HOST=postgres
```

---

#### Problema 2: Clave no existe en ConfigMap

**Síntoma**: Pod en `CreateContainerConfigError`

**Diagnóstico**:
```bash
kubectl describe pod myapp

# Error: key "DB_HOST" not found in ConfigMap "app-config"
```

**Solución**:
```bash
# Ver claves del ConfigMap
kubectl get configmap app-config -o yaml

# Agregar clave faltante
kubectl edit configmap app-config
```

---

#### Problema 3: ConfigMap actualizado pero Pod no cambia

**Síntoma**: Cambios en ConfigMap no se reflejan en el Pod.

**Causa**: Variables de entorno no se actualizan automáticamente.

**Solución**:
```bash
# Restart del Deployment
kubectl rollout restart deployment myapp

# O eliminar Pods (se recrean)
kubectl delete pod -l app=myapp
```

**Alternativa**: Usar volumeMounts (se actualizan automáticamente).

---

#### Problema 4: Archivo montado vacío o incorrecto

**Síntoma**: Archivo en `/etc/config/app.conf` está vacío.

**Diagnóstico**:
```bash
kubectl exec myapp -- cat /etc/config/app.conf
# (vacío)

kubectl get configmap app-config -o yaml
# data:
#   app.properties: |     ← Clave diferente
#     content...
```

**Causa**: Nombre de clave no coincide.

**Solución**:
```yaml
volumes:
- name: config
  configMap:
    name: app-config
    items:
    - key: app.properties    # Clave correcta del ConfigMap
      path: app.conf         # Nombre del archivo montado
```

---

## 📝 Comandos Esenciales - Cheat Sheet

### Crear ConfigMaps

```bash
# Desde literales
kubectl create configmap <name> \
  --from-literal=KEY1=value1 \
  --from-literal=KEY2=value2

# Desde archivo
kubectl create configmap <name> \
  --from-file=<file-path>

# Desde archivo con clave personalizada
kubectl create configmap <name> \
  --from-file=<key>=<file-path>

# Desde directorio
kubectl create configmap <name> \
  --from-file=<directory>

# Desde YAML
kubectl apply -f configmap.yaml
```

### Ver ConfigMaps

```bash
# Listar ConfigMaps
kubectl get configmaps
kubectl get cm  # Alias

# Ver contenido
kubectl get configmap <name> -o yaml
kubectl describe configmap <name>

# Editar
kubectl edit configmap <name>
```

### Eliminar ConfigMaps

```bash
kubectl delete configmap <name>

# Eliminar múltiples
kubectl delete configmap <name1> <name2>
```

### Usar en Pods

```bash
# Verificar env vars
kubectl exec <pod-name> -- env

# Ver archivo montado
kubectl exec <pod-name> -- cat /etc/config/<file>

# Listar archivos montados
kubectl exec <pod-name> -- ls -la /etc/config/
```

---

## 🎯 Conceptos Clave para Recordar

### 3 Formas de Inyectar Configuración

```
1. ENV VARS:         Valores estáticos en YAML
2. FIELD REFERENCES: Metadata del Pod (namespace, podIP)
3. CONFIGMAPS:       Configuración externalizada
```

### ConfigMaps: Env Vars vs Volumes

```
ENV VARS:
  - Valores simples
  - ❌ No se actualizan automáticamente

VOLUMES:
  - Archivos completos
  - ✅ Se actualizan automáticamente (~60s)
```

### ConfigMaps vs Secrets

```
CONFIGMAP:  Configuración pública (URLs, hosts)
SECRET:     Datos sensibles (passwords, tokens)
```

### ConfigMaps Inmutables

```
immutable: true
  ✅ Mejor performance
  ✅ Previene cambios accidentales
  ❌ No se puede editar (eliminar y recrear)
```

---

## ✅ Checklist de Dominio

Marca cuando domines cada concepto:

### Fundamentos
- [ ] Entiendo el principio de separación configuración/código
- [ ] Sé cuándo usar env vars, ConfigMaps o Secrets
- [ ] Conozco field references (metadata.name, podIP, etc.)
- [ ] Sé cómo se actualizan ConfigMaps en Pods

### Creación
- [ ] Puedo crear ConfigMap desde literales
- [ ] Puedo crear ConfigMap desde archivos
- [ ] Puedo crear ConfigMap desde directorios
- [ ] Sé crear ConfigMaps declarativamente (YAML)

### Consumo
- [ ] Puedo usar ConfigMap como env vars individuales
- [ ] Sé usar envFrom para todas las claves
- [ ] Puedo montar ConfigMap como volumen
- [ ] Sé usar subPath para archivos específicos

### Actualizaciones
- [ ] Entiendo cuándo se actualizan env vars (nunca, requiere restart)
- [ ] Entiendo cuándo se actualizan volumes (automático ~60s)
- [ ] Sé versionar ConfigMaps
- [ ] Puedo hacer rollout restart de Deployments

### Best Practices
- [ ] Separo configuración por entorno
- [ ] Uso nombres descriptivos
- [ ] Versiono ConfigMaps críticos
- [ ] Aplico ConfigMaps inmutables en producción
- [ ] Combino múltiples fuentes de configuración

### Troubleshooting
- [ ] Diagnostico "ConfigMap not found"
- [ ] Resuelvo "key not found in ConfigMap"
- [ ] Sé forzar actualización de Pods
- [ ] Verifico archivos montados con kubectl exec

### Práctica
- [ ] Completé Lab 01: Env Vars y Field Ref
- [ ] Completé Lab 02: ConfigMaps Avanzado
- [ ] Completé Lab 03: Troubleshooting
- [ ] Apliqué ConfigMaps en apps propias

---

## 🎓 Evaluación Final

### Preguntas Clave
1. ¿Cuál es la diferencia entre env vars y ConfigMaps?
2. ¿Qué son field references y para qué sirven?
3. ¿Qué pasa si actualizas un ConfigMap usado como env vars?
4. ¿Cuándo usar ConfigMaps inmutables?
5. ¿Cómo montar un archivo específico de un ConfigMap?

<details>
<summary>Ver Respuestas</summary>

1. **Env vars vs ConfigMaps**:
   - **Env vars**: Valores estáticos definidos en el YAML del Pod
   - **ConfigMaps**: Configuración externalizada, reutilizable entre Pods
   - ConfigMaps permiten separación configuración/código

2. **Field references**:
   - Acceden a metadata del Pod como variables de entorno
   - Ejemplos: `metadata.name`, `status.podIP`, `metadata.namespace`
   - Uso: Logging contextual, distributed tracing, service discovery

3. **Actualizar ConfigMap (env vars)**:
   - Variables de entorno **NO se actualizan automáticamente**
   - Requiere restart del Pod o rollout del Deployment
   - Alternativa: Usar volumeMounts (se actualizan automáticamente)

4. **ConfigMaps inmutables**:
   - Mejor performance (kubelet no watch cambios)
   - Previene cambios accidentales
   - Estabilidad en producción
   - Usar cuando configuración es estable

5. **Montar archivo específico**:
   ```yaml
   volumeMounts:
   - name: config
     mountPath: /etc/nginx/nginx.conf
     subPath: nginx.conf    # Solo este archivo
   volumes:
   - name: config
     configMap:
       name: nginx-config
       items:
       - key: nginx.conf
         path: nginx.conf
   ```

</details>

---

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Configure Pods Using ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

### Labs del Módulo
1. [Lab 01 - Env Vars y Field Ref](laboratorios/lab-01-env-vars-field-ref.md) - 40 min
2. [Lab 02 - ConfigMaps Avanzado](laboratorios/lab-02-configmaps-avanzado.md) - 60 min
3. [Lab 03 - Troubleshooting](laboratorios/lab-03-troubleshooting.md) - 50 min

### Ejemplos Prácticos
- [`ejemplos/01-env-vars-basicas/`](ejemplos/01-env-vars-basicas/) - Variables estáticas
- [`ejemplos/02-field-references/`](ejemplos/02-field-references/) - Metadata del Pod
- [`ejemplos/03-configmap-literal/`](ejemplos/03-configmap-literal/) - Desde literales
- [`ejemplos/04-configmap-file/`](ejemplos/04-configmap-file/) - Desde archivos
- [`ejemplos/05-configmap-env/`](ejemplos/05-configmap-env/) - Como env vars
- [`ejemplos/06-configmap-volume/`](ejemplos/06-configmap-volume/) - Como volúmenes
- [`ejemplos/07-combinados/`](ejemplos/07-combinados/) - Múltiples fuentes

### Siguiente Módulo
➡️ Módulo 14: Secrets y Datos Sensibles

---

## 🎉 ¡Felicitaciones!

Has completado el Módulo 13 de ConfigMaps y Variables de Entorno. Ahora puedes:

- ✅ Separar configuración del código (12-Factor App)
- ✅ Usar variables de entorno y field references
- ✅ Crear y consumir ConfigMaps (env vars y volumes)
- ✅ Gestionar actualizaciones de configuración
- ✅ Aplicar best practices (versionado, inmutables)
- ✅ Troubleshoot problemas de configuración

**Próximos pasos**:
1. Revisar este resumen periódicamente
2. Completar los 3 laboratorios prácticos
3. Migrar hardcoded config a ConfigMaps en apps existentes
4. Implementar GitOps para gestión de ConfigMaps
5. Continuar con Módulo 14: Secrets

¡Sigue adelante! 🚀
