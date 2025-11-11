# Laboratorio 01: RBAC Básico - Usuarios y Permisos

## Información del Laboratorio

**Duración estimada**: 45-60 minutos  
**Nivel**: Principiante  
**Requisitos previos**:
- Cluster de Kubernetes funcionando (minikube, AKS, etc.)
- `kubectl` instalado y configurado
- OpenSSL instalado
- Permisos de administrador en el cluster

## Objetivos de Aprendizaje

Al finalizar este laboratorio serás capaz de:
1. ✅ Crear certificados de usuario con OpenSSL
2. ✅ Configurar kubectl para múltiples usuarios
3. ✅ Crear Roles con permisos específicos
4. ✅ Asignar Roles a usuarios mediante RoleBindings
5. ✅ Verificar y probar permisos de RBAC
6. ✅ Troubleshoot errores comunes de permisos

## Escenario del Laboratorio

Eres el administrador de un cluster de Kubernetes. Tu empresa tiene un equipo de desarrollo que necesita acceso limitado al namespace `development`. Debes configurar:

- **Usuario**: `maria` (desarrolladora)
- **Permisos**: Solo lectura de pods y logs
- **Namespace**: `development`

## Parte 1: Preparación del Entorno

### Paso 1.1: Verificar cluster

```bash
# Verificar que kubectl funciona
kubectl cluster-info

# Ver contexto actual
kubectl config current-context

# Deberías estar como admin
kubectl auth can-i create clusterroles
# Expected output: yes
```

**✅ Checkpoint**: Si ves información del cluster, continúa.

### Paso 1.2: Crear namespace development

```bash
# Crear namespace
kubectl create namespace development

# Verificar
kubectl get namespaces
kubectl get namespace development
```

**Salida esperada**:
```
NAME          STATUS   AGE
development   Active   5s
```

### Paso 1.3: Crear un pod de prueba

```bash
# Crear pod de prueba en development
kubectl run nginx --image=nginx --namespace=development

# Verificar
kubectl get pods -n development
```

**Salida esperada**:
```
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          10s
```

---

## Parte 2: Creación del Usuario Maria

### Paso 2.1: Generar clave privada

```bash
# Crear directorio para certificados
mkdir -p ~/k8s-users-lab
cd ~/k8s-users-lab

# Generar clave privada para maria
openssl genrsa -out maria.key 2048

# Verificar el archivo
ls -lh maria.key
# Expected: -rw------- 1 user user 1.7K ...
```

**⚠️ Importante**: La clave tiene permisos `600` (solo owner puede leer/escribir).

### Paso 2.2: Crear Certificate Signing Request (CSR)

```bash
# Crear CSR con CN=maria
openssl req -new \
    -key maria.key \
    -out maria.csr \
    -subj "/CN=maria/O=developers"

# Verificar el CSR
openssl req -in maria.csr -noout -text | head -20
```

**Busca en la salida**:
```
Subject: CN = maria, O = developers
```

**📝 Nota**: 
- `CN=maria` → Kubernetes usará "maria" como nombre de usuario
- `O=developers` → Kubernetes usará "developers" como grupo

### Paso 2.3: Obtener CA del cluster

Para **minikube**:
```bash
# El CA está en ~/.minikube/
ls ~/.minikube/ca.crt
ls ~/.minikube/ca.key

# Guardar rutas
CA_CERT=~/.minikube/ca.crt
CA_KEY=~/.minikube/ca.key
```

Para **otros clusters** (AKS, kubeadm, etc.):
```bash
# Extraer CA del kubeconfig
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt

# Para el CA key, necesitarás acceso al servidor master
# Ubicación común: /etc/kubernetes/pki/ca.key
```

### Paso 2.4: Firmar el certificado

```bash
# Firmar CSR con el CA del cluster
openssl x509 -req \
    -in maria.csr \
    -CA $CA_CERT \
    -CAkey $CA_KEY \
    -CAcreateserial \
    -out maria.crt \
    -days 365

# Verificar certificado
openssl x509 -in maria.crt -noout -text | grep Subject
# Expected: Subject: CN = maria, O = developers
```

**Salida esperada**:
```
Signature ok
subject=CN = maria, O = developers
Getting CA Private Key
```

### Paso 2.5: Verificar archivos generados

```bash
# Deberías tener estos archivos
ls -lh maria.*

# Expected output:
# maria.crt  - Certificado firmado (público)
# maria.csr  - Certificate Signing Request (ya no necesario)
# maria.key  - Clave privada (¡PRIVADO!)
```

---

## Parte 3: Configuración de kubectl para Maria

### Paso 3.1: Agregar usuario maria a kubectl

```bash
# Configurar credenciales de maria
kubectl config set-credentials maria \
    --client-certificate=$(pwd)/maria.crt \
    --client-key=$(pwd)/maria.key \
    --embed-certs=false

# Verificar
kubectl config view | grep -A 5 "name: maria"
```

**Salida esperada**:
```yaml
- name: maria
  user:
    client-certificate: /path/to/maria.crt
    client-key: /path/to/maria.key
```

### Paso 3.2: Crear contexto para maria

```bash
# Obtener nombre del cluster
CLUSTER_NAME=$(kubectl config view -o jsonpath='{.contexts[?(@.name == "'"$(kubectl config current-context)"'")].context.cluster}')

# Crear contexto
kubectl config set-context maria-context \
    --cluster=$CLUSTER_NAME \
    --user=maria \
    --namespace=development

# Verificar contextos
kubectl config get-contexts
```

**Salida esperada**:
```
CURRENT   NAME            CLUSTER     AUTHINFO   NAMESPACE
*         minikube        minikube    minikube   default
          maria-context   minikube    maria      development
```

### Paso 3.3: Probar contexto de maria (sin permisos aún)

```bash
# Cambiar a contexto de maria
kubectl config use-context maria-context

# Intentar listar pods
kubectl get pods

# Expected output:
# Error from server (Forbidden): pods is forbidden: 
# User "maria" cannot list resource "pods" in API group "" 
# in the namespace "development"
```

**✅ Esto es correcto**: Maria no tiene permisos aún.

```bash
# Volver a contexto de admin
kubectl config use-context minikube  # o tu contexto de admin
```

---

## Parte 4: Crear Role de Solo Lectura

### Paso 4.1: Crear Role

Crea el archivo `role-pod-reader.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: development
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

Aplicar:
```bash
kubectl apply -f role-pod-reader.yaml

# Verificar
kubectl get role pod-reader -n development
kubectl describe role pod-reader -n development
```

**Salida esperada del describe**:
```
Name:         pod-reader
Namespace:    development
PolicyRule:
  Resources   Verbs
  ---------   -----
  pods        [get list watch]
  pods/log    [get list watch]
```

### Paso 4.2: Entender el Role

**Preguntas de comprensión**:
1. ¿Qué significa `apiGroups: [""]`?
   - Respuesta: Core API group (pods, services, etc.)

2. ¿Qué verbos tiene este Role?
   - Respuesta: get, list, watch (solo lectura)

3. ¿Puede maria crear o eliminar pods con este Role?
   - Respuesta: NO, solo lectura

---

## Parte 5: Asignar Role a Maria con RoleBinding

### Paso 5.1: Crear RoleBinding

Crea el archivo `rolebinding-maria.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: maria-pod-reader
  namespace: development
subjects:
- kind: User
  name: maria  # Debe coincidir con CN del certificado
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Aplicar:
```bash
kubectl apply -f rolebinding-maria.yaml

# Verificar
kubectl get rolebinding maria-pod-reader -n development
kubectl describe rolebinding maria-pod-reader -n development
```

**Salida esperada**:
```
Name:         maria-pod-reader
Namespace:    development
Role:
  Kind:  Role
  Name:  pod-reader
Subjects:
  Kind  Name   Namespace
  ----  ----   ---------
  User  maria
```

---

## Parte 6: Probar Permisos de Maria

### Paso 6.1: Verificar permisos desde admin

```bash
# Verificar permisos de maria (como admin)
kubectl auth can-i get pods --as maria -n development
# Expected: yes

kubectl auth can-i list pods --as maria -n development
# Expected: yes

kubectl auth can-i delete pods --as maria -n development
# Expected: no

kubectl auth can-i create deployments --as maria -n development
# Expected: no
```

### Paso 6.2: Cambiar a contexto de maria

```bash
# Cambiar a maria
kubectl config use-context maria-context

# Verificar contexto actual
kubectl config current-context
# Expected: maria-context
```

### Paso 6.3: Probar comandos permitidos

```bash
# ✅ Debe funcionar: listar pods
kubectl get pods

# ✅ Debe funcionar: describir pod
kubectl describe pod nginx

# ✅ Debe funcionar: ver logs
kubectl logs nginx

# ✅ Debe funcionar: watch pods
kubectl get pods --watch
# (Ctrl+C para salir)
```

**Salida esperada**:
```
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          10m
```

### Paso 6.4: Probar comandos NO permitidos

```bash
# ❌ Debe fallar: crear pod
kubectl run test --image=nginx

# Expected error:
# Error from server (Forbidden): pods is forbidden: 
# User "maria" cannot create resource "pods"

# ❌ Debe fallar: eliminar pod
kubectl delete pod nginx

# Expected error:
# Error from server (Forbidden): pods "nginx" is forbidden: 
# User "maria" cannot delete resource "pods"

# ❌ Debe fallar: crear deployment
kubectl create deployment test --image=nginx

# Expected error:
# Error from server (Forbidden): deployments.apps is forbidden
```

### Paso 6.5: Probar en otro namespace

```bash
# ❌ Debe fallar: ver pods en otro namespace
kubectl get pods -n default

# Expected error:
# Error from server (Forbidden): pods is forbidden: 
# User "maria" cannot list resource "pods" in namespace "default"
```

**📝 Observación**: Los permisos están limitados al namespace `development`.

---

## Parte 7: Troubleshooting

### Ejercicio 7.1: Diagnosticar permisos

Vuelve al contexto de admin:
```bash
kubectl config use-context minikube
```

Usa estos comandos para diagnosticar:

```bash
# Ver todos los Roles
kubectl get roles -A

# Ver todos los RoleBindings
kubectl get rolebindings -A

# Ver RoleBindings que involucran a maria
kubectl get rolebindings -A -o json | \
    jq -r '.items[] | select(.subjects[]?.name == "maria") | .metadata.name'

# Ver detalles de permisos
kubectl describe role pod-reader -n development
kubectl describe rolebinding maria-pod-reader -n development
```

### Ejercicio 7.2: Solucionar error común

**Problema**: Maria necesita también ver Services.

**Solución**: Modificar el Role

Edita `role-pod-reader.yaml`:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: development
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "services"]  # Agregado services
  verbs: ["get", "list", "watch"]
```

Aplicar cambios:
```bash
kubectl apply -f role-pod-reader.yaml

# Probar como maria
kubectl config use-context maria-context
kubectl get services  # Ahora debería funcionar
```

---

## Parte 8: Limpieza (Opcional)

```bash
# Volver a contexto de admin
kubectl config use-context minikube

# Eliminar recursos
kubectl delete rolebinding maria-pod-reader -n development
kubectl delete role pod-reader -n development
kubectl delete pod nginx -n development
kubectl delete namespace development

# Eliminar contexto de maria
kubectl config delete-context maria-context
kubectl config unset users.maria

# Eliminar certificados
rm ~/k8s-users-lab/maria.*
```

---

## Resumen y Validación

### ✅ Checklist de Completitud

Marca cada objetivo completado:

- [ ] Generé certificado de usuario con OpenSSL
- [ ] Firmé el certificado con el CA del cluster
- [ ] Configuré kubectl con credenciales del usuario
- [ ] Creé un Role con permisos específicos
- [ ] Creé un RoleBinding para asignar el Role
- [ ] Probé permisos permitidos exitosamente
- [ ] Probé permisos denegados (Forbidden)
- [ ] Entendí la diferencia entre Role y RoleBinding
- [ ] Diagnostiqué permisos con kubectl auth can-i

### Conceptos Clave Aprendidos

1. **Certificados de usuario**:
   - CN (Common Name) = nombre del usuario
   - O (Organization) = grupo
   - Firmado por el CA del cluster

2. **Role**: Define QUÉ se puede hacer
   - resources: pods, services, etc.
   - verbs: get, list, create, delete, etc.
   - Scope: un namespace

3. **RoleBinding**: Define QUIÉN puede hacerlo
   - subjects: User, Group, ServiceAccount
   - roleRef: qué Role usar

4. **kubectl auth can-i**: Verificar permisos
   - Como admin: `--as <usuario>`
   - Como usuario: cambiar contexto

### Preguntas de Repaso

1. **¿Qué archivo contiene la clave privada del usuario?**
   - Respuesta: `maria.key`

2. **¿Qué campo del certificado usa Kubernetes como nombre de usuario?**
   - Respuesta: CN (Common Name)

3. **¿Puede maria eliminar pods en el namespace development?**
   - Respuesta: NO, el Role solo tiene verbs de lectura

4. **¿Puede maria ver pods en el namespace default?**
   - Respuesta: NO, el RoleBinding es solo para namespace development

5. **¿Qué comando usarías para verificar si maria puede crear deployments?**
   - Respuesta: `kubectl auth can-i create deployments --as maria -n development`

---

## Próximos Pasos

¡Felicitaciones! Has completado el Laboratorio 01.

**Continúa tu aprendizaje**:
- 🔬 **[Laboratorio 02: RBAC Avanzado](../lab-02-rbac-avanzado/)**: ClusterRoles, grupos, múltiples namespaces
- 📚 **[README del Módulo](../../README.md)**: Repasa los conceptos teóricos
- 💾 **[Ejemplos](../../ejemplos/)**: Explora más configuraciones YAML

**Desafíos adicionales**:
1. Crea un segundo usuario `juan` con los mismos permisos que maria
2. Crea un Role que permita modificar ConfigMaps pero no Secrets
3. Experimenta con el verbo `watch` para observar cambios en tiempo real

---

**¡Excelente trabajo+x 11-configurar-kubectl.sh* Ahora dominas los fundamentos de RBAC para usuarios en Kubernetes.
