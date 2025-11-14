# Ejemplos YAML - Troubleshooting

Esta carpeta contiene ejemplos de configuraciones con errores intencionales para practicar troubleshooting.

## 📁 Archivos

### 1. `broken-apps.yaml`
Aplicaciones con errores comunes que encontrarás en el examen CKA:
- CrashLoopBackOff
- ImagePullBackOff
- OOMKilled
- Init container failures
- Liveness/Readiness probe issues
- Missing ConfigMaps/Secrets

### 2. `troubleshooting-tools.yaml`
Pods de debugging listos para usar:
- netshoot (networking debugging)
- busybox (lightweight testing)
- dnsutils (DNS troubleshooting)
- curl pod (HTTP testing)
- Debug pods con diferentes privilegios

### 3. `common-errors.yaml`
Configuraciones incorrectas típicas:
- Service sin endpoints (label mismatch)
- PVC que no hace bind
- Network Policy que bloquea todo
- Ingress mal configurado
- RBAC permissions issues

### 4. `performance-test.yaml`
Aplicaciones para testing de performance y resource limits:
- Memory stress test
- CPU stress test
- Disk I/O test
- Resource exhaustion scenarios
- HPA testing

### 5. `rbac-debugging.yaml`
Escenarios de troubleshooting RBAC:
- ServiceAccount sin permisos
- Role/RoleBinding incorrectos
- ClusterRole issues
- Permission denied scenarios

## 🚀 Uso

### Aplicar ejemplos rotos

```bash
# Aplicar aplicaciones rotas (para practicar)
kubectl apply -f broken-apps.yaml

# Ver qué está fallando
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Fix y volver a aplicar
kubectl delete -f broken-apps.yaml
# Editar el YAML con las correcciones
kubectl apply -f broken-apps-fixed.yaml
```

### Usar herramientas de debugging

```bash
# Desplegar herramientas
kubectl apply -f troubleshooting-tools.yaml

# Usar netshoot para debug de red
kubectl exec -it netshoot -- bash
# Dentro: ping, curl, nslookup, tcpdump, etc.

# Usar busybox para testing rápido
kubectl exec -it busybox -- sh

# DNS testing
kubectl exec -it dnsutils -- nslookup kubernetes.default
```

### Practicar con errores comunes

```bash
# Aplicar configuraciones incorrectas
kubectl apply -f common-errors.yaml

# Diagnosticar:
# 1. Service sin endpoints
kubectl get endpoints service-with-wrong-selector
kubectl get pods --show-labels

# 2. PVC en Pending
kubectl get pvc
kubectl describe pvc stuck-pvc

# 3. Network Policy bloqueando
kubectl get networkpolicy
kubectl describe networkpolicy deny-all
```

### Performance testing

```bash
# Desplegar tests de performance
kubectl apply -f performance-test.yaml

# Monitorear recursos
kubectl top pods
kubectl top nodes

# Ver evictions
kubectl get events --field-selector reason=Evicted
```

### RBAC debugging

```bash
# Aplicar escenarios RBAC
kubectl apply -f rbac-debugging.yaml

# Test permissions
kubectl auth can-i create pods --as=system:serviceaccount:default:restricted-sa
kubectl auth can-i --list --as=system:serviceaccount:default:restricted-sa

# Debug
kubectl describe role,rolebinding -n default
```

## 🎯 Práctica Sugerida

1. **Aplicar broken-apps.yaml** sin mirar el contenido
2. **Diagnosticar** cada pod que falla
3. **Identificar** la causa raíz usando kubectl describe/logs
4. **Fix** el problema (editando YAML o usando kubectl edit)
5. **Verificar** que funciona correctamente
6. **Repetir** hasta que puedas diagnosticar en <5 minutos

## 🧹 Cleanup

```bash
# Limpiar todos los ejemplos
kubectl delete -f broken-apps.yaml
kubectl delete -f troubleshooting-tools.yaml
kubectl delete -f common-errors.yaml
kubectl delete -f performance-test.yaml
kubectl delete -f rbac-debugging.yaml

# O todo a la vez
kubectl delete -f .
```

## 📝 Notas

- Todos los ejemplos están diseñados para fallar **intencionalmente**
- Usa estos YAMLs para **practicar troubleshooting** antes del examen CKA
- Los comentarios en cada archivo explican qué está mal
- Intenta diagnosticar SIN mirar los comentarios primero

---

**Siguiente**: Laboratorios hands-on en [../laboratorios/](../laboratorios/)
