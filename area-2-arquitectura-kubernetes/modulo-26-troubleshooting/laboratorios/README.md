# Laboratorios - Módulo 26: Troubleshooting

> **Objetivo**: Desarrollar habilidades avanzadas de troubleshooting para el examen CKA  
> **Tiempo total estimado**: 5-7 horas  
> **Nivel**: Avanzado a Experto

## 📁 Estructura

```
laboratorios/
├── README.md                          # Este archivo
├── lab-01-application/                # Application troubleshooting
│   ├── README.md                      # Instrucciones completas
│   ├── SETUP.md                       # Guía de setup
│   └── cleanup.sh                     # Script de limpieza
├── lab-02-control-plane/              # Control plane & nodes
│   ├── README.md
│   ├── SETUP.md
│   ├── etcd-backup.sh                 # Backup de etcd
│   └── cleanup.sh
├── lab-03-network-storage/            # Networking & storage
│   ├── README.md
│   ├── SETUP.md
│   └── cleanup.sh
└── lab-04-complete-cluster/           # CKA simulation
    ├── README.md
    ├── SETUP.md
    ├── pre-flight-check.sh            # Verificar prerrequisitos
    ├── create-backup.sh               # Backup completo
    └── cleanup.sh
```

## 📋 Laboratorios Disponibles

### [Lab 01: Application Troubleshooting](./lab-01-application/) ⭐⭐⭐
**Duración**: 60-75 minutos | **Dificultad**: Avanzado

**8 escenarios de troubleshooting de aplicaciones**:
- CrashLoopBackOff diagnosis
- ImagePullBackOff resolution
- OOMKilled (memory issues)
- Init container failures
- Liveness/Readiness probe errors
- Missing ConfigMaps/Secrets
- Port mismatches

**Archivos**:
- `README.md` - Instrucciones completas con soluciones
- `SETUP.md` - Guía de preparación
- `cleanup.sh` - Limpieza

**CKA Coverage**: Application Lifecycle (15%) + Troubleshooting (10%)

---

### [Lab 02: Control Plane & Nodes](./lab-02-control-plane/) ⭐⭐⭐⭐
**Duración**: 75-90 minutos | **Dificultad**: Experto

**8 escenarios de infraestructura del cluster**:
- API Server troubleshooting
- etcd backup & restore
- Scheduler diagnostics
- Controller Manager issues
- kubelet failures
- kube-proxy problems
- Node NotReady states
- Static pod management

**Archivos**:
- `README.md` - Guía completa
- `SETUP.md` - Prerrequisitos
- `etcd-backup.sh` - Script de backup de etcd
- `cleanup.sh` - Limpieza

**Prerrequisitos**:
- Acceso SSH a control plane y workers
- Permisos sudo
- Familiaridad con systemd

**CKA Coverage**: Cluster Architecture (15%) + Troubleshooting (10%)

---

### [Lab 03: Network & Storage](./lab-03-network-storage/) ⭐⭐⭐⭐
**Duración**: 75-90 minutos | **Dificultad**: Experto

**8 escenarios avanzados de networking y storage**:
- DNS (CoreDNS) troubleshooting
- Service without endpoints
- Network Policy debugging
- Ingress issues
- PVC Pending states
- StatefulSet storage problems
- Volume mount failures
- Pod-to-pod connectivity

**Archivos**:
- `README.md` - Guía completa con soluciones
- `SETUP.md` - Verificación de prerrequisitos
- `cleanup.sh` - Limpieza

**Prerrequisitos**:
- CNI plugin (Calico, Flannel)
- Ingress Controller
- Dynamic provisioning o capacidad para crear PVs

**CKA Coverage**: Services & Networking (15%) + Storage (5%) + Troubleshooting (10%)

---

### [Lab 04: Complete Cluster](./lab-04-complete-cluster/) ⭐⭐⭐⭐
**Duración**: 90-120 minutos | **Dificultad**: CKA Exam Level

**5 escenarios complejos de simulación de examen**:
1. Multi-Component Failure (25 pts)
2. Security Breach - RBAC (20 pts)
3. Performance Degradation (20 pts)
4. StatefulSet Data Recovery (15 pts)
5. Disaster Recovery - etcd (20 pts)

**Archivos**:
- `README.md` - Escenarios completos tipo examen
- `SETUP.md` - Advertencias y preparación
- `pre-flight-check.sh` - Verificar cluster está listo
- `create-backup.sh` - Backup completo antes de empezar
- `cleanup.sh` - Recuperación

**⚠️ ADVERTENCIA**: Solo para clusters de prueba, simula fallos críticos

**CKA Coverage**: All domains - Full exam simulation

**Scoring**: Passing score 66/100

---

## 🚀 Guía de Uso

### Opción 1: Lab Individual

```bash
# Navegar al lab
cd lab-01-application/

# Leer instrucciones
cat README.md
cat SETUP.md

# Ejecutar lab (seguir instrucciones del README)
# ...

# Limpiar al finalizar
chmod +x cleanup.sh
./cleanup.sh
```

### Opción 2: Secuencia Completa (Preparación CKA)

```bash
# Semana 1: Fundamentos
cd lab-01-application/
# Completar 3 veces hasta dominar (60-75 min cada vez)

# Semana 2: Infraestructura
cd ../lab-02-control-plane/
# Completar 3 veces (75-90 min cada vez)

# Semana 3: Networking & Storage
cd ../lab-03-network-storage/
# Completar 3 veces (75-90 min cada vez)

# Semana 4: Simulación de Examen
cd ../lab-04-complete-cluster/
# Completar bajo condiciones de examen
# Objetivo: 66+ puntos en 120 minutos
```

## 📊 Progresión de Dificultad

```
Lab 01 (⭐⭐⭐)      Lab 02 (⭐⭐⭐⭐)     Lab 03 (⭐⭐⭐⭐)     Lab 04 (⭐⭐⭐⭐)
Application        Control Plane      Network/Storage    Full Cluster
Pods, Containers   API, etcd          DNS, Services      Multi-component
Probes, Configs    kubelet, kube-proxy PV/PVC           Disaster Recovery
                   Scheduler          Network Policies   Exam Simulation
```

## 🎯 Preparación para el Examen CKA

### Checklist de Habilidades

Después de completar todos los labs, debes poder:

**Lab 01 Skills**:
- [ ] Diagnosticar CrashLoopBackOff en <3 minutos
- [ ] Resolver ImagePullBackOff rápidamente
- [ ] Identificar OOMKilled por exit code
- [ ] Debuggear liveness/readiness probes
- [ ] Resolver ConfigMap/Secret issues

**Lab 02 Skills**:
- [ ] Hacer backup de etcd en <5 minutos
- [ ] Restaurar etcd desde backup
- [ ] Diagnosticar API server down
- [ ] Resolver node NotReady
- [ ] Troubleshoot kubelet con journalctl

**Lab 03 Skills**:
- [ ] Diagnosticar DNS failures
- [ ] Fix service sin endpoints
- [ ] Crear y debuggear Network Policies
- [ ] Resolver PVC Pending
- [ ] Troubleshoot volume mounts

**Lab 04 Skills**:
- [ ] Manejar fallos multi-componente
- [ ] Resolver bajo presión de tiempo
- [ ] Priorizar problemas correctamente
- [ ] Documentar soluciones
- [ ] Lograr 66+ puntos en 120 minutos

### Matriz de Cobertura CKA

| Dominio CKA | % Examen | Labs que cubren |
|-------------|----------|-----------------|
| Cluster Architecture | 25% | Lab 02, Lab 04 |
| Workloads & Scheduling | 15% | Lab 01, Lab 04 |
| Services & Networking | 20% | Lab 03, Lab 04 |
| Storage | 10% | Lab 03, Lab 04 |
| **Troubleshooting** | **30%** | **TODOS** |

**Cobertura Total**: 100% del dominio de Troubleshooting + 70% de otros dominios

## 💡 Tips de Estudio

### Primera Pasada - Aprendizaje (Sin tiempo)
1. Lee cada escenario completo antes de empezar
2. Intenta resolver sin ver soluciones
3. Si te atascas >10 min, revisa pistas
4. Estudia la solución completa
5. Toma notas de comandos nuevos

### Segunda Pasada - Práctica (Con tiempo)
1. Establece timer según duración estimada
2. Intenta sin ayuda
3. Documenta tu proceso
4. Compara con solución oficial
5. Identifica gaps de conocimiento

### Tercera Pasada - Simulación (Examen)
1. Timer estricto (70% del tiempo)
2. Solo kubernetes.io/docs como ayuda
3. Marca problemas difíciles
4. Continúa si te atascas
5. Revisa al final

## 🔧 Troubleshooting de los Labs

### "No tengo acceso SSH a los nodes"
```bash
# Para minikube
minikube ssh

# Para kind
docker exec -it <control-plane-container> bash

# Ver containers de kind
docker ps | grep kind
```

### "No tengo permisos sudo"
Los labs 02 y 04 requieren acceso sudo. Usa minikube o kind donde tengas control completo.

### "etcd commands fallan"
```bash
# Verificar paths de certificados
ls -la /etc/kubernetes/pki/etcd/

# Usar alias completo
alias etcdctl='sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key'
```

### "Network Policies no funcionan"
Tu CNI debe soportar Network Policies. Calico y Cilium sí, Flannel NO.

```bash
# Verificar CNI
kubectl get pods -n kube-system | grep -E "calico|cilium"

# Instalar Calico si es necesario
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## 📚 Recursos Adicionales

- **Documentación**: [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- **CKA Info**: [Linux Foundation CKA](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/)
- **Practice**: [Killer.sh](https://killer.sh) - Simulador incluido con registro CKA
- **Cheatsheet**: Ver [RESUMEN-MODULO.md](../RESUMEN-MODULO.md)

## ✅ Preparación Final

Estás listo para el CKA cuando:

1. **Lab 01**: Completas en <60 minutos sin ayuda
2. **Lab 02**: Completas en <75 minutos sin ayuda
3. **Lab 03**: Completas en <75 minutos sin ayuda
4. **Lab 04**: Logras 70+ puntos en 120 minutos consistentemente

## 🎓 Próximos Pasos

1. Completa los 4 laboratorios en orden
2. Practica cada lab mínimo 3 veces
3. Toma Lab 04 como simulacro de examen (múltiples veces)
4. Cuando logres 66+ puntos consistentemente → **¡Estás listo para el CKA!**

---

**¡Buena suerte en tu preparación! 🚀**

[Volver al README del módulo](../README.md)
