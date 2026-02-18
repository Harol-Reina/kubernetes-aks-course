# Laboratorios - Cluster Maintenance & Upgrades

Guía completa de laboratorios prácticos para dominar mantenimiento y upgrades de Kubernetes.

## 📚 Índice de Laboratorios

| Lab | Título | Duración | Dificultad | CKA % |
|-----|--------|----------|------------|-------|
| 01 | Cluster Upgrade 1.27→1.28 | 60-90 min | ⭐⭐⭐ | ~10% |
| 02 | Node Maintenance | 45-60 min | ⭐⭐ | ~5% |
| 03 | Certificate Management | 45-60 min | ⭐⭐⭐ | ~5% |

**Total:** 150-210 minutos (~3-4 horas) | **CKA Coverage:** ~20% del examen

---

## 🎯 Lab 01: Cluster Upgrade

**Archivo:** `lab-01-cluster-upgrade.md`

### Objetivos
- Planificar y ejecutar upgrade de cluster completo
- Realizar backups completos (etcd, configs, resources)
- Upgrader control plane y workers de forma segura
- Aplicar version skew policy correctamente
- Verificar integridad post-upgrade

### Lo que aprenderás
- `kubeadm upgrade plan` y `kubeadm upgrade apply`
- Workflow completo de upgrade (kubeadm → kubelet → kubectl)
- Drain y uncordon durante upgrades
- Backup y restore de etcd
- Smoke tests post-upgrade

### Arquitectura
```
1.27.x  →  Upgrade  →  1.28.x
Master + 2 Workers
```

### Prerequisitos
- Cluster funcional en 1.27.x
- Acceso root a todos los nodos
- kubectl configurado
- ~10GB espacio libre en cada nodo

---

## 🛠️ Lab 02: Node Maintenance

**Archivo:** `lab-02-node-maintenance.md`

### Objetivos
- Dominar `kubectl drain`, `cordon`, `uncordon`
- Gestionar mantenimiento de nodos sin downtime
- Trabajar con PodDisruptionBudgets
- Simular escenarios reales (reboot, hardware maintenance)

### Escenarios cubiertos
1. **Node Reboot:** Drain → Reboot → Uncordon
2. **Cordon:** Marcar unschedulable sin evacuar
3. **PodDisruptionBudgets:** Proteger apps críticas durante drain

### Lo que aprenderás
- Diferencia entre drain y cordon
- Cuándo usar `--ignore-daemonsets`
- Cuándo usar `--delete-emptydir-data`
- Cómo PDBs protegen aplicaciones
- Estrategias de capacidad N-1

---

## 🔐 Lab 03: Certificate Management

**Archivo:** `lab-03-certificate-management.md`

### Objetivos
- Verificar expiración de certificados
- Renovar certificados con kubeadm
- Configurar certificate rotation automática
- Entender PKI de Kubernetes

### Exercises cubiertos
1. **Check Expiration:** Ver todos los certificados y su validez
2. **Manual Renewal:** Renovar todos los certificados
3. **Selective Renewal:** Renovar certificados específicos (API server, etcd)
4. **kubelet Rotation:** Configurar rotación automática
5. **Monitoring:** Setup de monitoreo con cron

### Lo que aprenderás
- `kubeadm certs check-expiration`
- `kubeadm certs renew all`
- Actualizar kubeconfig después de renovar
- Aprobar CSRs (Certificate Signing Requests)
- Setup de alertas de expiración

---

## 🚀 Rutas de Aprendizaje

### Ruta 1: CKA Completa (3-4 horas)
**Objetivo:** Cubrir 20% del examen CKA
```
Lab 01 (90 min) → Lab 02 (60 min) → Lab 03 (60 min)
```

**Ideal para:**
- Preparación para CKA
- Administradores de clusters nuevos
- Práctica exhaustiva

### Ruta 2: Express (2 horas)
**Objetivo:** Conceptos esenciales
```
Lab 01 (60 min, skip challenges) → Lab 02 (30 min, scenarios 1-2) → Lab 03 (30 min, exercises 1-2)
```

**Ideal para:**
- Refrescar conocimientos
- Focus en upgrades
- Tiempo limitado

### Ruta 3: Mantenimiento Operacional (1.5 horas)
**Objetivo:** Day-2 operations
```
Lab 02 (45 min) → Lab 03 (45 min)
```

**Ideal para:**
- Operadores que no hacen upgrades
- Focus en mantenimiento diario
- Certificate management

---

## 📋 Pre-Lab Setup

### Requisitos de Hardware

#### Opción A: VMs Locales (Recommended)
```
Control Plane:  2 CPU, 4GB RAM, 50GB disk
Worker 1:       2 CPU, 2GB RAM, 30GB disk
Worker 2:       2 CPU, 2GB RAM, 30GB disk
```

#### Opción B: Cloud (AWS/Azure/GCP)
```
Master:  t3.medium (2 vCPU, 4GB)
Workers: t3.small  (2 vCPU, 2GB) x2
```

#### Opción C: Minikube/Kind (Solo Lab 02 y 03)
```
minikube start --nodes 3 --cpus 2 --memory 3072
```

### Software Prerequisites

```bash
# En todos los nodos

# 1. kubectl
curl -LO "https://dl.k8s.io/release/v1.27.8/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 2. kubeadm, kubelet (versión 1.27.x para Lab 01)
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet=1.27.8-00 kubeadm=1.27.8-00
sudo apt-mark hold kubelet kubeadm

# 3. containerd
sudo apt-get install -y containerd
sudo systemctl enable --now containerd

# 4. Utilidades
sudo apt-get install -y jq tmux
```

### Cluster Setup (para Lab 01)

```bash
# Inicializar cluster con 1.27.x
sudo kubeadm init --kubernetes-version=v1.27.8 --pod-network-cidr=10.244.0.0/16

# Setup kubeconfig
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalar CNI (Calico)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Join workers
# (ejecutar comando que muestra kubeadm init)
```

---

## 📊 Checklist Pre-Lab

### Antes de empezar CUALQUIER lab:

- [ ] Cluster en estado saludable: `kubectl get nodes`
- [ ] Todos los pods Running: `kubectl get pods --all-namespaces`
- [ ] Sin eventos de error: `kubectl get events | grep -i error`
- [ ] Espacio suficiente: `df -h /var/lib/etcd` (>10GB libre)
- [ ] Backup actualizado (etcd): Ver Lab 01, Paso 2
- [ ] tmux/screen iniciado (evitar desconexiones)

### Antes de Lab 01 (Upgrade):

- [ ] Versión actual verificada: `kubectl version --short` (debe ser 1.27.x)
- [ ] Release notes leídas: https://kubernetes.io/docs/setup/release/notes/
- [ ] Staging cluster testeado (si disponible)
- [ ] Ventana de mantenimiento acordada

### Antes de Lab 02 (Maintenance):

- [ ] Al menos 2 workers disponibles (para capacidad N-1)
- [ ] Apps con múltiples réplicas (para testing)
- [ ] Conocimiento de PodDisruptionBudgets

### Antes de Lab 03 (Certificates):

- [ ] Backup de `/etc/kubernetes/pki`
- [ ] Acceso root al control plane
- [ ] Verificación de expiration actual: `sudo kubeadm certs check-expiration`

---

## 🎯 Tips para el Éxito

### General
- ✅ Usa `tmux` o `screen` para evitar perder sesión
- ✅ Copia comandos en bloc de notas (no confiar en memoria)
- ✅ Verifica CADA paso antes de continuar al siguiente
- ✅ Lee TODOS los outputs de comandos importantes

### Lab 01 (Upgrade)
- ✅ **SIEMPRE** backup antes de upgrade
- ✅ Un nodo a la vez (nunca draines múltiples workers simultáneamente)
- ✅ Espera a que pods reschedulen antes de siguiente nodo
- ✅ Si algo falla, DETENTE y diagnostica (no continúes a ciegas)

### Lab 02 (Maintenance)
- ✅ Drain puede tardar (especialmente con PDBs restrictivos)
- ✅ Usa `--dry-run=client` primero para ver impacto
- ✅ Verifica que hay capacidad antes de drain

### Lab 03 (Certificates)
- ✅ Backup de PKI antes de renovar
- ✅ Actualiza kubeconfig SIEMPRE después de renovar
- ✅ Reinicia kubelet después de cambios de certs

---

## 🐛 Troubleshooting General

### kubectl no funciona
```bash
# Verificar kubeconfig
cat ~/.kube/config

# Verificar conectividad a API server
kubectl cluster-info

# Regenerar kubeconfig (como root)
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

### Nodo NotReady
```bash
# Ver detalles
kubectl describe node <node-name>

# Ver logs de kubelet
ssh <node> 'sudo journalctl -u kubelet -f'

# Errores comunes:
# - Swap habilitado: sudo swapoff -a
# - CNI issues: kubectl get pods -n kube-system -l k8s-app=calico-node
# - containerd down: sudo systemctl status containerd
```

### Pods Pending
```bash
# Ver por qué no schedules
kubectl describe pod <pod-name>

# Causas comunes:
# - Nodo cordoned: kubectl get nodes
# - Recursos insuficientes: kubectl top nodes
# - Taints: kubectl describe node <node> | grep Taint
```

---

## ✅ Criterios de Completitud Global

Has completado exitosamente TODOS los labs si:

- [ ] **Lab 01:** Cluster upgraded de 1.27.x a 1.28.4
- [ ] **Lab 01:** Todos los nodos muestran v1.28.4 en `kubectl get nodes`
- [ ] **Lab 01:** Smoke test pasado (nginx deployment)
- [ ] **Lab 02:** Node reboot completado sin downtime
- [ ] **Lab 02:** PDB respetado durante drain
- [ ] **Lab 03:** Certificados renovados exitosamente
- [ ] **Lab 03:** Rotación automática de kubelet configurada
- [ ] **General:** Cluster funcional y saludable al final

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Safely Drain Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
- [Certificate Management](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)

### Scripts de Apoyo
- `../scripts/upgrade-cluster.sh` - Upgrade automatizado
- `../scripts/safe-drain.sh` - Drain con verificaciones
- `../scripts/cert-monitor.sh` - Monitoreo de certificados

### Ejemplos
- `../ejemplos/pdb-examples.yaml` - PodDisruptionBudgets
- `../ejemplos/pre-upgrade-checklist.md` - Checklist completo

---

## 🎓 Después de Completar

### Próximos Pasos
1. **Práctica adicional:** Repetir labs en diferentes entornos
2. **Automatización:** Crear tus propios scripts de upgrade
3. **Documentación:** Crear runbooks para tu organización
4. **Mock Exam:** Practicar escenarios de CKA

### Habilidades Adquiridas
- ✅ Upgrade seguro de clusters Kubernetes
- ✅ Mantenimiento de nodos sin downtime
- ✅ Gestión de certificados y PKI
- ✅ Troubleshooting de upgrades
- ✅ Automatización de tareas operacionales

**🎯 CKA Readiness:** Has cubierto ~20% del examen CKA con estos 3 labs.

---

**Ver también:**
- [README Principal](../README.md)
- [RESUMEN](../RESUMEN-MODULO.md)
- [Ejemplos](../ejemplos/README.md)
