# Apendice A: Objetivos de Aprendizaje por Capitulo

> Este apendice consolida los objetivos de aprendizaje de los 28 capitulos del curso, extraidos directamente de las secciones de cabecera de cada modulo README.md.

---

## Capitulo 1: Virtualizacion Tradicional

**Modulo**: `area-1-fundamentos-docker/modulo-1-virtualizacion/`

### Conceptuales
- Comprender que es la virtualizacion y como revoluciono la infraestructura TI tradicional
- Explicar el rol del hipervisor en la gestion de recursos fisicos virtualizados
- Diferenciar entre hipervisores tipo 1 (bare-metal) y tipo 2 (hosted)
- Identificar los diferentes tipos de virtualizacion (servidores, red, almacenamiento, aplicaciones, NFV)
- Entender la evolucion desde hardware dedicado hasta maquinas virtuales

### Tecnicos
- Crear y configurar maquinas virtuales en Azure Cloud
- Conectarse remotamente a VMs via SSH y gestionar recursos del sistema
- Monitorear uso de CPU, memoria y almacenamiento en entornos virtualizados
- Implementar laboratorios practicos con VirtualBox, KVM o Hyper-V
- Realizar migraciones basicas de VMs entre hosts

### Troubleshooting
- Diagnosticar problemas comunes de rendimiento en VMs (CPU steal time, memory ballooning)
- Identificar cuando el overhead de virtualizacion afecta el performance
- Resolver conflictos de recursos entre multiples VMs en el mismo host
- Troubleshoot conectividad de red en entornos virtualizados
- Analizar metricas de hipervisor para optimizar asignacion de recursos

### Profesionales
- Evaluar ventajas y desventajas de la virtualizacion vs. hardware dedicado
- Justificar decisiones arquitectonicas: VMs vs. Contenedores vs. Serverless
- Planificar estrategias de consolidacion de servidores para reducir costos
- Comprender las bases conceptuales necesarias para trabajar con Kubernetes
- Prepararse para certificaciones como VMware VCP, Microsoft MCSA o Red Hat RHCVA

---

## Capitulo 2: Docker y Contenerizacion

**Modulo**: `area-1-fundamentos-docker/modulo-2-docker/`

### Conceptuales
- Comprender que es un contenedor y como difiere fundamentalmente de una VM
- Explicar los 4 pilares de Docker: Contenedores, Imagenes, Dockerfiles y Docker Hub
- Entender las tecnologias Linux subyacentes: namespaces, cgroups, union filesystems
- Describir la arquitectura cliente-servidor de Docker (Docker CLI, Docker Engine, containerd)
- Reconocer por que los contenedores son la base de arquitecturas de microservicios

### Tecnicos
- Instalar Docker Engine en Linux, Windows y macOS
- Ejecutar contenedores desde imagenes publicas de Docker Hub
- Crear Dockerfiles para empaquetar aplicaciones personalizadas
- Construir imagenes Docker optimizadas con multi-stage builds
- Gestionar volumenes para persistencia de datos
- Configurar redes Docker para comunicacion entre contenedores
- Usar Docker Compose para orquestar aplicaciones multi-contenedor

### Troubleshooting
- Diagnosticar contenedores que no arrancan (errores de build, runtime)
- Resolver problemas de networking entre contenedores
- Inspeccionar logs de contenedores para debugging
- Identificar y solucionar problemas de permisos y volumenes
- Optimizar imagenes para reducir tamano y mejorar performance
- Troubleshoot consumo excesivo de recursos (CPU, memoria, disco)

### Profesionales
- Justificar cuando usar contenedores vs. VMs vs. serverless
- Implementar mejores practicas de seguridad en imagenes Docker
- Disenar estrategias de CI/CD con contenedores
- Prepararse conceptual y tecnicamente para Kubernetes
- Comprender el ecosistema de contenedores: Docker, Podman, containerd, CRI-O

---

## Capitulo 3: Introduccion a Kubernetes

**Modulo**: `area-2-arquitectura-kubernetes/modulo-01-introduccion-kubernetes/`

### Conceptuales
- Definir Kubernetes: Explicar que es, su origen y por que existe
- Entender la evolucion: Progresion desde servidores tradicionales a VMs a contenedores a orquestacion
- Identificar problemas resueltos: Comprender que problemas especificos soluciona K8s
- Reconocer el ecosistema: CNCF, Cloud Native, contenedores como fundamento

### Contextuales
- Casos de uso empresariales: Identificar cuando usar K8s (y cuando no)
- Beneficios de negocio: Escalabilidad, alta disponibilidad, portabilidad
- Comparacion con alternativas: Docker Swarm, Nomad, ECS, AKS vs self-managed
- Preparacion mental: Contexto necesario antes de aprender arquitectura tecnica

### Analisis
- Evaluar aplicabilidad: Determinar si K8s es apropiado para un proyecto
- Identificar complejidad: Entender que K8s requiere inversion en aprendizaje
- Reconocer trade-offs: Poder vs complejidad, flexibilidad vs curva de aprendizaje

---

## Capitulo 4: Arquitectura de Cluster Kubernetes

**Modulo**: `area-2-arquitectura-kubernetes/modulo-02-arquitectura-cluster/`

### Conceptuales
- Arquitectura de alto nivel: Visualizar y explicar la estructura completa de un cluster K8s
- Control Plane vs Workers: Distinguir claramente los roles y responsabilidades
- Flujo de requests: Entender el ciclo de vida de una peticion en K8s
- Componentes esenciales: Conocer cada pieza del sistema y su funcion

### Tecnicos
- Identificar componentes del Control Plane: API Server, etcd, Scheduler, Controllers
- Conocer componentes de Worker Nodes: kubelet, kube-proxy, container runtime
- Entender comunicacion: Como interactuan todos los componentes entre si
- Diagnosticar problemas basicos: Usar kubectl para verificar estado de componentes
- Arquitectura HA: Comprender multi-master y tolerancia a fallos

### Troubleshooting
- Verificar salud del cluster: kubectl get nodes, componentstatuses
- Diagnosticar problemas de Control Plane: Logs de API server, scheduler
- Identificar problemas de Workers: Estado de kubelet, pods en nodos
- Entender puntos de fallo: Que sucede si falla cada componente

### Profesionales
- Disenar clusters: Decidir arquitectura segun requisitos (HA, escala)
- Planear infraestructura: Dimensionamiento de Control Plane y Workers
- Preparacion para certificaciones: CKA (componentes), CKAD (contexto)
- Conversaciones tecnicas: Hablar con confianza sobre arquitectura K8s

---

## Capitulo 5: Instalacion y Configuracion de Minikube

**Modulo**: `area-2-arquitectura-kubernetes/modulo-03-instalacion-minikube/`

### Conceptuales
- Entender Minikube: Que es, para que sirve, y cuando usarlo vs clusters reales
- Arquitectura local: Como Minikube simula un cluster completo en tu maquina
- Drivers de Minikube: Docker vs VirtualBox vs otros (ventajas/desventajas)
- Diferencia kubectl vs Minikube: Cliente vs cluster local

### Tecnicos
- Instalar Docker: Configurar container runtime localmente
- Instalar kubectl: Herramienta CLI para interactuar con K8s
- Instalar Minikube: Crear cluster local Kubernetes
- Configurar autocompletado: Bash/Zsh para kubectl (productividad)
- Verificar salud del cluster: kubectl get nodes, componentstatuses
- Desplegar primera app: nginx en Minikube con kubectl

### Troubleshooting
- Diagnosticar problemas de instalacion: Docker, permisos, virtualization
- Resolver errores de Minikube: Start fallido, networking, addons
- Verificar recursos: CPU, RAM, espacio en disco
- Reiniciar Minikube: Stop, delete, start limpio

### Profesionales
- Entorno de desarrollo: Configurar workspace local para K8s
- Reproducibilidad: Crear clusters identicos en cualquier maquina
- Testing local: Probar manifiestos antes de produccion
- Aprendizaje seguro: Experimentar sin riesgo en tu laptop

---

## Capitulo 6: Pods vs Contenedores - Fundamentos

**Modulo**: `area-2-arquitectura-kubernetes/modulo-04-pods-vs-contenedores/`

### Conceptuales
- Entender la evolucion: LXC a Docker a Kubernetes Pods (historia de containers)
- Definir que es un Pod: La unidad atomica de K8s (no es un contenedor)
- Comprender el contenedor pause: Infraestructura invisible que sostiene el Pod
- Namespaces Linux: Los 7 tipos y cuales se comparten en un Pod
- Pod = grupo logico: Por que multiples contenedores en un Pod

### Tecnicos
- Crear Pods con kubectl: run, apply con YAML
- Inspeccionar Pods: describe, logs, exec para debugging
- Disenar multi-contenedor: Sidecar, adapter, ambassador patterns
- Comprender networking: Localhost entre contenedores del mismo Pod
- Entender almacenamiento: Volumenes compartidos entre contenedores

### Troubleshooting
- Diagnosticar Pods fallidos: CrashLoopBackOff, ImagePullBackOff, Error
- Analizar logs: kubectl logs -c <contenedor> para multi-contenedor
- Debugging interactivo: kubectl exec para inspeccionar contenedor
- Entender estados: Pending, Running, Failed, Succeeded, Unknown

### Profesionales
- Disenar Pods efectivos: Cuando usar 1 vs multiples contenedores
- Patrones de arquitectura: Sidecar (logging), Adapter (metricas), Ambassador (proxy)
- Mejores practicas: Pods inmutables, un proceso por contenedor
- Preparacion CKA/CKAD: Pods son 20-30% del examen

---

## Capitulo 7: Gestion Avanzada de Pods

**Modulo**: `area-2-arquitectura-kubernetes/modulo-05-gestion-pods/`

### Conceptuales
- Ciclo de vida completo: Entender cada fase del Pod (Pending, Running, Succeeded, Failed)
- Resource management: Por que son criticos requests y limits
- Restart policies: Always, OnFailure, Never y cuando usar cada una
- Security contexts: Privilegios, capabilities, user/group IDs
- QoS classes: Guaranteed, Burstable, BestEffort

### Tecnicos
- Manifiestos YAML production-ready: Configuracion completa de Pods
- Resource requests/limits: CPU, memoria, ephemeral storage
- Security contexts: runAsUser, fsGroup, capabilities
- Init containers: Preparacion antes de contenedor principal
- Lifecycle hooks: postStart, preStop para gestion avanzada
- Pod priority: PriorityClass para scheduling critico

### Troubleshooting
- Diagnosticar OOMKilled: Pods matados por falta de memoria
- Resolver CrashLoopBackOff: Analisis de logs y eventos
- Debugging con ephemeral containers: Contenedores temporales de debug
- Entender eviction: Cuando y por que K8s expulsa Pods
- Analizar resource usage: kubectl top, metricas reales

### Profesionales
- Production-ready Pods: Configuracion enterprise con limites y health checks
- Cost optimization: Dimensionar recursos correctamente
- Security hardening: Aplicar principio de minimo privilegio
- Preparacion CKA/CKAD: 30-40% del examen sobre gestion de Pods

---

## Capitulo 8: ReplicaSets y Gestion de Replicas

**Modulo**: `area-2-arquitectura-kubernetes/modulo-06-replicasets-replicas/`

### Conceptuales
- Entender ReplicaSets: Controlador que mantiene N replicas del mismo Pod
- Reconciliation loop: Como K8s converge estado deseado vs real
- Selectors y labels: Matching de Pods con ReplicaSets
- Owner references: Relacion ReplicaSet a Pods
- Diferencias arquitectonicas: ReplicaSet vs ReplicationController (legacy)

### Tecnicos
- Crear ReplicaSets: Manifiestos YAML completos
- Escalar replicas: kubectl scale, patch YAML
- Label selectors: matchLabels y matchExpressions
- Gestionar failures: Auto-recuperacion ante crashes
- Orphan Pods: Eliminar sin cascada (--cascade=orphan)

### Troubleshooting
- Diagnosticar replicas faltantes: Por que no se crean Pods
- Resolver conflictos de labels: Pods no adoptados
- Analizar eventos: ReplicaSet controller logs
- Debugging de scheduling: Pods Pending por recursos
- Verificar ownership: kubectl get pod -o yaml (ownerReferences)

### Profesionales
- Alta disponibilidad: Multiples replicas distribuidas
- Self-healing: Recuperacion automatica de fallos
- Horizontal scaling: Aumentar/reducir capacidad
- Preparacion CKA/CKAD: ReplicaSets son base para Deployments (20% examen)
- Production patterns: Nunca usar ReplicaSets directamente (usar Deployments)

---

## Capitulo 9: Deployments y Rolling Updates

**Modulo**: `area-2-arquitectura-kubernetes/modulo-07-deployments-rollouts/`

### Conceptuales
- Entender Deployments: Capa de abstraccion sobre ReplicaSets
- Arquitectura jerarquica: Deployment a ReplicaSet a Pods
- Rolling updates: Actualizar versiones sin downtime
- Rollback automatico: Volver a version anterior en segundos
- Estrategias de despliegue: RollingUpdate, Recreate, Blue/Green, Canary
- Reconciliation loop: Como Deployment gestiona ReplicaSets

### Tecnicos
- Crear Deployments: Manifiestos YAML production-ready
- Rolling updates: kubectl set image, apply con nueva version
- Controlar velocidad: maxSurge, maxUnavailable
- Pausar/resumir: Pause/resume rollouts
- Rollback: kubectl rollout undo
- Historial de revisiones: rollout history, revision
- Health checks: readinessProbe durante updates

### Troubleshooting
- Diagnosticar rollout fallido: ImagePullBackOff durante update
- Rollout stuck: Por que no progresa el despliegue
- Revisar historial: Que cambio entre revisiones
- Analizar eventos: Deployment controller logs
- Verificar progreso: kubectl rollout status

### Profesionales
- Zero-downtime deployments: Actualizaciones sin interrupcion
- Produccion estandar: Deployments son el estandar (no ReplicaSets)
- CI/CD integration: Automatizar despliegues
- Rollback strategy: Plan B siempre listo
- Preparacion CKA/CKAD: 25-30% del examen

---

## Capitulo 10: Services y Endpoints

**Modulo**: `area-2-arquitectura-kubernetes/modulo-08-services-endpoints/`

### Conceptos Fundamentales
- Comprender el concepto de Service como abstraccion de red en Kubernetes
- Entender el problema de los Pods efimeros y como los Services lo resuelven
- Dominar el rol de Endpoints y EndpointSlices en el descubrimiento de servicios
- Explicar el funcionamiento de kube-proxy y sus modos (iptables, IPVS)

### Habilidades Tecnicas
- Diferenciar y configurar los 4 tipos de Services: ClusterIP, NodePort, LoadBalancer, ExternalName
- Implementar balanceo de carga entre Pods con distintas politicas
- Gestionar descubrimiento de servicios mediante DNS y variables de entorno
- Configurar Services headless para aplicaciones stateful (StatefulSets)
- Usar session affinity y externalTrafficPolicy apropiadamente

### Aplicacion Practica
- Disenar comunicacion entre microservicios con ClusterIP
- Exponer aplicaciones externamente con NodePort y LoadBalancer
- Diagnosticar y resolver problemas comunes de networking
- Aplicar best practices de Services en produccion
- Implementar estrategias de acceso seguro y eficiente

### Nivel Profesional
- Evaluar cuando usar cada tipo de Service segun el caso de uso
- Optimizar performance con configuraciones avanzadas (IPVS, Local traffic policy)
- Integrar Services con herramientas de monitoreo (Prometheus)
- Documentar arquitecturas de networking para equipos

---

## Capitulo 11: Ingress y Acceso Externo

**Modulo**: `area-2-arquitectura-kubernetes/modulo-09-ingress-external-access/`

### Fundamentos
- Explicar la diferencia entre Services (NodePort/LoadBalancer) e Ingress
- Comprender la arquitectura de 3 componentes: Ingress Resource, Ingress Controller e IngressClass
- Entender por que Ingress reduce costos en cloud (1 LoadBalancer vs N LoadBalancers)
- Diferenciar entre path-based routing y host-based routing

### Tecnicos
- Instalar y configurar nginx ingress controller en minikube
- Crear recursos Ingress con reglas de enrutamiento por path y hostname
- Configurar terminacion TLS/HTTPS con Secrets de Kubernetes
- Usar anotaciones para funcionalidades avanzadas (rewrite, rate limiting, sticky sessions)
- Diagnosticar y resolver problemas comunes de Ingress

### Avanzados
- Implementar canary deployments con weights (division de trafico)
- Configurar multiples Ingress Controllers en el mismo cluster
- Disenar arquitecturas de produccion con alta disponibilidad
- Integrar con cert-manager para certificados automaticos
- Optimizar performance y seguridad con best practices

### Profesionales
- Aplicar patrones de produccion para multi-tenancy
- Implementar estrategias de blue-green deployments
- Configurar monitoreo y alertas de Ingress
- Evaluar y seleccionar Ingress Controllers segun casos de uso
- Migrar de Ingress a Gateway API

---

## Capitulo 12: Namespaces y Organizacion

**Modulo**: `area-2-arquitectura-kubernetes/modulo-10-namespaces-organizacion/`

### Fundamentos
- Explicar que son los Namespaces y por que son necesarios
- Comprender la diferencia entre aislamiento logico vs fisico
- Identificar los namespaces del sistema y su proposito
- Entender cuando usar namespaces (casos de uso)

### Tecnicos
- Crear, listar y eliminar namespaces con kubectl
- Configurar contextos en kubeconfig para cambiar entre namespaces
- Trabajar con recursos en namespaces especificos
- Comprender DNS scoping en namespaces
- Diferenciar recursos namespaced vs cluster-scoped

### Avanzados
- Implementar ResourceQuotas para limitar recursos por namespace
- Configurar LimitRanges para defaults de contenedores
- Aplicar NetworkPolicies para aislamiento de red
- Integrar RBAC con namespaces para control de acceso
- Disenar arquitecturas multi-tenant

### Profesionales
- Aplicar patrones de organizacion (por entorno, equipo, proyecto)
- Implementar best practices de naming conventions
- Configurar monitoreo por namespace
- Gestionar costos con chargebacks/showbacks
- Disenar estrategias de gobernanza

---

## Capitulo 13: Resource Limits en Pods

**Modulo**: `area-2-arquitectura-kubernetes/modulo-11-resource-limits-pods/`

### Fundamentos
- Comprender la diferencia entre requests y limits
- Explicar como el scheduler usa requests para placement de Pods
- Identificar los tres tipos de recursos: CPU, memoria y storage
- Entender las unidades de medicion (milicores, bytes, etc.)

### Tecnicos
- Configurar requests y limits en contenedores
- Aplicar QoS classes (Guaranteed, Burstable, BestEffort)
- Gestionar ephemeral storage en Pods
- Monitorear el uso de recursos con `kubectl top`
- Diagnosticar problemas OOMKilled y CPU throttling

### Avanzados
- Implementar Pod-level resources (K8s 1.34+)
- Configurar extended resources (GPUs, FPGAs)
- Optimizar configuraciones para produccion
- Aplicar strategies de right-sizing
- Integrar con Vertical Pod Autoscaler (VPA)

### Profesionales
- Disenar politicas de recursos para equipos/proyectos
- Balancear performance vs costo en el cluster
- Implementar monitoreo avanzado (Prometheus, Grafana)
- Aplicar best practices de resource management a escala
- Troubleshoot problemas complejos de recursos

---

## Capitulo 14: Health Checks y Probes

**Modulo**: `area-2-arquitectura-kubernetes/modulo-12-health-checks-probes/`

### Fundamentos
- Comprender que son las probes y por que son criticas
- Diferenciar entre Startup, Liveness y Readiness probes
- Explicar el ciclo de vida de un Pod y cuando se ejecutan las probes
- Identificar cuando usar cada tipo de probe

### Tecnicos
- Configurar HTTP, TCP y Exec probes
- Ajustar parametros (initialDelaySeconds, periodSeconds, timeoutSeconds)
- Combinar multiples probes efectivamente
- Usar named ports en probes
- Diagnosticar fallos de probes con `kubectl describe`

### Avanzados
- Disenar endpoints de health check en aplicaciones
- Optimizar tiempos de startup para aplicaciones lentas
- Implementar graceful shutdown
- Configurar probes para bases de datos y caches
- Aplicar patterns de circuit breaker con probes

### Profesionales
- Establecer politicas de probes por tipo de aplicacion
- Balancear disponibilidad vs sensibilidad en produccion
- Integrar probes con monitoreo (Prometheus, Grafana)
- Implementar health checks para arquitecturas multi-tier
- Troubleshoot problemas complejos de availability

---

## Capitulo 15: ConfigMaps y Variables de Entorno

**Modulo**: `area-2-arquitectura-kubernetes/modulo-13-configmaps-variables/`

### Fundamentos
- Comprender el principio de separacion configuracion/codigo (12-Factor App)
- Diferenciar entre variables de entorno, field references y ConfigMaps
- Explicar cuando usar ConfigMaps vs Secrets
- Entender el ciclo de vida y actualizacion de ConfigMaps

### Tecnicos
- Definir variables de entorno estaticas en Pods
- Usar field references para acceder a metadata del Pod
- Crear ConfigMaps desde literales, archivos y directorios
- Consumir ConfigMaps como variables de entorno
- Montar ConfigMaps como volumenes
- Gestionar actualizaciones de configuracion

### Avanzados
- Implementar ConfigMaps inmutables para performance
- Combinar multiples fuentes de configuracion
- Aplicar patterns de hot-reload de configuracion
- Disenar estrategias de versionado de ConfigMaps
- Integrar con Helm para gestion de configuracion

### Profesionales
- Establecer politicas de configuracion por entorno
- Implementar configuracion jerarquica (base + overrides)
- Aplicar GitOps para gestion de ConfigMaps
- Troubleshoot problemas comunes de configuracion
- Optimizar performance con ConfigMaps inmutables

---

## Capitulo 16: Secrets - Datos Sensibles

**Modulo**: `area-2-arquitectura-kubernetes/modulo-14-secrets-data-sensible/`

### Fundamentos
- Comprender que son los Secrets y cuando usarlos
- Diferenciar Secrets de ConfigMaps (uso, seguridad, codificacion)
- Conocer los tipos de Secrets (Opaque, TLS, docker-registry, service-account-token)
- Entender las limitaciones de seguridad de base64

### Tecnicos
- Crear Secrets usando kubectl (literales, archivos, YAML)
- Consumir Secrets como variables de entorno
- Montar Secrets como volumenes en Pods
- Gestionar Secrets TLS para Ingress/HTTPS
- Configurar imagePullSecrets para registros privados
- Aplicar Secrets inmutables

### Avanzados
- Implementar buenas practicas de seguridad (RBAC, encryption at rest)
- Integrar herramientas externas (Sealed Secrets, Vault, External Secrets)
- Disenar estrategias de rotacion de credenciales
- Troubleshoot problemas de permisos y montaje de Secrets
- Auditar acceso a Secrets

### Profesionales
- Evaluar cuando usar Secrets vs soluciones externas
- Prepararse para escenarios CKA/CKAD sobre Secrets
- Disenar arquitecturas seguras de gestion de secretos
- Aplicar principio de least privilege con RBAC

---

## Capitulo 17: Volumenes - Conceptos Fundamentales

**Modulo**: `area-2-arquitectura-kubernetes/modulo-15-volumes-conceptos/`

### Fundamentos
- Comprender que son los volumenes y por que son necesarios
- Diferenciar aplicaciones stateless vs stateful
- Entender el ciclo de vida de los volumenes
- Conocer el problema de los sistemas de archivos efimeros
- Comprender la abstraccion de almacenamiento en Kubernetes

### Tecnicos (Conceptuales)
- Identificar tipos basicos de volumenes (emptyDir, hostPath, cloud volumes)
- Comprender la abstraccion PV/PVC (PersistentVolume y PersistentVolumeClaim)
- Conocer los modos de acceso (ReadWriteOnce, ReadOnlyMany, ReadWriteMany)
- Entender las politicas de recuperacion (Retain, Delete, Recycle)
- Familiarizarse con StorageClasses

### Diseno
- Decidir cuando usar cada tipo de volumen
- Elegir modos de acceso apropiados segun el caso de uso
- Seleccionar politicas de recuperacion segun requisitos
- Disenar arquitecturas de almacenamiento para aplicaciones stateful

### Profesionales
- Prepararse para escenarios CKA/CKAD sobre volumenes
- Evaluar trade-offs entre tipos de almacenamiento
- Comprender conceptos antes de implementacion practica (Modulo 16)

---

## Capitulo 18: Volumenes - Implementacion Practica

**Modulo**: `area-2-arquitectura-kubernetes/modulo-16-volumes-tipos-storage/`

### Implementacion Practica
- Crear volumenes emptyDir y hostPath con YAMLs completos
- Provisionar PersistentVolumes y PersistentVolumeClaims en Azure AKS
- Implementar provisioning dinamico con StorageClasses
- Configurar Azure Disk para aplicaciones stateful
- Usar Azure Files para compartir archivos entre Pods
- Aplicar access modes apropiados segun caso de uso

### Tecnicos
- Ejecutar comandos kubectl para gestionar volumenes
- Depurar problemas de binding PV/PVC
- Configurar reclaim policies en entornos de produccion
- Crear StorageClasses personalizadas
- Implementar volumenes en StatefulSets
- Gestionar expansion de volumenes

### Troubleshooting
- Diagnosticar PVC en estado Pending
- Resolver problemas de montaje de volumenes
- Solucionar errores de permisos en volumenes
- Identificar conflictos de access modes
- Depurar problemas de provisioning dinamico

### Profesionales
- Aplicar best practices de almacenamiento en produccion
- Implementar arquitecturas de datos resilientes
- Prepararse para tareas practicas CKA/CKAD
- Evaluar trade-offs Azure Disk vs Azure Files en escenarios reales

---

## Capitulo 19: RBAC - Usuarios y Grupos

**Modulo**: `area-2-arquitectura-kubernetes/modulo-17-rbac-users-groups/`

### Conceptuales
- Comprender RBAC: Entender el modelo Role-Based Access Control y su importancia en seguridad
- Diferenciar identidades: Distinguir claramente entre usuarios humanos y Service Accounts
- Arquitectura de permisos: Dominar la relacion entre Roles, RoleBindings y Subjects
- Principio de minimo privilegio: Aplicar mejores practicas de seguridad en control de acceso

### Tecnicos
- Crear usuarios con certificados X.509: Generar CSR, firmar certificados con CA del cluster
- Configurar kubectl: Gestionar contextos, users y clusters en kubeconfig
- Definir Roles y ClusterRoles: Especificar permisos granulares sobre recursos
- Asignar permisos con RoleBindings: Conectar roles con usuarios y grupos
- Organizar usuarios en grupos: Implementar gestion escalable de permisos

### Troubleshooting
- Diagnosticar problemas de permisos: Usar `kubectl auth can-i` y logs de API server
- Auditar accesos: Verificar que usuarios tienen que permisos
- Resolver errores comunes: "Forbidden", certificados invalidos, contextos incorrectos

### Profesionales
- Implementar seguridad corporativa: Aplicar RBAC en entornos enterprise
- Documentar politicas de acceso: Crear matrices de permisos por rol
- Preparacion para certificaciones: CKA, CKAD, CKS (seccion de seguridad)

---

## Capitulo 20: RBAC - Service Accounts

**Modulo**: `area-2-arquitectura-kubernetes/modulo-18-rbac-serviceaccounts/`

### Conceptuales
- Entender Service Accounts: Comprender que son, para que sirven y cuando usarlos
- Diferenciar identidades: Distinguir Service Accounts de usuarios humanos
- Tokens JWT: Entender como funcionan los tokens automaticos en Kubernetes
- Arquitectura de seguridad: Dominar el modelo de permisos para aplicaciones internas

### Tecnicos
- Crear Service Accounts: Usar kubectl y manifiestos YAML
- Asignar a pods: Configurar `serviceAccountName` en specs
- Configurar permisos RBAC: Roles y RoleBindings para Service Accounts
- Gestionar tokens: Entender montaje automatico y projected volumes
- Acceder a API desde pods: Implementar aplicaciones que usan Kubernetes API

### Troubleshooting
- Diagnosticar problemas de autenticacion: Tokens invalidos o expirados
- Resolver errores de permisos: "Forbidden" desde pods
- Verificar montaje de tokens: Validar `/var/run/secrets/kubernetes.io/serviceaccount`
- Auditar accesos de aplicaciones: Que pods tienen que permisos

### Profesionales
- Implementar seguridad de aplicaciones: Minimo privilegio para pods
- Disenar arquitecturas seguras: Service Accounts por funcion/componente
- Automatizar CI/CD: Usar Service Accounts en pipelines
- Preparacion para certificaciones: CKA, CKAD, CKS (seguridad de aplicaciones)

---

## Capitulo 21: Jobs y CronJobs

**Modulo**: `area-2-arquitectura-kubernetes/modulo-19-jobs-cronjobs/`

### Conceptuales
- Comprender la diferencia entre workloads continuos (Deployments) y tareas finitas (Jobs)
- Explicar cuando usar Jobs vs Deployments vs CronJobs
- Entender el ciclo de vida de un Job y sus estados
- Conocer patrones de diseno para procesamiento batch en Kubernetes

### Tecnicos
- Crear y ejecutar Jobs simples y paralelos
- Configurar CronJobs con sintaxis de scheduling
- Gestionar Jobs completados, fallidos y en ejecucion
- Implementar backoffLimit y activeDeadlineSeconds
- Limpiar Jobs automaticamente (TTL)

### Troubleshooting
- Diagnosticar Jobs que no completan
- Resolver CronJobs que no se ejecutan segun schedule
- Debugging de Jobs fallidos con multiples reintentos
- Identificar problemas de concurrencia en CronJobs

### Profesionales
- Disenar pipelines de procesamiento batch escalables
- Implementar data migrations con Jobs
- Programar tareas de mantenimiento con CronJobs
- Aplicar patrones para certificacion CKAD (20% del examen)

---

## Capitulo 22: Init Containers y Sidecar Patterns

**Modulo**: `area-2-arquitectura-kubernetes/modulo-20-init-sidecar-patterns/`

### Conceptuales
- Init Containers: Que son, cuando usarlos y como se diferencian de containers principales
- Sidecar Pattern: Concepto de contenedores auxiliares que extienden funcionalidad
- Multi-Container Pods: Por que multiples containers comparten un Pod
- Patrones de Comunicacion: Como containers en el mismo Pod se comunican
- Shared Resources: Volumenes compartidos, networking localhost, y namespace de proceso

### Tecnicos
- Configurar Init Containers para tareas de setup y validacion
- Implementar Sidecar Pattern para logging, monitoring y proxies
- Crear Multi-Container Pods con comunicacion efectiva
- Usar Shared Volumes entre containers del mismo Pod
- Aplicar patrones Ambassador y Adapter
- Gestionar lifecycle de containers multiples
- Troubleshooting de Pods con multiples containers

### Troubleshooting
- Diagnosticar Init Containers que fallan y bloquean el Pod
- Identificar problemas de comunicacion entre containers
- Resolver conflictos de recursos compartidos
- Analizar logs de containers especificos en Pods multi-container
- Debugging de volumenes compartidos

### Profesionales
- Disenar arquitecturas de Pods escalables y mantenibles
- Aplicar separation of concerns con sidecars
- Implementar patrones de la industria (service mesh, logging agents)
- Preparacion para CKAD (Multi-Container Pods = 10% del examen)
- Best practices para microservicios en Kubernetes

---

## Capitulo 23: Helm - Package Manager

**Modulo**: `area-2-arquitectura-kubernetes/modulo-21-helm-basics/`

### Conceptuales
- Comprender la arquitectura de Helm y su proposito
- Entender la estructura de un Helm Chart
- Conocer el ciclo de vida de releases
- Diferenciar entre Chart, Release y Repository

### Tecnicos
- Instalar y configurar Helm 3
- Crear charts desde cero
- Personalizar deployments con `values.yaml`
- Usar templates y funciones de Helm
- Gestionar releases (install, upgrade, rollback)
- Trabajar con repositorios publicos y privados
- Implementar hooks de ciclo de vida

### Troubleshooting
- Depurar templates con `helm template` y `--dry-run`
- Resolver conflictos de valores
- Diagnosticar fallos en releases
- Recuperar releases fallidos

### Profesionales
- Seguir mejores practicas de Helm
- Disenar charts reutilizables
- Gestionar multiples entornos (dev, staging, prod)
- Prepararse para preguntas CKAD sobre Helm

---

## Capitulo 24: Cluster Setup con kubeadm

**Modulo**: `area-2-arquitectura-kubernetes/modulo-22-cluster-setup-kubeadm/`

### Objetivos
- Instalar un cluster Kubernetes desde cero con kubeadm
- Configurar control plane y worker nodes
- Implementar clusters High Availability (HA)
- Gestionar etcd y realizar backup/restore
- Configurar networking con CNI plugins
- Troubleshootear problemas comunes de instalacion
- Escalar clusters agregando/removiendo nodos
- Actualizar versiones de Kubernetes

---

## Capitulo 25: Cluster Maintenance y Upgrades

**Modulo**: `area-2-arquitectura-kubernetes/modulo-23-maintenance-upgrades/`

### Objetivos
- Planificar y ejecutar upgrades de cluster seguros
- Entender y aplicar version skew policy
- Realizar upgrades de control plane con kubeadm
- Actualizar worker nodes sin downtime
- Usar `drain`, `cordon`, y `uncordon` efectivamente
- Gestionar certificados de Kubernetes
- Implementar estrategias de backup pre-upgrade
- Realizar rollback en caso de problemas

---

## Capitulo 26: Advanced Scheduling

**Modulo**: `area-2-arquitectura-kubernetes/modulo-24-advanced-scheduling/`

### Objetivos
- Controlar el scheduling de pods manualmente
- Crear y gestionar static pods
- Aplicar taints y tolerations para control de nodos
- Usar node affinity para scheduling avanzado
- Implementar pod affinity y anti-affinity
- Configurar resource quotas y limits
- Trabajar con priority classes
- Entender scheduler profiles personalizados

---

## Capitulo 27: Networking Deep Dive

**Modulo**: `area-2-arquitectura-kubernetes/modulo-25-networking/`

### Objetivos
- Comprender el modelo de networking de Kubernetes
- Configurar y troubleshoot CNI plugins
- Implementar y gestionar Services (ClusterIP, NodePort, LoadBalancer)
- Configurar DNS en Kubernetes (CoreDNS)
- Implementar Network Policies para seguridad
- Configurar Ingress controllers y rules
- Diagnosticar y resolver problemas de red
- Optimizar comunicacion entre pods y servicios

---

## Capitulo 28: Troubleshooting Avanzado

**Modulo**: `area-2-arquitectura-kubernetes/modulo-26-troubleshooting/`

### Objetivos
- Diagnosticar y resolver problemas de aplicaciones (pods, containers, crashes)
- Identificar y solucionar problemas del control plane (API server, etcd, scheduler)
- Resolver problemas de worker nodes (kubelet, kube-proxy, CNI)
- Diagnosticar problemas de red (DNS, services, network policies, ingress)
- Solucionar problemas de almacenamiento (PV/PVC, mounts, permissions)
- Analizar problemas de rendimiento (resources, QoS, eviction)
- Resolver problemas de RBAC y seguridad (permissions, service accounts)
- Usar herramientas de diagnostico profesionales (kubectl, logs, events, debug pods)
