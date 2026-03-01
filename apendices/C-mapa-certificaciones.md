# Apendice C: Mapa de Certificaciones

> Para el mapeo detallado completo, consulta [PLAN-CERTIFICACIONES.md](../PLAN-CERTIFICACIONES.md).

---

## Estado de Cobertura del Curso

| Certificacion | Cobertura | Estado |
|---------------|-----------|--------|
| **CKAD** | 95% | Lista (100% con labs de M14-16) |
| **CKA** | 75% | Media (85%+ con expansion M22-23) |
| **AKS Specialty** | 70% | Media (90%+ con mejoras Areas 3-4) |

---

## CKAD (Certified Kubernetes Application Developer)

**Peso en el examen y capitulos del curso que cubren cada dominio:**

| Dominio CKAD | Peso | Capitulos del Curso |
|--------------|------|---------------------|
| **Application Design and Build** | 20% | Cap 6 (Pods), Cap 7 (Gestion Pods), Cap 22 (Init/Sidecar), Cap 9 (Deployments) |
| **Application Deployment** | 20% | Cap 9 (Deployments/Rollouts), Cap 23 (Helm), Cap 9 (Blue/Green, Canary) |
| **Application Observability and Maintenance** | 15% | Cap 14 (Health Checks/Probes), Cap 7 (Lifecycle hooks), Cap 28 (Troubleshooting) |
| **Application Environment, Configuration and Security** | 25% | Cap 15 (ConfigMaps), Cap 16 (Secrets), Cap 13 (Resource Limits), Cap 19-20 (RBAC) |
| **Services and Networking** | 20% | Cap 10 (Services), Cap 11 (Ingress), Cap 27 (Networking/NetworkPolicies) |

### Detalle por Dominio CKAD

**Application Design and Build (20%)**
- Define, build and modify container images: Cap 2 (Docker)
- Choose and use the right workload resource: Cap 6 (Pods), Cap 8 (ReplicaSets), Cap 9 (Deployments), Cap 21 (Jobs/CronJobs)
- Understand multi-container Pod design patterns: Cap 22 (Init/Sidecar/Ambassador/Adapter)
- Utilize persistent and ephemeral volumes: Cap 17-18 (Volumes)

**Application Deployment (20%)**
- Use Kubernetes primitives to implement deployment strategies: Cap 9 (Rolling Update, Recreate)
- Implement blue/green or canary deployments: Cap 9 (Strategies avanzadas)
- Use Helm package manager: Cap 23 (Helm Basics)

**Application Observability and Maintenance (15%)**
- Understand API deprecations: Cap 3 (Intro K8s)
- Implement probes and health checks: Cap 14 (Startup/Liveness/Readiness)
- Use built-in CLI tools to monitor K8s apps: Cap 28 (Troubleshooting), Cap 13 (kubectl top)
- Utilize container logs: Cap 6 (Pod logs), Cap 28

**Application Environment, Configuration and Security (25%)**
- Discover and use resources that extend K8s (CRD): Cap 23 (Helm)
- Understand authentication, authorization: Cap 19-20 (RBAC Users, ServiceAccounts)
- Understanding and defining resource requirements: Cap 13 (Resource Limits)
- ConfigMaps: Cap 15
- Create and consume Secrets: Cap 16
- Understand ServiceAccounts: Cap 20

**Services and Networking (20%)**
- Demonstrate basic understanding of NetworkPolicies: Cap 27 (Networking)
- Provide and troubleshoot access to apps via services: Cap 10 (Services)
- Use Ingress rules to expose apps: Cap 11 (Ingress)

---

## CKA (Certified Kubernetes Administrator)

**Peso en el examen y capitulos del curso que cubren cada dominio:**

| Dominio CKA | Peso | Capitulos del Curso |
|-------------|------|---------------------|
| **Cluster Architecture, Installation & Configuration** | 25% | Cap 4 (Arquitectura), Cap 24 (kubeadm), Cap 19-20 (RBAC) |
| **Workloads & Scheduling** | 15% | Cap 6-9 (Pods, RS, Deploy), Cap 26 (Advanced Scheduling) |
| **Services & Networking** | 20% | Cap 10-11 (Services, Ingress), Cap 27 (Networking, CNI, DNS) |
| **Storage** | 10% | Cap 17-18 (Volumes, PV/PVC, StorageClasses) |
| **Troubleshooting** | 30% | Cap 28 (Troubleshooting), Cap 25 (Maintenance), Cap 27 (Network debug) |

### Detalle por Dominio CKA

**Cluster Architecture, Installation & Configuration (25%)**
- Manage role based access control (RBAC): Cap 19 (Users/Groups), Cap 20 (ServiceAccounts)
- Use kubeadm to install a basic cluster: Cap 24 (Cluster Setup)
- Manage a highly-available Kubernetes cluster: Cap 24 (HA setup)
- Provision underlying infrastructure to deploy K8s: Cap 24
- Perform a version upgrade using kubeadm: Cap 25 (Maintenance/Upgrades)
- Implement etcd backup and restore: Cap 25 (etcd backup/restore)

**Workloads & Scheduling (15%)**
- Understand deployments and rolling updates: Cap 9 (Deployments/Rollouts)
- Use ConfigMaps and Secrets: Cap 15 (ConfigMaps), Cap 16 (Secrets)
- Know how to scale applications: Cap 8 (ReplicaSets), Cap 9 (Deployments)
- Understand resource limits and Pod scheduling: Cap 13 (Resource Limits)
- Awareness of manifest management: Cap 23 (Helm)
- Understand Taints and Tolerations: Cap 26 (Advanced Scheduling)
- Understand Node Affinity: Cap 26
- Understand DaemonSets: Cap 26
- Understand Static Pods: Cap 26

**Services & Networking (20%)**
- Understand host networking on cluster nodes: Cap 27 (Networking Deep Dive)
- Understand connectivity between Pods: Cap 27 (CNI)
- Understand ClusterIP, NodePort, LoadBalancer: Cap 10 (Services)
- Know how to use Ingress controllers and Ingress resources: Cap 11 (Ingress)
- Know how to configure and use CoreDNS: Cap 27 (DNS)
- Choose an appropriate container network interface plugin: Cap 27 (CNI)

**Storage (10%)**
- Understand storage classes, PVs: Cap 17-18 (Volumes)
- Understand volume modes, access modes, reclaim policies: Cap 17
- Understand PVCs: Cap 18
- Know how to configure apps with persistent storage: Cap 18

**Troubleshooting (30%)**
- Evaluate cluster and node logging: Cap 28 (Troubleshooting)
- Understand how to monitor applications: Cap 14 (Probes), Cap 13 (kubectl top)
- Manage container stdout & stderr logs: Cap 28
- Troubleshoot application failure: Cap 28
- Troubleshoot cluster component failure: Cap 28
- Troubleshoot networking: Cap 27, Cap 28

---

## Azure AKS Specialty

**Dominios del examen y capitulos del curso que cubren cada area:**

| Dominio AKS | Peso Aprox. | Capitulos del Curso |
|-------------|-------------|---------------------|
| **Deploy and Configure AKS** | 25% | Cap 5 (Minikube/kubectl), Cap 24 (kubeadm conceptos), Area 3 (AKS setup) |
| **Manage AKS Networking** | 20% | Cap 10-11 (Services, Ingress), Cap 27 (Networking, CNI) |
| **Manage AKS Storage** | 15% | Cap 17-18 (Volumes, Azure Disk/Files, StorageClasses) |
| **Manage AKS Security** | 20% | Cap 19-20 (RBAC), Cap 16 (Secrets), Area 3 (Azure AD, Policy) |
| **Monitor and Maintain AKS** | 20% | Cap 14 (Probes), Cap 25 (Upgrades), Cap 28 (Troubleshooting) |

### Detalle por Dominio AKS

**Deploy and Configure AKS (25%)**
- Create and configure AKS clusters: Area 3 (Portal + CLI)
- Configure node pools and scaling: Area 3 (Node pools, Autoscaling)
- Configure Azure Container Registry (ACR): Area 3 (ACR integration)
- Deploy workloads: Cap 9 (Deployments), Cap 23 (Helm)
- Use Managed Identity: Area 3 (Identity)

**Manage AKS Networking (20%)**
- Configure Azure CNI networking: Cap 27 (CNI plugins)
- Configure Services (LoadBalancer): Cap 10 (Services)
- Configure Ingress (AGIC/nginx): Cap 11 (Ingress)
- Implement Network Policies: Cap 27 (Network Policies)
- Configure DNS: Cap 27 (CoreDNS)

**Manage AKS Storage (15%)**
- Configure Azure Disk: Cap 18 (Azure Disk)
- Configure Azure Files: Cap 18 (Azure Files)
- Implement StorageClasses: Cap 18 (Dynamic provisioning)
- Manage PV/PVC lifecycle: Cap 17-18

**Manage AKS Security (20%)**
- Implement RBAC: Cap 19-20 (Users, ServiceAccounts)
- Integrate Azure AD: Area 3 (Azure AD + RBAC)
- Manage Secrets: Cap 16 (Secrets)
- Implement Azure Policy for AKS: Area 3 (Pendiente)
- Configure Azure Defender: Area 3 (Pendiente)

**Monitor and Maintain AKS (20%)**
- Configure health probes: Cap 14 (Probes)
- Implement Container Insights: Area 4 (Monitoring)
- Configure Log Analytics: Area 4 (Observability)
- Plan and execute cluster upgrades: Cap 25 (Maintenance)
- Implement HPA: Cap 13 (Resources), Area 4

---

## Modulos Clave por Certificacion

### Top 10 Modulos para CKAD

1. Cap 9: Deployments y Rolling Updates (30%)
2. Cap 15: ConfigMaps y Variables (25%)
3. Cap 16: Secrets (25%)
4. Cap 6: Pods vs Contenedores (20%)
5. Cap 10: Services y Endpoints (20%)
6. Cap 21: Jobs y CronJobs (20%)
7. Cap 14: Health Checks y Probes (15%)
8. Cap 22: Init Containers y Sidecar (10%)
9. Cap 11: Ingress (20%)
10. Cap 23: Helm (7%)

### Top 10 Modulos para CKA

1. Cap 28: Troubleshooting Avanzado (30%)
2. Cap 24: Cluster Setup con kubeadm (25%)
3. Cap 27: Networking Deep Dive (20%)
4. Cap 19-20: RBAC (25%)
5. Cap 25: Cluster Maintenance (25%)
6. Cap 26: Advanced Scheduling (15%)
7. Cap 10-11: Services e Ingress (20%)
8. Cap 17-18: Volumes y Storage (10%)
9. Cap 9: Deployments (15%)
10. Cap 13: Resource Limits (15%)

### Top 10 Modulos para AKS

1. Area 3: Deploy y Configure AKS (25%)
2. Cap 27: Networking (Azure CNI) (20%)
3. Cap 19-20: RBAC + Azure AD (20%)
4. Cap 17-18: Storage (Azure Disk/Files) (15%)
5. Cap 25: Maintenance y Upgrades (20%)
6. Cap 10-11: Services e Ingress (AGIC) (20%)
7. Cap 14: Health Probes (20%)
8. Area 4: Monitoring y HA (20%)
9. Cap 16: Secrets (Azure Key Vault) (20%)
10. Cap 23: Helm (Deployments) (25%)
