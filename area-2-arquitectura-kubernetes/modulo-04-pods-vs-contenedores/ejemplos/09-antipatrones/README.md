# 🚨 Antipatrones en Pods de Kubernetes

Este directorio contiene ejemplos de **antipatrones comunes** y sus **soluciones correctas**.

## 📋 Antipatrones Incluidos

### 1. **Fat Pods** - Demasiados contenedores
**Archivo**: `01-fat-pods.yaml`

❌ **Problema**: Pod con demasiados contenedores no relacionados
- Difícil de debugear
- Alto acoplamiento
- No se pueden escalar independientemente
- Punto único de falla

✅ **Solución**: Separar responsabilidades en Pods distintos
- Un Pod por servicio/función
- Solo sidecars relacionados
- Escalamiento independiente

### 2. **Singleton Services** - Un Pod para todo
**Archivo**: `02-singleton-services.yaml`

❌ **Problema**: Usar un Pod único sin réplicas
- Single point of failure
- No alta disponibilidad
- No puede escalar

✅ **Solución**: Usar Deployments con múltiples réplicas
- Alta disponibilidad (3+ réplicas)
- Auto-healing automático
- Rolling updates sin downtime
- Load balancing

### 3. **Shared Volumes Abuse** - Volúmenes para comunicación
**Archivo**: `03-volume-abuse.yaml`

❌ **Problema**: Usar filesystem compartido para comunicación entre servicios
- Alto acoplamiento
- Sincronización manual
- No hay validación de datos
- Difícil de debugear
- File locking issues

✅ **Solución**: Usar HTTP/gRPC para comunicación
- APIs bien definidas
- Validación automática
- Retry logic
- Versionado
- Escalable

⚠️ **Excepción válida**: Usar volumes solo para:
- Procesamiento de logs (sidecar pattern)
- Archivos de configuración estáticos
- Espacio temporal compartido

## 🎯 Cómo usar estos ejemplos

### Ver el antipatrón:
```bash
# Ver ejemplo del antipatrón
kubectl apply -f 01-fat-pods.yaml  # ❌ Primer manifest (malo)

# Observar los problemas
kubectl get pods
kubectl describe pod fat-pod-antipattern
```

### Aplicar la solución correcta:
```bash
# Aplicar la solución (segundo manifest en el mismo archivo)
kubectl apply -f 01-fat-pods.yaml  # ✅ Segundo manifest (bueno)

# Ver la mejora
kubectl get pods
```

## 📊 Comparación de Patrones

| Aspecto | Antipatrón | Patrón Correcto |
|---------|-----------|-----------------|
| **Fat Pods** | Muchos contenedores no relacionados | Un servicio + sidecars relacionados |
| **Singleton** | Un Pod único | Deployment con réplicas |
| **Volume Abuse** | Filesystem para comunicación | HTTP/gRPC APIs |
| **Escalabilidad** | Limitada | Horizontal y flexible |
| **Debugging** | Complejo | Simple y aislado |
| **Alta Disponibilidad** | No | Sí |

## ✅ Mejores Prácticas Generales

1. **Un Pod = Una responsabilidad principal**
2. **Sidecar solo si es esencial** para la función principal
3. **Init containers para setup** que debe completarse antes
4. **Shared volumes solo para datos compartidos** reales (no APIs)
5. **Use Deployments**, no Pods directos en producción
6. **Siempre define resources** (requests/limits)
7. **Health checks** (liveness/readiness probes)

## 🔗 Referencias

- [Documentación principal](../../README.md)
- [Ejemplos de patrones correctos](../03-multi-container/)
- [Laboratorios prácticos](../../laboratorios/)

## 📚 Para aprender más

- **Conceptos**: [Módulo 04: Pods vs Contenedores](../../README.md)
- **Práctica**: [Laboratorios](../../laboratorios/)
- **Ejemplos**: [Otros patrones](../)
