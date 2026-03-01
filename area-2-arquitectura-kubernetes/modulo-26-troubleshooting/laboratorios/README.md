# Laboratorios - Modulo 26: Troubleshooting

> **Objetivo**: Desarrollar habilidades avanzadas de troubleshooting para el examen CKA
> **Tiempo total estimado**: 5-7 horas
> **Nivel**: Avanzado a Experto

---

## 📚 Indice de Laboratorios

| Lab | Titulo | Dificultad | Duracion | Archivos |
|-----|--------|------------|----------|----------|
| [01](./lab-01-application/) | Application Troubleshooting | ⭐⭐⭐ Avanzado | 60-75 min | YAML: 15 \| Scripts: 1 |
| [02](./lab-02-control-plane/) | Control Plane & Worker Nodes | ⭐⭐⭐⭐ Experto | 75-90 min | YAML: 1 \| Scripts: 2 |
| [03](./lab-03-network-storage/) | Network & Storage | ⭐⭐⭐⭐ Experto | 75-90 min | YAML: 16 \| Scripts: 1 |
| [04](./lab-04-complete-cluster/) | Complete Cluster - CKA Simulation | ⭐⭐⭐⭐ CKA Level | 90-120 min | YAML: 9 \| Scripts: 3 |
| [Resumen](./lab-resumen-troubleshooting/) | Resumen: Troubleshooting | Repaso | 15 min | YAML: 1 |

---

## 📁 Estructura

```
laboratorios/
├── README.md                          # Este archivo
├── lab-01-application/                # Application troubleshooting
│   ├── README.md                      # 8 escenarios con setup + fix
│   ├── README.md.backup
│   ├── SETUP.md
│   ├── cleanup.sh
│   └── scenario-*.yaml (15 archivos)  # Setup y fix para cada escenario
├── lab-02-control-plane/              # Control plane & nodes
│   ├── README.md                      # 8 escenarios diagnosticos
│   ├── README.md.backup
│   ├── SETUP.md
│   ├── etcd-backup.sh
│   ├── cleanup.sh
│   └── scenario-08-staticpod-setup.yaml
├── lab-03-network-storage/            # Networking & storage
│   ├── README.md                      # 8 escenarios con setup + fix
│   ├── README.md.backup
│   ├── SETUP.md
│   ├── cleanup.sh
│   └── scenario-*.yaml (16 archivos)  # Setup y fix para cada escenario
├── lab-04-complete-cluster/           # CKA simulation
│   ├── README.md                      # 5 escenarios complejos
│   ├── README.md.backup
│   ├── SETUP.md
│   ├── pre-flight-check.sh
│   ├── create-backup.sh
│   ├── cleanup.sh
│   └── scenario-*.yaml (9 archivos)   # RBAC, NetPol, Quotas, Priorities
└── lab-resumen-troubleshooting/       # Resumen rapido
    ├── README.md
    ├── troubleshooting-lab.yaml
    └── cleanup.sh
```

---

## 📋 Laboratorios Disponibles

### [Lab 01: Application Troubleshooting](./lab-01-application/) ⭐⭐⭐
**Duracion**: 60-75 minutos | **Dificultad**: Avanzado

**8 escenarios de troubleshooting de aplicaciones**:
- CrashLoopBackOff diagnosis
- ImagePullBackOff resolution
- OOMKilled (memory issues)
- Init container failures
- Liveness/Readiness probe errors
- Missing ConfigMaps/Secrets
- Port mismatches

**Archivos**: 15 YAML (setup + fix), cleanup.sh

**CKA Coverage**: Application Lifecycle (15%) + Troubleshooting (10%)

---

### [Lab 02: Control Plane & Nodes](./lab-02-control-plane/) ⭐⭐⭐⭐
**Duracion**: 75-90 minutos | **Dificultad**: Experto

**8 escenarios de infraestructura del cluster**:
- API Server troubleshooting
- etcd backup & restore
- Scheduler diagnostics
- Controller Manager issues
- kubelet failures
- kube-proxy problems
- Node NotReady states
- Static pod management

**Archivos**: 1 YAML, etcd-backup.sh, cleanup.sh

**Prerrequisitos**: Acceso SSH a control plane y workers, permisos sudo

**CKA Coverage**: Cluster Architecture (15%) + Troubleshooting (10%)

---

### [Lab 03: Network & Storage](./lab-03-network-storage/) ⭐⭐⭐⭐
**Duracion**: 75-90 minutos | **Dificultad**: Experto

**8 escenarios avanzados de networking y storage**:
- DNS (CoreDNS) troubleshooting
- Service without endpoints
- Network Policy debugging
- PVC Pending states
- StatefulSet storage problems
- Volume mount failures
- Ingress issues
- Pod-to-pod connectivity

**Archivos**: 16 YAML (setup + fix), cleanup.sh

**Prerrequisitos**: CNI compatible (Calico), Ingress Controller, StorageClass

**CKA Coverage**: Services & Networking (15%) + Storage (5%) + Troubleshooting (10%)

---

### [Lab 04: Complete Cluster](./lab-04-complete-cluster/) ⭐⭐⭐⭐
**Duracion**: 90-120 minutos | **Dificultad**: CKA Exam Level

**5 escenarios complejos de simulacion de examen**:
1. Multi-Component Failure (25 pts)
2. Security Breach - RBAC (20 pts)
3. Performance Degradation (20 pts)
4. StatefulSet Data Recovery (15 pts)
5. Disaster Recovery - etcd (20 pts)

**Archivos**: 9 YAML, pre-flight-check.sh, create-backup.sh, cleanup.sh

**⚠️ ADVERTENCIA**: Solo para clusters de prueba, simula fallos criticos

**CKA Coverage**: All domains - Full exam simulation | **Passing**: 66/100

---

### [Lab Resumen: Troubleshooting](./lab-resumen-troubleshooting/)
**Duracion**: 15 minutos | **Nivel**: Repaso

Resumen rapido de troubleshooting con recursos con errores intencionales para practica de diagnostico. Cubre application issues, networking y probes en un solo namespace.

**Archivos**: troubleshooting-lab.yaml, cleanup.sh

---

## 🚀 Guia de Uso

### Opcion 1: Lab Individual

```bash
# Navegar al lab
cd lab-01-application/

# Revisar setup
cat SETUP.md

# Aplicar escenario con error
kubectl apply -f scenario-01-crashloop-setup.yaml

# Diagnosticar y resolver (ver README.md)

# Limpiar al finalizar
./cleanup.sh
```

### Opcion 2: Secuencia Completa (Preparacion CKA)

```bash
# Semana 1: Fundamentos
cd lab-01-application/    # Completar 3 veces (60-75 min)

# Semana 2: Infraestructura
cd ../lab-02-control-plane/    # Completar 3 veces (75-90 min)

# Semana 3: Networking & Storage
cd ../lab-03-network-storage/    # Completar 3 veces (75-90 min)

# Semana 4: Simulacion de Examen
cd ../lab-04-complete-cluster/    # Objetivo: 66+ en 120 min
```

---

## 📊 Progresion de Dificultad

```
Lab 01 (⭐⭐⭐)      Lab 02 (⭐⭐⭐⭐)     Lab 03 (⭐⭐⭐⭐)     Lab 04 (⭐⭐⭐⭐)
Application        Control Plane      Network/Storage    Full Cluster
Pods, Containers   API, etcd          DNS, Services      Multi-component
Probes, Configs    kubelet, kube-proxy PV/PVC           Disaster Recovery
                   Scheduler          Network Policies   Exam Simulation
```

---

## 🎯 Preparacion para el Examen CKA

### Matriz de Cobertura CKA

| Dominio CKA | % Examen | Labs que cubren |
|-------------|----------|-----------------|
| Cluster Architecture | 25% | Lab 02, Lab 04 |
| Workloads & Scheduling | 15% | Lab 01, Lab 04 |
| Services & Networking | 20% | Lab 03, Lab 04 |
| Storage | 10% | Lab 03, Lab 04 |
| **Troubleshooting** | **30%** | **TODOS** |

**Cobertura Total**: 100% del dominio de Troubleshooting + 70% de otros dominios

---

## ✅ Preparacion Final

Estas listo para el CKA cuando:

1. **Lab 01**: Completas en <60 minutos sin ayuda
2. **Lab 02**: Completas en <75 minutos sin ayuda
3. **Lab 03**: Completas en <75 minutos sin ayuda
4. **Lab 04**: Logras 70+ puntos en 120 minutos consistentemente

---

## 📚 Recursos Adicionales

- **Documentacion**: [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- **CKA Info**: [Linux Foundation CKA](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/)
- **Practice**: [Killer.sh](https://killer.sh) - Simulador incluido con registro CKA
- **Cheatsheet**: Ver [RESUMEN-MODULO.md](../RESUMEN-MODULO.md)

---

[Volver al README del modulo](../README.md)
