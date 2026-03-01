# Lab 04: Gestión de Certificados en Kubernetes

## 📋 Metadata del Laboratorio

| Atributo | Detalle |
|----------|---------|
| **Módulo** | M23: Cluster Maintenance & Upgrades |
| **Dificultad** | 🔴 Avanzado |
| **Duración estimada** | 90-120 minutos |
| **Requisitos previos** | Cluster kubeadm, acceso SSH a control plane |
| **Relevancia CKA** | 🔴 **CRÍTICO** - 15% del examen (PKI & Certificates) |

---

## Tecnicas y Conceptos Utilizados

| Tecnica / Concepto | Descripcion |
|---|---|
| `kubeadm certs check-expiration` | Verificacion del estado y fecha de expiracion de todos los certificados |
| `kubeadm certs renew` | Renovacion de certificados PKI del cluster sin necesidad de recrearlo |
| Verificacion con `openssl x509` | Inspeccion detallada de certificados (fechas, SANs, emisor) |
| Estructura PKI de Kubernetes | Jerarquia de CAs y certificados de componentes (API Server, kubelet, etcd) |
| Reinicio de static pods | Recarga de componentes del control plane tras renovar certificados |
| Actualizacion de kubeconfig | Regeneracion de kubeconfig tras cambios en certificados de acceso |
| Backup y restore de PKI | Copia de seguridad del directorio `/etc/kubernetes/pki` antes de renovar |

## Archivos del Laboratorio

| Archivo | Descripcion |
|---|---|
| `check-certs.sh` | Script de verificacion detallada de certificados con color coding |
| `renew-certs.sh` | Script de renovacion con backup automatico y restart de componentes |
| `verify-certs.sh` | Suite de 8 verificaciones post-renovacion |
| `cleanup.sh` | Script de limpieza con opcion de restaurar backup de PKI |

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, podrás:

1. ✅ **Verificar expiración de certificados** usando `kubeadm certs check-expiration`
2. ✅ **Renovar certificados manualmente** con `kubeadm certs renew`
3. ✅ **Entender la estructura PKI** de Kubernetes (CA, API Server, kubelet, etc.)
4. ✅ **Renovar certificados específicos** sin downtime del cluster
5. ✅ **Verificar renovación** usando `openssl x509` y kubectl
6. ✅ **Troubleshoot problemas comunes** de certificados expirados

---

## 🏗️ Arquitectura: PKI de Kubernetes

### Estructura de Certificados

```
/etc/kubernetes/pki/
│
├── ca.crt / ca.key                      (Kubernetes CA - 10 años)
│   └── apiserver.crt                    (API Server cert - 1 año)
│   └── apiserver-kubelet-client.crt     (API → kubelet - 1 año)
│
├── front-proxy-ca.crt / front-proxy-ca.key  (Front Proxy CA - 10 años)
│   └── front-proxy-client.crt           (Front proxy - 1 año)
│
├── etcd/
│   ├── ca.crt / ca.key                  (etcd CA - 10 años)
│   ├── server.crt                        (etcd server - 1 año)
│   ├── peer.crt                          (etcd peer - 1 año)
│   └── healthcheck-client.crt            (etcd healthcheck - 1 año)
│
└── sa.key / sa.pub                       (Service Account keys)
```

### Flujo de Verificación y Renovación

```
┌─────────────────────────────────────────────────────────────┐
│                   PASO 1: VERIFICACIÓN                      │
│                                                             │
│  kubeadm certs check-expiration                            │
│         │                                                   │
│         ├─→ apiserver.crt           expires in 250 days    │
│         ├─→ apiserver-kubelet.crt   expires in 250 days    │
│         ├─→ front-proxy-client.crt  expires in 250 days    │
│         ├─→ etcd/server.crt         expires in 250 days    │
│         └─→ ... (otros certificados)                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   PASO 2: BACKUP                            │
│                                                             │
│  cp -r /etc/kubernetes/pki /root/pki-backup-$(date +%F)    │
│  cp /etc/kubernetes/admin.conf /root/admin.conf.bak        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   PASO 3: RENOVACIÓN                        │
│                                                             │
│  Option A: Renovar todos                                   │
│    kubeadm certs renew all                                 │
│                                                             │
│  Option B: Renovar uno específico                          │
│    kubeadm certs renew apiserver                           │
│    kubeadm certs renew apiserver-kubelet-client            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   PASO 4: RESTART                           │
│                                                             │
│  systemctl restart kubelet                                 │
│  kubectl delete pod -n kube-system kube-apiserver-*        │
│  kubectl delete pod -n kube-system kube-controller-*       │
│  kubectl delete pod -n kube-system kube-scheduler-*        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   PASO 5: VERIFICACIÓN                      │
│                                                             │
│  kubeadm certs check-expiration    (debe mostrar ~1 año)   │
│  kubectl get nodes                 (todos Ready)            │
│  kubectl get pods -A               (todos Running)          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📖 Conceptos Clave

### 1. Tipos de Certificados

| Certificado | Propósito | Ubicación | Duración |
|------------|-----------|-----------|----------|
| **ca.crt** | Certificate Authority raíz | `/etc/kubernetes/pki/` | 10 años |
| **apiserver.crt** | Identidad del API Server | `/etc/kubernetes/pki/` | 1 año |
| **apiserver-kubelet-client.crt** | API Server → kubelet auth | `/etc/kubernetes/pki/` | 1 año |
| **front-proxy-client.crt** | Aggregation layer | `/etc/kubernetes/pki/` | 1 año |
| **etcd/server.crt** | etcd server identity | `/etc/kubernetes/pki/etcd/` | 1 año |
| **etcd/peer.crt** | etcd peer-to-peer | `/etc/kubernetes/pki/etcd/` | 1 año |
| **admin.conf** | kubectl admin kubeconfig | `/etc/kubernetes/` | 1 año |

### 2. Autorenovación vs Renovación Manual

**Renovación Automática** (kubeadm NO la hace):
- Kubernetes NO renueva certificados automáticamente
- Responsabilidad del administrador monitorear expiración
- Configurar alertas para certificados próximos a expirar

**Renovación Manual** (este lab):
```bash
# Verificar antes de renovar
kubeadm certs check-expiration

# Renovar (opción 1: todos)
kubeadm certs renew all

# Renovar (opción 2: selectivo)
kubeadm certs renew apiserver
kubeadm certs renew apiserver-kubelet-client
```

### 3. Impacto de Certificados Expirados

| Certificado Expirado | Síntoma | Impacto |
|---------------------|---------|---------|
| **apiserver.crt** | `unable to connect to server: x509: certificate has expired` | 🔴 CLUSTER DOWN |
| **apiserver-kubelet-client.crt** | `kubectl logs/exec` falla | 🟡 Funcionalidad limitada |
| **kubelet.crt** | Nodos en NotReady | 🟡 Algunos nodos afectados |
| **admin.conf** | kubectl no conecta | 🟡 Admin no puede acceder |
| **etcd/server.crt** | etcd no arranca | 🔴 CLUSTER DOWN |

---

## 🛠️ Procedimiento del Laboratorio

### Parte 1: Verificación de Estado Actual

#### 1.1 Verificar Expiración de Certificados

```bash
# Método 1: kubeadm (recomendado)
sudo kubeadm certs check-expiration

# Output esperado:
# CERTIFICATE                     EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
# admin.conf                      May 10, 2026 09:15 UTC   364d            ca                      no
# apiserver                       May 10, 2026 09:15 UTC   364d            ca                      no
# apiserver-kubelet-client        May 10, 2026 09:15 UTC   364d            ca                      no
# ...
```

#### 1.2 Verificar Certificados Manualmente con OpenSSL

```bash
# Verificar apiserver.crt
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A2 Validity

# Output:
#     Validity
#         Not Before: May 10, 2025 09:15:00 GMT
#         Not After : May 10, 2026 09:15:00 GMT

# Verificar días restantes
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate
# notAfter=May 10 09:15:00 2026 GMT

# Calcular días exactos
echo $(( ($(date -d "$(sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate | cut -d= -f2)" +%s) - $(date +%s)) / 86400 ))
# Output: 250 (días restantes)
```

#### 1.3 Listar Todos los Certificados

```bash
# Crear script helper (incluido en check-certs.sh)
find /etc/kubernetes/pki -name "*.crt" -exec echo "Checking: {}" \; -exec openssl x509 -in {} -noout -enddate \;
```

### Parte 2: Backup de Certificados

⚠️ **CRÍTICO**: SIEMPRE hacer backup antes de renovar

```bash
# 1. Backup completo del directorio PKI
sudo cp -r /etc/kubernetes/pki /root/pki-backup-$(date +%F-%H%M)

# 2. Backup de kubeconfigs
sudo cp /etc/kubernetes/admin.conf /root/admin.conf.backup-$(date +%F)
sudo cp /etc/kubernetes/controller-manager.conf /root/controller-manager.conf.backup-$(date +%F)
sudo cp /etc/kubernetes/scheduler.conf /root/scheduler.conf.backup-$(date +%F)

# 3. Verificar backup
ls -lh /root/pki-backup-*
ls -lh /root/*.backup-*

# 4. (Opcional) Comprimir backup
sudo tar -czf /root/k8s-pki-backup-$(date +%F).tar.gz /etc/kubernetes/pki /etc/kubernetes/*.conf
```

### Parte 3: Renovación de Certificados

#### 3.1 Renovar TODOS los Certificados

```bash
# Renovar todos (1 comando)
sudo kubeadm certs renew all

# Output esperado:
# [renew] Reading configuration from the cluster...
# [renew] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
# 
# certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
# certificate for serving the Kubernetes API renewed
# certificate the apiserver uses to access etcd renewed
# certificate for the API server to connect to kubelet renewed
# ...
# 
# Done renewing certificates. You must restart the kube-apiserver, kube-controller-manager, 
# kube-scheduler and etcd, so that they can use the new certificates.
```

#### 3.2 Renovar Certificados Específicos

```bash
# Listar certificados renovables
sudo kubeadm certs renew --help | grep "  kubeadm certs renew"

# Renovar solo apiserver
sudo kubeadm certs renew apiserver

# Renovar solo apiserver-kubelet-client
sudo kubeadm certs renew apiserver-kubelet-client

# Renovar solo admin.conf
sudo kubeadm certs renew admin.conf
```

#### 3.3 Verificar Renovación

```bash
# Verificar nuevas fechas
sudo kubeadm certs check-expiration

# Deberías ver:
# admin.conf                      Nov 13, 2026 23:45 UTC   364d            ca                      no
#                                 ^^^^^^^^^^^^^ NUEVA FECHA (1 año desde hoy)
```

### Parte 4: Restart de Componentes

⚠️ **IMPORTANTE**: Los componentes deben reiniciarse para usar los nuevos certificados

#### 4.1 Restart kubelet

```bash
# Restart del kubelet
sudo systemctl restart kubelet

# Verificar estado
sudo systemctl status kubelet
```

#### 4.2 Restart Control Plane Pods (Static Pods)

```bash
# Método 1: Mover manifiestos temporalmente (fuerza recreación)
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

sudo mv /etc/kubernetes/manifests/kube-controller-manager.yaml /tmp/
sleep 5
sudo mv /tmp/kube-controller-manager.yaml /etc/kubernetes/manifests/

sudo mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/
sleep 5
sudo mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/

# Método 2: Usando docker/crictl (si no funciona método 1)
# Encontrar container IDs
sudo crictl ps | grep kube-apiserver
sudo crictl stop <container-id>

# kubelet recreará el pod automáticamente
```

#### 4.3 Verificar Pods Corriendo

```bash
# Esperar a que pods estén Running
watch kubectl get pods -n kube-system

# Deberían estar Running:
# - kube-apiserver-*
# - kube-controller-manager-*
# - kube-scheduler-*
# - etcd-*
```

### Parte 5: Actualizar kubeconfig del Usuario

```bash
# El admin.conf fue renovado, copiar a usuario
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Verificar conectividad
kubectl get nodes
kubectl get pods -A
```

### Parte 6: Verificación Final

```bash
# 1. Verificar que certificados tienen ~1 año
sudo kubeadm certs check-expiration | grep "RESIDUAL TIME"
# Debería mostrar ~364d en todos

# 2. Verificar cluster funcional
kubectl cluster-info
kubectl get nodes
kubectl get pods -A

# 3. Verificar que puedes hacer operaciones
kubectl run test-cert --image=nginx:alpine --restart=Never
kubectl get pod test-cert
kubectl delete pod test-cert

# 4. Verificar logs de API Server
sudo journalctl -u kubelet | tail -50
kubectl logs -n kube-system kube-apiserver-$(hostname) | tail -20
```

---

## 🔧 Troubleshooting

### Escenario 1: "certificate has expired" Error

**Síntomas**:
```
Unable to connect to the server: x509: certificate has expired or is not yet valid
```

**Diagnóstico**:
```bash
# Verificar qué certificado expiró
sudo kubeadm certs check-expiration

# Verificar manualmente con openssl
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
```

**Solución**:
```bash
# Si kubectl no funciona, usar la API directamente con curl y certificado válido
# O usar el CA cert para verificar

# Renovar todos los certificados
sudo kubeadm certs renew all

# Restart componentes
sudo systemctl restart kubelet
sudo mv /etc/kubernetes/manifests/*.yaml /tmp/
sleep 10
sudo mv /tmp/*.yaml /etc/kubernetes/manifests/
```

### Escenario 2: kubectl Falla Después de Renovar

**Síntomas**:
```bash
kubectl get nodes
# Error: error: You must be logged in to the server (Unauthorized)
```

**Causa**: El kubeconfig del usuario no fue actualizado

**Solución**:
```bash
# Copiar el nuevo admin.conf
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Verificar
kubectl get nodes
```

### Escenario 3: API Server No Arranca Después de Renovar

**Síntomas**:
```bash
kubectl get nodes
# Unable to connect to the server: dial tcp: connect: connection refused
```

**Diagnóstico**:
```bash
# Verificar logs del kubelet
sudo journalctl -u kubelet -f

# Verificar static pods
sudo crictl ps -a | grep kube-apiserver

# Verificar manifiesto
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml
```

**Solución**:
```bash
# Verificar permisos de certificados
sudo chmod 600 /etc/kubernetes/pki/*.key
sudo chown root:root /etc/kubernetes/pki/*

# Si persiste, restaurar backup
sudo rm -rf /etc/kubernetes/pki
sudo cp -r /root/pki-backup-FECHA /etc/kubernetes/pki

# Restart kubelet
sudo systemctl restart kubelet
```

### Escenario 4: Certificado Renovado Pero Expiración No Cambia

**Síntomas**:
```bash
sudo kubeadm certs renew apiserver
# certificate for serving the Kubernetes API renewed

sudo kubeadm certs check-expiration
# apiserver    May 10, 2026 09:15 UTC   250d    <-- NO CAMBIÓ
```

**Causa**: Componentes no fueron reiniciados

**Solución**:
```bash
# Los certificados FUERON renovados, pero los pods usan los viejos en memoria
# Forzar restart de API Server
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# Verificar nuevamente
sleep 30
sudo kubeadm certs check-expiration
# Ahora debería mostrar ~364d
```

### Escenario 5: etcd No Arranca Después de Renovar

**Síntomas**:
```bash
kubectl get pods -n kube-system
# etcd-master     0/1   Error   5     2m
```

**Diagnóstico**:
```bash
# Logs de etcd
sudo journalctl -u kubelet | grep etcd

# Verificar certificados de etcd
sudo openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -issuer -subject
```

**Solución**:
```bash
# Verificar que los certificados de etcd también fueron renovados
sudo kubeadm certs renew etcd-server
sudo kubeadm certs renew etcd-peer
sudo kubeadm certs renew etcd-healthcheck-client

# Restart etcd
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/
sleep 10
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/

# Verificar
watch kubectl get pods -n kube-system
```

---

## 📝 Comandos Esenciales para CKA

### Verificación de Certificados

```bash
# Comando principal del examen
kubeadm certs check-expiration

# Verificar certificado específico con openssl
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text

# Ver solo fechas
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
```

### Renovación

```bash
# Renovar todos (más común en examen)
kubeadm certs renew all

# Renovar uno específico
kubeadm certs renew apiserver
kubeadm certs renew admin.conf
```

### Post-Renovación

```bash
# Restart kubelet (SIEMPRE necesario)
systemctl restart kubelet

# Actualizar kubeconfig del usuario
cp /etc/kubernetes/admin.conf ~/.kube/config

# Verificar cluster
kubectl get nodes
kubectl get pods -A
```

---

## 🎓 Preparación para el Examen CKA

### Escenario Típico en el Examen

**Pregunta**:
> "Los certificados del cluster están próximos a expirar. Renueva todos los certificados del control plane y verifica que el cluster funciona correctamente después de la renovación."

**Solución (5-7 minutos)**:

```bash
# 1. Verificar expiración actual (30 seg)
sudo kubeadm certs check-expiration

# 2. Backup (opcional pero recomendado) (30 seg)
sudo cp -r /etc/kubernetes/pki /root/pki-backup-$(date +%F)

# 3. Renovar todos los certificados (1 min)
sudo kubeadm certs renew all

# 4. Restart kubelet (15 seg)
sudo systemctl restart kubelet

# 5. Restart static pods (1 min)
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

sudo mv /etc/kubernetes/manifests/kube-controller-manager.yaml /tmp/
sleep 5
sudo mv /tmp/kube-controller-manager.yaml /etc/kubernetes/manifests/

# 6. Actualizar kubeconfig (15 seg)
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# 7. Verificar (1-2 min)
kubectl get nodes
kubectl get pods -A
sudo kubeadm certs check-expiration | head -5
```

### Tips del Examen

1. ✅ **`kubeadm certs renew all`** es el comando más rápido
2. ✅ **SIEMPRE restart kubelet** después de renovar
3. ✅ **Actualizar ~/.kube/config** o kubectl fallará
4. ✅ **Verificar `kubectl get nodes`** antes de finalizar
5. ⚠️ **NO olvides reiniciar API Server** (componentes no leen nuevos certs automáticamente)

---

## 🧪 Ejercicios Prácticos

### Ejercicio 1: Verificación Completa

Tarea: Verificar el estado de todos los certificados y crear un reporte

```bash
# 1. Verificar con kubeadm
sudo kubeadm certs check-expiration > /tmp/cert-report.txt

# 2. Verificar manualmente cada certificado
for cert in /etc/kubernetes/pki/*.crt /etc/kubernetes/pki/etcd/*.crt; do
    echo "Certificate: $cert"
    sudo openssl x509 -in "$cert" -noout -subject -enddate
    echo "---"
done >> /tmp/cert-report.txt

# 3. Revisar reporte
cat /tmp/cert-report.txt
```

### Ejercicio 2: Renovación Selectiva

Tarea: Renovar solo los certificados del API Server

```bash
# 1. Verificar estado antes
sudo kubeadm certs check-expiration | grep apiserver

# 2. Renovar certificados relacionados con API Server
sudo kubeadm certs renew apiserver
sudo kubeadm certs renew apiserver-kubelet-client
sudo kubeadm certs renew apiserver-etcd-client

# 3. Restart solo API Server
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# 4. Verificar
sleep 30
kubectl get pods -n kube-system
sudo kubeadm certs check-expiration | grep apiserver
```

### Ejercicio 3: Simulación de Certificado Expirado

⚠️ **ADVERTENCIA**: Solo en cluster de prueba

Tarea: Simular expiración y recuperar

```bash
# 1. Backup
sudo cp -r /etc/kubernetes/pki /root/pki-original

# 2. Simular expiración (cambiar fecha del sistema)
sudo timedatectl set-ntp false
sudo date -s "2026-06-01"

# 3. Intentar usar kubectl
kubectl get nodes
# Error: x509: certificate has expired

# 4. Restaurar fecha
sudo date -s "2025-11-13"
sudo timedatectl set-ntp true

# 5. Renovar certificados
sudo kubeadm certs renew all
sudo systemctl restart kubelet
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# 6. Verificar
kubectl get nodes
```

---

## 📚 Referencias

### Documentación Oficial

- [Certificate Management - Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [PKI Certificates and Requirements](https://kubernetes.io/docs/setup/best-practices/certificates/)
- [kubeadm certs Command Reference](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-certs/)

### Comandos de Referencia Rápida

```bash
# Verificar expiración
kubeadm certs check-expiration

# Renovar todos
kubeadm certs renew all

# Renovar específico
kubeadm certs renew <cert-name>

# Listar renovables
kubeadm certs renew --help

# Verificar con openssl
openssl x509 -in <cert-file> -noout -text

# Restart kubelet
systemctl restart kubelet

# Actualizar kubeconfig
cp /etc/kubernetes/admin.conf ~/.kube/config
```

---

## ✅ Checklist de Finalización

Antes de completar este lab, asegúrate de:

- [ ] Verificar expiración con `kubeadm certs check-expiration`
- [ ] Hacer backup completo de `/etc/kubernetes/pki`
- [ ] Renovar certificados con `kubeadm certs renew all`
- [ ] Reiniciar kubelet con `systemctl restart kubelet`
- [ ] Reiniciar static pods (apiserver, controller, scheduler)
- [ ] Actualizar `~/.kube/config` del usuario
- [ ] Verificar cluster funcional con `kubectl get nodes`
- [ ] Verificar nuevas fechas de expiración (debe mostrar ~364d)
- [ ] Ejecutar `cleanup.sh` para limpiar recursos de prueba

---

## 🎯 Criterios de Éxito

Este laboratorio se considera exitoso cuando:

1. ✅ Todos los certificados muestran ~364 días de validez
2. ✅ `kubectl get nodes` muestra todos los nodos Ready
3. ✅ Todos los pods en kube-system están Running
4. ✅ Puedes crear y eliminar recursos con kubectl
5. ✅ No hay errores de certificados en los logs del kubelet
6. ✅ El script `verify-certs.sh` pasa todas las verificaciones

---

**IMPORTANTE**: Los certificados de Kubernetes son críticos para la seguridad del cluster. SIEMPRE verifica las fechas de expiración regularmente y renueva con anticipación suficiente (30-60 días antes).

En producción, considera:
- Configurar alertas de monitoreo para certificados próximos a expirar
- Automatizar la renovación (scripting + cron)
- Documentar el procedimiento para el equipo
- Probar el proceso en ambientes de staging primero
