# 📚 RESUMEN - Módulo 05 (Área 4): CI/CD y GitOps

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre **CI/CD y GitOps** para Kubernetes — automatización del ciclo de vida de aplicaciones desde el commit hasta producción. Aprenderás pipelines de CI/CD, estrategias de despliegue (rolling, blue-green, canary), y la filosofía GitOps con ArgoCD.

**Duración**: 6 horas (teoría + labs)
**Nivel**: Intermedio-Avanzado
**Prerequisitos**: Deployments, Services, RBAC, kubectl

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Diferenciar entre CI, CD (Delivery) y CD (Deployment)
- ✅ Entender la filosofía GitOps (Git como fuente de verdad)
- ✅ Conocer las estrategias de despliegue principales
- ✅ Entender el concepto de rollback

### Técnico
- ✅ Configurar rolling updates con Deployments
- ✅ Implementar blue-green deployments
- ✅ Realizar canary deployments
- ✅ Hacer rollback con kubectl rollout
- ✅ Configurar ArgoCD para GitOps

---

## 🗺️ Estructura de Aprendizaje

### CI/CD Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│   CODE   │───►│  BUILD   │───►│   TEST   │───►│  DEPLOY  │
│          │    │          │    │          │    │          │
│ git push │    │ docker   │    │ unit     │    │ kubectl  │
│          │    │ build    │    │ integ    │    │ apply    │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
     CI              CI              CI              CD
 (Continuous Integration)        (Continuous Delivery/Deployment)
```

### Estrategias de Despliegue

```
Rolling Update (por defecto):
v1:[■■■] → v1:[■■□] v2:[□] → v1:[■□□] v2:[□□] → v2:[■■■]
                     (gradual, sin downtime)

Blue-Green:
Blue (v1): [■■■] ← tráfico      Blue (v1): [■■■]
Green (v2):[■■■]                 Green (v2):[■■■] ← tráfico
                                 (switch instantáneo)

Canary:
v1: [■■■■■■■■■] ← 90% tráfico   v1: [■■■■■] ← 50%
v2: [■]          ← 10% tráfico   v2: [■■■■■] ← 50%
                                 (incremento gradual)
```

| Estrategia | Ventaja | Desventaja | Uso |
|-----------|---------|------------|-----|
| **Rolling** | Simple, sin downtime | Rollback lento, versiones mixtas | Default para la mayoría |
| **Blue-Green** | Rollback instantáneo, sin versiones mixtas | Doble de recursos temporalmente | Aplicaciones críticas |
| **Canary** | Riesgo controlado, feedback temprano | Más complejo de implementar | Apps de alto tráfico |

---

## 🔧 Comandos Esenciales

### Rolling Updates y Rollbacks

```bash
# Actualizar imagen de un Deployment
kubectl set image deployment/<name> <container>=<new-image>

# Ver estado del rollout
kubectl rollout status deployment/<name>

# Ver historial de rollouts
kubectl rollout history deployment/<name>

# Rollback al deployment anterior
kubectl rollout undo deployment/<name>

# Rollback a una revisión específica
kubectl rollout undo deployment/<name> --to-revision=2

# Pausar/reanudar rollout
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>
```

### Deployment Strategy

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1           # Máximo 1 Pod extra durante update
      maxUnavailable: 0     # 0 Pods no disponibles (safe)
```

---

## 📝 Cheat Sheet: Estrategias

### Rolling Update (YAML)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: app
        image: mi-app:v2
```

### Blue-Green (usando Services)

```bash
# 1. Desplegar versión green
kubectl apply -f deployment-green.yaml

# 2. Verificar que green funciona
kubectl get pods -l version=green

# 3. Cambiar el Service para apuntar a green
kubectl patch service mi-app -p '{"spec":{"selector":{"version":"green"}}}'

# 4. Rollback: cambiar selector a blue
kubectl patch service mi-app -p '{"spec":{"selector":{"version":"blue"}}}'
```

### Canary Deployment

```bash
# 1. Crear Deployment canary con 1 réplica
kubectl apply -f deployment-canary.yaml

# 2. El Service selecciona tanto stable como canary por label app=
# Tráfico se distribuye: 3 stable + 1 canary = 25% canary

# 3. Si funciona, escalar canary y reducir stable
kubectl scale deployment mi-app-canary --replicas=3
kubectl scale deployment mi-app-stable --replicas=0
```

---

## ❗ Problemas Comunes

### 1. Rolling update se queda en progreso
**Causa**: Los nuevos Pods no pasan el readiness probe.
**Diagnóstico**: `kubectl rollout status` + `kubectl describe pod <new-pod>`
**Solución**: Fix del readiness probe o hacer rollback.

### 2. Rollback no funciona
**Causa**: El historial de revisiones fue eliminado (revisionHistoryLimit: 0).
**Solución**: Establecer `revisionHistoryLimit: 10` en el Deployment.

### 3. Blue-Green requiere doble de recursos
**Solución**: Escalar temporalmente el cluster o usar Spot/preemptible nodes para green.

---

## ✅ Checklist

- [ ] Entiendo CI vs CD (Delivery) vs CD (Deployment)
- [ ] Sé configurar rolling updates con maxSurge/maxUnavailable
- [ ] Puedo hacer rollback con kubectl rollout undo
- [ ] Entiendo blue-green y canary deployments
- [ ] Conozco la filosofía GitOps
- [ ] Sé configurar ArgoCD básico

---

## 📝 Preguntas de Repaso

### 1. ¿Cuál es la diferencia entre CI y CD?

<details><summary>Ver respuesta</summary>
**CI (Continuous Integration)**: Automatiza build y tests cada vez que hay un commit. Detecta errores rápidamente.
**CD (Continuous Delivery)**: Automatiza el despliegue a staging/producción. Puede requerir aprobación manual.
**CD (Continuous Deployment)**: Automatiza TODO incluyendo deploy a producción sin aprobación manual.
</details>

### 2. ¿Cuándo usarías canary vs blue-green?

<details><summary>Ver respuesta</summary>
**Canary**: Cuando quieres probar con un porcentaje pequeño de tráfico real antes de hacer deploy completo. Ideal para apps de alto tráfico donde un bug puede afectar a millones de usuarios.
**Blue-Green**: Cuando necesitas switch instantáneo y rollback inmediato. Ideal para apps donde no puedes tener versiones mixtas (ej: cambios de schema de DB).
</details>

### 3. ¿Qué es GitOps y por qué importa?

<details><summary>Ver respuesta</summary>
GitOps usa un repositorio Git como la única fuente de verdad del estado deseado del cluster. Herramientas como ArgoCD observan el repo y sincronizan automáticamente el cluster con lo que está en Git. Beneficios: auditoría completa (git log), rollback fácil (git revert), y workflow familiar para desarrolladores (pull requests).
</details>

---

## 🎓 Certificaciones

- **CKA**: Rolling updates, rollbacks (~10%)
- **CKAD**: Deployment strategies, rolling updates (~15%)
- **AKS**: Azure DevOps pipelines, GitHub Actions, ArgoCD en AKS

---

## 🔗 Siguiente Paso

Este es el último módulo del curso. Continúa con el **Proyecto Final**: aplicación de 3 capas desplegada en AKS usando todos los conceptos aprendidos.
