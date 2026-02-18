# Helm Hooks Example

Demostración completa de Helm Hooks para automatizar tareas en el ciclo de vida de releases.

## 🎯 ¿Qué son los Hooks?

Los hooks son trabajos (Jobs) que se ejecutan en momentos específicos del ciclo de vida:

```
INSTALL WORKFLOW:
  1. pre-install hook    ← Ejecuta antes de instalar
  2. Install resources   ← Crea Deployments, Services, etc.
  3. post-install hook   ← Ejecuta después de instalar

UPGRADE WORKFLOW:
  1. pre-upgrade hook    ← Backup, preparación
  2. Upgrade resources   ← Actualiza recursos
  3. post-upgrade hook   ← Migraciones, cleanup
```

## 📋 Hooks Incluidos

### 1. Pre-Install Hook
```yaml
annotations:
  "helm.sh/hook": pre-install
  "helm.sh/hook-weight": "-5"
  "helm.sh/hook-delete-policy": before-hook-creation
```

**Ejecuta**: Antes de instalar la aplicación  
**Uso**: Verificar requisitos, crear namespaces, preparar secrets

### 2. Post-Install Hook
```yaml
annotations:
  "helm.sh/hook": post-install
  "helm.sh/hook-weight": "5"
  "helm.sh/hook-delete-policy": hook-succeeded
```

**Ejecuta**: Después de instalar  
**Uso**: Seed de datos, configuración inicial, notificaciones

### 3. Pre-Upgrade Hook
```yaml
annotations:
  "helm.sh/hook": pre-upgrade
  "helm.sh/hook-weight": "-5"
```

**Ejecuta**: Antes de actualizar  
**Uso**: Backup de database, verificar compatibilidad

### 4. Post-Upgrade Hook
```yaml
annotations:
  "helm.sh/hook": post-upgrade
  "helm.sh/hook-weight": "5"
```

**Ejecuta**: Después de actualizar  
**Uso**: Migraciones de database, limpiar cache

## 🚀 Uso

### Instalación Inicial

```bash
# Instalar con hooks habilitados
helm install myapp .

# Ver ejecución de hooks
kubectl get jobs
kubectl logs job/myapp-pre-install
kubectl logs job/myapp-post-install
```

### Upgrade con Hooks

```bash
# Hacer upgrade
helm upgrade myapp . --set replicaCount=3

# Ver hooks de upgrade
kubectl get jobs
kubectl logs job/myapp-pre-upgrade-2
kubectl logs job/myapp-post-upgrade-2
```

### Deshabilitar Hooks

```bash
# Instalar sin hooks
helm install myapp . \
  --set hooks.preInstall.enabled=false \
  --set hooks.postInstall.enabled=false
```

## 🔧 Hook Annotations

### helm.sh/hook
Tipo de hook:
- `pre-install` - Antes de install
- `post-install` - Después de install
- `pre-upgrade` - Antes de upgrade
- `post-upgrade` - Después de upgrade
- `pre-delete` - Antes de uninstall
- `post-delete` - Después de uninstall
- `pre-rollback` - Antes de rollback
- `post-rollback` - Después de rollback
- `test` - Para tests (`helm test`)

### helm.sh/hook-weight
Orden de ejecución (menor = primero):
- `-10` - Primero
- `0` - Default
- `10` - Último

### helm.sh/hook-delete-policy
Cuándo eliminar el Job:
- `before-hook-creation` - Antes de crear nuevo hook
- `hook-succeeded` - Si tiene éxito
- `hook-failed` - Si falla

## 📚 Ejemplos Reales

### Database Migration Hook

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-migrate
  annotations:
    "helm.sh/hook": post-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: myapp/migrations:{{ .Values.image.tag }}
        command: ["./migrate.sh", "up"]
        env:
        - name: DATABASE_URL
          value: postgres://...
```

### Backup Hook

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-backup
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "-10"
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: backup
        image: postgres:14
        command:
          - /bin/sh
          - -c
          - |
            pg_dump -h database -U user mydb > /backup/backup.sql
            echo "Backup completado"
```

### Notification Hook

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-notify
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-weight": "10"
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: notify
        image: curlimages/curl
        command:
          - curl
          - -X
          - POST
          - https://hooks.slack.com/...
          - -d
          - '{"text":"Deployment completed!"}'
```

## 🔍 Debugging Hooks

```bash
# Ver todos los jobs
kubectl get jobs

# Ver logs de hook específico
kubectl logs job/myapp-pre-install

# Ver hooks fallidos
kubectl get jobs --field-selector status.successful=0

# Describir hook
kubectl describe job myapp-pre-install

# Eliminar hooks manualmente
kubectl delete job -l hook=pre-install
```

## ⚠️ Consideraciones

1. **Timeout**: Los hooks tienen timeout (default 5 minutos)
2. **Failures**: Si un hook falla, el release falla
3. **Cleanup**: Usar `hook-delete-policy` para limpiar automáticamente
4. **Order**: Usar `hook-weight` para orden específico
5. **Multiple**: Puedes tener múltiples hooks del mismo tipo

## 🎯 Best Practices

✅ **DO**:
- Usar `restartPolicy: Never` en Jobs
- Agregar timeout apropiado
- Hacer hooks idempotentes
- Usar `hook-delete-policy` para cleanup
- Loguear claramente qué hace el hook

❌ **DON'T**:
- Hacer hooks muy largos (>5 min)
- Asumir orden sin usar `hook-weight`
- Dejar hooks fallidos acumulados
- Hardcodear valores en hooks

## ✅ Testing

```bash
# Install y ver hooks
helm install test . --wait
kubectl get jobs
kubectl logs -l hook=pre-install

# Upgrade y verificar
helm upgrade test . --set replicaCount=3 --wait
kubectl logs -l hook=pre-upgrade
kubectl logs -l hook=post-upgrade

# Cleanup
helm uninstall test
kubectl delete jobs -l app=helm-hooks
```
