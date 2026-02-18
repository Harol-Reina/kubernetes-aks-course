# Laboratorios - Módulo 14: Secrets & Sensitive Data

## 📚 Navegación

**Ubicación**: `area-2-arquitectura-kubernetes/modulo-14-secrets-data-sensible/laboratorios/`

[← Volver al Módulo 14](../README.md) | [Ir a Módulo 15 →](../../modulo-15-volumes-conceptos/README.md)

---

## 🎯 Índice de Laboratorios

### Lab 01: Secret Básico
- **Ruta**: `lab-01-secret-basico/`
- **Dificultad**: 🟢 Principiante
- **Tiempo**: 15-20 minutos
- **Objetivo**: Crear y usar secrets básicos con kubectl

**Aprenderás**:
- ✅ Crear secrets con `kubectl create secret`
- ✅ Montar secrets como volúmenes
- ✅ Leer valores desde archivos
- ✅ Codificación base64

**[📖 Comenzar Lab 01](./lab-01-secret-basico/README.md)**

---

### Lab 02: Secret from File
- **Ruta**: `lab-02-secret-from-file/`
- **Dificultad**: 🟢 Principiante
- **Tiempo**: 20-25 minutos
- **Objetivo**: Crear secrets desde archivos existentes

**Aprenderás**:
- ✅ `--from-file` con archivos individuales
- ✅ `--from-file` con directorios completos
- ✅ Personalizar nombres de claves
- ✅ Configurar nginx con TLS

**[📖 Comenzar Lab 02](./lab-02-secret-from-file/README.md)**

---

### Lab 03: Secret como Variables de Entorno
- **Ruta**: `lab-03-secret-env-vars/`
- **Dificultad**: 🟢 Principiante
- **Tiempo**: 15-20 minutos
- **Objetivo**: Inyectar secrets como env vars

**Aprenderás**:
- ✅ `envFrom` para secrets completos
- ✅ `env` con `secretKeyRef` para valores individuales
- ✅ Combinar secrets, configmaps y valores literales
- ✅ Mejores prácticas de env vars

**[📖 Comenzar Lab 03](./lab-03-secret-env-vars/README.md)**

---

## 📊 Progreso del Módulo

| Lab | Estado | Completado |
|-----|--------|------------|
| Lab 01: Secret Básico | ✅ Disponible | [ ] |
| Lab 02: Secret from File | ✅ Disponible | [ ] |
| Lab 03: Secret as Env Vars | ✅ Disponible | [ ] |

---

## 🎓 Ruta de Aprendizaje Sugerida

### 🟢 Ruta Principiante (60 minutos)
1. ✅ Lab 01: Secret Básico (20 min)
2. ✅ Lab 02: Secret from File (25 min)
3. ✅ Lab 03: Secret Env Vars (20 min)

### 🟡 Ruta Intermedia (45 minutos)
1. ✅ Lab 01 (15 min, foco en base64)
2. ✅ Lab 02 (20 min, foco en TLS)
3. ✅ Lab 03 (15 min, foco en combinaciones)

### 🔴 Ruta Certificación CKAD (30 minutos)
- ✅ Lab 01 (enfoque imperativo rápido)
- ✅ Lab 03 (envFrom vs env, práctica rápida)
- ⏭️ Skip Lab 02 (menos común en examen)

---

## 🔧 Setup General

Antes de comenzar cualquier laboratorio:

```bash
# Verificar cluster
kubectl cluster-info

# Verificar permisos
kubectl auth can-i create secrets
kubectl auth can-i create pods

# Namespace opcional
kubectl create namespace lab-secrets
kubectl config set-context --current --namespace=lab-secrets
```

---

## 🧹 Limpieza Completa del Módulo

Para limpiar TODOS los labs del módulo:

```bash
# Ejecutar cleanup de cada lab
cd lab-01-secret-basico && ./cleanup.sh && cd ..
cd lab-02-secret-from-file && ./cleanup.sh && cd ..
cd lab-03-secret-env-vars && ./cleanup.sh && cd ..

# Eliminar namespace (si lo creaste)
kubectl delete namespace lab-secrets --ignore-not-found=true
```

---

## 📖 Conceptos Clave del Módulo

### Secrets vs ConfigMaps

| Aspecto | Secrets | ConfigMaps |
|---------|---------|------------|
| **Propósito** | Datos sensibles | Configuración |
| **Codificación** | Base64 | Plain text |
| **Seguridad** | Mayor protección | Normal |
| **Uso** | Passwords, tokens, certs | URLs, flags, configs |

### Métodos de Inyección

1. **Volúmenes** (`volumeMounts`)
   - Archivos grandes
   - Certificados TLS
   - Múltiples archivos

2. **Variables de Entorno** (`env`/`envFrom`)
   - Valores simples
   - 12-factor apps
   - Configuración estándar

### Tipos de Secrets

- **Opaque**: Genérico (estos labs)
- **kubernetes.io/service-account-token**: ServiceAccount
- **kubernetes.io/dockerconfigjson**: Registry credentials
- **kubernetes.io/tls**: Certificados TLS

---

## ✅ Objetivos de Aprendizaje del Módulo

Al completar todos los labs, podrás:

- ✅ Crear secrets de múltiples formas
- ✅ Entender codificación base64
- ✅ Montar secrets como volúmenes
- ✅ Inyectar secrets como env vars
- ✅ Combinar múltiples sources de configuración
- ✅ Aplicar mejores prácticas de seguridad
- ✅ Troubleshoot problemas comunes con secrets

---

## 🚀 Próximo Módulo

Después de completar estos labs:

**[→ Módulo 15: Volumes - Conceptos](../../modulo-15-volumes-conceptos/README.md)**

Aprenderás sobre:
- emptyDir volumes
- hostPath volumes
- ConfigMap volumes
- Persistent storage (introducción)

---

## 📚 Recursos Adicionales

- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Secrets Best Practices](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
- [Encryption at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
- [External Secrets Operator](https://external-secrets.io/)

---

## 🎯 Checklist de Completitud

- [ ] Lab 01: Secret Básico completado
- [ ] Lab 02: Secret from File completado
- [ ] Lab 03: Secret Env Vars completado
- [ ] Preguntas de repaso contestadas
- [ ] Troubleshooting practicado
- [ ] Limpieza ejecutada

---

**Total de labs**: 3  
**Tiempo total estimado**: 50-65 minutos  
**Nivel**: 🟢 Principiante a 🟡 Intermedio

¡Buena suerte con los laboratorios! 🚀
