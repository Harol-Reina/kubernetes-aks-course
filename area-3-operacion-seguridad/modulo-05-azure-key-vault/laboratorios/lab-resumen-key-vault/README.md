# Lab Resumen: Kubernetes Secrets y Azure Key Vault

**Duracion:** 60 minutos | **Nivel:** Principiante | **Archivo:** `key-vault-lab.yaml`

Un solo YAML despliega todo el entorno: Namespace, ServiceAccount, tres tipos de Secret, un ConfigMap, y tres Pods que demuestran todas las formas de consumir Secrets en Kubernetes.

---

## Conceptos Previos (lee esto antes de empezar)

Esta seccion explica todo lo que necesitas saber antes de ejecutar el primer comando. Si ya conoces Secrets, puedes saltar directamente al Paso 0.

### La analogia de la caja fuerte

Imagina la oficina de una empresa que maneja informacion confidencial.

En una oficina desorganizada, el desarrollador escribe la contrasena de la base de datos en un post-it pegado al monitor. Cualquiera que pase por su escritorio puede leerla. Si alguien hace una fotografia del escritorio, las credenciales estan expuestas.

En una oficina bien organizada, la informacion no sensible (el horario de reunion, la URL del servidor de documentacion, el nombre del entorno) se anota en una pizarra publica en la sala de reuniones. Todos pueden verla y eso esta bien. Pero las contrasenas, las claves de API, los certificados TLS, van dentro de una caja fuerte. Solo las personas con la combinacion correcta pueden abrirla. Si alguien entra a la oficina sin permiso, no puede leer lo que hay dentro de la caja.

Kubernetes funciona exactamente igual:

- **ConfigMap** = la pizarra publica. Datos de configuracion no sensibles, visibles para cualquiera con acceso al namespace.
- **Secret** = la caja fuerte del namespace. Datos sensibles, protegidos por RBAC. Kubernetes controla quien tiene la "combinacion".
- **Azure Key Vault** = la camara acorazada del banco. Para datos criticos en produccion: cifrado AES-256, audit trail de cada acceso, rotacion automatica, cumplimiento regulatorio.

### Que es un Secret en Kubernetes

Un Secret es un objeto de la API de Kubernetes que almacena datos sensibles en pares clave-valor. A diferencia de un ConfigMap, Kubernetes:

1. No muestra los valores en `kubectl describe` (los oculta con `<REDACTED>` o `***`)
2. Requiere permiso RBAC especifico `get secrets` para leerlos con `kubectl get secret -o yaml`
3. Solo los monta en los Pods que explicitamente los solicitan
4. (Opcionalmente) los cifra en reposo en etcd con EncryptionConfiguration

Los tres tipos de Secret mas usados son:

**Opaque** — el tipo generico. Para cualquier par clave-valor: contrasenas, tokens, connection strings, API keys. Es el tipo por defecto cuando no se especifica otro.

**kubernetes.io/dockerconfigjson** — especifico para credenciales de registros de imagenes Docker privados. Kubernetes lo entiende y lo usa automaticamente en `imagePullSecrets` para autenticarse cuando descarga imagenes.

**kubernetes.io/tls** — para certificados TLS. Almacena el par `tls.crt` (certificado) y `tls.key` (clave privada). Los Ingress controllers lo usan para servir HTTPS.

### base64 NO es cifrado (esto es importante)

Kubernetes almacena los valores de los Secrets codificados en base64. Muchos principiantes asumen que esto proporciona seguridad. No es asi.

base64 es un esquema de codificacion que convierte datos binarios en texto ASCII imprimible. Es completamente reversible sin ninguna clave secreta:

```bash
# Codificar en base64
echo -n "MiContrasena123" | base64
# TWlDb250cmFzZW5hMTIz

# Decodificar — cualquier persona puede hacer esto
echo "TWlDb250cmFzZW5hMTIz" | base64 -d
# MiContrasena123
```

No se necesita ninguna clave. No hay algoritmo secreto. Cualquier herramienta puede hacerlo. La "proteccion" de los Secrets no viene de base64, sino del control de acceso RBAC de Kubernetes: solo quienes tienen permiso `get` sobre Secrets en ese namespace pueden ejecutar `kubectl get secret -o yaml`.

Cuando defines un Secret en un archivo YAML, debes codificar los valores en base64:

```yaml
data:
  password: TWlDb250cmFzZW5hMTIz    # base64 de "MiContrasena123"
```

O puedes usar `stringData` para que Kubernetes lo codifique automaticamente:

```yaml
stringData:
  password: MiContrasena123         # Kubernetes lo convierte a base64 al guardarlo
```

### Diferencia entre ConfigMap y Secret

La diferencia no es tecnica (internamente son estructuras muy similares), sino de semantica y control de acceso:

```
ConfigMap                              Secret
---------                              ------
Datos no sensibles                     Datos sensibles
Texto plano en etcd                    base64 en etcd (cifrado opcional)
kubectl describe muestra valores       kubectl describe OCULTA valores
Acceso: get configmaps                 Acceso: get secrets (permiso separado)
Rotacion: reiniciar Pod                Rotacion: volumen se actualiza automaticamente
Uso: URLs, flags, configuracion        Uso: passwords, tokens, certificados
```

En la practica, usa ConfigMap cuando el valor pueda aparecer en logs sin problema. Usa Secret cuando el valor NO debe aparecer en logs, en pantalla, ni en pipelines de CI/CD.

### Dos formas de pasar un Secret a un Pod

**Metodo 1: Variables de entorno** — cada clave del Secret se convierte en una variable de entorno del proceso principal del contenedor.

Ventaja: sencillo, compatible con aplicaciones 12-factor que esperan configuracion via env vars.
Desventaja: el valor queda fijo en el momento del inicio del Pod. Si el Secret cambia, el Pod debe reiniciarse. Ademas, las variables de entorno pueden aparecer en herramientas de diagnostico del sistema operativo (`ps aux`, `/proc/PID/environ`).

**Metodo 2: Volumenes** — Kubernetes monta el Secret como un directorio de archivos dentro del contenedor. Cada clave del Secret se convierte en un archivo con ese nombre, cuyo contenido es el valor ya decodificado (sin base64).

Ventaja: si el Secret cambia, Kubernetes actualiza los archivos automaticamente sin reiniciar el Pod (util para rotacion de credenciales). Los valores no aparecen en variables de entorno.
Desventaja: la aplicacion debe leer los archivos del sistema de archivos en lugar de env vars.

### Que es Azure Key Vault y cuando usarlo

Azure Key Vault es el servicio de Azure para gestionar secretos, claves criptograficas y certificados de forma centralizada. Mientras que los Secrets de Kubernetes son adecuados para entornos de desarrollo o clusters pequeños, Azure Key Vault esta disenado para produccion empresarial:

- Cifrado AES-256 siempre activo (no es opcional como en Kubernetes)
- Registro de auditoria de cada acceso (quien leyo el secreto, cuando, desde donde)
- Rotacion automatica de secretos con notificaciones
- Historial de versiones (puedes ver versiones anteriores de un secreto)
- Integracion con Managed Identities (sin contrasenas de servicio)
- Cumplimiento FIPS 140-2, PCI-DSS, SOC2, HIPAA

La integracion con Kubernetes AKS usa el **CSI Secrets Store Driver** y un objeto **SecretProviderClass** que le indica a Kubernetes como montar secretos de Azure Key Vault directamente como volumenes en los Pods, sin que los valores pasen por los Secrets de Kubernetes.

### Tabla comparativa: ConfigMap vs Secret vs Azure Key Vault

```
Caracteristica              ConfigMap        Secret K8s        Azure Key Vault
--------------------------  ---------------  ----------------  ----------------------
Para datos sensibles        NO               Si (basico)       Si (enterprise)
Visibilidad en kubectl      Texto plano      base64            Solo metadatos
Cifrado en reposo           No               Opcional (etcd)   Siempre (AES-256)
Audit trail                 No               Parcial           Siempre activo
Rotacion automatica         No               No                Si (programada)
Control de acceso           RBAC namespace   RBAC namespace    Azure RBAC + policies
Historial de versiones      No               No                Si (completo)
Notificaciones expiracion   No               No                Si (Event Grid)
Gestion multi-cluster       Por cluster      Por cluster       Centralizada
Coste                       Incluido         Incluido          Azure pricing
Cuando usarlo               Configuracion    Dev/testing       Produccion regulada
```

---

## Paso 0: Preparar Minikube

Antes de desplegar el YAML, verifica que tienes Minikube ejecutandose:

```bash
minikube status
```

**Salida esperada:**

```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

Si Minikube no esta ejecutandose:

```bash
minikube start
```

Verifica la version de Kubernetes disponible:

```bash
kubectl version --short
```

**Salida esperada (version puede variar):**

```
Client Version: v1.29.x
Server Version: v1.29.x
```

---

## Paso 1: Desplegar todo con un solo comando

```bash
kubectl apply -f key-vault-lab.yaml
```

**Salida esperada:**

```
namespace/lab-key-vault created
serviceaccount/app-service-account created
secret/db-credentials created
secret/api-credentials created
secret/registry-credentials created
secret/app-tls-cert created
configmap/app-config created
pod/pod-secret-volume created
pod/pod-secret-env created
pod/pod-configmap-compare created
```

Kubernetes procesa los recursos en el orden del YAML. El namespace se crea primero, luego los recursos dentro de el.

Verificar que todo se creo correctamente:

```bash
kubectl get all -n lab-key-vault
```

**Salida esperada:**

```
NAME                        READY   STATUS      RESTARTS   AGE
pod/pod-configmap-compare   1/1     Running     0          30s
pod/pod-secret-env          1/1     Running     0          30s
pod/pod-secret-volume       1/1     Running     0          30s
```

Los tres Pods deben estar en estado `Running` o `Completed` despues de unos segundos. Si ves `ContainerCreating`, espera un momento y ejecuta el comando de nuevo.

Ver tambien los Secrets y el ConfigMap:

```bash
kubectl get secrets,configmaps -n lab-key-vault
```

**Salida esperada:**

```
NAME                              TYPE                             DATA   AGE
secret/app-tls-cert               kubernetes.io/tls                2      45s
secret/api-credentials            Opaque                           3      45s
secret/db-credentials             Opaque                           5      45s
secret/registry-credentials       kubernetes.io/dockerconfigjson   1      45s

NAME                         DATA   AGE
configmap/app-config         6      45s
configmap/kube-root-ca.crt   1      45s
```

> Que aprendimos? Con un solo `kubectl apply` creamos un Namespace completo con Secrets de tres tipos distintos, un ConfigMap, y tres Pods con diferentes formas de consumir esos Secrets. El orden en el YAML importa: el Namespace debe existir antes de los recursos que van dentro de el.

---

## Paso 2: Explorar Secrets — ver que estan en base64

Este paso demuestra la diferencia fundamental entre `kubectl describe` y `kubectl get -o yaml` para Secrets.

**Primero, intenta ver el Secret con describe:**

```bash
kubectl describe secret db-credentials -n lab-key-vault
```

**Salida esperada:**

```
Name:         db-credentials
Namespace:    lab-key-vault
Labels:       app=demo-app
              lab=key-vault
              secret-type=database
              tier=database
Annotations:  description: Credenciales de acceso a la base de datos PostgreSQL
              owner: equipo-backend
              rotation-policy: cada-90-dias

Type:  Opaque

Data
====
db-host:      51 bytes
db-name:      5 bytes
db-password:  12 bytes
db-port:      4 bytes
db-username:  5 bytes
```

`kubectl describe` muestra los nombres de las claves y el tamano en bytes, pero NO los valores. Esto es intencional: protege contra ver credenciales accidentalmente en la terminal.

**Ahora, ver el YAML completo (muestra base64):**

```bash
kubectl get secret db-credentials -n lab-key-vault -o yaml
```

**Salida esperada:**

```yaml
apiVersion: v1
data:
  db-host: cG9zdGdyZXMubGFiLWtleS12YXVsdC5zdmMuY2x1c3Rlci5sb2NhbA==
  db-name: YXBwZGI=
  db-password: UzNjdXIzUEBzcyE=
  db-port: NTQzMg==
  db-username: YWRtaW4=
kind: Secret
metadata:
  name: db-credentials
  namespace: lab-key-vault
  ...
type: Opaque
```

Los valores estan en base64. Cualquier persona con permiso `get secrets` puede verlos. Decodifica uno para confirmar que no hay cifrado real:

```bash
kubectl get secret db-credentials -n lab-key-vault \
  -o jsonpath='{.data.db-username}' | base64 -d
```

**Salida esperada:**

```
admin
```

```bash
kubectl get secret db-credentials -n lab-key-vault \
  -o jsonpath='{.data.db-password}' | base64 -d
```

**Salida esperada:**

```
S3cur3P@ss!
```

**Compara con el ConfigMap** — no necesita decodificacion:

```bash
kubectl describe configmap app-config -n lab-key-vault
```

**Salida esperada:**

```
Name:         app-config
Namespace:    lab-key-vault
...
Data
====
APP_ENV:
----
development
CACHE_TTL:
----
300
FEATURE_FLAG_NEW_UI:
----
false
LOG_LEVEL:
----
info
MAX_CONNECTIONS:
----
100
app.properties:
----
# Configuracion de la aplicacion demo
app.name=demo-app
...
```

`kubectl describe` del ConfigMap muestra los valores directamente en texto plano. Esta es la diferencia visual mas importante entre ConfigMap y Secret.

> Que aprendimos? `kubectl describe secret` nunca muestra los valores (solo el tamano en bytes). `kubectl get secret -o yaml` los muestra en base64, que se puede decodificar trivialmente. La "proteccion" viene del RBAC que controla quien puede ejecutar `get secrets`, no de base64 en si mismo.

---

## Paso 3: Explorar Secrets montados como volumenes

Entra al Pod que monta Secrets como archivos:

```bash
kubectl exec -it pod-secret-volume -n lab-key-vault -- sh
```

Dentro del Pod, explora el directorio donde se montaron los Secrets:

```sh
# Ver el directorio del Secret de base de datos
ls -la /etc/secrets/db/
```

**Salida esperada:**

```
total 0
drwxrwxrwt    3 root     root           120 Mar  3 10:00 .
drwxr-xr-x    4 root     root            80 Mar  3 10:00 ..
drwxr-xr-x    2 root     root           100 Mar  3 10:00 ..2026_03_03_10_00_00.000000000
lrwxrwxrwx    1 root     root            32 Mar  3 10:00 ..data -> ..2026_03_03_10_00_00.000000000
lrwxrwxrwx    1 root     root            11 Mar  3 10:00 db-host -> ..data/db-host
lrwxrwxrwx    1 root     root            11 Mar  3 10:00 db-name -> ..data/db-name
lrwxrwxrwx    1 root     root            15 Mar  3 10:00 db-password -> ..data/db-password
lrwxrwxrwx    1 root     root            11 Mar  3 10:00 db-port -> ..data/db-port
lrwxrwxrwx    1 root     root            15 Mar  3 10:00 db-username -> ..data/db-username
```

Cada clave del Secret aparece como un archivo. Los archivos son symlinks a un directorio con timestamp — esto es lo que permite la actualizacion atomica cuando el Secret cambia.

Lee el contenido de un archivo:

```sh
cat /etc/secrets/db/db-username
```

**Salida esperada:**

```
admin
```

```sh
cat /etc/secrets/db/db-password
```

**Salida esperada:**

```
S3cur3P@ss!
```

El valor ya esta decodificado de base64. Kubernetes hace la conversion automaticamente al montar el volumen. El contenedor recibe el valor real, no el base64.

Verifica los permisos del archivo:

```sh
ls -la /etc/secrets/db/..data/
```

**Salida esperada:**

```
-r--------    1 root     root            5 Mar  3 10:00 db-name
-r--------    1 root     root           12 Mar  3 10:00 db-password
...
```

Los permisos `r--------` (0400) significan solo lectura para el propietario. Definimos esto con `defaultMode: 0400` en el YAML. Es mas seguro que el default 0644 porque evita que otros procesos en el mismo contenedor lean las credenciales.

Verifica tambien el directorio del certificado TLS:

```sh
ls -la /etc/secrets/tls/
cat /etc/secrets/tls/tls.crt | head -3
```

**Salida esperada:**

```
lrwxrwxrwx    1 root     root    tls.crt -> ..data/tls.crt
lrwxrwxrwx    1 root     root    tls.key -> ..data/tls.key
-----BEGIN CERTIFICATE-----
```

Sal del Pod:

```sh
exit
```

> Que aprendimos? Cuando Kubernetes monta un Secret como volumen, convierte automaticamente los valores de base64 al texto original. Cada clave del Secret se convierte en un archivo separado. Los symlinks permiten actualizar los valores sin reiniciar el contenedor. El modo de permisos 0400 es una buena practica de seguridad.

---

## Paso 4: Explorar Secrets como variables de entorno

Entra al Pod que usa Secrets como env vars:

```bash
kubectl exec -it pod-secret-env -n lab-key-vault -- sh
```

Verifica las variables de entorno inyectadas desde el Secret:

```sh
echo $DB_USERNAME
```

**Salida esperada:**

```
admin
```

```sh
echo $DB_HOST
```

**Salida esperada:**

```
postgres.lab-key-vault.svc.cluster.local
```

```sh
echo $DB_PORT
```

**Salida esperada:**

```
5432
```

Ahora comprueba que las variables del `envFrom` (todas las claves del Secret api-credentials) tambien estan disponibles:

```sh
env | grep -i api
```

**Salida esperada:**

```
api-key=abcd1234-api-key-example
api-token=bearer-token-xyz-example
webhook-secret=webhook-secret-value
```

Observa que los nombres de las variables coinciden exactamente con las claves del Secret, sin prefijo. Si hubieramos usado `prefix: "API_"` en el YAML, habrian aparecido como `API_api-key`, etc.

Sal del Pod:

```sh
exit
```

**Diferencia critica con volumenes:** si ahora cambiaras el Secret y esperaras, las variables de entorno de este Pod NO se actualizarian. El Pod mostraria los valores originales hasta que se reiniciara.

```bash
# Demostrar que las variables NO se actualizan automaticamente
# Primero, actualiza el Secret
kubectl patch secret db-credentials -n lab-key-vault \
  --type='json' \
  -p='[{"op":"replace","path":"/data/db-username","value":"'$(echo -n "nuevo-admin" | base64)'"}]'

# Espera 5 segundos
sleep 5

# Verifica la variable en el Pod - sigue mostrando el valor antiguo
kubectl exec pod-secret-env -n lab-key-vault -- sh -c 'echo $DB_USERNAME'
```

**Salida esperada:**

```
admin
```

El Pod todavia muestra `admin` aunque el Secret ya tiene `nuevo-admin`.

Contrasta con el volumen:

```bash
# En el Pod de volumen, el archivo SI se actualiza (puede tardar 1-2 minutos)
kubectl exec pod-secret-volume -n lab-key-vault -- cat /etc/secrets/db/db-username
```

**Salida esperada (despues de 1-2 minutos):**

```
nuevo-admin
```

Restaura el valor original del Secret para los siguientes pasos:

```bash
kubectl patch secret db-credentials -n lab-key-vault \
  --type='json' \
  -p='[{"op":"replace","path":"/data/db-username","value":"'$(echo -n "admin" | base64)'"}]'
```

> Que aprendimos? Los Secrets como variables de entorno son mas simples de usar pero tienen una limitacion importante: no se actualizan cuando el Secret cambia. Los volumenes si se actualizan automaticamente. Para rotacion de credenciales en produccion, los volumenes son la opcion correcta.

---

## Paso 5: Comparar ConfigMap vs Secret en el mismo Pod

Entra al Pod de comparacion:

```bash
kubectl exec -it pod-configmap-compare -n lab-key-vault -- sh
```

Ve el directorio del ConfigMap montado como volumen:

```sh
ls /etc/config/
```

**Salida esperada:**

```
APP_ENV                CACHE_TTL              FEATURE_FLAG_NEW_UI
LOG_LEVEL              MAX_CONNECTIONS        app.properties
```

Lee el archivo de configuracion del ConfigMap:

```sh
cat /etc/config/app.properties
```

**Salida esperada:**

```
# Configuracion de la aplicacion demo
# Estos valores NO son sensibles - estan en texto plano a proposito
app.name=demo-app
app.version=1.0.0
app.environment=development
server.port=8080
server.host=0.0.0.0

# URL del backend (no incluye credenciales)
database.url=jdbc:postgresql://postgres.lab-key-vault.svc.cluster.local:5432/appdb
# NOTA: Las credenciales (usuario/password) vienen de Secrets, no de aqui
...
```

Ahora ve el directorio del Secret montado:

```sh
ls /etc/secrets/
```

**Salida esperada:**

```
db-host      db-name      db-password  db-port      db-username
```

Lee el valor del Secret:

```sh
cat /etc/secrets/db-username
```

**Salida esperada:**

```
admin
```

Verifica las variables de entorno del ConfigMap (inyectadas via envFrom):

```sh
echo "APP_ENV=$APP_ENV | LOG_LEVEL=$LOG_LEVEL | MAX_CONNECTIONS=$MAX_CONNECTIONS"
```

**Salida esperada:**

```
APP_ENV=development | LOG_LEVEL=info | MAX_CONNECTIONS=100
```

Sal del Pod:

```sh
exit
```

**Desde fuera del Pod, la diferencia es evidente:**

```bash
# ConfigMap: valores visibles inmediatamente con describe
kubectl describe configmap app-config -n lab-key-vault | grep -A2 "LOG_LEVEL"
```

**Salida esperada:**

```
LOG_LEVEL:
----
info
```

```bash
# Secret: describe NO muestra valores
kubectl describe secret db-credentials -n lab-key-vault | grep -A2 "db-password"
```

**Salida esperada:**

```
db-password:  12 bytes
```

> Que aprendimos? Desde dentro del Pod no hay diferencia visible entre datos de ConfigMap y datos de Secret: ambos llegan como archivos de texto normal. La diferencia es en el nivel de acceso externo al cluster: `kubectl describe configmap` expone los valores, `kubectl describe secret` los oculta. Esto es la capa de proteccion que ofrecen los Secrets de Kubernetes.

---

## Paso 6: Restricciones RBAC para Secrets

Este paso demuestra como RBAC puede restringir el acceso a Secrets. En produccion, los desarrolladores no deberian poder leer Secrets de namespaces de produccion.

Verifica los permisos del ServiceAccount del Pod:

```bash
# Ver el ServiceAccount
kubectl describe serviceaccount app-service-account -n lab-key-vault
```

**Salida esperada:**

```
Name:                app-service-account
Namespace:           lab-key-vault
Labels:              app=demo-app
                     lab=key-vault
                     tier=application
Annotations:         description: ServiceAccount para la aplicacion demo del lab de Key Vault
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
```

El ServiceAccount existe pero no tiene permisos RBAC asignados todavia. En un cluster real, necesitaria un Role y un RoleBinding.

Crea un Role que permita leer solo el Secret de base de datos:

```bash
kubectl create role secret-reader \
  --verb=get \
  --resource=secrets \
  --resource-name=db-credentials \
  -n lab-key-vault
```

**Salida esperada:**

```
role.rbac.authorization.k8s.io/secret-reader created
```

Vincula el Role al ServiceAccount:

```bash
kubectl create rolebinding app-secret-binding \
  --role=secret-reader \
  --serviceaccount=lab-key-vault:app-service-account \
  -n lab-key-vault
```

**Salida esperada:**

```
rolebinding.rbac.authorization.k8s.io/app-secret-binding created
```

Verifica los permisos del ServiceAccount:

```bash
kubectl auth can-i get secret/db-credentials \
  --as=system:serviceaccount:lab-key-vault:app-service-account \
  -n lab-key-vault
```

**Salida esperada:**

```
yes
```

```bash
# Pero NO puede leer el Secret de API (no esta en el resource-name del Role)
kubectl auth can-i get secret/api-credentials \
  --as=system:serviceaccount:lab-key-vault:app-service-account \
  -n lab-key-vault
```

**Salida esperada:**

```
no
```

```bash
# Y no puede listar todos los Secrets
kubectl auth can-i list secrets \
  --as=system:serviceaccount:lab-key-vault:app-service-account \
  -n lab-key-vault
```

**Salida esperada:**

```
no
```

Este es el principio de minimo privilegio: la aplicacion solo puede acceder al Secret exacto que necesita, nada mas.

> Que aprendimos? RBAC es la capa de control de acceso que da sentido a los Secrets. Sin RBAC, cualquier Pod del namespace podria leer cualquier Secret. Con RBAC bien configurado, cada aplicacion solo puede acceder a sus propios Secrets. El comando `kubectl auth can-i` permite verificar permisos de cualquier ServiceAccount sin necesidad de crear un Pod de prueba.

---

## Paso 7: Best practices de seguridad

Este paso resume las mejores practicas que se aplican en produccion.

### Practica 1: Nunca guardar Secrets en archivos YAML versionados

```bash
# MAL - no hagas esto nunca
cat > mi-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
data:
  password: U3VwZXJTZWNyZXQxMjM=   # base64 de "SuperSecret123" - NUNCA en git
EOF

# BIEN - crear Secrets de forma imperativa, sin guardar el archivo
kubectl create secret generic db-credentials \
  --from-literal=password=SuperSecret123 \
  -n lab-key-vault
```

Si necesitas declaratividad, usa herramientas como Sealed Secrets, External Secrets Operator, o directamente Azure Key Vault CSI Driver.

### Practica 2: Usar stringData para legibilidad en desarrollo

```bash
# Durante desarrollo puedes usar stringData (Kubernetes hace el base64 automaticamente)
# Pero NUNCA guardes este archivo en git con valores reales
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: dev-secret
  namespace: lab-key-vault
stringData:
  password: "mi-password-de-desarrollo"
EOF
```

Verifica que Kubernetes convirtio el valor a base64:

```bash
kubectl get secret dev-secret -n lab-key-vault -o jsonpath='{.data.password}' | base64 -d
```

**Salida esperada:**

```
mi-password-de-desarrollo
```

### Practica 3: Verificar que un Secret existe antes de desplegar un Pod que lo necesita

```bash
# Ver todos los Secrets del namespace
kubectl get secrets -n lab-key-vault

# Verificar que tiene las claves esperadas (sin ver los valores)
kubectl get secret db-credentials -n lab-key-vault -o jsonpath='{.data}' | python3 -m json.tool
```

**Salida esperada:**

```json
{
    "db-host": "cG9zdGdy...",
    "db-name": "YXBwZGI=",
    "db-password": "UzNjdXIz...",
    "db-port": "NTQzMg==",
    "db-username": "YWRtaW4="
}
```

Ves las claves disponibles pero no necesitas decodificar los valores para verificar que existen.

### Practica 4: Usar volumes en lugar de env vars cuando sea posible

```bash
# Verificar que el Pod de volumen puede leer el Secret
kubectl exec pod-secret-volume -n lab-key-vault -- cat /etc/secrets/db/db-username
```

**Salida esperada:**

```
admin
```

### Practica 5: Limpiar Secrets que ya no se usan

```bash
# Ver todos los Secrets del namespace con su edad
kubectl get secrets -n lab-key-vault --sort-by='.metadata.creationTimestamp'

# Eliminar un Secret especifico cuando ya no se necesita
# kubectl delete secret dev-secret -n lab-key-vault
```

### Practica 6: En AKS de produccion, usar Azure Key Vault

Para produccion en AKS, el flujo recomendado es:

```
1. Crear Azure Key Vault:
   az keyvault create --name kv-mi-app --resource-group mi-rg --location eastus

2. Agregar el secreto al Key Vault:
   az keyvault secret set --vault-name kv-mi-app --name db-password --value "MiPassword123"

3. Instalar el CSI Secrets Store Driver en AKS:
   az aks enable-addons --addons azure-keyvault-secrets-provider \
     --name mi-cluster --resource-group mi-rg

4. Crear SecretProviderClass que mapea el Key Vault al Pod:
   kubectl apply -f secret-provider-class.yaml

5. Montar el secreto del Key Vault en el Pod via CSI:
   volumeMounts:
   - name: secrets-store
     mountPath: /mnt/secrets-store
     readOnly: true
   volumes:
   - name: secrets-store
     csi:
       driver: secrets-store.csi.k8s.io
       readOnly: true
       volumeAttributes:
         secretProviderClass: "my-provider"
```

Con este flujo, los secretos nunca se almacenan en Kubernetes Secrets. Van directamente desde Azure Key Vault al sistema de archivos del Pod a traves del CSI driver.

> Que aprendimos? Las best practices de Secrets se resumen en: nunca en git, usar RBAC, preferir volumenes, y en produccion usar Azure Key Vault con CSI driver. El objetivo es que ninguna credencial aparezca en texto plano en ningun repositorio, pipeline, ni log del cluster.

---

## Resumen Visual

```
                    CLUSTER KUBERNETES
                    ==================

    kubectl apply   ->  Namespace: lab-key-vault
                            |
                    --------|--------
                    |               |
              ConfigMap         Secrets (3 tipos)
              app-config        ---------------
              (texto plano)     db-credentials (Opaque)
                                api-credentials (Opaque)
                                registry-creds (docker-reg)
                                app-tls-cert (tls)
                    |               |
                    |           RBAC protege el acceso
                    |               |
                    v               v
              Pod: pod-configmap-compare
              +-- /etc/config/    <- ConfigMap como volumen
              +-- /etc/secrets/   <- Secret como volumen
              +-- APP_ENV=...     <- ConfigMap como env var

              Pod: pod-secret-volume
              +-- /etc/secrets/db/     <- Secret Opaque como volumen
              +-- /etc/secrets/api/    <- Secret Opaque como volumen
              +-- /etc/secrets/tls/    <- Secret TLS como volumen

              Pod: pod-secret-env
              +-- DB_USERNAME=admin    <- Secret como env var
              +-- DB_PASSWORD=...      <- Secret como env var
              +-- api-key=...          <- Secret (envFrom)
```

---

## Comandos de Diagnostico Esenciales

Estos comandos cubren el 90% de las situaciones de troubleshooting con Secrets:

```bash
# Ver todos los Secrets de un namespace
kubectl get secrets -n lab-key-vault

# Ver los tipos y claves (sin valores) de un Secret
kubectl describe secret db-credentials -n lab-key-vault

# Ver valores en base64 (requiere permiso 'get secrets')
kubectl get secret db-credentials -n lab-key-vault -o yaml

# Decodificar un valor especifico
kubectl get secret db-credentials -n lab-key-vault \
  -o jsonpath='{.data.db-password}' | base64 -d

# Verificar que un Pod puede acceder a su Secret
kubectl exec pod-secret-volume -n lab-key-vault -- \
  cat /etc/secrets/db/db-username

# Verificar variables de entorno de un Pod
kubectl exec pod-secret-env -n lab-key-vault -- env | grep DB_

# Verificar permisos de un ServiceAccount sobre Secrets
kubectl auth can-i get secret/db-credentials \
  --as=system:serviceaccount:lab-key-vault:app-service-account \
  -n lab-key-vault

# Ver eventos si un Pod no puede montar un Secret
kubectl describe pod pod-secret-volume -n lab-key-vault | grep -A20 Events
```

---

## Errores Comunes para Principiantes

**"El Pod queda en estado Pending o Error"**

El motivo mas frecuente es que el Secret referenciado no existe. Verifica:

```bash
# Ver el error especifico
kubectl describe pod pod-secret-volume -n lab-key-vault | tail -20

# Verificar que el Secret existe en el mismo namespace
kubectl get secret db-credentials -n lab-key-vault
```

El error tipico en los eventos sera:
```
secret "db-credentials" not found
```

Si el Secret no existe, crealo antes de desplegar el Pod.

**"kubectl describe secret muestra todo en bytes, no veo los valores"**

Ese es el comportamiento correcto. Para ver los valores usa:

```bash
kubectl get secret db-credentials -n lab-key-vault -o yaml
# Luego decodifica: echo "base64value" | base64 -d
```

**"Modifique el Secret pero el Pod sigue usando el valor antiguo"**

Si el Pod usa variables de entorno (`env`/`envFrom`), las variables se fijan en el momento del inicio. Debes reiniciar el Pod:

```bash
kubectl delete pod pod-secret-env -n lab-key-vault
kubectl apply -f key-vault-lab.yaml
```

Si el Pod usa volumenes (`volumeMounts`), Kubernetes actualiza los archivos automaticamente en 1-2 minutos sin necesidad de reiniciar el Pod.

**"Puse valores en texto plano en el YAML (sin base64) y fallo"**

El campo `data:` requiere valores en base64. Si quieres valores en texto plano, usa `stringData:` en cambio:

```yaml
# Falla: data necesita base64
data:
  password: MiPassword123   # INCORRECTO sin codificar

# Funciona: stringData acepta texto plano
stringData:
  password: MiPassword123   # Kubernetes lo codifica automaticamente
```

**"El Pod no puede acceder al Secret por RBAC"**

Si ves `Error from server (Forbidden)` al intentar acceder a un Secret, verifica los permisos del ServiceAccount del Pod:

```bash
# Ver el ServiceAccount del Pod
kubectl get pod pod-secret-volume -n lab-key-vault -o jsonpath='{.spec.serviceAccountName}'

# Verificar si tiene permiso para leer el Secret
kubectl auth can-i get secret/db-credentials \
  --as=system:serviceaccount:lab-key-vault:app-service-account \
  -n lab-key-vault
```

Si la respuesta es `no`, necesitas crear un Role y RoleBinding (ver Paso 6).

---

## Limpieza

```bash
chmod +x cleanup.sh
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-key-vault
```
