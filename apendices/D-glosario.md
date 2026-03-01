# Apendice D: Glosario

> Version completa: [Glosario](../recursos/glossario.md)

Este glosario incluye todos los terminos del glosario principal del curso, mas terminos adicionales que aparecen en los modulos.

---

## A

**AKS (Azure Kubernetes Service)**
Servicio gestionado de Kubernetes en Microsoft Azure que simplifica el despliegue, gestion y operaciones de clusteres Kubernetes.

**Ambassador Pattern**
Patron de diseno multi-contenedor donde un contenedor auxiliar actua como proxy entre la aplicacion principal y servicios externos. Cubierto en Cap 6 y Cap 22.

**API Server (kube-apiserver)**
Componente central del plano de control de Kubernetes que expone la API de Kubernetes y actua como frontend para el estado del cluster.

**Azure Container Registry (ACR)**
Registro privado de contenedores Docker en Azure que permite almacenar y gestionar imagenes de contenedores.

**Adapter Pattern**
Patron de diseno multi-contenedor donde un contenedor auxiliar transforma la salida del contenedor principal a un formato estandar (por ejemplo, metricas Prometheus). Cubierto en Cap 6 y Cap 22.

**Autoscaling**
Capacidad de ajustar automaticamente el numero de recursos (pods, nodos) basandose en metricas como CPU, memoria o metricas personalizadas.

## B

**backoffLimit**
Parametro de un Job que define el numero maximo de reintentos antes de considerar el Job como fallido. Cubierto en Cap 21.

**Blue-Green Deployment**
Estrategia de despliegue que reduce el tiempo de inactividad ejecutando dos entornos de produccion identicos llamados Blue y Green. Cubierto en Cap 9.

**BestEffort (QoS)**
Clase de calidad de servicio mas baja en Kubernetes, asignada a Pods sin requests ni limits. Primer candidato para eviction. Cubierto en Cap 7 y Cap 13.

**Burstable (QoS)**
Clase de calidad de servicio intermedia en Kubernetes, asignada cuando requests y limits estan configurados pero no son iguales. Cubierto en Cap 7 y Cap 13.

## C

**Canary Deployment**
Tecnica para reducir el riesgo de introducir nueva version de software en produccion desplegandola gradualmente a un subconjunto de usuarios. Cubierto en Cap 9.

**cgroups (Control Groups)**
Funcionalidad del kernel Linux que limita, contabiliza y aisla el uso de recursos (CPU, memoria, I/O) de procesos. Fundamental para contenedores. Cubierto en Cap 2.

**CNI (Container Network Interface)**
Especificacion y bibliotecas para escribir plugins de red para configurar interfaces de red en contenedores Linux.

**ConfigMap**
Objeto de Kubernetes que permite desacoplar la configuracion especifica del entorno del codigo de la aplicacion. Cubierto en Cap 15.

**Container**
Unidad ejecutable de software que empaqueta codigo y todas sus dependencias para que la aplicacion se ejecute de manera consistente.

**Container Runtime**
Software responsable de ejecutar contenedores. Ejemplos: Docker, containerd, CRI-O.

**containerd**
Runtime de contenedores de nivel industrial, usado por defecto en Kubernetes moderno. Es mas ligero que Docker Engine. Cubierto en Cap 2 y Cap 4.

**Control Plane**
Conjunto de componentes que toman decisiones globales sobre el cluster y detectan y responden a eventos del cluster. Incluye API Server, etcd, Scheduler, Controller Manager. Cubierto en Cap 4.

**ClusterIP**
Tipo de Service por defecto que expone el servicio en una IP interna del cluster, accesible solo dentro del cluster. Cubierto en Cap 10.

**ClusterRole**
Recurso RBAC que define permisos a nivel de cluster (no limitado a un namespace). Cubierto en Cap 19.

**CRI (Container Runtime Interface)**
Interfaz estandar que permite a kubelet comunicarse con diferentes runtimes de contenedores.

**CronJob**
Objeto de Kubernetes que ejecuta Jobs en un horario programado usando sintaxis cron. Cubierto en Cap 21.

**CSI (Container Storage Interface)**
Estandar para exponer sistemas de almacenamiento arbitrarios a cargas de trabajo contenerizadas.

## D

**DaemonSet**
Objeto de Kubernetes que asegura que todos (o algunos) nodos ejecuten una copia de un Pod. Cubierto en Cap 26.

**Deployment**
Objeto de Kubernetes que proporciona actualizaciones declarativas para Pods y ReplicaSets. Metodo estandar para gestionar aplicaciones. Cubierto en Cap 9.

**Docker**
Plataforma para desarrollar, enviar y ejecutar aplicaciones usando tecnologia de contenedores. Cubierto en Cap 2.

**Docker Compose**
Herramienta para definir y ejecutar aplicaciones multi-contenedor usando archivos YAML. Cubierto en Cap 2.

**Dockerfile**
Archivo de texto que contiene instrucciones para construir una imagen Docker. Cubierto en Cap 2.

**drain**
Comando kubectl que evacua todos los Pods de un nodo, preparandolo para mantenimiento. Cubierto en Cap 25.

## E

**emptyDir**
Tipo de volumen que se crea cuando un Pod es asignado a un nodo y existe mientras el Pod exista en ese nodo. Cubierto en Cap 17.

**Endpoint**
Direccion IP:Puerto de un Pod que cumple con el selector de un Service. Es el puente entre Service y Pods. Cubierto en Cap 10.

**EndpointSlice**
Evolucion de Endpoints que escala mejor para clusters grandes. Cubierto en Cap 10.

**etcd**
Base de datos clave-valor distribuida que Kubernetes usa como almacen de respaldo para todos los datos del cluster. Cubierto en Cap 4 y Cap 24-25.

**Egress**
Trafico de red saliente desde un Pod o nodo.

**Eviction**
Proceso por el cual Kubernetes expulsa Pods de un nodo cuando hay presion de recursos. Cubierto en Cap 7.

## F

**Field References**
Mecanismo para inyectar metadata del Pod (nombre, namespace, IP, nodo) como variables de entorno. Cubierto en Cap 15.

**Fluentd**
Recolector de datos unificado de codigo abierto para procesamiento de logs unificado.

## G

**GitOps**
Practica de usar Git como fuente unica de verdad para la infraestructura declarativa y aplicaciones.

**Grafana**
Plataforma de analisis y monitoreo de codigo abierto para metricas de tiempo real.

**Guaranteed (QoS)**
Clase de calidad de servicio mas alta en Kubernetes, asignada cuando requests y limits son iguales. Ultimo candidato para eviction. Cubierto en Cap 7 y Cap 13.

## H

**Health Check**
Verificacion automatica para determinar si una aplicacion esta funcionando correctamente. Implementada via Probes en K8s. Cubierto en Cap 14.

**Helm**
Gestor de paquetes para Kubernetes que ayuda a gestionar aplicaciones de Kubernetes mediante Charts. Cubierto en Cap 23.

**Helm Chart**
Paquete que contiene todos los manifiestos YAML necesarios para desplegar una aplicacion en Kubernetes. Cubierto en Cap 23.

**Hipervisor**
Software que gestiona y distribuye recursos fisicos entre maquinas virtuales. Tipo 1 (bare-metal) y Tipo 2 (hosted). Cubierto en Cap 1.

**hostPath**
Tipo de volumen que monta un directorio del sistema de archivos del nodo host en el Pod. Cubierto en Cap 17.

**HPA (Horizontal Pod Autoscaler)**
Controlador que escala automaticamente el numero de Pods basandose en metricas observadas.

## I

**Image**
Plantilla de solo lectura usada para crear contenedores. Construida con Dockerfile. Cubierto en Cap 2.

**imagePullSecrets**
Secreto de tipo docker-registry que permite a Pods descargar imagenes de registros privados. Cubierto en Cap 16.

**Ingress**
Objeto de Kubernetes que gestiona el acceso externo a servicios HTTP y HTTPS mediante reglas de enrutamiento. Cubierto en Cap 11.

**Ingress Controller**
Controlador que implementa un Ingress, tipicamente con un load balancer (nginx, AGIC, Traefik). Cubierto en Cap 11.

**IngressClass**
Recurso que permite configurar multiples Ingress Controllers en un mismo cluster. Cubierto en Cap 11.

**Init Container**
Contenedor que se ejecuta antes de los contenedores principales de un Pod. Usado para setup, validacion o esperas. Cubierto en Cap 7 y Cap 22.

## J

**Job**
Objeto de Kubernetes que ejecuta Pods hasta completar exitosamente un numero especifico de ellos. Cubierto en Cap 21.

## K

**kubeadm**
Herramienta oficial para crear y gestionar clusters Kubernetes. Cubierto en Cap 24.

**kubectl**
Herramienta de linea de comandos para comunicarse con el API server de Kubernetes.

**kubelet**
Agente principal del nodo que se ejecuta en cada nodo y gestiona Pods y contenedores. Cubierto en Cap 4.

**kube-proxy**
Proxy de red que mantiene reglas de red en nodos y permite comunicacion de red a Pods. Soporta modos iptables e IPVS. Cubierto en Cap 4 y Cap 10.

**kube-scheduler**
Componente del Control Plane que decide en que nodo debe ejecutarse cada Pod. Cubierto en Cap 4 y Cap 26.

## L

**Label**
Par clave-valor adjunto a objetos como Pods, usado para organizar y seleccionar subconjuntos de objetos. Cubierto en Cap 8.

**LimitRange**
Recurso que define valores por defecto y limites minimos/maximos de recursos para contenedores en un namespace. Cubierto en Cap 12.

**Liveness Probe**
Verificacion que determina si un contenedor esta ejecutandose. Si falla, kubelet reinicia el contenedor. Cubierto en Cap 14.

**LoadBalancer**
Tipo de Service que provisiona un balanceador de carga externo del cloud provider. Cubierto en Cap 10.

**Load Balancer**
Distribuye trafico de red entrante a traves de multiples servidores backend.

## M

**maxSurge**
Parametro de rolling update que controla cuantos Pods adicionales pueden existir por encima del numero deseado. Cubierto en Cap 9.

**maxUnavailable**
Parametro de rolling update que controla cuantos Pods pueden estar no disponibles durante la actualizacion. Cubierto en Cap 9.

**Microservices**
Arquitectura que estructura una aplicacion como coleccion de servicios debilmente acoplados.

**Minikube**
Herramienta que crea un cluster Kubernetes local de un solo nodo para desarrollo y aprendizaje. Cubierto en Cap 5.

**Multi-tenancy**
Arquitectura donde una sola instancia de software sirve a multiples inquilinos. En K8s se logra con namespaces. Cubierto en Cap 12.

## N

**Namespace**
Manera de dividir recursos del cluster entre multiples usuarios o equipos. Proporciona aislamiento logico. Cubierto en Cap 12.

**Namespaces (Linux)**
Los 7 tipos de namespaces del kernel Linux (PID, NET, MNT, IPC, UTS, User, Cgroup) que proporcionan aislamiento a contenedores. Cubierto en Cap 2 y Cap 6.

**Network Policy**
Especificacion de como grupos de Pods pueden comunicarse entre si y con otros endpoints de red. Cubierto en Cap 27.

**Node**
Maquina trabajadora en Kubernetes, puede ser virtual o fisica.

**NodePort**
Tipo de Service que expone el servicio en cada IP del nodo en un puerto estatico (30000-32767). Cubierto en Cap 10.

## O

**Observability**
Medida de que tan bien se puede inferir el estado interno de un sistema desde su conocimiento de salidas externas.

**OCI (Open Container Initiative)**
Estandar abierto para formatos de contenedores y runtime.

**OOMKilled**
Estado que indica que un contenedor fue terminado por el kernel por exceder su limite de memoria. Cubierto en Cap 7 y Cap 13.

**OverlayFS**
Union filesystem usado por Docker para gestionar capas de imagenes de forma eficiente. Cubierto en Cap 2.

## P

**Pause Container**
Contenedor de infraestructura invisible que sostiene los namespaces de red y IPC de un Pod. Cubierto en Cap 6.

**Pod**
Unidad mas pequena desplegable en Kubernetes que puede contener uno o mas contenedores. Cubierto en Cap 6-7.

**PersistentVolume (PV)**
Pieza de almacenamiento en el cluster aprovisionada por un administrador o dinamicamente. Cubierto en Cap 17-18.

**PersistentVolumeClaim (PVC)**
Solicitud de almacenamiento por parte de un usuario. Se vincula a un PV. Cubierto en Cap 17-18.

**PriorityClass**
Recurso que define la prioridad de scheduling de un Pod. Pods de alta prioridad pueden desalojar a los de baja prioridad. Cubierto en Cap 7 y Cap 26.

**Prometheus**
Sistema de monitoreo y alertas de codigo abierto.

**Projected Volume**
Tipo de volumen que combina multiples fuentes (Secrets, ConfigMaps, tokens) en un solo directorio. Cubierto en Cap 20.

## Q

**QoS (Quality of Service)**
Clasifica Pods en categorias de servicio (Guaranteed, Burstable, BestEffort) basandose en recursos requests y limits. Cubierto en Cap 7 y Cap 13.

## R

**RBAC (Role-Based Access Control)**
Metodo para regular acceso a recursos computacionales o de red basandose en roles de usuarios. Cubierto en Cap 19-20.

**Readiness Probe**
Verificacion que determina si un contenedor esta listo para recibir trafico. Si falla, se remueve de Endpoints del Service. Cubierto en Cap 14.

**Reconciliation Loop**
Bucle continuo donde los controllers de Kubernetes comparan el estado deseado con el estado real y actuan para converger. Concepto fundamental. Cubierto en Cap 8 y Cap 9.

**Registry**
Servicio que almacena y distribuye imagenes Docker (Docker Hub, ACR, etc.).

**ReplicaSet**
Objeto que mantiene un conjunto estable de Pods replica ejecutandose en cualquier momento. Cubierto en Cap 8.

**Resource Quota**
Proporciona restricciones que limitan el consumo agregado de recursos por namespace. Cubierto en Cap 12.

**Resource Requests**
Cantidad minima de recursos (CPU, memoria) que un contenedor necesita. Usado por el scheduler para placement. Cubierto en Cap 7 y Cap 13.

**Resource Limits**
Cantidad maxima de recursos (CPU, memoria) que un contenedor puede usar. Enforcement por kubelet. Cubierto en Cap 7 y Cap 13.

**Role**
Recurso RBAC que define permisos dentro de un namespace especifico. Cubierto en Cap 19.

**RoleBinding**
Recurso que vincula un Role o ClusterRole a un usuario, grupo o ServiceAccount. Cubierto en Cap 19.

**Rolling Update**
Estrategia de actualizacion que reemplaza Pods gradualmente, asegurando zero-downtime. Estrategia por defecto en Deployments. Cubierto en Cap 9.

## S

**Secret**
Objeto que contiene una pequena cantidad de datos sensibles como contrasenas o tokens. Almacenado en base64. Cubierto en Cap 16.

**Service**
Abstraccion que define un conjunto logico de Pods y politica para acceder a ellos. Proporciona IP estable y DNS. Cubierto en Cap 10.

**ServiceAccount**
Proporciona identidad para procesos que se ejecutan en un Pod. Usa tokens JWT. Cubierto en Cap 20.

**Sidecar Pattern**
Patron de diseno multi-contenedor donde un contenedor auxiliar extiende la funcionalidad del principal (logging, monitoring, proxy). Cubierto en Cap 6 y Cap 22.

**Static Pod**
Pod gestionado directamente por kubelet en un nodo especifico, no por el API server. Cubierto en Cap 26.

**StatefulSet**
Controlador que gestiona el despliegue y escalado de un conjunto de Pods, y proporciona garantias sobre el orden y unicidad.

**StorageClass**
Proporciona una forma para que administradores describan "clases" de almacenamiento que ofrecen. Permite provisioning dinamico. Cubierto en Cap 17-18.

**Startup Probe**
Verificacion que determina si la aplicacion dentro del contenedor ha arrancado. Bloquea liveness/readiness hasta que tiene exito. Cubierto en Cap 14.

## T

**Taint**
Permite que un nodo rechace un conjunto de Pods. Solo Pods con Tolerations coincidentes pueden ser programados. Cubierto en Cap 26.

**Toleration**
Aplicada a Pods, permite que sean programados en nodos con taints coincidentes. Cubierto en Cap 26.

**TTL (Time To Live)**
Mecanismo para limpiar automaticamente Jobs completados despues de un tiempo configurado. Cubierto en Cap 21.

## V

**Version Skew Policy**
Politica de Kubernetes que define la compatibilidad de versiones entre componentes del cluster. Cubierto en Cap 25.

**Volume**
Directorio, posiblemente con datos, accesible a contenedores en un Pod. Cubierto en Cap 17-18.

**VPA (Vertical Pod Autoscaler)**
Ajusta automaticamente los requests y limits de CPU y memoria para contenedores.

## W

**Workload**
Aplicacion ejecutandose en Kubernetes, representada por uno o mas Pods.

---

## Terminos de Azure

**Azure Active Directory (AAD)**
Servicio de gestion de identidades y acceso basado en la nube de Microsoft.

**Azure Key Vault**
Servicio de nube que proporciona almacen seguro para secretos.

**Azure Monitor**
Servicio que maximiza la disponibilidad y rendimiento de aplicaciones y servicios.

**Azure Resource Group**
Contenedor logico para recursos desplegados en Azure.

**Managed Identity**
Proporciona identidad gestionada automaticamente en Azure AD para aplicaciones.

---

## Terminos de DevOps

**CI/CD**
Integracion Continua y Despliegue Continuo - practicas para automatizar el desarrollo de software.

**Infrastructure as Code (IaC)**
Gestion de infraestructura a traves de codigo legible por maquinas.

---

## Metricas y Observabilidad

**SLA (Service Level Agreement)**
Acuerdo entre proveedor de servicio y cliente que define nivel de servicio esperado.

**SLI (Service Level Indicator)**
Medida cuantitativa de algun aspecto del nivel de servicio proporcionado.

**SLO (Service Level Objective)**
Valor objetivo o rango de valores para un SLI medido por un SLA.

**MTTR (Mean Time To Recovery)**
Tiempo promedio para recuperarse de una falla.

**MTBF (Mean Time Between Failures)**
Tiempo promedio entre fallas de un sistema.
