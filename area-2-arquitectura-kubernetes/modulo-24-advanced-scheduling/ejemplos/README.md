# Advanced Scheduling Examples

Complete YAML examples for all scheduling scenarios covered in Module 24.

## 📁 Files Overview

1. **affinity-examples.yaml** - Node affinity, pod affinity/anti-affinity
2. **taints-tolerations.yaml** - Taints and tolerations examples
3. **priority-classes.yaml** - Priority class definitions
4. **resource-quotas.yaml** - Namespace resource quotas
5. **limitrange-examples.yaml** - Container and pod limits
6. **static-pod-example.yaml** - Static pod for /etc/kubernetes/manifests
7. **complete-scheduling.yaml** - All features combined

---

## 🚀 Quick Start

```bash
# Apply all examples
kubectl apply -f affinity-examples.yaml
kubectl apply -f taints-tolerations.yaml
kubectl apply -f priority-classes.yaml
kubectl apply -f resource-quotas.yaml
kubectl apply -f limitrange-examples.yaml

# For static pod
sudo cp static-pod-example.yaml /etc/kubernetes/manifests/

# Test complete example
kubectl apply -f complete-scheduling.yaml
```

---

## 📖 Usage Guide

See individual files for detailed examples and use cases.

**See also:**
- [README Principal](../README.md)
- [RESUMEN](../RESUMEN-MODULO.md)
- [Laboratorios](../laboratorios/README.md)
