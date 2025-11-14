# Laboratorio 3: Troubleshooting ConfigMaps

## Objetivos

✅ Diagnosticar problemas comunes con ConfigMaps  
✅ Resolver errores de referencias  
✅ Depurar actualización de configuración  
✅ Aplicar mejores prácticas

**Duración estimada**: 45 minutos

---

## Problema 1: ConfigMap No Existe

### Escenario

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: broken-pod
spec:
  containers:
  - name: app
    image: nginx:alpine
    envFrom:
    - configMapRef:
        name: missing-config  # ❌ No existe
EOF
```

### Diagnóstico

```bash
kubectl get pods
# NAME         READY   STATUS                  RESTARTS
# broken-pod   0/1     CreateContainerConfigError

kubectl describe pod broken-pod | tail -15
# Warning  Failed  10s  kubelet  Error: configmap "missing-config" not found
```

### Solución

```bash
# Opción 1: Crear el ConfigMap
kubectl create configmap missing-config --from-literal=key=value

# Opción 2: Hacer la referencia opcional
kubectl delete pod broken-pod

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: fixed-pod
spec:
  containers:
  - name: app
    image: nginx:alpine
    envFrom:
    - configMapRef:
        name: missing-config
        optional: true  # ✅ Pod arranca aunque no exista
EOF
```

---

## Problema 2: Clave No Existe

### Escenario

```bash
# ConfigMap solo tiene 'app.port'
kubectl create configmap partial-config --from-literal=app.port=8080

# Pod referencia clave inexistente
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: missing-key-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    env:
    - name: APP_PORT
      valueFrom:
        configMapKeyRef:
          name: partial-config
          key: app.port  # ✅ Existe
    
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: partial-config
          key: database.host  # ❌ NO existe
EOF
```

### Diagnóstico

```bash
kubectl get pod missing-key-pod
# STATUS: CreateContainerConfigError

kubectl describe pod missing-key-pod | grep -A5 Events
# Warning  Failed  key "database.host" not found in ConfigMap default/partial-config
```

### Solución

```yaml
# Agregar optional: true
env:
- name: DB_HOST
  valueFrom:
    configMapKeyRef:
      name: partial-config
      key: database.host
      optional: true  # ✅ No falla si falta la clave
```

---

## Problema 3: ConfigMap No Se Actualiza

### Escenario

```bash
# 1. Crear ConfigMap
kubectl create configmap app-version --from-literal=version=1.0

# 2. Pod con variable
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: version-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "while true; do echo Version: \$APP_VERSION; sleep 5; done"]
    env:
    - name: APP_VERSION
      valueFrom:
        configMapKeyRef:
          name: app-version
          key: version
EOF

# 3. Ver versión actual
kubectl logs version-pod --tail=1
# Version: 1.0

# 4. Actualizar ConfigMap
kubectl patch configmap app-version --patch '{"data":{"version":"2.0"}}'

# 5. Esperar... pero sigue mostrando 1.0!
sleep 10
kubectl logs version-pod --tail=1
# Version: 1.0  ← ❌ No cambió
```

### Explicación

**Variables de entorno NO se actualizan automáticamente**. Se inyectan al crear el contenedor y quedan fijas.

### Solución

```bash
# Opción 1: Recrear Pod
kubectl delete pod version-pod
kubectl apply -f ...

# Opción 2: Usar Deployment y hacer rollout restart
kubectl rollout restart deployment/myapp
```

---

## Problema 4: Volumen con subPath No Actualiza

### Escenario

```yaml
kubectl create configmap nginx-conf --from-literal=nginx.conf="server { listen 8080; }"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx-subpath
spec:
  containers:
  - name: web
    image: nginx:alpine
    volumeMounts:
    - name: config
      mountPath: /etc/nginx/conf.d
  volumes:
  - name: config
    configMap:
      name: nginx-conf
EOF
```

Actualizar ConfigMap:

```bash
kubectl patch configmap nginx-conf \
  --patch '{"data":{"nginx.conf":"server { listen 9090; }"}}'

# Esperar 90 segundos...
sleep 90

# Verificar... sigue siendo 8080!
kubectl exec nginx-subpath -- cat /etc/nginx/nginx.conf
# server { listen 8080; }  ← ❌ No cambió
```

### Solución

**Opción 1**: Eliminar `subPath` (pero monta todo el directorio)

```yaml
volumeMounts:
- name: config
  mountPath: /etc/nginx/conf.d  # Sin subPath
```

**Opción 2**: Recrear Pod después de actualizar ConfigMap

```bash
kubectl delete pod nginx-subpath
kubectl apply -f ...
```

**Opción 3**: Usar sidecar con inotify (avanzado)

---

## Problema 5: Nombres Inválidos en envFrom

### Escenario

```bash
kubectl create configmap invalid-keys \
  --from-literal=my-database-host=postgres \
  --from-literal=cache.enabled=true

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: invalid-env
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | sort && sleep 3600"]
    envFrom:
    - configMapRef:
        name: invalid-keys
EOF
```

### Diagnóstico

```bash
kubectl exec invalid-env -- env | grep -E '(database|cache)'
# (vacío)  ← ❌ Las claves NO aparecen

kubectl logs invalid-env | grep -i warn
# Warning: keys with invalid format for environment variables are skipped
```

**Razón**: `my-database-host` tiene guiones (`-`), no permitidos en env vars.

### Solución

**Opción 1**: Renombrar claves (usar guiones bajos)

```bash
kubectl delete configmap invalid-keys

kubectl create configmap valid-keys \
  --from-literal=my_database_host=postgres \
  --from-literal=cache_enabled=true
```

**Opción 2**: Usar `env` individual y renombrar

```yaml
env:
- name: DATABASE_HOST
  valueFrom:
    configMapKeyRef:
      name: invalid-keys
      key: my-database-host  # Mapear a nombre válido
```

---

## Checklist de Troubleshooting

```
[ ] ¿El ConfigMap existe? → kubectl get configmap <name>
[ ] ¿La clave existe en el ConfigMap? → kubectl describe configmap <name>
[ ] ¿El nombre de la clave es válido para env vars? (solo a-zA-Z0-9_)
[ ] ¿El Pod está en el mismo namespace que el ConfigMap?
[ ] ¿Esperaste suficiente para que se actualice el volumen? (~60-90s)
[ ] ¿Usas subPath? (impide auto-update)
[ ] ¿Usas variables ENV? (nunca se actualizan)
```

---

## Ejercicio Final

Identifica y corrige todos los errores:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: broken-config
data:
  database-host: "postgres"  # ❌ Guión
  port: "5432"  # ✅ OK
---
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env && sleep 3600"]
    
    envFrom:
    - configMapRef:
        name: broken-confg  # ❌ Typo
    
    env:
    - name: DB_PASSWORD
      valueFrom:
        configMapKeyRef:
          name: broken-config
          key: password  # ❌ No existe
```

<details>
<summary>💡 Solución</summary>

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: broken-config
data:
  database_host: "postgres"  # ✅ Guión bajo
  port: "5432"
  password: "secret"  # ✅ Agregar
---
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env && sleep 3600"]
    
    envFrom:
    - configMapRef:
        name: broken-config  # ✅ Nombre correcto
    
    env:
    - name: DB_PASSWORD
      valueFrom:
        configMapKeyRef:
          name: broken-config
          key: password
          optional: true  # ✅ O agregar la clave
```

</details>

---

## Comandos Útiles

```bash
# Ver ConfigMap completo
kubectl get configmap <name> -o yaml

# Comparar antes/después
kubectl diff -f configmap-updated.yaml

# Ver eventos del Pod
kubectl get events --field-selector involvedObject.name=<pod-name>

# Debugging interactivo
kubectl exec -it <pod-name> -- sh
env | sort
ls -la /etc/config/
cat /etc/config/my-file
```

---

## Limpieza

```bash
kubectl delete pod broken-pod fixed-pod missing-key-pod version-pod nginx-subpath invalid-env debug-pod
kubectl delete configmap missing-config partial-config app-version nginx-conf invalid-keys valid-keys broken-config
```

---

## Resumen

✅ ConfigMap no existe → Crear o marcar `optional: true`  
✅ Clave no existe → Marcar `optional: true`  
✅ Variables ENV no actualizan → Recrear Pod/Deployment  
✅ Volumen con subPath no actualiza → Eliminar subPath o recrear Pod  
✅ Claves con guiones en envFrom → Renombrar a guiones bajos

**Has completado el módulo!** 🎉
