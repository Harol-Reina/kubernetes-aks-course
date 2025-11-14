# 📚 Laboratorios - Módulo 15: Volumes Conceptos

## 🎯 Descripción

Laboratorios prácticos para aprender los **conceptos fundamentales de volúmenes en Kubernetes**: emptyDir, hostPath y ConfigMap volumes.

---

## 📋 Contenido de Laboratorios

### 🔄 Lab 01: EmptyDir Volume
- **Duración**: 20-25 minutos
- **Nivel**: 🟢 Principiante
- **Conceptos**: Volúmenes efímeros, compartir datos entre contenedores
- **Archivos**: [lab-01-emptydir-volume/](./lab-01-emptydir-volume/)

**Aprenderás**:
- ✅ Compartir datos entre contenedores en un Pod
- ✅ EmptyDir en memoria (tmpfs)
- ✅ Límites de tamaño con `sizeLimit`
- ✅ Ciclo de vida de volúmenes efímeros

---

### 🗂️ Lab 02: HostPath Volume
- **Duración**: 25-30 minutos
- **Nivel**: 🟡 Intermedio
- **Conceptos**: Acceso al filesystem del nodo, riesgos de seguridad
- **Archivos**: [lab-02-hostpath-volume/](./lab-02-hostpath-volume/)

**Aprenderás**:
- ✅ Montar directorios del nodo en Pods
- ✅ Persistencia más allá del ciclo de vida del Pod
- ✅ Tipos de hostPath (Directory, File, Socket)
- ✅ DaemonSets con hostPath
- ⚠️ Consideraciones de seguridad y portabilidad

---

### 📄 Lab 03: ConfigMap Volume
- **Duración**: 20-25 minutos
- **Nivel**: 🟢 Principiante
- **Conceptos**: Inyectar configuración como archivos
- **Archivos**: [lab-03-configmap-volume/](./lab-03-configmap-volume/)

**Aprenderás**:
- ✅ Montar ConfigMaps como archivos
- ✅ Proyección selectiva de keys
- ✅ Actualización automática de configuración
- ✅ Permisos personalizados con `defaultMode`

---

## 🗺️ Rutas de Aprendizaje

### 🟢 Ruta Principiante (Orden Recomendado)

1. **Lab 01**: EmptyDir Volume (20 min)
   - Conceptos más simples y seguros
   - Sin riesgos de seguridad
   - Entender volúmenes efímeros

2. **Lab 03**: ConfigMap Volume (20 min)
   - Práctica con configuración
   - Preparación para aplicaciones reales

3. **Lab 02**: HostPath Volume (25 min)
   - Conceptos avanzados
   - Consideraciones de seguridad

**Total**: ~65 minutos

---

### 🟡 Ruta Intermedia (Enfoque Rápido)

Si ya conoces volúmenes básicos:

1. **Lab 01** (15 min): Repaso rápido de emptyDir
2. **Lab 02** (20 min): HostPath con enfoque en DaemonSets
3. **Lab 03** (15 min): ConfigMap volume vs envFrom

**Total**: ~50 minutos

---

### 🔴 Ruta Certificación CKAD

Enfoque en temas del examen:

1. **Lab 03**: ConfigMap Volume ⭐ (80% probabilidad en CKAD)
   - Montar configuración
   - Proyección selectiva

2. **Lab 01**: EmptyDir ⭐ (60% probabilidad)
   - Multi-container patterns
   - Shared storage

3. **Lab 02**: HostPath (20% probabilidad)
   - Solo para contexto de DaemonSets

**Total**: ~35 minutos (enfoque práctico)

---

## 📊 Comparativa de Tipos de Volúmenes

| Tipo | Persistencia | Portabilidad | Seguridad | Caso de Uso Principal |
|------|--------------|--------------|-----------|----------------------|
| **EmptyDir** | ❌ Efímero | ✅ Alta | ✅ Seguro | Caches, datos temporales |
| **HostPath** | ✅ Persiste | ❌ Baja | ⚠️ Riesgoso | DaemonSets, logs del nodo |
| **ConfigMap** | ✅ Persiste | ✅ Alta | ✅ Seguro | Archivos de configuración |

---

## 🎓 Objetivos de Aprendizaje del Módulo

Al completar estos laboratorios, podrás:

**Conceptuales**:
- [ ] Entender el ciclo de vida de diferentes tipos de volúmenes
- [ ] Distinguir entre volúmenes efímeros y persistentes
- [ ] Conocer las limitaciones de cada tipo de volumen

**Técnicos**:
- [ ] Crear Pods con emptyDir, hostPath y ConfigMap volumes
- [ ] Compartir datos entre contenedores usando volúmenes
- [ ] Montar configuración desde ConfigMaps como archivos
- [ ] Configurar permisos y límites en volúmenes

**Troubleshooting**:
- [ ] Diagnosticar problemas de montaje de volúmenes
- [ ] Resolver errores de permisos
- [ ] Verificar actualización de ConfigMaps

**Profesionales**:
- [ ] Elegir el tipo de volumen apropiado según el caso de uso
- [ ] Aplicar mejores prácticas de seguridad con volúmenes
- [ ] Diseñar aplicaciones con configuración desacoplada

---

## 🧹 Limpieza Global

Para limpiar **todos los laboratorios** de este módulo:

```bash
# Desde cada laboratorio
cd lab-01-emptydir-volume && ./cleanup.sh && cd ..
cd lab-02-hostpath-volume && ./cleanup.sh && cd ..
cd lab-03-configmap-volume && ./cleanup.sh && cd ..
```

O manualmente:

```bash
# Eliminar todos los Pods y ConfigMaps del módulo
kubectl delete pods -l app=emptydir-demo
kubectl delete pods -l app=hostpath-demo
kubectl delete daemonset log-collector
kubectl delete configmaps app-config nginx-config multi-config dynamic-config

# Limpiar nodo Minikube (opcional)
minikube ssh "sudo rm -rf /mnt/data/*"
```

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Ephemeral Volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/)

### Siguientes Pasos
- ➡️ **Módulo 16**: Volumes Tipos Storage (PV, PVC, StorageClass)
- 📘 **Módulo 17**: RBAC Users & Groups
- 🔒 **Módulo 14**: Secrets Data Sensible

---

## 🎯 Preparación para Certificaciones

### CKAD - Application Environment (25%)

**Cobertura de este módulo**:
- ✅ ConfigMap volumes (alta probabilidad)
- ✅ Multi-container pods con emptyDir (media probabilidad)
- ⚠️ HostPath (baja probabilidad, pero útil para contexto)

**Comandos críticos para el examen**:

```bash
# Crear ConfigMap desde literal/archivo
kubectl create configmap <name> --from-literal=key=value
kubectl create configmap <name> --from-file=config.txt

# Montar ConfigMap como volumen (modo imperativo)
kubectl run pod --image=nginx --dry-run=client -o yaml > pod.yaml
# Luego editar YAML para agregar volumen

# Verificar montaje
kubectl exec <pod> -- ls -la /path/to/mount
kubectl exec <pod> -- cat /path/to/mount/file
```

---

## ✅ Checklist de Completitud

Marca cuando completes cada laboratorio:

- [ ] ✅ Lab 01: EmptyDir Volume
- [ ] ✅ Lab 02: HostPath Volume
- [ ] ✅ Lab 03: ConfigMap Volume
- [ ] ✅ Revisé troubleshooting de cada lab
- [ ] ✅ Practiqué comandos de verificación
- [ ] ✅ Limpié recursos después de cada lab

---

## 🆘 Soporte

**Problemas comunes**:
- Ver sección de Troubleshooting en cada laboratorio
- Revisar SETUP.md para validaciones pre-lab
- Ejecutar cleanup.sh si hay conflictos de recursos

**¿Necesitas ayuda?**
- 📖 Revisa [RESUMEN-MODULO.md](../RESUMEN-MODULO.md) para conceptos teóricos
- 🔍 Consulta documentación oficial de Kubernetes
- 💬 Pregunta en foros de la comunidad K8s

---

## 📈 Progreso del Curso

**Has completado**:
- ✅ Módulo 14: Secrets Data Sensible
- ✅ Módulo 15: Volumes Conceptos ← **Estás aquí**

**Próximamente**:
- ⏳ Módulo 16: Volumes Tipos Storage (PV, PVC)
- ⏳ Módulo 17: RBAC Users & Groups

---

**🎉 ¡Éxito en tu aprendizaje de volúmenes en Kubernetes!**

Con estos labs dominarás los conceptos fundamentales de storage en K8s, preparándote para volúmenes persistentes avanzados en el Módulo 16. 🚀
