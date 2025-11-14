# Laboratorios - Módulo 21: Helm Basics

> **Objetivo**: Dominar los fundamentos de Helm para gestionar aplicaciones en Kubernetes  
> **Tiempo total estimado**: 75-90 minutos  
> **Nivel**: Intermedio

## 📁 Estructura

```
laboratorios/
├── README.md                   # Este archivo
└── lab-01-helm-basics/         # Fundamentos de Helm
    ├── README.md               # Instrucciones completas
    ├── SETUP.md                # Instalación y setup de Helm
    └── cleanup.sh              # Script de limpieza
```

## 📋 Laboratorio Disponible

### [Lab 01: Helm Basics](./lab-01-helm-basics/) ⭐⭐⭐
**Duración**: 75-90 minutos | **Dificultad**: Intermedio

**Objetivos**:
- Instalar y configurar Helm 3
- Buscar y explorar charts en repositorios
- Instalar aplicaciones usando Helm charts
- Personalizar instalaciones con valores
- Actualizar y hacer rollback de releases
- Crear un chart básico desde cero
- Gestionar repositorios de charts

**Archivos**:
- `README.md` - Instrucciones paso a paso
- `SETUP.md` - Instalación de Helm y prerequisitos
- `cleanup.sh` - Limpieza de releases y recursos

**Conceptos cubiertos**:
- Comandos Helm: install, upgrade, rollback, uninstall
- Repositorios de charts
- Values files (values.yaml)
- Templates y personalización
- Chart structure
- Helm lifecycle management
- Best practices

---

## 🚀 Guía de Uso

```bash
# Navegar al lab
cd lab-01-helm-basics/

# Leer prerequisitos e instalar Helm
cat SETUP.md

# Verificar Helm instalado
helm version

# Seguir instrucciones
cat README.md

# Limpiar al finalizar
chmod +x cleanup.sh
./cleanup.sh
```

## 🎯 Resultados de Aprendizaje

Después de completar este laboratorio, serás capaz de:

- [ ] Instalar Helm 3 en tu sistema
- [ ] Agregar y gestionar repositorios de charts
- [ ] Buscar charts disponibles
- [ ] Instalar aplicaciones con `helm install`
- [ ] Personalizar deployments con values.yaml
- [ ] Actualizar releases con `helm upgrade`
- [ ] Hacer rollback de releases
- [ ] Listar y verificar releases instalados
- [ ] Crear charts personalizados básicos
- [ ] Entender la estructura de un chart
- [ ] Usar `helm template` para debugging

## 💡 Tips de Estudio

### Comandos Esenciales

```bash
# Gestión de repositorios
helm repo add <name> <url>
helm repo update
helm repo list
helm search repo <keyword>

# Gestión de releases
helm install <name> <chart>
helm list
helm status <name>
helm upgrade <name> <chart>
helm rollback <name> <revision>
helm uninstall <name>

# Debugging
helm template <name> <chart>
helm get values <name>
helm get manifest <name>
```

### Workflow Típico

```
1. Buscar chart → helm search repo nginx
2. Inspeccionar → helm show values bitnami/nginx
3. Personalizar → Crear values.yaml
4. Instalar → helm install mi-app bitnami/nginx -f values.yaml
5. Verificar → helm status mi-app
6. Actualizar → helm upgrade mi-app bitnami/nginx
7. Rollback si falla → helm rollback mi-app
8. Limpiar → helm uninstall mi-app
```

## 🔧 Troubleshooting Común

### "Error: Kubernetes cluster unreachable"
```bash
# Verificar contexto
kubectl config current-context

# Verificar conexión
kubectl cluster-info
```

### "Error: repo not found"
```bash
# Agregar repositorio
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### "Release failed"
```bash
# Ver status
helm status <release-name>

# Ver logs
kubectl logs -l app=<release-name>

# Hacer rollback
helm rollback <release-name>
```

## 📚 Recursos Adicionales

- **Helm Docs**: [helm.sh/docs](https://helm.sh/docs/)
- **Artifact Hub**: [artifacthub.io](https://artifacthub.io/) - Buscar charts
- **Bitnami Charts**: [github.com/bitnami/charts](https://github.com/bitnami/charts)
- **Chart Best Practices**: [helm.sh/docs/chart_best_practices](https://helm.sh/docs/chart_best_practices/)

## 🎓 Próximos Pasos

1. Completa el Lab 01
2. Practica instalando diferentes aplicaciones
3. Experimenta creando tus propios charts
4. Explora [Artifact Hub](https://artifacthub.io) para descubrir más charts
5. Siguiente módulo: **Módulo 22 - Cluster Setup con Kubeadm**

---

**¡Buena suerte con Helm! ⎈**

[Volver al módulo](../README.md) | [Ver ejemplos](../ejemplos/)
