# Laboratorios - Modulo 04: Pods vs Contenedores

Laboratorios practicos para comprender las diferencias fundamentales entre Pods y Contenedores,
los patrones de diseno multi-container y la migracion desde Docker Compose.

---

## Estructura de Directorios

```
laboratorios/
├── README.md                        # Este indice
├── lab-01-evolucion/
│   ├── README.md                    # Lab: LXC -> Docker -> Kubernetes
│   ├── SETUP.md                     # Prerequisitos y verificacion
│   └── cleanup.sh                   # Limpieza de recursos Docker y Kubernetes
├── lab-02-namespace-sharing/
│   ├── README.md                    # Lab: Network, IPC y PID namespace sharing
│   ├── SETUP.md
│   └── cleanup.sh
├── lab-03-sidecar-real-world/
│   ├── README.md                    # Lab: Logging, monitoring y proxy sidecar
│   ├── SETUP.md
│   └── cleanup.sh
├── lab-04-init-migration/
│   ├── README.md                    # Lab: Migracion de setup scripts a init containers
│   ├── SETUP.md
│   └── cleanup.sh
├── lab-05-compose-migration/
│   ├── README.md                    # Lab: Migracion de Docker Compose a Kubernetes
│   ├── SETUP.md
│   ├── cleanup.sh
│   ├── db-deployment.yaml           # PVC + ConfigMap + Secret + Deployment + Service PostgreSQL
│   ├── api-deployment.yaml          # ConfigMap + Deployment + Service API Node.js
│   └── web-deployment.yaml          # ConfigMap (nginx.conf) + Deployment + Service NodePort Nginx
└── lab-resumen-pods/
    ├── README.md                    # Lab resumen: repaso integral de 15 minutos
    ├── cleanup.sh                   # Elimina namespace lab-pods-test
    └── pods-lab.yaml                # YAML unico: Namespace + 5 Pods de todos los conceptos
```

---

## Tabla de Laboratorios

| Lab | Titulo | Duracion | Nivel | Archivos YAML |
|-----|--------|----------|-------|---------------|
| [Lab 01](./lab-01-evolucion/) | Evolucion: LXC → Docker → Kubernetes | 30 min | Basico | inline en README |
| [Lab 02](./lab-02-namespace-sharing/) | Namespace Sharing (network, IPC, PID) | 45 min | Intermedio | inline en README |
| [Lab 03](./lab-03-sidecar-real-world/) | Sidecar Real World (logging, proxy) | 60 min | Intermedio | inline en README |
| [Lab 04](./lab-04-init-migration/) | Init Container Migration | 45 min | Intermedio | inline en README |
| [Lab 05](./lab-05-compose-migration/) | Migracion de Docker Compose | 50 min | Intermedio | 3 archivos `.yaml` |
| [Lab Resumen](./lab-resumen-pods/) | Repaso integral Pods | 15 min | Intermedio | `pods-lab.yaml` |

**Tiempo total estimado:** 4-5 horas (sin el Lab Resumen que es para repaso rapido)

---

## Ruta de Aprendizaje Recomendada

```
Nivel Basico
└── Lab 01: Evolucion (LXC → Docker → Kubernetes)
    Comprende POR QUE existen los Pods y como evolucionaron los contenedores.

Nivel Intermedio
├── Lab 02: Namespace Sharing
│   Experimenta con network, IPC y PID namespaces compartidos.
├── Lab 03: Sidecar Real World
│   Implementa patrones de logging, monitoring y proxy con sidecars.
└── Lab 04: Init Container Migration
    Convierte setup scripts en init containers con dependencias.

Nivel Avanzado
└── Lab 05: Docker Compose Migration
    Migra una app multi-service completa (web + api + db) a Kubernetes.

Repaso Pre-Examen
└── Lab Resumen: Pods
    Repasa todos los conceptos en 15 minutos con un solo YAML.
```

---

## Prerequisitos del Modulo

```bash
# Verificar cluster activo
kubectl cluster-info
kubectl get nodes

# Verificar Docker (necesario para Labs 01-02)
docker --version
docker ps

# Verificar espacio en disco para PVCs (Lab 05)
kubectl get storageclass
```

---

## Conceptos Evaluados en CKAD/CKA

| Concepto | Labs | Relevancia examen |
|----------|------|-------------------|
| Pods multi-container | 01, 02, Resumen | CKAD - Alta |
| Sidecar pattern (logging, proxy) | 03, Resumen | CKAD - Alta |
| Init containers y dependencias | 04, Resumen | CKAD - Alta |
| shareProcessNamespace | 02, Resumen | CKAD/CKA - Media |
| emptyDir y volumen compartido | 03, Resumen | CKAD - Alta |
| ConfigMap y Secret en Deployments | 05 | CKAD - Alta |
| PersistentVolumeClaim | 05 | CKAD/CKA - Alta |
| Migracion Docker Compose → K8s | 05 | Profesional |

---

## Limpieza Global

Para limpiar todos los recursos de todos los labs:

```bash
# Labs 01-04: cada uno tiene su propio cleanup.sh
./lab-01-evolucion/cleanup.sh
./lab-02-namespace-sharing/cleanup.sh
./lab-03-sidecar-real-world/cleanup.sh
./lab-04-init-migration/cleanup.sh

# Lab 05: recursos en namespace default
./lab-05-compose-migration/cleanup.sh

# Lab Resumen: elimina namespace lab-pods-test
./lab-resumen-pods/cleanup.sh
```
