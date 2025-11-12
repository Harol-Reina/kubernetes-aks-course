# Módulo 01: Introducción a Kubernetes

## Tabla de Contenidos

1. [Introducción al Módulo](#introducción-al-módulo)
2. [¿Qué es Kubernetes?](#1-qué-es-kubernetes)
3. [De Docker a Kubernetes: La Evolución](#2-de-docker-a-kubernetes-la-evolución)
4. [Arquitectura Básica de Kubernetes](#3-arquitectura-básica-de-kubernetes)
5. [Conceptos Fundamentales](#4-conceptos-fundamentales)
6. [Casos de Uso Reales](#5-casos-de-uso-reales)
7. [Tu Primer Contacto con Kubernetes](#6-tu-primer-contacto-con-kubernetes)
8. [Conclusiones y Próximos Pasos](#conclusiones-y-próximos-pasos)

---

## Introducción al Módulo

Bienvenidos al primer módulo del curso de Kubernetes. Este módulo marca el inicio de tu viaje hacia la comprensión de una de las tecnologías más importantes en el mundo del desarrollo y operaciones modernas.

### Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:
- ✅ Explicar qué es Kubernetes y por qué es fundamental en la infraestructura moderna
- ✅ Comprender la evolución desde contenedores individuales hasta orquestación
- ✅ Identificar los componentes básicos de un cluster de Kubernetes
- ✅ Reconocer cuándo y por qué usar Kubernetes en proyectos reales
- ✅ Ejecutar tus primeros comandos básicos de Kubernetes

### Prerequisitos

Para este módulo necesitas:
- Conocimientos básicos de Docker y contenedores (Área 1 completada)
- Comprensión de conceptos de virtualización
- Familiaridad con la línea de comandos
- (Opcional) Acceso a un cluster de Kubernetes o minikube instalado

### Duración Estimada

- **Lectura teórica**: 30-40 minutos
- **Ejemplos prácticos**: 20-30 minutos
- **Laboratorio**: 60 minutos

---

## 1. ¿Qué es Kubernetes?

### El Origen del Nombre

Antes de entender qué hace Kubernetes, vale la pena conocer su origen. **Kubernetes** (K8s) proviene del griego **"κυβερνήτης" (kubernētēs)**, que significa **"timonel"** o **"piloto de barco"**. Esta etimología no es casual: Kubernetes actúa como el capitán que dirige una flota completa de contenedores (la "carga"), asegurando que todo llegue a su destino de forma segura y eficiente.

El número "8" en K8s representa las 8 letras entre la "K" y la "s" en Kubernetes, una convención común en tecnología para abreviar palabras largas (similar a i18n para internationalization).

### Definición y Propósito

**Definición simple**: Kubernetes es un sistema de código abierto que automatiza el despliegue, escalado y gestión de aplicaciones contenerizadas.

**Definición práctica**: Kubernetes es el "piloto automático" que supervisa miles de contenedores corriendo en múltiples servidores, asegurando que tu aplicación esté siempre disponible, escalable y funcionando correctamente sin intervención manual.

### El Problema que Resuelve

Imagina que tienes una aplicación web exitosa. En el Área 1 aprendiste que Docker te permite empaquetar esta aplicación en un contenedor que funciona igual en cualquier lugar. Pero ahora enfrentas nuevos desafíos:

1. **Escalabilidad**: Tu aplicación creció de 100 a 10,000 usuarios. Necesitas pasar de 1 contenedor a 50 contenedores.
2. **Alta disponibilidad**: Si un servidor falla, ¿cómo garantizas que la aplicación siga funcionando?
3. **Distribución**: Tienes 10 servidores. ¿En cuál servidor debe correr cada contenedor?
4. **Actualizaciones**: ¿Cómo actualizas 50 contenedores sin interrumpir el servicio?
5. **Recursos**: ¿Cómo aseguras que cada contenedor tenga suficiente CPU y memoria?

**Sin Kubernetes**, tendrías que:
- Conectarte manualmente a cada servidor
- Decidir qué contenedores van en cada máquina
- Escribir scripts complejos para reiniciar contenedores caídos
- Gestionar networking entre contenedores en diferentes servidores
- Monitorear constantemente el estado de todo

**Con Kubernetes**, solo describes el estado deseado ("quiero 50 réplicas de mi aplicación con 2GB de RAM cada una") y Kubernetes se encarga de hacerlo realidad y mantenerlo así automáticamente.

### Ejemplo práctico:

Comparación visual de gestión manual vs Kubernetes:

```
GESTIÓN MANUAL DE CONTENEDORES:
┌─────────────────────────────────────────────────────┐
│ Servidor 1  │ Servidor 2  │ Servidor 3              │
│ [App A]     │ [App A]     │ [App B]                 │
│ [App C]     │             │ [App A] ❌ CRASHED      │
│             │ [App B]     │                         │
└─────────────────────────────────────────────────────┘
      ↓             ↓             ↓
  SSH manual    SSH manual    SSH manual
  Reiniciar     Verificar     ¿Qué pasó?
  
Tiempo de respuesta: 5-30 minutos
Riesgo de error humano: ALTO


CON KUBERNETES:
┌─────────────────────────────────────────────────────┐
│              Kubernetes Cluster                     │
│                                                     │
│  Estado deseado: 3 réplicas de App A                │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│  │ App A   │  │ App A   │  │ App A   │              │
│  │ Node 1  │  │ Node 2  │  │ Node 3  │ ❌ Falla     │
│  └─────────┘  └─────────┘  └─────────┘              │
│                                   ↓                 │
│  🤖 Kubernetes detecta fallo automáticamente        │
│                                   ↓                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│  │ App A   │  │ App A   │  │ App A   │ ✅ Nueva     │
│  │ Node 1  │  │ Node 2  │  │ Node 1  │   réplica    │
│  └─────────┘  └─────────┘  └─────────┘              │
└─────────────────────────────────────────────────────┘

Tiempo de respuesta: 5-10 segundos
Riesgo de error humano: NINGUNO
```

### Beneficios Cuantificables

Empresas que adoptan Kubernetes reportan:
- **40-60% reducción** en costos de infraestructura
- **95% reducción** en tiempo de deployment (de horas a minutos)
- **99% mejora** en tiempo de recuperación ante fallos (de 30 min a 30 seg)
- **80% utilización** de recursos vs 35% en entornos tradicionales

**🔬 Laboratorio**: Explora estos conceptos de forma práctica en [`laboratorios/lab-01-conceptos-basicos.md`](./laboratorios/lab-01-conceptos-basicos.md)

---

## 2. De Docker a Kubernetes: La Evolución

### La Historia de la Infraestructura

Para entender por qué Kubernetes es revolucionario, necesitamos ver la evolución de cómo hemos desplegado aplicaciones:

**Era 1: Servidores Físicos (Pre-2000)**
- Una aplicación = Un servidor físico completo
- Desperdicio masivo de recursos (uso típico: 10-15%)
- Escalamiento = Comprar más servidores (semanas/meses)
- Costo: Muy alto
- Flexibilidad: Muy baja

**Era 2: Virtualización (2000-2010)**
- Múltiples VMs en un servidor físico
- Mejor utilización de recursos (30-40%)
- Escalamiento = Crear nuevas VMs (minutos/horas)
- Costo: Alto
- Flexibilidad: Media

**Era 3: Contenedores (2013-2015)**
- Múltiples contenedores compartiendo el mismo OS
- Excelente utilización de recursos (60-70%)
- Escalamiento = Lanzar nuevos contenedores (segundos)
- Costo: Medio
- Flexibilidad: Alta

**Era 4: Orquestación con Kubernetes (2015-Presente)**
- Gestión automatizada de miles de contenedores
- Óptima utilización de recursos (80%+)
- Escalamiento = Automático basado en demanda
- Costo: Bajo a largo plazo
- Flexibilidad: Muy alta

### El Vacío que Docker Solo No Llena

Docker revolucionó cómo empaquetamos y ejecutamos aplicaciones, pero tiene limitaciones cuando escalas:

**Limitaciones de Docker standalone:**

1. **No hay scheduling inteligente**: Tú decides manualmente dónde correr cada contenedor
2. **No hay self-healing**: Si un contenedor falla, permanece caído hasta que lo reinicies
3. **No hay scaling automático**: Debes crear/destruir contenedores manualmente
4. **No hay load balancing integrado**: Necesitas herramientas adicionales
5. **No hay gestión de secretos robusta**: Credenciales expuestas en variables de entorno
6. **No hay rolling updates**: Actualizaciones requieren downtime o scripting complejo

### Ejemplo práctico:

Escalando una aplicación con Docker vs Kubernetes:

**Con Docker solo:**
```bash
# Servidor 1
ssh usuario@servidor1
docker run -d -p 8080:80 --name app-1 miapp:latest

# Servidor 2
ssh usuario@servidor2
docker run -d -p 8080:80 --name app-2 miapp:latest

# Servidor 3
ssh usuario@servidor3
docker run -d -p 8080:80 --name app-3 miapp:latest

# Configurar load balancer manualmente...
# Configurar health checks manualmente...
# Monitorear cada servidor manualmente...
```

**Con Kubernetes:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: miapp
spec:
  replicas: 3  # Kubernetes decide dónde poner cada réplica
  selector:
    matchLabels:
      app: miapp
  template:
    metadata:
      labels:
        app: miapp
    spec:
      containers:
      - name: app
        image: miapp:latest
        ports:
        - containerPort: 80
```

```bash
# Un solo comando
kubectl apply -f deployment.yaml

# Kubernetes automáticamente:
# ✅ Distribuye las 3 réplicas en los nodos disponibles
# ✅ Configura networking entre contenedores
# ✅ Monitorea y reinicia contenedores que fallan
# ✅ Balancea carga entre las réplicas
```

**📁 Ver archivo completo:** [`ejemplos/01-comparacion-docker-k8s/deployment-basico.yaml`](./ejemplos/01-comparacion-docker-k8s/deployment-basico.yaml)

### Por Qué Necesitas Kubernetes

Kubernetes no reemplaza a Docker; lo complementa. Docker sigue siendo la tecnología que ejecuta los contenedores, pero Kubernetes agrega la capa de inteligencia que decide:

- **Dónde** ejecutar cada contenedor (scheduling)
- **Cuándo** reiniciar contenedores (self-healing)
- **Cómo** escalar automáticamente (auto-scaling)
- **Qué** hacer cuando hay actualizaciones (rolling updates)
- **Cómo** exponer servicios al mundo exterior (networking)

**🔬 Laboratorio**: Compara Docker y Kubernetes en acción en [`laboratorios/lab-02-docker-vs-kubernetes.md`](./laboratorios/lab-02-docker-vs-kubernetes.md)

---

## 3. Arquitectura Básica de Kubernetes

### El Concepto de Cluster

Un **cluster de Kubernetes** es un conjunto de máquinas (físicas o virtuales) que trabajan juntas como una unidad. En lugar de gestionar servidores individuales, gestionas el cluster completo como un único sistema computacional.

Piensa en un cluster como una orquesta: tienes un director (control plane) y músicos (worker nodes). El director coordina quién toca qué y cuándo, mientras que los músicos ejecutan la música (corren los contenedores).

### Componentes Principales

Un cluster de Kubernetes se divide en dos tipos de nodos:

**1. Control Plane (Plano de Control)** - "El Cerebro"
Es el conjunto de componentes que toman decisiones globales sobre el cluster. Generalmente corre en uno o más nodos dedicados.

**2. Worker Nodes (Nodos de Trabajo)** - "Los Ejecutores"
Son las máquinas donde realmente corren tus aplicaciones contenerizadas.

### Arquitectura Visual

```
┌────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                      │
│                                                            │
│  ┌────────────────────────────────────────────────────┐    │
│  │           CONTROL PLANE (Master Node)              │    │
│  │                                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐                │    │
│  │  │  API Server  │  │  Scheduler   │                │    │
│  │  │   (cerebro)  │  │  (asignador) │                │    │
│  │  └──────────────┘  └──────────────┘                │    │
│  │                                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐                │    │
│  │  │   etcd       │  │  Controller  │                │    │
│  │  │  (memoria)   │  │   Manager    │                │    │
│  │  └──────────────┘  └──────────────┘                │    │
│  └─────────────────────────┬──────────────────────────┘    │
│                            │                               │
│                   ┌────────┴────────┐                      │
│                   │                 │                      │
│  ┌────────────────▼───┐  ┌──────────▼──────┐               │
│  │   WORKER NODE 1    │  │  WORKER NODE 2  │               │
│  │                    │  │                 │               │
│  │  ┌──────────────┐  │  │ ┌──────────────┐│               │
│  │  │   kubelet    │  │  │ │   kubelet    ││               │
│  │  │  (agente)    │  │  │ │  (agente)    ││               │
│  │  └──────────────┘  │  │ └──────────────┘│               │
│  │                    │  │                 │               │
│  │  ┌──────────────┐  │  │ ┌──────────────┐│               │
│  │  │  Container   │  │  │ │  Container   ││               │
│  │  │   Runtime    │  │  │ │   Runtime    ││               │
│  │  │  (Docker)    │  │  │ │  (Docker)    ││               │
│  │  └──────────────┘  │  │ └──────────────┘│               │
│  │                    │  │                 │               │
│  │  ┌─────┐  ┌─────┐  │  │  ┌─────┐ ┌─────┐│               │
│  │  │ Pod │  │ Pod │  │  │  │ Pod │ │ Pod ││               │
│  │  └─────┘  └─────┘  │  │  └─────┘ └─────┘│               │
│  └────────────────────┘  └─────────────────┘               │
└────────────────────────────────────────────────────────────┘
```

### Componentes del Control Plane

**API Server** - La puerta de entrada
- Es el componente con el que interactúas mediante `kubectl`
- Valida y procesa todas las peticiones REST
- Es el único componente que habla directamente con etcd
- Expone la API de Kubernetes en el puerto 6443

**etcd** - La base de datos distribuida
- Almacena toda la configuración del cluster
- Guarda el estado deseado vs estado actual
- Base de datos clave-valor altamente disponible
- Si etcd falla, el cluster no puede funcionar

**Scheduler** - El asignador inteligente
- Decide en qué nodo debe ejecutarse cada pod
- Considera recursos disponibles (CPU, RAM)
- Respeta restricciones y afinidades
- Optimiza la distribución de carga

**Controller Manager** - El supervisor
- Ejecuta múltiples controladores
- ReplicationController: mantiene el número correcto de réplicas
- NodeController: detecta cuando un nodo cae
- ServiceAccountController: crea service accounts automáticamente
- EndpointController: conecta services con pods

### Componentes de los Worker Nodes

**kubelet** - El agente local
- Corre en cada worker node
- Se comunica con el API Server
- Asegura que los contenedores estén corriendo en su nodo
- Reporta el estado del nodo al control plane

**Container Runtime** - El ejecutor de contenedores
- Software que ejecuta contenedores (Docker, containerd, CRI-O)
- Descarga imágenes de contenedores
- Gestiona el ciclo de vida de contenedores
- Kubernetes es agnóstico al runtime

**kube-proxy** - El proxy de red
- Gestiona reglas de red en cada nodo
- Habilita la comunicación entre pods
- Implementa el concepto de Service
- Puede usar iptables, IPVS, u otros

### Ejemplo práctico:

Flujo de creación de un pod:

```
1. Usuario ejecuta: kubectl create -f pod.yaml
                ↓
2. kubectl envía petición HTTP a API Server
                ↓
3. API Server valida y guarda en etcd
                ↓
4. Scheduler detecta pod sin asignar
                ↓
5. Scheduler elige mejor nodo (Node 2)
                ↓
6. Scheduler actualiza etcd con asignación
                ↓
7. kubelet en Node 2 detecta nuevo pod asignado
                ↓
8. kubelet le dice al Container Runtime: "ejecuta este contenedor"
                ↓
9. Container Runtime descarga imagen y crea contenedor
                ↓
10. kubelet reporta estado "Running" al API Server
                ↓
11. Usuario ve: kubectl get pods → STATUS: Running
```

**📁 Ver diagrama completo:** [`ejemplos/02-arquitectura/diagrama-arquitectura.md`](./ejemplos/02-arquitectura/diagrama-arquitectura.md)

**🔬 Laboratorio**: Explora los componentes del cluster en [`laboratorios/lab-03-componentes-cluster.md`](./laboratorios/lab-03-componentes-cluster.md)

---

## 4. Conceptos Fundamentales

### Los Bloques de Construcción de Kubernetes

Kubernetes introduce varios conceptos nuevos que debes dominar. Estos son los "bloques de construcción" con los que trabajarás diariamente.

### Pod - La Unidad Básica

**Definición**: Un Pod es la unidad más pequeña y simple que puedes crear en Kubernetes. Es un grupo de uno o más contenedores que comparten almacenamiento y red.

**Concepto clave**: En la mayoría de los casos, 1 Pod = 1 contenedor. Sin embargo, cuando múltiples contenedores necesitan trabajar muy estrechamente juntos (por ejemplo, una aplicación y su sidecar de logs), van en el mismo Pod.

**Características de un Pod:**
- Tiene una dirección IP única dentro del cluster
- Los contenedores en un Pod comparten la misma IP y puertos
- Los contenedores pueden comunicarse vía localhost
- Pods son efímeros (pueden crearse y destruirse en cualquier momento)
- Si un Pod muere, no se "repara", se crea uno nuevo

**Analogía**: Un Pod es como un apartamento en un edificio. Puede tener uno o varios habitantes (contenedores), todos comparten la misma dirección (IP) y servicios (red, almacenamiento), pero si el apartamento se destruye, no se reconstruye el mismo, se asigna otro diferente.

### Ejemplo práctico:

Pod con un solo contenedor (caso más común):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```

Comandos básicos con Pods:

```bash
# Crear el pod
kubectl apply -f pod.yaml

# Ver pods en ejecución
kubectl get pods

# Ver detalles del pod
kubectl describe pod nginx-pod

# Ver logs del pod
kubectl logs nginx-pod

# Eliminar el pod
kubectl delete pod nginx-pod
```

**📁 Ver archivo completo:** [`ejemplos/03-pods/pod-simple.yaml`](./ejemplos/03-pods/pod-simple.yaml)

### Deployment - Gestión Declarativa

**Definición**: Un Deployment es un objeto de Kubernetes que gestiona un conjunto de Pods idénticos, asegurando que siempre haya el número correcto de réplicas en ejecución.

**Por qué no usar Pods directamente**: Los Pods son efímeros. Si un Pod falla, desaparece. Un Deployment garantiza que siempre haya el número deseado de Pods corriendo, creando nuevos automáticamente cuando es necesario.

**Capacidades de un Deployment:**
- Mantiene N réplicas de un Pod siempre en ejecución
- Permite rolling updates (actualizaciones sin downtime)
- Permite rollback a versiones anteriores
- Escala horizontal fácilmente (aumentar/disminuir réplicas)
- Self-healing automático (recrea Pods que fallan)

### Ejemplo práctico:

Deployment con 3 réplicas:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3  # Mantener siempre 3 pods
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

Operaciones comunes:

```bash
# Crear deployment
kubectl apply -f deployment.yaml

# Ver deployments
kubectl get deployments

# Escalar a 5 réplicas
kubectl scale deployment nginx-deployment --replicas=5

# Actualizar imagen (rolling update)
kubectl set image deployment/nginx-deployment nginx=nginx:latest

# Ver historial de revisiones
kubectl rollout history deployment/nginx-deployment

# Rollback a versión anterior
kubectl rollout undo deployment/nginx-deployment
```

**📁 Ver archivo completo:** [`ejemplos/04-deployments/deployment-basico.yaml`](./ejemplos/04-deployments/deployment-basico.yaml)

### Service - Exposición de Aplicaciones

**Definición**: Un Service es una abstracción que define un conjunto lógico de Pods y una política para acceder a ellos.

**El problema que resuelve**: Los Pods tienen IPs dinámicas que cambian cuando se recrean. ¿Cómo acceder a tu aplicación si las IPs cambian constantemente? Los Services proporcionan una IP y DNS estables.

**Tipos principales de Services:**

1. **ClusterIP** (por defecto): Expone el Service internamente en el cluster
2. **NodePort**: Expone el Service en cada nodo en un puerto estático
3. **LoadBalancer**: Crea un load balancer externo (en cloud)

### Ejemplo práctico:

Service para exponer un Deployment:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx  # Selecciona pods con esta label
  ports:
  - protocol: TCP
    port: 80        # Puerto del Service
    targetPort: 80  # Puerto del contenedor
```

Acceder al Service:

```bash
# Crear el service
kubectl apply -f service.yaml

# Ver services
kubectl get services

# Desde dentro del cluster, puedes acceder via:
# http://nginx-service:80
# o
# http://nginx-service.default.svc.cluster.local:80
```

**📁 Ver archivo completo:** [`ejemplos/05-services/service-clusterip.yaml`](./ejemplos/05-services/service-clusterip.yaml)

### Namespace - Organización Lógica

**Definición**: Los Namespaces son como "clusters virtuales" dentro de tu cluster físico. Permiten dividir recursos del cluster entre múltiples usuarios o proyectos.

**Uso común:**
- Separar ambientes: `development`, `staging`, `production`
- Separar equipos: `team-a`, `team-b`
- Separar proyectos: `proyecto-x`, `proyecto-y`

**Namespaces por defecto en Kubernetes:**
- `default`: Namespace por defecto para recursos sin namespace especificado
- `kube-system`: Para componentes del sistema de Kubernetes
- `kube-public`: Legible públicamente, usado para recursos públicos
- `kube-node-lease`: Para heartbeats de nodos

### Ejemplo práctico:

Crear y usar namespaces:

```bash
# Crear namespace
kubectl create namespace desarrollo

# O via YAML:
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: desarrollo
```

```bash
# Listar namespaces
kubectl get namespaces

# Crear recursos en un namespace específico
kubectl apply -f deployment.yaml -n desarrollo

# Ver recursos en un namespace
kubectl get pods -n desarrollo

# Ver recursos en todos los namespaces
kubectl get pods --all-namespaces
```

**📁 Ver ejemplos de organización:** [`ejemplos/06-namespaces/organizacion-namespaces.yaml`](./ejemplos/06-namespaces/organizacion-namespaces.yaml)

**🔬 Laboratorio**: Practica con Pods, Deployments y Services en [`laboratorios/lab-04-conceptos-fundamentales.md`](./laboratorios/lab-04-conceptos-fundamentales.md)

---

## 5. Casos de Uso Reales

### Cuándo y Por Qué Usar Kubernetes

Kubernetes no es la solución para todo. Como profesor, mi responsabilidad es ayudarte a identificar cuándo Kubernetes aporta valor real y cuándo puede ser sobrecarga innecesaria.

### Escenarios Ideales para Kubernetes

**1. Aplicaciones Microservicios**

Cuando tu aplicación se compone de múltiples servicios independientes que necesitan:
- Escalado independiente (frontend escala diferente que base de datos)
- Despliegues independientes (actualizar servicio A sin afectar servicio B)
- Comunicación inter-servicios confiable
- Gestión centralizada de secretos y configuraciones

**Ejemplo real**: E-commerce con servicios separados para catálogo, carrito, pagos, notificaciones, etc.

**2. Aplicaciones con Tráfico Variable**

Cuando tu carga de trabajo cambia significativamente:
- Picos de tráfico predecibles (Black Friday, eventos especiales)
- Carga variable impredecible
- Necesidad de escalar rápidamente (segundos, no horas)
- Optimización de costos (escalar hacia abajo cuando no hay demanda)

**Ejemplo real**: Aplicación de entrega de comida que tiene picos en horas de almuerzo y cena.

**3. Aplicaciones Multi-cloud o Híbridas**

Cuando necesitas:
- Evitar vendor lock-in
- Distribuir carga entre múltiples clouds (AWS, Azure, GCP)
- Migrar gradualmente de on-premise a cloud
- Disaster recovery en múltiples regiones

**Ejemplo real**: Banco que mantiene datos sensibles on-premise pero usa cloud para aplicaciones no críticas.

**4. CI/CD y Desarrollo Moderno**

Cuando tu equipo necesita:
- Ambientes consistentes de dev, staging y producción
- Despliegues frecuentes (varias veces al día)
- Rollbacks rápidos y seguros
- Testing automatizado en ambientes aislados

**Ejemplo real**: Startup de software con releases diarios y múltiples equipos de desarrollo.

### Casos de Uso por Industria

**Fintech / Banca:**
- Procesamiento de transacciones escalable
- Cumplimiento regulatorio con namespaces aislados
- Alta disponibilidad (99.99% uptime)
- Ejemplo: [Monzo Bank migró completamente a Kubernetes](https://monzo.com)

**Media / Streaming:**
- Transcodificación de video bajo demanda
- Distribución global de contenido
- Scaling basado en eventos (lanzamiento de nuevo contenido)
- Ejemplo: Spotify usa Kubernetes para servir millones de streams

**E-commerce:**
- Manejo de picos de tráfico (ventas especiales)
- Recomendaciones en tiempo real (machine learning)
- Procesamiento de pagos distribuido
- Ejemplo: Shopify procesa millones de transacciones en Kubernetes

**Salud / Healthcare:**
- Análisis de imágenes médicas (GPU-intensive)
- Aplicaciones HIPAA-compliant aisladas
- Procesamiento de datos sensibles con seguridad robusta
- Ejemplo: Philips usa Kubernetes para aplicaciones de diagnóstico

### Ejemplo práctico:

Arquitectura típica de e-commerce en Kubernetes:

```
┌─────────────────────────────────────────────────────────┐
│           CLUSTER KUBERNETES - E-COMMERCE               │
│                                                         │
│  Namespace: frontend                                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐         │
│  │   React    │  │   React    │  │   React    │         │
│  │    App     │  │    App     │  │    App     │         │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘         │
│        └────────────────┴────────────────┘              │
│                         │                               │
│  ─────────────────────────────────────────────────────  │
│  Namespace: backend                                     │
│                         │                               │
│  ┌──────────────────────┴─────────────────────┐         │
│  │              API Gateway                   │         │
│  └──┬─────────┬──────────┬──────────┬─────────┘         │
│     │         │          │          │                   │
│  ┌──▼──┐   ┌─▼──┐    ┌──▼──┐   ┌──▼──┐                  │
│  │Catá │   │Carr│    │Pago │   │User │                  │
│  │logo │   │ito │    │  s  │   │ s   │                  │
│  └─────┘   └────┘    └─────┘   └─────┘                  │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│  Namespace: data                                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │PostgreSQL│  │  Redis   │  │Elastic   │               │
│  │          │  │  Cache   │  │ Search   │               │
│  └──────────┘  └──────────┘  └──────────┘               │
└─────────────────────────────────────────────────────────┘
```

**📁 Ver arquitectura completa:** [`ejemplos/07-casos-uso/arquitectura-ecommerce.yaml`](./ejemplos/07-casos-uso/arquitectura-ecommerce.yaml)

### Cuándo NO Usar Kubernetes

Es igualmente importante saber cuándo Kubernetes es excesivo:

**❌ No uses Kubernetes si:**
1. **Aplicación simple y monolítica**: Un blog WordPress estático no necesita Kubernetes
2. **Equipo pequeño sin experiencia**: La curva de aprendizaje puede ser contraproducente
3. **Recursos limitados**: Necesitas al menos 3-4 máquinas para un cluster mínimamente viable
4. **Tráfico predecible y bajo**: Una aplicación con 100 usuarios estables
5. **Prototipo o MVP**: Para validar una idea, usa plataformas PaaS más simples

**Alternativas más simples:**
- **Docker Compose**: Para desarrollo local o aplicaciones muy pequeñas
- **Heroku/Vercel/Netlify**: Para aplicaciones web simples
- **AWS ECS/Fargate**: Para equipos ya invertidos en AWS
- **VMs tradicionales**: Para aplicaciones legacy sin containerizar

**🔬 Laboratorio**: Analiza casos de uso reales en [`laboratorios/lab-05-casos-uso.md`](./laboratorios/lab-05-casos-uso.md)

---

## 6. Tu Primer Contacto con Kubernetes

### Verificar Acceso al Cluster

Antes de trabajar con Kubernetes, necesitas confirmar que tienes acceso a un cluster. Esto puede ser:
- Minikube (cluster local en tu laptop)
- Docker Desktop con Kubernetes habilitado
- Cluster en la nube (AKS, EKS, GKE)
- Cluster empresarial

### Ejemplo práctico:

Comandos básicos para explorar tu cluster:

```bash
# Verificar versión de kubectl
kubectl version --client

# Ver información del cluster
kubectl cluster-info

# Ver nodos del cluster
kubectl get nodes

# Ver todos los namespaces
kubectl get namespaces

# Ver pods en todos los namespaces
kubectl get pods --all-namespaces
```

### Tu Primer Pod

Vamos a crear tu primer Pod en Kubernetes:

```yaml
# mi-primer-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-primer-pod
  labels:
    app: demo
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```

Ejecutar:

```bash
# Crear el pod
kubectl apply -f mi-primer-pod.yaml

# Ver el pod
kubectl get pods

# Ver detalles
kubectl describe pod mi-primer-pod

# Ver logs
kubectl logs mi-primer-pod

# Acceder al pod (opcional)
kubectl exec -it mi-primer-pod -- bash

# Eliminar el pod
kubectl delete pod mi-primer-pod
```

### Tu Primer Deployment

Ahora algo más robusto:

```yaml
# mi-primer-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mi-app
  template:
    metadata:
      labels:
        app: mi-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

```bash
# Crear deployment
kubectl apply -f mi-primer-deployment.yaml

# Ver deployment
kubectl get deployments

# Ver pods creados por el deployment
kubectl get pods -l app=mi-app

# Escalar a 4 réplicas
kubectl scale deployment mi-app --replicas=4

# Ver el escalado en acción
kubectl get pods -l app=mi-app -w
```

**📁 Ver ejemplos completos:** [`ejemplos/08-primeros-pasos/`](./ejemplos/08-primeros-pasos/)

**🔬 Laboratorio**: Realiza tu primer despliegue completo en [`laboratorios/lab-06-primer-despliegue.md`](./laboratorios/lab-06-primer-despliegue.md)

---

## Conclusiones y Próximos Pasos

### Resumen de Conceptos Aprendidos

En este módulo has construido una base sólida para trabajar con Kubernetes:

✅ **Comprendes qué es Kubernetes**: Un orquestador de contenedores que automatiza despliegue, escalado y gestión de aplicaciones.

✅ **Entiendes la evolución**: Desde servidores físicos → VMs → Contenedores → Orquestación, y por qué cada paso fue necesario.

✅ **Conoces la arquitectura**: Control Plane (cerebro) + Worker Nodes (ejecutores) trabajando juntos.

✅ **Dominas conceptos fundamentales**: 
- Pods (unidad básica)
- Deployments (gestión de réplicas)
- Services (exposición de aplicaciones)
- Namespaces (organización lógica)

✅ **Identificas casos de uso**: Sabes cuándo Kubernetes aporta valor y cuándo es excesivo.

✅ **Has ejecutado comandos**: Has interactuado con un cluster real creando y gestionando recursos.

### Mapa Conceptual del Módulo

```
                    KUBERNETES
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    QUÉ ES          POR QUÉ        CÓMO FUNCIONA
        │               │               │
    ┌───┴───┐      ┌────┴────┐     ┌───┴───┐
Orquestador    Evolución  Arquitectura
Contenedores   Necesaria    Cluster
    │              │            │
    │              │       ┌────┴────┐
    │              │   Control   Worker
    │              │    Plane    Nodes
    │              │
    └──────┬───────┴──────────┐
           │                  │
    CONCEPTOS BÁSICOS    CASOS DE USO
           │                  │
    ┌──────┼──────┐      ┌────┼────┐
   Pod  Deploy Service  Micro Cloud CI/CD
                        services
```

### Progresión del Aprendizaje

Has completado el **Módulo 01: Introducción a Kubernetes**. 

**Lo que sigue:**

📖 **Módulo 02**: Arquitectura del Cluster (profundización en componentes)
📖 **Módulo 03**: Instalación de Minikube (cluster local para desarrollo)
📖 **Módulo 04**: Pods vs Contenedores (diferencias fundamentales)
📖 **Módulo 05**: Gestión de Pods (ciclo de vida, comandos avanzados)

### Recursos Adicionales

**Documentación Oficial:**
- [Kubernetes.io - Documentación](https://kubernetes.io/docs/)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

**Herramientas Útiles:**
- [Minikube](https://minikube.sigs.k8s.io/) - Cluster local para aprendizaje
- [K9s](https://k9scli.io/) - Terminal UI para Kubernetes
- [Lens](https://k8slens.dev/) - IDE para Kubernetes

**Comunidad:**
- [Kubernetes Slack](https://slack.k8s.io/)
- [CNCF (Cloud Native Computing Foundation)](https://www.cncf.io/)

### Checklist de Verificación

Antes de pasar al siguiente módulo, asegúrate de poder responder:

- [ ] ¿Qué problema principal resuelve Kubernetes?
- [ ] ¿Cuál es la diferencia entre Docker y Kubernetes?
- [ ] ¿Cuáles son los dos tipos principales de nodos en un cluster?
- [ ] ¿Qué es un Pod y en qué se diferencia de un contenedor?
- [ ] ¿Para qué sirve un Deployment?
- [ ] ¿Cuándo usarías Kubernetes y cuándo no?
- [ ] ¿Puedes ejecutar comandos básicos de kubectl?

Si respondiste "sí" a todas, ¡estás listo para continuar!

### Estructura de Archivos del Módulo

```
modulo-01-introduccion-kubernetes/
├── README.md (este archivo)
├── ejemplos/
│   ├── 01-comparacion-docker-k8s/
│   │   └── deployment-basico.yaml
│   ├── 02-arquitectura/
│   │   └── diagrama-arquitectura.md
│   ├── 03-pods/
│   │   └── pod-simple.yaml
│   ├── 04-deployments/
│   │   └── deployment-basico.yaml
│   ├── 05-services/
│   │   └── service-clusterip.yaml
│   ├── 06-namespaces/
│   │   └── organizacion-namespaces.yaml
│   ├── 07-casos-uso/
│   │   └── arquitectura-ecommerce.yaml
│   └── 08-primeros-pasos/
│       ├── mi-primer-pod.yaml
│       └── mi-primer-deployment.yaml
└── laboratorios/
    ├── lab-01-conceptos-basicos.md
    ├── lab-02-docker-vs-kubernetes.md
    ├── lab-03-componentes-cluster.md
    ├── lab-04-conceptos-fundamentales.md
    ├── lab-05-casos-uso.md
    └── lab-06-primer-despliegue.md
```

---

**¡Felicitaciones por completar el Módulo 01!** Has dado el primer paso en tu viaje hacia la maestría en Kubernetes. 

**Siguiente módulo:** [Módulo 02: Arquitectura del Cluster](../modulo-02-arquitectura-cluster/README.md)

---

**Última actualización**: Noviembre 2025  
**Autor**: Curso Kubernetes - Arquitectura y Operaciones  
**Licencia**: Uso educativo
