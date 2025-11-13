# Basic Helm Chart Example

Chart básico completo y funcional para aprender Helm desde cero.

## 📁 Estructura del Chart

```
basic-chart/
├── Chart.yaml              # Metadata del chart
├── values.yaml             # Valores por defecto
├── .helmignore            # Archivos a ignorar
└── templates/              # Templates de Kubernetes
    ├── deployment.yaml    # Deployment template
    ├── service.yaml       # Service template
    └── NOTES.txt         # Notas post-instalación
```

## 🚀 Uso Rápido

### 1. Validar el chart

```bash
cd basic-chart
helm lint .
```

### 2. Ver el YAML generado (dry-run)

```bash
helm template my-release .
```

### 3. Instalar el chart

```bash
# Instalación básica
helm install my-nginx .

# Con valores personalizados
helm install my-nginx . --set replicaCount=3

# Con archivo de valores custom
cat > custom-values.yaml <<EOF
replicaCount: 5
image:
  tag: "1.22.0"
service:
  type: NodePort
EOF

helm install my-nginx . -f custom-values.yaml
```

### 4. Verificar instalación

```bash
# Ver estado del release
helm status my-nginx

# Listar releases
helm list

# Ver pods creados
kubectl get pods -l release=my-nginx

# Ver service
kubectl get svc -l release=my-nginx
```

### 5. Acceder a la aplicación

```bash
# Port forward al servicio
kubectl port-forward svc/my-nginx-basic-chart-service 8080:80

# En otra terminal
curl http://localhost:8080
```

### 6. Actualizar release

```bash
# Cambiar número de réplicas
helm upgrade my-nginx . --set replicaCount=4

# Ver historial
helm history my-nginx
```

### 7. Rollback

```bash
# Rollback a revisión anterior
helm rollback my-nginx

# Rollback a revisión específica
helm rollback my-nginx 1
```

### 8. Desinstalar

```bash
helm uninstall my-nginx
```

## 📝 Personalización

### Valores disponibles (values.yaml)

```yaml
replicaCount: 2                    # Número de réplicas
image:
  repository: nginx                # Imagen del container
  tag: "1.21.0"                   # Tag de la imagen
  pullPolicy: IfNotPresent        # Pull policy

service:
  type: ClusterIP                 # Tipo de servicio
  port: 80                        # Puerto del servicio
  targetPort: 80                  # Puerto del container

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

customLabels:
  environment: development
  team: platform
```

## 🎯 Ejemplos de Uso

### Ejemplo 1: Desarrollo (1 réplica, ClusterIP)

```bash
helm install myapp-dev . --set replicaCount=1
```

### Ejemplo 2: Staging (3 réplicas, NodePort)

```bash
cat > values-staging.yaml <<EOF
replicaCount: 3
service:
  type: NodePort
image:
  tag: "1.22.0"
EOF

helm install myapp-staging . -f values-staging.yaml
```

### Ejemplo 3: Producción (5 réplicas, más recursos)

```bash
cat > values-prod.yaml <<EOF
replicaCount: 5
image:
  tag: "1.22.0"
  pullPolicy: IfNotPresent
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
customLabels:
  environment: production
  team: platform
EOF

helm install myapp-prod . -f values-prod.yaml
```

## 🔍 Troubleshooting

### Ver valores aplicados

```bash
helm get values my-nginx
helm get values my-nginx --all
```

### Ver manifest completo

```bash
helm get manifest my-nginx
```

### Debug template rendering

```bash
helm template my-nginx . --debug
```

### Ver eventos de Kubernetes

```bash
kubectl get events --sort-by='.lastTimestamp'
```

## 📚 Conceptos Aprendidos

✅ **Estructura de Chart**: Chart.yaml, values.yaml, templates/  
✅ **Templates**: Uso de `{{ .Values.* }}`, `{{ .Release.* }}`, `{{ .Chart.* }}`  
✅ **Funciones**: `toYaml`, `nindent` para formateo  
✅ **Condicionales**: `{{- if }}` para lógica  
✅ **Loops**: `{{- range }}` para iterar  
✅ **NOTES.txt**: Información post-instalación  
✅ **Ciclo de vida**: install → upgrade → rollback → uninstall

## 🎓 Próximos Pasos

1. **Modificar el chart**: Cambia valores en `values.yaml`
2. **Agregar recursos**: Crea `templates/configmap.yaml` o `templates/ingress.yaml`
3. **Helpers**: Aprende a usar `templates/_helpers.tpl`
4. **Dependencias**: Añade subchart en `Chart.yaml`

## 📖 Referencias

- [Helm Documentation](https://helm.sh/docs/)
- [Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Best Practices](https://helm.sh/docs/chart_best_practices/)
