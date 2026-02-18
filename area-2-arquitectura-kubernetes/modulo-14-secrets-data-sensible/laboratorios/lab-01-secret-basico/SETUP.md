# Setup - Lab 01: Secret Básico

## 🔧 Prerequisitos del Sistema

### Software Requerido

| Herramienta | Versión Mínima | Verificación |
|------------|----------------|--------------|
| **kubectl** | 1.24+ | `kubectl version --client` |
| **minikube** o cluster K8s | 1.24+ | `kubectl version --short` |
| **bash/zsh** | Cualquiera | `echo $SHELL` |

### Comandos de Verificación

```bash
# Verificar conexión al cluster
kubectl cluster-info

# Verificar nodos disponibles
kubectl get nodes

# Verificar namespace actual
kubectl config view --minified | grep namespace
```

---

## 🎯 Configuración del Entorno

### 1. Crear Namespace para el Lab (Opcional)

```bash
# Crear namespace dedicado
kubectl create namespace lab-secrets

# Cambiar al namespace
kubectl config set-context --current --namespace=lab-secrets

# Verificar
kubectl config view --minified | grep namespace
```

### 2. Verificar Permisos

```bash
# Verificar que puedes crear secrets
kubectl auth can-i create secrets
# Debe retornar: yes

# Verificar que puedes crear pods
kubectl auth can-i create pods
# Debe retornar: yes
```

### 3. Preparar Directorio de Trabajo

```bash
# Crear directorio para archivos del lab
mkdir -p ~/k8s-labs/lab-secrets-basico
cd ~/k8s-labs/lab-secrets-basico

# Verificar ubicación
pwd
```

---

## 📋 Recursos Necesarios

### Recursos del Cluster

| Recurso | Cantidad | Razón |
|---------|----------|-------|
| **CPU** | 0.1 cores | Pod nginx ligero |
| **Memoria** | 64Mi | Contenedor Alpine mínimo |
| **Secrets** | 2 | db-credentials + db-credentials-yaml |
| **Pods** | 1 | app-with-db |

### Verificar Recursos Disponibles

```bash
# Ver recursos del cluster
kubectl top nodes 2>/dev/null || echo "Metrics server no disponible (opcional)"

# Ver cuota del namespace (si existe)
kubectl get resourcequota
```

---

## 🧪 Prueba de Entorno

### Script de Verificación Rápida

```bash
# Crear archivo test-setup.sh
cat > test-setup.sh << 'EOF'
#!/bin/bash

echo "🔍 Verificando entorno para Lab 01: Secret Básico..."
echo

# Test 1: kubectl disponible
if command -v kubectl &> /dev/null; then
    echo "✅ kubectl instalado: $(kubectl version --client --short 2>/dev/null | head -n1)"
else
    echo "❌ kubectl NO encontrado"
    exit 1
fi

# Test 2: Cluster accesible
if kubectl cluster-info &> /dev/null; then
    echo "✅ Cluster accesible"
else
    echo "❌ No se puede conectar al cluster"
    exit 1
fi

# Test 3: Permisos de secrets
if kubectl auth can-i create secrets &> /dev/null; then
    echo "✅ Permisos para crear secrets"
else
    echo "❌ Sin permisos para crear secrets"
    exit 1
fi

# Test 4: Permisos de pods
if kubectl auth can-i create pods &> /dev/null; then
    echo "✅ Permisos para crear pods"
else
    echo "❌ Sin permisos para crear pods"
    exit 1
fi

# Test 5: base64 disponible
if command -v base64 &> /dev/null; then
    echo "✅ base64 disponible"
else
    echo "❌ base64 NO encontrado"
    exit 1
fi

echo
echo "🎉 Entorno listo para el laboratorio!"
EOF

chmod +x test-setup.sh
./test-setup.sh
```

---

## 🚨 Troubleshooting del Setup

### Problema: "kubectl not found"

```bash
# Instalar kubectl (Linux)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verificar
kubectl version --client
```

### Problema: "connection refused"

```bash
# Si usas minikube
minikube status
minikube start

# Verificar configuración
kubectl config current-context
```

### Problema: "forbidden: User cannot create secrets"

```bash
# Verificar usuario actual
kubectl config view --minified

# Si estás en minikube, deberías tener permisos completos
# En cluster corporativo, contacta al administrador
```

---

## 📚 Conocimientos Previos Requeridos

Antes de comenzar este lab, deberías saber:

### Conceptos de Kubernetes
- ✅ Qué es un **Pod**
- ✅ Cómo usar `kubectl apply`
- ✅ Cómo ver logs con `kubectl logs`
- ✅ Cómo ejecutar comandos en pods (`kubectl exec`)

### Conceptos de Linux/Bash
- ✅ Comandos básicos de shell (`cat`, `ls`, `echo`)
- ✅ Redirección de salida (`>`, `>>`)
- ✅ Variables de entorno

### Conceptos de Base64
- ✅ Qué es codificación base64
- ✅ Diferencia entre codificación y encriptación

---

## 🎓 Módulos Relacionados

Asegúrate de haber completado:

1. **Módulo 04**: Pods vs Contenedores
   - Entender qué es un Pod
   - Crear pods simples

2. **Módulo 05**: Gestión de Pods
   - `kubectl exec` para entrar a pods
   - `kubectl logs` para ver salidas

3. **Módulo 13**: ConfigMaps
   - Concepto de configuración externa
   - Volúmenes vs variables de entorno

---

## ✅ Checklist Pre-Lab

Marca cada item antes de comenzar:

- [ ] Cluster de Kubernetes funcionando
- [ ] `kubectl` instalado y configurado
- [ ] Permisos para crear secrets y pods
- [ ] Comando `base64` disponible
- [ ] Namespace configurado (opcional)
- [ ] Directorio de trabajo creado
- [ ] Script de verificación ejecutado exitosamente

---

## 🚀 Listo para Comenzar

Si todos los checks pasaron, estás listo para:

**[▶️ Comenzar Lab 01: Secret Básico](./README.md)**

---

## 📞 Soporte

Si tienes problemas con el setup:

1. Revisa la sección de Troubleshooting
2. Verifica que tu cluster esté funcionando (`kubectl get nodes`)
3. Asegúrate de tener permisos suficientes
4. Consulta los logs del cluster si es necesario

**Tiempo estimado de setup**: 5-10 minutos
