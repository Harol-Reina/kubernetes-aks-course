# ⚙️ Setup - Lab 02: HostPath Volume

## 📋 Prerequisitos

### Cluster Kubernetes

- ✅ **Minikube recomendado** (para acceso fácil al nodo)
- ✅ kubectl configurado
- ✅ Permisos admin en el cluster
- ⚠️ **Cluster multi-nodo**: Requiere configuración adicional

### Acceso al Nodo

**Para Minikube**:
```bash
# Verificar acceso SSH al nodo
minikube ssh echo "Access OK"
```

**Para otros clusters**:
- Acceso SSH a los nodos o
- Herramienta de administración del cluster

---

## 🛠️ Herramientas Necesarias

| Herramienta | Versión Mínima | Verificación |
|-------------|----------------|--------------|
| kubectl | 1.24+ | `kubectl version --client` |
| Minikube | 1.30+ (opcional) | `minikube version` |
| SSH | Cualquiera | `ssh -V` |

---

## 📦 Preparación del Nodo

### Crear Directorio de Prueba

**Para Minikube**:

```bash
# Acceder al nodo
minikube ssh

# Crear directorio
sudo mkdir -p /mnt/data
sudo chmod 777 /mnt/data

# Crear archivo de prueba
echo "Hello from host node" | sudo tee /mnt/data/test.txt

# Verificar
ls -la /mnt/data/

# Salir
exit
```

**Para cluster remoto**: Ejecuta comandos equivalentes vía SSH en cada nodo.

---

## ⚠️ Consideraciones de Seguridad

**Importante**:
- HostPath expone el filesystem del nodo
- En producción, usa PodSecurityPolicy o SecurityContext estrictos
- Solo para desarrollo/testing o DaemonSets específicos

**Verificar permisos**:

```bash
# Verificar si puedes crear Pods con hostPath
kubectl auth can-i create pods
# Esperado: yes

# Algunos clusters pueden bloquear hostPath con policies
kubectl get psp 2>/dev/null
```

---

## ✅ Validación Pre-Lab

```bash
# 1. Cluster accesible
kubectl get nodes
# Esperado: Al menos 1 nodo Ready

# 2. Directorio creado en el nodo
minikube ssh "ls -la /mnt/data/test.txt"
# Esperado: -rwxrwxrwx ... test.txt

# 3. Permisos de escritura
minikube ssh "echo 'test' > /mnt/data/write-test.txt && rm /mnt/data/write-test.txt"
# Esperado: Sin errores
```

---

## 🚀 ¡Listo para Comenzar!

Si todas las validaciones pasaron, procede con el [README.md](./README.md) del laboratorio.

---

## 🆘 Troubleshooting Setup

### Error: Cannot access /mnt/data

**Solución**:
```bash
minikube ssh "sudo mkdir -p /mnt/data && sudo chmod 777 /mnt/data"
```

### Error: PodSecurityPolicy blocks hostPath

**Solución**: En desarrollo local, desactiva PSP o ajusta políticas. En producción, consulta con tu admin.

### Cluster multi-nodo: Directorio no existe en todos los nodos

**Solución**: Usa `nodeSelector` para garantizar scheduling en el nodo correcto, o crea el directorio en todos los nodos.

---

**📌 Nota**: HostPath es principalmente para desarrollo local. Para producción, usa PersistentVolumes con storage backends apropiados.
