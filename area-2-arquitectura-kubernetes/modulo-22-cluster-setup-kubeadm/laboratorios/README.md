# Laboratorios: Cluster Setup con kubeadm

Laboratorios prácticos hands-on para dominar el setup y administración de clusters Kubernetes con kubeadm. Estos labs cubren desde instalación básica hasta troubleshooting avanzado, preparándote para la certificación CKA.

---

## 📚 Índice de Laboratorios

| Lab | Título | Dificultad | Duración | Objetivos |
|-----|--------|------------|----------|-----------|
| [01](./lab-01-basic-cluster.md) | Setup de Cluster Básico | ⭐⭐ Intermedio | 45-60 min | Instalar prerequisites, inicializar control plane, agregar workers |
| [02](./lab-02-ha-cluster.md) | Cluster High Availability | ⭐⭐⭐⭐ Avanzado | 90-120 min | Setup HA con 3 control planes, load balancer, test failover |
| [03](./lab-03-etcd-backup-restore.md) | Backup y Restore de etcd | ⭐⭐⭐ Intermedio-Avanzado | 45-60 min | Backups manuales/automáticos, restore, DR strategy |
| [04](./lab-04-troubleshooting.md) | Troubleshooting Cluster | ⭐⭐⭐⭐ Avanzado | 60-90 min | Diagnosticar y resolver 10 problemas comunes |

---

## 🎯 Objetivos Generales

Después de completar todos los laboratorios, serás capaz de:

### Lab 01: Setup de Cluster Básico
- ✅ Instalar y configurar container runtime (containerd)
- ✅ Instalar kubeadm, kubelet, kubectl
- ✅ Inicializar control plane con `kubeadm init`
- ✅ Configurar CNI plugin (Calico)
- ✅ Agregar worker nodes al cluster
- ✅ Verificar estado del cluster

### Lab 02: High Availability
- ✅ Configurar load balancer (HAProxy/nginx)
- ✅ Setup cluster HA con 3+ control planes
- ✅ Entender topología stacked vs external etcd
- ✅ Implementar leader election
- ✅ Probar failover de control plane
- ✅ Gestionar certificados en entorno HA

### Lab 03: Backup & Restore
- ✅ Realizar backups manuales de etcd con etcdctl
- ✅ Automatizar backups con scripts y cron
- ✅ Verificar integridad de snapshots
- ✅ Restaurar cluster desde snapshot
- ✅ Implementar estrategia de disaster recovery

### Lab 04: Troubleshooting
- ✅ Diagnosticar nodos en NotReady
- ✅ Resolver pods en Pending
- ✅ Troubleshoot CNI y networking issues
- ✅ Renovar certificados expirados
- ✅ Recuperar etcd corrupto
- ✅ Fix API server y kubelet issues
- ✅ Usar herramientas de diagnóstico

---

## 🏗️ Arquitectura por Laboratorio

### Lab 01: Cluster Básico (Single Master)
```
       Control Plane (Master)
            192.168.1.10
                 |
        ┌────────┴────────┐
        |                 |
    Worker-01         Worker-02
  192.168.1.20      192.168.1.21
```

**Componentes:**
- 1 control plane node
- 2 worker nodes
- CNI: Calico
- Runtime: containerd

---

### Lab 02: Cluster HA (Multi-Master)
```
           Load Balancer
          192.168.1.100
                |
    ┌───────────┼───────────┐
    |           |           |
Master-01    Master-02   Master-03
192.168.1.10  .11         .12
    └───────────┼───────────┘
                |
    ┌───────────┼───────────┐
    |           |           |
Worker-01    Worker-02   Worker-03
192.168.1.20  .21         .22
```

**Componentes:**
- 1 load balancer (HAProxy)
- 3 control plane nodes (HA)
- 3 worker nodes
- etcd: stacked topology
- Leader election enabled

---

### Lab 03: Backup & Restore
```
  Control Plane
      etcd
  /var/lib/etcd/
       |
       | snapshot
       ▼
 /var/backups/etcd/
  ├── snapshot-001.db
  ├── snapshot-002.db
  └── snapshot-003.db
       |
       | restore
       ▼
  /var/lib/etcd/
```

**Componentes:**
- etcdctl
- Backup scripts
- Cron jobs
- DR procedures

---

## 📋 Prerequisites Generales

### Hardware Mínimo

**Para Lab 01 (Single Master):**
- 3 VMs total
- Master: 2 CPU, 2GB RAM, 20GB disk
- Workers: 1 CPU, 1GB RAM, 20GB disk cada uno

**Para Lab 02 (HA):**
- 7 VMs total
- Load Balancer: 1 CPU, 1GB RAM, 10GB disk
- Masters (3x): 2 CPU, 2GB RAM, 20GB disk cada uno
- Workers (3x): 2 CPU, 2GB RAM, 20GB disk cada uno

### Software

- **OS**: Ubuntu 22.04 LTS (recomendado) o 20.04
- **Acceso**: Root (sudo) en todos los nodos
- **Red**: Conectividad entre todos los nodos

### Conocimientos Previos

- Comandos básicos de Linux
- Conceptos de redes (IP, DNS, ports)
- Conceptos básicos de Kubernetes (pods, services, deployments)
- SSH y acceso remoto a servidores

---

## 🚀 Ruta de Aprendizaje Recomendada

### Opción A: Completa (Preparación CKA)
Seguir orden secuencial de labs:

```
Lab 01 → Lab 02 → Lab 03 → Lab 04
  ↓        ↓        ↓        ↓
Basic    HA     Backup   Debug
Setup   Setup   & DR    Skills
```

**Tiempo total:** ~5-6 horas

**Resultado:** Preparación completa para CKA

---

### Opción B: Express (Fundamentos)
Solo labs esenciales:

```
Lab 01 → Lab 03
  ↓        ↓
Basic   Backup
Setup   & DR
```

**Tiempo total:** ~2 horas

**Resultado:** Skills básicos de administración

---

### Opción C: Especialización HA
Foco en production readiness:

```
Lab 01 → Lab 02 → Lab 03
  ↓        ↓        ↓
Basic    HA     Backup
Setup   Setup   & DR
```

**Tiempo total:** ~4 horas

**Resultado:** Clusters production-ready

---

## 🛠️ Setup del Entorno

### Opción 1: VMs Locales (VirtualBox/VMware)

```bash
# Crear 3 VMs para Lab 01
# Cada VM:
- CPU: 2 cores (master), 1 core (workers)
- RAM: 2GB (master), 1GB (workers)
- Disk: 20GB
- Network: Bridged o Host-Only
- OS: Ubuntu 22.04 Server
```

### Opción 2: Cloud (AWS/GCP/Azure)

```bash
# AWS: Usar EC2 t3.small
# GCP: Usar e2-small
# Azure: Usar B2s

# Lab 01: 3 instancias
# Lab 02: 7 instancias
```

### Opción 3: Kind/Minikube (Testing)

⚠️ **Nota**: Labs diseñados para VMs reales. Kind/Minikube tienen limitaciones para ciertos escenarios (especialmente Lab 02 HA).

---

## 📝 Preparación Pre-Lab

Antes de comenzar cualquier lab:

### 1. Configurar SSH

```bash
# Generar key SSH (si no tienes)
ssh-keygen -t rsa -b 4096

# Copiar key a cada nodo
ssh-copy-id user@192.168.1.10
ssh-copy-id user@192.168.1.20
ssh-copy-id user@192.168.1.21
```

### 2. Configurar /etc/hosts

En **TU MÁQUINA LOCAL** y en **TODOS LOS NODOS**:

```bash
sudo tee -a /etc/hosts <<EOF
192.168.1.10 k8s-master-01
192.168.1.20 k8s-worker-01
192.168.1.21 k8s-worker-02
# Para Lab 02 HA:
192.168.1.100 k8s-lb
192.168.1.11 k8s-master-02
192.168.1.12 k8s-master-03
192.168.1.22 k8s-worker-03
EOF
```

### 3. Actualizar Sistema (en todos los nodos)

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl wget vim git
```

---

## 🎓 Tips para el Éxito

### Durante los Labs

1. **Leer TODO el lab antes de comenzar**
   - Entender el objetivo final
   - Identificar checkpoints
   - Preparar recursos necesarios

2. **Usar tmux para múltiples nodos**
   ```bash
   # Instalar tmux
   sudo apt-get install -y tmux
   
   # Crear sesión con 3 paneles (para 3 nodos)
   tmux new-session \; split-window -h \; split-window -v
   ```

3. **Tomar snapshots antes de cambios importantes**
   - VM snapshots (VirtualBox/VMware)
   - Cloud snapshots (AWS/GCP/Azure)

4. **Documentar comandos ejecutados**
   ```bash
   # Usar script para grabar sesión
   script -a lab01-session.log
   # ... ejecutar comandos ...
   exit  # Para terminar grabación
   ```

5. **Verificar cada checkpoint**
   - No avanzar si algo no funciona
   - Troubleshoot antes de continuar

### Troubleshooting General

```bash
# Si algo falla, SIEMPRE revisar:

# 1. Logs de kubelet
sudo journalctl -u kubelet -f

# 2. Pods del sistema
kubectl get pods -n kube-system

# 3. Eventos del cluster
kubectl get events --sort-by='.lastTimestamp'

# 4. Descripción del recurso problemático
kubectl describe <resource> <name>

# 5. Estado del container runtime
sudo systemctl status containerd
sudo crictl ps
```

---

## ✅ Checklist por Laboratorio

### Lab 01: Setup Básico
- [ ] Prerequisites instalados (containerd, kubeadm, kubelet, kubectl)
- [ ] Swap deshabilitado en todos los nodos
- [ ] Control plane inicializado con `kubeadm init`
- [ ] CNI plugin (Calico) instalado
- [ ] 2 workers unidos al cluster
- [ ] Todos los nodos en estado **Ready**
- [ ] Test de deployment exitoso

### Lab 02: High Availability
- [ ] Load balancer (HAProxy) configurado
- [ ] 3 control planes en estado **Ready**
- [ ] etcd cluster con 3 miembros healthy
- [ ] Leader election funcionando
- [ ] 3 workers unidos al cluster
- [ ] Failover test exitoso (apagar 1 master)
- [ ] Cluster sobrevive a fallo de 1 control plane

### Lab 03: Backup & Restore
- [ ] etcdctl instalado y configurado
- [ ] Backup manual exitoso
- [ ] Script de backup automatizado funcionando
- [ ] Cron job configurado para backups periódicos
- [ ] Restore desde snapshot exitoso
- [ ] Datos restaurados verificados
- [ ] Estrategia de DR documentada

### Lab 04: Troubleshooting
- [ ] Diagnosticado y resuelto: Nodo NotReady
- [ ] Diagnosticado y resuelto: Pods Pending
- [ ] Diagnosticado y resuelto: CNI failure
- [ ] Diagnosticado y resuelto: Certificados expirados
- [ ] Diagnosticado y resuelto: etcd unhealthy
- [ ] Diagnosticado y resuelto: API server no responde
- [ ] Diagnosticado y resuelto: Swap habilitado
- [ ] Diagnosticado y resuelto: DNS no funciona
- [ ] Diagnosticado y resuelto: Worker no se une
- [ ] Diagnosticado y resuelto: Container runtime falla

---

## 📊 Mapeo a Objetivos CKA

Los laboratorios mapean directamente a los dominios del examen CKA:

| Dominio CKA | Peso | Labs Relacionados |
|-------------|------|-------------------|
| **Cluster Architecture, Installation & Configuration** | 25% | Lab 01, Lab 02 |
| **Workloads & Scheduling** | 15% | Lab 04 (escenarios de scheduling) |
| **Services & Networking** | 20% | Lab 01 (CNI), Lab 04 (troubleshooting networking) |
| **Storage** | 10% | Lab 03 (etcd backup) |
| **Troubleshooting** | 30% | Lab 04 (todos los escenarios) |

**Total Coverage:** ~85% del examen CKA

---

## 🔧 Herramientas Utilizadas

| Herramienta | Uso | Lab |
|-------------|-----|-----|
| **kubeadm** | Bootstrapping de cluster | 01, 02 |
| **kubectl** | Cliente de API de Kubernetes | Todos |
| **containerd** | Container runtime | Todos |
| **Calico** | CNI plugin | 01, 02, 04 |
| **etcdctl** | Cliente de etcd | 03 |
| **HAProxy** | Load balancer | 02 |
| **crictl** | Debug de container runtime | 04 |
| **journalctl** | Ver logs de systemd | 04 |

---

## 📚 Referencias y Recursos

### Documentación Oficial
- [kubeadm Installation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Creating HA Clusters](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
- [etcd Disaster Recovery](https://etcd.io/docs/v3.5/op-guide/recovery/)
- [Troubleshooting Clusters](https://kubernetes.io/docs/tasks/debug/)

### Guías Complementarias
- [CKA Exam Curriculum](https://github.com/cncf/curriculum)
- [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [CKA Practice Questions](https://github.com/alijahnas/CKA-practice-exercises)

### Cheat Sheets
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [etcdctl Cheat Sheet](https://lzone.de/cheat-sheet/etcd)

---

## 🆘 Soporte

### Si Encuentras Problemas

1. **Revisar troubleshooting section del lab**
2. **Consultar Lab 04 para escenarios similares**
3. **Buscar en logs:**
   ```bash
   sudo journalctl -u kubelet --since "10 minutes ago"
   kubectl logs -n kube-system <pod-name>
   ```
4. **Verificar documentación oficial**
5. **Buscar en Issues de GitHub del curso**

### Recursos de la Comunidad
- Kubernetes Slack: #kubeadm
- Stack Overflow: [kubernetes] tag
- Reddit: r/kubernetes

---

## 🎯 Próximos Pasos

Después de completar los laboratorios:

1. **Practicar más:**
   - Repetir labs hasta dominar cada paso
   - Intentar sin consultar documentación
   - Cronometrarse (simular examen CKA)

2. **Experimentar:**
   - Modificar configuraciones
   - Probar diferentes CNI plugins (Flannel, Weave)
   - Setup en diferentes clouds (AWS, GCP, Azure)

3. **Preparación para CKA:**
   - Completar [Módulo 23: Maintenance & Upgrades](../modulo-23-maintenance-upgrades/)
   - Practicar con [killer.sh CKA Simulator](https://killer.sh/cka)
   - Tomar mock exams

4. **Production Readiness:**
   - Implementar monitoring (Prometheus/Grafana)
   - Configurar logging centralizado (EFK stack)
   - Setup CI/CD pipelines

---

## ✨ Conclusión

Estos laboratorios te proporcionan experiencia práctica real con kubeadm y administración de clusters Kubernetes. Al completarlos, tendrás las habilidades necesarias para:

- ✅ Instalar y configurar clusters Kubernetes desde cero
- ✅ Implementar alta disponibilidad production-ready
- ✅ Realizar backups y disaster recovery
- ✅ Troubleshoot problemas comunes efectivamente

**¡Buena suerte con los laboratorios!** 🚀

---

**Ver también:**
- [Módulo 22 README](../README.md) - Documentación completa del módulo
- [Ejemplos](../ejemplos/README.md) - Configuraciones de ejemplo
- [Scripts](../scripts/) - Scripts de automatización
