# Lab 01: Crear y Administrar un Cluster AKS

**Duración:** 45 minutos | **Nivel:** Básico

## Objetivos

- Crear un cluster AKS desde Azure CLI
- Conectar kubectl al cluster
- Explorar los componentes del cluster
- Verificar el estado de nodos y system pods

## Técnicas y Conceptos Utilizados

| Técnica | Descripción |
|---------|-------------|
| `az aks create` | Creación de cluster gestionado |
| `az aks get-credentials` | Configuración de kubectl |
| `kubectl get nodes` | Verificación de nodos |
| `kubectl get pods -n kube-system` | Exploración de componentes del sistema |

## Archivos YAML del Laboratorio

| Archivo | Descripción |
|---------|-------------|
| N/A | Este lab usa comandos CLI, no archivos YAML |

---

## Paso 1: Preparar el Entorno (5 min)

### Verificar Azure CLI

```bash
# Verificar que Azure CLI está instalado
az version

# Verificar autenticación
az account show --query "{name:name, state:state}" -o table
```

**Salida esperada:**

```
Name                    State
----------------------  --------
Mi Suscripción Azure    Enabled
```

### Crear Resource Group

```bash
az group create --name rg-lab-aks --location eastus
```

## Paso 2: Crear Cluster AKS (10 min)

```bash
# Crear cluster con 2 nodos
# La creación tarda 5-10 minutos
az aks create \
  --resource-group rg-lab-aks \
  --name aks-lab-01 \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --enable-managed-identity \
  --generate-ssh-keys
```

**¿Qué pasa durante la creación?**
1. Azure crea las VMs para el control plane (ocultas para ti)
2. Azure crea las VMs para los worker nodes
3. Se instala Kubernetes en todos los nodos
4. Se configuran los certificados TLS
5. Se despliegan los componentes del sistema (CoreDNS, etc.)

## Paso 3: Conectar kubectl (2 min)

```bash
# Descargar credenciales y configurar kubectl
az aks get-credentials --resource-group rg-lab-aks --name aks-lab-01

# Verificar conexión
kubectl cluster-info
```

**Salida esperada:**

```
Kubernetes control plane is running at https://aks-lab-01-xxxxx.hcp.eastus.azmk8s.io:443
CoreDNS is running at https://aks-lab-01-xxxxx.hcp.eastus.azmk8s.io:443/api/v1/...
```

## Paso 4: Explorar el Cluster (10 min)

### Ver nodos

```bash
kubectl get nodes -o wide
```

### Ver componentes del sistema

```bash
kubectl get pods -n kube-system
```

### Ver información detallada de un nodo

```bash
kubectl describe node <nombre-del-nodo> | head -40
```

### Ver los recursos disponibles

```bash
kubectl top nodes
```

## Paso 5: Verificar Componentes de AKS (8 min)

```bash
# Ver el estado completo del cluster
az aks show --resource-group rg-lab-aks --name aks-lab-01 -o table

# Ver las versiones de Kubernetes disponibles
az aks get-versions --location eastus -o table

# Ver los addons habilitados
az aks show --resource-group rg-lab-aks --name aks-lab-01 \
  --query "addonProfiles" -o json
```

## Paso 6: Desplegar una Aplicación de Prueba (5 min)

```bash
# Crear un Deployment simple
kubectl create deployment nginx-test --image=nginx:1.25-alpine --replicas=3

# Verificar que las réplicas están corriendo
kubectl get pods -l app=nginx-test -o wide

# Exponer con un Service
kubectl expose deployment nginx-test --port=80 --type=ClusterIP

# Verificar el Service
kubectl get service nginx-test
```

## Paso 7: Limpieza (5 min)

```bash
./cleanup.sh
```

## Troubleshooting

### Error "AuthorizationFailed"
**Causa:** Tu cuenta no tiene permisos para crear recursos en la suscripción.
**Solución:** Verifica que tienes rol de "Contributor" o "Owner" en la suscripción.

### Creación del cluster tarda más de 15 minutos
**Causa:** Puede haber congestión en la región Azure.
**Solución:** Espera. Si supera 30 minutos, cancela y prueba en otra región.

## Navegación

- ⬆️ [Índice de laboratorios](../README.md)
- ➡️ [Lab 02: Node Pools y Scaling](../lab-02-node-pools-scaling/)
