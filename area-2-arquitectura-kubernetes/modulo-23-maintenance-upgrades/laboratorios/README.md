# Laboratorios - Modulo 23: Cluster Maintenance & Upgrades

> **Objetivo**: Dominar operaciones de mantenimiento, upgrade y disaster recovery de clusters Kubernetes
> **Tiempo total estimado**: 4-6 horas
> **Nivel**: Avanzado a Experto

---

## Indice de Laboratorios

| Lab | Titulo | Dificultad | Duracion | Archivos |
|-----|--------|------------|----------|----------|
| [01](./lab-01-etcd-backup-restore/) | etcd Backup y Restore | ⭐⭐⭐ Avanzado | 30-45 min | Scripts: 3 |
| [02](./lab-02-cluster-upgrade-minor/) | Cluster Upgrade (Minor Version) | ⭐⭐⭐ Avanzado | 45-60 min | Scripts: 3 |
| [03](./lab-03-node-drain-cordon/) | Node Drain, Cordon & Maintenance | ⭐⭐ Intermedio | 30-45 min | YAML: 3 \| Scripts: 2 |
| [04](./lab-04-certificate-management/) | Gestion de Certificados | ⭐⭐⭐ Avanzado | 90-120 min | Scripts: 3 |
| [Resumen](./lab-resumen-maintenance/) | Resumen: Maintenance | Repaso | 15 min | YAML: 1 |

---

## Estructura

```
laboratorios/
├── README.md                              # Este archivo
├── lab-01-etcd-backup-restore/            # etcd backup y disaster recovery
│   ├── README.md                          # Procedimiento backup/restore
│   ├── README.md.backup
│   ├── SETUP.md
│   ├── backup-etcd.sh                     # Script de backup automatizado
│   ├── restore-etcd.sh                    # Script de disaster recovery
│   ├── verify-data.sh                     # Verificacion de datos restaurados
│   └── cleanup.sh
├── lab-02-cluster-upgrade-minor/          # Upgrade de cluster v1.27 → v1.28
│   ├── README.md                          # Procedimiento de upgrade paso a paso
│   ├── README.md.backup
│   ├── SETUP.md
│   ├── upgrade-control-plane.sh           # Upgrade automatizado del control plane
│   ├── upgrade-worker.sh                  # Upgrade de worker nodes
│   ├── verify-upgrade.sh                  # 12 tests de verificacion post-upgrade
│   └── cleanup.sh
├── lab-03-node-drain-cordon/              # Mantenimiento de nodos
│   ├── README.md                          # Procedimiento drain/cordon/uncordon
│   ├── README.md.backup
│   ├── SETUP.md
│   ├── nginx-demo-deployment.yaml         # Deployment con 6 replicas
│   ├── critical-app-deployment-pdb.yaml   # Deployment + PDB (minAvailable: 2)
│   ├── node-monitor-daemonset.yaml        # DaemonSet que permanece durante drain
│   ├── drain-demo.sh                      # Demo interactiva de drain
│   ├── verify-drain.sh                    # Verificacion del estado
│   └── cleanup.sh
├── lab-04-certificate-management/         # Gestion de certificados PKI
│   ├── README.md                          # Verificacion, renovacion, troubleshooting
│   ├── README.md.backup
│   ├── SETUP.md
│   ├── check-certs.sh                     # Verificacion detallada de certs
│   ├── renew-certs.sh                     # Renovacion con backup y restart
│   ├── verify-certs.sh                    # 8 verificaciones post-renovacion
│   └── cleanup.sh
└── lab-resumen-maintenance/               # Resumen rapido
    ├── README.md
    ├── maintenance-lab.yaml
    └── cleanup.sh
```

> **Nota:** Este modulo tambien contiene 3 archivos legacy en formato antiguo
> (`lab-01-cluster-upgrade.md`, `lab-02-node-maintenance.md`, `lab-03-certificate-management.md`)
> que han sido reemplazados por los laboratorios en subdirectorios.

---

## Laboratorios Disponibles

### [Lab 01: etcd Backup y Restore](./lab-01-etcd-backup-restore/) ⭐⭐⭐
**Duracion**: 30-45 minutos | **Dificultad**: Avanzado

Procedimiento completo de backup y restore de etcd para disaster recovery:
- Configuracion de etcdctl con certificados TLS
- Snapshot save/status/restore
- Simulacion de perdida de datos y recuperacion
- Automatizacion con cron jobs

**Archivos**: backup-etcd.sh, restore-etcd.sh, verify-data.sh, cleanup.sh

**CKA Coverage**: Troubleshooting (30%) - etcd backup/restore

---

### [Lab 02: Cluster Upgrade (Minor Version)](./lab-02-cluster-upgrade-minor/) ⭐⭐⭐
**Duracion**: 45-60 minutos | **Dificultad**: Avanzado

Upgrade completo de cluster Kubernetes de v1.27 a v1.28:
- Version skew policy y compatibilidad
- Upgrade de control plane con kubeadm
- Upgrade de worker nodes con drain/uncordon
- Verificacion post-upgrade con 12 tests

**Archivos**: upgrade-control-plane.sh, upgrade-worker.sh, verify-upgrade.sh, cleanup.sh

**CKA Coverage**: Cluster Architecture (25%) - Cluster Maintenance

---

### [Lab 03: Node Drain, Cordon & Maintenance](./lab-03-node-drain-cordon/) ⭐⭐
**Duracion**: 30-45 minutos | **Dificultad**: Intermedio

Mantenimiento de nodos sin downtime de aplicaciones:
- Cordon, drain y uncordon de nodos
- PodDisruptionBudgets para proteger apps criticas
- Comportamiento de DaemonSets durante drain
- Graceful shutdown y rebalanceo

**Archivos**: 3 YAML (Deployment, PDB, DaemonSet), drain-demo.sh, verify-drain.sh, cleanup.sh

**CKA Coverage**: Cluster Architecture (25%) - Node Maintenance (15%)

---

### [Lab 04: Gestion de Certificados](./lab-04-certificate-management/) ⭐⭐⭐
**Duracion**: 90-120 minutos | **Dificultad**: Avanzado

Verificacion, renovacion y gestion de certificados PKI:
- Estructura PKI de Kubernetes (CA, API Server, etcd, front-proxy)
- kubeadm certs check-expiration y renew
- Restart de componentes static pod
- Simulacion de certificado expirado y recuperacion

**Archivos**: check-certs.sh, renew-certs.sh, verify-certs.sh, cleanup.sh

**CKA Coverage**: Cluster Architecture (25%) - PKI & Certificates (15%)

---

### [Lab Resumen: Maintenance](./lab-resumen-maintenance/)
**Duracion**: 15 minutos | **Nivel**: Repaso

Resumen rapido de mantenimiento de clusters con recursos de prueba para practica de drain/cordon, PDBs y verificacion de datos. Cubre los conceptos clave de los 4 labs en un solo ejercicio.

**Archivos**: maintenance-lab.yaml, cleanup.sh

---

## Guia de Uso

### Opcion 1: Lab Individual

```bash
# Navegar al lab
cd lab-03-node-drain-cordon/

# Revisar setup
cat SETUP.md

# Aplicar recursos
kubectl apply -f nginx-demo-deployment.yaml

# Seguir ejercicios del README.md

# Limpiar al finalizar
./cleanup.sh
```

### Opcion 2: Secuencia Completa (Preparacion CKA)

```bash
# Semana 1: Disaster Recovery
cd lab-01-etcd-backup-restore/    # 30-45 min

# Semana 2: Cluster Upgrade
cd ../lab-02-cluster-upgrade-minor/    # 45-60 min

# Semana 3: Node Maintenance
cd ../lab-03-node-drain-cordon/    # 30-45 min

# Semana 4: Certificados
cd ../lab-04-certificate-management/    # 90-120 min
```

---

## Progresion de Dificultad

```
Lab 01 (⭐⭐⭐)      Lab 02 (⭐⭐⭐)      Lab 03 (⭐⭐)       Lab 04 (⭐⭐⭐)
etcd Backup        Cluster Upgrade    Node Drain         Certificates
snapshot save      kubeadm upgrade    cordon/drain       check-expiration
snapshot restore   version skew       PDB management     renew all
cron automation    rolling upgrade    DaemonSets         PKI structure
```

---

## Preparacion para el Examen CKA

### Matriz de Cobertura CKA

| Dominio CKA | % Examen | Labs que cubren |
|-------------|----------|-----------------|
| Cluster Architecture | 25% | Lab 01, Lab 02, Lab 03, Lab 04 |
| Workloads & Scheduling | 15% | Lab 03 |
| Services & Networking | 20% | - |
| Storage | 10% | Lab 01 (etcd) |
| **Troubleshooting** | **30%** | Lab 01, Lab 02, Lab 04 |

**Cobertura Total**: ~20% directo del examen CKA (Cluster Maintenance)

---

## Preparacion Final

Estas listo para la seccion de mantenimiento del CKA cuando:

1. **Lab 01**: Completas backup+restore de etcd en <15 minutos
2. **Lab 02**: Completas upgrade de cluster en <20 minutos
3. **Lab 03**: Completas drain/uncordon en <10 minutos
4. **Lab 04**: Completas renovacion de certificados en <10 minutos

---

## Recursos Adicionales

- **Documentacion**: [Cluster Administration](https://kubernetes.io/docs/tasks/administer-cluster/)
- **CKA Info**: [Linux Foundation CKA](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/)
- **Cheatsheet**: Ver [RESUMEN-MODULO.md](../RESUMEN-MODULO.md)

---

[Volver al README del modulo](../README.md)
