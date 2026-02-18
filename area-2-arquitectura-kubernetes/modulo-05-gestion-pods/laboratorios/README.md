# Laboratorios - Módulo 05: Gestión de Pods

> **Objetivo**: Dominar la creación y gestión de pods en Kubernetes  
> **Tiempo total estimado**: 90-120 minutos  
> **Nivel**: Principiante a Intermedio

## 📁 Estructura

```
laboratorios/
├── README.md                          # Este archivo
├── lab-01-crear-pods/                 # Creación básica de pods
│   ├── README.md                      # Instrucciones completas
│   ├── SETUP.md                       # Guía de setup
│   └── cleanup.sh                     # Script de limpieza
└── lab-02-multi-contenedor-labels/    # Multi-contenedor y labels
    ├── README.md
    ├── SETUP.md
    └── cleanup.sh
```

## 📋 Laboratorios Disponibles

### [Lab 01: Crear Pods](./lab-01-crear-pods/) ⭐⭐
**Duración**: 45-60 minutos | **Dificultad**: Principiante

**Objetivos**:
- Crear pods usando comandos imperativos (`kubectl run`)
- Crear pods usando manifiestos YAML
- Configurar recursos (requests/limits)
- Usar variables de entorno
- Inspeccionar y debuggear pods

**Archivos**:
- `README.md` - Instrucciones paso a paso
- `SETUP.md` - Prerequisitos y verificación
- `cleanup.sh` - Limpieza de recursos

**Conceptos cubiertos**:
- Comando `kubectl run`
- Estructura básica de manifiestos
- `kubectl describe` y `kubectl logs`
- Recursos CPU/memoria
- Variables de entorno

---

### [Lab 02: Multi-contenedor y Labels](./lab-02-multi-contenedor-labels/) ⭐⭐⭐
**Duración**: 45-60 minutos | **Dificultad**: Intermedio

**Objetivos**:
- Crear pods con múltiples contenedores
- Implementar patrón sidecar
- Implementar patrón ambassador
- Usar labels y selectors
- Filtrar pods con queries

**Archivos**:
- `README.md` - Instrucciones completas
- `SETUP.md` - Prerequisitos y setup
- `cleanup.sh` - Limpieza

**Conceptos cubiertos**:
- Multi-container pods
- Patrones: sidecar, ambassador, adapter
- Labels y annotations
- Selectors
- Namespace sharing

---

## 🚀 Guía de Uso

### Opción 1: Lab Individual

```bash
# Navegar al lab
cd lab-01-crear-pods/

# Leer prerequisitos
cat SETUP.md

# Ejecutar verificaciones
kubectl cluster-info
kubectl get nodes

# Seguir instrucciones del README
cat README.md

# Limpiar al finalizar
chmod +x cleanup.sh
./cleanup.sh
```

### Opción 2: Secuencia Completa

```bash
# Lab 01: Fundamentos
cd lab-01-crear-pods/
# Completar todas las tareas (45-60 min)
./cleanup.sh

# Lab 02: Avanzado
cd ../lab-02-multi-contenedor-labels/
# Completar todas las tareas (45-60 min)
./cleanup.sh
```

## 📊 Progresión de Dificultad

```
Lab 01 (⭐⭐)           Lab 02 (⭐⭐⭐)
Crear Pods            Multi-contenedor
Comandos básicos      Patrones avanzados
YAML simple           Labels/Selectors
kubectl run           Comunicación inter-container
```

## 🎯 Resultados de Aprendizaje

Después de completar estos laboratorios, serás capaz de:

**Lab 01 - Habilidades**:
- [ ] Crear pods imperativamente con `kubectl run`
- [ ] Escribir manifiestos YAML de pods desde cero
- [ ] Configurar requests y limits de recursos
- [ ] Usar variables de entorno en pods
- [ ] Debuggear pods con `describe` y `logs`
- [ ] Eliminar pods correctamente

**Lab 02 - Habilidades**:
- [ ] Crear pods con múltiples contenedores
- [ ] Implementar patrón sidecar (logging, proxy)
- [ ] Implementar patrón ambassador (proxy de BD)
- [ ] Aplicar labels a pods
- [ ] Filtrar pods usando selectors
- [ ] Entender namespace sharing entre contenedores

## 💡 Tips de Estudio

### Primera Pasada - Aprendizaje
1. Lee cada sección del README completo
2. Ejecuta comandos uno por uno
3. Observa la salida de cada comando
4. Experimenta con variaciones
5. Toma notas de errores comunes

### Segunda Pasada - Práctica
1. Intenta escribir manifiestos sin ayuda
2. Usa solo `kubectl --help` como referencia
3. Cronometra tu velocidad
4. Compara con soluciones del README

### Preparación CKAD
1. Practica creación de pods en <3 minutos
2. Memoriza estructura básica de manifiestos
3. Domina `kubectl run` con todas sus flags
4. Practica debugging rápido

## 🔧 Troubleshooting Común

### "Error creating pod: forbidden"
```bash
# Verificar permisos
kubectl auth can-i create pods

# Verificar contexto actual
kubectl config current-context
```

### "ImagePullBackOff"
```bash
# Verificar nombre de imagen
kubectl describe pod <pod-name> | grep Image

# Usar imagen alternativa
# nginx -> nginx:alpine
# busybox -> busybox:latest
```

### "Pod stays in Pending"
```bash
# Verificar recursos del nodo
kubectl describe nodes

# Verificar eventos
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 📚 Recursos Adicionales

- **Docs oficiales**: [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- **Multi-container**: [Pod Patterns](https://kubernetes.io/blog/2015/06/the-distributed-system-toolkit-patterns/)
- **Labels**: [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- **Cheatsheet**: Ver [RESUMEN-MODULO.md](../RESUMEN-MODULO.md)

## ✅ Checklist de Completitud

Marca cuando completes cada laboratorio:

- [ ] **Lab 01**: Crear Pods
  - [ ] Pods imperativos creados
  - [ ] Manifiestos YAML escritos
  - [ ] Recursos configurados
  - [ ] Variables de entorno usadas
  - [ ] Debugging practicado

- [ ] **Lab 02**: Multi-contenedor y Labels
  - [ ] Patrón sidecar implementado
  - [ ] Patrón ambassador implementado
  - [ ] Labels aplicados y usados
  - [ ] Selectors dominados
  - [ ] Comunicación inter-container comprendida

## 🎓 Próximos Pasos

1. Completa Lab 01 primero
2. Asegúrate de entender todos los conceptos
3. Practica Lab 01 hasta que sea fácil
4. Continúa con Lab 02
5. Experimenta con tus propios ejemplos
6. Siguiente módulo: **Módulo 06 - ReplicaSets y Réplicas**

---

**¡Buena suerte en tu aprendizaje! 🚀**

[Volver al README del módulo](../README.md)
