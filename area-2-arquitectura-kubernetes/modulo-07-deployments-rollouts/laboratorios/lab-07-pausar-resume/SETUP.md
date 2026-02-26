# Prerequisitos - Lab 07: Troubleshooting de Deployments

## Conocimientos Previos

- Laboratorios 1 al 6 del modulo completados (especialmente Lab 02: Rolling Updates)
- Conocimiento solido de Deployments y ReplicaSets
- Familiaridad con readinessProbe y livenessProbe
- Comprension basica de SecurityContext y recursos (requests/limits)

## Herramientas Necesarias

- Minikube o cluster Kubernetes funcional
- kubectl configurado y conectado al cluster
- Dos terminales disponibles (una para comandos, otra para `watch`)
- `watch` disponible en el sistema (incluido por defecto en Linux)

## Verificacion del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar permisos para crear namespaces
kubectl auth can-i create namespaces

# Verificar que kubectl esta configurado
kubectl get nodes

# Verificar archivos YAML del laboratorio
ls -la /ruta/al/lab-07-pausar-resume/*.yaml
```

**Output esperado del ultimo comando**:
```
broken-image.yaml
broken-readiness.yaml
oom-deployment.yaml
stuck-rollout.yaml
selector-mismatch.yaml
selector-mismatch-fixed.yaml
permission-issue.yaml
permission-issue-fixed.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 8 archivos YAML que demuestran problemas comunes en Deployments:

| Archivo | Ejercicio | Problema que demuestra |
|---------|-----------|----------------------|
| `broken-image.yaml` | Ejercicio 1 | ImagePullBackOff por imagen inexistente |
| `broken-readiness.yaml` | Ejercicio 2 | Pods Running pero NOT Ready (readiness probe falla) |
| `oom-deployment.yaml` | Ejercicio 3 | OOMKilled / CrashLoopBackOff por limite de memoria bajo |
| `stuck-rollout.yaml` | Ejercicio 4 | Rollout extremadamente lento (stuck rollout) |
| `selector-mismatch.yaml` | Ejercicio 5 | Error de validacion: selector no coincide con template labels |
| `selector-mismatch-fixed.yaml` | Ejercicio 5 | Version corregida del selector mismatch |
| `permission-issue.yaml` | Ejercicio 6 | CrashLoopBackOff por SecurityContext sin volumenes de escritura |
| `permission-issue-fixed.yaml` | Ejercicio 6 | Version corregida con emptyDir para paths de escritura |

Cada archivo incluye:
- Comentario de uso al inicio (`# Uso: kubectl apply -f ...`)
- Descripcion del problema que demuestra
- Explicacion del resultado esperado
- Namespace declarado en el manifiesto (`lab-troubleshooting`)

## Preparacion del Entorno

```bash
# Crear namespace para el laboratorio
kubectl create namespace lab-troubleshooting

# Configurar namespace como contexto actual
kubectl config set-context --current --namespace=lab-troubleshooting

# Verificar
kubectl get ns lab-troubleshooting
```

**Output esperado**:
```
NAME                 STATUS   AGE
lab-troubleshooting  Active   5s
```
