---
name: refactor-labs
description: Refactoriza los laboratorios de un modulo de Kubernetes para usar archivos YAML separados y documentados, actualiza READMEs con tablas de tecnicas, mejora cleanup.sh, y crea un lab-resumen de 1 hora con Minikube.
argument-hint: "[modulo-path]"
disable-model-invocation: true
---

# Refactorizar Laboratorios de un Modulo

Refactoriza todos los laboratorios del modulo indicado en `$ARGUMENTS` siguiendo el patron establecido en modulos 08, 09 y 10.

## Paso 0: Analizar el modulo

1. Leer la estructura del modulo con `ls` y `Glob`
2. Identificar labs con READMEs completos vs stubs (los stubs se ignoran)
3. Leer cada lab README completo para entender que YAML tiene inline (heredoc)
4. Leer cada cleanup.sh existente

## Paso 1: Crear backups

Para cada lab con README completo, crear `README.md.backup`:

```bash
cp laboratorios/lab-XX/README.md laboratorios/lab-XX/README.md.backup
```

## Paso 2: Extraer YAML a archivos separados

Para cada bloque YAML inline (heredoc) en los READMEs, crear un archivo `.yaml` separado con esta estructura de documentacion:

```yaml
# Ejercicio N: Titulo del Ejercicio - Descripcion del Recurso
# Uso: kubectl apply -f nombre-archivo.yaml
#
# Descripcion:
#   Descripcion detallada de 2-3 lineas explicando que hace este
#   recurso y su proposito en el laboratorio.
#
# Conceptos clave:
#   - Concepto 1 relevante al recurso
#   - Concepto 2 relevante al recurso
#   - Concepto 3 relevante al recurso
#
# Namespace: default (o el namespace correspondiente)
---
apiVersion: ...
```

Convenciones para nombres de archivo:
- Usar nombres descriptivos en kebab-case: `deployment-backend.yaml`, `service-clusterip.yaml`
- Si un archivo es reutilizable con `-n`, indicarlo en la descripcion
- Si un YAML tiene multiples recursos separados por `---`, mantenerlos juntos si son logicamente relacionados

## Paso 3: Actualizar READMEs con tablas de tecnicas

Agregar dos tablas al inicio de cada lab README, despues del encabezado y antes de requisitos:

### Tabla 1: Tecnicas y Conceptos Utilizados

```markdown
## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Nombre Tecnica** | Descripcion de 1-2 lineas de la tecnica o concepto |
| **Otra Tecnica** | Descripcion correspondiente |
```

### Tabla 2: Archivos YAML del Laboratorio

```markdown
## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `nombre-archivo.yaml` | 1 | Descripcion breve del archivo |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |
```

### Actualizar comandos en el README

Reemplazar bloques heredoc/inline YAML por:

```bash
# Ver contenido del archivo
cat nombre-archivo.yaml

# Aplicar
kubectl apply -f nombre-archivo.yaml
```

## Paso 4: Actualizar cleanup.sh

Cada lab debe tener un cleanup.sh con el patron estandar del repositorio:

```bash
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab XX: Nombre...${NC}"

delete_resource() {
    local resource_type=$1
    local resource_name=$2
    if kubectl get $resource_type $resource_name &> /dev/null; then
        kubectl delete $resource_type $resource_name --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# Eliminar recursos especificos del lab
delete_resource deployment mi-deployment
delete_resource service mi-service

echo -e "\n${GREEN}🎉 Limpieza del Lab XX completada!${NC}"
```

Para labs que usan namespaces dedicados, eliminar el namespace directamente (borra todo):

```bash
for ns in namespace-1 namespace-2; do
    if kubectl get namespace $ns &> /dev/null; then
        kubectl delete namespace $ns
        echo -e "  ${GREEN}✓ namespace/$ns eliminado${NC}"
    fi
done
```

Hacer ejecutable: `chmod +x cleanup.sh`

## Paso 5: Crear lab-resumen

Crear directorio `laboratorios/lab-resumen-TEMA/` con 3 archivos:

### 5.1: YAML unico (TEMA-lab.yaml)

Un solo archivo YAML que despliega TODO lo necesario para practicar los conceptos del modulo. Incluir:
- Comentarios de seccion numerados explicando cada recurso
- Header completo con descripcion, duracion, lista de conceptos
- Todos los recursos en un namespace dedicado `lab-TEMA` o multiples namespaces segun el tema
- Recursos variados que cubran los conceptos principales del modulo

### 5.2: README.md del lab-resumen

Estructura:

```markdown
# Resumen Practico: Titulo del Modulo

**Duracion:** 60 minutos | **Nivel:** Repaso integral | **Archivo:** `tema-lab.yaml`

Descripcion de 1-2 lineas.

---

## Que es [Concepto Principal]

Explicacion de 2-3 parrafos del concepto central.

## Conceptos Cubiertos en Este Lab

| Concepto | Que demuestra |
|----------|---------------|
| **Concepto 1** | Descripcion breve |

## Diagrama Visual

(Diagrama ASCII del lab)

## Paso 0: Preparar Minikube (2 min)

## Paso 1: Desplegar Todo (2 min)
kubectl apply -f tema-lab.yaml

## Pasos 2-7: Ejercicios guiados
(Cada paso con comandos, salida esperada, explicacion)

## Tabla Comparativa
(Tabla ASCII comparando los conceptos)

## Cuando Usar Cada Concepto
(Tabla de situaciones -> concepto -> justificacion)

## Limpieza (2 min)
chmod +x cleanup.sh && ./cleanup.sh

## Checklist de Verificacion
(Lista de verificacion con [ ])
```

### 5.3: cleanup.sh del lab-resumen

Elimina el namespace dedicado del lab y restaura el contexto a default.

## Paso 6: Actualizar indice de laboratorios

Actualizar `laboratorios/README.md` para:
- Listar los archivos YAML de cada lab actualizado
- Agregar entrada del nuevo lab-resumen al final
- Mantener el formato existente del indice

## Paso 7: Hacer ejecutables los scripts

```bash
chmod +x laboratorios/*/cleanup.sh
```

## Paso 8: Verificar

- Listar todos los archivos creados/modificados con `find`
- Verificar que no quedan heredoc YAML en los READMEs actualizados
- Confirmar que cada lab tiene su tabla de tecnicas

## Notas importantes

- **NO** modificar labs stub (sin README completo)
- **NO** incluir archivos .backup en git (estan en .gitignore)
- Los archivos YAML reutilizables con `-n` no deben especificar namespace en el YAML
- El lab-resumen siempre usa Minikube y dura 60 minutos
- Seguir el idioma del repositorio: contenido en espanol, terminos tecnicos en ingles
