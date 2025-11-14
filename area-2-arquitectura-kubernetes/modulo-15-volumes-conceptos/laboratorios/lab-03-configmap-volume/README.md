# 📄 Lab 03: ConfigMap Volume - Configuración como Archivos

## 📋 Objetivo

Aprender a montar ConfigMaps como volúmenes para inyectar configuración como archivos dentro de Pods.

**Conceptos clave**:
- Desacoplar configuración del código
- Montar ConfigMaps como archivos
- Actualización automática de configuración
- Proyección selectiva de keys

---

## ⏱️ Duración Estimada

- **Nivel**: 🟢 Principiante  
- **Tiempo**: 20-25 minutos
- **Comandos**: ~16

---

## 🎯 Escenarios de Aprendizaje

### Escenario 1: Archivo de Configuración de Aplicación

ConfigMap con `app.conf` montado en `/etc/config/`

### Escenario 2: Múltiples Archivos de Configuración

Varios archivos (nginx.conf, database.ini, logging.yaml) en un solo volumen

### Escenario 3: Proyección Selectiva de Keys

Montar solo algunas keys del ConfigMap, no todas

---

## 📝 Paso a Paso

### 1️⃣ ConfigMap Simple como Volumen

**Crear ConfigMap**:

```bash
kubectl create configmap app-config \
  --from-literal=database.host=mysql.example.com \
  --from-literal=database.port=3306 \
  --from-literal=log.level=INFO
```

**Archivo**: `pod-configmap-volume.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap-volume
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c"]
    args:
      - while true; do
          echo "=== Config files ===";
          ls -la /etc/config/;
          echo "";
          echo "=== database.host ===";
          cat /etc/config/database.host;
          echo "";
          echo "=== log.level ===";
          cat /etc/config/log.level;
          sleep 15;
        done
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

**Aplicar**:

```bash
kubectl apply -f pod-configmap-volume.yaml
```

**Verificar logs**:

```bash
kubectl logs pod-configmap-volume --tail=20
```

**Salida esperada**:
```
=== Config files ===
total 0
lrwxrwxrwx 1 root root 20 Nov 13 10:40 database.host -> ..data/database.host
lrwxrwxrwx 1 root root 20 Nov 13 10:40 database.port -> ..data/database.port
lrwxrwxrwx 1 root root 17 Nov 13 10:40 log.level -> ..data/log.level

=== database.host ===
mysql.example.com

=== log.level ===
INFO
```

**📌 Cada key del ConfigMap se convierte en un archivo**

---

### 2️⃣ ConfigMap desde Archivo

**Crear archivo de configuración**:

```bash
cat > nginx.conf <<EOF
server {
    listen 80;
    server_name example.com;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    
    location /api {
        proxy_pass http://backend:8080;
    }
}
EOF
```

**Crear ConfigMap desde archivo**:

```bash
kubectl create configmap nginx-config --from-file=nginx.conf
```

**Archivo**: `pod-nginx-configmap.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx-configmap
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: nginx-config-volume
      mountPath: /etc/nginx/conf.d
  
  volumes:
  - name: nginx-config-volume
    configMap:
      name: nginx-config
```

**Aplicar y verificar**:

```bash
kubectl apply -f pod-nginx-configmap.yaml

# Verificar que nginx leyó la config
kubectl exec pod-nginx-configmap -- cat /etc/nginx/conf.d/nginx.conf

# Verificar logs de nginx
kubectl logs pod-nginx-configmap
```

---

### 3️⃣ Proyección Selectiva de Keys

**Crear ConfigMap con múltiples keys**:

```bash
kubectl create configmap multi-config \
  --from-literal=public.api.key=abc123 \
  --from-literal=private.secret=supersecret \
  --from-literal=database.url=postgres://db:5432 \
  --from-literal=cache.ttl=3600
```

**Archivo**: `pod-selective-keys.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-selective-keys
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "ls -la /config && cat /config/* && sleep 3600"]
    volumeMounts:
    - name: config-volume
      mountPath: /config
  
  volumes:
  - name: config-volume
    configMap:
      name: multi-config
      items:  # Proyectar solo algunas keys
      - key: public.api.key
        path: api-key.txt
      - key: database.url
        path: db-connection.txt
      # private.secret y cache.ttl NO se montan
```

**Aplicar y verificar**:

```bash
kubectl apply -f pod-selective-keys.yaml

# Ver archivos montados (solo 2 de 4 keys)
kubectl exec pod-selective-keys -- ls -la /config

# Verificar contenido
kubectl exec pod-selective-keys -- cat /config/api-key.txt
kubectl exec pod-selective-keys -- cat /config/db-connection.txt
```

**Salida esperada**:
```
total 0
lrwxrwxrwx 1 root root 18 Nov 13 10:45 api-key.txt -> ..data/api-key.txt
lrwxrwxrwx 1 root root 24 Nov 13 10:45 db-connection.txt -> ..data/db-connection.txt
```

---

### 4️⃣ Permisos de Archivos Personalizados

**Archivo**: `pod-config-permissions.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-config-permissions
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "ls -la /etc/config && sleep 3600"]
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  
  volumes:
  - name: config-volume
    configMap:
      name: app-config
      defaultMode: 0400  # Solo lectura para el owner (octal)
```

**Aplicar y verificar**:

```bash
kubectl apply -f pod-config-permissions.yaml

# Ver permisos (debería ser r-- para owner)
kubectl exec pod-config-permissions -- ls -la /etc/config
```

**Salida esperada**:
```
lrwxrwxrwx 1 root root 20 ... database.host -> ..data/database.host
-r-------- 1 root root 20 ... (archivos con permisos 0400)
```

---

### 5️⃣ Actualización Automática de ConfigMap

**Crear ConfigMap inicial**:

```bash
kubectl create configmap dynamic-config --from-literal=version=1.0
```

**Archivo**: `pod-dynamic-config.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-dynamic-config
spec:
  containers:
  - name: watcher
    image: busybox
    command: ["sh", "-c"]
    args:
      - while true; do
          echo "Current config:";
          cat /config/version;
          sleep 5;
        done
    volumeMounts:
    - name: config-volume
      mountPath: /config
  
  volumes:
  - name: config-volume
    configMap:
      name: dynamic-config
```

**Aplicar y observar**:

```bash
kubectl apply -f pod-dynamic-config.yaml

# Ver logs (versión 1.0)
kubectl logs pod-dynamic-config --tail=5
```

**Actualizar ConfigMap**:

```bash
kubectl create configmap dynamic-config \
  --from-literal=version=2.0 \
  --dry-run=client -o yaml | kubectl apply -f -
```

**Esperar ~60 segundos y verificar logs nuevamente**:

```bash
kubectl logs pod-dynamic-config --tail=10
```

**📌 El archivo se actualiza automáticamente** (puede tardar hasta 1 minuto por kubelet sync)

---

## 🔍 Troubleshooting

### Problema 1: ConfigMap No Encontrado

**Síntoma**:
```
Warning  FailedMount  pod/my-pod  configmap "app-config" not found
```

**Diagnóstico**:

```bash
kubectl get configmap
```

**Solución**: Crear el ConfigMap antes del Pod.

---

### Problema 2: Archivos No Se Actualizan

**Síntoma**: ConfigMap actualizado pero Pod sigue viendo valores antiguos.

**Causas posibles**:
1. **SubPath mounts**: No se actualizan automáticamente
2. **Caché de kubelet**: Puede tardar hasta 60s

**Solución**:

```bash
# Opción 1: Esperar ~1 minuto
sleep 60

# Opción 2: Reiniciar el Pod
kubectl delete pod pod-dynamic-config
kubectl apply -f pod-dynamic-config.yaml

# Opción 3: No usar subPath
# En lugar de:
# volumeMounts:
#   - name: config
#     mountPath: /app/config.txt
#     subPath: config.txt  # ❌ No se actualiza

# Usar:
# volumeMounts:
#   - name: config
#     mountPath: /app/config/  # ✅ Se actualiza
```

---

### Problema 3: Permisos Incorrectos

**Síntoma**: Aplicación no puede leer archivos de configuración.

**Solución**:

```yaml
volumes:
- name: config-volume
  configMap:
    name: app-config
    defaultMode: 0644  # rw-r--r--
```

---

## 📊 Resumen de Conceptos

| Aspecto | ConfigMap Volume | Detalles |
|---------|------------------|----------|
| **Actualización** | ✅ Automática | ~60s delay (sin subPath) |
| **Proyección** | Selectiva | Montar solo keys específicas |
| **Permisos** | Configurables | `defaultMode` |
| **Formato** | Archivos | Cada key = 1 archivo |
| **Casos de uso** | Configs, scripts | Nginx, app configs, scripts |

---

## ✅ Verificación de Aprendizaje

**Checklist**:

- [ ] ✅ Monté un ConfigMap completo como volumen
- [ ] ✅ Creé ConfigMap desde archivo y lo monté
- [ ] ✅ Proyecté solo algunas keys seleccionadas
- [ ] ✅ Configuré permisos personalizados con `defaultMode`
- [ ] ✅ Observé actualización automática de ConfigMap
- [ ] ✅ Entiendo cuándo usar ConfigMap volume vs envFrom

---

## 🎓 Preguntas de Repaso

1. **¿Qué sucede si actualizas un ConfigMap montado como volumen?**
   <details>
   <summary>Ver respuesta</summary>
   
   Los archivos se actualizan **automáticamente** dentro del Pod después de ~60 segundos (sincronización de kubelet). **Excepción**: Si usas `subPath`, NO se actualiza.
   </details>

2. **¿Cómo montar solo algunas keys de un ConfigMap?**
   <details>
   <summary>Ver respuesta</summary>
   
   Usa `items` en la definición del volumen:
   ```yaml
   volumes:
   - name: config
     configMap:
       name: my-config
       items:
       - key: database.url
         path: db.txt
   ```
   </details>

3. **¿ConfigMap volume vs variables de entorno?**
   <details>
   <summary>Ver respuesta</summary>
   
   - **Volume**: Archivos, actualización automática, útil para configs complejas
   - **EnvFrom**: Variables de entorno, NO se actualizan, útil para configs simples
   </details>

---

## 🔗 Recursos Adicionales

- [ConfigMap Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#configmap)
- [Configure Pods Using ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
- [Projected Volumes](https://kubernetes.io/docs/concepts/storage/projected-volumes/)

---

## 🧹 Limpieza

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete pod pod-configmap-volume pod-nginx-configmap pod-selective-keys \
  pod-config-permissions pod-dynamic-config
kubectl delete configmap app-config nginx-config multi-config dynamic-config
rm -f nginx.conf
```

---

## 📚 Módulo Completo

✅ **Lab 01**: EmptyDir - Almacenamiento temporal  
✅ **Lab 02**: HostPath - Acceso al nodo  
✅ **Lab 03**: ConfigMap Volume - Configuración como archivos

➡️ **Siguiente Módulo**: M16 - Volumes Tipos Storage (PV, PVC, StorageClass)

---

**🎯 Has completado el Lab 03 - ConfigMap Volume**

¡Felicidades! Dominaste los volúmenes conceptuales básicos de Kubernetes. Ahora estás listo para storage persistente avanzado. 🚀
