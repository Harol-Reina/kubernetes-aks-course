# Setup - Lab 01: Crear y Administrar Cluster AKS

## Prerrequisitos

| Requisito | Verificación |
|-----------|-------------|
| Azure CLI v2.49+ | `az version` |
| Cuenta Azure autenticada | `az account show` |
| Suscripción con cuota CPU | Azure Portal > Subscriptions > Usage |
| kubectl instalado | `kubectl version --client` |

## Verificación Rápida

```bash
# Ejecutar todo de una vez para verificar prerrequisitos
echo "=== Azure CLI ===" && az version --query '"azure-cli"' -o tsv && \
echo "=== Cuenta ===" && az account show --query name -o tsv && \
echo "=== kubectl ===" && kubectl version --client --short 2>/dev/null && \
echo "✅ Todo listo"
```

## Notas

- El cluster AKS tiene un coste asociado (~$2-5/hora para 2 nodos Standard_D2s_v3)
- Recuerda ejecutar `./cleanup.sh` al terminar para evitar costes innecesarios
- La creación del cluster tarda 5-10 minutos
