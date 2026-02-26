# SETUP - Lab 3.7: Cluster Multi-Nodo con Minikube

## Prerequisitos

### Software requerido

| Componente | Version minima | Verificacion |
|------------|---------------|--------------|
| Minikube | v1.32.0+ | `minikube version` |
| kubectl | v1.28.0+ | `kubectl version --client` |
| Docker | 24.0+ | `docker --version` |

### Recursos del sistema

| Recurso | Minimo | Recomendado | Verificacion |
|---------|--------|-------------|--------------|
| CPUs | 8 cores | 10+ cores | `nproc` |
| RAM | 16 GB | 20+ GB | `free -h` |
| Disco | 40 GB libres | 60+ GB libres | `df -h /` |

> **Nota**: El cluster multi-nodo requiere significativamente mas recursos que un cluster de un solo nodo. Cada nodo consume 2 CPUs y 4 GB de RAM.

### Labs previos completados

- [ ] Lab 3.2: Docker instalado y funcionando
- [ ] Lab 3.3: kubectl instalado y configurado
- [ ] Lab 3.4: Minikube instalado

---

## Verificacion del entorno

Ejecuta este script para verificar que tu entorno esta listo:

```bash
#!/bin/bash
echo "=== VERIFICACION DE PREREQUISITOS - Lab 3.7 ==="
echo ""

ERRORS=0

# Verificar Minikube
if command -v minikube &> /dev/null; then
    echo "✅ Minikube: $(minikube version --short 2>/dev/null || minikube version | head -1)"
else
    echo "❌ Minikube no esta instalado"
    ERRORS=$((ERRORS + 1))
fi

# Verificar kubectl
if command -v kubectl &> /dev/null; then
    echo "✅ kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client | head -1)"
else
    echo "❌ kubectl no esta instalado"
    ERRORS=$((ERRORS + 1))
fi

# Verificar Docker
if command -v docker &> /dev/null && docker ps &> /dev/null; then
    echo "✅ Docker: $(docker --version)"
else
    echo "❌ Docker no esta funcionando"
    ERRORS=$((ERRORS + 1))
fi

# Verificar CPUs (necesitamos al menos 8)
CPUS=$(nproc)
if [ "$CPUS" -ge 8 ]; then
    echo "✅ CPUs: $CPUS cores disponibles"
else
    echo "⚠️  CPUs: $CPUS cores (recomendado: 8+, podrias necesitar reducir --cpus o --nodes)"
fi

# Verificar RAM (necesitamos al menos 16 GB)
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$((RAM_KB / 1024 / 1024))
if [ "$RAM_GB" -ge 16 ]; then
    echo "✅ RAM: ${RAM_GB} GB disponibles"
else
    echo "⚠️  RAM: ${RAM_GB} GB (recomendado: 16+ GB, podrias necesitar reducir --memory o --nodes)"
fi

# Verificar disco
DISK_AVAIL=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
if [ "$DISK_AVAIL" -ge 40 ]; then
    echo "✅ Disco: ${DISK_AVAIL} GB libres"
else
    echo "⚠️  Disco: ${DISK_AVAIL} GB libres (recomendado: 40+ GB)"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "🎉 Entorno listo para el Lab 3.7"
else
    echo "❌ Corrige $ERRORS error(es) antes de continuar"
fi
```

---

## Alternativas si no tienes suficientes recursos

Si tu maquina no tiene 8 CPUs o 16 GB de RAM, puedes ajustar los parametros:

```bash
# Opcion A: 3 nodos con menos recursos
minikube start -p k8s-lab --nodes=3 --cpus=1 --memory=2048mb

# Opcion B: 2 nodos (1 control plane + 1 worker)
minikube start -p k8s-lab --nodes=2 --cpus=2 --memory=3072mb
```

El laboratorio funciona con cualquier configuracion multi-nodo (2+ nodos), aunque los ejemplos de distribucion de pods son mas visibles con 4 nodos.
