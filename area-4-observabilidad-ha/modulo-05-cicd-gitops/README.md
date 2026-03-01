# Capítulo 38: CI/CD y GitOps

Llegamos al capítulo final del curso habiendo recorrido todo el ciclo de vida de Kubernetes: desde los fundamentos de Docker y la arquitectura del cluster, pasando por Deployments, Services, Ingress, seguridad con RBAC y Network Policies, almacenamiento, observabilidad y alta disponibilidad. Sabemos construir, operar, monitorear y depurar clusters en producción. El último paso es automatizar todo ese proceso para que sea reproducible, auditable y libre de errores humanos.

El escenario sin CI/CD es familiar: un desarrollador termina una feature, crea una imagen Docker manualmente con `docker build`, la sube al registro con `docker push`, se conecta al cluster con `kubectl apply` desde su laptop — con sus propias credenciales, sus variables de entorno locales, su versión del manifiesto que quizás difiere del repositorio. A las 2 AM, hay un hotfix urgente. Otro desarrollador hace lo mismo desde su máquina. Ahora el cluster tiene una configuración que nadie puede reproducir exactamente, sin audit trail, con riesgo de que dev y producción diverjan sin que nadie lo note. Un error humano en el comando de kubectl puede eliminar el Deployment de producción.

CI/CD (Continuous Integration / Continuous Deployment) automatiza el pipeline completo: cada push a Git dispara el build de la imagen, ejecuta los tests, publica la imagen al registro de contenedores y despliega al cluster. GitOps lleva este principio un paso más allá con una filosofía declarativa: el estado completo del cluster (todos los Deployments, Services, ConfigMaps, Network Policies) se describe en archivos YAML en un repositorio Git, y un operador como ArgoCD o Flux monitorea ese repositorio continuamente y reconcilia el cluster para que siempre coincida con lo que está en Git. Si alguien hace un `kubectl apply` manual en producción, el operador lo detecta y lo revierte.

Piensa en el despliegue manual como entregar el correo a pie, carta por carta: funciona en volúmenes pequeños pero no escala. CI/CD es el sistema postal automatizado. GitOps es el piloto automático de un avión: el plan de vuelo (estado deseado en Git) está definido, y el sistema corrige continuamente cualquier desviación de la ruta, sin necesidad de intervención manual.

En este capítulo aprenderás a construir pipelines CI/CD con Azure DevOps y GitHub Actions para AKS, a implementar los principios de GitOps con ArgoCD y Flux, a configurar sincronización automática entre repositorios Git y el estado del cluster, a gestionar múltiples entornos (dev, staging, prod) con la misma base de código, y a implementar estrategias de despliegue progresivo (blue-green, canary) dentro de un pipeline GitOps.

---

## El Problema de los Deployments Manuales

Para entender por qué CI/CD y GitOps son necesarios, hay que entender en detalle qué sale mal cuando los equipos hacen deployments manuales. El escenario siguiente es una historia real que se repite en equipos de todo el mundo.

### La Historia del Hotfix de las 2 AM

Son las 2:07 AM del sábado. El sistema de monitoreo envía una alerta: la API de pagos está respondiendo con errores 500. El equipo de guardia despierta a Ana, la desarrolladora senior que conoce mejor ese servicio. Ana identifica el bug: hay una condición de carrera en el manejo de transacciones concurrentes. Lo corrige en su laptop en 20 minutos, hace `docker build` de la imagen, la etiqueta como `v2.1.1-hotfix`, la sube al registro con `docker push`. Después edita `deployment.yaml` en su copia local (que lleva tres días sin sincronizar con el repositorio), actualiza la imagen y ejecuta:

```bash
kubectl apply -f deployment.yaml --context=production-cluster
```

La API se recupera. Ana vuelve a dormir. El problema se resolvió en 35 minutos.

A las 9 AM del lunes, Carlos del equipo de DevOps ejecuta el pipeline de CI/CD normal para desplegar la nueva versión `v2.2.0` que llevaba dos semanas en desarrollo. El pipeline toma la definición de `deployment.yaml` del repositorio Git, construye la imagen y la despliega. El hotfix de Ana nunca llegó al repositorio. La condición de carrera reaparece en producción.

Peor aún: nadie sabe exactamente qué contenía el hotfix de Ana porque la imagen `v2.1.1-hotfix` se construyó desde su laptop con cambios locales no commiteados. El audit log del cluster solo muestra "kubectl apply por ana@empresa.com a las 02:23 AM". No hay forma de reproducir ese estado exacto.

### Los Cinco Problemas del Deployment Manual

**1. Error humano: el cluster equivocado, el namespace equivocado**

Cuando un desarrollador ejecuta `kubectl apply`, el contexto activo de `kubectl` determina a qué cluster y namespace va el comando. Es trivialmente fácil tener el contexto apuntando a producción cuando crees que apuntas a staging:

```bash
# El desarrollador cree estar en staging
kubectl config get-contexts
# CURRENT   NAME                          CLUSTER         NAMESPACE
# *         aks-production                aks-prod        default   ← PRODUCCIÓN ACTIVA
#           aks-staging                   aks-staging     default

kubectl delete deployment mi-app   # ELIMINÓ EL DEPLOYMENT DE PRODUCCIÓN
```

Los pipelines automatizados tienen credenciales con alcance limitado: el Service Principal del pipeline de staging solo tiene acceso al cluster de staging. El error humano de apuntar al cluster equivocado es imposible desde el pipeline.

**2. Inconsistencia: la deriva entre entornos**

Con deployments manuales, cada entorno tiende a derivar del estado descrito en Git. El desarrollador prueba algo en staging con `kubectl edit deployment` para ajustar variables de entorno. Funciona. Termina el día sin reflejar el cambio en los manifiestos del repositorio. Esa variable de entorno existe en staging pero no en producción. Cuando el equipo de QA aprueba los tests en staging y se despliega a producción, el comportamiento es diferente.

```
Estado en Git (fuente de verdad oficial):
  FEATURE_FLAG_X=false
  DB_POOL_SIZE=10

Estado real en staging (después de edición manual):
  FEATURE_FLAG_X=true    ← modificado manualmente
  DB_POOL_SIZE=20        ← modificado manualmente

Estado real en producción (desplegado desde Git):
  FEATURE_FLAG_X=false   ← diferente
  DB_POOL_SIZE=10        ← diferente
```

El equipo de QA aprobó tests con `FEATURE_FLAG_X=true`. En producción está `false`. El bug aparece en producción, no en staging. "Funciona en mi entorno" tiene raíces técnicas reales.

**3. Sin audit trail: quién hizo qué y cuándo**

El audit log de Kubernetes (API Server audit logging) registra qué llamadas a la API se hicieron y con qué credenciales. Pero si múltiples desarrolladores usan sus propias credenciales para hacer deployments manuales, el audit trail te dice quién ejecutó el comando, pero no por qué, no desde qué versión del código, no si había tests pasando en ese momento.

Con CI/CD, el audit trail es completo: cada deployment tiene asociado un build ID que enlaza con el commit de Git, los resultados de los tests, el nombre del pipeline y el aprobador si hubo aprobación manual. Seis meses después puedes reconstruir exactamente por qué se desplegó esa versión específica.

**4. Sin plan de rollback: "funcionaba en mi laptop"**

Cuando un deployment manual falla, ¿cuál es el plan de rollback? Si los manifiestos no están versionados en Git, `kubectl rollout undo deployment/mi-app` revierte al estado anterior del Deployment en el cluster, pero eso puede ser otra versión manual desplegada por otra persona. No hay una versión canónica anterior a la que volver de forma confiable.

```bash
# ¿Qué versiones existen para rollback?
kubectl rollout history deployment/mi-app
# REVISION  CHANGE-CAUSE
# 1         <none>        ← sin información
# 2         <none>        ← sin información
# 3         <none>        ← sin información
```

Con GitOps, el rollback es un `git revert` o apuntar la Application de ArgoCD a un commit anterior. La versión anterior está perfectamente descrita en Git con todos sus manifiestos.

**5. Sin proceso de aprobación: acceso directo a producción**

Los deployments manuales generalmente requieren que el desarrollador tenga acceso directo (kubectl context + credenciales) al cluster de producción. Esto viola el principio de mínimo privilegio. En entornos regulados (PCI DSS, SOC 2, ISO 27001), el acceso directo de desarrolladores a producción es un hallazgo de auditoría crítico.

Los pipelines de CI/CD implementan approval gates: el deployment a producción requiere una aprobación manual explícita de una persona designada (tech lead, release manager). El desarrollador solo tiene acceso para escribir código y crear pull requests; el pipeline tiene las credenciales para desplegar.

### El Impacto Real: Outages, Pérdida de Datos y Violaciones de Compliance

Un estudio del State of DevOps Report (DORA) muestra consistentemente que los equipos con prácticas maduras de CI/CD tienen:

- **Frecuencia de deployment**: 46 veces mayor que equipos sin CI/CD
- **Lead time para cambios**: de semanas a horas
- **Time to restore**: de días a menos de una hora
- **Change failure rate**: 5x menor

Los incidentes producidos por deployments manuales tienen patrones reconocibles: el entorno de producción diverge del repositorio, los rollbacks son lentos porque no hay una versión canónica anterior, y el diagnóstico post-mortem no puede determinar exactamente qué cambió porque no hay audit trail completo.

### La Solución: Automatización con CI/CD + GitOps

El pipeline de CI/CD elimina el acceso manual a producción. Git se convierte en la interfaz para cualquier cambio en el cluster: hacer un cambio requiere crear un commit, que dispara el pipeline, que ejecuta tests, que requiere aprobación, que despliega de forma reproducible. GitOps añade la reconciliación continua: cualquier desviación del estado declarado en Git se corrige automáticamente.

---

## Pipeline CI/CD: Conceptos Fundamentales

Antes de ver herramientas específicas, es importante entender los conceptos que definen CI/CD y por qué cada etapa del pipeline existe.

### ¿Qué es Continuous Integration?

**Continuous Integration (CI)** es la práctica de integrar cambios de código frecuentemente — idealmente varias veces al día — en un repositorio compartido, donde cada integración se verifica automáticamente con un build y tests.

El objetivo de CI es detectar errores de integración lo antes posible. Sin CI, los desarrolladores trabajan en ramas largas (días o semanas) y cuando intentan fusionar, se encuentran con conflictos masivos y bugs de integración que son difíciles de diagnosticar porque involucran cambios de múltiples personas.

Con CI, cada push a una rama feature dispara automáticamente:
1. Compilación del código (si aplica)
2. Construcción de la imagen Docker
3. Ejecución de tests unitarios
4. Ejecución de tests de integración
5. Análisis estático de código
6. Escaneo de vulnerabilidades de seguridad

Si cualquiera de estos pasos falla, el desarrollador recibe retroalimentación inmediata — mientras el contexto del cambio aún está fresco en su mente.

### ¿Qué es Continuous Delivery?

**Continuous Delivery (CD)** extiende CI para que el software siempre esté en un estado desplegable. El pipeline lleva automáticamente cada cambio que pasa CI hasta un entorno de staging o pre-producción. El deployment a producción es un paso manual, pero puede ejecutarse en cualquier momento porque el artefacto ya fue validado.

Continuous Delivery responde a la pregunta: "¿Puedo desplegar hoy si quiero?" La respuesta es siempre sí, porque el pipeline ya validó el artefacto.

### ¿Qué es Continuous Deployment?

**Continuous Deployment** va un paso más allá: cada cambio que pasa todos los tests se despliega automáticamente a producción sin intervención manual. Es el nivel más alto de automatización.

La distinción entre Delivery y Deployment es importante para el contexto empresarial. Muchas organizaciones con regulaciones (finanzas, salud, gobierno) necesitan aprobación manual para producción — usan Continuous Delivery. Empresas de software de alta velocidad (Netflix, Amazon) usan Continuous Deployment y despliegan a producción cientos de veces al día.

### El Pipeline Completo: Visualización

Un pipeline moderno de CI/CD para Kubernetes tiene las siguientes etapas en secuencia:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Commit  │───▶│  Build   │───▶│  Test    │───▶│  Scan    │───▶│  Deploy  │
│          │    │          │    │          │    │          │    │          │
│ git push │    │ Docker   │    │ Unit     │    │ Trivy    │    │ kubectl  │
│          │    │ build    │    │ Integra  │    │ Snyk     │    │ apply    │
│          │    │ Push ACR │    │ E2E      │    │ SonarQ   │    │ Helm     │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     │               │               │               │               │
     │               │               │               │               │
  Developer       Registry        Test Report    Security        K8s Cluster
  makes a         receives        with pass/     Report with     runs new
  change          image           fail status    vulnerabilities version
```

Cada etapa tiene una responsabilidad clara y un gate: si falla, el pipeline se detiene y el desarrollador recibe una notificación.

### Stage: Build

El stage de Build toma el código fuente y produce el artefacto desplegable: la imagen Docker. Las responsabilidades son:

- Clonar el repositorio en el agente de CI
- Construir la imagen Docker con `docker build`
- Etiquetar la imagen con un tag único e inmutable (generalmente el commit SHA o el build number)
- Publicar la imagen al registro de contenedores (Azure Container Registry, Docker Hub, ECR)

El tag de la imagen debe ser **inmutable** y **único**. Usar `latest` en producción es una mala práctica: no hay forma de saber qué versión específica del código representa `latest` en un momento dado. El commit SHA es el tag ideal porque es determinístico y trazable al código exacto.

```bash
# Tag con commit SHA — inmutable, trazable
IMAGE_TAG="${REGISTRY}/myapp:${GIT_COMMIT_SHA}"
docker build -t "${IMAGE_TAG}" .
docker push "${IMAGE_TAG}"

# También útil: tag con branch + build number para entornos no producción
DEV_TAG="${REGISTRY}/myapp:develop-${BUILD_NUMBER}"
```

### Stage: Test

El stage de Test ejecuta los diferentes niveles de la pirámide de tests:

**Tests unitarios**: prueban funciones y clases de forma aislada. Son rápidos (segundos) y deben cubrir la lógica de negocio crítica. Se ejecutan sin necesidad del cluster.

**Tests de integración**: prueban cómo interactúan los componentes. Pueden requerir bases de datos y servicios auxiliares. En pipelines de CI, se usan contenedores efímeros (Docker Compose, Testcontainers) para levantar estas dependencias.

**Tests end-to-end (E2E)**: prueban el sistema completo desde la perspectiva del usuario. Son lentos y frágiles pero validan el comportamiento real. Herramientas como Cypress, Playwright o k6 son comunes.

**Tests de contrato (Contract Testing)**: validan que los contratos entre servicios (APIs, eventos) no se rompen. Herramientas como Pact son el estándar para microservicios.

### Stage: Scan

El stage de Scan es el guardián de seguridad del pipeline. Tiene dos dimensiones:

**Escaneo de vulnerabilidades de contenedores**: herramientas como Trivy, Snyk o Anchore analizan la imagen Docker construida buscando CVEs (Common Vulnerabilities and Exposures) en las librerías del sistema operativo base y en las dependencias de la aplicación.

```bash
# Escanear imagen con Trivy
trivy image \
  --exit-code 1 \
  --severity CRITICAL,HIGH \
  --no-progress \
  acrk8scourse.azurecr.io/myapp:${BUILD_ID}

# Salida de ejemplo:
# Total: 3 (HIGH: 2, CRITICAL: 1)
# ┌──────────────┬──────────────────┬──────────────┬─────────────────────────────┐
# │   Library    │  Vulnerability   │   Severity   │           Title             │
# ├──────────────┼──────────────────┼──────────────┼─────────────────────────────┤
# │ openssl      │ CVE-2023-0286    │ CRITICAL     │ X.400 address type          │
# │ libssh2      │ CVE-2019-17498   │ HIGH         │ Integer overflow             │
# └──────────────┴──────────────────┴──────────────┴─────────────────────────────┘
```

**Análisis de calidad de código (SAST)**: herramientas como SonarQube o Semgrep analizan el código fuente buscando problemas de seguridad, code smells, cobertura de tests insuficiente y deuda técnica.

La práctica de "shift left security" consiste en mover los controles de seguridad lo más cerca posible del desarrollador: detectar una vulnerabilidad en el pipeline de CI (cuando el desarrollador acaba de escribir el código) es mucho menos costoso que detectarla en producción meses después.

### Stage: Deploy

El stage de Deploy aplica los manifiestos de Kubernetes al cluster. Hay tres enfoques principales:

**kubectl apply directo**: el pipeline aplica los manifiestos YAML directamente. Simple pero sin gestión de versiones ni dependencias entre manifiestos.

**Helm**: el pipeline ejecuta `helm upgrade --install` con el chart de la aplicación. Helm gestiona el templating (permite parametrizar manifiestos para diferentes entornos), el versionado del chart y el rollback.

**Kustomize**: el pipeline ejecuta `kubectl apply -k overlays/production`. Kustomize permite gestionar variaciones entre entornos mediante overlays (sobreescritura de valores) sin templating.

### Entornos y Gates de Aprobación

Un pipeline maduro tiene múltiples entornos con gates entre ellos:

```
Commit ──▶ Build ──▶ Test ──▶ Scan ──▶ Deploy Dev ──▶ Deploy Staging ──[Aprobación]──▶ Deploy Prod
                                              │               │                               │
                                         Automático      Automático                     Manual Gate
                                                                                    (Tech Lead aprueba)
```

El gate de aprobación antes de producción puede ser:
- **Manual**: una persona designada revisa y aprueba en la interfaz del pipeline
- **Automático con condiciones**: si los tests de staging pasaron, si no hay vulnerabilidades críticas, si las métricas de staging son normales durante X minutos
- **Canary gate**: despliega el 10% del tráfico en producción, monitorea métricas durante Y minutos, promueve al 100% si todo está bien

---

## Azure DevOps con AKS

### Configuración Previa: Service Connections

Antes de crear el pipeline, necesitas configurar las conexiones de servicio en Azure DevOps que permitirán al pipeline autenticarse con ACR y AKS:

**Service Connection para ACR (Docker Registry)**:
1. En Azure DevOps: Project Settings → Service connections → New service connection
2. Tipo: Docker Registry
3. Registry type: Azure Container Registry
4. Seleccionar suscripción y ACR
5. Nombre: `acrConnection`

**Service Connection para AKS (Kubernetes)**:
1. New service connection → Kubernetes
2. Authentication method: Azure Subscription
3. Seleccionar cluster AKS
4. Namespace: `production` (o el namespace target)
5. Nombre: `aksConnection`

**Variable Groups para Secrets**:

Los secrets (contraseñas, connection strings) no deben estar en el YAML del pipeline. Azure DevOps Variable Groups + Azure Key Vault es el patrón recomendado:

```bash
# Crear Key Vault y enlazar con Variable Group en Azure DevOps
az keyvault create \
  --name kv-k8scourse-pipeline \
  --resource-group rg-kubernetes-course \
  --location eastus

# Añadir secrets
az keyvault secret set \
  --vault-name kv-k8scourse-pipeline \
  --name DB-CONNECTION-STRING \
  --value "postgresql://user:pass@db:5432/mydb"

az keyvault secret set \
  --vault-name kv-k8scourse-pipeline \
  --name API-KEY-EXTERNAL \
  --value "sk-xxxxxxxxxxxxx"
```

En Azure DevOps: Library → Variable Groups → Link secrets from Azure Key Vault. Los secrets aparecen como variables en el pipeline pero nunca se exponen en logs ni en el YAML del pipeline.

### Pipeline YAML para Kubernetes

El pipeline mínimo que ya conocemos solo tiene build y deploy. Vamos a expandirlo a un pipeline completo con todas las etapas:

```yaml
# azure-pipelines.yml
# Pipeline CI/CD completo para AKS
# Cubre: Build → Test → Scan → Deploy Staging → Aprobación → Deploy Producción

# Disparar el pipeline en commits a main y develop
# Excluir cambios solo en documentación (no requieren redeploy)
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    exclude:
    - docs/*
    - '*.md'
    - .github/*

# Variables globales del pipeline
variables:
  # Conexiones de servicio configuradas en Azure DevOps
  dockerRegistryServiceConnection: 'acrConnection'
  kubernetesServiceConnectionStaging: 'aksConnectionStaging'
  kubernetesServiceConnectionProd: 'aksConnectionProd'
  # Registry y repositorio
  imageRepository: 'myapp'
  containerRegistry: 'acrk8scourse.azurecr.io'
  dockerfilePath: '**/Dockerfile'
  # Tag único por build: usa el ID del build para trazabilidad
  tag: '$(Build.BuildId)'
  # Habilitar análisis de cobertura
  DISABLE_COVERAGE: 'false'

# ─────────────────────────────────────────
# STAGE 1: Build — Construir imagen Docker
# ─────────────────────────────────────────
stages:
- stage: Build
  displayName: 'Build: Construir imagen Docker'
  jobs:
  - job: BuildImage
    displayName: 'Docker build y push a ACR'
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    # Paso 1: Construir y publicar imagen Docker
    - task: Docker@2
      displayName: 'Build y push imagen Docker'
      inputs:
        command: buildAndPush
        repository: $(imageRepository)
        dockerfile: $(dockerfilePath)
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(tag)
          latest

    # Paso 2: Publicar los manifiestos de K8s como artefacto del pipeline
    # Esto permite que etapas posteriores usen siempre la misma versión de manifiestos
    - task: PublishPipelineArtifact@1
      displayName: 'Publicar manifiestos K8s como artefacto'
      inputs:
        targetPath: '$(Build.SourcesDirectory)/k8s'
        artifact: 'k8s-manifests'
        publishLocation: 'pipeline'

# ─────────────────────────────────────────
# STAGE 2: Test — Tests unitarios e integración
# ─────────────────────────────────────────
- stage: Test
  displayName: 'Test: Tests unitarios e integración'
  dependsOn: Build
  jobs:
  - job: UnitTests
    displayName: 'Tests unitarios'
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - script: |
        # Instalar dependencias y ejecutar tests unitarios
        npm install
        npm run test:unit -- --coverage --reporters=junit
      displayName: 'Ejecutar tests unitarios con cobertura'
      workingDirectory: '$(Build.SourcesDirectory)'

    # Publicar resultados de tests en Azure DevOps
    - task: PublishTestResults@2
      displayName: 'Publicar resultados de tests unitarios'
      condition: always()  # Publicar incluso si los tests fallan
      inputs:
        testResultsFormat: 'JUnit'
        testResultsFiles: '**/test-results.xml'
        mergeTestResults: true
        testRunTitle: 'Tests Unitarios'

    # Publicar reporte de cobertura
    - task: PublishCodeCoverageResults@1
      displayName: 'Publicar cobertura de código'
      condition: always()
      inputs:
        codeCoverageTool: 'Cobertura'
        summaryFileLocation: '$(Build.SourcesDirectory)/coverage/cobertura-coverage.xml'

  - job: IntegrationTests
    displayName: 'Tests de integración'
    pool:
      vmImage: 'ubuntu-latest'
    services:
      # Docker Compose levanta los servicios dependientes para tests de integración
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
        ports:
        - 5432:5432
      redis:
        image: redis:7
        ports:
        - 6379:6379
    steps:
    - script: |
        npm install
        # Tests de integración apuntan a los servicios levantados por el pipeline
        DATABASE_URL=postgresql://testuser:testpass@localhost:5432/testdb \
        REDIS_URL=redis://localhost:6379 \
        npm run test:integration
      displayName: 'Ejecutar tests de integración'

# ─────────────────────────────────────────
# STAGE 3: SecurityScan — Escaneo de vulnerabilidades
# ─────────────────────────────────────────
- stage: SecurityScan
  displayName: 'Security: Escaneo de vulnerabilidades'
  dependsOn: Build
  jobs:
  - job: TrivyScan
    displayName: 'Trivy — Vulnerabilidades de contenedor'
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - script: |
        # Instalar Trivy
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

        # Autenticarse en ACR para descargar la imagen a escanear
        az acr login --name acrk8scourse

        # Escanear la imagen recién construida
        # --exit-code 1 hace fallar el pipeline si hay vulnerabilidades CRÍTICAS o ALTAS
        trivy image \
          --exit-code 1 \
          --severity CRITICAL,HIGH \
          --format template \
          --template "@/usr/local/share/trivy/templates/junit.tpl" \
          --output trivy-results.xml \
          --no-progress \
          $(containerRegistry)/$(imageRepository):$(tag)
      displayName: 'Escanear imagen con Trivy'
      condition: always()

    - task: PublishTestResults@2
      displayName: 'Publicar reporte Trivy'
      condition: always()
      inputs:
        testResultsFormat: 'JUnit'
        testResultsFiles: 'trivy-results.xml'
        testRunTitle: 'Trivy Security Scan'

# ─────────────────────────────────────────
# STAGE 4: DeployStaging — Deploy automático a staging
# ─────────────────────────────────────────
- stage: DeployStaging
  displayName: 'Deploy: Staging (automático)'
  dependsOn:
  - Test
  - SecurityScan
  condition: |
    and(
      succeeded('Test'),
      succeeded('SecurityScan'),
      eq(variables['Build.SourceBranchName'], 'main')
    )
  jobs:
  - deployment: DeployToStaging
    displayName: 'Deploy a AKS Staging'
    pool:
      vmImage: 'ubuntu-latest'
    environment: 'staging'
    strategy:
      runOnce:
        deploy:
          steps:
          # Descargar los manifiestos publicados en el stage Build
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'k8s-manifests'
              targetPath: '$(Pipeline.Workspace)/k8s'

          # Aplicar overlays de Kustomize para staging
          - task: KubernetesManifest@0
            displayName: 'Deploy a K8s Staging con Kustomize'
            inputs:
              action: deploy
              kubernetesServiceConnection: $(kubernetesServiceConnectionStaging)
              namespace: staging
              kustomizationPath: '$(Pipeline.Workspace)/k8s/overlays/staging'
              containers: |
                $(containerRegistry)/$(imageRepository):$(tag)

          # Verificar que el rollout se completó correctamente
          - task: Kubernetes@1
            displayName: 'Verificar rollout en staging'
            inputs:
              connectionType: 'Kubernetes Service Connection'
              kubernetesServiceEndpoint: $(kubernetesServiceConnectionStaging)
              namespace: staging
              command: rollout
              arguments: 'status deployment/myapp --timeout=5m'

# ─────────────────────────────────────────
# STAGE 5: Approval — Gate de aprobación manual
# ─────────────────────────────────────────
- stage: Approval
  displayName: 'Aprobación manual para producción'
  dependsOn: DeployStaging
  jobs:
  - job: WaitForApproval
    displayName: 'Esperar aprobación del Tech Lead'
    pool: server  # Job sin agente — solo espera aprobación
    timeoutInMinutes: 1440  # 24 horas para aprobar
    steps:
    - task: ManualValidation@0
      timeoutInMinutes: 1440
      inputs:
        notifyUsers: |
          tech-lead@empresa.com
          release-manager@empresa.com
        instructions: |
          Por favor verifica:
          1. Tests de staging han pasado correctamente
          2. No hay vulnerabilidades críticas en el reporte de Trivy
          3. La versión $(tag) ha sido probada en staging
          4. Se ha notificado al equipo de operaciones

          Para aprobar, haz click en "Resume" en Azure DevOps.
          Para rechazar el deployment, haz click en "Reject".
        onTimeout: reject  # Si nadie aprueba en 24h, rechazar

# ─────────────────────────────────────────
# STAGE 6: DeployProduction — Deploy a producción
# ─────────────────────────────────────────
- stage: DeployProduction
  displayName: 'Deploy: Producción'
  dependsOn: Approval
  jobs:
  - deployment: DeployToProduction
    displayName: 'Deploy a AKS Producción'
    pool:
      vmImage: 'ubuntu-latest'
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'k8s-manifests'
              targetPath: '$(Pipeline.Workspace)/k8s'

          # Deploy con Kustomize overlay de producción
          - task: KubernetesManifest@0
            displayName: 'Deploy a K8s Producción con Kustomize'
            inputs:
              action: deploy
              kubernetesServiceConnection: $(kubernetesServiceConnectionProd)
              namespace: production
              kustomizationPath: '$(Pipeline.Workspace)/k8s/overlays/production'
              containers: |
                $(containerRegistry)/$(imageRepository):$(tag)

          # Verificar rollout en producción
          - task: Kubernetes@1
            displayName: 'Verificar rollout en producción'
            inputs:
              connectionType: 'Kubernetes Service Connection'
              kubernetesServiceEndpoint: $(kubernetesServiceConnectionProd)
              namespace: production
              command: rollout
              arguments: 'status deployment/myapp --timeout=10m'

          # Plan de rollback automático si el rollout falla
          - task: Kubernetes@1
            displayName: 'Rollback si el deploy falla'
            condition: failed()
            inputs:
              connectionType: 'Kubernetes Service Connection'
              kubernetesServiceEndpoint: $(kubernetesServiceConnectionProd)
              namespace: production
              command: rollout
              arguments: 'undo deployment/myapp'
```

### Kustomize para Multi-Entorno

Kustomize permite gestionar variaciones de configuración entre entornos sin duplicar los manifiestos. La estructura típica de un repositorio de manifiestos con Kustomize:

```
k8s/
├── base/                           # Configuración común a todos los entornos
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
└── overlays/
    ├── dev/                        # Override para desarrollo
    │   ├── kustomization.yaml
    │   └── patch-replicas.yaml    # 1 réplica en dev
    ├── staging/                    # Override para staging
    │   ├── kustomization.yaml
    │   └── patch-replicas.yaml    # 2 réplicas en staging
    └── production/                 # Override para producción
        ├── kustomization.yaml
        ├── patch-replicas.yaml    # 5 réplicas en prod
        └── patch-resources.yaml   # Más CPU/memoria en prod
```

```yaml
# k8s/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml
- configmap.yaml

commonLabels:
  app: myapp
  managed-by: kustomize
```

```yaml
# k8s/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Heredar todo lo del base
bases:
- ../../base

# Sobreescribir imagen con el tag del pipeline
images:
- name: myapp
  newName: acrk8scourse.azurecr.io/myapp
  newTag: "$(tag)"  # Reemplazado por el pipeline

# Aplicar patches específicos de producción
patches:
- patch-replicas.yaml
- patch-resources.yaml

# Namespace de producción
namespace: production
```

```yaml
# k8s/overlays/production/patch-replicas.yaml
# Sobreescribir réplicas para producción
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5  # Producción necesita 5 réplicas
```

---

## GitHub Actions como Alternativa a Azure DevOps

GitHub Actions es la plataforma de CI/CD integrada en GitHub. Si el repositorio de código ya está en GitHub, GitHub Actions elimina la necesidad de una herramienta externa de CI/CD.

### Comparación: Azure DevOps vs GitHub Actions

| Característica | Azure DevOps | GitHub Actions |
|----------------|-------------|----------------|
| Ubicación del YAML | `azure-pipelines.yml` en raíz | `.github/workflows/*.yml` |
| Agentes | Microsoft-hosted runners | GitHub-hosted runners |
| Integración AKS | Nativa (tareas Azure*) | Via `azure/aks-set-context` action |
| Gates de aprobación | Environments con approval checks | Environment protection rules |
| Marketplace | Azure DevOps Extensions | GitHub Actions Marketplace |
| Secretos | Variable Groups + Key Vault | GitHub Secrets + OIDC |
| Paralelismo | Jobs en stages paralelos | Jobs en el mismo workflow |
| Artefactos | Pipeline Artifacts | Actions Artifacts |
| Precio | Por usuarios + agentes paralelos | Por minutos de compute |
| Integración con Azure AD | Profunda y nativa | Via federated credentials (OIDC) |
| Self-hosted agents | Agentes self-hosted | Self-hosted runners |
| Auditoria | Audit logs en Azure DevOps | Audit log en GitHub Enterprise |

**¿Cuándo preferir Azure DevOps?** Cuando la organización ya usa el ecosistema Microsoft (Azure Boards para gestión de proyectos, Azure Repos para código, Azure Artifacts para paquetes). La integración nativa con Azure AD y Azure Resource Manager es significativa para organizaciones enterprise.

**¿Cuándo preferir GitHub Actions?** Cuando el código ya está en GitHub, el equipo prefiere un modelo de configuración más simple, o se necesita el extenso ecosistema de actions públicas de la comunidad.

### Workflow Completo con GitHub Actions

```yaml
# .github/workflows/deploy-aks.yml
# Workflow CI/CD completo para Azure AKS con GitHub Actions
# Estrategia: OIDC para autenticación sin contraseñas almacenadas

name: Deploy to AKS

# Disparar en push a main y en pull requests (solo CI, no CD)
on:
  push:
    branches:
    - main
    paths-ignore:
    - 'docs/**'
    - '*.md'
  pull_request:
    branches:
    - main

# Permisos necesarios para OIDC (autenticación sin secrets de larga duración)
permissions:
  id-token: write   # Necesario para OIDC
  contents: read    # Necesario para checkout

# Variables de entorno globales
env:
  REGISTRY: acrk8scourse.azurecr.io
  IMAGE_NAME: myapp
  RESOURCE_GROUP: rg-kubernetes-course
  CLUSTER_NAME: aks-k8s-course

jobs:
  # ─────────────────────────────────────────
  # JOB 1: Build y push imagen Docker a ACR
  # ─────────────────────────────────────────
  build:
    name: Build Docker image
    runs-on: ubuntu-latest
    outputs:
      # Exportar el tag para que jobs siguientes puedan usarlo
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}

    steps:
    # Clonar el repositorio
    - name: Checkout código
      uses: actions/checkout@v4

    # Autenticación en Azure via OIDC (sin contraseñas almacenadas en secrets)
    # Requiere configurar federated credential en Azure AD App Registration
    - name: Login en Azure via OIDC
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

    # Login en Azure Container Registry
    - name: Login en ACR
      run: az acr login --name acrk8scourse

    # Generar metadata para el tag de la imagen
    # Usa el SHA del commit como tag único e inmutable
    - name: Generar metadata de imagen
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=sha,prefix=sha-,format=short
          type=ref,event=branch
          type=semver,pattern={{version}}

    # Build y push de la imagen Docker
    - name: Build y push imagen
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        # Cache en GitHub Actions para acelerar builds futuros
        cache-from: type=gha
        cache-to: type=gha,mode=max

    # Publicar manifiestos como artefacto para stages siguientes
    - name: Publicar manifiestos K8s
      uses: actions/upload-artifact@v4
      with:
        name: k8s-manifests
        path: k8s/
        retention-days: 7

  # ─────────────────────────────────────────
  # JOB 2: Tests unitarios e integración
  # ─────────────────────────────────────────
  test:
    name: Tests
    runs-on: ubuntu-latest
    needs: build

    services:
      # Levantar PostgreSQL para tests de integración
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
        ports:
        - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - name: Checkout código
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'

    - name: Instalar dependencias
      run: npm ci

    - name: Ejecutar tests unitarios
      run: npm run test:unit -- --coverage

    - name: Ejecutar tests de integración
      env:
        DATABASE_URL: postgresql://testuser:testpass@localhost:5432/testdb
      run: npm run test:integration

    # Publicar reporte de cobertura en el PR (comentario automático)
    - name: Publicar reporte de cobertura
      uses: codecov/codecov-action@v4
      with:
        token: ${{ secrets.CODECOV_TOKEN }}

  # ─────────────────────────────────────────
  # JOB 3: Escaneo de seguridad con Trivy
  # ─────────────────────────────────────────
  security-scan:
    name: Security scan
    runs-on: ubuntu-latest
    needs: build

    steps:
    - name: Login en Azure via OIDC
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

    - name: Login en ACR
      run: az acr login --name acrk8scourse

    # Escanear imagen con Trivy (GitHub Action oficial)
    - name: Escanear imagen con Trivy
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:sha-${{ github.sha }}'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'
        exit-code: '1'  # Fallar si hay vulnerabilidades críticas o altas

    # Publicar resultados en la tab Security de GitHub
    - name: Publicar resultados en GitHub Security
      uses: github/codeql-action/upload-sarif@v3
      if: always()  # Publicar aunque el scan haya fallado
      with:
        sarif_file: 'trivy-results.sarif'

  # ─────────────────────────────────────────
  # JOB 4: Deploy a staging (automático en main)
  # ─────────────────────────────────────────
  deploy-staging:
    name: Deploy a Staging
    runs-on: ubuntu-latest
    needs: [test, security-scan]
    # Solo desplegar a staging cuando el push es a main (no en PRs)
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    # Usar environment "staging" para tracking y URL del entorno
    environment:
      name: staging
      url: https://staging.miapp.ejemplo.com

    steps:
    - name: Descargar manifiestos K8s
      uses: actions/download-artifact@v4
      with:
        name: k8s-manifests
        path: k8s/

    - name: Login en Azure via OIDC
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

    # Configurar kubectl para el cluster de staging
    - name: Configurar kubectl para AKS Staging
      uses: azure/aks-set-context@v3
      with:
        resource-group: ${{ env.RESOURCE_GROUP }}
        cluster-name: aks-staging

    # Desplegar usando manifiestos K8s con sustitución de imagen
    - name: Deploy a staging
      uses: azure/k8s-deploy@v4
      with:
        namespace: staging
        manifests: |
          k8s/base/deployment.yaml
          k8s/base/service.yaml
        # Sustituir la imagen con el tag del commit actual
        images: |
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:sha-${{ github.sha }}
        # Estrategia de deployment: rolling update
        strategy: rolling

    # Verificar que el deployment está healthy
    - name: Verificar deployment en staging
      run: |
        kubectl rollout status deployment/myapp -n staging --timeout=5m
        echo "Staging deployment exitoso"

  # ─────────────────────────────────────────
  # JOB 5: Deploy a producción (requiere aprobación manual)
  # ─────────────────────────────────────────
  deploy-production:
    name: Deploy a Producción
    runs-on: ubuntu-latest
    needs: deploy-staging
    # Environment "production" en GitHub tiene protection rules:
    # - Required reviewers: tech-lead, release-manager
    # - Wait timer: 5 minutos (tiempo de reflexión)
    environment:
      name: production
      url: https://miapp.ejemplo.com

    steps:
    - name: Descargar manifiestos K8s
      uses: actions/download-artifact@v4
      with:
        name: k8s-manifests
        path: k8s/

    - name: Login en Azure via OIDC
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

    - name: Configurar kubectl para AKS Producción
      uses: azure/aks-set-context@v3
      with:
        resource-group: ${{ env.RESOURCE_GROUP }}
        cluster-name: ${{ env.CLUSTER_NAME }}

    - name: Deploy a producción
      uses: azure/k8s-deploy@v4
      with:
        namespace: production
        manifests: |
          k8s/base/deployment.yaml
          k8s/base/service.yaml
        images: |
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:sha-${{ github.sha }}
        strategy: rolling

    - name: Verificar deployment en producción
      run: |
        kubectl rollout status deployment/myapp -n production --timeout=10m
        echo "Producción deployment exitoso: version sha-${{ github.sha }}"
```

### Configurar Environment Protection Rules en GitHub

Para activar el gate de aprobación en producción, configura las protection rules en el repositorio de GitHub:

```
GitHub → Repository → Settings → Environments → production → Configure

Protección:
  [x] Required reviewers
      Reviewers: @tech-lead @release-manager

  [x] Wait timer: 5 minutes (tiempo mínimo entre deploy staging → prod)

  [x] Restrict deployment to protected branches: main
```

### Configurar OIDC para Autenticación sin Contraseñas

La autenticación OIDC (OpenID Connect) elimina la necesidad de almacenar el `client_secret` de Azure AD en los secrets de GitHub. En su lugar, GitHub emite un token JWT de corta duración que Azure AD valida:

```bash
# 1. Crear App Registration en Azure AD
az ad app create --display-name "github-actions-aks"

# 2. Crear Service Principal
az ad sp create --id <app-id>

# 3. Crear federated credential (confiar en tokens de GitHub)
az ad app federated-credential create \
  --id <app-id> \
  --parameters '{
    "name": "github-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:mi-org/mi-repo:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# 4. Asignar permisos al Service Principal
az role assignment create \
  --assignee <sp-object-id> \
  --role "AcrPush" \
  --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerRegistry/registries/acrk8scourse

az role assignment create \
  --assignee <sp-object-id> \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerService/managedClusters/aks-k8s-course
```

Con OIDC, los únicos secrets que se almacenan en GitHub son `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` y `AZURE_SUBSCRIPTION_ID` — todos identificadores no sensibles, sin contraseñas.

---

## GitOps: El Estado Deseado Vive en Git

CI/CD automatiza el proceso de build y deploy. GitOps es una metodología que extiende este principio para la operación continua del cluster: no es solo sobre cómo se despliega, sino sobre cómo el cluster se mantiene en el estado correcto en todo momento.

### ¿Qué es GitOps?

GitOps es una metodología de operaciones de infraestructura donde:

1. **El estado deseado de la infraestructura se describe de forma declarativa en Git**: todos los manifiestos de Kubernetes (Deployments, Services, ConfigMaps, Network Policies, PersistentVolumeClaims, RBAC) viven en un repositorio Git como archivos YAML.

2. **Git es la única fuente de verdad**: cualquier cambio en el cluster debe pasar por Git. `kubectl apply` directo en producción está prohibido. El único camino para cambiar el estado del cluster es hacer un commit a Git.

3. **Un agente automático reconcilia el estado**: un operador corriendo en el cluster (ArgoCD, Flux) compara continuamente el estado declarado en Git con el estado real del cluster y aplica los cambios necesarios para que coincidan.

4. **Las desviaciones se detectan y corrigen automáticamente**: si alguien ejecuta `kubectl edit deployment/myapp` y cambia el número de réplicas, el operador de GitOps lo detecta y revierte el cambio para volver al estado declarado en Git.

GitOps no es una herramienta — es una metodología. La herramienta (ArgoCD, Flux, Fleet) es la implementación.

### El Modelo Push vs Pull

La diferencia arquitectónica fundamental entre CI/CD tradicional y GitOps es el modelo de deployment:

```
MODELO PUSH (CI/CD Tradicional):

  Developer                Pipeline                  Cluster
     │                        │                         │
     │── git push ──────────▶ │                         │
     │                        │── build ────────────── │
     │                        │── test ─────────────── │
     │                        │── docker push ───────── │
     │                        │── kubectl apply ───────▶│
     │                        │                         │
     │                                           Estado final

MODELO PULL (GitOps):

  Developer       Git Repo              GitOps Operator         Cluster
     │               │                        │                    │
     │── git push ──▶│                        │                    │
     │               │◀── poll cada 3min ─────│                    │
     │               │─── cambio detectado ──▶│                    │
     │               │                        │── reconcile ──────▶│
     │               │                        │                    │
     │               │                   compara estado          aplica
     │               │                   desired vs actual       diferencia
```

**Ventajas del modelo Pull (GitOps)**:

- **Seguridad**: el operador GitOps en el cluster solo necesita acceso de lectura a Git (no de escritura), y el cluster no necesita exponer su API a pipelines externos. Reduce significativamente la superficie de ataque.

- **Audit trail completo**: cada cambio en el cluster tiene un commit de Git asociado con autor, mensaje, timestamp y aprobadores del pull request. El historial de Git es el historial de cambios del cluster.

- **Rollback trivial**: `git revert <commit>` + push revierte cualquier cambio. El operador GitOps detecta el nuevo estado en Git y aplica el rollback automáticamente.

- **Drift detection**: si el estado real del cluster diverge del estado en Git (por un `kubectl apply` manual, un bug en un operador, o un fallo de infraestructura), el operador GitOps lo detecta y lo corrige.

### Cuándo Usar GitOps vs CI/CD Tradicional

| Escenario | CI/CD Tradicional | GitOps |
|-----------|------------------|--------|
| Deployment de aplicaciones | Muy adecuado | Muy adecuado |
| Gestión de infraestructura | Limitado | Ideal |
| Multi-cluster | Complejo | Nativo |
| Rollback de configuración | Manual | `git revert` |
| Compliance y auditoría | Básico | Excelente |
| Detección de drift | No | Sí (automático) |
| Equipo pequeño, startup | Suficiente | Puede ser exceso |
| Equipo grande, enterprise | Insuficiente | Necesario |

La combinación ideal es CI/CD + GitOps: CI/CD maneja el build, test y el push de la imagen al registro; GitOps maneja el deployment y la operación continua del cluster.

```
                    CI/CD se detiene aquí
                              │
Commit ──▶ Build ──▶ Test ──▶ │ Push imagen al registro
                              │
                              ▼
                    GitOps toma el relevo
                              │
                     Developer actualiza
                     image tag en Git repo
                              │
                              ▼
                        ArgoCD detecta
                        el cambio en Git
                              │
                              ▼
                       Despliega la nueva
                       imagen al cluster
```

---

## GitOps con ArgoCD

### Arquitectura Interna de ArgoCD

ArgoCD es un controlador de Kubernetes que implementa el modelo de reconciliación de GitOps. Sus componentes internos son:

```
┌─────────────────────────────────────────────────┐
│                    ArgoCD                         │
│                                                   │
│  ┌──────────────┐     ┌──────────────────────┐   │
│  │  API Server  │     │    Repo Server        │   │
│  │              │     │                      │   │
│  │  - REST API  │     │  - Clona repos Git   │   │
│  │  - gRPC API  │     │  - Renderiza Helm    │   │
│  │  - Auth JWT  │     │  - Renderiza Kustomize│   │
│  │  - RBAC      │     │  - Renderiza Jsonnet  │   │
│  └──────┬───────┘     └──────────────────────┘   │
│         │                                         │
│  ┌──────▼───────┐     ┌──────────────────────┐   │
│  │   UI Web     │     │  Application          │   │
│  │              │     │  Controller           │   │
│  │  - Dashboard │     │                      │   │
│  │  - App tree  │     │  - Reconcile loop    │   │
│  │  - Sync ops  │     │  - Compara desired   │   │
│  │  - Diff view │     │    vs live state     │   │
│  └──────────────┘     │  - Dispara syncs     │   │
│                        │  - Health checks     │   │
│                        └──────────────────────┘   │
└─────────────────────────────────────────────────┘
         │                         │
         │ kubeconfig              │ kubectl apply
         ▼                         ▼
   Usuarios/CI             Cluster Kubernetes
   (UI, CLI, API)          (aplica cambios)
```

**API Server**: expone la API REST y gRPC de ArgoCD. Maneja autenticación (SSO con OIDC, LDAP, SAML), autorización con RBAC propio de ArgoCD, y coordina las operaciones de sync.

**Repo Server**: clona y gestiona los repositorios Git. Renderiza templates: si la aplicación usa Helm, ejecuta `helm template`; si usa Kustomize, ejecuta `kustomize build`; si son manifiestos raw, los lee directamente. El Repo Server es stateless — no guarda estado entre renders.

**Application Controller**: el núcleo de GitOps. Ejecuta un loop de reconciliación continuo. Compara el estado deseado (lo que está en Git, renderizado por el Repo Server) con el estado real (lo que está en el cluster via kubectl). Si hay diferencia, o aplica automáticamente (si `automated` está configurado) o marca la aplicación como "OutOfSync" para sync manual.

### Instalación de ArgoCD

```bash
# Crear namespace dedicado para ArgoCD
kubectl create namespace argocd

# Instalar ArgoCD con los manifiestos oficiales
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Verificar que todos los Pods están Running
kubectl get pods -n argocd
# NAME                                               READY   STATUS    RESTARTS
# argocd-application-controller-0                   1/1     Running   0
# argocd-applicationset-controller-7d8bc89b5-xxxx   1/1     Running   0
# argocd-dex-server-6d8446987-xxxx                  1/1     Running   0
# argocd-notifications-controller-6c4b8c884-xxxx    1/1     Running   0
# argocd-redis-7d8d46875f-xxxx                      1/1     Running   0
# argocd-repo-server-7697899f84-xxxx                1/1     Running   0
# argocd-server-7c4d876694-xxxx                     1/1     Running   0

# Exponer ArgoCD Server (para acceso desde fuera del cluster)
# Opción 1: LoadBalancer (AKS)
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'

# Opción 2: Port-forward para acceso local
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Obtener password inicial del admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Salida de ejemplo:
# x8Kp2mNqR7vLtZ9w

# Login con CLI de ArgoCD
argocd login localhost:8080 \
  --username admin \
  --password x8Kp2mNqR7vLtZ9w \
  --insecure

# Cambiar password del admin (obligatorio en producción)
argocd account update-password
```

### El Application CRD: Campo por Campo

La pieza central de ArgoCD es el Custom Resource `Application`. Cada campo tiene un propósito específico:

```yaml
# Configurar Aplicación en ArgoCD
# Uso: kubectl apply -f argocd-application.yaml -n argocd
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app                    # Nombre de la Application en ArgoCD
  namespace: argocd               # Siempre en el namespace de ArgoCD

  # Finalizer: ArgoCD borrará los recursos K8s cuando se borre la Application
  # Sin esto, borrar la Application NO borra los recursos desplegados
  finalizers:
  - resources-finalizer.argocd.argoproj.io

  labels:
    team: backend                 # Para filtrar en la UI de ArgoCD
    environment: production

spec:
  # Project: agrupación lógica de Applications con RBAC propio
  # "default" es el project por defecto (sin restricciones)
  project: default

  source:
    # URL del repositorio Git (HTTPS o SSH)
    repoURL: https://github.com/mi-usuario/mi-repo-k8s

    # Rama, tag, o commit SHA al que apuntar
    # HEAD = siempre la última versión de la rama configurada
    targetRevision: HEAD

    # Directorio dentro del repo que contiene los manifiestos
    # ArgoCD renderizará todo lo que encuentre aquí
    path: k8s/overlays/production

    # Si se usa Helm en lugar de manifiestos raw:
    # helm:
    #   chart: mi-chart
    #   valueFiles:
    #   - values-production.yaml

    # Si se usa Kustomize:
    # kustomize:
    #   images:
    #   - acrk8scourse.azurecr.io/myapp:v1.2.3

  destination:
    # API Server del cluster donde desplegar
    # "https://kubernetes.default.svc" = el cluster donde corre ArgoCD
    server: https://kubernetes.default.svc

    # Namespace donde se crearán los recursos
    namespace: production

  syncPolicy:
    automated:
      # prune: true → ArgoCD eliminará recursos que ya no están en Git
      # Sin esto, los recursos huérfanos (borrados de Git) permanecen en el cluster
      prune: true

      # selfHeal: true → ArgoCD revertirá cambios manuales en el cluster
      # Si alguien hace "kubectl edit", ArgoCD lo detecta y lo revierte
      selfHeal: true

      # allowEmpty: false → protege contra borrar todos los recursos por error
      # Si el directorio en Git queda vacío, no sincronizar
      allowEmpty: false

    syncOptions:
    - CreateNamespace=true       # Crear el namespace si no existe
    - PrunePropagationPolicy=foreground  # Borrar en orden (hijos antes que padres)
    - ApplyOutOfSyncOnly=true    # Optimización: solo aplicar recursos que difieren

    # Retry automático si el sync falla (red, recursos temporalmente no disponibles)
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2          # Backoff exponencial: 5s, 10s, 20s, 40s, 80s
        maxDuration: 3m

  # Ignorar diferencias en campos que Kubernetes modifica automáticamente
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas   # Ignorar si HPA modifica el número de réplicas
```

### Sync Policies y Comportamiento de Reconciliación

El comportamiento de reconciliación de ArgoCD es configurable en detalle:

**Manual Sync (sin `automated`)**: ArgoCD detecta cuando el cluster diverge de Git y muestra la aplicación como "OutOfSync", pero no aplica los cambios automáticamente. Un operador debe hacer el sync manualmente en la UI o con `argocd app sync my-app`. Útil para producción donde se quiere control explícito.

**Automated Sync con prune y selfHeal**: el máximo nivel de automatización. ArgoCD aplica cambios de Git automáticamente, elimina recursos que se borran de Git, y revierte cambios manuales en el cluster.

```bash
# Verificar estado de sync de una aplicación
argocd app get my-app
# Name:              my-app
# Project:           default
# Server:            https://kubernetes.default.svc
# Namespace:         production
# URL:               https://argocd.ejemplo.com/applications/my-app
# Repo:              https://github.com/mi-usuario/mi-repo-k8s
# Target:            HEAD
# Path:              k8s/overlays/production
# SyncWindow:        Sync Allowed
# Sync Policy:       Automated (Prune)
# Sync Status:       Synced to HEAD (a3b2c1d)
# Health Status:     Healthy

# Forzar sync manual (útil para aplicar cambios de forma inmediata)
argocd app sync my-app

# Ver historial de syncs
argocd app history my-app
# ID  DATE                           REVISION
# 1   2024-01-15 09:00:00 +0000 UTC  a3b2c1d (HEAD)
# 2   2024-01-14 15:30:00 +0000 UTC  f1e2d3c
# 3   2024-01-13 11:15:00 +0000 UTC  9b8a7c6

# Rollback a una revisión anterior (por ID del historial)
argocd app rollback my-app 2
```

### App of Apps: Gestionar Múltiples Aplicaciones

En entornos con muchas aplicaciones (microservicios), el patrón "App of Apps" permite que una Application de ArgoCD gestione otras Applications:

```
Git Repo (fleet-config):
└── apps/
    ├── root-app.yaml         ← La Application "raíz" que ArgoCD gestiona
    └── apps/
        ├── frontend-app.yaml     ← Application para el frontend
        ├── backend-app.yaml      ← Application para el backend
        ├── database-app.yaml     ← Application para la DB
        └── monitoring-app.yaml   ← Application para Prometheus + Grafana
```

```yaml
# apps/root-app.yaml
# La Application raíz gestiona el directorio apps/apps/
# Que contiene otras Applications
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/mi-org/fleet-config
    targetRevision: HEAD
    path: apps/apps  # Directorio con las sub-Applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd  # Las Applications se crean en el namespace de ArgoCD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Cuando se hace un commit que añade un nuevo archivo `apps/apps/nuevo-servicio-app.yaml`, ArgoCD detecta el cambio en `root-app`, crea la nueva Application, y esa Application a su vez despliega el nuevo servicio. Todo el ciclo de vida de una nueva aplicación se gestiona con un commit a Git.

### Sync Waves y Hooks para Ordenar el Deployment

En aplicaciones complejas, algunas cosas deben desplegarse antes que otras: las migraciones de base de datos deben ejecutarse antes que la aplicación que las necesita; el namespace y RBAC deben existir antes que los Deployments.

```yaml
# Las sync waves controlan el orden de deployment
# Los recursos con waves más bajas se despliegan primero

# Wave 1: Namespace y RBAC (infraestructura básica)
apiVersion: v1
kind: Namespace
metadata:
  name: production
  annotations:
    argocd.argoproj.io/sync-wave: "1"
---
# Wave 2: ConfigMaps y Secrets (configuración)
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
  annotations:
    argocd.argoproj.io/sync-wave: "2"
---
# Wave 3: Migraciones de base de datos (Job)
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  namespace: production
  annotations:
    argocd.argoproj.io/sync-wave: "3"
    argocd.argoproj.io/hook: PreSync       # Ejecutar antes del sync principal
    argocd.argoproj.io/hook-delete-policy: HookSucceeded  # Borrar Job si éxito
spec:
  template:
    spec:
      containers:
      - name: migration
        image: acrk8scourse.azurecr.io/myapp:v1.2.3
        command: ["npm", "run", "migrate"]
      restartPolicy: Never
---
# Wave 5: La aplicación (después de migración)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
  annotations:
    argocd.argoproj.io/sync-wave: "5"
spec:
  replicas: 3
  # ...
```

### ArgoCD Projects: Aislamiento Multi-Equipo

En organizaciones con múltiples equipos, los Projects de ArgoCD proporcionan aislamiento y control de acceso:

```yaml
# Proyecto para el equipo de backend
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-backend
  namespace: argocd
spec:
  description: "Proyecto para el equipo de Backend"

  # Solo puede desplegar desde estos repositorios
  sourceRepos:
  - 'https://github.com/mi-org/backend-app'
  - 'https://github.com/mi-org/shared-config'

  # Solo puede desplegar a estos clusters y namespaces
  destinations:
  - namespace: backend-prod
    server: https://kubernetes.default.svc
  - namespace: backend-staging
    server: https://kubernetes.default.svc

  # No puede crear ClusterRoles ni modificar Namespaces
  # (solo recursos dentro de namespaces, no cluster-level)
  clusterResourceWhitelist: []
  namespaceResourceBlacklist:
  - group: ''
    kind: ResourceQuota   # No puede cambiar los quotas (los gestiona Platform)

  # Roles dentro del proyecto
  roles:
  - name: developer
    description: "Desarrolladores del equipo backend"
    policies:
    - p, proj:team-backend:developer, applications, get, team-backend/*, allow
    - p, proj:team-backend:developer, applications, sync, team-backend/*, allow
    groups:
    - team-backend-devs  # Grupo de GitHub/LDAP
```

---

## Flux como Alternativa a ArgoCD

Flux v2 (también conocido como Flux CD) es otra implementación popular de GitOps. A diferencia de ArgoCD (que es una aplicación monolítica con UI integrada), Flux adopta un enfoque "toolkit": un conjunto de controladores especializados que cada uno gestiona un aspecto de GitOps.

### Arquitectura de Flux v2 (GitOps Toolkit)

```
Flux GitOps Toolkit:

┌─────────────────────────────────────────────────┐
│                Flux Controllers                   │
│                                                   │
│  ┌─────────────────┐   ┌─────────────────────┐   │
│  │  Source          │   │  Kustomize           │   │
│  │  Controller      │   │  Controller          │   │
│  │                 │   │                     │   │
│  │  - GitRepository│   │  - Kustomization     │   │
│  │  - HelmRepository│  │    CRD              │   │
│  │  - Bucket       │   │  - Aplica overlays  │   │
│  └────────┬────────┘   └──────────┬──────────┘   │
│           │                        │               │
│  ┌────────▼────────┐   ┌──────────▼──────────┐   │
│  │  Helm            │   │  Notification        │   │
│  │  Controller      │   │  Controller          │   │
│  │                 │   │                     │   │
│  │  - HelmRelease  │   │  - Alertas Slack    │   │
│  │  - Helm charts  │   │  - Webhooks         │   │
│  │  - Rollbacks    │   │  - Alertmanager     │   │
│  └─────────────────┘   └─────────────────────┘   │
│                                                   │
│  ┌─────────────────────────────────────────────┐  │
│  │  Image Automation Controller                  │  │
│  │  - ImageRepository: monitorea registry       │  │
│  │  - ImagePolicy: filtra tags (semver, regex)   │  │
│  │  - ImageUpdateAutomation: PR o push a Git    │  │
│  └─────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

El Image Automation Controller es una característica destacada de Flux: puede monitorear un container registry y cuando detecta una nueva imagen (que coincide con una policy como `semver:>=1.0.0`), automáticamente actualiza el YAML en Git y hace commit+push. Esto cierra el loop entre CI (push de imagen) y GitOps (actualización del manifest en Git).

### Comparación: ArgoCD vs Flux

| Característica | ArgoCD | Flux v2 |
|----------------|--------|---------|
| UI integrada | Sí (completa) | No (opcional con Weave GitOps) |
| Multi-cluster | Sí (nativo) | Sí (nativo) |
| Soporte Helm | Sí | Sí (nativo, HelmRelease CRD) |
| Soporte Kustomize | Sí | Sí (nativo, Kustomization CRD) |
| Image automation | Sí (Image Updater) | Sí (nativo, Image* CRDs) |
| Notificaciones | Webhooks + UI | Provider CRDs (Slack, Teams, etc.) |
| RBAC | RBAC propio de ArgoCD | RBAC nativo de Kubernetes |
| Multi-tenancy | Projects + RBAC | Namespace isolation |
| Curva de aprendizaje | Media (UI facilita) | Alta (todo via manifiestos) |
| Arquitectura | Monolítica | Modular (toolkit) |
| Bootstrap | Manual o Helm | CLI (`flux bootstrap`) |
| Comunidad CNCF | Graduated | Graduated |

**¿Cuándo preferir Flux?** Cuando el equipo tiene preferencia por el modelo Kubernetes-native (todo son CRDs y kubectl), cuando se necesita el Image Automation Controller para cerrar el loop CI/CD automáticamente, o cuando se prefiere un modelo más modular y sin UI por defecto.

**¿Cuándo preferir ArgoCD?** Cuando la UI es importante para el equipo, cuando se necesita un modelo de multi-tenancy más sofisticado (Projects), o cuando el equipo tiene experiencia previa con ArgoCD.

### Instalación y Bootstrap de Flux

```bash
# Instalar el CLI de Flux
curl -s https://fluxcd.io/install.sh | sudo bash

# Verificar que el cluster es compatible con Flux
flux check --pre
# ► checking prerequisites
# ✔ Kubernetes 1.28.5 >=1.26.0-0
# ✔ prerequisites checks passed

# Bootstrap de Flux con GitHub
# Esto crea el repositorio si no existe, instala Flux en el cluster,
# y configura Flux para reconciliarse desde ese repositorio
flux bootstrap github \
  --owner=mi-usuario \
  --repository=fleet-infra \
  --branch=main \
  --path=clusters/production \
  --personal   # Para repositorios personales (no de organización)

# El bootstrap:
# 1. Crea el repo GitHub (si no existe)
# 2. Genera claves SSH para que Flux acceda al repo
# 3. Instala los controllers de Flux en el namespace flux-system
# 4. Hace commit del manifiesto de instalación al repo

# Verificar que Flux está corriendo
flux check
# ► checking prerequisites
# ✔ Kubernetes 1.28.5 >=1.26.0-0
# ► checking controllers
# ✔ helm-controller: deployment ready
# ✔ kustomize-controller: deployment ready
# ✔ notification-controller: deployment ready
# ✔ source-controller: deployment ready
# ✔ image-automation-controller: deployment ready
# ✔ image-reflector-controller: deployment ready
# ✔ all checks passed
```

### Ejemplo Completo: Desplegar una Aplicación con Flux

```yaml
# clusters/production/myapp/gitrepository.yaml
# Flux Source Controller: monitorear el repositorio de manifiestos
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: myapp-config
  namespace: flux-system
spec:
  interval: 1m              # Verificar cambios en Git cada minuto
  url: https://github.com/mi-org/myapp-config
  ref:
    branch: main
  secretRef:
    name: myapp-git-credentials   # Secret con token de GitHub
---
# clusters/production/myapp/kustomization.yaml
# Flux Kustomize Controller: aplicar los manifiestos del repositorio
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 10m             # Reconciliar cada 10 minutos
  path: ./k8s/overlays/production  # Path dentro del GitRepository
  prune: true               # Borrar recursos removidos de Git
  sourceRef:
    kind: GitRepository
    name: myapp-config
  targetNamespace: production
  healthChecks:             # Verificar que los recursos están healthy
  - apiVersion: apps/v1
    kind: Deployment
    name: myapp
    namespace: production
```

---

## Gestión Multi-Entorno con GitOps

En entornos de producción reales, siempre hay múltiples entornos: desarrollo, staging y producción. GitOps necesita una estrategia clara para gestionar las diferencias de configuración entre entornos.

### Estructura de Repositorios para GitOps

Hay dos patrones principales para organizar los repositorios en un setup GitOps:

**Patrón Mono-repo**: un único repositorio contiene tanto el código fuente como los manifiestos de Kubernetes.

```
mi-app/
├── src/                        # Código fuente de la aplicación
├── Dockerfile
├── azure-pipelines.yml         # Pipeline CI/CD
└── k8s/                        # Manifiestos de Kubernetes
    ├── base/
    │   ├── kustomization.yaml
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── configmap.yaml
    └── overlays/
        ├── dev/
        │   ├── kustomization.yaml
        │   └── patches/
        │       └── replicas.yaml    # 1 réplica en dev
        ├── staging/
        │   ├── kustomization.yaml
        │   └── patches/
        │       └── replicas.yaml    # 2 réplicas en staging
        └── production/
            ├── kustomization.yaml
            └── patches/
                ├── replicas.yaml    # 5 réplicas en producción
                └── resources.yaml   # Más CPU/memoria en producción
```

**Patrón Fleet/Config repo separado**: el código fuente está en un repositorio, y los manifiestos de Kubernetes para todos los servicios están en un repositorio de configuración separado.

```
fleet-config/                        # Repositorio de configuración (GitOps)
├── clusters/
│   ├── dev/
│   │   └── apps/
│   │       ├── frontend.yaml        # Application ArgoCD o Kustomization Flux
│   │       ├── backend.yaml
│   │       └── database.yaml
│   ├── staging/
│   │   └── apps/
│   │       ├── frontend.yaml
│   │       ├── backend.yaml
│   │       └── database.yaml
│   └── production/
│       └── apps/
│           ├── frontend.yaml
│           ├── backend.yaml
│           └── database.yaml
└── services/
    ├── frontend/
    │   ├── base/
    │   └── overlays/
    ├── backend/
    │   ├── base/
    │   └── overlays/
    └── database/
        ├── base/
        └── overlays/
```

El patrón de repositorio separado es preferido en organizaciones grandes porque permite gestionar el acceso al repositorio de configuración de forma independiente del código fuente, y un único equipo de Platform puede ser owner del repo de configuración.

### ArgoCD ApplicationSet para Múltiples Entornos

ApplicationSet es una extensión de ArgoCD que permite crear múltiples Applications de forma dinámica usando generadores (List, Git, Cluster, Pull Request):

```yaml
# ApplicationSet que crea una Application por cada entorno
# Útil para gestionar dev/staging/production con una sola definición
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: myapp-environments
  namespace: argocd
spec:
  generators:
  # List generator: definir explícitamente los entornos
  - list:
      elements:
      - environment: dev
        namespace: development
        replicas: "1"
        cluster: https://dev-cluster.ejemplo.com
      - environment: staging
        namespace: staging
        replicas: "2"
        cluster: https://staging-cluster.ejemplo.com
      - environment: production
        namespace: production
        replicas: "5"
        cluster: https://prod-cluster.ejemplo.com

  template:
    metadata:
      # Nombre de la Application: myapp-dev, myapp-staging, myapp-production
      name: 'myapp-{{environment}}'
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/mi-org/mi-app
        targetRevision: HEAD
        # Path con el overlay del entorno correspondiente
        path: 'k8s/overlays/{{environment}}'
      destination:
        server: '{{cluster}}'
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          # selfHeal solo en producción (en dev los desarrolladores pueden hacer cambios manuales)
          selfHeal: '{{environment}}' == 'production'
```

### Promover Cambios entre Entornos

En GitOps, "promover" un cambio de dev a staging a producción significa actualizar la referencia a la imagen (o el overlay de configuración) en el repositorio Git para cada entorno:

```bash
# Flujo de promoción de una nueva versión

# 1. CI/CD construye y publica imagen con tag del commit SHA
IMAGE_TAG="sha-abc1234"
docker push acrk8scourse.azurecr.io/myapp:${IMAGE_TAG}

# 2. Actualizar el overlay de dev en el repositorio de configuración
# (Esto puede hacerlo automáticamente el pipeline de CI o el Image Automation de Flux)
cd fleet-config
kustomize edit set image myapp=acrk8scourse.azurecr.io/myapp:${IMAGE_TAG} \
  --kustomization-file services/backend/overlays/dev/kustomization.yaml

git add services/backend/overlays/dev/kustomization.yaml
git commit -m "feat: Update backend image to ${IMAGE_TAG} in dev"
git push

# ArgoCD/Flux detecta el cambio y despliega automáticamente en dev

# 3. Después de validar en dev, promover a staging
kustomize edit set image myapp=acrk8scourse.azurecr.io/myapp:${IMAGE_TAG} \
  --kustomization-file services/backend/overlays/staging/kustomization.yaml

git add services/backend/overlays/staging/kustomization.yaml
git commit -m "feat: Promote backend ${IMAGE_TAG} to staging"
git push

# 4. Después de aprobación QA, promover a producción
# (Normalmente via Pull Request con revisión obligatoria)
git checkout -b promote/backend-${IMAGE_TAG}-to-production
kustomize edit set image myapp=acrk8scourse.azurecr.io/myapp:${IMAGE_TAG} \
  --kustomization-file services/backend/overlays/production/kustomization.yaml

git add services/backend/overlays/production/kustomization.yaml
git commit -m "feat: Promote backend ${IMAGE_TAG} to production"
git push --set-upstream origin promote/backend-${IMAGE_TAG}-to-production

# Crear Pull Request → Tech Lead aprueba → Merge → ArgoCD despliega en producción
```

---

## Troubleshooting CI/CD y GitOps

Los problemas en CI/CD y GitOps tienen patrones reconocibles. A continuación, los seis escenarios más comunes con diagnóstico y solución.

### Escenario 1: ArgoCD Sync Failed — Error de Sintaxis YAML

**Síntomas**: en la UI de ArgoCD, la Application muestra estado "SyncFailed". Al hacer clic en el error se ve un mensaje como `error validating data: ValidationError`.

**Diagnóstico**:

```bash
# Ver el detalle del error de sync en ArgoCD
argocd app get my-app --show-operation

# Salida de ejemplo:
# Message:  one or more objects failed to apply, reason: ...
# error validating data: ValidationError(Deployment.spec.template.spec.containers[0]):
# unknown field "resourcess" in io.k8s.api.core.v1.Container
#
# → Typo: "resourcess" en lugar de "resources"

# Renderizar los manifiestos localmente para detectar errores antes de hacer push
kubectl apply --dry-run=client -f k8s/
# Error from server (BadRequest): error when creating "deployment.yaml":
# Deployment in version "v1" cannot be handled as a Deployment

# Si se usa Kustomize, renderizar localmente:
kustomize build k8s/overlays/production | kubectl apply --dry-run=client -f -

# Si se usa Helm, renderizar localmente:
helm template my-release ./helm-chart --values values-production.yaml \
  | kubectl apply --dry-run=client -f -
```

**Solución**: corregir el error de sintaxis en el YAML, hacer commit y push. ArgoCD reintentará el sync automáticamente.

**Prevención**: añadir un paso de validación en el pipeline CI que ejecute `kubectl apply --dry-run=client` antes de hacer commit a la rama principal. Herramientas como `kubeval` o `kube-score` también detectan errores de schema.

### Escenario 2: Image Not Found Durante Deploy

**Síntomas**: el Deployment en Kubernetes tiene Pods en estado `ImagePullBackOff` o `ErrImagePull`.

**Diagnóstico**:

```bash
# Ver el error exacto del Pod
kubectl describe pod -l app=myapp -n production
# Events:
#   Warning  Failed  10s  kubelet  Failed to pull image
#   "acrk8scourse.azurecr.io/myapp:sha-wrongtag":
#   rpc error: code = Unknown desc = failed to pull and unpack image
#   "acrk8scourse.azurecr.io/myapp:sha-wrongtag":
#   unexpected status code 404 Not Found

# Verificar que la imagen existe en el registry
az acr repository show-tags \
  --name acrk8scourse \
  --repository myapp \
  --orderby time_desc \
  --top 5
# sha-abc1234
# sha-def5678
# latest

# Verificar que el tag del Deployment coincide con la imagen que existe
kubectl get deployment myapp -n production \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
# acrk8scourse.azurecr.io/myapp:sha-wrongtag  ← Tag incorrecto

# Verificar que el Secret de ACR está configurado correctamente
kubectl get secret acr-secret -n production -o yaml
kubectl get serviceaccount default -n production -o yaml
# Verificar que imagePullSecrets incluye acr-secret
```

**Solución**: corregir el tag de la imagen en el manifiesto. Si el tag es correcto pero la imagen no existe, el step de `docker push` del pipeline falló silenciosamente. Revisar los logs del pipeline de CI.

**Prevención**:
1. El pipeline de CI debe verificar explícitamente que el push fue exitoso antes de continuar al stage de deploy.
2. En AKS, usar la integración nativa con ACR en lugar de imagePullSecrets: `az aks update -n aks-cluster -g rg-grupo --attach-acr acrk8scourse`.

```bash
# Verificar integración AKS-ACR
az aks check-acr \
  --name aks-k8s-course \
  --resource-group rg-kubernetes-course \
  --acr acrk8scourse.azurecr.io
```

### Escenario 3: Pipeline Timeout — Build Demasiado Lento

**Síntomas**: el pipeline falla por timeout en el stage de Build. El `docker build` tarda 15-20 minutos cuando antes tardaba 3.

**Diagnóstico**:

```bash
# Ver el tiempo de cada layer en el build log:
# Step 1/10 : FROM node:20-alpine
#  ---> Using cache          ← Cache hit: rápido
# Step 2/10 : WORKDIR /app
#  ---> Running in xxx       ← Sin cache: lento
# Step 3/10 : COPY package*.json ./
#  ---> Running in xxx
# Step 4/10 : RUN npm install  ← Aquí está el problema: sin cache descarga todo
#  ---> Running in xxx (14 minutos)

# El problema: el Dockerfile tiene COPY . . antes de npm install
# Cualquier cambio en el código fuente invalida el cache de npm install
```

**Causa raíz**: el Dockerfile no está optimizado para el cache de capas de Docker. Si `COPY . .` está antes de `npm install`, cualquier cambio en cualquier archivo de código fuente invalida el cache de npm, forzando una reinstalación completa de dependencias.

**Solución: optimizar el Dockerfile para usar cache**:

```dockerfile
# Dockerfile INCORRECTO (cache ineficiente)
FROM node:20-alpine
WORKDIR /app
COPY . .              # Copia TODO primero → invalida cache de npm install en cada commit
RUN npm install       # Se ejecuta SIEMPRE aunque package.json no cambió
RUN npm run build

# Dockerfile CORRECTO (cache eficiente)
FROM node:20-alpine
WORKDIR /app

# 1. Copiar SOLO los archivos de dependencias primero
# Esta capa solo se invalida cuando package.json o package-lock.json cambian
COPY package*.json ./
RUN npm ci --only=production   # Cache hit en el 90% de los commits

# 2. Copiar el código fuente después
# Esta capa se invalida en cada commit, pero las dependencias ya están cacheadas
COPY . .
RUN npm run build

# 3. Imagen final ligera (multi-stage build)
FROM node:20-alpine AS runtime
WORKDIR /app
COPY --from=0 /app/dist ./dist
COPY --from=0 /app/node_modules ./node_modules
CMD ["node", "dist/main.js"]
```

Además, configurar Docker BuildKit con cache en el registry de CI/CD:

```yaml
# En Azure DevOps:
- task: Docker@2
  inputs:
    command: buildAndPush
    arguments: '--cache-from=$(containerRegistry)/$(imageRepository):cache'

# En GitHub Actions:
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha          # Cache en GitHub Actions Cache
    cache-to: type=gha,mode=max
```

### Escenario 4: Drift Detectado Pero No Corregido

**Síntomas**: ArgoCD muestra la aplicación como "OutOfSync" pero no la sincroniza automáticamente aunque se configuró `automated: true`.

**Diagnóstico**:

```bash
# Ver el estado detallado de la sincronización
argocd app get my-app
# Sync Status: OutOfSync from HEAD (a3b2c1d)
# Health Status: Healthy
# Sync Policy: Automated

# Ver qué recursos están fuera de sync
argocd app diff my-app
# ===== apps/Deployment production/myapp ======
# 4,5c4,5
# <   replicas: 5          ← Valor en Git
# >   replicas: 3          ← Valor real en cluster (alguien lo cambió manualmente)

# Verificar si hay SyncWindows que estén bloqueando el sync
argocd app get my-app -o json | jq '.status.sync.status, .status.operationState'

# Verificar la política real de la Application
kubectl get application my-app -n argocd -o jsonpath='{.spec.syncPolicy}'
# {"automated":{"prune":false,"selfHeal":false}}
# → selfHeal: false! No corrige drift automáticamente
```

**Causa**: `selfHeal: false` (o ausente) en la política de sync. ArgoCD detecta el drift pero no lo corrige porque `selfHeal` no está habilitado. Además, verificar si hay SyncWindows configuradas que bloqueen syncs en ciertos horarios.

**Solución**:

```bash
# Habilitar selfHeal en la Application
argocd app set my-app --self-heal

# O editar el manifiesto YAML de la Application en Git:
# syncPolicy:
#   automated:
#     prune: true
#     selfHeal: true   ← Añadir esto

# Si el problema es una SyncWindow bloqueante:
argocd app sync my-app --force  # Forzar sync ignorando SyncWindows
```

### Escenario 5: Rollback Necesario en Producción

**Síntomas**: se desplegó una nueva versión a producción y hay errores en las métricas (latencia alta, error rate aumentado).

**Diagnóstico y Rollback**:

```bash
# Opción 1: Rollback via ArgoCD (recomendado con GitOps)
# Ver el historial de syncs de la Application
argocd app history my-app
# ID  DATE                           REVISION
# 5   2024-01-20 14:30:00 +0000 UTC  a3b2c1d ← Versión actual (problemática)
# 4   2024-01-19 10:15:00 +0000 UTC  f1e2d3c ← Versión anterior (estable)
# 3   2024-01-18 09:00:00 +0000 UTC  9b8a7c6

# Rollback a la versión anterior (ID 4)
argocd app rollback my-app 4
# TIMESTAMP                  GROUP  KIND        NAMESPACE  NAME    STATUS   HEALTH
# 2024-01-20T14:35:00+00:00  apps   Deployment  production myapp   Synced   Healthy

# Opción 2: git revert (mejor para GitOps puro — el rollback queda en el historial de Git)
cd fleet-config
git log --oneline -5
# a3b2c1d feat: Update myapp image to sha-badcommit
# f1e2d3c feat: Update myapp image to sha-goodversion
# 9b8a7c6 feat: Previous release

# Revertir el commit problemático
git revert a3b2c1d --no-edit
# [main c4d5e6f] Revert "feat: Update myapp image to sha-badcommit"

git push origin main
# ArgoCD detecta el nuevo commit y despliega automáticamente la versión anterior

# Verificar que el rollback fue exitoso
kubectl rollout status deployment/myapp -n production
# deployment "myapp" successfully rolled out

kubectl get pods -n production -l app=myapp
# NAME                      READY   STATUS    RESTARTS
# myapp-6d8f9c8b4-xxxxx     1/1     Running   0
# myapp-6d8f9c8b4-yyyyy     1/1     Running   0
# myapp-6d8f9c8b4-zzzzz     1/1     Running   0
```

**Prevención**: implementar smoke tests automáticos post-deploy. Si las métricas clave (error rate, latencia p99) superan un threshold en los primeros 5 minutos después del deploy, ejecutar el rollback automáticamente.

### Escenario 6: Webhook no Dispara el Pipeline

**Síntomas**: se hace `git push` pero el pipeline de CI/CD no se dispara automáticamente. El pipeline solo se puede iniciar manualmente.

**Diagnóstico**:

```bash
# Para GitHub Actions: verificar que el workflow file está en la rama correcta
# y en el path correcto
ls .github/workflows/
# deploy-aks.yml

# Verificar el trigger del workflow
head -10 .github/workflows/deploy-aks.yml
# on:
#   push:
#     branches:
#     - main           ← Solo dispara en main, no en feature branches

# Para Azure DevOps: verificar la configuración del webhook en el repositorio
# En GitHub: Settings → Webhooks → Verificar que el webhook de Azure DevOps está configurado
# Recent Deliveries → Ver si hay entregas fallidas

# Verificar el estado del webhook desde Azure DevOps
# Project Settings → Service Connections → GitHub Connection → Test connection

# Error común: el webhook apunta a una URL obsoleta de Azure DevOps
# URL correcta: https://dev.azure.com/{organization}/_apis/public/hooks/externalevents?publisherId=...
```

**Causas comunes y soluciones**:

1. **El push es a una rama que no está en el trigger**: el workflow tiene `branches: [main]` pero el push fue a `feature/nueva-feature`. Solución: ajustar el trigger para incluir las ramas deseadas, o hacer merge a main.

2. **El webhook fue desconfigurado** (deleteo y recreación del repositorio, cambio de organización): ir a Settings → Webhooks en GitHub y verificar que el webhook de Azure DevOps/GitHub Actions tiene estado verde y que las últimas entregas fueron exitosas.

3. **Hay un error de sintaxis en el workflow YAML**: GitHub Actions no dispara el workflow si el YAML tiene errores de sintaxis (incluso si son solo en los jobs que no se triggearían). Ir a Actions → Workflows para ver si hay errores de parsing.

4. **El pipeline file no está en la rama correcta**: para Azure DevOps, verificar que `azure-pipelines.yml` está en la rama que triggea el pipeline. Para GitHub Actions, verificar que el workflow está en `.github/workflows/` en la rama con el push.

```bash
# Disparar pipeline manualmente para verificar que funciona (descarta problema de webhook)
# GitHub CLI:
gh workflow run deploy-aks.yml --ref main

# Azure DevOps CLI:
az pipelines run \
  --name "Mi Pipeline" \
  --branch main \
  --org https://dev.azure.com/mi-org \
  --project mi-proyecto
```

---

## Resumen del Capítulo

CI/CD y GitOps son los dos pilares de la automatización de despliegues en Kubernetes. Se complementan: CI/CD se encarga del ciclo de build, test y publicación de artefactos (imágenes Docker); GitOps se encarga del ciclo de despliegue y operación continua del cluster.

**Los problemas de los deployments manuales** son fundamentales y recurrentes: error humano (cluster equivocado, namespace equivocado), deriva entre entornos, ausencia de audit trail, falta de plan de rollback, y acceso directo a producción sin proceso de aprobación. Estos problemas no se resuelven con mejores procedimientos manuales — se resuelven con automatización.

**El pipeline CI/CD** automatiza las fases de Build (imagen Docker + push a registry), Test (unitarios, integración, E2E), Scan (vulnerabilidades de contenedor con Trivy, calidad de código con SonarQube), y Deploy (kubectl apply, Helm, Kustomize). Azure DevOps y GitHub Actions son las dos plataformas principales para AKS, ambas con soporte nativo para autenticación via Azure AD y despliegue a AKS.

**GitOps** declara el estado completo del cluster en un repositorio Git y usa un operador (ArgoCD, Flux) que reconcilia continuamente el cluster hacia ese estado deseado. El modelo Pull de GitOps tiene ventajas de seguridad significativas sobre el modelo Push de CI/CD tradicional: el cluster no necesita exponer su API a pipelines externos, y el operador GitOps solo necesita acceso de lectura a Git.

**ArgoCD** es la implementación más popular de GitOps, con UI integrada, soporte para Helm y Kustomize, sync policies configurables (manual, automated con prune y selfHeal), sync waves para ordenar el despliegue de recursos, hooks para migraciones de base de datos, y Projects para aislamiento multi-equipo. **Flux v2** es una alternativa modular con Image Automation nativo para cerrar el loop CI/CD automáticamente.

**La gestión multi-entorno** se implementa con Kustomize overlays (base + dev/staging/production) y la promoción de cambios entre entornos mediante commits a Git — idealmente via Pull Requests con revisión obligatoria para producción.

**Los patrones de troubleshooting** más comunes son: sync failed por errores de sintaxis YAML (prevenir con `kubectl apply --dry-run`), image not found por tags incorrectos o falta de autenticación con el registry, pipeline timeout por Dockerfiles sin optimización de cache, drift no corregido por `selfHeal: false`, y webhooks que no disparan por configuración incorrecta del trigger o del webhook.

Con CI/CD y GitOps completamente implementados, el equipo puede desplegar a producción con confianza, revertir cualquier cambio con un `git revert`, y garantizar que el estado del cluster en cualquier momento es exactamente lo que está descrito en Git — auditable, reproducible y libre de errores humanos.
