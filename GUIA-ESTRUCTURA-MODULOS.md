# 📐 Guía de Estructura de Módulos - Curso Kubernetes

> **Documento de Referencia**: Estándares y plantillas para crear/actualizar módulos del curso manteniendo consistencia pedagógica.

---

## 🎯 Propósito de esta Guía

Este documento establece la **estructura estándar** que TODOS los módulos del curso deben seguir para garantizar:
- ✅ Consistencia pedagógica en los 18 módulos
- ✅ Navegación uniforme para estudiantes
- ✅ Experiencia de aprendizaje optimizada
- ✅ Facilidad de mantenimiento y actualización

---

## 📋 Checklist de Creación/Actualización

Antes de considerar un módulo "completo", verificar:

- [ ] **README.md** tiene header pedagógico completo (~250-400 líneas)
- [ ] **RESUMEN-MODULO.md** existe y es comprehensivo (~900-1,400 líneas)
- [ ] **README.md.backup** creado antes de modificaciones
- [ ] Todas las secciones del header están presentes
- [ ] Rutas de estudio definidas (Principiante, Intermedia, Certificación)
- [ ] Ejemplos y laboratorios documentados
- [ ] Conexiones con otros módulos explicadas
- [ ] Comandos y code blocks tienen sintaxis correcta
- [ ] Emojis consistentes con el estándar del curso

---

## 📁 Estructura de Archivos por Módulo

```
modulo-XX-nombre-descriptivo/
├── README.md                      # Contenido principal + header pedagógico
├── README.md.backup              # Backup antes de modificaciones
├── RESUMEN-MODULO.md             # Guía de estudio rápida
├── ejemplos/                     # 5-10 directorios de ejemplos
│   ├── 01-concepto-basico/
│   │   ├── README.md
│   │   ├── ejemplo.yaml
│   │   └── commands.md
│   ├── 02-concepto-intermedio/
│   └── ...
└── laboratorios/                 # Labs prácticos
    ├── README.md                 # Índice de labs
    ├── lab-01-basico.md
    ├── lab-02-intermedio.md
    └── lab-03-avanzado.md
```

---

## 🏗️ Estructura del README.md

### 1. Título y Descripción (Líneas 1-5)

```markdown
# 🎯 Módulo XX: Título Descriptivo del Módulo

> **Subtítulo Atractivo**: Descripción concisa de 1 línea que explique el valor del módulo.

---
```

**Reglas**:
- Emoji relevante al tema (🎯 gestión, 🔄 réplicas, 🚀 despliegue, 🔐 seguridad, etc.)
- Título claro y descriptivo
- Subtítulo que responda: "¿Qué aprenderé aquí?"

---

### 2. Objetivos de Aprendizaje (~80-120 líneas)

```markdown
## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### 🎓 Objetivos Conceptuales
- **Concepto clave 1**: Breve explicación
- **Concepto clave 2**: Breve explicación
- **Concepto clave 3**: Breve explicación
- **Concepto clave 4**: Breve explicación

### 🛠️ Objetivos Técnicos
- **Habilidad técnica 1**: Qué hacer específicamente
- **Habilidad técnica 2**: Comandos o configuraciones
- **Habilidad técnica 3**: Implementación práctica
- **Habilidad técnica 4**: Integración o uso avanzado

### 🔍 Objetivos de Troubleshooting
- **Diagnosticar problema 1**: Cómo identificar y resolver
- **Resolver error 2**: Pasos de diagnóstico
- **Debugging técnica 3**: Herramientas y comandos
- **Analizar issue 4**: Interpretación de logs/eventos

### 🏢 Objetivos Profesionales
- **Aplicación en producción 1**: Contexto real
- **Best practice 2**: Estándares de la industria
- **Preparación certificación**: CKA/CKAD relevancia (%)
- **Skill empresarial 4**: Valor para el CV

---
```

**Reglas**:
- SIEMPRE 4 categorías en este orden
- 4-6 objetivos por categoría
- Usar negritas para el concepto, seguido de explicación
- Mencionar certificaciones cuando sea relevante

---

### 3. Prerrequisitos (~40-60 líneas)

```markdown
## ✅ Prerrequisitos

### Conocimientos Previos
- ✅ **Módulo X completado**: Qué necesitas saber
- ✅ **Concepto técnico**: Nivel requerido
- ✅ **Herramienta**: Familiaridad esperada
- ✅ **Skill adicional**: Si aplica

### Herramientas Necesarias
- 🔧 **Herramienta 1**: Para qué se usa
- 🔧 **Herramienta 2**: Configuración necesaria
- 🔧 **Herramienta 3**: Versión mínima

### Verificación
```bash
# Comando 1 para verificar prerrequisito
comando --version

# Comando 2 para verificar setup
otro-comando check

# Comando 3 para validar estado
kubectl get nodes
# Salida esperada: comentario
```

---
```

**Reglas**:
- Siempre dividir en: Conocimientos, Herramientas, Verificación
- Comandos de verificación DEBEN incluir comentarios de salida esperada
- Ser específico en versiones cuando sea crítico

---

### 4. Estructura del Módulo (~50-80 líneas)

```markdown
## 🗺️ Estructura del Módulo

### Contenido Teórico (XX minutos)
1. **Sección 1** (XX min) - Descripción breve
2. **Sección 2** (XX min) - Descripción breve
3. **Sección 3** (XX min) - Descripción breve
4. **Sección 4** (XX min) - Descripción breve

### Contenido Práctico (XX-XX minutos)
1. **Lab 1** (XX min) - Objetivo del lab
2. **Lab 2** (XX min) - Objetivo del lab
3. **Lab 3** (XX min) - Objetivo del lab
4. **Ejercicios** (XX min) - Práctica adicional

### Ejemplos Prácticos (X directorios)
- 📁 **01-concepto-basico/** - Descripción
- 📁 **02-concepto-intermedio/** - Descripción
- 📁 **03-concepto-avanzado/** - Descripción
- 📁 **04-pattern-común/** - Descripción
- 📁 **05-troubleshooting/** - Descripción
- 📁 **...-...-.../** - Más ejemplos según necesidad

### Laboratorios
- 🔬 **Lab 01**: Título descriptivo del lab
- 🔬 **Lab 02**: Título descriptivo del lab
- 🔬 **Lab 03**: Título descriptivo del lab
- 🔬 **Lab 04**: Título descriptivo del lab (si aplica)

---
```

**Reglas**:
- Tiempos realistas (teoría: 60-120 min, práctica: 120-240 min)
- Listar TODOS los directorios de ejemplos existentes
- Labs numerados secuencialmente
- Emojis: 📁 para carpetas, 🔬 para labs

---

### 5. Rutas de Estudio (~100-150 líneas)

```markdown
## 📚 Rutas de Estudio Recomendadas

### 🟢 Ruta Principiante (Primera vez con el tema)
**Tiempo**: X-X horas (distribución realista)
```
Día 1: Fundamentos (XX min)
  ├─ Sección 1: Teoría básica (XX min)
  │   └─ Entender conceptos core
  ├─ Lab 01: Práctica básica (XX min)
  │   └─ Primer contacto
  └─ Revisión (XX min)
      └─ Consolidar conocimiento

Día 2: Práctica Intermedia (XX min)
  ├─ Sección 2: Teoría avanzada (XX min)
  ├─ Labs 02-03 (XX min)
  └─ Ejercicios (XX min)

Día 3: Consolidación (XX min)
  ├─ RESUMEN-MODULO.md (XX min)
  └─ Preguntas de repaso (XX min)
```

### 🟡 Ruta Intermedia (Ya conoces el tema)
**Tiempo**: X-X horas
```
Sesión 1: Teoría concentrada (XX min)
  ├─ Lectura enfocada en puntos clave
  └─ Saltar lo básico, enfoque en avanzado

Sesión 2: Práctica intensiva (XX min)
  ├─ Labs principales (saltando básicos)
  └─ Ejercicios desafiantes

Sesión 3: Repaso (XX min)
  └─ RESUMEN-MODULO.md + troubleshooting
```

### 🔴 Ruta Certificación (CKA/CKAD)
**Tiempo**: XX-XX minutos
```
Estrategia Examen:
  ├─ RESUMEN-MODULO.md primero (XX min)
  │   ├─ Comandos esenciales
  │   ├─ YAML templates
  │   └─ Cheat sheet
  │
  ├─ Práctica de comandos (XX min)
  │   ├─ Comando 1 (repetir 5 veces)
  │   ├─ Comando 2 (repetir 5 veces)
  │   └─ Comando 3 (escenarios)
  │
  └─ Memorización (XX min)
      ├─ Conceptos clave para examen
      └─ Shortcuts y alias

CKA: XX% del examen (sección relevante)
CKAD: XX% del examen (sección relevante)
```

---
```

**Reglas**:
- SIEMPRE 3 rutas: Principiante, Intermedia, Certificación
- Usar formato de árbol ASCII con └─ ├─
- Tiempos realistas y específicos
- Mencionar % del examen en ruta certificación
- Incluir distribución por días para principiantes

---

### 6. Organización de Recursos (~60-100 líneas)

```markdown
## 📁 Organización de Recursos

### Carpeta `ejemplos/`
```
ejemplos/
├── 01-nombre-ejemplo/
│   ├── README.md                      # Explicación del ejemplo
│   ├── archivo-ejemplo.yaml           # Manifest o código
│   └── commands.md                    # Comandos para ejecutar
│
├── 02-nombre-ejemplo/
│   ├── README.md
│   ├── archivo1.yaml
│   ├── archivo2.yaml
│   └── script.sh
│
├── 03-nombre-ejemplo/
│   └── ...
│
└── XX-nombre-ejemplo/
    └── ...
```

### Carpeta `laboratorios/` (si existe)
```
laboratorios/
├── README.md                          # Índice de laboratorios
├── lab-01-nombre-descriptivo.md       # Lab paso a paso
├── lab-02-nombre-descriptivo.md       # Lab intermedio
└── lab-03-nombre-descriptivo.md       # Lab avanzado
```

---
```

**Reglas**:
- Usar bloques de código con ``` para la estructura de árbol
- Comentarios explicativos a la derecha de cada archivo
- Listar estructura REAL del módulo (no inventar)
- Incluir labs si existen

---

### 7. Metodología de Aprendizaje (~40-60 líneas)

```markdown
## 🎯 Metodología de Aprendizaje

Este módulo es **XX% teórico, XX% práctico**:

### Distribución de Contenido
```
💻 Práctica hands-on       XX%  ██████████▓░░░░░░░░░
📖 Teoría y conceptos      XX%  ██████▓░░░░░░░░░░░░░
🔍 Troubleshooting         XX%  ████▓░░░░░░░░░░░░░░░
🎯 Ejercicios avanzados    XX%  ██▓░░░░░░░░░░░░░░░░░
```

### Enfoque Pedagógico
1. **Principio pedagógico 1**: Explicación
2. **Principio pedagógico 2**: Explicación
3. **Principio pedagógico 3**: Explicación
4. **Principio pedagógico 4**: Explicación

### Flujo de Trabajo
```
1. Paso inicial → 2. Acción → 3. Verificación
                ↓
4. Siguiente paso → 5. Práctica → 6. Consolidación
                ↓
7. Troubleshooting → 8. Corrección → 9. Dominio
```

---
```

**Reglas**:
- Porcentajes deben sumar 100%
- Barras de progreso visuales con bloques █ ▓ ░
- Flujo de trabajo en formato de árbol ASCII
- Ser honesto con la distribución teórico/práctico

---

### 8. Conexión con Otros Módulos (~40-60 líneas)

```markdown
## 🔗 Conexión con Otros Módulos

### Este Módulo te Prepara Para
- ➡️ **Módulo XX**: Título (cómo se relaciona)
- ➡️ **Módulo XX**: Título (qué usarás de aquí)
- ➡️ **Módulo XX**: Título (dependencia directa)
- ➡️ **Área X**: Tema avanzado (aplicación futura)

### Relación con Módulos Anteriores
```
Módulo XX: Fundamento previo
    ↓
Módulo YY: Construcción sobre eso
    ↓
Módulo ZZ: Este módulo ← ESTÁS AQUÍ
    ↓
Módulo AA: Siguiente paso lógico
```

---
```

**Reglas**:
- Siempre dos secciones: "Prepara Para" y "Relación con Anteriores"
- Usar ➡️ para módulos futuros
- Diagrama de flujo ASCII mostrando posición actual
- Marcar posición actual con ← ESTÁS AQUÍ

---

### 9. Conceptos Clave Previos (Opcional, ~40-80 líneas)

```markdown
## 💡 Conceptos Clave Previos

### Concepto Central del Módulo

**Definición clara en 1-2 oraciones**

```
DIAGRAMA ASCII O VISUAL SIMPLE:
┌─────────────────────┐
│   Componente A      │
│  ┌──────────┐       │
│  │  Parte 1 │       │
│  └──────────┘       │
│  ┌──────────┐       │
│  │  Parte 2 │       │
│  └──────────┘       │
└─────────────────────┘
```

**Explicación**:
- Punto clave 1
- Punto clave 2
- Punto clave 3

### Comparación Importante

| Aspecto | Opción A | Opción B |
|---------|----------|----------|
| **Característica 1** | Valor | Valor |
| **Característica 2** | Valor | Valor |
| **Característica 3** | Valor | Valor |
| **Uso recomendado** | Escenario | Escenario |

---
```

**Reglas**:
- Usar solo si hay un concepto que necesita clarificación antes del contenido principal
- Diagramas ASCII simples y claros
- Tablas comparativas cuando aplique
- Mantener conciso (no repetir contenido del módulo)

---

### 10. Objetivos del Módulo Expandido (~30-50 líneas)

```markdown
## 🎯 Objetivos del Módulo (Expandido)

Al completar este módulo serás capaz de:

- ✅ **Objetivo detallado 1** con contexto adicional
- ✅ **Objetivo detallado 2** incluyendo casos de uso
- ✅ **Objetivo detallado 3** con ejemplos concretos
- ✅ **Objetivo detallado 4** y su aplicación práctica
- ✅ **Objetivo detallado 5** relacionado con troubleshooting
- ✅ **Objetivo detallado 6** para producción
- ✅ **Objetivo detallado 7** preparación certificación
- ✅ **Objetivo detallado 8** integración con otros módulos

---
```

**Reglas**:
- Resume los objetivos de las 4 categorías en una lista unificada
- 8-12 objetivos totales
- Formato: ✅ **Negrita** seguido de descripción
- Cada uno debe ser verificable/medible
- Última sección antes del contenido principal del módulo

---

## 📄 Estructura del RESUMEN-MODULO.md

El archivo RESUMEN debe ser una **guía de estudio autónoma** (~900-1,400 líneas).

### Secciones Obligatorias

```markdown
# 📝 RESUMEN: Título del Módulo

> **Guía de Estudio Rápida** - Subtítulo explicativo

---

## 🎯 Conceptos Clave en 5 Minutos

### ¿Qué es [Concepto Principal]?
Explicación concisa en 2-3 párrafos

### Analogía Simple
Comparación con algo cotidiano

### Diagrama Básico
```
ASCII art simple explicando arquitectura/flujo
```

---

## 📊 [Sección 2: Conceptos Técnicos Principales]

### Concepto Técnico 1
- Explicación detallada
- Ejemplos de código
- Comandos esenciales

### Concepto Técnico 2
- Explicación detallada
- Casos de uso
- Comparaciones

[Continuar con 4-7 secciones técnicas principales]

---

## 🛠️ Comandos Esenciales

### Operaciones Básicas
```bash
# Comando 1 con explicación
kubectl comando parametros
# Salida esperada

# Comando 2 con explicación
kubectl comando parametros
# Salida esperada
```

### Operaciones Intermedias
```bash
# Comandos más avanzados
```

### Troubleshooting
```bash
# Comandos de diagnóstico
```

---

## 📋 Cheat Sheet / Referencia Rápida

### Tabla de Referencia

| Aspecto | Valor/Comando | Notas |
|---------|---------------|-------|
| Item 1 | Valor | Explicación |
| Item 2 | Valor | Explicación |

### Snippets YAML Comunes

```yaml
# Template 1
apiVersion: v1
kind: Pod
metadata:
  name: ejemplo
spec:
  # ...
```

---

## 🔍 Troubleshooting Común

### Problema 1: [Descripción]

**Síntoma**:
```
Error o comportamiento observado
```

**Diagnóstico**:
```bash
# Comandos para diagnosticar
kubectl describe ...
```

**Solución**:
```bash
# Pasos para resolver
kubectl fix ...
```

[Repetir para 4-6 problemas comunes]

---

## 📋 Checklist de Conceptos Clave

### Categoría 1
- [ ] Concepto verificable 1
- [ ] Concepto verificable 2
- [ ] Concepto verificable 3

### Categoría 2
- [ ] Concepto verificable 4
- [ ] Concepto verificable 5
- [ ] Concepto verificable 6

[3-4 categorías total]

---

## ❓ Preguntas de Repaso

### Conceptuales

1. **Pregunta conceptual sobre fundamentos**
   <details>
   <summary>Ver respuesta</summary>
   
   Respuesta detallada con:
   - Explicación
   - Ejemplos
   - Código si aplica
   </details>

2. **Pregunta sobre arquitectura o diseño**
   <details>
   <summary>Ver respuesta</summary>
   
   Respuesta completa
   </details>

### Técnicas

3. **Pregunta práctica con comandos**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Comandos con explicación
   kubectl comando
   ```
   
   Explicación del resultado
   </details>

### Troubleshooting

4. **Escenario de problema**
   <details>
   <summary>Ver respuesta</summary>
   
   Pasos de diagnóstico y solución
   </details>

### Profesionales

5. **Pregunta de decisión/diseño**
   <details>
   <summary>Ver respuesta</summary>
   
   Análisis de trade-offs y recomendaciones
   </details>

[10-15 preguntas total]

---

## 🎓 Para Certificaciones

### CKA (Certified Kubernetes Administrator)

**Temas de este módulo en el examen**:
- ✅ Tema relevante (XX% del examen)
- ✅ Tema relevante (sección específica)

**Comandos que DEBES saber**:
```bash
# Lista de comandos críticos para examen
```

### CKAD (Certified Kubernetes Application Developer)

**Relevancia para CKAD**: [Alta/Media/Baja]

**Enfoque**:
- En qué concentrarse
- Qué saltear
- Tiempo recomendado

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [Enlace a docs oficiales](URL)
- [Enlace a API reference](URL)

### Herramientas
- **Herramienta 1**: Descripción y enlace
- **Herramienta 2**: Descripción y enlace

---

## 🎯 Siguiente Paso

[Descripción del siguiente módulo y cómo se conecta]

➡️ **Módulo XX: Título** - Qué aprenderás

---

**📊 Estadísticas de este módulo**:
- Conceptos principales: X
- Comandos esenciales: X
- Ejemplos prácticos: X
- Labs disponibles: X
- Tiempo estimado: X-X horas

**✅ Checklist final**: ¿Pregunta de verificación de dominio? Si sí → continúa.
```

---

## 🎨 Estándares de Formato

### Emojis Estándar por Sección

| Sección | Emoji | Uso |
|---------|-------|-----|
| Objetivos de Aprendizaje | 📋 | Siempre al inicio |
| Objetivos Conceptuales | 🎓 | Subsección |
| Objetivos Técnicos | 🛠️ | Subsección |
| Objetivos Troubleshooting | 🔍 | Subsección |
| Objetivos Profesionales | 🏢 | Subsección |
| Prerrequisitos | ✅ | Checkmarks |
| Herramientas | 🔧 | Items de herramientas |
| Estructura | 🗺️ | Mapa del módulo |
| Carpetas/Ejemplos | 📁 | Directorios |
| Laboratorios | 🔬 | Labs prácticos |
| Rutas de Estudio | 📚 | Sección principal |
| Ruta Principiante | 🟢 | Verde |
| Ruta Intermedia | 🟡 | Amarillo |
| Ruta Certificación | 🔴 | Rojo |
| Metodología | 🎯 | Enfoque de aprendizaje |
| Conexión Módulos | 🔗 | Enlaces |
| Conceptos Clave | 💡 | Ideas importantes |
| RESUMEN conceptos | 🎯 | Resumen rápido |
| RESUMEN comandos | 🛠️ | Comandos |
| RESUMEN troubleshooting | 🔍 | Diagnóstico |
| RESUMEN checklist | 📋 | Verificación |
| RESUMEN preguntas | ❓ | Repaso |
| RESUMEN certificación | 🎓 | CKA/CKAD |
| RESUMEN recursos | 📚 | Enlaces externos |
| RESUMEN siguiente paso | 🎯 | Continuación |

---

### Code Blocks

**YAML**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ejemplo
spec:
  containers:
  - name: nginx
    image: nginx:1.21
```

**Bash/Terminal**:
```bash
# Comentario explicativo
kubectl get pods

# Salida esperada (comentada)
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          5s
```

**Estructura de Directorios**:
```
directorio-raiz/
├── subdirectorio-1/
│   ├── archivo1.yaml
│   └── README.md
├── subdirectorio-2/
│   └── archivo2.yaml
└── README.md
```

**Diagramas ASCII**:
```
┌─────────────────┐
│   Componente    │
│  ┌──────────┐   │
│  │  Parte   │   │
│  └──────────┘   │
└─────────────────┘
```

---

### Tablas

**Formato Estándar**:
```markdown
| Columna 1 | Columna 2 | Columna 3 |
|-----------|-----------|-----------|
| **Negrita** | Valor | Descripción |
| **Item 2** | Valor | Descripción |
```

**Tabla Comparativa**:
```markdown
| Aspecto | Opción A | Opción B |
|---------|----------|----------|
| **Característica** | ✅ Sí | ❌ No |
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
```

---

### Enlaces y Referencias

**Enlaces Internos** (otros módulos):
```markdown
- ➡️ **Módulo 05**: [Gestión de Pods](../modulo-05-gestion-pods/)
```

**Enlaces Externos**:
```markdown
- [Kubernetes Documentation](https://kubernetes.io/docs/)
```

---

## 🔄 Proceso de Creación de Nuevo Módulo

### Paso 1: Planificación
1. Definir número del módulo (secuencial)
2. Nombre descriptivo (kebab-case)
3. Identificar tema y alcance
4. Determinar prerrequisitos

### Paso 2: Estructura Básica
```bash
# Crear directorio
mkdir modulo-XX-nombre-descriptivo

# Crear archivos base
touch modulo-XX-nombre-descriptivo/README.md
touch modulo-XX-nombre-descriptivo/RESUMEN-MODULO.md

# Crear carpetas
mkdir -p modulo-XX-nombre-descriptivo/ejemplos
mkdir -p modulo-XX-nombre-descriptivo/laboratorios
```

### Paso 3: README.md
1. Copiar plantilla de esta guía
2. Adaptar secciones al contenido específico
3. Completar objetivos (4 categorías)
4. Definir prerrequisitos realistas
5. Crear estructura del módulo
6. Definir 3 rutas de estudio
7. Documentar organización de recursos
8. Establecer metodología
9. Conectar con otros módulos
10. Expandir objetivos finales

### Paso 4: Ejemplos
```bash
# Crear al menos 5 directorios de ejemplos
mkdir modulo-XX/ejemplos/01-basico
mkdir modulo-XX/ejemplos/02-intermedio
mkdir modulo-XX/ejemplos/03-avanzado
mkdir modulo-XX/ejemplos/04-pattern
mkdir modulo-XX/ejemplos/05-troubleshooting

# Cada uno debe tener:
# - README.md (explicación)
# - Archivos de código (.yaml, .sh, etc.)
# - commands.md (opcional, comandos para ejecutar)
```

### Paso 5: RESUMEN-MODULO.md
1. Conceptos en 5 minutos (elevator pitch)
2. 4-7 secciones técnicas principales
3. Comandos esenciales (básicos, intermedios, troubleshooting)
4. Cheat sheet / referencia rápida
5. 4-6 problemas comunes con soluciones
6. Checklist de conceptos (3-4 categorías)
7. 10-15 preguntas de repaso (con respuestas colapsables)
8. Sección de certificaciones
9. Recursos adicionales
10. Siguiente paso

### Paso 6: Laboratorios
```bash
# Crear labs prácticos
touch modulo-XX/laboratorios/README.md
touch modulo-XX/laboratorios/lab-01-basico.md
touch modulo-XX/laboratorios/lab-02-intermedio.md
touch modulo-XX/laboratorios/lab-03-avanzado.md
```

### Paso 7: Verificación
- [ ] README.md completo (usar checklist al inicio de esta guía)
- [ ] RESUMEN-MODULO.md completo
- [ ] Ejemplos creados y documentados
- [ ] Labs escritos con pasos claros
- [ ] Code blocks tienen sintaxis correcta
- [ ] Enlaces funcionan
- [ ] Emojis consistentes
- [ ] Backup creado si modificaste existente

---

## 🔄 Proceso de Actualización de Módulo Existente

### Paso 1: Backup
```bash
# SIEMPRE crear backup antes de modificar
cd modulo-XX-nombre
cp README.md README.md.backup
```

### Paso 2: Análisis
1. Leer README.md actual
2. Identificar qué falta vs esta plantilla
3. Verificar si existe RESUMEN-MODULO.md
4. Revisar estructura de ejemplos

### Paso 3: Actualización README.md
1. Si no tiene header pedagógico → añadir completo
2. Si tiene header básico → expandir siguiendo plantilla
3. Verificar todas las 10 secciones estén presentes
4. Actualizar contenido obsoleto
5. Mantener contenido original del módulo (después del header)

### Paso 4: RESUMEN-MODULO.md
1. Si no existe → crear desde cero
2. Si existe pero incompleto → expandir
3. Seguir estructura de 10 secciones

### Paso 5: Verificación
- [ ] Backup creado
- [ ] Header completo
- [ ] RESUMEN existe y es completo
- [ ] No se perdió contenido original
- [ ] Formato consistente
- [ ] Enlaces actualizados

---

## 📏 Métricas de Calidad

Un módulo está **completo y de calidad** cuando:

| Métrica | Objetivo | Verificación |
|---------|----------|--------------|
| **README.md líneas** | 1,500-4,000 | Header ~250-400 + contenido |
| **RESUMEN.md líneas** | 900-1,400 | Guía autónoma completa |
| **Ejemplos** | 5-10 directorios | Cada uno con README.md |
| **Labs** | 3-5 prácticos | Paso a paso detallado |
| **Code blocks** | Sin errores | Sintaxis válida |
| **Enlaces** | Todos funcionan | No 404s |
| **Objetivos** | 4 categorías | 16-24 objetivos total |
| **Rutas estudio** | 3 rutas | Principiante, Intermedia, Cert |
| **Tiempo estimado** | Realista | Basado en complejidad |
| **Preguntas repaso** | 10-15 | Con respuestas colapsables |

---

## 💾 Control de Versiones

### Naming de Backups
```bash
README.md.backup           # Backup simple
README.md.backup.original  # Backup del original antes de curso
README.md.backup.YYYYMMDD  # Backup con fecha específica
```

### Git Commits
```bash
# Para nuevos módulos
git add modulo-XX-nombre/
git commit -m "feat: Añadir módulo XX - Título"

# Para actualizaciones
git add modulo-XX-nombre/
git commit -m "docs: Actualizar header pedagógico módulo XX"

# Para RESUMEN
git add modulo-XX-nombre/RESUMEN-MODULO.md
git commit -m "docs: Añadir RESUMEN completo módulo XX"
```

---

## 🎯 Ejemplos de Referencia

### Módulos con Estructura Completa (Usar como Plantilla)

1. **Módulo 01** - Introducción Kubernetes
   - Header pedagógico excelente
   - RESUMEN con evolución histórica
   - Buenas analogías

2. **Módulo 02** - Arquitectura Cluster
   - Header técnico detallado
   - RESUMEN con componentes
   - Diagramas ASCII claros

3. **Módulo 08** - Services y Endpoints
   - Estructura intermedia-avanzada
   - Troubleshooting detallado
   - Labs bien documentados

4. **Módulo 17-18** - RBAC
   - Módulos complementarios
   - Headers diferenciados
   - Conexiones claras entre ellos

---

## 🚨 Errores Comunes a Evitar

### ❌ NO HACER

1. **Header incompleto**
   - Falta alguna de las 10 secciones
   - Objetivos no divididos en 4 categorías
   - Sin rutas de estudio

2. **RESUMEN superficial**
   - Menos de 900 líneas
   - Sin preguntas de repaso
   - Falta cheat sheet de comandos

3. **Inconsistencia de formato**
   - Emojis diferentes al estándar
   - Tablas sin formato
   - Code blocks sin sintaxis

4. **Ejemplos sin documentar**
   - Carpetas sin README.md
   - Código sin comentarios
   - Sin comandos de ejecución

5. **No crear backup**
   - Modificar sin cp README.md README.md.backup
   - Perder contenido original

6. **Tiempos irreales**
   - "5 minutos para aprender Deployments"
   - Rutas de estudio demasiado optimistas

7. **Enlaces rotos**
   - Referencias a módulos inexistentes
   - URLs que no funcionan

8. **Objetivos vagos**
   - "Entender Kubernetes" (demasiado amplio)
   - "Usar kubectl" (no específico)

### ✅ HACER

1. **Header completo** con las 10 secciones
2. **RESUMEN autónomo** que se pueda usar sin README
3. **Formato consistente** siguiendo esta guía
4. **Ejemplos documentados** con README + código + commands
5. **Backup SIEMPRE** antes de modificar
6. **Tiempos realistas** basados en complejidad
7. **Enlaces verificados** funcionando
8. **Objetivos específicos** y medibles

---

## 📞 Uso de esta Guía

### Para Crear Nuevo Módulo
1. Leer sección "Proceso de Creación"
2. Copiar plantillas de cada sección
3. Adaptar al contenido específico
4. Seguir checklist de calidad

### Para Actualizar Módulo Existente
1. Leer sección "Proceso de Actualización"
2. Crear backup
3. Identificar gaps vs plantilla
4. Completar secciones faltantes
5. Verificar checklist

### Para Revisar Calidad
1. Usar checklist al inicio
2. Verificar métricas de calidad
3. Comparar con ejemplos de referencia
4. Revisar errores comunes

---

## 📊 Plantilla Rápida (Copy-Paste)

### Header Mínimo README.md

```markdown
# 🎯 Módulo XX: Título

> **Subtítulo**: Descripción breve

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### 🎓 Objetivos Conceptuales
- **Concepto 1**: Descripción
- **Concepto 2**: Descripción
- **Concepto 3**: Descripción
- **Concepto 4**: Descripción

### 🛠️ Objetivos Técnicos
- **Técnica 1**: Descripción
- **Técnica 2**: Descripción
- **Técnica 3**: Descripción
- **Técnica 4**: Descripción

### 🔍 Objetivos de Troubleshooting
- **Diagnosticar 1**: Descripción
- **Resolver 2**: Descripción
- **Debugging 3**: Descripción
- **Analizar 4**: Descripción

### 🏢 Objetivos Profesionales
- **Producción 1**: Descripción
- **Best practice 2**: Descripción
- **Certificación**: Relevancia
- **Skill 4**: Descripción

---

## ✅ Prerrequisitos

### Conocimientos Previos
- ✅ **Módulo X**: Qué necesitas
- ✅ **Concepto**: Nivel requerido

### Herramientas Necesarias
- 🔧 **Herramienta 1**: Para qué
- 🔧 **Herramienta 2**: Configuración

### Verificación
```bash
# Verificar prerequisito
comando --version
```

---

## 🗺️ Estructura del Módulo

### Contenido Teórico (XX minutos)
1. **Sección 1** (XX min)
2. **Sección 2** (XX min)

### Contenido Práctico (XX minutos)
1. **Lab 1** (XX min)
2. **Lab 2** (XX min)

### Ejemplos Prácticos
- 📁 **01-basico/**
- 📁 **02-intermedio/**

### Laboratorios
- 🔬 **Lab 01**: Descripción
- 🔬 **Lab 02**: Descripción

---

## 📚 Rutas de Estudio Recomendadas

### 🟢 Ruta Principiante
**Tiempo**: X-X horas
```
Día 1: Fundamentos
  ├─ Teoría
  └─ Práctica
```

### 🟡 Ruta Intermedia
**Tiempo**: X-X horas
```
Sesión única:
  ├─ Teoría concentrada
  └─ Práctica intensiva
```

### 🔴 Ruta Certificación
**Tiempo**: XX minutos
```
Estrategia:
  ├─ RESUMEN primero
  └─ Práctica comandos
```

---

## 📁 Organización de Recursos

### Carpeta `ejemplos/`
```
ejemplos/
├── 01-basico/
│   └── README.md
└── 02-intermedio/
    └── README.md
```

---

## 🎯 Metodología de Aprendizaje

Este módulo es **XX% teórico, XX% práctico**:

### Distribución de Contenido
```
💻 Práctica    XX%  ██████████▓░░░░░░░░░
📖 Teoría      XX%  ██████▓░░░░░░░░░░░░░
```

### Enfoque Pedagógico
1. **Principio 1**
2. **Principio 2**

---

## 🔗 Conexión con Otros Módulos

### Este Módulo te Prepara Para
- ➡️ **Módulo XX**: Descripción

### Relación con Módulos Anteriores
```
Módulo anterior
    ↓
Módulo actual ← ESTÁS AQUÍ
    ↓
Módulo siguiente
```

---

## 🎯 Objetivos del Módulo (Expandido)

- ✅ **Objetivo 1** detallado
- ✅ **Objetivo 2** detallado
- ✅ **Objetivo 3** detallado

---
```

---

## 📝 Notas Finales

### Filosofía del Curso

Este curso sigue una filosofía pedagógica específica:

1. **Progresión gradual**: De conceptos simples a complejos
2. **Teoría + Práctica**: Siempre balanceados
3. **Troubleshooting integrado**: Aprender de errores
4. **Production-ready**: Estándares enterprise desde el inicio
5. **Preparación certificación**: Alineado con CKA/CKAD

### Mantener Consistencia

La consistencia es CRÍTICA para la experiencia del estudiante:
- ✅ Todos los módulos deben "sentirse" similares
- ✅ Navegación predecible
- ✅ Mismo nivel de detalle
- ✅ Formato uniforme

### Actualización de esta Guía

Esta guía debe actualizarse cuando:
- Se identifique una mejora en la estructura
- Se añada una nueva sección a los módulos
- Cambien los estándares del curso
- Se detecten errores o inconsistencias

**Última actualización**: 2025-11-12  
**Versión**: 1.0  
**Módulos siguiendo este estándar**: 18/18 (100%)

---

**✅ Con esta guía puedes crear o actualizar cualquier módulo manteniendo la calidad y consistencia del curso.**
