# 🧪 Lab 01: Helm Basics - Install, Search, Deploy

> **Duración**: 30 minutos  
> **Nivel**: 🟢 Básico  
> **Objetivo**: Dominar comandos esenciales de Helm y workflow básico

---

## 📋 Pre-requisitos

```bash
# Verificar Helm instalado
helm version
# Debería mostrar: version.BuildInfo{Version:"v3.x.x", ...}

# Verificar cluster K8s
kubectl cluster-info

# Verificar namespace
kubectl get namespaces
```

---

## Parte 1: Setup y Búsqueda de Charts (8 min)

### Paso 1.1: Añadir Repositorios (2 min)

```bash
# Añadir repositorio Bitnami (el más usado)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Añadir más repositorios útiles
helm repo add stable https://charts.helm.sh/stable
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Listar repositorios configurados
helm repo list
```

**✅ Checkpoint**: Deberías ver 3 repositorios listados

### Paso 1.2: Actualizar y Buscar Charts (3 min)

```bash
# Actualizar índice de charts
helm repo update

# Buscar charts de nginx
helm search repo nginx

# Buscar charts de postgresql
helm search repo postgresql

# Buscar en todos los repos públicos (Artifact Hub)
helm search hub wordpress

# Ver todas las versiones disponibles
helm search repo nginx --versions | head -20
```

**✅ Checkpoint**: Ver múltiples charts de NGINX disponibles

### Paso 1.3: Inspeccionar Chart Antes de Instalar (3 min)

```bash
# Ver metadata del chart
helm show chart bitnami/nginx

# Ver valores configurables (importante!)
helm show values bitnami/nginx

# Ver valores y guardar para editar
helm show values bitnami/nginx > nginx-values.yaml

# Ver README del chart
helm show readme bitnami/nginx | head -50
```

**✅ Checkpoint**: Entender qué valores se pueden customizar

---

## Parte 2: Instalar Primera Aplicación (10 min)

### Paso 2.1: Instalación Básica de NGINX (3 min)

```bash
# Instalar NGINX con defaults
helm install my-nginx bitnami/nginx

# Ver estado del release
helm status my-nginx

# Listar releases instalados
helm list

# Ver pods creados
kubectl get pods -l app.kubernetes.io/instance=my-nginx

# Ver servicio
kubectl get svc -l app.kubernetes.io/instance=my-nginx
```

**✅ Checkpoint**: Pod `my-nginx-xxx` en estado Running

### Paso 2.2: Acceder a la Aplicación (2 min)

```bash
# Port-forward para acceder
export POD_NAME=$(kubectl get pods -l app.kubernetes.io/instance=my-nginx -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 8080:8080 &

# Probar en otra terminal
curl http://localhost:8080
# Debería ver HTML de NGINX

# Terminar port-forward
pkill -f "port-forward"
```

### Paso 2.3: Personalizar con --set (3 min)

```bash
# Desinstalar el release anterior
helm uninstall my-nginx

# Instalar con custom replicas
helm install my-nginx bitnami/nginx --set replicaCount=3

# Verificar 3 réplicas
kubectl get pods -l app.kubernetes.io/instance=my-nginx

# Ver valores aplicados
helm get values my-nginx

# Ver TODOS los valores (defaults + overrides)
helm get values my-nginx --all
```

**✅ Checkpoint**: 3 pods de NGINX corriendo

### Paso 2.4: Personalizar con Archivo (2 min)

```bash
# Crear archivo de valores custom
cat > custom-nginx-values.yaml <<EOF
replicaCount: 2
service:
  type: NodePort
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
EOF

# Desinstalar release anterior
helm uninstall my-nginx

# Instalar con archivo custom
helm install my-nginx bitnami/nginx -f custom-nginx-values.yaml

# Verificar servicio tipo NodePort
kubectl get svc my-nginx

# Ver valores aplicados
helm get values my-nginx
```

**✅ Checkpoint**: Servicio tipo NodePort creado

---

## Parte 3: Gestionar Releases (8 min)

### Paso 3.1: Upgrade de Release (3 min)

```bash
# Hacer upgrade cambiando replicas
helm upgrade my-nginx bitnami/nginx --set replicaCount=4

# Ver historia de revisiones
helm history my-nginx

# Verificar 4 réplicas
kubectl get pods -l app.kubernetes.io/instance=my-nginx

# Ver manifest completo
helm get manifest my-nginx | head -50
```

**✅ Checkpoint**: History muestra 2 revisiones

### Paso 3.2: Rollback (2 min)

```bash
# Rollback a revisión anterior (2 réplicas)
helm rollback my-nginx

# Ver nueva revisión en historia
helm history my-nginx

# Verificar que volvió a 2 réplicas
kubectl get pods -l app.kubernetes.io/instance=my-nginx
```

**✅ Checkpoint**: Vuelta a 2 réplicas correctamente

### Paso 3.3: Dry-Run y Template (3 min)

```bash
# Simular upgrade sin aplicar
helm upgrade my-nginx bitnami/nginx \
  --set replicaCount=5 \
  --dry-run --debug | head -100

# Generar YAML sin instalar (template)
helm template my-test bitnami/nginx \
  --set replicaCount=3 > nginx-template.yaml

# Ver el YAML generado
cat nginx-template.yaml | head -50

# Validar que es YAML válido
kubectl apply --dry-run=client -f nginx-template.yaml
```

**✅ Checkpoint**: Ver YAML generado por template

---

## Parte 4: Instalar PostgreSQL (4 min)

### Paso 4.1: Instalar Database (2 min)

```bash
# Instalar PostgreSQL con configuración custom
helm install my-postgres bitnami/postgresql \
  --set auth.username=myuser \
  --set auth.password=mypassword \
  --set auth.database=mydb

# Ver estado
helm status my-postgres

# Ver pods
kubectl get pods -l app.kubernetes.io/instance=my-postgres
```

### Paso 4.2: Conectar a PostgreSQL (2 min)

```bash
# Obtener password (si no lo guardaste)
export POSTGRES_PASSWORD=$(kubectl get secret my-postgres-postgresql \
  -o jsonpath="{.data.postgres-password}" | base64 -d)

echo "Password: $POSTGRES_PASSWORD"

# Port-forward
kubectl port-forward svc/my-postgres-postgresql 5432:5432 &

# Conectar con psql (si está instalado)
# PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -U myuser -d mydb

# O usar pod de postgres
kubectl exec -it $(kubectl get pod -l app.kubernetes.io/instance=my-postgres -o jsonpath="{.items[0].metadata.name}") \
  -- psql -U myuser -d mydb -c "\dt"

# Terminar port-forward
pkill -f "port-forward.*5432"
```

**✅ Checkpoint**: Conexión exitosa a PostgreSQL

---

## Desafíos Adicionales (Opcionales)

### Desafío 1: WordPress Completo (5 min)

```bash
# Instalar WordPress con MariaDB
helm install my-wordpress bitnami/wordpress \
  --set wordpressUsername=admin \
  --set wordpressPassword=admin123 \
  --set wordpressEmail=admin@example.com

# Esperar a que esté listo
kubectl get pods -w -l app.kubernetes.io/instance=my-wordpress

# Obtener URL (si es LoadBalancer)
kubectl get svc my-wordpress

# O port-forward
kubectl port-forward svc/my-wordpress 8080:80
```

### Desafío 2: Múltiples Releases (3 min)

```bash
# Instalar 3 releases de NGINX diferentes
helm install nginx-dev bitnami/nginx -n dev --create-namespace
helm install nginx-staging bitnami/nginx -n staging --create-namespace
helm install nginx-prod bitnami/nginx -n prod --create-namespace --set replicaCount=3

# Listar todos
helm list -A

# Ver diferencias
helm get values nginx-dev -n dev
helm get values nginx-prod -n prod
```

### Desafío 3: Chart desde URL (2 min)

```bash
# Empaquetar chart local
helm create test-chart
helm package test-chart

# Instalar desde archivo .tgz
helm install my-test ./test-chart-0.1.0.tgz

# Desinstalar
helm uninstall my-test
```

---

## Cleanup (2 min)

```bash
# Listar todos los releases
helm list -A

# Desinstalar releases creados
helm uninstall my-nginx
helm uninstall my-postgres
helm uninstall my-wordpress  # Si lo instalaste

# Desinstalar releases en namespaces
helm uninstall nginx-dev -n dev
helm uninstall nginx-staging -n staging
helm uninstall nginx-prod -n prod

# Opcional: Eliminar namespaces
kubectl delete namespace dev staging prod

# Verificar limpieza
helm list -A
kubectl get pods --all-namespaces | grep nginx
```

---

## 📊 Resumen de Comandos Aprendidos

| Comando | Propósito |
|---------|-----------|
| `helm repo add` | Añadir repositorio |
| `helm repo update` | Actualizar índice |
| `helm search repo` | Buscar charts |
| `helm show values` | Ver configuración |
| `helm install` | Instalar release |
| `helm list` | Listar releases |
| `helm status` | Ver estado |
| `helm upgrade` | Actualizar release |
| `helm rollback` | Revertir cambios |
| `helm uninstall` | Desinstalar |
| `helm get values` | Ver valores aplicados |
| `helm template` | Generar YAML |
| `--dry-run --debug` | Simular sin aplicar |

---

## 🎯 Auto-Evaluación

- [ ] Puedo añadir repositorios de Helm
- [ ] Puedo buscar charts disponibles
- [ ] Puedo instalar aplicaciones con Helm
- [ ] Puedo personalizar con --set y -f
- [ ] Puedo hacer upgrade de releases
- [ ] Puedo hacer rollback si algo falla
- [ ] Entiendo la diferencia entre `helm template` y `helm install --dry-run`
- [ ] Puedo ver valores aplicados a un release
- [ ] Puedo desinstalar releases correctamente

---

## ⏱️ Timing CKAD

Para el examen CKAD:
- **Instalar chart**: 2-3 min
- **Personalizar con --set**: +1 min
- **Upgrade/Rollback**: 2 min
- **Total escenario típico**: 3-5 min

**Tip**: Memorizar `helm repo add bitnami https://charts.bitnami.com/bitnami`

---

## 🔍 Troubleshooting

### Problema: "Error: repo already exists"
```bash
helm repo list  # Ver repos existentes
helm repo remove bitnami  # Remover si es necesario
helm repo add bitnami https://charts.bitnami.com/bitnami
```

### Problema: Release no se instala
```bash
helm install myapp bitnami/nginx --dry-run --debug  # Ver qué falló
kubectl get events --sort-by='.lastTimestamp'  # Ver eventos K8s
```

### Problema: Pods no inician
```bash
kubectl get pods -l app.kubernetes.io/instance=my-nginx
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

---

**🎉 ¡Lab 01 Completado!**

**Próximo**: [Lab 02 - Crear Chart desde Cero](./lab-02-crear-chart.md)
