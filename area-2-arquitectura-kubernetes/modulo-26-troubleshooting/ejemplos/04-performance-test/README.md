# Ejemplo 04: Performance Testing - Tests de Rendimiento y Recursos

> **Objetivo**: Simular escenarios de performance y límites de recursos  
> **Dificultad**: ⭐⭐⭐⭐ (Avanzado)  
> **Tiempo estimado**: 40-50 minutos

## 📋 Descripción

10 escenarios para testear y troubleshoot performance, recursos, QoS, y comportamiento bajo presión.

## 🎯 Tests Incluidos

1. **Memory Stress** - stress con 250M RAM
2. **CPU Stress** - stress con 2 cores
3. **ResourceQuota** - Límites por namespace
4. **LimitRange** - Defaults y límites
5. **Memory Leak Simulator** - Consumo creciente
6. **Disk I/O Stress** - dd para test de disco
7. **HPA con Load** - Autoscaling bajo carga
8. **QoS Classes** - Guaranteed, Burstable, BestEffort
9. **Node Pressure** - Memory hog para simular presión
10. **PriorityClass** - Eviction por prioridad

## 📁 Archivos

```
04-performance-test/
├── README.md                    # Este archivo
├── performance-test.yaml        # 10 escenarios de testing
├── load-generator.sh            # Script para generar carga
└── cleanup.sh                   # Limpieza
```

## 🚀 Uso Rápido

```bash
# Aplicar tests
kubectl apply -f performance-test.yaml

# Monitorear recursos
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=memory

# Generar carga
chmod +x load-generator.sh
./load-generator.sh
```

## 📊 Comandos de Monitoreo

```bash
# Resources por node
kubectl describe nodes | grep -A 10 "Allocated resources"

# Top consumers
kubectl top pods --all-namespaces --sort-by=cpu
kubectl top pods --all-namespaces --sort-by=memory

# QoS Classes
kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass

# Events de eviction
kubectl get events --field-selector reason=Evicted

# ResourceQuotas
kubectl describe resourcequota -n <namespace>
```

## 🧹 Limpieza

```bash
./cleanup.sh
```

## 💡 Key Learnings

- **Memory stress**: Útil para test de OOMKilled
- **ResourceQuota**: Limita uso total en namespace
- **LimitRange**: Establece defaults y bounds
- **QoS Guaranteed**: requests = limits (mejor protección)
- **QoS Burstable**: requests < limits (flexible)
- **QoS BestEffort**: sin requests/limits (first to evict)
- **PriorityClass**: Controla eviction order

---

**Siguiente**: [Ejemplo 05 - RBAC Debugging](../05-rbac-debugging/)
