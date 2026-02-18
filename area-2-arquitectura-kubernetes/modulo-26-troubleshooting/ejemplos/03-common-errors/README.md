# Ejemplo 03: Common Errors - Errores Comunes de Configuración

> **Objetivo**: Practicar identificación y resolución de errores típicos de configuración  
> **Dificultad**: ⭐⭐⭐ (Intermedio-Avanzado)  
> **Tiempo estimado**: 30-40 minutos

## 📋 Descripción

12 escenarios de misconfiguración que verás frecuentemente en producción. Cada uno representa un error común que causa fallos sutiles pero críticos.

## 🎯 Errores Incluidos

1. **Service sin Endpoints** - Label selector mismatch
2. **Service Port Mismatch** - targetPort incorrecto
3. **PVC Pending** - No matching PV
4. **PVC Access Mode Mismatch** - ReadWriteOnce vs ReadWriteMany
5. **Network Policy Deny-All** - Bloquea todo el tráfico
6. **Ingress Path Incorrecto** - Path no coincide
7. **Image Tag Mutable** - Usando `:latest`
8. **SecurityContext Restrictivo** - Permisos muy estrictos
9. **HPA Sin Metrics** - metrics-server faltante
10. **StatefulSet StorageClass Inexistente** - SC no existe
11. **Probe Timeout Corto** - Probe falla prematuramente
12. **Resources Inválido** - Requests > Limits

## 📁 Archivos

```
03-common-errors/
├── README.md                    # Este archivo
├── common-errors.yaml           # 12 configuraciones erróneas
├── fixes.yaml                   # Versiones corregidas
└── cleanup.sh                   # Script de limpieza
```

## 🚀 Uso

### Aplicar Errores

```bash
kubectl apply -f common-errors.yaml
kubectl get all
```

### Diagnóstico Rápido

| Error | Comando de Diagnóstico | Fix Rápido |
|-------|------------------------|-----------|
| Service sin endpoints | `kubectl get endpoints` | Corregir labels |
| Port mismatch | `kubectl describe svc` | Ajustar targetPort |
| PVC Pending | `kubectl describe pvc` | Crear PV o SC |
| Network Policy | `kubectl get netpol` | Crear allow policy |
| HPA sin metrics | `kubectl describe hpa` | Instalar metrics-server |

### Aplicar Fixes

```bash
# Ver versiones corregidas
cat fixes.yaml

# Aplicar correcciones
kubectl apply -f fixes.yaml
```

## 🧹 Limpieza

```bash
chmod +x cleanup.sh
./cleanup.sh
```

## 📚 Aprendizajes Clave

- Siempre verifica labels en Services vs Pods
- targetPort debe coincidir con containerPort
- PVCs requieren PV disponible o StorageClass
- Network Policies son whitelist por defecto
- HPA requiere metrics-server instalado
- Evita usar `:latest` en producción
- Probes necesitan tiempo suficiente (initialDelaySeconds)

---

**Siguiente**: [Ejemplo 04 - Performance Test](../04-performance-test/)
