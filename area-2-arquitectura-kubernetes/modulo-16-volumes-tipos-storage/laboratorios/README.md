# 📚 Laboratorios - Módulo 16: Volumes Tipos Storage

## 🎯 Descripción

Laboratorios prácticos para dominar **almacenamiento persistente en Kubernetes**: PV/PVC, StorageClass y StatefulSets.

---

## 📋 Contenido

### 💾 Lab 01: PV/PVC Static
⏱️ 30-35 min | 🟡 Intermedio | [→ Ir al lab](./lab-01-pv-pvc-static/)

**Aprenderás**: PersistentVolume, PersistentVolumeClaim, access modes, reclaim policies

---

### ⚡ Lab 02: Dynamic Provisioning
⏱️ 25-30 min | 🟡 Intermedio | [→ Ir al lab](./lab-02-dynamic-provisioning/)

**Aprenderás**: StorageClass, aprovisionamiento automático, custom StorageClass

---

### 🗄️ Lab 03: StatefulSet Storage
⏱️ 30-35 min | 🔴 Avanzado | [→ Ir al lab](./lab-03-statefulset-storage/)

**Aprenderás**: volumeClaimTemplates, storage por replica, headless services

---

## 🗺️ Rutas de Aprendizaje

### 🟢 Principiante
1. Lab 01 (30 min) - Fundamentos PV/PVC
2. Lab 02 (25 min) - StorageClass
3. Lab 03 (30 min) - StatefulSets

**Total**: ~85 minutos

### 🔴 CKAD (State Persistence 8%)
1. Lab 02 ⭐ - Dynamic provisioning (70% probabilidad)
2. Lab 01 ⭐ - PVC creation (60% probabilidad)
3. Lab 03 - StatefulSets (30% probabilidad)

**Total**: ~35 minutos

---

## 📊 Comparativa

| Tipo | Creación PV | Escalabilidad | Caso de Uso |
|------|-------------|---------------|-------------|
| **Static PV** | Manual | Baja | Testing, legacy |
| **Dynamic PV** | Automática | Alta | Producción |
| **StatefulSet** | Por replica | Media | Bases de datos |

---

## 🎓 Objetivos

- [ ] Entender separación admin (PV) vs usuario (PVC)
- [ ] Crear PVCs con aprovisionamiento dinámico
- [ ] Usar StatefulSets con storage persistente
- [ ] Conocer reclaim policies y access modes

---

## 🧹 Limpieza Global

```bash
cd lab-01-pv-pvc-static && ./cleanup.sh && cd ..
cd lab-02-dynamic-provisioning && ./cleanup.sh && cd ..
cd lab-03-statefulset-storage && ./cleanup.sh && cd ..
```

---

## 📈 Progreso

**Has completado**:
- ✅ M14: Secrets
- ✅ M15: Volumes Conceptos
- ✅ M16: Volumes Storage ← **Estás aquí**

**Próximo**: M17 RBAC Users & Groups

---

🎉 **¡Domina storage persistente en Kubernetes!** 🚀
