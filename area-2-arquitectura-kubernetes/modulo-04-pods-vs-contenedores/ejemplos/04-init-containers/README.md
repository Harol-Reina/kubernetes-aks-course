# 🚀 Patrones Multi-Contenedor: Init Containers

Ejemplos prácticos del patrón **Init Container** en Kubernetes.

## 📖 ¿Qué son los Init Containers?

Los **init containers** son contenedores que se ejecutan y completan **ANTES** de que los contenedores principales inicien. Se ejecutan secuencialmente y deben completar exitosamente para que el Pod inicie.

## 📁 Ejemplos Disponibles

### 01. Init Container: Database Migrations
**Archivo:** `01-init-db-migration.yaml`

Demuestra cómo ejecutar migraciones de base de datos antes de iniciar la app.

**Arquitectura:**
- **Init 1:** wait-for-db (espera PostgreSQL)
- **Init 2:** database-migration (ejecuta migraciones SQL)
- **Main:** Aplicación web

**Uso:**
```bash
# Aplicar
kubectl apply -f 01-init-db-migration.yaml

# Ver progreso de init containers
kubectl get pods -w

# Ver logs de cada init container
kubectl logs web-with-init -c wait-for-db
kubectl logs web-with-init -c database-migration

# Ver app final
kubectl logs web-with-init -c web-app

# Cleanup
kubectl delete pod web-with-init
kubectl delete configmap db-migrations
kubectl delete secret db-credentials
```

**Qué aprendes:**
- ✅ Ejecución secuencial de init containers
- ✅ Wait for dependencies pattern
- ✅ Database migrations antes de deploy
- ✅ Uso de ConfigMaps para SQL scripts

---

### 02. Init Container: Wait for Dependencies
**Archivo:** `02-init-wait-for-deps.yaml`

Demuestra cómo esperar múltiples servicios externos.

**Arquitectura:**
- **Init 1:** wait-for-redis (TCP check)
- **Init 2:** wait-for-db (pg_isready)
- **Init 3:** wait-for-api (HTTP health check)
- **Main:** Aplicación

**Uso:**
```bash
# Aplicar
kubectl apply -f 02-init-wait-for-deps.yaml

# Ver status
kubectl get pods app-wait-deps -w

# Ver logs de cada wait
kubectl logs app-wait-deps -c wait-for-redis
kubectl logs app-wait-deps -c wait-for-db
kubectl logs app-wait-deps -c wait-for-api

# Cleanup
kubectl delete pod app-wait-deps
kubectl delete service app-wait-deps-svc
```

**Qué aprendes:**
- ✅ Múltiples estrategias de health checking
- ✅ TCP check con netcat
- ✅ PostgreSQL check con pg_isready
- ✅ HTTP check con curl y retry logic

---

### 03. Init Container: Configuration Setup
**Archivo:** `03-init-config-setup.yaml`

Demuestra setup completo de ambiente: configs, assets, permisos.

**Arquitectura:**
- **Init 1:** generate-config (template rendering)
- **Init 2:** download-assets (fetch external files)
- **Init 3:** setup-permissions (filesystem setup)
- **Main:** Nginx con configuración lista

**Uso:**
```bash
# Aplicar
kubectl apply -f 03-init-config-setup.yaml

# Ver progreso
kubectl get pods app-config-setup -w

# Ver cada fase
kubectl logs app-config-setup -c generate-config
kubectl logs app-config-setup -c download-assets
kubectl logs app-config-setup -c setup-permissions

# Ver configuración generada
kubectl exec app-config-setup -- cat /app/config/app.conf

# Ver assets descargados
kubectl exec app-config-setup -- ls -la /app/assets/

# Cleanup
kubectl delete pod app-config-setup
kubectl delete configmap config-template assets-list
kubectl delete service app-config-svc
```

**Qué aprendes:**
- ✅ Template rendering dinámico
- ✅ Download de assets externos
- ✅ Setup de permisos y directorios
- ✅ Preparación completa de ambiente

---

## 🎯 Cuándo Usar Init Containers

| Situación | ¿Init Container? | Razón |
|-----------|------------------|-------|
| Migrar DB antes de app | ✅ Sí | Garantiza schema actualizado |
| Esperar dependencias | ✅ Sí | Evita fallos al iniciar |
| Descargar configs/assets | ✅ Sí | Prepara ambiente |
| Setup de permisos | ✅ Sí | One-time configuration |
| Procesar logs en runtime | ❌ No | Usar Sidecar |
| Lógica de negocio | ❌ No | Usar Main Container |

## 🔄 Diferencias vs Sidecar

| Aspecto | Init Container | Sidecar |
|---------|----------------|---------|
| **Cuándo corre** | ⏰ ANTES de main | 🔄 Simultáneo con main |
| **Ejecución** | 📝 Secuencial | 🔄 Paralelo |
| **Duración** | ⚡ Completa y termina | ♾️ Corre indefinidamente |
| **Si falla** | 🔁 Restart Pod completo | 🔁 Restart solo el container |

## 📚 Recursos Adicionales

- [Kubernetes Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Init Container Best Practices](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/#differences-from-regular-containers)

## 🔗 Ver También

- [../03-multi-container/](../03-multi-container/) - Sidecar pattern
- [../05-ambassador/](../05-ambassador/) - Ambassador pattern
- [../../README.md](../../README.md) - Documentación principal
