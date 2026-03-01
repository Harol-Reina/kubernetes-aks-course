# Capítulo 38: CI/CD y GitOps

La operación manual es insostenible a escala. CI/CD automatiza el ciclo build-test-deploy, y GitOps lleva un paso más allá: el estado deseado del cluster vive en Git, y un operador lo reconcilia automáticamente.

---

## Azure DevOps con AKS

### Pipeline YAML para Kubernetes

```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
  dockerRegistryServiceConnection: 'acrConnection'
  imageRepository: 'myapp'
  containerRegistry: 'acrk8scourse.azurecr.io'
  dockerfilePath: '**/Dockerfile'
  tag: '$(Build.BuildId)'
  kubernetesServiceConnection: 'aksConnection'

stages:
- stage: Build
  displayName: Build and push image
  jobs:
  - job: Build
    steps:
    - task: Docker@2
      displayName: Build and push image
      inputs:
        command: buildAndPush
        repository: $(imageRepository)
        dockerfile: $(dockerfilePath)
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(tag)
          latest

- stage: Deploy
  displayName: Deploy to AKS
  dependsOn: Build
  jobs:
  - deployment: Deploy
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: Deploy to Kubernetes cluster
            inputs:
              action: deploy
              kubernetesServiceConnection: $(kubernetesServiceConnection)
              manifests: |
                k8s/deployment.yaml
                k8s/service.yaml
              containers: |
                $(containerRegistry)/$(imageRepository):$(tag)
```

## GitOps con ArgoCD

### Instalación de ArgoCD

```bash
# Crear namespace
kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Exponer ArgoCD Server
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Obtener password inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Configurar Aplicación en ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mi-usuario/mi-repo-k8s
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

---

## Resumen del Capítulo

CI/CD con Azure DevOps automatiza el ciclo de vida: build de imagen Docker, push al registro, y deploy a AKS. GitOps con ArgoCD va más allá: el repositorio Git es la fuente de verdad, y ArgoCD reconcilia continuamente el estado del cluster con lo declarado en Git. La combinación de ambos proporciona despliegues reproducibles, auditables y reversibles.
