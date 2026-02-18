# Módulo 18: RBAC - Service Accounts en Kubernetes

> **🎯 Enfoque del Módulo**: Control de acceso para **aplicaciones y pods** usando **tokens JWT automáticos**. Para personas (desarrolladores, admins), ver [Módulo 17: Usuarios y Grupos](../modulo-17-rbac-users-groups/).

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

### 🎓 Objetivos Conceptuales
- **Entender Service Accounts**: Comprender qué son, para qué sirven y cuándo usarlos
- **Diferenciar identidades**: Distinguir Service Accounts de usuarios humanos
- **Tokens JWT**: Entender cómo funcionan los tokens automáticos en Kubernetes
- **Arquitectura de seguridad**: Dominar el modelo de permisos para aplicaciones internas

### 🛠️ Objetivos Técnicos
- **Crear Service Accounts**: Usar kubectl y manifiestos YAML
- **Asignar a pods**: Configurar `serviceAccountName` en specs
- **Configurar permisos RBAC**: Roles y RoleBindings para Service Accounts
- **Gestionar tokens**: Entender montaje automático y projected volumes
- **Acceder a API desde pods**: Implementar aplicaciones que usan Kubernetes API

### 🔍 Objetivos de Troubleshooting
- **Diagnosticar problemas de autenticación**: Tokens inválidos o expirados
- **Resolver errores de permisos**: "Forbidden" desde pods
- **Verificar montaje de tokens**: Validar `/var/run/secrets/kubernetes.io/serviceaccount`
- **Auditar accesos de aplicaciones**: Qué pods tienen qué permisos

### 🏢 Objetivos Profesionales
- **Implementar seguridad de aplicaciones**: Mínimo privilegio para pods
- **Diseñar arquitecturas seguras**: Service Accounts por función/componente
- **Automatizar CI/CD**: Usar Service Accounts en pipelines
- **Preparación para certificaciones**: CKA, CKAD, CKS (seguridad de aplicaciones)

---

## ✅ Prerrequisitos

### Conocimientos Previos
- ✅ **Módulo 17 completado (CRÍTICO)**: Debes dominar Roles, RoleBindings, RBAC conceptos
- ✅ **Pods y Deployments**: Cómo crear y gestionar workloads
- ✅ **Namespaces**: Scope de Service Accounts
- ✅ **Conceptos de API REST**: HTTP, JSON, tokens de autenticación

### Herramientas Necesarias
- ✅ **Cluster Kubernetes funcional**: Minikube, AKS, GKE, o similar
- ✅ **kubectl instalado**: Versión 1.20+
- ✅ **Conocimientos de YAML**: Para crear manifiestos
- ✅ **Opcional: Python o Go**: Para ejemplos de API clients

### Verificación de Entorno
```bash
# 1. Verificar acceso al cluster
kubectl cluster-info

# 2. Confirmar permisos de admin
kubectl auth can-i '*' '*' --all-namespaces
# Debe retornar: yes

# 3. Listar Service Accounts existentes
kubectl get serviceaccounts --all-namespaces

# 4. Ver default Service Account
kubectl get serviceaccount default -n default -o yaml

# 5. Verificar si existen RoleBindings para SAs
kubectl get rolebindings --all-namespaces | grep ServiceAccount
```

### Diferencia con Módulo 17
**NO confundir**:
- Módulo 17: **Certificados X.509** para **personas** (desarrolladores, admins)
- Módulo 18: **Tokens JWT** para **aplicaciones** (pods, deployments)

---

## 🗺️ Estructura del Módulo

### Contenido Teórico (4-5 horas)
1. **¿Qué son Service Accounts?** (30 min) - Identidades para pods, diferencias con usuarios
2. **Service Accounts vs Usuarios** (30 min) - Comparación detallada, casos de uso
3. **Anatomía de un Service Account** (30 min) - Estructura, secrets, tokens
4. **Creación y Gestión** (40 min) - kubectl create, manifiestos YAML, ciclo de vida
5. **Tokens y Autenticación** (45 min) - JWT tokens, montaje automático, projected volumes
6. **Asignación de Permisos** (45 min) - Roles y RoleBindings para SAs
7. **Service Accounts en Pods** (40 min) - Configuración, acceso a API
8. **Casos de Uso Prácticos** (30 min) - Monitoring, CI/CD, operators
9. **Mejores Prácticas** (30 min) - Seguridad, auditoría, principio de mínimo privilegio
10. **Troubleshooting** (30 min) - Errores comunes, diagnóstico

### Ejemplos Prácticos (11 archivos/directorios)
- 📄 **01-serviceaccount-completo.yaml**: SA con metadata completa
- 📄 **02-serviceaccount-basico.yaml**: SA minimalista
- 📄 **03-serviceaccounts-por-ambiente.yaml**: Dev, Staging, Prod
- 📄 **04-pod-con-serviceaccount.yaml**: Pod usando SA custom
- 📄 **05-pod-token-proyectado.yaml**: Projected volume para tokens
- 📁 **06-rbac-completo/**: Role + RoleBinding + SA + Pod completo
- 📄 **07-clusterrole-serviceaccount.yaml**: Permisos cluster-wide
- 📄 **08-pod-custom-sa.yaml**: Multiple SAs en diferentes pods
- 📄 **09-deployment-con-sa.yaml**: Deployment con SA específico
- 📄 **10-pod-api-access.yaml**: Pod que accede a K8s API
- 📁 **11-python-api-client/**: Aplicación Python usando SA

### Laboratorios Guiados (1 lab, ~90 min)
- 🧪 **Lab 01: Crear y Usar Service Accounts** (90 min)
  - Crear Service Account para aplicación de monitoreo
  - Definir Role con permisos para leer pods y events
  - Asignar permisos con RoleBinding
  - Desplegar pod que usa el SA
  - Verificar acceso desde dentro del pod
  - Implementar aplicación Python que consulta API

---

## 📚 Rutas de Estudio Recomendadas

### 🟢 Ruta Principiante (3-4 días, ~6-7 horas)
**Para**: Estudiantes que completaron Módulo 17
```
Día 1: Conceptos y Diferencias
  ├─ Secciones 1-3 (1.5 horas)
  ├─ Ejemplos 01-03 (30 min)
  └─ Practicar: kubectl get sa, describe sa

Día 2: Creación y Gestión
  ├─ Secciones 4-5 (1.5 horas)
  ├─ Ejemplos 04-05 (tokens y montaje)
  └─ Crear SAs propios en cluster

Día 3: RBAC para Service Accounts
  ├─ Sección 6 (45 min)
  ├─ Ejemplo 06-rbac-completo (1 hora)
  └─ Asignar permisos a SAs

Día 4: Práctica y Troubleshooting
  ├─ Secciones 7-10 (1.5 horas)
  ├─ Lab 01 completo (90 min)
  └─ Repaso con RESUMEN-MODULO.md
```

### 🟡 Ruta Intermedia (2 días, ~5-6 horas)
**Para**: Desarrolladores con experiencia en K8s
```
Día 1: Teoría + RBAC
  ├─ Secciones 1-6 lectura rápida (2 horas)
  ├─ Ejemplos 01-07 (1 hora)
  └─ Crear SA con permisos propios

Día 2: Aplicaciones Prácticas
  ├─ Secciones 7-10 (1 hora)
  ├─ Ejemplos 08-11 (API clients)
  └─ Lab 01 completo (90 min)
```

### 🔴 Ruta Certificación (1 día, ~4-5 horas)
**Para**: Preparación CKA/CKAD/CKS
```
Sesión Intensiva:
  ├─ RESUMEN-MODULO.md completo (30 min)
  ├─ Ejemplos 01-11 ejecución rápida (1.5 horas)
  ├─ Lab 01 (90 min)
  ├─ Sección 10 Troubleshooting (30 min)
  └─ Práctica comandos rápidos (30 min)

Comandos esenciales para memorizar:
  - kubectl create serviceaccount
  - kubectl create rolebinding --serviceaccount
  - kubectl set serviceaccount
  - kubectl get sa -A
  - kubectl describe sa <name>
  - kubectl get secret <sa-token>
```

---

## 🔗 Relación con Módulo 17 - COMPLEMENTARIEDAD

### Diagrama de Identidades en Kubernetes

```
┌─────────────────────────────────────────────────────────────┐
│         Identidades en Kubernetes - Dos Tipos                │
├───────────────────────────┬─────────────────────────────────┤
│      MÓDULO 17           │         MÓDULO 18               │
│   Usuarios y Grupos      │      Service Accounts           │
├───────────────────────────┼─────────────────────────────────┤
│  👤 PARA QUIÉN            │  🤖 PARA QUIÉN                  │
│                           │                                 │
│  • Personas (humanos)     │  • Aplicaciones (software)      │
│  • Desarrolladores        │  • Pods                         │
│  • Administradores        │  • Deployments                  │
│  • Operadores SRE         │  • CronJobs                     │
│  • Auditores              │  • Controllers                  │
│  • Externos al cluster    │  • DaemonSets                   │
├───────────────────────────┼─────────────────────────────────┤
│  🔐 AUTENTICACIÓN         │  🎫 AUTENTICACIÓN               │
│                           │                                 │
│  • Certificados X.509     │  • Tokens JWT                   │
│  • Generación MANUAL      │  • Generación AUTOMÁTICA        │
│  • OpenSSL                │  • API Kubernetes (nativo)      │
│  • CA externa             │  • CA del cluster               │
│  • Renovación manual      │  • Rotación automática          │
│  • Distribución manual    │  • Montaje automático en pods   │
├───────────────────────────┼─────────────────────────────────┤
│  🌍 ACCESO                │  🏠 ACCESO                      │
│                           │                                 │
│  • EXTERNO al cluster     │  • INTERNO al cluster           │
│  • Desde laptop/PC        │  • Desde dentro de pods         │
│  • kubectl en terminal    │  • Llamadas HTTP a API server   │
│  • kubeconfig local       │  • Token en /var/run/secrets    │
│  • IP remota              │  • IP interna (10.x.x.x)        │
├───────────────────────────┼─────────────────────────────────┤
│  ⚙️ GESTIÓN               │  ⚙️ GESTIÓN                     │
│                           │                                 │
│  • Manual (scripts bash)  │  • Declarativa (kubectl apply)  │
│  • NO es objeto K8s       │  • ES objeto nativo K8s         │
│  • NO persiste en etcd    │  • PERSISTE en etcd             │
│  • Requiere scripts       │  • API estándar de K8s          │
│  • Complejidad alta       │  • Simplicidad relativa         │
├───────────────────────────┼─────────────────────────────────┤
│  📦 SCOPE                 │  📦 SCOPE                       │
│                           │                                 │
│  • Global (no namespace)  │  • Por namespace                │
│  • Usuario único          │  • SA por namespace             │
│  • CN en certificado      │  • Nombre + namespace           │
├───────────────────────────┴─────────────────────────────────┤
│           CONCEPTOS COMPARTIDOS (mismos para ambos)          │
│                                                              │
│  ✅ Roles / ClusterRoles (definición idéntica)              │
│  ✅ RoleBindings / ClusterRoleBindings (misma sintaxis)     │
│  ✅ Permisos (resources, verbs, apiGroups)                  │
│  ✅ Principio de mínimo privilegio                          │
│  ✅ Auditoría de accesos                                    │
└──────────────────────────────────────────────────────────────┘
```

### ¿Cuándo usar qué?

| Escenario | Solución | Módulo |
|-----------|----------|--------|
| Developer ejecuta `kubectl get pods` | Usuario + Certificado | **Módulo 17** |
| Pod de monitoring necesita listar pods | Service Account + Role | **Módulo 18** |
| Admin gestiona cluster remoto | Usuario + ClusterRole | **Módulo 17** |
| Deployment necesita crear ConfigMaps | Service Account + Role | **Módulo 18** |
| CronJob hace backups de etcd | Service Account + ClusterRole | **Módulo 18** |
| CI/CD pipeline despliega apps | Service Account (mejor práctica) | **Módulo 18** |
| Auditor revisa recursos | Usuario (read-only) | **Módulo 17** |
| Operator de K8s crea CRDs | Service Account + ClusterRole | **Módulo 18** |

### Enfoque de Este Módulo (18)

**✅ SÍ cubrimos**:
- Creación de Service Accounts con kubectl y YAML
- Tokens JWT y cómo funcionan
- Montaje automático de tokens en pods
- Asignación de permisos RBAC a Service Accounts
- Acceso a Kubernetes API desde aplicaciones
- Casos de uso: monitoring, CI/CD, operators
- Seguridad y mejores prácticas para aplicaciones

**❌ NO cubrimos** (ver Módulo 17):
- Usuarios humanos (personas)
- Certificados X.509 para autenticación
- OpenSSL y generación manual de certificados
- kubectl config y contextos de usuario
- Grupos de usuarios
- Acceso externo al cluster

---

## 📁 Organización de Recursos

### Carpeta `ejemplos/`
```
ejemplos/
├── 01-serviceaccount-completo.yaml      # SA con annotations y labels
├── 02-serviceaccount-basico.yaml        # SA minimalista
├── 03-serviceaccounts-por-ambiente.yaml # Dev, staging, prod
├── 04-pod-con-serviceaccount.yaml       # Pod usando SA custom
├── 05-pod-token-proyectado.yaml         # Projected volume
├── 06-rbac-completo/                    # Suite completa
│   ├── 01-serviceaccount.yaml           # Service Account
│   ├── 02-role.yaml                     # Role con permisos
│   ├── 03-rolebinding.yaml              # RoleBinding SA→Role
│   └── 04-pod.yaml                      # Pod que usa todo
├── 07-clusterrole-serviceaccount.yaml   # Permisos cluster-wide
├── 08-pod-custom-sa.yaml                # Variaciones de SAs
├── 09-deployment-con-sa.yaml            # Deployment + SA
├── 10-pod-api-access.yaml               # Pod accediendo API
└── 11-python-api-client/                # App Python real
    ├── Dockerfile                       # Imagen container
    ├── requirements.txt                 # Dependencias
    ├── app.py                           # Código Python
    ├── serviceaccount.yaml              # SA para la app
    ├── role.yaml                        # Permisos necesarios
    ├── rolebinding.yaml                 # Binding
    └── deployment.yaml                  # Deploy completo
```

### Carpeta `laboratorios/`
```
laboratorios/
└── lab-01-crear-serviceaccounts.md      # Lab guiado completo
    ├── Objetivos y prerrequisitos
    ├── Parte 1: Crear SA básico
    ├── Parte 2: Asignar permisos RBAC
    ├── Parte 3: Usar SA en pod
    ├── Parte 4: Acceder a K8s API desde pod
    ├── Parte 5: Troubleshooting
    └── Parte 6: Implementar app Python
```

---

## 🎯 Metodología de Aprendizaje

Este módulo sigue un enfoque **práctico-progresivo**:

1. **📖 Fundamentos Teóricos** (30%):
   - Qué son Service Accounts
   - Diferencias con usuarios
   - Arquitectura de tokens JWT

2. **💻 Práctica Incremental** (40%):
   - Crear SAs simples
   - Asignar permisos RBAC
   - Configurar pods con SAs
   - Acceder a API desde aplicaciones

3. **🧪 Laboratorio Integral** (20%):
   - Caso de uso realista (app de monitoring)
   - Implementación end-to-end
   - Troubleshooting de problemas reales

4. **🔍 Mejores Prácticas** (10%):
   - Seguridad de aplicaciones
   - Auditoría de permisos
   - Patrones de diseño

### Flujo de Trabajo Recomendado
```
1. Lee teoría → 2. Crea SA básico → 3. Experimenta en cluster
                          ↓
4. Asigna permisos → 5. Crea pod con SA → 6. Verifica acceso
                          ↓
7. Implementa app → 8. Troubleshooting → 9. Optimiza seguridad
                          ↓
10. Lab completo → 11. Caso de uso propio
```

---

## Tabla de Contenidos

1. [¿Qué son los Service Accounts?](#1-qué-son-los-service-accounts)
2. [Service Accounts vs Usuarios: Diferencias Clave](#2-service-accounts-vs-usuarios-diferencias-clave)
3. [Anatomía de un Service Account](#3-anatomía-de-un-service-account)
4. [Creación y Gestión de Service Accounts](#4-creación-y-gestión-de-service-accounts)
5. [Tokens y Autenticación](#5-tokens-y-autenticación)
6. [Asignación de Permisos con Roles](#6-asignación-de-permisos-con-roles)
7. [Service Accounts en Pods](#7-service-accounts-en-pods)
8. [Casos de Uso Prácticos](#8-casos-de-uso-prácticos)
9. [Mejores Prácticas y Seguridad](#9-mejores-prácticas-y-seguridad)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. ¿Qué son los Service Accounts?

### El Problema que Resuelven

Imagina que tienes una aplicación de monitoreo corriendo dentro de tu cluster de Kubernetes. Esta aplicación necesita consultar constantemente el estado de otros pods, obtener métricas de recursos y verificar el estado de los deployments. Pero surge una pregunta fundamental: **¿cómo puede una aplicación corriendo dentro de un pod autenticarse de forma segura con la API de Kubernetes?**

A diferencia de los usuarios humanos que acceden al cluster desde fuera (usando kubectl con certificados), las aplicaciones corriendo dentro del cluster necesitan un mecanismo diferente. No tiene sentido crear certificados manualmente para cada pod, especialmente cuando estos se crean y destruyen dinámicamente. Aquí es donde entran los **Service Accounts**: identidades automáticas gestionadas por Kubernetes específicamente diseñadas para que las aplicaciones puedan autenticarse con la API del cluster.

Los Service Accounts resuelven este problema proporcionando una identidad digital que Kubernetes genera automáticamente, monta en los pods como tokens JWT, y valida cada vez que la aplicación hace una petición a la API. Es como dar a cada aplicación su propia "tarjeta de identificación" que el cluster reconoce y confía.

### Concepto Fundamental

Un **Service Account** es un objeto de Kubernetes que representa una identidad para procesos que se ejecutan dentro de pods. A diferencia de las cuentas de usuario (que son para personas), los Service Accounts son exclusivamente para aplicaciones y servicios automatizados.

**Características esenciales:**
- 🤖 **Identidad para procesos**: Diseñados para aplicaciones, no para humanos
- 🔑 **Autenticación automática**: Kubernetes genera y monta tokens JWT automáticamente
- 📦 **Alcance por namespace**: Cada Service Account pertenece a un namespace específico
- 🔄 **Gestionado por API**: Se crean y administran como cualquier otro recurso de Kubernetes
- 🛡️ **Seguridad integrada**: Los tokens tienen permisos limitados según la configuración RBAC

### Ejemplo práctico:

Crear un Service Account básico es muy simple:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mi-aplicacion
  namespace: produccion
```

Usar el Service Account en un pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-pod
spec:
  serviceAccountName: mi-aplicacion  # Asignar el SA al pod
  containers:
  - name: app
    image: nginx
```

**📁 Ver archivo completo:** [`ejemplos/02-serviceaccount-basico.yaml`](./ejemplos/02-serviceaccount-basico.yaml)

**🔬 Laboratorio:** Aprende a crear y verificar Service Accounts en [`laboratorios/lab-01-crear-serviceaccounts.md`](./laboratorios/lab-01-crear-serviceaccounts.md)

---

## 2. Service Accounts vs Usuarios: Diferencias Clave

Es crucial entender que Service Accounts y Usuarios son conceptos **completamente diferentes** en Kubernetes.

### Comparación Detallada

#### Service Accounts (Este Módulo)

```yaml
# Son recursos de Kubernetes
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mi-app
  namespace: produccion
```

**Características**:
- ✅ Gestionados por la API de Kubernetes
- ✅ Tienen representación como objetos (puedes hacer `kubectl get sa`)
- ✅ Tokens generados automáticamente
- ✅ Montados automáticamente en pods
- ✅ Scope por namespace
- ✅ Para aplicaciones dentro del cluster

#### Usuarios (Módulo 17)

```bash
# NO son recursos de Kubernetes
# Se gestionan con certificados externos
openssl genrsa -out usuario.key 2048
```

**Características**:
- ❌ NO son objetos de Kubernetes
- ❌ NO se crean con kubectl
- ❌ Certificados gestionados manualmente
- ❌ Para acceso externo (kubectl)
- ❌ Scope global al cluster
- ✅ Para personas

### Analogía del Mundo Real

Piensa en una empresa:

**Usuarios (Módulo 17)** = **Empleados con tarjeta de identificación**
- Entran al edificio desde afuera
- Usan credenciales personales (certificado)
- Gestión manual de credenciales
- Ejemplo: "Juan Pérez, Desarrollador"

**Service Accounts (Módulo 18)** = **Sistemas automatizados internos**
- Operan dentro del edificio
- Credenciales generadas automáticamente
- Sistema de gestión centralizado
- Ejemplo: "Sistema de monitoreo, Sala de servidores A"

### Tabla Comparativa Visual

| Característica | Usuarios y Grupos | Service Accounts |
|----------------|-------------------|------------------|
| **Tipo de identidad** | Humana | Aplicación/Proceso |
| **¿Objeto de K8s?** | ❌ No | ✅ Sí |
| **Creación** | Manual (certificados) | API (`kubectl create sa`) |
| **Autenticación** | Certificado X.509 | Token JWT |
| **Gestión de tokens** | Manual | Automática |
| **Namespace** | No aplica | Sí (namespace-scoped) |
| **Montaje en pods** | ❌ No | ✅ Sí (automático) |
| **Uso típico** | kubectl desde laptop | API calls desde pods |
| **Ejemplo** | DevOps team, Developer | monitoring-app, ci-runner |

---

## 3. Anatomía de un Service Account

### Estructura y Componentes

Un Service Account en Kubernetes es más que solo un nombre. Es un recurso completo que incluye múltiples elementos trabajando en conjunto para proporcionar autenticación y autorización a las aplicaciones. Comprender su anatomía es fundamental para usarlos correctamente y aprovechar todas sus capacidades.

Cuando creas un Service Account, Kubernetes automáticamente genera un Secret que contiene un token JWT. Este token es la "llave" que usa tu aplicación para autenticarse. Además, puedes configurar secretos adicionales para descargar imágenes de registros privados (como Azure Container Registry) y controlar si el token se monta automáticamente en los pods.

La configuración más importante es `automountServiceAccountToken`, que determina si Kubernetes debe montar automáticamente el token en los pods que usan este Service Account. Por defecto es `true`, lo cual es conveniente pero puede representar un riesgo de seguridad si la aplicación no necesita acceso a la API.

### Componentes Principales

Un Service Account completo consta de:

1. **Metadata**: Nombre, namespace, labels y annotations
2. **Secrets**: Token de autenticación generado automáticamente
3. **ImagePullSecrets**: (Opcional) Credenciales para registros de imágenes privados
4. **AutomountServiceAccountToken**: Control de montaje automático del token

### Ejemplo práctico:

Service Account con todas las opciones configuradas:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aplicacion-backend
  namespace: produccion
  labels:
    app: backend
    team: platform
  annotations:
    description: "SA para backend con acceso a ConfigMaps"

# Secretos para pull de imágenes de Azure Container Registry
imagePullSecrets:
  - name: acr-secret

# Permitir montaje automático del token
automountServiceAccountToken: true
```

**📁 Ver archivo completo:** [`ejemplos/01-serviceaccount-completo.yaml`](./ejemplos/01-serviceaccount-completo.yaml)

### El Service Account por Defecto

**Concepto importante:** Cada namespace tiene automáticamente un Service Account llamado `default` que se crea cuando se crea el namespace. Si no especificas un Service Account en un pod, Kubernetes usa automáticamente el SA `default`.

Verificar el Service Account default:

```bash
kubectl get serviceaccount default -n default
kubectl describe sa default -n default
```

**� Laboratorio:** Explora la anatomía completa de Service Accounts en [`laboratorios/lab-01-crear-serviceaccounts.md`](./laboratorios/lab-01-crear-serviceaccounts.md)

---

## 4. Creación y Gestión de Service Accounts

### Métodos de Creación

Existen dos formas principales de crear Service Accounts en Kubernetes: el método imperativo (usando comandos `kubectl` directamente) y el método declarativo (usando archivos YAML). Como profesor, les recomiendo aprender ambos métodos. El imperativo es útil para pruebas rápidas y experimentación, pero el declarativo es el estándar en producción porque permite versionamiento, revisiones y facilita la implementación de GitOps.

El método declarativo tiene ventajas importantes: puedes mantener los manifiestos en Git, revisar cambios antes de aplicarlos, y asegurar que todos los entornos (desarrollo, staging, producción) tengan configuraciones consistentes. Además, es más fácil documentar y compartir la configuración con tu equipo.

### Método 1: Imperativo (Comandos kubectl)

El método más rápido para crear un Service Account es usando `kubectl create`:

```bash
# Crear Service Account básico
kubectl create serviceaccount mi-app

# Crear en namespace específico
kubectl create serviceaccount mi-app -n produccion

# Ver el YAML que se generaría (sin crearlo)
kubectl create serviceaccount mi-app --dry-run=client -o yaml
```

### Método 2: Declarativo (Manifiestos YAML)

**Recomendado para producción.** Permite control de versiones y reproducibilidad:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-reader
  namespace: desarrollo
  labels:
    purpose: read-only
    team: developers
```

Aplicar el manifest:

```bash
kubectl apply -f serviceaccount.yaml
```

**📁 Ver archivo completo:** [`ejemplos/02-serviceaccount-basico.yaml`](./ejemplos/02-serviceaccount-basico.yaml)

### Ejemplo práctico: Service Accounts por Ambiente

Organizar Service Accounts para diferentes ambientes:

```yaml
# Desarrollo - configuración permisiva
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-dev
  namespace: desarrollo
  labels:
    environment: dev
---
# Producción - configuración restrictiva
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-prod
  namespace: produccion
  labels:
    environment: production
    security-level: high
```

**📁 Ver archivo completo:** [`ejemplos/03-serviceaccounts-por-ambiente.yaml`](./ejemplos/03-serviceaccounts-por-ambiente.yaml)

### Comandos de Gestión Comunes

```bash
# Listar Service Accounts
kubectl get serviceaccounts
kubectl get sa  # forma corta

# Ver detalles de un SA
kubectl describe sa mi-app

# Ver en formato YAML
kubectl get sa mi-app -o yaml

# Eliminar un SA
kubectl delete sa mi-app
```

**🔬 Laboratorio:** Practica la creación y gestión de Service Accounts en [`laboratorios/lab-01-crear-serviceaccounts.md`](./laboratorios/lab-01-crear-serviceaccounts.md)

---

## 5. Tokens y Autenticación

### Comprendiendo los Tokens de Service Account

Los tokens son el mecanismo de autenticación que permite a los pods comunicarse con la API de Kubernetes. A diferencia de los certificados que usan los usuarios humanos, los Service Accounts utilizan tokens JWT (JSON Web Tokens) que Kubernetes genera automáticamente. Este diseño simplifica enormemente la gestión de credenciales para aplicaciones que se escalan dinámicamente.

Cuando creas un Service Account, Kubernetes realiza varias acciones automáticas: crea un Secret que contiene el token JWT, asocia ese Secret al Service Account, y cuando un pod usa ese SA, monta automáticamente el token en una ubicación predecible dentro del contenedor (`/var/run/secrets/kubernetes.io/serviceaccount/`). La aplicación puede entonces leer este token y usarlo para autenticarse en cada petición a la API.

En versiones modernas de Kubernetes (1.20+), se recomienda usar **tokens proyectados** en lugar de tokens estáticos. Los tokens proyectados tienen ventajas significativas de seguridad: expiran automáticamente, se renuevan antes de expirar, pueden ser específicos de una audiencia, y reducen el riesgo si un token es comprometido.

### Generación y Montaje Automático

Proceso automático cuando creas un Service Account:

```
1. Creas Service Account
       ↓
2. Kubernetes crea Secret con token JWT
       ↓
3. Secret se asocia al Service Account
       ↓
4. Pod usa el Service Account
       ↓
5. Kubernetes monta el token en el pod automáticamente
```

### Ejemplo práctico:

Verificar el token dentro de un pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-token-pod
spec:
  serviceAccountName: mi-app
  containers:
  - name: test
    image: busybox
    command: ["sleep", "3600"]
```

Inspeccionar el token desde el pod:

```bash
# Entrar al pod
kubectl exec -it test-token-pod -- sh

# Ver archivos del Service Account
ls -la /var/run/secrets/kubernetes.io/serviceaccount/

# Ver el namespace
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace

# Ver el token (JWT)
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

**📁 Ver archivo completo:** [`ejemplos/04-pod-con-serviceaccount.yaml`](./ejemplos/04-pod-con-serviceaccount.yaml)

### Tokens Proyectados (Recomendado)

Configuración moderna y segura con tokens que expiran:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-token-seguro
spec:
  serviceAccountName: mi-app
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: token
      mountPath: /var/run/secrets/tokens
  volumes:
  - name: token
    projected:
      sources:
      - serviceAccountToken:
          path: token
          expirationSeconds: 3600  # Expira en 1 hora
          audience: api
```

**📁 Ver archivo completo:** [`ejemplos/05-pod-token-proyectado.yaml`](./ejemplos/05-pod-token-proyectado.yaml)

**🔬 Laboratorio:** Experimenta con tokens y autenticación en [`laboratorios/lab-02-tokens-autenticacion.md`](./laboratorios/lab-02-tokens-autenticacion.md)

---

## 6. Asignación de Permisos con Roles

### El Modelo RBAC Completo

Este es un concepto crítico que muchos estudiantes confunden al principio: **los Service Accounts por sí solos NO tienen permisos**. Crear un Service Account es solo el primer paso. Para que una aplicación pueda hacer algo útil con la API de Kubernetes, necesitas tres componentes trabajando juntos:

1. **Service Account**: La identidad (quién es)
2. **Role o ClusterRole**: Los permisos (qué puede hacer)
3. **RoleBinding o ClusterRoleBinding**: La conexión (asignar permisos a la identidad)

Esta separación es intencional y poderosa. Te permite reutilizar roles en múltiples Service Accounts, cambiar permisos sin modificar las aplicaciones, y mantener una clara auditoría de quién puede hacer qué. El principio de **mínimo privilegio** debe guiar siempre tus decisiones: otorga solo los permisos estrictamente necesarios para que la aplicación funcione.

### Arquitectura de Permisos

```
ServiceAccount + Role + RoleBinding = Permisos efectivos

┌──────────────────┐   usa    ┌──────────────────┐
│ ServiceAccount   │◄─────────│      Pod         │
│  name: mi-app    │          │                  │
└────────┬─────────┘          └──────────────────┘
         │
         │ asignado mediante
         │
    ┌────▼────────┐        ┌──────────────────┐
    │RoleBinding  │───────►│      Role        │
    │             │        │  Permisos:       │
    └─────────────┘        │  - get pods      │
                           │  - list pods     │
                           └──────────────────┘
```

### Ejemplo práctico: Configuración RBAC Completa

**Paso 1:** Crear el Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-reader
  namespace: desarrollo
```

**Paso 2:** Crear el Role con permisos

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader-role
  namespace: desarrollo
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

**Paso 3:** Crear el RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: desarrollo
subjects:
  - kind: ServiceAccount
    name: pod-reader
    namespace: desarrollo
roleRef:
  kind: Role
  name: pod-reader-role
  apiGroup: rbac.authorization.k8s.io
```

**📁 Ver archivos completos:** [`ejemplos/06-rbac-completo/`](./ejemplos/06-rbac-completo/)

### Permisos Globales con ClusterRole

Para permisos en todos los namespaces:

```yaml
# ClusterRole - permisos globales
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods", "namespaces"]
    verbs: ["get", "list"]
---
# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-monitor-binding
subjects:
  - kind: ServiceAccount
    name: cluster-monitor
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: cluster-pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**📁 Ver archivo completo:** [`ejemplos/07-clusterrole-serviceaccount.yaml`](./ejemplos/07-clusterrole-serviceaccount.yaml)

### Verificar Permisos

```bash
# Ver qué puede hacer un Service Account
kubectl auth can-i --list \
  --as=system:serviceaccount:desarrollo:pod-reader \
  -n desarrollo

# Verificar permiso específico
kubectl auth can-i get pods \
  --as=system:serviceaccount:desarrollo:pod-reader \
  -n desarrollo
```

**🔬 Laboratorio:** Practica la asignación de permisos RBAC en [`laboratorios/lab-03-permisos-rbac.md`](./laboratorios/lab-03-permisos-rbac.md)

---

## 7. Service Accounts en Pods

### Asignación de Service Account a un Pod

Hay dos formas principales de usar Service Accounts en pods:

#### 1. Uso del Service Account por Defecto

Si no especificas nada, el pod usa el SA `default`:

```yaml
# El pod usará automáticamente el SA "default"
apiVersion: v1
kind: Pod
metadata:
  name: pod-default-sa
spec:
  containers:
  - name: nginx
    image: nginx:alpine
```

#### 2. Especificar un Service Account Personalizado

```yaml
# ejemplos/08-pod-custom-sa.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-custom-sa
  namespace: desarrollo
spec:
  # Especificar el Service Account
  serviceAccountName: pod-reader
  
  containers:
  - name: app
    image: busybox:1.36
    command:
      - sleep
      - "3600"
```

### Service Accounts en Deployments

La práctica común es especificar el SA en el template del Deployment:

```yaml
# ejemplos/09-deployment-con-sa.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  namespace: produccion
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      # Service Account para todos los pods del deployment
      serviceAccountName: aplicacion-backend
      
      containers:
      - name: api
        image: miapp/backend:v1.0
        ports:
        - containerPort: 8080
        
        # Opcional: variables de entorno con info del SA
        env:
        - name: MY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: MY_POD_SA
          valueFrom:
            fieldRef:
              fieldPath: spec.serviceAccountName
```

### Acceder a la API desde un Pod

Una vez que un pod tiene un Service Account con permisos, puede acceder a la API:

```yaml
# ejemplos/10-pod-api-access.yaml
apiVersion: v1
kind: Pod
metadata:
  name: api-client
  namespace: desarrollo
spec:
  serviceAccountName: pod-reader
  
  containers:
  - name: kubectl-container
    image: bitnami/kubectl:latest
    command:
      - sleep
      - "3600"
```

```bash
# Aplicar el pod
kubectl apply -f ejemplos/10-pod-api-access.yaml

# Ejecutar comandos dentro del pod
kubectl exec -it api-client -n desarrollo -- bash

# Dentro del pod, usar kubectl
kubectl get pods
kubectl get pods --all-namespaces  # Fallará si no tiene permisos cluster-wide
```

### Ejemplo con curl: Acceso Directo a la API

```bash
# Dentro de un pod con Service Account
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

# Hacer request a la API
curl --cacert $CACERT \
     --header "Authorization: Bearer $TOKEN" \
     https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods
```

### Ejemplo Aplicación Python con Service Account

```yaml
# ejemplos/11-python-api-client/deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: python-api-client
  namespace: desarrollo
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-lister
  namespace: desarrollo
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: python-api-client-binding
  namespace: desarrollo
subjects:
  - kind: ServiceAccount
    name: python-api-client
    namespace: desarrollo
roleRef:
  kind: Role
  name: pod-lister
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-api-client
  namespace: desarrollo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: python-client
  template:
    metadata:
      labels:
        app: python-client
    spec:
      serviceAccountName: python-api-client
      containers:
      - name: python
        image: python:3.11-slim
        command:
          - sleep
          - "infinity"
```

**Script Python de ejemplo** (ver [`ejemplos/11-python-api-client/app.py`](./ejemplos/11-python-api-client/app.py)):
```python
# Usar la librería oficial de Kubernetes
from kubernetes import client, config

# Cargar config desde el pod (usa el SA token automáticamente)
config.load_incluster_config()

# Crear cliente de la API
v1 = client.CoreV1Api()

# Listar pods en el namespace actual
pods = v1.list_namespaced_pod(namespace="desarrollo")
for pod in pods.items:
    print(f"Pod: {pod.metadata.name}")
```

> 🔬 **Laboratorio**: Para practicar el uso de Service Accounts en pods, consulta [`laboratorios/lab-03-pods-con-serviceaccounts.md`](./laboratorios/lab-03-pods-con-serviceaccounts.md)

---

## 8. Casos de Uso Prácticos

### Caso 1: Aplicación de Monitoreo

**Escenario**: Prometheus necesita descubrir pods y servicios automáticamente.

```yaml
# ejemplos/12-caso-uso-monitoreo.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-reader
rules:
  # Descubrir servicios y endpoints
  - apiGroups: [""]
    resources: ["services", "endpoints", "pods", "nodes"]
    verbs: ["get", "list", "watch"]
  
  # Leer config de Ingresses
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-reader-binding
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: prometheus-reader
  apiGroup: rbac.authorization.k8s.io
```

### Caso 2: CI/CD Runner

**Escenario**: GitLab Runner o Jenkins necesita desplegar aplicaciones.

```yaml
# ejemplos/13-caso-uso-cicd.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gitlab-runner
  namespace: ci-cd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: staging
rules:
  # Gestión completa de Deployments
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
  
  # Gestión de Services
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list", "create", "update", "patch"]
  
  # Lectura de Pods para verificar estado
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: gitlab-runner-deployer
  namespace: staging
subjects:
  - kind: ServiceAccount
    name: gitlab-runner
    namespace: ci-cd
roleRef:
  kind: Role
  name: deployer
  apiGroup: rbac.authorization.k8s.io
```

### Caso 3: Aplicación con Acceso a ConfigMaps

**Escenario**: Aplicación que lee configuración dinámica.

```yaml
# ejemplos/14-caso-uso-config-reader.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: config-reader-app
  namespace: produccion
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: configmap-reader
  namespace: produccion
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
  
  # NO incluir secrets - principio de mínimo privilegio
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: config-reader-binding
  namespace: produccion
subjects:
  - kind: ServiceAccount
    name: config-reader-app
    namespace: produccion
roleRef:
  kind: Role
  name: configmap-reader
  apiGroup: rbac.authorization.k8s.io
```

### Caso 4: Operador de Kubernetes

**Escenario**: Custom operator que gestiona recursos personalizados.

```yaml
# ejemplos/15-caso-uso-operator.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: database-operator
  namespace: operators
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: database-operator-role
rules:
  # Gestión de CRDs
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    verbs: ["get", "list", "watch"]
  
  # Gestión de recursos propios
  - apiGroups: ["databases.example.com"]
    resources: ["databases", "databases/status"]
    verbs: ["*"]
  
  # Crear StatefulSets y Services
  - apiGroups: ["apps"]
    resources: ["statefulsets"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
  
  - apiGroups: [""]
    resources: ["services", "persistentvolumeclaims"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: database-operator-binding
subjects:
  - kind: ServiceAccount
    name: database-operator
    namespace: operators
roleRef:
  kind: ClusterRole
  name: database-operator-role
  apiGroup: rbac.authorization.k8s.io
```

### Caso 5: Service Account con Azure Workload Identity

**Escenario**: Integración con Azure AD para acceder a recursos de Azure.

```yaml
# ejemplos/16-caso-uso-azure-workload-identity.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: azure-storage-app
  namespace: produccion
  annotations:
    # Federated identity con Azure AD
    azure.workload.identity/client-id: "12345678-1234-1234-1234-123456789012"
    azure.workload.identity/tenant-id: "87654321-4321-4321-4321-210987654321"
  labels:
    azure.workload.identity/use: "true"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-storage-app
  namespace: produccion
spec:
  replicas: 2
  selector:
    matchLabels:
      app: storage-app
  template:
    metadata:
      labels:
        app: storage-app
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: azure-storage-app
      containers:
      - name: app
        image: myapp/azure-client:v1.0
        env:
        - name: AZURE_CLIENT_ID
          value: "12345678-1234-1234-1234-123456789012"
        - name: AZURE_TENANT_ID
          value: "87654321-4321-4321-4321-210987654321"
        - name: AZURE_FEDERATED_TOKEN_FILE
          value: /var/run/secrets/azure/tokens/azure-identity-token
        volumeMounts:
        - name: azure-identity-token
          mountPath: /var/run/secrets/azure/tokens
          readOnly: true
      volumes:
      - name: azure-identity-token
        projected:
          sources:
          - serviceAccountToken:
              path: azure-identity-token
              expirationSeconds: 3600
              audience: api://AzureADTokenExchange
```

> 🔬 **Laboratorio**: Para implementar estos casos de uso, consulta [`laboratorios/lab-04-casos-uso-practicos.md`](./laboratorios/lab-04-casos-uso-practicos.md)

---

## 9. Mejores Prácticas y Seguridad

### Principios Fundamentales

#### 1. Principio de Mínimo Privilegio

**❌ MAL - Permisos excesivos**:
```yaml
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
```

**✅ BIEN - Permisos específicos**:
```yaml
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

#### 2. Service Accounts Dedicados

**❌ MAL - Reutilizar el SA default**:
```yaml
spec:
  # Usa default implícitamente - no recomendado
  containers:
  - name: app
    image: myapp:v1
```

**✅ BIEN - SA específico por aplicación**:
```yaml
spec:
  serviceAccountName: monitoring-app
  containers:
  - name: app
    image: myapp:v1
```

#### 3. Namespaces para Aislamiento

```yaml
# Separar por namespace y entorno
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-api
  namespace: produccion  # Aislado por namespace
```

### Checklist de Seguridad

✅ **Hacer**:
- Crear un Service Account por aplicación
- Usar Roles (namespace-scoped) en lugar de ClusterRoles cuando sea posible
- Revisar permisos regularmente
- Usar tokens proyectados con expiración
- Auditar el uso de Service Accounts
- Deshabilitar `automountServiceAccountToken` cuando no se necesite
- Usar labels y annotations para documentar propósito

❌ **No hacer**:
- Dar permisos de `cluster-admin` a Service Accounts
- Usar el Service Account `default` para aplicaciones
- Dar acceso a Secrets sin necesidad
- Usar verbos `*` (todos) en Rules
- Compartir Service Accounts entre aplicaciones no relacionadas

### Auditoría de Permisos

```bash
# Ver qué puede hacer un Service Account
kubectl auth can-i --list --as=system:serviceaccount:default:mi-app

# Verificar permiso específico
kubectl auth can-i get pods \
  --as=system:serviceaccount:desarrollo:pod-reader \
  -n desarrollo

# Listar todos los RoleBindings de un Service Account
kubectl get rolebindings --all-namespaces \
  -o json | jq '.items[] | select(.subjects[]?.name=="mi-app")'
```

### Rotación de Tokens

```bash
# Eliminar Secret antiguo (Kubernetes creará uno nuevo)
kubectl delete secret mi-app-token-abc123

# Verificar nuevo secret generado
kubectl get sa mi-app -o yaml

# Reiniciar pods para que usen el nuevo token
kubectl rollout restart deployment mi-deployment
```

### Deshabilitar Service Account cuando no se necesita

```yaml
# ejemplos/17-pod-sin-sa.yaml
# Para pods que NO necesitan acceder a la API
apiVersion: v1
kind: Pod
metadata:
  name: aplicacion-estatica
spec:
  # Deshabilitar completamente el Service Account
  automountServiceAccountToken: false
  
  containers:
  - name: nginx
    image: nginx:alpine
```

### Network Policies para Mayor Seguridad

Combinar Service Accounts con Network Policies:

```yaml
# ejemplos/18-networkpolicy-sa.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-api-access
  namespace: produccion
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Egress
  egress:
  # Permitir DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Bloquear acceso a API server
  # (frontend no necesita acceder a la API)
```

### Pod Security Standards

```yaml
# ejemplos/19-pod-security-standards.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: aplicaciones-restringidas
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
# Los pods en este namespace tendrán restricciones adicionales
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-restricted
  namespace: aplicaciones-restringidas
```

### Ejemplo: Configuración Segura Completa

```yaml
# ejemplos/20-configuracion-segura-completa.yaml
# Service Account con configuración de seguridad completa
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secure-app
  namespace: produccion
  labels:
    app: secure-app
    security-level: high
  annotations:
    description: "SA para aplicación crítica con permisos mínimos"
automountServiceAccountToken: true
---
# Role con permisos mínimos necesarios
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secure-app-role
  namespace: produccion
rules:
  # Solo lo necesario - lectura de ConfigMaps específicos
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["app-config"]  # Solo este ConfigMap específico
    verbs: ["get"]
---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secure-app-binding
  namespace: produccion
subjects:
  - kind: ServiceAccount
    name: secure-app
    namespace: produccion
roleRef:
  kind: Role
  name: secure-app-role
  apiGroup: rbac.authorization.k8s.io
---
# Deployment con todas las mejores prácticas
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: produccion
spec:
  replicas: 3
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      serviceAccountName: secure-app
      
      # Security Context a nivel de pod
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault
      
      containers:
      - name: app
        image: myapp/secure:v1.0
        
        # Security Context a nivel de contenedor
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        # Token proyectado con expiración
        volumeMounts:
        - name: token
          mountPath: /var/run/secrets/tokens
          readOnly: true
        
        # Resources limits
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      
      volumes:
      - name: token
        projected:
          sources:
          - serviceAccountToken:
              path: token
              expirationSeconds: 3600
              audience: api
```

---

## 10. Troubleshooting

### Problemas Comunes y Soluciones

#### Problema 1: "Error: Forbidden"

**Síntoma**:
```
Error from server (Forbidden): pods is forbidden: 
User "system:serviceaccount:default:mi-app" cannot list resource "pods"
```

**Causa**: El Service Account no tiene permisos.

**Solución**:
```bash
# Verificar permisos actuales
kubectl auth can-i list pods --as=system:serviceaccount:default:mi-app

# Verificar RoleBindings
kubectl get rolebindings -o wide | grep mi-app
kubectl get clusterrolebindings -o wide | grep mi-app

# Si no existe, crear Role y RoleBinding
kubectl create role pod-reader --verb=get,list --resource=pods
kubectl create rolebinding mi-app-binding \
  --role=pod-reader \
  --serviceaccount=default:mi-app
```

#### Problema 2: Token No Montado en el Pod

**Síntoma**:
```bash
# Dentro del pod
ls /var/run/secrets/kubernetes.io/serviceaccount/
# No existe o está vacío
```

**Causas posibles**:
1. `automountServiceAccountToken: false` en SA o Pod
2. El pod no especifica un SA válido

**Solución**:
```bash
# Verificar configuración del SA
kubectl get sa mi-app -o yaml | grep automount

# Verificar configuración del pod
kubectl get pod mi-pod -o yaml | grep -A5 serviceAccount

# Recrear pod con configuración correcta
kubectl delete pod mi-pod
kubectl apply -f pod-correcto.yaml
```

#### Problema 3: Service Account No Existe

**Síntoma**:
```
Error: error when creating pod: serviceaccounts "mi-app" not found
```

**Solución**:
```bash
# Verificar si existe
kubectl get sa mi-app -n mi-namespace

# Crear si no existe
kubectl create serviceaccount mi-app -n mi-namespace

# O aplicar desde manifest
kubectl apply -f serviceaccount.yaml
```

#### Problema 4: Token Expirado

**Síntoma**:
```
Unauthorized: Token has expired
```

**Solución**:
```bash
# Para tokens proyectados, se renuevan automáticamente
# Para tokens legacy, eliminar el secret
kubectl delete secret mi-app-token-xyz

# Reiniciar pods
kubectl rollout restart deployment mi-deployment
```

#### Problema 5: Permisos en Namespace Incorrecto

**Síntoma**: Los permisos funcionan en un namespace pero no en otro.

**Causa**: RoleBinding está en namespace diferente.

**Solución**:
```bash
# Verificar namespace del RoleBinding
kubectl get rolebinding -A | grep mi-app

# Role y RoleBinding deben estar en el mismo namespace
# O usar ClusterRole + ClusterRoleBinding para permisos globales
```

### Comandos de Diagnóstico

```bash
# Ver todos los Service Accounts
kubectl get sa --all-namespaces

# Describir Service Account con detalles
kubectl describe sa mi-app

# Ver secrets asociados
kubectl get sa mi-app -o jsonpath='{.secrets[*].name}'

# Ver YAML completo del SA
kubectl get sa mi-app -o yaml

# Listar todos los Roles
kubectl get roles --all-namespaces

# Listar todos los RoleBindings
kubectl get rolebindings --all-namespaces

# Ver qué puede hacer un SA específico
kubectl auth can-i --list \
  --as=system:serviceaccount:default:mi-app \
  -n default

# Probar permiso específico
kubectl auth can-i create deployments \
  --as=system:serviceaccount:default:mi-app \
  -n default

# Ver eventos relacionados con autenticación
kubectl get events --sort-by='.lastTimestamp' | grep -i auth
```

### Debug desde un Pod

```yaml
# ejemplos/21-debug-pod.yaml
# Pod de debug con herramientas útiles
apiVersion: v1
kind: Pod
metadata:
  name: debug-sa
  namespace: default
spec:
  serviceAccountName: mi-app
  containers:
  - name: debug
    image: nicolaka/netshoot:latest
    command:
      - sleep
      - "3600"
```

```bash
# Ejecutar comandos de debug
kubectl exec -it debug-sa -- bash

# Dentro del pod:
# Ver token
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Probar acceso a la API
curl -k -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  https://kubernetes.default.svc/api/v1/namespaces/default/pods

# Instalar kubectl en el pod
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
./kubectl get pods
```

### Logs y Auditoría

```bash
# Ver logs del API server (en clusters gestionados puede no estar disponible)
kubectl logs -n kube-system kube-apiserver-xxx | grep -i "serviceaccount"

# En AKS, revisar logs de diagnóstico
# (requiere configuración de Azure Monitor)

# Ver eventos de autorizacion fallida
kubectl get events --all-namespaces --field-selector type=Warning | grep Forbidden
```

> 🔬 **Laboratorio**: Para practicar troubleshooting, consulta [`laboratorios/lab-05-troubleshooting.md`](./laboratorios/lab-05-troubleshooting.md)

---

## Conclusiones y Próximos Pasos

### Resumen del Módulo

En este módulo hemos aprendido:

✅ **Conceptos fundamentales**:
- Qué son los Service Accounts y por qué son diferentes de los usuarios
- Cómo Kubernetes gestiona automáticamente tokens para aplicaciones
- La arquitectura de autenticación y autorización para pods

✅ **Implementación práctica**:
- Crear y gestionar Service Accounts
- Asignar permisos usando Roles y RoleBindings
- Configurar pods y deployments con Service Accounts
- Trabajar con tokens y acceso a la API

✅ **Seguridad y mejores prácticas**:
- Principio de mínimo privilegio
- Auditoría de permisos
- Configuración segura de Service Accounts
- Troubleshooting de problemas comunes

### Diferencias Clave: Módulo 17 vs Módulo 18

| Concepto | Módulo 17 | Módulo 18 |
|----------|-----------|-----------|
| **Identidad** | Usuarios y Grupos | Service Accounts |
| **Para** | Personas | Aplicaciones/Pods |
| **Autenticación** | Certificados | Tokens JWT |
| **Gestión** | Manual | API de Kubernetes |
| **Uso** | kubectl externo | Dentro del cluster |

### Integración de Conceptos

```
RBAC Completo = Módulo 17 + Módulo 18

┌─────────────────────────────────────────┐
│     Acceso al Cluster Kubernetes        │
│                                          │
│  Externo              │      Interno     │
│  (Módulo 17)          │    (Módulo 18)   │
│                       │                  │
│  Usuarios ────────────┼─── Service       │
│  Grupos               │    Accounts      │
│         │             │        │         │
│         │             │        │         │
│         ▼             │        ▼         │
│    Certificados       │     Tokens       │
│         │             │        │         │
│         └─────────────┴────────┘         │
│                 │                         │
│                 ▼                         │
│         Roles/ClusterRoles                │
│                 │                         │
│                 ▼                         │
│         RoleBindings                      │
│                 │                         │
│                 ▼                         │
│         Permisos Efectivos                │
└─────────────────────────────────────────┘
```

### Próximos Pasos

Después de completar este módulo, estás preparado para:

1. **Implementar seguridad en aplicaciones reales**:
   - Configurar Service Accounts para tus deployments
   - Establecer políticas de seguridad en tu cluster
   - Auditar y monitorear accesos

2. **Explorar temas avanzados**:
   - Pod Security Policies / Pod Security Standards
   - Azure Workload Identity para integración con Azure AD
   - OPA (Open Policy Agent) para políticas avanzadas
   - Service Mesh (Istio, Linkerd) para autenticación mTLS

3. **Mejores prácticas de DevOps**:
   - Automatizar creación de Service Accounts con GitOps
   - Integrar RBAC en pipelines de CI/CD
   - Implementar políticas como código

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

## Glosario Específico del Módulo

- **Service Account (SA)**: Identidad para procesos y aplicaciones dentro de Kubernetes
- **Token JWT**: JSON Web Token usado para autenticar Service Accounts
- **Projected Token**: Token con expiración y audiencia específica (más seguro)
- **automountServiceAccountToken**: Configuración que controla si el token se monta automáticamente
- **imagePullSecrets**: Secrets usados para autenticar con registros de imágenes privados
- **system:serviceaccount**: Prefijo usado en identificadores de Service Accounts
- **In-cluster config**: Configuración que permite a pods acceder a la API desde dentro del cluster

---

## Agradecimientos

Gracias por completar el Módulo 18. Ahora tienes los conocimientos necesarios para implementar autenticación y autorización robusta para tus aplicaciones en Kubernetes.

**¡No olvides practicar con los laboratorios!** La mejor forma de aprender es experimentando con ejemplos reales.

---

**Última actualización**: Noviembre 2025  
**Autor**: Curso Kubernetes - Arquitectura y Operaciones  
**Licencia**: Uso educativo
