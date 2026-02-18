# Ejemplo 01: ServiceAccount Completo

## 🎯 Objetivo

Demostrar la configuración completa de un ServiceAccount con:
- Nombre y namespace personalizados
- Secrets automáticos y manuales
- ImagePullSecrets
- AutomountServiceAccountToken configurado

## 📝 Descripción

Este ejemplo crea un ServiceAccount con todas las opciones de configuración disponibles, ideal para entornos de producción donde se requiere control completo sobre la identidad del pod.

## 🚀 Uso

```bash
# Aplicar el ServiceAccount
kubectl apply -f 01-serviceaccount-completo.yaml

# Verificar creación
kubectl get serviceaccount sa-completo -n production

# Ver detalles
kubectl describe serviceaccount sa-completo -n production

# Ver secrets asociados
kubectl get secrets -n production | grep sa-completo
```

## 📊 Qué demuestra

- ✅ ServiceAccount con nombre descriptivo
- ✅ Namespace específico (production)
- ✅ AutomountServiceAccountToken = false (seguridad)
- ✅ ImagePullSecrets para registros privados
- ✅ Secrets manuales vinculados

## 🧪 Verificación

```bash
# Confirmar que NO se monta el token automáticamente
kubectl get sa sa-completo -n production -o yaml | grep automount

# Ver imagePullSecrets
kubectl get sa sa-completo -n production -o jsonpath='{.imagePullSecrets}'
```

## 🧹 Limpieza

```bash
./cleanup.sh
# O manualmente:
kubectl delete -f 01-serviceaccount-completo.yaml
```

## 📚 Conceptos

- **AutomountServiceAccountToken**: Control sobre montaje automático del token
- **ImagePullSecrets**: Autenticación a registros de imágenes privados
- **Secrets vinculados**: Secrets adicionales asociados al SA

---

[Volver a ejemplos](../README.md)
