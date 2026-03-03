# 📁 Ejemplos - Módulo 01: Gestión de Clústeres AKS

Ejemplos prácticos para aprender los conceptos de gestión de clusters AKS.

---

## Índice de Ejemplos

| # | Ejemplo | Descripción | Nivel |
|---|---------|-------------|-------|
| 01 | [Crear Cluster AKS](01-crear-cluster-aks/) | Comandos para crear y configurar un cluster AKS desde cero | Básico |
| 02 | [Node Pools](02-node-pools/) | Gestión de system y user node pools | Intermedio |
| 03 | [Escalado de Cluster](03-escalado-cluster/) | Autoescalado de nodos y Pods (HPA + Cluster Autoscaler) | Intermedio |
| 04 | [Actualización de Cluster](04-actualizacion-cluster/) | Upgrade de versión de Kubernetes en AKS | Avanzado |

---

## Cómo Usar los Ejemplos

1. Navega al directorio del ejemplo que te interesa
2. Lee el `README.md` para entender el concepto
3. Aplica los manifiestos YAML con `kubectl apply -f <archivo>.yaml`
4. Experimenta modificando los valores
5. Limpia con `./cleanup.sh` al terminar

## Requisitos

- Azure CLI instalado y autenticado (`az login`)
- kubectl configurado para tu cluster AKS
- Para ejemplos locales: Minikube o kind

## Navegación

- ⬆️ [Volver al módulo](../README.md)
- 🔬 [Laboratorios](../laboratorios/)
