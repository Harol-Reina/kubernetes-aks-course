# Ejemplo 02: Containerd Configuration

## 🎯 Objetivo
Archivo de configuración de containerd para uso con Kubernetes.

## 📝 Descripción
Configuración completa de containerd (config.toml) incluyendo:
- CRI plugin configuration
- Registry mirrors
- systemd cgroup driver
- Runtime options

## 🚀 Uso

```bash
# Copiar al sistema (requiere sudo)
sudo cp containerd-config.toml /etc/containerd/config.toml

# Reiniciar containerd
sudo systemctl restart containerd

# Verificar status
sudo systemctl status containerd
```

## 📊 Configuraciones importantes

- `SystemdCgroup = true` - Usa systemd como cgroup driver
- Registry mirrors configurados
- Sandbox image especificado
- Plugins habilitados

## 🧪 Verificación

```bash
# Ver configuración aplicada
sudo containerd config dump

# Test de contenedor
sudo ctr images pull docker.io/library/nginx:alpine
sudo ctr run --rm docker.io/library/nginx:alpine test nginx -v
```

## ⚠️ Nota
Este archivo debe colocarse en `/etc/containerd/config.toml` en cada nodo del cluster.

[Volver a ejemplos](../README.md)
