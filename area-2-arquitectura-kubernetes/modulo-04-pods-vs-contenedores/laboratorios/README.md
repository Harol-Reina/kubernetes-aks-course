# 🧪 Laboratorios - Módulo 04: Pods vs Contenedores

Los laboratorios prácticos de este módulo están integrados directamente en el **[README principal](../README.md)** en las secciones:

## 📍 Ubicación de los Laboratorios

### **Sección 6: Laboratorios Prácticos Mejorados**

Incluye 5 laboratorios completos:

1. **Lab 1: Evolución Histórica Práctica**
   - Experimenta LXC → Docker → Kubernetes
   - Compara aislamiento total vs bridge vs shared networking

2. **Lab 2: Namespace Sharing Deep Dive**
   - Explora namespaces compartidos (Network, PID, IPC, UTS)
   - Analiza diferencias con Mount y User namespaces

3. **Lab 3: Multi-Container Patterns**
   - Implementa patrón Sidecar con log processing
   - Construye aplicación web con Fluent Bit

4. **Lab 4: Init Containers**
   - Setup de aplicación con dependencias
   - Wait-for-db, migrations, config download

5. **Lab 5: Migración de Docker Compose**
   - Convierte docker-compose.yml a Kubernetes
   - Compara estrategias Multi-Pod vs Single-Pod

---

## 📁 Ejemplos Prácticos

Todos los archivos YAML necesarios están en la carpeta **[ejemplos/](../ejemplos/)**:

```
ejemplos/
├── 01-evolucion/evolution-pod.yaml
├── 02-namespaces/namespace-pod.yaml
├── 03-multi-container/sidecar-pod.yaml
├── 04-init-containers/
│   ├── postgres-pod.yaml
│   └── init-pod.yaml
└── 05-migracion-compose/
    ├── docker-compose.yml
    ├── web-deployment.yaml
    ├── api-deployment.yaml
    └── db-deployment.yaml
```

---

## 🚀 Cómo Usar

1. **Sigue los laboratorios en el README principal**: Contienen instrucciones paso a paso
2. **Usa los YAMLs de la carpeta ejemplos/**: Archivos listos para aplicar
3. **Consulta ejemplos/README.md**: Documentación detallada de cada ejemplo

---

## 🔗 Enlaces Directos

- **[README Principal del Módulo](../README.md)** - Teoría completa + Labs integrados
- **[Carpeta de Ejemplos](../ejemplos/)** - Archivos YAML organizados
- **[Documentación de Ejemplos](../ejemplos/README.md)** - Guía de uso

---

## 💡 Nota

Esta carpeta existe para mantener la estructura del curso, pero **no contiene laboratorios separados**. 

Todo el contenido práctico está:
- ✅ Integrado en el README principal (teoría + práctica juntas)
- ✅ Archivos YAML en carpeta `ejemplos/` (código reutilizable)

Este enfoque proporciona mejor experiencia de aprendizaje al combinar teoría y práctica en un solo lugar.
