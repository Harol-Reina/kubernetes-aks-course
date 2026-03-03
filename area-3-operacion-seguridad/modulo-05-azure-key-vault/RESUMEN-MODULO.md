# 📚 RESUMEN - Módulo 05 (Área 3): Azure Key Vault y Gestión de Secrets

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre la **gestión segura de secrets** en Kubernetes — desde Secrets nativos de K8s hasta la integración con Azure Key Vault mediante el CSI Secret Store Driver. Aprenderás a almacenar, distribuir y rotar credenciales de forma segura.

**Duración**: 6 horas (teoría + labs)
**Nivel**: Intermedio-Avanzado
**Prerequisitos**: Pods, Volumes, RBAC, ConfigMaps

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Entender qué son los Secrets y por qué existen
- ✅ Diferenciar entre ConfigMap y Secret
- ✅ Saber que base64 NO es encriptación
- ✅ Conocer los tipos de Secrets (Opaque, docker-registry, tls)

### Técnico
- ✅ Crear Secrets de forma imperativa y declarativa
- ✅ Montar Secrets como volúmenes o variables de entorno
- ✅ Integrar AKS con Azure Key Vault via CSI Driver
- ✅ Configurar rotación automática de secrets
- ✅ Usar Workload Identity para acceso seguro

### Troubleshooting
- ✅ Diagnosticar Pods que no pueden acceder a Secrets
- ✅ Verificar que los Secrets están montados correctamente
- ✅ Depurar problemas de CSI Secret Store Driver

---

## 🗺️ Diagrama Mental

```
Niveles de Seguridad para Secrets:

Nivel 1: ConfigMap (sin seguridad)
  ├── Datos en texto plano
  ├── Visibles con kubectl get cm -o yaml
  └── NUNCA para datos sensibles

Nivel 2: Kubernetes Secrets (seguridad básica)
  ├── Datos en base64 (NO encriptación)
  ├── Almacenados en etcd
  ├── RBAC controla acceso
  └── Suficiente para dev/staging

Nivel 3: Azure Key Vault (seguridad empresarial)
  ├── Encriptación real (HSM)
  ├── Auditoría de acceso
  ├── Rotación automática
  ├── Compliance (SOC2, ISO27001)
  └── Recomendado para producción
```

### ConfigMap vs Secret vs Azure Key Vault

| Aspecto | ConfigMap | Secret | Azure Key Vault |
|---------|-----------|--------|-----------------|
| **Datos** | Texto plano | Base64 | Encriptado (HSM) |
| **Seguridad** | Ninguna | RBAC básico | Encriptación + RBAC + Audit |
| **Uso** | Config no sensible | Passwords, tokens | Certificados, claves API |
| **Rotación** | Manual | Manual | Automática |
| **Auditoría** | No | Limitada | Completa |

---

## 🔧 Comandos Esenciales

### Básicos

```bash
# Crear Secret imperativo
kubectl create secret generic mi-secret \
  --from-literal=username=admin \
  --from-literal=password=s3cr3t

# Crear Secret desde archivo
kubectl create secret generic mi-secret \
  --from-file=ssh-key=~/.ssh/id_rsa

# Ver Secrets
kubectl get secrets -n <namespace>

# Ver contenido (base64)
kubectl get secret mi-secret -o yaml

# Decodificar un valor
kubectl get secret mi-secret -o jsonpath='{.data.password}' | base64 -d
```

### Intermedios

```bash
# Crear Secret TLS
kubectl create secret tls mi-tls \
  --cert=cert.pem --key=key.pem

# Crear Secret docker-registry
kubectl create secret docker-registry mi-registry \
  --docker-server=myregistry.azurecr.io \
  --docker-username=user \
  --docker-password=pass

# Ver Secrets montados en un Pod
kubectl exec <pod> -- ls /mnt/secrets/
kubectl exec <pod> -- cat /mnt/secrets/password
```

---

## 📝 Cheat Sheet: YAML Snippets

### Secret Opaque

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:           # stringData: texto plano (K8s convierte a base64)
  username: admin
  password: "super-secreto-123"
  connection: "postgresql://admin:pass@db:5432/myapp"
```

### Pod con Secret como Volumen

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-con-secrets
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: secret-vol
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-vol
    secret:
      secretName: db-credentials
```

### Pod con Secret como Variables de Entorno

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-env-secrets
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
```

---

## ❗ Problemas Comunes y Soluciones

### 1. Secret no se monta en el Pod

**Causa**: El nombre del Secret en el YAML no coincide.
**Diagnóstico**: `kubectl describe pod <name>` → buscar errores en Volumes.
**Solución**: Verificar que el `secretName` coincide con `kubectl get secrets`.

### 2. Variable de entorno del Secret está vacía

**Causa**: La key especificada en `secretKeyRef.key` no existe en el Secret.
**Solución**: `kubectl get secret <name> -o jsonpath='{.data}'` para ver las keys disponibles.

### 3. Error "secrets is forbidden" al acceder desde un Pod

**Causa**: El ServiceAccount del Pod no tiene permisos RBAC para leer Secrets.
**Solución**: Crear un Role con `get` en `secrets` y un RoleBinding.

### 4. Datos aparecen en base64 en lugar de texto plano

**Causa**: Estás viendo el Secret con `kubectl get -o yaml`. base64 NO es encriptación.
**Solución**: Decodificar con `echo <valor> | base64 -d`.

---

## ✅ Checklist de Conceptos

- [ ] Sé la diferencia entre ConfigMap y Secret
- [ ] Entiendo que base64 no es encriptación
- [ ] Puedo crear Secrets de forma imperativa y declarativa
- [ ] Sé montar Secrets como volúmenes y variables de entorno
- [ ] Entiendo los tipos de Secrets (Opaque, docker-registry, tls)
- [ ] Conozco las best practices (RBAC, encryption at rest, rotación)
- [ ] Sé integrar AKS con Azure Key Vault

---

## 📝 Preguntas de Repaso

### 1. ¿Por qué base64 no es seguridad?

<details><summary>Ver respuesta</summary>
base64 es una codificación, no encriptación. Cualquiera puede decodificarlo con `echo <valor> | base64 -d`. Los Secrets de K8s usan base64 solo para poder almacenar datos binarios (como certificados) en formato texto. La seguridad real viene de RBAC y encryption at rest en etcd.
</details>

### 2. ¿Cuándo usar volúmenes vs variables de entorno para Secrets?

<details><summary>Ver respuesta</summary>
**Volúmenes**: Cuando el Secret puede cambiar y necesitas que el Pod vea los cambios automáticamente (K8s actualiza el archivo montado). También para archivos como certificados TLS o claves SSH.
**Variables de entorno**: Para valores simples (username, password). Más fácil de usar pero NO se actualizan si el Secret cambia (requiere reinicio del Pod).
</details>

### 3. ¿Qué ventajas ofrece Azure Key Vault sobre K8s Secrets?

<details><summary>Ver respuesta</summary>
Encriptación real con HSM, auditoría de acceso completa, rotación automática de secrets, compliance regulatorio (SOC2, ISO27001), control de acceso granular con Azure RBAC, y separación de responsabilidades (el equipo de seguridad gestiona Key Vault, los desarrolladores solo consumen los secrets).
</details>

### 4. ¿Cómo funciona el CSI Secret Store Driver?

<details><summary>Ver respuesta</summary>
El CSI Secret Store Driver permite montar secrets de Azure Key Vault directamente como volúmenes en Pods de AKS. El flujo es: Pod solicita un volumen → CSI Driver consulta Azure Key Vault → Los secrets se montan como archivos en el Pod. Soporta rotación automática y Workload Identity para autenticación.
</details>

---

## 🎓 Relevancia para Certificaciones

- **CKA**: Crear y gestionar Secrets, montar en Pods
- **CKAD**: Usar Secrets como volúmenes y env vars
- **AKS**: Azure Key Vault, CSI Secret Store, Workload Identity

---

## 🔗 Siguiente Paso

Continúa con el **Área 4: Observabilidad y Alta Disponibilidad**, empezando por el **Módulo 01: Logging y Observabilidad**.
