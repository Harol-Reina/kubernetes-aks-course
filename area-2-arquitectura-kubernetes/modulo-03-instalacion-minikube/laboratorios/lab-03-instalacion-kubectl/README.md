# Lab 3.3: Instalación de kubectl

**Duración**: 15 minutos  
**Objetivo**: Instalar kubectl y configurar autocompletado para gestión de Kubernetes

## 🎯 Objetivos

- Instalar la herramienta kubectl
- Configurar autocompletado de bash
- Verificar funcionalidad básica
- Preparar configuración para Minikube

---

## 📋 Prerequisitos

- VM con Docker instalado (Lab 3.2 completado)
- Conexión SSH activa
- Acceso a internet

---

## 📥 Paso 1: Descargar e instalar kubectl

### **Método 1: Descarga directa (Recomendado)**

```bash
# Obtener la última versión estable
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
echo "Última versión estable: $KUBECTL_VERSION"

# Descargar kubectl
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"

# Verificar checksum (opcional pero recomendado)
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Instalar kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verificar instalación
kubectl version --client
```

### **Método 2: Usando repositorio de paquetes**

```bash
# Actualizar índice y instalar dependencias
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl

# Descargar clave de firma
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

# Agregar repositorio
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Actualizar e instalar
sudo apt update
sudo apt install -y kubectl

# Verificar instalación
kubectl version --client
```

**Salida esperada:**
```
Client Version: version.Info{Major:"1", Minor:"28", GitVersion:"v1.28.4"...}
```

---

## 🔧 Paso 2: Configurar autocompletado de bash

```bash
# Verificar que kubectl funciona
kubectl version --client --output=yaml

# Instalar autocompletado de bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc

# Crear alias 'k' para kubectl (opcional pero útil)
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc

# Recargar configuración de bash
source ~/.bashrc

# Verificar autocompletado (probar con TAB)
echo "Prueba escribir 'kubectl get po' y presiona TAB"
```

---

## 📁 Paso 3: Configurar directorio de configuración

```bash
# Crear directorio de configuración de kubectl
mkdir -p ~/.kube

# Verificar permisos
ls -la ~/.kube

# Crear configuración temporal (se sobrescribirá con Minikube)
cat << 'EOF' > ~/.kube/config
apiVersion: v1
kind: Config
clusters: []
contexts: []
current-context: ""
preferences: {}
users: []
EOF

# Verificar configuración
kubectl config view

# Verificar contexto actual (debería estar vacío)
kubectl config current-context || echo "No hay contexto configurado aún"
```

---

## 🧪 Paso 4: Verificar kubectl básico

```bash
# Crear script de verificación
cat << 'EOF' > ~/verificar-kubectl.sh
# !/bin/bash

echo "=== VERIFICACIÓN DE KUBECTL ==="
echo ""

# Verificar versión
echo "📋 Versión de kubectl:"
kubectl version --client --short 2>/dev/null || kubectl version --client

# Verificar ubicación del binario
echo ""
echo "📍 Ubicación del binario:"
which kubectl

# Verificar permisos
echo ""
echo "🔐 Permisos del binario:"
ls -la $(which kubectl)

# Verificar configuración
echo ""
echo "⚙️ Configuración actual:"
if [ -f ~/.kube/config ]; then
    echo "✅ Archivo de configuración existe"
    echo "Ubicación: ~/.kube/config"
    echo "Contexto actual: $(kubectl config current-context 2>/dev/null || echo 'No configurado')"
else
    echo "❌ Archivo de configuración no existe"
fi

# Verificar autocompletado
echo ""
echo "💡 Autocompletado:"
if grep -q "kubectl completion bash" ~/.bashrc; then
    echo "✅ Autocompletado configurado en ~/.bashrc"
else
    echo "❌ Autocompletado no configurado"
fi

# Verificar alias
if grep -q "alias k=kubectl" ~/.bashrc; then
    echo "✅ Alias 'k' configurado"
else
    echo "ℹ️ Alias 'k' no configurado (opcional)"
fi

# Probar comandos básicos (sin cluster)
echo ""
echo "🧪 Pruebas básicas:"
echo "Comando 'kubectl cluster-info':"
kubectl cluster-info 2>&1 | head -2

echo ""
echo "Comando 'kubectl version':"
kubectl version --short 2>/dev/null || kubectl version 2>&1 | grep "Client Version"

echo ""
echo "=== RESUMEN ==="
if which kubectl &>/dev/null && [ -f ~/.kube/config ]; then
    echo "🎉 kubectl está correctamente instalado!"
    echo "📌 Listo para conectar con Minikube"
else
    echo "⚠️ kubectl requiere configuración adicional"
fi
EOF

# Ejecutar verificación
chmod +x ~/verificar-kubectl.sh
~/verificar-kubectl.sh
```

---

## 🎓 Paso 5: Comandos útiles para aprender

```bash
# Obtener ayuda de kubectl
kubectl --help

# Obtener ayuda de un comando específico
kubectl get --help

# Listar todos los comandos disponibles
kubectl api-resources

# Explicar un recurso de Kubernetes
kubectl explain pods

# Ver la estructura completa de un pod
kubectl explain pods --recursive

# Obtener ejemplos de uso
kubectl create deployment --help | grep -A 20 "Examples:"
```

---

## 📖 Paso 6: Configurar documentación y ayuda

```bash
# Crear aliases útiles para documentación
cat << 'EOF' >> ~/.bashrc

# Aliases útiles para kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

# Función para obtener ayuda rápida
khelp() {
    echo "Comandos básicos de kubectl:"
    echo "  kubectl get pods                    # Listar pods"
    echo "  kubectl get services               # Listar servicios"
    echo "  kubectl get deployments           # Listar deployments"
    echo "  kubectl describe pod <nombre>     # Describir pod"
    echo "  kubectl logs <pod>                # Ver logs de pod"
    echo "  kubectl exec -it <pod> -- bash    # Conectar a pod"
    echo "  kubectl apply -f <archivo>        # Aplicar configuración"
    echo "  kubectl delete -f <archivo>       # Eliminar configuración"
}
EOF

# Recargar bash
source ~/.bashrc

# Probar nueva función
khelp
```

---

## ✅ Resultado esperado

```
=== VERIFICACIÓN DE KUBECTL ===

📋 Versión de kubectl:
Client Version: v1.28.4

📍 Ubicación del binario:
/usr/local/bin/kubectl

🔐 Permisos del binario:
-rwxr-xr-x 1 root root 47185920 Nov  5 10:30 /usr/local/bin/kubectl

⚙️ Configuración actual:
✅ Archivo de configuración existe
Ubicación: ~/.kube/config
Contexto actual: No configurado

💡 Autocompletado:
✅ Autocompletado configurado en ~/.bashrc
✅ Alias 'k' configurado

🧪 Pruebas básicas:
Comando 'kubectl cluster-info':
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
The connection to the server localhost:8080 was refused

Comando 'kubectl version':
Client Version: v1.28.4

=== RESUMEN ===
🎉 kubectl está correctamente instalado!
📌 Listo para conectar con Minikube
```

**Nota**: Es normal que `kubectl cluster-info` falle porque aún no hay un cluster configurado.

---

## 🔧 Troubleshooting

### **Error: kubectl command not found**
```bash
# Verificar PATH
echo $PATH

# Verificar ubicación del binario
ls -la /usr/local/bin/kubectl

# Agregar al PATH si es necesario
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### **Error: Permission denied**
```bash
# Verificar permisos del binario
ls -la $(which kubectl)

# Corregir permisos si es necesario
sudo chmod +x /usr/local/bin/kubectl
```

### **Error: Autocompletado no funciona**
```bash
# Verificar que bash-completion está instalado
sudo apt install -y bash-completion

# Recargar configuración
source ~/.bashrc

# Verificar manualmente
kubectl completion bash
```

### **Error: No se puede escribir en ~/.bashrc**
```bash
# Verificar permisos del archivo
ls -la ~/.bashrc

# Crear archivo si no existe
touch ~/.bashrc

# Verificar propietario
sudo chown $USER:$USER ~/.bashrc
```

---

## 🧪 Paso 7: Preparar para Minikube

```bash
# Crear script que verificará la conexión con Minikube (para uso futuro)
cat << 'EOF' > ~/test-kubectl-minikube.sh
# !/bin/bash

echo "=== TEST DE CONECTIVIDAD KUBECTL-MINIKUBE ==="
echo ""

# Este script se usará después de instalar Minikube
echo "ℹ️ Este script se ejecutará después de configurar Minikube"

echo "Comandos que probaremos:"
echo "  kubectl cluster-info"
echo "  kubectl get nodes"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl config current-context"

echo ""
echo "📌 Por ahora, kubectl está listo para conectarse a Minikube"
EOF

chmod +x ~/test-kubectl-minikube.sh
```

---

## 📝 Checklist de completado

- [ ] kubectl instalado correctamente
- [ ] Versión de kubectl verificada
- [ ] Autocompletado configurado
- [ ] Alias útiles configurados
- [ ] Directorio ~/.kube creado
- [ ] Archivo de configuración básico creado
- [ ] Funciones de ayuda configuradas
- [ ] Script de verificación exitoso

---

## 🎯 Comandos que ahora funcionan

```bash
# Comandos básicos (sin cluster aún)
kubectl version --client
kubectl --help
kubectl explain pods

# Autocompletado (presiona TAB después de cada comando)
kubectl get <TAB>
kubectl describe <TAB>

# Aliases configurados
k version --client
khelp
```

---

**Siguiente paso**: [Lab 3.4: Instalación de Minikube](./instalacion-minikube.md)