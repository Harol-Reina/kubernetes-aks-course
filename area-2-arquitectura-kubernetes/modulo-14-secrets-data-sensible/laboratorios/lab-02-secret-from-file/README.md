# Lab 02: Secret from File - Crear Secrets desde Archivos

## 📋 Información del Laboratorio

- **Módulo**: 14 - Secrets & Sensitive Data
- **Laboratorio**: 02 - Secret from File
- **Dificultad**: 🟢 Principiante
- **Tiempo estimado**: 20-25 minutos

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:
- ✅ Crear Secrets desde archivos existentes
- ✅ Crear Secrets desde múltiples archivos a la vez
- ✅ Montar secrets como volumen con archivos individuales
- ✅ Usar secrets para configurar aplicaciones web
- ✅ Entender cómo los archivos se convierten en claves del Secret

## 📚 Prerrequisitos

Antes de comenzar, asegúrate de haber completado:
- ✅ [SETUP.md](./SETUP.md) - Configuración del entorno
- ✅ Lab 01: Secret Básico

## 🔧 Escenario del Laboratorio

Vas a configurar un servidor web nginx que use HTTPS. Para esto necesitas:
- Certificado TLS (archivo `.crt`)
- Clave privada (archivo `.key`)
- Configuración de nginx (archivo `.conf`)

Almacenarás estos archivos sensibles en un Secret y los montarás en el pod de nginx.

---

## 📝 Paso 1: Preparar Archivos de Configuración

### 1.1. Crear Directorio de Trabajo

```bash
# Crear directorio para archivos
mkdir -p ~/k8s-labs/lab-secrets-files
cd ~/k8s-labs/lab-secrets-files
```

### 1.2. Generar Certificado Auto-firmado (Para Testing)

```bash
# Generar clave privada
openssl genrsa -out tls.key 2048

# Generar certificado auto-firmado
openssl req -new -x509 -key tls.key -out tls.crt -days 365 \
  -subj "/CN=myapp.local/O=MyCompany"
```

**Explicación**:
- `tls.key`: Clave privada RSA de 2048 bits
- `tls.crt`: Certificado público válido por 365 días
- `/CN=myapp.local`: Common Name (nombre de dominio)

### 1.3. Crear Configuración de nginx

```bash
# Crear archivo nginx.conf
cat > nginx.conf << 'EOF'
server {
    listen 443 ssl;
    server_name myapp.local;
    
    ssl_certificate     /etc/nginx/ssl/tls.crt;
    ssl_certificate_key /etc/nginx/ssl/tls.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location / {
        root   /usr/share/nginx/html;
        index  index.html;
    }
}
EOF
```

### 1.4. Crear Archivo README (Documentación)

```bash
# Crear archivo de documentación
cat > README.txt << 'EOF'
TLS Configuration for MyApp
============================
Generated: 2025-11-13
Validity: 365 days
Common Name: myapp.local

Security Notes:
- This is a self-signed certificate
- Use only for development/testing
- Replace with CA-signed cert in production
EOF
```

### 1.5. Verificar Archivos Creados

```bash
# Listar archivos
ls -lh

# Ver contenido del certificado
openssl x509 -in tls.crt -text -noout | head -20
```

**Archivos esperados**:
```
tls.key       (clave privada, ~1.7K)
tls.crt       (certificado, ~1.2K)
nginx.conf    (configuración nginx)
README.txt    (documentación)
```

---

## 📝 Paso 2: Crear Secret desde Archivos

### 2.1. Crear Secret con UN Archivo

```bash
# Crear secret con solo el certificado
kubectl create secret generic tls-cert \
  --from-file=tls.crt
```

**Explicación**:
- `--from-file=tls.crt`: Nombre de archivo se convierte en clave
- Contenido del archivo se convierte en valor
- El archivo mantiene su nombre original

### 2.2. Crear Secret con MÚLTIPLES Archivos

```bash
# Crear secret con certificado Y clave privada
kubectl create secret generic tls-keypair \
  --from-file=tls.crt \
  --from-file=tls.key
```

### 2.3. Crear Secret con TODOS los Archivos de un Directorio

```bash
# Crear secret con todos los archivos del directorio actual
kubectl create secret generic nginx-config \
  --from-file=.
```

**Nota**: Esto incluye `tls.crt`, `tls.key`, `nginx.conf`, y `README.txt`

### 2.4. Crear Secret con Nombre de Clave Personalizado

```bash
# Crear secret con nombre de clave diferente al archivo
kubectl create secret generic app-cert \
  --from-file=certificate=tls.crt \
  --from-file=private-key=tls.key
```

**Explicación**:
- `certificate=tls.crt`: La clave se llamará `certificate`
- `private-key=tls.key`: La clave se llamará `private-key`

---

## 📝 Paso 3: Inspeccionar los Secrets Creados

### 3.1. Listar Secrets

```bash
# Ver todos los secrets creados
kubectl get secrets
```

**Salida esperada**:
```
NAME            TYPE     DATA   AGE
tls-cert        Opaque   1      1m
tls-keypair     Opaque   2      1m
nginx-config    Opaque   4      1m
app-cert        Opaque   2      1m
```

### 3.2. Ver Detalles del Secret nginx-config

```bash
# Describir el secret
kubectl describe secret nginx-config
```

**Observa**:
- 4 claves (4 archivos)
- Nombres de claves = nombres de archivos
- Tamaños aproximados de cada archivo

### 3.3. Ver Contenido del Secret

```bash
# Ver en formato YAML
kubectl get secret nginx-config -o yaml
```

**Observa**:
- Cada archivo está codificado en base64
- `data` contiene todas las claves

### 3.4. Decodificar un Archivo del Secret

```bash
# Decodificar nginx.conf
kubectl get secret nginx-config -o jsonpath='{.data.nginx\.conf}' | base64 --decode

# Decodificar README.txt
kubectl get secret nginx-config -o jsonpath='{.data.README\.txt}' | base64 --decode
```

---

## 📝 Paso 4: Usar el Secret en un Pod de Nginx

### 4.1. Crear Manifiesto del Pod

Crea el archivo `nginx-https.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-https
  labels:
    app: nginx-secure
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 443
      name: https
    volumeMounts:
    - name: nginx-config-vol
      mountPath: /etc/nginx/conf.d
      readOnly: true
    - name: tls-certs
      mountPath: /etc/nginx/ssl
      readOnly: true
  
  volumes:
  - name: nginx-config-vol
    secret:
      secretName: nginx-config
      items:
      - key: nginx.conf
        path: default.conf
  
  - name: tls-certs
    secret:
      secretName: nginx-config
      items:
      - key: tls.crt
        path: tls.crt
      - key: tls.key
        path: tls.key
        mode: 0600  # Solo lectura para el propietario
```

**Explicación**:
- Dos volumeMounts: uno para config, otro para certificados
- `items`: Selecciona archivos específicos del secret
- `path`: Nombre de archivo en el pod (puede ser diferente)
- `mode: 0600`: Permisos restrictivos para clave privada

### 4.2. Aplicar el Manifiesto

```bash
# Crear el pod
kubectl apply -f nginx-https.yaml

# Esperar a que esté running
kubectl wait --for=condition=Ready pod/nginx-https --timeout=60s
```

### 4.3. Verificar el Pod

```bash
# Ver estado del pod
kubectl get pod nginx-https

# Ver logs
kubectl logs nginx-https
```

---

## 📝 Paso 5: Verificar Configuración Dentro del Pod

### 5.1. Conectarse al Pod

```bash
# Abrir shell interactivo
kubectl exec -it nginx-https -- sh
```

### 5.2. Verificar Archivos de Configuración

```bash
# Listar archivos de configuración
ls -la /etc/nginx/conf.d/

# Ver contenido de la configuración
cat /etc/nginx/conf.d/default.conf

# Listar certificados SSL
ls -la /etc/nginx/ssl/

# Verificar permisos de la clave privada
ls -l /etc/nginx/ssl/tls.key
```

**Salida esperada**:
```
-rw------- 1 root root 1704 Nov 13 22:00 tls.key
```

### 5.3. Verificar que Nginx Cargó la Configuración

```bash
# Verificar sintaxis de nginx
nginx -t

# Ver procesos de nginx
ps aux | grep nginx

# Salir del pod
exit
```

---

## 📝 Paso 6: Probar el Servidor HTTPS

### 6.1. Hacer Port-Forward del Pod

```bash
# Crear túnel al puerto 443
kubectl port-forward pod/nginx-https 8443:443 &
```

### 6.2. Probar con curl

```bash
# Probar HTTPS (aceptando certificado auto-firmado)
curl -k https://localhost:8443

# Ver detalles del certificado
curl -kv https://localhost:8443 2>&1 | grep "subject:"
```

**Salida esperada**:
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

### 6.3. Detener Port-Forward

```bash
# Detener el proceso en background
pkill -f "port-forward.*nginx-https"
```

---

## ✅ Verificación del Laboratorio

### Checklist de Validación

```bash
# 1. Secrets creados correctamente
kubectl get secret nginx-config -o jsonpath='{.data}' | jq 'keys'

# 2. Pod running
kubectl get pod nginx-https -o wide

# 3. Archivos montados correctamente
kubectl exec nginx-https -- ls -la /etc/nginx/conf.d/
kubectl exec nginx-https -- ls -la /etc/nginx/ssl/

# 4. Permisos correctos en clave privada
kubectl exec nginx-https -- stat -c "%a %n" /etc/nginx/ssl/tls.key

# 5. Nginx funcionando con TLS
kubectl exec nginx-https -- nginx -t
```

**Resultados esperados**:
- ✅ Secret tiene 4 claves
- ✅ Pod en estado `Running`
- ✅ Archivos montados en rutas correctas
- ✅ Clave privada con permisos `600`
- ✅ Nginx syntax OK

---

## 🧹 Limpieza de Recursos

```bash
# Ejecutar script de limpieza
./cleanup.sh
```

---

## 🔍 Troubleshooting

### Problema: "nginx: [emerg] cannot load certificate"

**Causa**: Ruta incorrecta o archivo faltante

**Solución**:
```bash
# Verificar que los archivos estén montados
kubectl exec nginx-https -- ls -la /etc/nginx/ssl/

# Verificar configuración de nginx
kubectl exec nginx-https -- cat /etc/nginx/conf.d/default.conf
```

### Problema: Certificado no confiable en navegador

**Es normal**: Es un certificado auto-firmado

**Solución**: Para producción, usa un certificado de CA reconocida (Let's Encrypt, etc.)

---

## 📖 Conceptos Clave Aprendidos

### ✅ --from-file Options

```bash
# Archivo individual
--from-file=archivo.txt

# Múltiples archivos
--from-file=file1.txt --from-file=file2.txt

# Todo un directorio
--from-file=/path/to/dir/

# Con nombre de clave personalizado
--from-file=clave-custom=archivo.txt
```

### ✅ Secret Items (Selección Específica)

```yaml
volumes:
- name: my-volume
  secret:
    secretName: my-secret
    items:
    - key: archivo-en-secret
      path: nombre-en-pod
      mode: 0600  # Permisos opcionales
```

### ✅ Mejores Prácticas TLS

- ✅ Usa `mode: 0600` para claves privadas
- ✅ Usa `readOnly: true` en volumeMounts
- ✅ Separa certificados de configuración
- ✅ Rota certificados antes de expirar
- ✅ Usa cert-manager para gestión automatizada

---

## 🎓 Preguntas de Repaso

1. **¿Qué pasa si usas `--from-file=.` en un directorio?**
   - Todos los archivos del directorio se agregan al secret

2. **¿Cómo controlar el nombre de la clave en el secret?**
   - Usa `--from-file=clave=archivo` sintaxis

3. **¿Por qué usar `items` en el volume?**
   - Para montar solo archivos específicos
   - Para renombrar archivos en el pod
   - Para controlar permisos individuales

4. **¿Cuál es la diferencia entre mode 0600 y 0644?**
   - `0600`: Solo propietario puede leer/escribir
   - `0644`: Todos pueden leer, solo propietario escribe

---

## 🚀 Siguiente Paso

Continúa con:
- **[Lab 03: Secret como Variables de Entorno](../lab-03-secret-env-vars/README.md)**

---

**¡Excelente trabajo!** 🎉 Ahora sabes crear Secrets desde archivos y usarlos en aplicaciones reales.
