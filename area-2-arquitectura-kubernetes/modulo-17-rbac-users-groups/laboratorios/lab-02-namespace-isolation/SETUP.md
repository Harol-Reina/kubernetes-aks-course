# Prerequisites - Lab 02: Namespace Isolation

## Requisitos

- Cluster Kubernetes funcionando
- kubectl v1.24+
- openssl instalado
- Lab 01 completado (conocimientos básicos RBAC)

## Validación Rápida

```bash
kubectl cluster-info
kubectl auth can-i create roles
openssl version
```

Todo debe devolver resultados exitosos.

## Estructura de Archivos

```
lab-02-namespace-isolation/
├── README.md
├── SETUP.md (este archivo)
├── create-multi-users.sh
├── verify-isolation.sh
└── cleanup.sh
```

## Diferencias con Lab 01

| Aspecto | Lab 01 | Lab 02 |
|---------|--------|--------|
| Usuarios | 1 | 3 |
| Namespaces | 1 | 3 |
| Roles | 1 (lectura) | 3 (lectura, escritura, admin) |
| Complejidad | Básica | Media |

## Tiempo Estimado

- Setup: 10-15 min (automatizado)
- Verificación manual: 15-20 min
- Tests: 5-10 min (automatizado)
- **Total**: 30-45 min

Listo para comenzar → [README.md](./README.md)
