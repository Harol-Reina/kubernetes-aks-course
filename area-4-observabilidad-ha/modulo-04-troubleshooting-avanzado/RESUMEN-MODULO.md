# 📚 RESUMEN - Módulo 04 (Área 4): Troubleshooting Avanzado

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre **troubleshooting avanzado** en Kubernetes — diagnóstico sistemático de fallos en Pods, nodos, networking y storage. Aprenderás un framework de diagnóstico estructurado y las herramientas para resolver cualquier problema en tu cluster.

**Duración**: 6 horas (teoría + labs)
**Nivel**: Avanzado
**Prerequisitos**: Todos los módulos anteriores

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Aplicar un framework de diagnóstico sistemático
- ✅ Clasificar estados de Pod (Pending, CrashLoopBackOff, etc.)
- ✅ Leer y entender eventos de Kubernetes
- ✅ Correlacionar síntomas con causas raíz

### Técnico
- ✅ Usar kubectl describe, logs, exec, debug
- ✅ Diagnosticar problemas de scheduling (Pending)
- ✅ Resolver CrashLoopBackOff y ImagePullBackOff
- ✅ Depurar problemas de networking y DNS
- ✅ Diagnosticar OOMKilled y nodos con presión de recursos
- ✅ Usar ephemeral containers para debugging

---

## 🗺️ Framework de Diagnóstico

```
¿El Pod está corriendo?
│
├─ NO → ¿Qué estado tiene?
│       ├─ Pending      → Problema de scheduling
│       │                  kubectl describe pod → Events
│       │                  - Recursos insuficientes
│       │                  - NodeSelector/Affinity no match
│       │                  - PVC no bound
│       │
│       ├─ ImagePullBackOff → Problema de imagen
│       │                      - Imagen no existe
│       │                      - Registry privado sin credenciales
│       │                      - Tag incorrecto
│       │
│       ├─ CrashLoopBackOff → Problema de aplicación
│       │                      kubectl logs <pod> --previous
│       │                      - Comando incorrecto
│       │                      - Puerto ocupado
│       │                      - Dependencia no disponible
│       │
│       ├─ OOMKilled → Memoria insuficiente
│       │               - Aumentar limits de memoria
│       │               - Memory leak en la aplicación
│       │
│       └─ CreateContainerConfigError → Config inválida
│                                        - Secret/ConfigMap no existe
│                                        - Key incorrecta
│
├─ SÍ pero no funciona → ¿Qué falla?
│       ├─ No responde → Readiness/Liveness probe
│       ├─ No conecta → Service/Networking/DNS
│       └─ Lento → Resources/throttling
│
└─ SÍ y funciona ✅
```

---

## 🔧 Comandos Esenciales

### Diagnóstico Básico

```bash
# Ver estado de Pods
kubectl get pods -n <ns> -o wide

# Detalles y eventos de un Pod
kubectl describe pod <pod-name> -n <ns>

# Logs del contenedor
kubectl logs <pod-name> -n <ns>
kubectl logs <pod-name> -n <ns> --previous    # contenedor crasheado
kubectl logs <pod-name> -n <ns> -c <container> # contenedor específico

# Ejecutar comando dentro del Pod
kubectl exec <pod-name> -n <ns> -- <comando>
kubectl exec -it <pod-name> -n <ns> -- sh

# Eventos recientes
kubectl get events -n <ns> --sort-by='.lastTimestamp'
```

### Diagnóstico de Nodos

```bash
# Estado de nodos
kubectl get nodes -o wide
kubectl describe node <node-name>

# Recursos del nodo
kubectl top node <node-name>

# Condiciones del nodo
kubectl get node <node-name> -o jsonpath='{.status.conditions[*].type}'

# Pods en un nodo específico
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node>
```

### Diagnóstico de Networking

```bash
# Verificar DNS
kubectl exec <pod> -- nslookup <service-name>
kubectl exec <pod> -- nslookup kubernetes.default

# Verificar conectividad
kubectl exec <pod> -- wget -qO- --timeout=3 http://<service>:<port>
kubectl exec <pod> -- nc -zv <ip> <port>

# Ver endpoints de un Service
kubectl get endpoints <service-name> -n <ns>

# Verificar Network Policies
kubectl get networkpolicies -n <ns>
```

### Debugging Avanzado

```bash
# Ephemeral container para debug (K8s 1.25+)
kubectl debug <pod-name> -n <ns> -it --image=busybox --target=<container>

# Debug de nodo
kubectl debug node/<node-name> -it --image=busybox

# Port-forward para probar un Service
kubectl port-forward svc/<service> 8080:80 -n <ns>

# Copiar archivos desde/hacia un Pod
kubectl cp <pod>:/path/file ./local-file -n <ns>
```

---

## 📝 Tabla de Estados de Pod y Soluciones

| Estado | Causa Común | Comando de Diagnóstico | Solución |
|--------|------------|----------------------|----------|
| **Pending** | Sin recursos | `kubectl describe pod` → Events | Escalar nodos o reducir requests |
| **ImagePullBackOff** | Imagen incorrecta | `kubectl describe pod` → Image | Verificar nombre/tag de imagen |
| **CrashLoopBackOff** | App crashea | `kubectl logs --previous` | Fix del código o configuración |
| **OOMKilled** | Sin memoria | `kubectl describe pod` → Last State | Aumentar memory limit |
| **CreateContainerConfigError** | Config inválida | `kubectl describe pod` → Events | Verificar Secrets/ConfigMaps |
| **Running pero no ready** | Probe falla | `kubectl describe pod` → Conditions | Fix del readiness probe |
| **Evicted** | Nodo sin recursos | `kubectl describe pod` → Status | Agregar nodos o reducir carga |

---

## ❗ Problemas Comunes

### 1. CrashLoopBackOff
**Diagnóstico**: `kubectl logs <pod> --previous`
**Causas comunes**: comando incorrecto, puerto ya en uso, dependencia faltante, error en código.

### 2. Pod en Pending
**Diagnóstico**: `kubectl describe pod <pod>` → Events
**Causas comunes**: recursos insuficientes, nodeSelector sin match, PVC no bound.

### 3. ImagePullBackOff
**Diagnóstico**: `kubectl describe pod <pod>` → Events → "Failed to pull image"
**Causas comunes**: imagen no existe, tag incorrecto, registry privado sin imagePullSecret.

### 4. OOMKilled (exit code 137)
**Diagnóstico**: `kubectl describe pod <pod>` → Last State → Reason: OOMKilled
**Solución**: Aumentar el `limits.memory` o investigar memory leaks.

---

## ✅ Checklist

- [ ] Tengo un framework de diagnóstico sistemático
- [ ] Sé diferenciar entre todos los estados de Pod
- [ ] Domino kubectl describe, logs, exec, debug
- [ ] Puedo diagnosticar problemas de scheduling
- [ ] Sé resolver CrashLoopBackOff e ImagePullBackOff
- [ ] Puedo depurar problemas de networking y DNS
- [ ] Sé diagnosticar OOMKilled y resource pressure

---

## 📝 Preguntas de Repaso

### 1. ¿Cuál es el primer comando que ejecutas cuando un Pod falla?

<details><summary>Ver respuesta</summary>
`kubectl describe pod <pod-name> -n <namespace>`. La sección "Events" al final te dice exactamente qué falló: scheduling, pull de imagen, crash del contenedor, etc.
</details>

### 2. ¿Cómo ves los logs de un contenedor que ya crasheó?

<details><summary>Ver respuesta</summary>
`kubectl logs <pod-name> --previous`. Muestra los logs de la ejecución anterior del contenedor, antes del crash.
</details>

### 3. ¿Qué significa exit code 137?

<details><summary>Ver respuesta</summary>
El contenedor fue terminado por una señal SIGKILL (128 + 9 = 137). La causa más común es OOMKilled: el contenedor superó su límite de memoria y el kernel de Linux lo terminó.
</details>

---

## 🎓 Certificaciones

- **CKA**: Troubleshooting es ~30% del examen (mayor peso)
- **CKAD**: Debugging de aplicaciones (~10%)
- **AKS**: Diagnóstico de nodos, networking, AKS-specific issues

---

## 🔗 Siguiente Paso

Continúa con el **Módulo 05: CI/CD y GitOps** para aprender a automatizar el despliegue de aplicaciones.
