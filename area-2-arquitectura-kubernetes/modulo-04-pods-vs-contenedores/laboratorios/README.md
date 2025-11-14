# 🐳 Laboratorios - Pods vs Contenedores

Este módulo contiene laboratorios prácticos para comprender las diferencias entre Pods y Contenedores.

## 📋 Índice de Laboratorios

### [Lab 01: Evolución](./lab-01-evolucion/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐☆☆☆

Evolución de contenedores a Pods.

**Objetivos:**
- Comparar Docker containers vs Pods
- Entender por qué existen los Pods
- Limitaciones de containers standalone
- Ventajas del modelo Pod

---

### [Lab 02: Namespace Sharing](./lab-02-namespace-sharing/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐☆☆

Compartición de namespaces en Pods.

**Objetivos:**
- Network namespace compartido
- IPC namespace compartido
- PID namespace sharing
- Comunicación localhost entre containers

---

### [Lab 03: Sidecar Real World](./lab-03-sidecar-real-world/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Casos de uso reales de sidecar containers.

**Objetivos:**
- Logging sidecar
- Monitoring sidecar
- Proxy sidecar
- Patterns de producción

---

### [Lab 04: Init Migration](./lab-04-init-migration/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐☆☆

Migración de scripts init a Init Containers.

**Objetivos:**
- Migrar setup scripts
- Init Containers patterns
- Dependencias y orden
- Best practices

---

### [Lab 05: Compose Migration](./lab-05-compose-migration/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Migración de Docker Compose a Pods.

**Objetivos:**
- Analizar docker-compose.yml
- Convertir a manifiestos de Pod
- Networking equivalente
- Volúmenes compartidos

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Labs 01-02 (Conceptos fundamentales)
2. **Nivel Intermedio** → Labs 03-04 (Patrones reales)
3. **Nivel Avanzado** → Lab 05 (Migraciones complejas)

**Tiempo total estimado:** 6-8 horas

## 📚 Conceptos Clave

### Pod vs Container

**Container (Docker):**
- Unidad de ejecución individual
- Aislamiento completo
- Networking separado
- Gestión independiente

**Pod (Kubernetes):**
- Grupo de 1+ containers
- Namespaces compartidos
- IP compartida (localhost)
- Ciclo de vida común

### ¿Por qué Pods?

1. **Cohesión**: Containers relacionados juntos
2. **Comunicación**: localhost entre containers
3. **Recursos**: Compartición de volúmenes, network
4. **Despliegue**: Unidad atómica de deployment

### Namespaces Compartidos en Pods

```yaml
# Network: Misma IP, puertos únicos
containers:
- name: app
  ports:
  - containerPort: 8080
- name: sidecar
  ports:
  - containerPort: 9090  # Diferente puerto

# Volúmenes: Mismo emptyDir
volumes:
- name: shared-data
  emptyDir: {}
```

## ⚠️ Antes de Comenzar

```bash
# Verificar Docker (para comparaciones)
docker --version
docker ps

# Verificar Kubernetes
kubectl cluster-info
kubectl get pods

# Herramientas útiles
kubectl explain pod
kubectl explain pod.spec.containers
```

## 🧹 Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```

## 💡 Cuándo Usar Multi-Container Pods

✅ **SÍ usar cuando:**
- Containers altamente acoplados
- Necesitan compartir recursos (volumen, network)
- Tienen mismo ciclo de vida
- Sidecar/adapter/ambassador patterns

❌ **NO usar cuando:**
- Servicios independientes
- Escalado diferente
- Ciclo de vida diferente
- Mejor usar Deployments separados
