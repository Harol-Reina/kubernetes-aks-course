# Apéndice F: Referencias por Capítulo

Este apéndice consolida todas las fuentes y referencias técnicas citadas en los capítulos del curso.

---

## Capítulo 1: Virtualización Tradicional

### 📚 9. Fuentes y referencias técnicas

### **📖 Fuentes principales:**
- **[Red Hat - ¿Qué es la virtualización?](https://www.redhat.com/es/topics/virtualization/what-is-virtualization)** - Documentación oficial y completa
- **[Red Hat - ¿Qué es KVM?](https://www.redhat.com/es/topics/virtualization/what-is-KVM)** - Tecnología open source de virtualización
- **[Red Hat - Hipervisores](https://www.redhat.com/es/topics/virtualization/what-is-a-hypervisor)** - Tipos y funcionamiento detallado

### **🌐 Documentación técnica oficial:**
- [Microsoft Learn – Introducción a la Virtualización](https://docs.microsoft.com/es-es/learn/modules/intro-to-azure-virtual-machines/)
- [VMware Docs – What is Virtualization](https://www.vmware.com/topics/glossary/content/virtualization.html)
- [Azure Virtual Machines Documentation](https://docs.microsoft.com/es-es/azure/virtual-machines/)
- [KVM Documentation](https://www.linux-kvm.org/page/Documents)

### **🔧 Plataformas y herramientas:**
- **[Red Hat OpenShift Virtualization](https://www.redhat.com/es/technologies/cloud-computing/openshift/virtualization)** - Virtualización en Kubernetes
- **[VMware vSphere](https://www.vmware.com/products/vsphere.html)** - Plataforma empresarial de virtualización
- **[Microsoft Hyper-V](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/)** - Hipervisor de Windows Server
- **[Proxmox VE](https://www.proxmox.com/en/proxmox-ve)** - Plataforma open source de virtualización

### **📊 Comparaciones y estudios:**
- [Red Hat - Contenedores vs VMs](https://www.redhat.com/es/topics/containers/containers-vs-vms)
- [Red Hat - Migración de VMware](https://www.redhat.com/es/technologies/cloud-computing/openshift/migrate-vmware-to-openshift-virtualization)
- [Red Hat - NFV (Network Function Virtualization)](https://www.redhat.com/es/topics/virtualization/what-is-nfv)

### **🎓 Recursos de aprendizaje:**
- [Red Hat Training - Virtualización](https://www.redhat.com/es/services/training/rh018-virtualization-and-infrastructure-migration-technical-overview)
- [Microsoft Learn - Azure Virtual Machines](https://docs.microsoft.com/en-us/learn/paths/administer-infrastructure-resources-in-azure/)
- [VMware Learning - vSphere Fundamentals](https://www.vmware.com/education-services/certification/vsphere.html)

---

---

## Capítulo 2: Docker y Contenerización

### 📚 11. Fuentes y referencias técnicas

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://compose-spec.io/)
- [BuildKit Documentation](https://docs.docker.com/build/buildkit/)
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [Docker Scout](https://docs.docker.com/scout/)
- [Container Runtime Interface (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/)
- [Open Container Initiative (OCI)](https://opencontainers.org/)
- [Linux Containers (LXC)](https://linuxcontainers.org/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Compose v2 Migration Guide](https://docs.docker.com/compose/migrate/)

---

### 📂 Recursos del Módulo

- **🔧 [Laboratorios](./laboratorios/)**
  - [Lab 1: Instalación de Docker](./laboratorios/lab-docker-install.md) ⏱️ 60min
  - [Lab 2: Primer Contenedor](./laboratorios/primer-contenedor-lab.md) ⏱️ 30min
  - [Lab 3: Namespaces y Aislamiento](./laboratorios/namespaces-isolation-lab.md) ⏱️ 30min
  - [Lab 4: Imágenes Personalizadas](./laboratorios/imagenes-personalizadas-lab.md) ⏱️ 45min
  - [Lab 5: Volúmenes y Persistencia](./laboratorios/volumenes-persistencia-lab.md) ⏱️ 40min
  - [Lab 6: Redes Docker](./laboratorios/redes-docker-lab.md) ⏱️ 50min
  - [Lab 7: Docker Compose - Evolución](./laboratorios/docker-compose-evolution-lab.md) ⏱️ 45min
  - [Lab 8: Ejercicios Prácticos](./laboratorios/docker-exercises.md) ⏱️ Variable
  - [Guía de Comandos](./laboratorios/docker-commands-guide.md) 📖 Referencia

- **📝 [Ejemplos de código](../ejemplos/)**
  - [Dockerfile Node.js](../ejemplos/Dockerfile.nodejs)
  - [Docker Compose](../ejemplos/docker-compose.yml)

---

---

## Capítulo 3: Introducción a Kubernetes

### 📖 Recursos Adicionales

### **🔗 Enlaces Oficiales:**
- **[📚 Documentación oficial Kubernetes](https://kubernetes.io/docs/)**
- **[🎥 Kubernetes in 5 minutes](https://www.youtube.com/watch?v=PH-2FfFD2PU)**
- **[📊 CNCF Landscape](https://landscape.cncf.io/)**
- **[📈 Kubernetes adoption stats](https://www.cncf.io/surveys/)**

### **🎓 Recursos de Certificación:**
- **[📜 CKA Exam Guide](https://kubernetes.io/docs/reference/config-file/kubeconfig/)**
- **[📜 CKAD Exam Guide](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/)**  
- **[📜 CKS Exam Guide](https://kubernetes.io/docs/concepts/security/)**
- **[🛠️ Killer.sh Practice Exams](https://killer.sh/)**

### **🎨 Diagramas Conceptuales:**

Los siguientes diagramas ilustran la evolución y arquitectura de Kubernetes:

#### **Evolución: Tradicional → Kubernetes:**
```
TRADICIONAL:                    KUBERNETES:
┌─────────────┐                ┌───────────────────────────┐
│   App A     │                │     CLUSTER ABSTRACTION   │
│     │       │                │   ┌─────────────────────┐ │
│   ┌─▼─┐     │                │   │ App A │ App B │ ... │ │
│   │VM1│     │                │   └─────────────────────┘ │
│   └───┘     │    ──────►     │           │               │
│             │                │           ▼               │
│   App B     │                │   ┌─────────────────────┐ │
│     │       │                │   │   Worker Nodes      │ │
│   ┌─▼─┐     │                │   │ ┌───┐ ┌───┐ ┌───┐   │ │
│   │VM2│     │                │   │ │N1 │ │N2 │ │N3 │   │ │
│   └───┘     │                │   │ └───┘ └───┘ └───┘   │ │
└─────────────┘                │   └─────────────────────┘ │
                               └───────────────────────────┘
1 App = 1 VM                   N Apps = Cluster Shared
```

#### **Abstracción de Recursos:**
```
DESARROLLADOR VE:              KUBERNETES GESTIONA:
┌─────────────────┐           ┌──────────────────────────┐
│ "Necesito:"     │           │ "Tengo disponible:"      │
│ - 2 CPU cores   │    ◄──►   │ - Node1: 8 CPU, 16GB     │
│ - 4 GB RAM      │           │ - Node2: 16 CPU, 32GB    │
│ - 100GB storage │           │ - Node3: 4 CPU, 8GB      │
│ - 3 replicas    │           │                          │
└─────────────────┘           │ Scheduler optimiza       │
                              │ distribución automática  │
                              └──────────────────────────┘
```

### **🎪 Recursos de la Comunidad:**
- **[💬 Kubernetes Slack](https://kubernetes.slack.com/)**
- **[📺 KubeCon Talks](https://www.youtube.com/c/cloudnativefdn)**
- **[📰 Kubernetes Blog](https://kubernetes.io/blog/)**
- **[🐙 Awesome Kubernetes](https://github.com/ramitsurana/awesome-kubernetes)**

---

---

## Capítulo 8: ReplicaSets y Escalado

### 📚 Recursos Adicionales

### **Documentación Oficial**
- 📖 [ReplicaSets - Kubernetes Docs](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
- 📖 [Owner References](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/)
- 📖 [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

### **Próximo Módulo**

En el **Módulo 07: Deployments y Rolling Updates**, aprenderás:
- ✅ **Rolling updates** automáticos sin downtime
- ✅ **Rollback** a versiones anteriores
- ✅ **Estrategias de despliegue** (RollingUpdate, Recreate)
- ✅ **Historial de versiones** y revisiones
- ✅ **Pause/Resume** de deployments
- ✅ **Blue-Green** y **Canary** deployments

**Diferencia clave**:
- **Módulo 06** (este): Gestión de **réplicas** y escalado
- **Módulo 07**: Gestión de **versiones** y actualizaciones

---

---

## Capítulo 9: Deployments y Rollouts

### 📚 Recursos del Módulo

### **Ejemplos Disponibles**

```
ejemplos/
├── 01-basico/
│   ├── 01-deployment-simple.yaml          # Deployment básico
│   └── 02-deployment-production.yaml      # Production-ready
├── 02-rolling-updates/
│   ├── 01-rolling-update-demo.yaml        # Demo de rolling update
│   └── 02-max-surge-unavailable.yaml      # Configuración maxSurge/maxUnavailable
├── 03-rollback/
│   ├── 01-rollback-demo.yaml              # Demo de rollback
│   └── 02-pause-resume.yaml               # Pause/resume
├── 04-estrategias/
│   ├── 01-blue-deployment.yaml            # Blue-Green: Blue
│   ├── 02-green-deployment.yaml           # Blue-Green: Green
│   ├── 03-service.yaml                    # Blue-Green: Service
│   ├── 04-stable-deployment.yaml          # Canary: Stable
│   ├── 05-canary-deployment.yaml          # Canary: Canary
│   └── 06-service-canary.yaml             # Canary: Service
└── 05-best-practices/
    └── production-template.yaml           # Template completo
```

### **Laboratorios Disponibles**

```
laboratorios/
├── lab-01-introduccion-deployments.md     # 30 min
├── lab-02-gestion-deployments.md          # 35 min
├── lab-03-rolling-updates.md              # 45 min
├── lab-04-rollback-versiones.md           # 40 min
├── lab-05-estrategias-avanzadas.md        # 60 min
├── lab-06-best-practices.md               # 50 min
├── lab-07-troubleshooting.md              # 45 min
└── lab-08-proyecto-integrador.md          # 90 min (FINAL)
```

**Tiempo total de laboratorios**: ~6 horas prácticas

---

---

## Capítulo 10: Services y Service Discovery

### 📖 Recursos Adicionales

### Documentación Oficial
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

### Artículos Recomendados
- [pabpereza.dev - Servicios en Kubernetes](https://pabpereza.dev/docs/cursos/kubernetes/servicios_en_kubernetes_clusterip_nodeport_y_loadbalancer)
- [Service Mesh (Istio, Linkerd)](https://kubernetes.io/docs/concepts/services-networking/service/)

### Herramientas
- [MetalLB](https://metallb.universe.tf/) - Load balancer para bare-metal
- [CoreDNS](https://coredns.io/) - DNS server para Kubernetes
- [Cilium](https://cilium.io/) - Networking y seguridad avanzada

---

---

## Capítulo 11: Ingress y Acceso Externo

### Recursos Adicionales

### Documentación Oficial

- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Ingress Controllers List](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- [Gateway API (successor of Ingress)](https://kubernetes.io/docs/concepts/services-networking/gateway/)

### Tutoriales Recomendados

- [Curso Kubernetes by Pabpereza](https://pabpereza.dev/docs/cursos/kubernetes/ingress_controller_en_kubernetes)
- [Ingress Nginx Examples](https://github.com/kubernetes/ingress-nginx/tree/main/docs/examples)
- [TLS with cert-manager](https://cert-manager.io/docs/usage/ingress/)

### Herramientas

| Herramienta | Descripción | Uso |
|-------------|-------------|-----|
| **cert-manager** | Gestión automática de certificados TLS (Let's Encrypt) | Certificados en producción |
| **external-dns** | Actualización automática de DNS basado en Ingress | Sincronización DNS |
| **k9s** | CLI interactiva para Kubernetes | Gestión y troubleshooting |
| **kubectx/kubens** | Cambio rápido de contextos/namespaces | Productividad |

### Comparación de Ingress Controllers

| Controller | Ventajas | Desventajas | Mejor para |
|------------|----------|-------------|------------|
| **Nginx Ingress** | Más usado, documentación extensa, estable | Configuración compleja | General purpose |
| **Traefik** | Auto-discovery, dashboard UI, fácil setup | Menos maduro que nginx | Microservicios |
| **HAProxy Ingress** | Alto rendimiento, WAF integrado | Menor comunidad | Alta carga |
| **Istio Ingress** | Service mesh, observabilidad avanzada | Complejo, overhead | Microservicios enterprise |
| **Kong Ingress** | API Gateway features, plugins | Licencia comercial para features | APIs |
| **AWS ALB Ingress** | Integración nativa AWS | Solo AWS | AWS EKS |
| **GCE Ingress** | Integración nativa GCP | Solo GCP | GKE |

### Checklist de Producción

✅ **Seguridad**:
- [ ] Todos los Ingress usan HTTPS (TLS)
- [ ] Certificados de CA confiable (Let's Encrypt con cert-manager)
- [ ] Rate limiting configurado
- [ ] Whitelist de IPs para endpoints sensibles
- [ ] Autenticación básica o OAuth para admin

✅ **Alta Disponibilidad**:
- [ ] Mínimo 3 réplicas del ingress controller
- [ ] PodDisruptionBudget configurado
- [ ] Pod anti-affinity (distribución en nodos)
- [ ] Resource requests/limits definidos
- [ ] HPA (Horizontal Pod Autoscaler) si es necesario

✅ **Monitoreo**:
- [ ] Métricas de Prometheus habilitadas
- [ ] Dashboards de Grafana creados
- [ ] Alertas configuradas (certificados expirados, errores 5xx)
- [ ] Logs centralizados (ELK, Loki)

✅ **Rendimiento**:
- [ ] Connection pooling configurado
- [ ] Timeouts apropiados
- [ ] Buffer sizes optimizados
- [ ] Compresión gzip habilitada

✅ **Gestión**:
- [ ] IngressClass definida explícitamente
- [ ] Anotaciones documentadas
- [ ] Naming conventions consistentes
- [ ] GitOps para control de versiones

---

---

## Capítulo 12: Namespaces y Organización

### Recursos Adicionales

### Documentación Oficial

- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Configure Memory and CPU Quotas](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/quota-memory-cpu-namespace/)
- [Configure Default Memory/CPU Requests/Limits](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/)

### Herramientas

| Herramienta | Descripción | Instalación |
|-------------|-------------|-------------|
| **kubectx/kubens** | Cambio rápido de contextos/namespaces | `brew install kubectx` |
| **k9s** | CLI interactiva con soporte de namespaces | `brew install k9s` |
| **Lens** | IDE de Kubernetes con gestión visual | [https://k8slens.dev](https://k8slens.dev) |

### Comandos Útiles

```bash
# Listar todos los recursos en un namespace
kubectl get all -n development

# Contar objetos por namespace
kubectl get pods --all-namespaces --no-headers | awk '{print $1}' | sort | uniq -c

# Eliminar todos los recursos de un namespace (sin eliminar el namespace)
kubectl delete all --all -n development

# Ver eventos de un namespace
kubectl get events -n development --sort-by='.lastTimestamp'

# Comparar recursos entre namespaces
diff <(kubectl get pods -n dev -o name | sort) <(kubectl get pods -n prod -o name | sort)
```

---

---

## Capítulo 13: Resource Limits en Pods

### Referencias

### Documentación Oficial

- **Kubernetes Docs**: [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- **API Reference**: [Container Resources](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#Container)
- **Quality of Service**: [Configure Quality of Service for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
- **Ephemeral Storage**: [Ephemeral Volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/)

### Módulos Relacionados

- **[Módulo 10 - Namespaces y Organización](../modulo-10-namespaces-organizacion/)**: Organización de recursos, ResourceQuota y LimitRange
- **[Módulo 12 - Health Checks y Probes](../modulo-12-health-checks-probes/)**: Liveness y Readiness probes
- **[Módulo 13 - ConfigMaps y Variables](../modulo-13-configmaps-variables/)**: Configuración externa para Pods

### Herramientas

- **[Metrics Server](https://github.com/kubernetes-sigs/metrics-server)**: Métricas de recursos
- **[Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)**: Ajuste automático de resources
- **[Goldilocks](https://github.com/FairwindsOps/goldilocks)**: Recomendaciones de resources
- **[kubectl-resource-view](https://github.com/appvia/kubectl-resource_view)**: Vista de recursos

### Artículos y Guías

- **CNCF**: [Resource Requests and Limits Best Practices](https://www.cncf.io/blog/2023/01/13/kubernetes-resource-requests-and-limits/)
- **Google Cloud**: [Best practices for managing Kubernetes resources](https://cloud.google.com/architecture/best-practices-for-running-cost-effective-kubernetes-applications-on-gke)
- **AWS**: [Amazon EKS Best Practices - Resource Management](https://aws.github.io/aws-eks-best-practices/reliability/docs/dataplane/#configure-and-size-resource-requests-and-limits-for-all-workloads)

### Videos

- **Kubernetes Resource Management Explained** - KubeCon 2024
- **Right-sizing Kubernetes Applications** - Google Cloud Next

---

---

## Capítulo 14: Health Checks y Probes

### Recursos Adicionales

### Documentación Oficial

- **Kubernetes Probes**: [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- **Pod Lifecycle**: [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- **Container Probes**: [Container Probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)

### Módulos Relacionados

- **[Módulo 11 - Resource Limits](../modulo-11-resource-limits-pods/)**: Configuración de recursos de Pods
- **[Módulo 13 - ConfigMaps y Variables](../modulo-13-configmaps-variables/)**: Configuración de aplicaciones
- **[Módulo 14 - Secrets](../modulo-14-secrets-data-sensible/)**: Gestión de credenciales

### Herramientas

- **k9s**: Monitor de recursos en tiempo real con probes
- **Lens**: IDE de Kubernetes con visualización de probes
- **Prometheus**: Métricas de probes y alertas

---

---

## Capítulo 15: ConfigMaps y Variables

### Recursos Adicionales

### Documentación Oficial

- [Kubernetes Docs - ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Docs - Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Kubernetes Docs - Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
- [The Twelve-Factor App - Config](https://12factor.net/config)

### Herramientas Recomendadas

- **[Reloader](https://github.com/stakater/Reloader)**: Auto-restart Pods cuando ConfigMaps/Secrets cambian
- **[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)**: Cifrar Secrets para Git
- **[External Secrets Operator](https://external-secrets.io/)**: Sincronizar desde Vault, AWS Secrets Manager, etc.
- **[Kustomize](https://kustomize.io/)**: Gestionar variantes de ConfigMaps por entorno

### Laboratorios

- **[Laboratorio 1: Variables y Field References](laboratorios/lab-01-env-vars-field-ref.md)** (30 min)
- **[Laboratorio 2: ConfigMaps Avanzado](laboratorios/lab-02-configmaps-avanzado.md)** (60 min)
- **[Laboratorio 3: Troubleshooting](laboratorios/lab-03-troubleshooting.md)** (45 min)

### Ejemplos de Este Módulo

Todos los ejemplos están en [`ejemplos/`](ejemplos/):

```
ejemplos/
├── 01-env-vars-basicas/        # Variables estáticas
├── 02-field-references/        # Metadata, status, resources
├── 03-configmap-literal/       # Crear desde CLI
├── 04-configmap-file/          # Crear desde archivos
├── 05-configmap-env/           # Consumir como env vars
├── 06-configmap-volume/        # Montar como volúmenes
└── 07-combinados/              # Casos reales (nginx, nodejs, etc.)
```

---

---

## Capítulo 16: Secrets y Datos Sensibles

### Referencias

### 📚 Documentación Oficial

- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Good Practices for Kubernetes Secrets](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
- [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
- [Managing Secrets using kubectl](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/)
- [Managing Secrets using Configuration File](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-config-file/)

### 🔗 Recursos Adicionales

- [External Secrets Operator](https://external-secrets.io/)
- [HashiCorp Vault](https://www.vaultproject.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [SOPS (Secrets OPerationS)](https://github.com/mozilla/sops)

### 📖 Módulos Relacionados

- [Módulo 13: ConfigMaps y Variables de Entorno](../modulo-13-configmaps-variables/)
- [Módulo 15: Persistent Volumes](../modulo-15-persistent-volumes/) (siguiente)
- [Módulo 11: Deployments](../modulo-11-deployments/)

### 🛠️ Herramientas

- `kubectl` - Cliente de línea de comandos de Kubernetes
- `base64` - Codificación/decodificación Base64
- `envsubst` - Sustitución de variables de entorno
- `jq` - Procesador JSON para consultas
- `kubeseal` - Herramienta para Sealed Secrets

---

---

## Capítulo 17: Volumes — Conceptos

### Referencias

### 📚 Documentación Oficial

- [Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Azure Disk CSI Driver](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
- [Azure Files CSI Driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)
- [AKS Storage Options](https://learn.microsoft.com/en-us/azure/aks/concepts-storage)

### 🔗 Recursos Adicionales

- [Azure Managed Disks](https://learn.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview)
- [Azure Files Documentation](https://learn.microsoft.com/en-us/azure/storage/files/)
- [Storage Performance in AKS](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-storage)

### 📖 Módulos Relacionados

- [Módulo 14: Secrets y ConfigMaps](../modulo-14-secrets-data-sensible/)
- **[Módulo 16: Volúmenes - Implementación Práctica](../modulo-16-volumes-tipos-storage/)** (siguiente - ejemplos y laboratorios)
- [Módulo 17: RBAC - Users y Groups](../modulo-17-rbac-users-groups/)

---

**¡Felicitaciones!** 🎉 Has completado los conceptos fundamentales de volúmenes en Kubernetes.

**Próximo paso**: Continúa con el [Módulo 16 - Implementación Práctica](../modulo-16-volumes-tipos-storage/) para aplicar estos conceptos con ejemplos hands-on y laboratorios.

---

## Capítulo 18: Volumes — Tipos y Storage

### 📚 Referencias Adicionales

**Documentación oficial**:
- [Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Azure Disk CSI Driver](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
- [Azure File CSI Driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)

**Mejores prácticas**:
- [AKS Storage Best Practices](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-storage)
- [Kubernetes Storage Performance](https://kubernetes.io/blog/2018/07/12/resizing-persistent-volumes-using-kubernetes/)

**Herramientas útiles**:
- [Velero](https://velero.io/) - Backup y migración de clusters
- [K9s](https://k9scli.io/) - TUI para gestión de Kubernetes
- [kubectl-view-allocations](https://github.com/davidB/kubectl-view-allocations) - Ver uso de recursos

---

---

## Capítulo 20: RBAC — ServiceAccounts

### Recursos Adicionales

**Documentación oficial**:
- [Service Accounts - Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [RBAC Authorization - Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)

**Azure específico**:
- [Azure Workload Identity](https://azure.github.io/azure-workload-identity/)
- [AKS Security Best Practices](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-cluster-security)

**Herramientas útiles**:
- [kubectl-who-can](https://github.com/aquasecurity/kubectl-who-can): Plugin para auditar permisos
- [rbac-lookup](https://github.com/FairwindsOps/rbac-lookup): Herramienta de análisis de RBAC
- [kube-bench](https://github.com/aquasecurity/kube-bench): Auditoría de seguridad de clusters

### Estructura de Archivos del Módulo

```
modulo-18-rbac-serviceaccounts/
├── README.md (este archivo)
├── ejemplos/
│   ├── 01-serviceaccount-completo.yaml
│   ├── 02-serviceaccount-basico.yaml
│   ├── 03-serviceaccounts-por-ambiente.yaml
│   ├── 04-pod-con-serviceaccount.yaml
│   ├── 05-pod-token-proyectado.yaml
│   ├── 06-rbac-completo/
│   │   ├── 01-serviceaccount.yaml
│   │   ├── 02-role.yaml
│   │   └── 03-rolebinding.yaml
│   ├── 07-clusterrole-serviceaccount.yaml
│   ├── 08-pod-custom-sa.yaml
│   ├── 09-deployment-con-sa.yaml
│   ├── 10-pod-api-access.yaml
│   ├── 11-python-api-client/
│   │   ├── deployment.yaml
│   │   └── app.py
│   ├── 12-caso-uso-monitoreo.yaml
│   ├── 13-caso-uso-cicd.yaml
│   ├── 14-caso-uso-config-reader.yaml
│   ├── 15-caso-uso-operator.yaml
│   ├── 16-caso-uso-azure-workload-identity.yaml
│   ├── 17-pod-sin-sa.yaml
│   ├── 18-networkpolicy-sa.yaml
│   ├── 19-pod-security-standards.yaml
│   ├── 20-configuracion-segura-completa.yaml
│   └── 21-debug-pod.yaml
└── laboratorios/
    ├── lab-01-crear-serviceaccounts.md
    ├── lab-02-permisos-serviceaccounts.md
    ├── lab-03-pods-con-serviceaccounts.md
    ├── lab-04-casos-uso-practicos.md
    └── lab-05-troubleshooting.md
```

---

---

## Capítulo 21: Jobs y CronJobs

### 📚 Sección 9: Recursos Adicionales

#### 9.1 Documentación Oficial

**Kubernetes Docs:**
- [Jobs Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJob Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Job Patterns](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-patterns)
- [API Reference - Job](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/job-v1/)
- [API Reference - CronJob](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/cron-job-v1/)

**Best Practices:**
- [Running Automated Tasks](https://kubernetes.io/docs/tasks/job/)
- [Configure Parallel Processing](https://kubernetes.io/docs/tasks/job/parallel-processing-expansion/)
- [Handling Pod and Container Failures](https://kubernetes.io/docs/concepts/workloads/controllers/job/#handling-pod-and-container-failures)

#### 9.2 Tutoriales y Guías

**Tutoriales oficiales:**
- [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)
- [Coarse Parallel Processing Using a Work Queue](https://kubernetes.io/docs/tasks/job/coarse-parallel-processing-work-queue/)
- [Fine Parallel Processing Using a Work Queue](https://kubernetes.io/docs/tasks/job/fine-parallel-processing-work-queue/)

**Blog posts recomendados:**
- [Kubernetes Jobs and CronJobs Explained](https://blog.container-solutions.com/kubernetes-jobs-and-cronjobs)
- [Advanced Job Patterns](https://medium.com/@marko.luksa/kubernetes-job-patterns-b7e1c1d8e55a)
- [Best Practices for Kubernetes Jobs](https://cloud.google.com/blog/products/containers-kubernetes/best-practices-for-running-cost-effective-kubernetes-applications-on-gke)

**Videos explicativos:**
- [Kubernetes Jobs Tutorial - TechWorld with Nana](https://www.youtube.com/watch?v=6wB1wMqXmns)
- [CronJobs Deep Dive - CNCF](https://www.youtube.com/watch?v=PVYikPDVqAM)

#### 9.3 Herramientas Complementarias

**1. Kube-batch / Volcano**
- Batch scheduling avanzado para Kubernetes
- Mejor para workloads científicos y ML
- [Volcano Project](https://volcano.sh/)

**2. Argo Workflows**
- Orquestación de workflows complejos
- DAGs (Directed Acyclic Graphs)
- [Argo Workflows Docs](https://argoproj.github.io/argo-workflows/)

**3. Apache Airflow on K8s**
- Data pipelines y ETL
- Scheduler robusto
- [Airflow Kubernetes Executor](https://airflow.apache.org/docs/apache-airflow/stable/executor/kubernetes.html)

**4. Tekton Pipelines**
- CI/CD nativo de Kubernetes
- Pipeline as Code
- [Tekton Docs](https://tekton.dev/)

**5. Kueue**
- Queue management para batch workloads
- Fair sharing y priorización
- [Kueue Project](https://kueue.sigs.k8s.io/)

#### 9.4 Comunidad y Soporte

**Recursos de la comunidad:**
- [Kubernetes Slack](https://slack.k8s.io) - Canal #sig-apps
- [Stack Overflow - kubernetes-jobs](https://stackoverflow.com/questions/tagged/kubernetes-jobs)
- [Reddit r/kubernetes](https://reddit.com/r/kubernetes)
- [Kubernetes Forum](https://discuss.kubernetes.io/)

**Repositorios de ejemplos:**
- [Kubernetes Examples - Jobs](https://github.com/kubernetes/examples/tree/master/staging/job)
- [Awesome Kubernetes - Jobs](https://github.com/ramitsurana/awesome-kubernetes#jobs)

**Cursos adicionales:**
- [CKAD Certification Prep](https://training.linuxfoundation.org/training/kubernetes-for-developers/)
- [Udemy - Kubernetes Jobs Mastery](https://www.udemy.com/topic/kubernetes/)

---

### ✅ Sección 10: Evaluación y Siguientes Pasos

#### 10.1 Checklist de Dominio del Módulo

**Conceptos teóricos:**
- [ ] Explicar la diferencia entre Job, Deployment y CronJob
- [ ] Describir el ciclo de vida de un Job (pending → running → completed/failed)
- [ ] Justificar cuándo usar Jobs vs otros workloads
- [ ] Comprender `completions`, `parallelism` y `backoffLimit`
- [ ] Explicar sintaxis de cron schedule (5 campos)
- [ ] Conocer patrones de Jobs (simple, paralelo, work queue, indexed)

**Habilidades prácticas:**
- [ ] Crear Job simple desde YAML y desde kubectl create
- [ ] Configurar Job paralelo con completions y parallelism
- [ ] Implementar CronJob con schedule correcto
- [ ] Configurar TTL para limpieza automática
- [ ] Usar activeDeadlineSeconds para timeouts
- [ ] Configurar concurrencyPolicy en CronJobs
- [ ] Gestionar histórico con successfulJobsHistoryLimit

**Troubleshooting:**
- [ ] Diagnosticar Job que no completa (CrashLoopBackOff)
- [ ] Resolver CronJob que no ejecuta según schedule
- [ ] Debugging de Jobs con múltiples reintentos fallidos
- [ ] Identificar problemas de concurrencia
- [ ] Analizar logs de Jobs completados

**Comandos esenciales:**
- [ ] `kubectl create job` - Crear Job imperativo
- [ ] `kubectl get jobs` - Listar Jobs
- [ ] `kubectl describe job` - Ver detalles y eventos
- [ ] `kubectl logs job/<name>` - Ver logs
- [ ] `kubectl delete jobs --field-selector status.successful=1` - Limpiar
- [ ] `kubectl create job --from=cronjob/<name>` - Trigger manual de CronJob

#### 10.2 Ejercicios de Auto-Evaluación

**Ejercicio 1: Implementación desde cero**

**Requisitos:**
- Crear Job que procesa 50 archivos en paralelo
- Máximo 10 workers simultáneos
- 3 reintentos por archivo
- Timeout total de 30 minutos
- Limpieza automática después de 1 hora

**Solución esperada:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: file-processor
spec:
  completions: 50
  parallelism: 10
  backoffLimit: 3
  activeDeadlineSeconds: 1800
  ttlSecondsAfterFinished: 3600
  template:
    spec:
      containers:
      - name: processor
        image: file-processor:v1
        command: ["python", "process.py"]
      restartPolicy: OnFailure
```

**Ejercicio 2: Debugging challenge**

**Escenario:** CronJob no ejecuta según schedule:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: broken-cronjob
spec:
  schedule: "0 2 * * *"
  suspend: true  # ⚠️ PROBLEMA!
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup:v1
          restartPolicy: Never
```

**Preguntas:**
1. ¿Por qué no se ejecuta? → `suspend: true`
2. ¿Cómo verificar? → `kubectl describe cronjob`
3. ¿Cómo resolver? → `kubectl patch cronjob broken-cronjob -p '{"spec":{"suspend":false}}'`

**Ejercicio 3: Diseño de solución**

**Caso de uso:** Empresa necesita:
- Generar report de ventas cada Lunes a las 8 AM
- Backup de base de datos cada 6 horas
- Limpieza de logs antiguos el primer día de cada mes
- No permitir ejecuciones simultáneas

**Diseño esperado:**
```yaml
# Report Semanal
schedule: "0 8 * * 1"
concurrencyPolicy: Forbid

# Backup cada 6h
schedule: "0 */6 * * *"
concurrencyPolicy: Replace

# Limpieza Mensual
schedule: "0 0 1 * *"
concurrencyPolicy: Forbid
```

#### 10.3 Preparación para Certificación CKAD

**Relevancia del módulo:**
⭐⭐⭐⭐⭐ **CRÍTICO para CKAD** (20% del examen)

**Peso en examen:**
- Jobs: ~10-12% de las preguntas
- CronJobs: ~8% de las preguntas
- Total: 18-20% del examen CKAD

**Temas clave a dominar:**

1. **Crear Jobs imperativamente (velocidad)**
   ```bash
   # En examen, esto es más rápido que escribir YAML
   kubectl create job test --image=busybox -- echo "test"
   ```

2. **Configurar completions y parallelism**
   - Memorizar sintaxis exacta
   - Practicar sin kubectl explain

3. **CronJob schedule syntax**
   - Memorizar patrones comunes
   - Saber interpretar y crear schedules

4. **Troubleshooting rápido**
   - `kubectl describe job`
   - `kubectl logs job/<name>`
   - Ver status.failed y status.succeeded

**Preguntas tipo examen:**

**Pregunta 1 (Práctica):**
> Crear un Job llamado `data-import` que ejecute la imagen `busybox:1.35` con el comando `echo "Importing data..." && sleep 30 && echo "Done!"`. El Job debe tener:
> - backoffLimit: 3
> - activeDeadlineSeconds: 120
> - restartPolicy: Never

**Respuesta:**
```bash
kubectl create job data-import --image=busybox:1.35 -- /bin/sh -c "echo 'Importing data...' && sleep 30 && echo 'Done!'" --dry-run=client -o yaml > job.yaml

# Editar job.yaml y agregar:
spec:
  backoffLimit: 3
  activeDeadlineSeconds: 120
  template:
    spec:
      restartPolicy: Never

kubectl apply -f job.yaml
```

**Pregunta 2 (CronJob):**
> Crear CronJob `backup-hourly` que ejecute cada hora la imagen `postgres:15` con comando `pg_dump mydb > /backup/backup.sql`. Configurar:
> - concurrencyPolicy: Forbid
> - successfulJobsHistoryLimit: 3
> - restartPolicy: OnFailure

**Respuesta:**
```bash
kubectl create cronjob backup-hourly --image=postgres:15 --schedule="0 * * * *" -- pg_dump mydb > /backup/backup.sql --dry-run=client -o yaml > cronjob.yaml

# Editar y agregar políticas
kubectl apply -f cronjob.yaml
```

**Pregunta 3 (Troubleshooting):**
> Un Job llamado `process-data` tiene 5 Pods en estado CrashLoopBackOff. ¿Cómo investigas?

**Respuesta:**
```bash
# 1. Ver estado del Job
kubectl describe job process-data

# 2. Ver logs del Pod
kubectl logs -l job-name=process-data --tail=50

# 3. Ver eventos
kubectl get events --sort-by='.lastTimestamp' | grep process-data

# 4. Verificar configuración
kubectl get job process-data -o yaml
```

#### 10.4 Tips de Estudio por Nivel

**Para principiantes:**
- 📖 Lee las secciones 1-4 completas (fundamentos)
- 🧪 Haz Labs 1 y 2 paso a paso
- 📝 Crea cheat sheet personal de comandos
- 🔄 Practica crear Jobs imperativos 10 veces
- ⏰ Aprende sintaxis cron con crontab.guru

**Para intermedios:**
- 🎯 Enfócate en Labs 3 y 4 (avanzados)
- 🔍 Practica troubleshooting sin mirar soluciones
- 💡 Experimenta con diferentes patrones de Jobs
- 🏗️ Crea tus propios casos de uso
- ⚙️ Integra Jobs con ConfigMaps y Volumes

**Para certificación CKAD:**
- ⏱️ Practica crear Jobs en menos de 2 minutos
- 📚 Memoriza comandos sin autocompletado
- 🧩 Resuelve troubleshooting challenges bajo presión
- 🎓 Simula condiciones de examen (sin internet)
- 🔁 Repite labs hasta hacerlos "de memoria"

---

### ▶️ Navegación

- **⬅️ Módulo Anterior**: [Módulo 18 - RBAC: ServiceAccounts](../modulo-18-rbac-serviceaccounts/README.md)
- **➡️ Siguiente Módulo**: [Módulo 20 - Init Containers & Sidecar Patterns](../modulo-20-init-sidecar-patterns/README.md) *(en desarrollo)*
- **🏠 Índice del Área**: [Área 2 - Arquitectura Kubernetes](../README.md)
- **📚 Curso Principal**: [Inicio](../../README.md)
- **📋 RESUMEN**: [RESUMEN-MODULO.md](./RESUMEN-MODULO.md)

---

### 💡 Consejos Finales

**Estrategias de aprendizaje efectivas:**

1. **📖 Teoría primero, práctica después**
   - Lee secciones 1-6 completas
   - Entiende el "por qué" antes del "cómo"
   - Toma notas de conceptos clave

2. **🧪 Hands-on prioritario**
   - Haz TODOS los labs en orden
   - No copies y pegues, escribe los comandos
   - Experimenta más allá de las guías

3. **🤔 Aprende de los errores**
   - Si un Job falla, investiga por qué
   - Usa `kubectl describe` y `kubectl logs`
   - Documenta errores y soluciones

4. **🔄 Repetición espaciada**
   - Día 1: Labs 1-2
   - Día 3: Labs 3-4
   - Día 7: Repite todos los labs
   - Día 14: Repaso final

5. **🎓 Prepárate para CKAD**
   - Practica velocidad (2 min por Job)
   - Memoriza sintaxis cron común
   - Simula examen con timer

**Errores comunes a evitar:**

- ❌ Usar `restartPolicy: Always` en Jobs
- ❌ Olvidar configurar `backoffLimit`
- ❌ No configurar TTL (acumulación de Jobs)
- ❌ Schedules muy frecuentes sin necesidad
- ❌ No probar CronJobs con trigger manual primero
- ❌ Ignorar `concurrencyPolicy` en CronJobs críticos

**Recursos extra de práctica:**

- **Killer.sh**: Simulador de examen CKAD (incluye Jobs)
- **KodeKloud**: Labs interactivos de Jobs y CronJobs
- **Katacoda**: Escenarios de Kubernetes hands-on
- **Play with Kubernetes**: Cluster temporal gratis

---

**🎉 ¡Felicitaciones por completar el Módulo 19!**

*Has adquirido conocimientos fundamentales de Jobs y CronJobs que te preparan para ejecutar tareas batch y programadas en Kubernetes, una habilidad crítica para CKAD y operaciones en producción.*

**Tiempo estimado de estudio**: 
- 4-5 horas (principiante) 
- 2-3 horas (intermedio) 
- 1-2 horas (certificación)

**Estado**: ✅ 100% Completo  
**Versión**: 1.0  
**Última actualización**: Noviembre 2025

---

## Capítulo 22: Init Containers y Sidecar Patterns

### 📖 Recursos Adicionales

### Documentación Oficial

- [Kubernetes Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Multi-Container Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [CKAD Curriculum](https://github.com/cncf/curriculum/blob/master/CKAD_Curriculum_v1.28.pdf)

### Ejemplos YAML

Todos los ejemplos en `/ejemplos/`:

```bash
# Aplicar ejemplo básico
kubectl apply -f ejemplos/init-container-basic.yaml

# Aplicar ejemplo completo
kubectl apply -f ejemplos/multi-container-full.yaml
```

---

---

## Capítulo 23: Helm Basics

### 📖 Recursos Adicionales

### Documentación Oficial
- **Helm Docs**: https://helm.sh/docs/
- **Chart Best Practices**: https://helm.sh/docs/chart_best_practices/
- **Chart Template Guide**: https://helm.sh/docs/chart_template_guide/

### Repositorios Útiles
- **Artifact Hub**: https://artifacthub.io/
- **Bitnami Charts**: https://github.com/bitnami/charts
- **Helm Stable**: https://github.com/helm/charts

### Herramientas
- **Helmfile**: Gestión declarativa de releases
- **Helm Diff**: Ver diferencias antes de upgrade
- **ChartMuseum**: Repositorio privado de charts

---

---

## Capítulo 24: Cluster Setup con kubeadm

### 🔗 Referencias

- [kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [CNI Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [etcd Documentation](https://etcd.io/docs/)
- [Cluster Administration](https://kubernetes.io/docs/tasks/administer-cluster/)

---

---

## Capítulo 25: Mantenimiento y Upgrades

### 📚 Referencias

- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
- [Certificate Management](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [Safely Drain Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
- [Kubernetes Release Notes](https://kubernetes.io/docs/setup/release/notes/)

---

---

## Capítulo 26: Advanced Scheduling

### 📚 Referencias

- [Scheduling Framework](https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/)
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

---

---

## Capítulo 27: Networking Avanzado

### Recursos Adicionales

### Documentación Oficial

- [Kubernetes Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [CoreDNS](https://coredns.io/plugins/kubernetes/)

### Tools

- [Calico](https://www.tigera.io/project-calico/)
- [Cilium](https://cilium.io/)
- [Ingress-Nginx](https://kubernetes.github.io/ingress-nginx/)
- [Istio](https://istio.io/)
- [Linkerd](https://linkerd.io/)

### Labs y Tutoriales

- Ver directorio `laboratorios/` para prácticas hands-on
- Ver directorio `ejemplos/` para YAML de referencia

---

---

## Parte III

- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Azure Key Vault Provider](https://azure.github.io/secrets-store-csi-driver-provider-azure/)

---

## Parte IV

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Azure DevOps with Kubernetes](https://docs.microsoft.com/en-us/azure/devops/pipelines/ecosystems/kubernetes/)

---

