# Glosario - Kubernetes y Contenedores

## A

**AKS (Azure Kubernetes Service)**
Servicio gestionado de Kubernetes en Microsoft Azure que simplifica el despliegue, gestión y operaciones de clústeres Kubernetes.

**API Server**
Componente central del plano de control de Kubernetes que expone la API de Kubernetes y actúa como frontend para el estado del clúster.

**Azure Container Registry (ACR)**
Registro privado de contenedores Docker en Azure que permite almacenar y gestionar imágenes de contenedores.

**Autoscaling**
Capacidad de ajustar automáticamente el número de recursos (pods, nodos) basándose en métricas como CPU, memoria o métricas personalizadas.

## B

**Blue-Green Deployment**
Estrategia de despliegue que reduce el tiempo de inactividad ejecutando dos entornos de producción idénticos llamados Blue y Green.

## C

**CNI (Container Network Interface)**
Especificación y bibliotecas para escribir plugins de red para configurar interfaces de red en contenedores Linux.

**ConfigMap**
Objeto de Kubernetes que permite desacoplar la configuración específica del entorno del código de la aplicación.

**Container**
Unidad ejecutable de software que empaqueta código y todas sus dependencias para que la aplicación se ejecute de manera consistente.

**Container Runtime**
Software responsable de ejecutar contenedores. Ejemplos: Docker, containerd, CRI-O.

**Control Plane**
Conjunto de componentes que toman decisiones globales sobre el clúster y detectan y responden a eventos del clúster.

**CronJob**
Objeto de Kubernetes que ejecuta Jobs en un horario programado.

**CSI (Container Storage Interface)**
Estándar para exponer sistemas de almacenamiento arbitrarios a cargas de trabajo contenerizadas.

## D

**DaemonSet**
Objeto de Kubernetes que asegura que todos (o algunos) nodos ejecuten una copia de un Pod.

**Deployment**
Objeto de Kubernetes que proporciona actualizaciones declarativas para Pods y ReplicaSets.

**Docker**
Plataforma para desarrollar, enviar y ejecutar aplicaciones usando tecnología de contenedores.

**Dockerfile**
Archivo de texto que contiene instrucciones para construir una imagen Docker.

## E

**etcd**
Base de datos clave-valor distribuida que Kubernetes usa como almacén de respaldo para todos los datos del clúster.

**Egress**
Tráfico de red saliente desde un Pod o nodo.

## F

**Fluentd**
Recolector de datos unificado de código abierto para procesamiento de logs unificado.

## G

**GitOps**
Práctica de usar Git como fuente única de verdad para la infraestructura declarativa y aplicaciones.

**Grafana**
Plataforma de análisis y monitoreo de código abierto para métricas de tiempo real.

## H

**Health Check**
Verificación automática para determinar si una aplicación está funcionando correctamente.

**Helm**
Gestor de paquetes para Kubernetes que ayuda a gestionar aplicaciones de Kubernetes.

**HPA (Horizontal Pod Autoscaler)**
Controlador que escala automáticamente el número de Pods basándose en métricas observadas.

## I

**Image**
Plantilla de solo lectura usada para crear contenedores.

**Ingress**
Objeto de Kubernetes que gestiona el acceso externo a servicios HTTP y HTTPS.

**Ingress Controller**
Controlador que implementa un Ingress, típicamente con un load balancer.

## J

**Job**
Objeto de Kubernetes que ejecuta Pods hasta completar exitosamente un número específico de ellos.

## K

**kubectl**
Herramienta de línea de comandos para comunicarse con el API server de Kubernetes.

**kubelet**
Agente principal del nodo que se ejecuta en cada nodo y gestiona Pods y contenedores.

**kube-proxy**
Proxy de red que mantiene reglas de red en nodos y permite comunicación de red a Pods.

## L

**Label**
Par clave-valor adjunto a objetos como Pods, usado para organizar y seleccionar subconjuntos de objetos.

**Load Balancer**
Distribuye tráfico de red entrante a través de múltiples servidores backend.

**Liveness Probe**
Verificación que determina si un contenedor está ejecutándose.

## M

**Microservices**
Arquitectura que estructura una aplicación como colección de servicios débilmente acoplados.

**Multi-tenancy**
Arquitectura donde una sola instancia de software sirve a múltiples inquilinos.

## N

**Namespace**
Manera de dividir recursos del clúster entre múltiples usuarios o equipos.

**Network Policy**
Especificación de cómo grupos de Pods pueden comunicarse entre sí y con otros endpoints de red.

**Node**
Máquina trabajadora en Kubernetes, puede ser virtual o física.

**NodePort**
Tipo de Service que expone el servicio en cada IP del nodo en un puerto estático.

## O

**Observability**
Medida de qué tan bien se puede inferir el estado interno de un sistema desde su conocimiento de salidas externas.

**OCI (Open Container Initiative)**
Estándar abierto para formatos de contenedores y runtime.

## P

**Pod**
Unidad más pequeña desplegable en Kubernetes que puede contener uno o más contenedores.

**PersistentVolume (PV)**
Pieza de almacenamiento en el clúster aprovisionada por un administrador.

**PersistentVolumeClaim (PVC)**
Solicitud de almacenamiento por parte de un usuario.

**Prometheus**
Sistema de monitoreo y alertas de código abierto.

## Q

**QoS (Quality of Service)**
Clasifica Pods en categorías de servicio basándose en recursos requests y limits.

## R

**RBAC (Role-Based Access Control)**
Método para regular acceso a recursos computacionales o de red basándose en roles de usuarios.

**Readiness Probe**
Verificación que determina si un contenedor está listo para recibir tráfico.

**Registry**
Servicio que almacena y distribuye imágenes Docker.

**ReplicaSet**
Objeto que mantiene un conjunto estable de Pods réplica ejecutándose en cualquier momento.

**Resource Quota**
Proporciona restricciones que limitan el consumo agregado de recursos por namespace.

## S

**Secret**
Objeto que contiene una pequeña cantidad de datos sensibles como contraseñas o tokens.

**Service**
Abstracción que define un conjunto lógico de Pods y política para acceder a ellos.

**ServiceAccount**
Proporciona identidad para procesos que se ejecutan en un Pod.

**StatefulSet**
Controlador que gestiona el despliegue y escalado de un conjunto de Pods, y proporciona garantías sobre el orden y unicidad.

**StorageClass**
Proporciona una forma para que administradores describan "clases" de almacenamiento que ofrecen.

## T

**Taint**
Permite que un nodo rechace un conjunto de Pods.

**Toleration**
Aplicada a Pods, permite que sean programados en nodos con taints coincidentes.

## V

**Volume**
Directorio, posiblemente con datos, accesible a contenedores en un Pod.

**VPA (Vertical Pod Autoscaler)**
Ajusta automáticamente los requests y limits de CPU y memoria para contenedores.

## W

**Workload**
Aplicación ejecutándose en Kubernetes, representada por uno o más Pods.

---

## Términos de Azure

**Azure Active Directory (AAD)**
Servicio de gestión de identidades y acceso basado en la nube de Microsoft.

**Azure Key Vault**
Servicio de nube que proporciona almacén seguro para secretos.

**Azure Monitor**
Servicio que maximiza la disponibilidad y rendimiento de aplicaciones y servicios.

**Azure Resource Group**
Contenedor lógico para recursos desplegados en Azure.

**Managed Identity**
Proporciona identidad gestionada automáticamente en Azure AD para aplicaciones.

---

## Términos de DevOps

**CI/CD**
Integración Continua y Despliegue Continuo - prácticas para automatizar el desarrollo de software.

**Infrastructure as Code (IaC)**
Gestión de infraestructura a través de código legible por máquinas.

**Canary Deployment**
Técnica para reducir el riesgo de introducir nueva versión de software en producción.

**Blue-Green Deployment**
Estrategia de despliegue que reduce tiempo de inactividad y riesgo.

---

## Métricas y Observabilidad

**SLA (Service Level Agreement)**
Acuerdo entre proveedor de servicio y cliente que define nivel de servicio esperado.

**SLI (Service Level Indicator)**
Medida cuantitativa de algún aspecto del nivel de servicio proporcionado.

**SLO (Service Level Objective)**
Valor objetivo o rango de valores para un SLI medido por un SLA.

**MTTR (Mean Time To Recovery)**
Tiempo promedio para recuperarse de una falla.

**MTBF (Mean Time Between Failures)**
Tiempo promedio entre fallas de un sistema.