# Setup - Lab 02: Secret from File

## 🔧 Prerequisitos del Sistema

### Software Requerido

| Herramienta | Versión Mínima | Verificación |
|------------|----------------|--------------|
| **kubectl** | 1.24+ | `kubectl version --client` |
| **openssl** | 1.1.1+ | `openssl version` |
| **curl** | 7.0+ | `curl --version` |

### Comandos de Verificación

```bash
# Verificar cluster
kubectl cluster-info

# Verificar openssl (para generar certificados)
openssl version

# Verificar curl (para testing HTTPS)
curl --version
```

---

## 🎯 Configuración del Entorno

### 1. Verificar Permisos

```bash
kubectl auth can-i create secrets
kubectl auth can-i create pods
```

### 2. Preparar Directorio

```bash
mkdir -p ~/k8s-labs/lab-secrets-files
cd ~/k8s-labs/lab-secrets-files
```

---

## ✅ Checklist Pre-Lab

- [ ] Cluster K8s funcionando
- [ ] kubectl configurado
- [ ] openssl instalado
- [ ] curl disponible
- [ ] Lab 01 completado

**[▶️ Comenzar Lab 02](./README.md)**
