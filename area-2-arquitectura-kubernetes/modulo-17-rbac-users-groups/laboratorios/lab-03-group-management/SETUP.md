# Prerequisites - Lab 03

Mismo setup que Lab 01 y Lab 02.

## Nuevo Concepto

**Organization field** en certificados:
- Define el grupo del usuario
- Formato: `/CN=username/O=groupname`
- Múltiples usuarios pueden tener mismo O

## Validación

```bash
kubectl cluster-info
openssl version
```

Listo → [README.md](./README.md)
