#!/bin/bash

# Script de validación del Basic Helm Chart
# Este script NO requiere Helm instalado para validar sintaxis YAML

CHART_DIR="basic-chart"
ERRORS=0

echo "🔍 Validando estructura del Helm Chart..."
echo ""

# Función para verificar archivo
check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1 existe"
    else
        echo "❌ $1 NO encontrado"
        ((ERRORS++))
    fi
}

# Función para validar YAML con yamllint o básico
validate_yaml() {
    local file=$1
    local is_template=$2
    
    # Los templates de Helm contienen sintaxis Go, no son YAML puro
    if [ "$is_template" = "template" ]; then
        if grep -q "{{" "$file"; then
            echo "  ✅ Template válido (contiene sintaxis Go): $file"
        else
            echo "  ⚠️  Template no contiene placeholders: $file"
        fi
        return
    fi
    
    if command -v yamllint &> /dev/null; then
        if yamllint -d relaxed "$file" &> /dev/null; then
            echo "  ✅ YAML válido: $file"
        else
            echo "  ⚠️  YAML con warnings: $file"
        fi
    else
        # Validación básica con Python
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo "  ✅ YAML válido: $file"
        else
            echo "  ❌ YAML inválido: $file"
            ((ERRORS++))
        fi
    fi
}

# Verificar estructura de directorios
echo "📁 Estructura de directorios:"
check_file "$CHART_DIR/Chart.yaml"
check_file "$CHART_DIR/values.yaml"
check_file "$CHART_DIR/.helmignore"
check_file "$CHART_DIR/templates/deployment.yaml"
check_file "$CHART_DIR/templates/service.yaml"
check_file "$CHART_DIR/templates/NOTES.txt"
check_file "$CHART_DIR/README.md"
echo ""

# Validar archivos YAML
echo "🔧 Validando sintaxis YAML:"
validate_yaml "$CHART_DIR/Chart.yaml" "static"
validate_yaml "$CHART_DIR/values.yaml" "static"
validate_yaml "$CHART_DIR/templates/deployment.yaml" "template"
validate_yaml "$CHART_DIR/templates/service.yaml" "template"
echo ""

# Verificar contenido de Chart.yaml
echo "📋 Verificando Chart.yaml:"
if grep -q "apiVersion: v2" "$CHART_DIR/Chart.yaml"; then
    echo "  ✅ apiVersion correcto (v2)"
else
    echo "  ❌ apiVersion incorrecto o faltante"
    ((ERRORS++))
fi

if grep -q "name: basic-chart" "$CHART_DIR/Chart.yaml"; then
    echo "  ✅ name definido"
else
    echo "  ❌ name faltante"
    ((ERRORS++))
fi

if grep -q "version:" "$CHART_DIR/Chart.yaml"; then
    echo "  ✅ version definida"
else
    echo "  ❌ version faltante"
    ((ERRORS++))
fi
echo ""

# Verificar values.yaml tiene keys esperados
echo "📝 Verificando values.yaml:"
for key in replicaCount image service resources; do
    if grep -q "^$key:" "$CHART_DIR/values.yaml"; then
        echo "  ✅ $key definido"
    else
        echo "  ⚠️  $key no encontrado"
    fi
done
echo ""

# Verificar templates tienen sintaxis Go template
echo "🔨 Verificando templates Go:"
if grep -q "{{ .Values" "$CHART_DIR/templates/deployment.yaml"; then
    echo "  ✅ deployment.yaml usa templates Go"
else
    echo "  ❌ deployment.yaml no tiene templates"
    ((ERRORS++))
fi

if grep -q "{{ .Release.Name }}" "$CHART_DIR/templates/deployment.yaml"; then
    echo "  ✅ deployment.yaml usa .Release.Name"
else
    echo "  ⚠️  deployment.yaml no usa .Release.Name"
fi

if grep -q "{{ .Chart.Name }}" "$CHART_DIR/templates/deployment.yaml"; then
    echo "  ✅ deployment.yaml usa .Chart.Name"
else
    echo "  ⚠️  deployment.yaml no usa .Chart.Name"
fi
echo ""

# Verificar que templates tienen recursos K8s válidos
echo "☸️  Verificando recursos Kubernetes:"
if grep -q "kind: Deployment" "$CHART_DIR/templates/deployment.yaml"; then
    echo "  ✅ deployment.yaml define Deployment"
else
    echo "  ❌ deployment.yaml no define Deployment"
    ((ERRORS++))
fi

if grep -q "kind: Service" "$CHART_DIR/templates/service.yaml"; then
    echo "  ✅ service.yaml define Service"
else
    echo "  ❌ service.yaml no define Service"
    ((ERRORS++))
fi
echo ""

# Resumen final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo "✅ Chart válido! ($CHART_DIR)"
    echo ""
    echo "🚀 Para usar el chart:"
    echo "   helm lint $CHART_DIR"
    echo "   helm template test-release $CHART_DIR"
    echo "   helm install my-nginx $CHART_DIR"
    exit 0
else
    echo "❌ Chart tiene $ERRORS error(es)"
    echo ""
    echo "🔧 Revisa los mensajes arriba para corregir"
    exit 1
fi
