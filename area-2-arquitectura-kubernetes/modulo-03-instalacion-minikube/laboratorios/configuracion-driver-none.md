# Lab 3.5: Configuración Driver "None"

**Duración**: 15 minutos  
**Objetivo**: Configurar Minikube con driver "none" para acceso directo a servicios

## 🎯 Objetivos

- Configurar Minikube con driver "none"
- Entender las implicaciones de seguridad
- Configurar kubelet correctamente
- Acceder a servicios directamente desde la VM

---

## 📋 Prerequisitos

- Minikube instalado (Lab 3.4)
- Docker funcionando correctamente
- kubectl configurado
- Acceso sudo en la VM

---

## ⚠️ Paso 1: Entender el driver "none"

```bash
# Mostrar información sobre el driver "none"
cat << 'EOF'
=== ¿QUÉ ES EL DRIVER "NONE"? ===

El driver "none" ejecuta Kubernetes directamente en el host (VM) sin contenedores 
o máquinas virtuales adicionales.

✅ VENTAJAS:
- Acceso directo a servicios (sin port-forwarding)
- Mejor rendimiento (sin overhead de virtualización)
- Usa los recursos completos de la VM
- Ideal para desarrollo y testing

⚠️ DESVENTAJAS:
- Requiere permisos root
- Modifica el sistema host
- Potenciales conflictos con otros servicios
- No aislamiento completo

🔒 CONSIDERACIONES DE SEGURIDAD:
- Solo usar en entornos de desarrollo
- NO usar en producción
- La VM debe ser dedicada para Kubernetes

🎯 CASO DE USO IDEAL:
- VM Azure dedicada para desarrollo
- Necesidad de acceso directo a servicios web
- Testing de aplicaciones con múltiples servicios

EOF

read -p "¿Entiendes las implicaciones y quieres continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operación cancelada por el usuario"
    exit 1
fi
```

---

## 🔧 Paso 2: Preparar el sistema para driver "none"

```bash
# Verificar requisitos previos
echo "=== VERIFICANDO REQUISITOS PARA DRIVER 'NONE' ==="

# Verificar que somos root o tenemos sudo
if [ "$EUID" -eq 0 ]; then
    echo "✅ Ejecutando como root"
elif sudo -n true 2>/dev/null; then
    echo "✅ Acceso sudo disponible"
else
    echo "❌ Requiere acceso root o sudo"
    exit 1
fi

# Verificar systemd
if systemctl --version &>/dev/null; then
    echo "✅ systemd disponible"
    systemctl --version | head -1
else
    echo "❌ systemd no disponible"
    exit 1
fi

# Verificar conectividad
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo "✅ Conectividad a Internet OK"
else
    echo "❌ Sin conectividad a Internet"
    exit 1
fi

# Verificar puertos necesarios
echo "🔍 Verificando puertos necesarios:"
PORTS=(6443 10250 10251 10252 2379 2380)
for port in "${PORTS[@]}"; do
    if netstat -tulnp | grep ":$port " &>/dev/null; then
        echo "⚠️ Puerto $port ya está en uso"
        netstat -tulnp | grep ":$port "
    else
        echo "✅ Puerto $port disponible"
    fi
done

# Verificar espacio en disco
AVAILABLE=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
if [ "$AVAILABLE" -lt 10 ]; then
    echo "⚠️ Poco espacio en disco: ${AVAILABLE}GB disponible (recomendado: 10GB+)"
else
    echo "✅ Espacio en disco suficiente: ${AVAILABLE}GB disponible"
fi

echo ""
echo "✅ Sistema preparado para driver 'none'"
```

---

## 🚀 Paso 3: Crear cluster con driver "none"

```bash
# Detener cualquier cluster existente
echo "=== PREPARANDO CLUSTER CON DRIVER 'NONE' ==="

# Detener Minikube si está ejecutándose
minikube stop 2>/dev/null || true
minikube delete 2>/dev/null || true

# Crear cluster con driver "none"
echo "🚀 Iniciando Minikube con driver 'none'..."
echo "⚠️ Esto requerirá permisos sudo"

# Configurar perfil para driver "none"
minikube config set profile none-cluster
minikube config set driver none

# Iniciar cluster (requiere sudo)
sudo minikube start --driver=none --profile=none-cluster

# Verificar estado
sudo minikube status --profile=none-cluster
```

**Salida esperada:**
```
✅ Using the none driver based on user configuration
✅ Starting control plane node none-cluster in cluster none-cluster
🤹 Running on localhost (CPUs=4, Memory=8192MB, Disk=25600MB)...
ℹ️ OS release is Ubuntu 22.04.3 LTS
🐳 Preparing Kubernetes v1.28.3 on Docker 24.0.7...
    ▪ kubelet.resolv-conf=/run/systemd/resolve/resolv.conf
    ▪ Generating certificates and keys...
    ▪ Booting up control plane...
    ▪ Configuring RBAC rules...
🤹 Configuring local host environment...
🔎 Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟 Enabled addons: default-storageclass, storage-provisioner
💡 kubectl is now configured to use "none-cluster" cluster and "default" namespace by default
```

---

## 🔧 Paso 4: Configurar permisos de kubectl

```bash
# El driver "none" requiere configuración especial de permisos
echo "=== CONFIGURANDO PERMISOS DE KUBECTL ==="

# Verificar ubicación del config de kubectl
sudo ls -la /root/.kube/config

# Copiar configuración a usuario regular
sudo cp /root/.kube/config ~/.kube/config

# Cambiar propietario del archivo de configuración
sudo chown $USER:$USER ~/.kube/config

# Verificar permisos
ls -la ~/.kube/config

# Probar kubectl
kubectl get nodes

# Verificar contexto actual
kubectl config current-context

# Verificar cluster info
kubectl cluster-info
```

---

## 🧪 Paso 5: Verificar funcionamiento del cluster

```bash
# Crear script de verificación completa
cat << 'EOF' > ~/verificar-cluster-none.sh
#!/bin/bash

echo "=== VERIFICACIÓN CLUSTER DRIVER 'NONE' ==="
echo ""

# Verificar estado de Minikube
echo "📊 Estado de Minikube:"
sudo minikube status --profile=none-cluster

# Verificar nodos
echo ""
echo "🖥️ Nodos del cluster:"
kubectl get nodes -o wide

# Verificar componentes del sistema
echo ""
echo "⚙️ Pods del sistema:"
kubectl get pods --all-namespaces

# Verificar servicios
echo ""
echo "🌐 Servicios disponibles:"
kubectl get services --all-namespaces

# Verificar API server
echo ""
echo "🔗 API Server:"
kubectl cluster-info

# Verificar addons habilitados
echo ""
echo "🔌 Addons habilitados:"
sudo minikube addons list --profile=none-cluster | grep enabled

# Verificar configuración de kubelet
echo ""
echo "🔧 Configuración de kubelet:"
sudo systemctl status kubelet --no-pager -l

# Verificar logs recientes
echo ""
echo "📋 Logs recientes de kubelet:"
sudo journalctl -u kubelet --no-pager -n 10

echo ""
echo "=== VERIFICACIÓN COMPLETADA ==="
EOF

chmod +x ~/verificar-cluster-none.sh
~/verificar-cluster-none.sh
```

---

## 🌐 Paso 6: Probar acceso directo a servicios

```bash
# Crear aplicación de prueba para verificar acceso directo
echo "=== PROBANDO ACCESO DIRECTO A SERVICIOS ==="

# Crear deployment de prueba
kubectl create deployment test-web --image=nginx:alpine

# Esperar a que el pod esté listo
kubectl wait --for=condition=ready pod -l app=test-web --timeout=60s

# Exponer el servicio
kubectl expose deployment test-web --port=80 --type=NodePort

# Obtener información del servicio
kubectl get service test-web

# Obtener puerto asignado
NODE_PORT=$(kubectl get service test-web -o jsonpath='{.spec.ports[0].nodePort}')
echo "Puerto NodePort asignado: $NODE_PORT"

# Obtener IP de la VM
VM_IP=$(hostname -I | awk '{print $1}')
echo "IP de la VM: $VM_IP"

# Probar acceso directo
echo ""
echo "🌐 Probando acceso directo al servicio:"
echo "URL del servicio: http://$VM_IP:$NODE_PORT"

# Probar con curl
if curl -s http://localhost:$NODE_PORT | grep -q "Welcome to nginx"; then
    echo "✅ Acceso directo funciona correctamente"
    echo "📌 El servicio es accesible en: http://$VM_IP:$NODE_PORT"
else
    echo "❌ Error en acceso directo"
fi

# Mostrar logs del pod
echo ""
echo "📋 Logs del pod de prueba:"
kubectl logs deployment/test-web

# Limpiar recursos de prueba
echo ""
read -p "¿Eliminar recursos de prueba? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete service test-web
    kubectl delete deployment test-web
    echo "Recursos de prueba eliminados"
fi
```

---

## 🔧 Paso 7: Configurar acceso desde fuera de la VM

```bash
# Crear script para abrir puertos en firewall (si es necesario)
cat << 'EOF' > ~/configurar-firewall.sh
#!/bin/bash

echo "=== CONFIGURACIÓN DE FIREWALL PARA ACCESO EXTERNO ==="
echo ""

# Verificar si ufw está activo
if sudo ufw status | grep -q "Status: active"; then
    echo "🔥 UFW firewall está activo"
    
    # Mostrar reglas actuales
    echo "Reglas actuales:"
    sudo ufw status numbered
    
    echo ""
    read -p "¿Abrir puerto 30000-32767 para NodePort services? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ufw allow 30000:32767/tcp
        echo "✅ Puertos NodePort abiertos"
    fi
    
    echo ""
    read -p "¿Abrir puerto 6443 para API Server? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ufw allow 6443/tcp
        echo "✅ Puerto API Server abierto"
    fi
    
else
    echo "ℹ️ UFW firewall no está activo"
fi

# Verificar reglas de iptables
echo ""
echo "📋 Reglas actuales de iptables:"
sudo iptables -L -n | grep -E "(30000|32767|6443)"

echo ""
echo "💡 Para acceder desde fuera de la VM:"
echo "  - Asegúrate de que Azure NSG permite el tráfico"
echo "  - Usa la IP pública de la VM"
echo "  - Formato: http://<IP_PUBLICA>:<NODE_PORT>"
EOF

chmod +x ~/configurar-firewall.sh

# Ejecutar configuración de firewall
~/configurar-firewall.sh
```

---

## 📊 Paso 8: Dashboard de Kubernetes (opcional)

```bash
# Habilitar dashboard de Kubernetes
echo "=== CONFIGURANDO DASHBOARD DE KUBERNETES ==="

# Habilitar addon de dashboard
sudo minikube addons enable dashboard --profile=none-cluster

# Verificar que el dashboard está ejecutándose
kubectl get pods -n kubernetes-dashboard

# Crear usuario admin para el dashboard
cat << 'EOF' > ~/dashboard-admin.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Aplicar configuración
kubectl apply -f ~/dashboard-admin.yaml

# Obtener token de acceso
echo ""
echo "🔑 Token para acceder al dashboard:"
kubectl -n kubernetes-dashboard create token admin-user

# Exponer dashboard como NodePort
kubectl patch service kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'

# Obtener puerto del dashboard
DASHBOARD_PORT=$(kubectl get service kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}')
VM_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🌐 Dashboard accesible en:"
echo "https://$VM_IP:$DASHBOARD_PORT"
echo ""
echo "⚠️ Nota: Usa HTTPS y acepta el certificado autofirmado"
echo "💡 Usa el token mostrado arriba para autenticarte"
```

---

## ✅ Paso 9: Verificación final

```bash
# Crear script de verificación final completa
cat << 'EOF' > ~/verificacion-final-none.sh
#!/bin/bash

echo "=== VERIFICACIÓN FINAL DRIVER 'NONE' ==="
echo ""

# Verificar estado general
echo "📊 Estado del sistema:"
echo "Sistema operativo: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Arquitectura: $(uname -m)"
echo "CPU: $(nproc) cores"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}') total, $(free -h | awk '/^Mem:/ {print $3}') usado"

# Verificar Minikube
echo ""
echo "🚀 Estado de Minikube:"
sudo minikube status --profile=none-cluster

# Verificar kubectl
echo ""
echo "🔧 Configuración de kubectl:"
kubectl config current-context
kubectl get nodes

# Verificar servicios del sistema
echo ""
echo "⚙️ Servicios críticos:"
kubectl get pods -n kube-system

# Verificar acceso directo
echo ""
echo "🌐 Verificando acceso directo:"
if kubectl get service kubernetes &>/dev/null; then
    KUBE_PORT=$(kubectl get service kubernetes -o jsonpath='{.spec.ports[0].port}')
    echo "✅ API Server accesible en puerto $KUBE_PORT"
else
    echo "❌ Problema con acceso al API Server"
fi

# Verificar addons
echo ""
echo "🔌 Addons habilitados:"
sudo minikube addons list --profile=none-cluster | grep enabled

# Verificar recursos disponibles
echo ""
echo "💻 Recursos disponibles para pods:"
kubectl top node 2>/dev/null || echo "ℹ️ Metrics server no disponible (normal)"

# Verificar DNS
echo ""
echo "🔍 Verificando DNS interno:"
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local 2>/dev/null || echo "DNS funcionando"

echo ""
echo "=== RESUMEN FINAL ==="
echo "✅ Minikube con driver 'none' está funcionando"
echo "✅ kubectl configurado correctamente"
echo "✅ Acceso directo a servicios disponible"
echo "✅ Cluster listo para desarrollo"

echo ""
echo "💡 Comandos útiles:"
echo "  kubectl get pods --all-namespaces    # Ver todos los pods"
echo "  kubectl get services                 # Ver servicios"
echo "  kubectl proxy                       # Proxy para API server"
echo "  sudo minikube dashboard              # Abrir dashboard"

echo ""
echo "🎯 El cluster está listo para el Lab 3.6: Verificación Final"
EOF

chmod +x ~/verificacion-final-none.sh
~/verificacion-final-none.sh
```

---

## ✅ Resultado esperado

```
=== VERIFICACIÓN FINAL DRIVER 'NONE' ===

📊 Estado del sistema:
Sistema operativo: Ubuntu 22.04.3 LTS
Kernel: 5.15.0-88-generic
Arquitectura: x86_64
CPU: 4 cores
RAM: 8.0Gi total, 2.1Gi usado

🚀 Estado de Minikube:
none-cluster
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

🔧 Configuración de kubectl:
none-cluster
NAME       STATUS   ROLES           AGE   VERSION
azurevm    Ready    control-plane   5m    v1.28.3

⚙️ Servicios críticos:
NAME                                READY   STATUS    RESTARTS   AGE
coredns-5d78c9869d-xyz12           1/1     Running   0          5m
etcd-azurevm                       1/1     Running   0          5m
kube-apiserver-azurevm             1/1     Running   0          5m
kube-controller-manager-azurevm    1/1     Running   0          5m
kube-proxy-abc34                   1/1     Running   0          5m
kube-scheduler-azurevm             1/1     Running   0          5m

🌐 Verificando acceso directo:
✅ API Server accesible en puerto 443

🔌 Addons habilitados:
| default-storageclass    | minikube | Enabled ✅  | gcr.io/k8s-minikube/storage-provisioner:v5 |
| storage-provisioner     | minikube | Enabled ✅  | gcr.io/k8s-minikube/storage-provisioner:v5 |

=== RESUMEN FINAL ===
✅ Minikube con driver 'none' está funcionando
✅ kubectl configurado correctamente
✅ Acceso directo a servicios disponible
✅ Cluster listo para desarrollo

💡 Comandos útiles:
  kubectl get pods --all-namespaces    # Ver todos los pods
  kubectl get services                 # Ver servicios
  kubectl proxy                       # Proxy para API server
  sudo minikube dashboard              # Abrir dashboard

🎯 El cluster está listo para el Lab 3.6: Verificación Final
```

---

## 🔧 Troubleshooting

### **Error: The "none" driver requires root privileges**
```bash
# Asegurarse de usar sudo
sudo minikube start --driver=none --profile=none-cluster
```

### **Error: kubectl configuration incorrect**
```bash
# Copiar configuración de root
sudo cp /root/.kube/config ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### **Error: Port already in use**
```bash
# Verificar qué proceso usa el puerto
sudo netstat -tulnp | grep :6443

# Detener Minikube y reiniciar
sudo minikube stop --profile=none-cluster
sudo minikube start --driver=none --profile=none-cluster
```

### **Error: Cannot access services externally**
```bash
# Verificar firewall
sudo ufw status
sudo ufw allow 30000:32767/tcp

# Verificar Azure NSG
# (Desde Azure Portal, verificar Network Security Group)
```

---

## 📝 Checklist de completado

- [ ] Driver "none" configurado correctamente
- [ ] Cluster iniciado con éxito
- [ ] kubectl funcionando sin sudo
- [ ] Acceso directo a servicios verificado
- [ ] Firewall configurado (si es necesario)
- [ ] Dashboard habilitado (opcional)
- [ ] Verificación final completada

---

## 🎯 Estado actual

✅ **Minikube ejecutándose con driver "none"**  
✅ **Acceso directo a servicios habilitado**  
✅ **kubectl configurado correctamente**  
✅ **Sistema listo para desarrollo**

---

**Siguiente paso**: [Lab 3.6: Verificación y Testing Final](./verificacion-testing-final.md)