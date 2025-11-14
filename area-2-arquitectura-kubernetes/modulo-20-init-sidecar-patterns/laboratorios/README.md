# 🔄 Laboratorios - Init Containers y Sidecar Patterns

Este módulo contiene laboratorios prácticos para dominar patrones multi-container en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: Init Containers](./lab-01-init-container/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

Introducción a Init Containers y su uso.

**Objetivos:**
- Crear Init Containers
- Configurar dependencias de inicio
- Compartir volúmenes entre init y main
- Casos de uso comunes

---

### [Lab 03: Multi-Container Patterns](./lab-03-multi-container/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Patrones avanzados multi-container.

**Objetivos:**
- Sidecar pattern
- Adapter pattern
- Ambassador pattern
- Comunicación entre containers

---

### [Lab 04: Service Mesh](./lab-04-service-mesh/)
**Duración:** 120-150 minutos | **Dificultad:** ⭐⭐⭐⭐⭐

Introducción a Service Mesh con sidecars.

**Objetivos:**
- Entender Service Mesh concepts
- Proxy sidecar pattern
- Traffic management
- Observability

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (Init Containers)
2. **Nivel Intermedio** → Lab 03 (Multi-container)
3. **Nivel Avanzado** → Lab 04 (Service Mesh)

**Tiempo total estimado:** 5-6 horas

## 📚 Patrones Multi-Container

### Init Containers
- Ejecutan antes del container principal
- Deben completarse exitosamente
- Útiles para setup, configuración, dependencias

**Casos de uso:**
- Esperar a que un servicio esté disponible
- Clonar código desde git
- Generar configuración dinámica
- Descargar datos o recursos

### Sidecar Pattern
- Container auxiliar que complementa el principal
- Comparten mismo pod, network, volumes
- Lifecycle ligado al container principal

**Casos de uso:**
- Logging y monitoreo
- Service mesh proxies
- Configuración dinámica
- Caching local

### Adapter Pattern
- Transforma la salida del container principal
- Estandariza interfaces
- No modifica el container principal

**Casos de uso:**
- Convertir formato de logs
- Normalizar métricas
- Transformar datos

### Ambassador Pattern
- Proxy para servicios externos
- Simplifica conectividad
- Abstrae complejidad de red

**Casos de uso:**
- Proxy a database
- Circuit breaker
- Rate limiting
- Service discovery

## ⚠️ Antes de Comenzar

```bash
# Verificar cluster
kubectl cluster-info

# Ver pods multi-container
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

# Describir pod para ver init containers
kubectl describe pod <pod-name>
```

## 🧹 Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```

## 💡 Best Practices

- Usa Init Containers para setup, no para lógica de negocio
- Sidecars deben ser ligeros y enfocados
- Comparte volúmenes emptyDir entre containers
- Define resources para todos los containers
- Considera el impacto en scheduling
