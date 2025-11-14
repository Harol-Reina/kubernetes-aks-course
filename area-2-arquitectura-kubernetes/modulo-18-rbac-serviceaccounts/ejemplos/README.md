# Ejemplos - Módulo 18: RBAC ServiceAccounts

> **Enfoque**: ServiceAccounts y su integración con RBAC  
> **Total**: 11 ejemplos progresivos

## 📁 Estructura

```
ejemplos/
├── README.md                              # Este archivo
├── 01-serviceaccount-completo/            # SA con todas las opciones
├── 02-serviceaccount-basico/              # SA mínimo
├── 03-serviceaccounts-por-ambiente/       # SAs por ambiente
├── 04-pod-con-serviceaccount/             # Pod usando SA
├── 05-pod-token-proyectado/               # Token proyectado moderno
├── 06-rbac-completo/                      # RBAC completo (ya existente)
├── 07-clusterrole-serviceaccount/         # ClusterRole + SA
├── 08-pod-custom-sa/                      # Pod con SA custom + RBAC
├── 09-deployment-con-sa/                  # Deployment con SA
├── 10-pod-api-access/                     # Pod accediendo a API
└── 11-python-api-client/                  # Cliente Python (ya existente)
```

## 📋 Ejemplos Disponibles

### Básicos (01-04)

**[01-serviceaccount-completo](./01-serviceaccount-completo/)**
- ServiceAccount con todas las opciones
- AutomountServiceAccountToken
- ImagePullSecrets
- Secrets manuales

**[02-serviceaccount-basico](./02-serviceaccount-basico/)**
- Configuración mínima
- Token automático
- Listo para usar

**[03-serviceaccounts-por-ambiente](./03-serviceaccounts-por-ambiente/)**
- Múltiples SAs en un archivo
- Labels por ambiente
- Segregación de identidades

**[04-pod-con-serviceaccount](./04-pod-con-serviceaccount/)**
- Asignar SA a pod
- Token montado en /var/run/secrets
- Verificar identidad

### Intermedios (05-07)

**[05-pod-token-proyectado](./05-pod-token-proyectado/)**
- Token con expiración
- Audiencia específica
- Mayor seguridad

**[06-rbac-completo](./06-rbac-completo/)** ⭐
- Ejemplo completo RBAC
- (Carpeta ya existente)

**[07-clusterrole-serviceaccount](./07-clusterrole-serviceaccount/)**
- ClusterRole + SA
- Permisos cluster-wide
- ClusterRoleBinding

### Avanzados (08-11)

**[08-pod-custom-sa](./08-pod-custom-sa/)**
- SA con permisos específicos
- Role + RoleBinding
- Pod usando SA custom

**[09-deployment-con-sa](./09-deployment-con-sa/)**
- Deployment completo
- RBAC configurado
- Production-ready

**[10-pod-api-access](./10-pod-api-access/)**
- Acceso a K8s API desde pod
- Variables de entorno
- Token automático

**[11-python-api-client](./11-python-api-client/)** 🐍
- Cliente Python para K8s API
- (Carpeta ya existente)

## 🚀 Guía de Uso

### Explorar un Ejemplo

```bash
# Navegar al ejemplo
cd 01-serviceaccount-completo/

# Leer documentación
cat README.md

# Ver el YAML
cat 01-serviceaccount-completo.yaml

# Aplicar
kubectl apply -f 01-serviceaccount-completo.yaml

# Verificar
kubectl get sa

# Limpiar
./cleanup.sh
```

### Progresión Recomendada

```
Día 1: Básicos
├── 01-serviceaccount-completo
├── 02-serviceaccount-basico
├── 03-serviceaccounts-por-ambiente
└── 04-pod-con-serviceaccount

Día 2: Intermedios + RBAC
├── 05-pod-token-proyectado
├── 06-rbac-completo
└── 07-clusterrole-serviceaccount

Día 3: Avanzados + API
├── 08-pod-custom-sa
├── 09-deployment-con-sa
├── 10-pod-api-access
└── 11-python-api-client
```

## 🎯 Conceptos Cubiertos

| Ejemplo | ServiceAccount | RBAC | Pods | API |
|---------|----------------|------|------|-----|
| 01 | ⭐⭐⭐ | - | - | - |
| 02 | ⭐ | - | - | - |
| 03 | ⭐⭐ | - | - | - |
| 04 | ⭐ | - | ⭐⭐ | - |
| 05 | ⭐⭐⭐ | - | ⭐ | - |
| 06 | ⭐ | ⭐⭐⭐ | - | - |
| 07 | ⭐ | ⭐⭐⭐ | - | - |
| 08 | ⭐⭐ | ⭐⭐ | ⭐⭐ | - |
| 09 | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ | - |
| 10 | ⭐ | ⭐ | ⭐⭐ | ⭐⭐⭐ |
| 11 | ⭐ | ⭐ | - | ⭐⭐⭐ |

## 💡 Tips

### Verificar ServiceAccount

```bash
# Listar todos
kubectl get sa

# Describir uno específico
kubectl describe sa <nombre>

# Ver en formato YAML
kubectl get sa <nombre> -o yaml

# Ver token secret
kubectl get sa <nombre> -o jsonpath='{.secrets[0].name}'
```

### Probar Permisos

```bash
# Como usuario actual
kubectl auth can-i list pods

# Como ServiceAccount
kubectl auth can-i list pods \
  --as=system:serviceaccount:default:mi-sa
```

### Debugging

```bash
# Ver token en pod
kubectl exec <pod> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Ver qué SA usa un pod
kubectl get pod <pod> -o jsonpath='{.spec.serviceAccountName}'
```

## 📚 Recursos

- [ServiceAccounts Docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [RBAC Docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [API Access from Pods](https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/)

---

[Volver al módulo](../README.md) | [Ir a laboratorios](../laboratorios/)
